package toolbox

import (
	"context"
	"encoding/binary"
	"net"
	"net/netip"
	"sync"
	"testing"
	"time"
)

func TestLocalPingICMPLoopback(t *testing.T) {
	for _, target := range []string{"127.0.0.1", "::1"} {
		t.Run(target, func(t *testing.T) {
			var mu sync.Mutex
			notified := 0
			state := runLocalPing(context.Background(), 1, LocalPingParams{Target: target, Count: 3, Interval: 100, Size: 48}, func(state LocalPingState) {
				mu.Lock()
				if state.Reply != nil {
					notified++
				}
				mu.Unlock()
			})
			if state.Error == localPingErrorDenied {
				t.Skip("icmp sockets not permitted")
			}
			if state.Error != "" || state.Phase != localPingPhaseDone || state.Sent != 3 || len(state.Replies) != 3 {
				t.Fatalf("unexpected state: %+v", state)
			}
			for i, reply := range state.Replies {
				if reply.Seq != i+1 || reply.Status != localPingStatusOK || reply.RTT <= 0 || reply.Bytes != 48 {
					t.Fatalf("bad reply %d: %+v", i, reply)
				}
			}
			if notified != 3 {
				t.Fatalf("notified %d replies", notified)
			}
		})
	}
}

func TestLocalPingTCP(t *testing.T) {
	listener, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
	}
	defer listener.Close()
	go func() {
		for {
			conn, err := listener.Accept()
			if err != nil {
				return
			}
			_ = conn.Close()
		}
	}()
	port := listener.Addr().(*net.TCPAddr).Port
	state := runLocalPing(context.Background(), 1, LocalPingParams{Target: "127.0.0.1", Protocol: localPingTCP, Port: port, Count: 2, Interval: 100}, nil)
	if state.Error != "" || len(state.Replies) != 2 || state.Size != 0 || state.Port != port {
		t.Fatalf("unexpected state: %+v", state)
	}
	for _, reply := range state.Replies {
		if reply.Status != localPingStatusOK || reply.RTT <= 0 {
			t.Fatalf("bad reply: %+v", reply)
		}
	}

	closed, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
	}
	closedPort := closed.Addr().(*net.TCPAddr).Port
	_ = closed.Close()
	prober := &localTCPProber{addr: netip.AddrPortFrom(netip.MustParseAddr("127.0.0.1"), uint16(closedPort))}
	if reply := prober.ping(context.Background(), 1); reply.Status != localPingStatusClosed || reply.RTT <= 0 {
		t.Fatalf("closed port: %+v", reply)
	}
}

func TestLocalPingUDP(t *testing.T) {
	server, err := net.ListenUDP("udp4", &net.UDPAddr{IP: net.IPv4(127, 0, 0, 1)})
	if err != nil {
		t.Fatal(err)
	}
	defer server.Close()
	go func() {
		buf := make([]byte, 2048)
		for {
			n, addr, err := server.ReadFromUDPAddrPort(buf)
			if err != nil {
				return
			}
			if n == len(localPingDNSQuery(0)) {
				response := append([]byte(nil), buf[:n]...)
				response[2] |= 0x80
				wrong := append([]byte(nil), response...)
				binary.BigEndian.PutUint16(wrong, binary.BigEndian.Uint16(response)+1)
				_, _ = server.WriteToUDPAddrPort(wrong, addr)
				_, _ = server.WriteToUDPAddrPort(response, addr)
			}
		}
	}()
	addr := server.LocalAddr().(*net.UDPAddr).AddrPort()
	loopback := netip.AddrPortFrom(netip.MustParseAddr("127.0.0.1"), addr.Port())

	dns := &localUDPProber{addr: loopback, dns: true}
	if reply := dns.ping(context.Background(), 1); reply.Status != localPingStatusOK || reply.RTT <= 0 || reply.Bytes != len(localPingDNSQuery(0)) {
		t.Fatalf("dns reply: %+v", reply)
	}

	ctx, cancel := context.WithTimeout(context.Background(), 300*time.Millisecond)
	defer cancel()
	silent := &localUDPProber{addr: loopback, payload: localPingPayload(32)}
	if reply := silent.ping(ctx, 1); reply.Status != localPingStatusTimeout {
		t.Fatalf("silent port: %+v", reply)
	}

	closed, err := net.ListenUDP("udp4", &net.UDPAddr{IP: net.IPv4(127, 0, 0, 1)})
	if err != nil {
		t.Fatal(err)
	}
	closedAddr := closed.LocalAddr().(*net.UDPAddr).AddrPort()
	_ = closed.Close()
	refused := &localUDPProber{addr: netip.AddrPortFrom(netip.MustParseAddr("127.0.0.1"), closedAddr.Port()), payload: localPingPayload(32)}
	ctx2, cancel2 := context.WithTimeout(context.Background(), time.Second)
	defer cancel2()
	if reply := refused.ping(ctx2, 1); reply.Status != localPingStatusClosed {
		t.Fatalf("closed udp port: %+v", reply)
	}
}

func TestLocalPingCancel(t *testing.T) {
	listener, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
	}
	defer listener.Close()
	go func() {
		for {
			conn, err := listener.Accept()
			if err != nil {
				return
			}
			_ = conn.Close()
		}
	}()
	ctx, cancel := context.WithCancel(context.Background())
	time.AfterFunc(350*time.Millisecond, cancel)
	start := time.Now()
	state := runLocalPing(ctx, 1, LocalPingParams{Target: "127.0.0.1", Protocol: localPingTCP, Port: listener.Addr().(*net.TCPAddr).Port, Count: 100, Interval: 100}, nil)
	if took := time.Since(start); took > time.Second {
		t.Fatalf("cancel took %v", took)
	}
	if state.Phase != localPingPhaseDone || state.Sent < 2 || state.Sent > 6 || state.Sent != len(state.Replies) {
		t.Fatalf("unexpected state after cancel: %+v", state)
	}
}

func TestLocalPingErrors(t *testing.T) {
	if state := runLocalPing(context.Background(), 1, LocalPingParams{Target: "bad host"}, nil); state.Error != localPingErrorInvalid || state.Phase != localPingPhaseDone {
		t.Fatalf("invalid target: %+v", state)
	}
	if state := runLocalPing(context.Background(), 1, LocalPingParams{Target: "missing.invalid"}, nil); state.Error != localPingErrorResolve {
		t.Fatalf("unresolvable target: %+v", state)
	}
	params := normalizeLocalPingParams(LocalPingParams{Protocol: localPingUDP, Count: 99999, Interval: 1, Size: -1})
	if params.Port != 53 || params.Count != localPingMaxCount || params.Interval != localPingMinInterval || params.Size != len(localPingDNSQuery(0)) {
		t.Fatalf("normalize: %+v", params)
	}
}
