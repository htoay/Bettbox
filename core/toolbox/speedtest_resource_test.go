package toolbox

import (
	"context"
	"runtime"
	"runtime/debug"
	"sync"
	"sync/atomic"
	"testing"
	"time"

	mhttp "github.com/metacubex/http"
	"github.com/metacubex/mihomo/adapter"
	"github.com/metacubex/mihomo/adapter/outbound"
	"github.com/metacubex/mihomo/constant"
	"github.com/metacubex/mihomo/tunnel"
	"github.com/metacubex/mihomo/tunnel/statistic"
)

type speedTestResources struct {
	goroutines  int
	heapInuse   uint64
	heapObjects uint64
	connections int
}

func collectSpeedTestResources() speedTestResources {
	runtime.GC()
	debug.FreeOSMemory()
	var stats runtime.MemStats
	runtime.ReadMemStats(&stats)
	resources := speedTestResources{
		goroutines:  runtime.NumGoroutine(),
		heapInuse:   stats.HeapInuse,
		heapObjects: stats.HeapObjects,
	}
	statistic.DefaultManager.Range(func(statistic.Tracker) bool {
		resources.connections++
		return true
	})
	return resources
}

func waitSpeedTestReleased(baseline speedTestResources) speedTestResources {
	deadline := time.Now().Add(5 * time.Second)
	for {
		current := collectSpeedTestResources()
		if (current.goroutines <= baseline.goroutines && current.connections == 0) || time.Now().After(deadline) {
			return current
		}
		time.Sleep(100 * time.Millisecond)
	}
}

type speedTestPeak struct {
	heapInuse   atomic.Uint64
	goroutines  atomic.Int64
	connections atomic.Int64
}

func watchSpeedTestPeak(ctx context.Context, wg *sync.WaitGroup) *speedTestPeak {
	peak := &speedTestPeak{}
	wg.Add(1)
	go func() {
		defer wg.Done()
		ticker := time.NewTicker(50 * time.Millisecond)
		defer ticker.Stop()
		for {
			select {
			case <-ctx.Done():
				return
			case <-ticker.C:
				var stats runtime.MemStats
				runtime.ReadMemStats(&stats)
				if stats.HeapInuse > peak.heapInuse.Load() {
					peak.heapInuse.Store(stats.HeapInuse)
				}
				if n := int64(runtime.NumGoroutine()); n > peak.goroutines.Load() {
					peak.goroutines.Store(n)
				}
				var connections int64
				statistic.DefaultManager.Range(func(statistic.Tracker) bool {
					connections++
					return true
				})
				if connections > peak.connections.Load() {
					peak.connections.Store(connections)
				}
			}
		}
	}()
	return peak
}

func useSpeedTestTunnel(t *testing.T) {
	tunnel.UpdateProxies(map[string]constant.Proxy{
		"DIRECT": adapter.NewProxy(outbound.NewDirect()),
	}, nil)
	tunnel.OnRunning()
	t.Cleanup(tunnel.OnSuspend)
}

func mb(value uint64) float64 {
	return float64(value) / 1024 / 1024
}

func TestSpeedTestReleasesResources(t *testing.T) {
	useSpeedTestTunnel(t)
	server := newSpeedTestServer(t)
	baseline := collectSpeedTestResources()
	t.Logf("baseline: goroutines=%d heap=%.2fMB objects=%d", baseline.goroutines, mb(baseline.heapInuse), baseline.heapObjects)

	cases := []struct {
		name   string
		cancel time.Duration
	}{
		{name: "complete-1"},
		{name: "complete-2"},
		{name: "cancel-during-download", cancel: 1200 * time.Millisecond},
		{name: "complete-3"},
	}
	for _, item := range cases {
		tester := newTestSpeedTester(server)
		tester.direct = false
		tester.params.Duration = 1

		ctx, cancel := context.WithCancel(context.Background())
		watchCtx, stopWatch := context.WithCancel(context.Background())
		var wg sync.WaitGroup
		peak := watchSpeedTestPeak(watchCtx, &wg)
		if item.cancel > 0 {
			time.AfterFunc(item.cancel, cancel)
		}
		start := time.Now()
		tester.run(ctx, func(SpeedTestState) {})
		elapsed := time.Since(start)
		stopWatch()
		wg.Wait()
		cancel()

		state := tester.snapshot()
		after := waitSpeedTestReleased(baseline)
		t.Logf(
			"%s: elapsed=%s bytes=%.1fMB phase=%s error=%q outbound=%v | peak heap=%.2fMB goroutines=%d connections=%d | after heap=%.2fMB goroutines=%d connections=%d watched=%v",
			item.name, elapsed.Round(time.Millisecond), mb(uint64(state.Bytes)), state.Phase, state.Error, state.Outbound,
			mb(peak.heapInuse.Load()), peak.goroutines.Load(), peak.connections.Load(),
			mb(after.heapInuse), after.goroutines, after.connections, speedTestWatched.Load() != nil,
		)

		if item.cancel == 0 && (state.Error != "" || state.Download <= 0) {
			t.Fatalf("%s did not finish: %+v", item.name, state)
		}
		if item.cancel > 0 && state.Error != speedTestErrorCancelled {
			t.Fatalf("%s expected cancelled, got %q", item.name, state.Error)
		}
		if state.Outbound == nil || len(state.Outbound.Chains) == 0 || state.Outbound.Chains[0] != "DIRECT" {
			t.Fatalf("%s outbound not resolved through tunnel: %+v", item.name, state.Outbound)
		}
		if peak.connections.Load() == 0 {
			t.Fatalf("%s did not go through the tunnel", item.name)
		}
		if after.goroutines > baseline.goroutines || after.connections != 0 || speedTestWatched.Load() != nil {
			t.Fatalf("%s leaked: goroutines %d -> %d, connections=%d", item.name, baseline.goroutines, after.goroutines, after.connections)
		}
		if after.heapInuse > baseline.heapInuse+4<<20 {
			t.Fatalf("%s heap not released: %.2fMB -> %.2fMB", item.name, mb(baseline.heapInuse), mb(after.heapInuse))
		}
		if item.cancel > 0 && elapsed > item.cancel+time.Second {
			t.Fatalf("%s cancel took too long: %s", item.name, elapsed)
		}
	}
}

