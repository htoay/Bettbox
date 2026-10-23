package toolbox

import (
	"crypto/rand"
	"io"
	"slices"
	"sort"
	"strconv"
	"strings"
	"sync"
	"sync/atomic"
	"testing"
	"time"
)

func medianOld(values []float64) float64 {
	if len(values) == 0 {
		return 0
	}
	sorted := append([]float64{}, values...)
	sort.Float64s(sorted)
	middle := len(sorted) / 2
	if len(sorted)%2 == 0 {
		return (sorted[middle-1] + sorted[middle]) / 2
	}
	return sorted[middle]
}

func parseServerTimingOld(header string) float64 {
	for _, part := range strings.Split(header, ";") {
		key, value, ok := strings.Cut(strings.TrimSpace(part), "=")
		if ok && key == "dur" {
			if dur, err := strconv.ParseFloat(value, 64); err == nil {
				return dur
			}
		}
	}
	return 0
}

func parseCloudflareTraceOld(body string) map[string]string {
	result := map[string]string{}
	for _, line := range strings.Split(body, "\n") {
		key, value, ok := strings.Cut(strings.TrimSpace(line), "=")
		if ok {
			result[key] = value
		}
	}
	return result
}

func stableSpeedOld(samples []speedSample) float64 {
	if len(samples) < 2 {
		return 0
	}
	last := samples[len(samples)-1]
	cut := time.Duration(float64(last.at) * speedTestRampUp)
	first := samples[0]
	for _, sample := range samples {
		if sample.at >= cut {
			first = sample
			break
		}
	}
	elapsed := (last.at - first.at).Seconds()
	if elapsed <= 0 {
		return 0
	}
	return float64(last.bytes-first.bytes) * 8 / elapsed
}

type speedUploadReaderOld struct {
	payload   []byte
	remaining int64
	counter   *atomic.Int64
	total     *atomic.Int64
}

func (r *speedUploadReaderOld) Read(p []byte) (int, error) {
	if r.remaining <= 0 {
		return 0, io.EOF
	}
	if int64(len(p)) > r.remaining {
		p = p[:r.remaining]
	}
	n := copy(p, r.payload)
	r.remaining -= int64(n)
	r.counter.Add(int64(n))
	r.total.Add(int64(n))
	return n, nil
}

func medianNew(values []float64) float64 {
	n := len(values)
	if n == 0 {
		return 0
	}
	if n == 1 {
		return values[0]
	}
	if n == 2 {
		return (values[0] + values[1]) / 2
	}
	var sorted []float64
	var stackBuf [64]float64
	if n <= len(stackBuf) {
		sorted = stackBuf[:n]
		copy(sorted, values)
	} else {
		sorted = append([]float64(nil), values...)
	}
	slices.Sort(sorted)
	middle := n / 2
	if n%2 == 0 {
		return (sorted[middle-1] + sorted[middle]) / 2
	}
	return sorted[middle]
}

func parseServerTimingNew(header string) float64 {
	rem := header
	for len(rem) > 0 {
		var part string
		part, rem, _ = strings.Cut(rem, ";")
		key, value, ok := strings.Cut(strings.TrimSpace(part), "=")
		if ok && key == "dur" {
			if dur, err := strconv.ParseFloat(value, 64); err == nil {
				return dur
			}
		}
	}
	return 0
}

func parseCloudflareTraceNew(body string) map[string]string {
	result := make(map[string]string, 16)
	rem := body
	for len(rem) > 0 {
		var line string
		line, rem, _ = strings.Cut(rem, "\n")
		key, value, ok := strings.Cut(strings.TrimSpace(line), "=")
		if ok {
			result[key] = value
		}
	}
	return result
}

func stableSpeedNew(samples []speedSample) float64 {
	if len(samples) < 2 {
		return 0
	}
	last := samples[len(samples)-1]
	cut := time.Duration(float64(last.at) * speedTestRampUp)
	idx, _ := slices.BinarySearchFunc(samples, cut, func(s speedSample, target time.Duration) int {
		if s.at < target {
			return -1
		} else if s.at > target {
			return 1
		}
		return 0
	})
	if idx >= len(samples) {
		idx = len(samples) - 1
	}
	first := samples[idx]
	elapsed := (last.at - first.at).Seconds()
	if elapsed <= 0 {
		return 0
	}
	return float64(last.bytes-first.bytes) * 8 / elapsed
}

