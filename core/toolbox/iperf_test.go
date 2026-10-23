package toolbox

import (
	"encoding/json"
	"fmt"
	"net"
	"testing"
)

func TestIperfBridgeRoundTrip(t *testing.T) {
	listener, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
	}
	port := listener.Addr().(*net.TCPAddr).Port
	_ = listener.Close()
	var info IperfServerInfo
	_ = json.Unmarshal([]byte(HandleStartIperfServer(fmt.Sprintf(`{"port":%d}`, port))), &info)
	defer HandleStopIperfServer()
	if info.Error != "" || info.Port != port || !info.UDP {
		t.Fatalf("server failed: %+v", info)
	}
	var state map[string]any
	raw := HandleStartIperfClient(fmt.Sprintf(`{"hosts":["127.0.0.1"],"port":%d,"protocol":"tcp","direction":"bidir","parallel":2,"duration":1}`, port))
	if err := json.Unmarshal([]byte(raw), &state); err != nil {
		t.Fatal(err)
	}
	if state["role"] != "client" || state["phase"] != "done" || state["error"] != "" || state["direction"] != "bidir" {
		t.Fatalf("unexpected state %s", raw)
	}
	for _, key := range []string{"upload-result", "download-result"} {
		flow, ok := state[key].(map[string]any)
		if !ok || flow["bitrate"].(float64) <= 0 {
			t.Fatalf("missing %s in %s", key, raw)
		}
	}
	var busy IperfServerInfo
	_ = json.Unmarshal([]byte(HandleStartIperfServer(fmt.Sprintf(`{"port":%d}`, port))), &busy)
	if busy.Error != "" {
		t.Fatalf("restarting the server on the same port failed: %+v", busy)
	}
	occupied, err := net.Listen("tcp", ":0")
	if err != nil {
		t.Fatal(err)
	}
	defer occupied.Close()
	var taken IperfServerInfo
	_ = json.Unmarshal([]byte(HandleStartIperfServer(fmt.Sprintf(`{"port":%d}`, occupied.Addr().(*net.TCPAddr).Port))), &taken)
	if taken.Error != iperfErrorPortInUse {
		t.Fatalf("expected port in use, got %+v", taken)
	}
}