func TestSpeedTestQuicReleasesResources(t *testing.T) {
	url := newQuicTestServer(t)
	baseline := collectSpeedTestResources()
	for round := 1; round <= 3; round++ {
		tester := newSpeedTester(SpeedTestParams{Protocol: speedTestProtocolQuic, Duration: 1}, true)
		clients := make([]*mhttp.Client, tester.params.Streams)
		for i := range clients {
			clients[i] = newInsecureQuicClient(tester)
		}
		tester.load = clients
		tester.probe = newInsecureQuicClient(tester)
		target := &speedTestTarget{latencyURL: url + "/", downloadURL: url + "/download"}

		watchCtx, stopWatch := context.WithCancel(context.Background())
		var wg sync.WaitGroup
		peak := watchSpeedTestPeak(watchCtx, &wg)
		speed, loaded := tester.measureLoad(context.Background(), target, tester.downloadWorker(target.downloadURL))
		stopWatch()
		wg.Wait()
		for _, closer := range tester.closers {
			closer()
		}
		after := waitSpeedTestReleased(baseline)
		t.Logf(
			"quic round %d: speed=%.0fMbps loaded=%d bytes=%.1fMB | peak heap=%.2fMB goroutines=%d | after heap=%.2fMB goroutines=%d (baseline %d)",
			round, speed/1e6, len(loaded), mb(uint64(tester.bytes.Load())),
			mb(peak.heapInuse.Load()), peak.goroutines.Load(),
			mb(after.heapInuse), after.goroutines, baseline.goroutines,
		)
		if speed <= 0 {
			t.Fatalf("quic round %d transferred nothing", round)
		}
		if after.goroutines > baseline.goroutines {
			t.Fatalf("quic round %d leaked goroutines: %d -> %d", round, baseline.goroutines, after.goroutines)
		}
		if after.heapInuse > baseline.heapInuse+4<<20 {
			t.Fatalf("quic round %d heap not released: %.2fMB -> %.2fMB", round, mb(baseline.heapInuse), mb(after.heapInuse))
		}
	}
}

func TestSpeedTestDialsSelectedProxyAndReleases(t *testing.T) {
	useSpeedTestTunnel(t)
	tunnel.UpdateProxies(map[string]constant.Proxy{
		"DIRECT": adapter.NewProxy(outbound.NewDirect()),
		"Node":   adapter.NewProxy(outbound.NewDirect()),
	}, nil)
	server := newSpeedTestServer(t)
	baseline := collectSpeedTestResources()

	tester := newTestSpeedTester(server)
	tester.direct = false
	tester.params.Proxy = "Node"
	tester.run(context.Background(), func(SpeedTestState) {})
	state := tester.snapshot()
	if state.Error != "" || state.Download <= 0 || state.Outbound == nil || len(state.Outbound.Chains) == 0 {
		t.Fatalf("selected proxy run failed %+v %+v", state, state.Outbound)
	}
	after := waitSpeedTestReleased(baseline)
	if after.goroutines > baseline.goroutines || after.connections != 0 {
		t.Fatalf("leaked: goroutines %d -> %d connections=%d", baseline.goroutines, after.goroutines, after.connections)
	}

	missing := newTestSpeedTester(server)
	missing.direct = false
	missing.params.Proxy = "Missing"
	missing.prepare = func(ctx context.Context, t *speedTester) (*speedTestTarget, error) {
		_, _, err := t.fetch(ctx, t.client, server.URL+"/latency", 1024)
		return nil, err
	}
	missing.run(context.Background(), func(SpeedTestState) {})
	if state := missing.snapshot(); state.Error != speedTestErrorUnavailable {
		t.Fatalf("expected unavailable for missing proxy, got %q", state.Error)
	}
}