type speedUploadReaderNew struct {
	payload   []byte
	offset    int
	remaining int64
	counter   *atomic.Int64
	total     *atomic.Int64
}

func (r *speedUploadReaderNew) Read(p []byte) (int, error) {
	if r.remaining <= 0 {
		return 0, io.EOF
	}
	toRead := len(p)
	if int64(toRead) > r.remaining {
		toRead = int(r.remaining)
	}
	n := 0
	for n < toRead {
		chunk := copy(p[n:toRead], r.payload[r.offset:])
		r.offset += chunk
		if r.offset >= len(r.payload) {
			r.offset = 0
		}
		n += chunk
	}
	r.remaining -= int64(n)
	r.counter.Add(int64(n))
	r.total.Add(int64(n))
	return n, nil
}

func (r *speedUploadReaderNew) Close() error {
	return nil
}

const benchBufferSize = 64 * 1024

var benchBufferPool = sync.Pool{
	New: func() any {
		buf := make([]byte, benchBufferSize)
		return &buf
	},
}

var benchCounterPool = sync.Pool{
	New: func() any {
		return &speedCounter{}
	},
}

var (
	benchGlobalPayloadOnce sync.Once
	benchGlobalPayload     []byte
)

func getBenchGlobalPayload() []byte {
	benchGlobalPayloadOnce.Do(func() {
		benchGlobalPayload = make([]byte, benchBufferSize)
		_, _ = rand.Read(benchGlobalPayload)
	})
	return benchGlobalPayload
}

func BenchmarkMedian_Old(b *testing.B) {
	data := []float64{23.5, 21.0, 19.8, 25.1, 24.3, 20.5, 22.1, 28.0, 19.2, 21.4,
		23.1, 22.8, 20.1, 26.4, 21.9, 22.0, 24.8, 23.9, 21.2, 22.5}
	b.ResetTimer()
	b.ReportAllocs()
	for i := 0; i < b.N; i++ {
		_ = medianOld(data)
	}
}

func BenchmarkMedian_New(b *testing.B) {
	data := []float64{23.5, 21.0, 19.8, 25.1, 24.3, 20.5, 22.1, 28.0, 19.2, 21.4,
		23.1, 22.8, 20.1, 26.4, 21.9, 22.0, 24.8, 23.9, 21.2, 22.5}
	b.ResetTimer()
	b.ReportAllocs()
	for i := 0; i < b.N; i++ {
		_ = medianNew(data)
	}
}

func BenchmarkParseServerTiming_Old(b *testing.B) {
	header := "edge; dur=12.345, origin; dur=45.678; desc=\"something\""
	b.ResetTimer()
	b.ReportAllocs()
	for i := 0; i < b.N; i++ {
		_ = parseServerTimingOld(header)
	}
}

func BenchmarkParseServerTiming_New(b *testing.B) {
	header := "edge; dur=12.345, origin; dur=45.678; desc=\"something\""
	b.ResetTimer()
	b.ReportAllocs()
	for i := 0; i < b.N; i++ {
		_ = parseServerTimingNew(header)
	}
}

func BenchmarkParseCloudflareTrace_Old(b *testing.B) {
	body := "fl=123f45\nh=speed.cloudflare.com\nip=1.2.3.4\nts=1690000000\nvisit_scheme=https\nuag=Mozilla/5.0\ncolo=HKG\nsliver=none\nhttp=http/2\nloc=HK\ntls=TLSv1.3\nsni=plaintext\nwarp=off\ngateway=off\nrbi=off\nkex=X25519\n"
	b.ResetTimer()
	b.ReportAllocs()
	for i := 0; i < b.N; i++ {
		_ = parseCloudflareTraceOld(body)
	}
}

func BenchmarkParseCloudflareTrace_New(b *testing.B) {
	body := "fl=123f45\nh=speed.cloudflare.com\nip=1.2.3.4\nts=1690000000\nvisit_scheme=https\nuag=Mozilla/5.0\ncolo=HKG\nsliver=none\nhttp=http/2\nloc=HK\ntls=TLSv1.3\nsni=plaintext\nwarp=off\ngateway=off\nrbi=off\nkex=X25519\n"
	b.ResetTimer()
	b.ReportAllocs()
	for i := 0; i < b.N; i++ {
		_ = parseCloudflareTraceNew(body)
	}
}

func BenchmarkStableSpeed_Old(b *testing.B) {
	samples := make([]speedSample, 100)
	for i := range samples {
		samples[i] = speedSample{
			at:    time.Duration(i*100) * time.Millisecond,
			bytes: int64(i * 1250000),
		}
	}
	b.ResetTimer()
	b.ReportAllocs()
	for i := 0; i < b.N; i++ {
		_ = stableSpeedOld(samples)
	}
}

func BenchmarkStableSpeed_New(b *testing.B) {
	samples := make([]speedSample, 100)
	for i := range samples {
		samples[i] = speedSample{
			at:    time.Duration(i*100) * time.Millisecond,
			bytes: int64(i * 1250000),
		}
	}
	b.ResetTimer()
	b.ReportAllocs()
	for i := 0; i < b.N; i++ {
		_ = stableSpeedNew(samples)
	}
}

func BenchmarkDownloadWorker_AllocPerRequest_Old(b *testing.B) {
	b.ReportAllocs()
	var counter, total atomic.Int64
	for i := 0; i < b.N; i++ {
		buf := make([]byte, benchBufferSize)
		c := &speedCounter{counter: &counter, total: &total}
		_, _ = c.Write(buf)
	}
}

func BenchmarkDownloadWorker_PoolReuse_New(b *testing.B) {
	b.ReportAllocs()
	var counter, total atomic.Int64
	for i := 0; i < b.N; i++ {
		bufPtr := benchBufferPool.Get().(*[]byte)
		c := benchCounterPool.Get().(*speedCounter)
		c.counter = &counter
		c.total = &total
		_, _ = c.Write(*bufPtr)
		benchCounterPool.Put(c)
		benchBufferPool.Put(bufPtr)
	}
}

func BenchmarkUploadWorker_PayloadAlloc_Old(b *testing.B) {
	b.ReportAllocs()
	for i := 0; i < b.N; i++ {
		payload := make([]byte, benchBufferSize)
		_, _ = rand.Read(payload)
	}
}

func BenchmarkUploadWorker_PayloadGlobal_New(b *testing.B) {
	b.ReportAllocs()
	for i := 0; i < b.N; i++ {
		_ = getBenchGlobalPayload()
	}
}

func BenchmarkUploadReader_Stream10MB_Old(b *testing.B) {
	payload := make([]byte, benchBufferSize)
	_, _ = rand.Read(payload)
	buf := make([]byte, 32*1024)
	var counter, total atomic.Int64

	b.ResetTimer()
	b.ReportAllocs()
	for i := 0; i < b.N; i++ {
		reader := &speedUploadReaderOld{
			payload:   payload,
			remaining: 10 * 1024 * 1024,
			counter:   &counter,
			total:     &total,
		}
		for {
			_, err := reader.Read(buf)
			if err == io.EOF {
				break
			}
		}
	}
}

func BenchmarkUploadReader_Stream10MB_New(b *testing.B) {
	payload := getBenchGlobalPayload()
	buf := make([]byte, 32*1024)
	var counter, total atomic.Int64

	b.ResetTimer()
	b.ReportAllocs()
	for i := 0; i < b.N; i++ {
		reader := &speedUploadReaderNew{
			payload:   payload,
			remaining: 10 * 1024 * 1024,
			counter:   &counter,
			total:     &total,
		}
		for {
			_, err := reader.Read(buf)
			if err == io.EOF {
				break
			}
		}
	}
}
