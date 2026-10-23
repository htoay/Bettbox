package toolbox

import (
	"bufio"
	"context"
	"encoding/base64"
	"encoding/hex"
	"encoding/json"
	"io"
	"net"
	"net/http"
	"strings"
	"sync"
	"time"

	"github.com/metacubex/mihomo/constant"
	"github.com/metacubex/mihomo/tunnel/statistic"
)

const toolProxyInbound = "Toolbox"

type toolProxyServer struct {
	listener net.Listener
	mu       sync.Mutex
	conns    map[net.Conn]struct{}
	wg       sync.WaitGroup
}

var (
	toolProxyLock    sync.Mutex
	toolProxyCurrent *toolProxyServer
)

func startToolProxy() (int, error) {
	toolProxyLock.Lock()
	defer toolProxyLock.Unlock()
	if current := toolProxyCurrent; current != nil {
		return current.listener.Addr().(*net.TCPAddr).Port, nil
	}
	listener, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		return 0, err
	}
	server := &toolProxyServer{listener: listener, conns: map[net.Conn]struct{}{}}
	toolProxyCurrent = server
	server.wg.Add(1)
	go server.serve()
	return listener.Addr().(*net.TCPAddr).Port, nil
}

func stopToolProxy() {
	toolProxyLock.Lock()
	server := toolProxyCurrent
	toolProxyCurrent = nil
	toolProxyLock.Unlock()
	if server == nil {
		return
	}
	_ = server.listener.Close()
	server.mu.Lock()
	for conn := range server.conns {
		_ = conn.Close()
	}
	server.mu.Unlock()
	server.wg.Wait()
}

func (s *toolProxyServer) track(conn net.Conn, add bool) {
	s.mu.Lock()
	if add {
		s.conns[conn] = struct{}{}
	} else {
		delete(s.conns, conn)
	}
	s.mu.Unlock()
}

func (s *toolProxyServer) serve() {
	defer s.wg.Done()
	for {
		conn, err := s.listener.Accept()
		if err != nil {
			return
		}
		s.wg.Add(1)
		go func() {
			defer s.wg.Done()
			s.track(conn, true)
			defer s.track(conn, false)
			defer conn.Close()
			s.handle(conn)
		}()
	}
}

func toolProxyName(header string) string {
	const prefix = "Basic "
	if !strings.HasPrefix(header, prefix) {
		return ""
	}
	raw, err := base64.StdEncoding.DecodeString(strings.TrimPrefix(header, prefix))
	if err != nil {
		return ""
	}
	user, _, _ := strings.Cut(string(raw), ":")
	name, err := hex.DecodeString(user)
	if err != nil {
		return ""
	}
	return string(name)
}

func toolProxyDial(ctx context.Context, name, address string) (net.Conn, error) {
	proxy, ok := FindProxy(name)
	if !ok {
		return nil, errSpeedTestProxyNotFound
	}
	metadata := &constant.Metadata{
		NetWork: constant.TCP,
		Type:    constant.INNER,
		DNSMode: constant.DNSNormal,
		Process: constant.MihomoName,
		InName:  toolProxyInbound,
	}
	if err := metadata.SetRemoteAddress(address); err != nil {
		return nil, err
	}
	conn, err := proxy.DialContext(ctx, metadata)
	if err != nil {
		return nil, err
	}
	return statistic.NewTCPTracker(conn, statistic.DefaultManager, metadata, nil, 0, 0, true), nil
}

func (s *toolProxyServer) handle(conn net.Conn) {
	_ = conn.SetReadDeadline(time.Now().Add(15 * time.Second))
	reader := bufio.NewReader(conn)
	req, err := http.ReadRequest(reader)
	if err != nil {
		return
	}
	_ = conn.SetReadDeadline(time.Time{})
	name := toolProxyName(req.Header.Get("Proxy-Authorization"))
	if name == "" {
		_, _ = io.WriteString(conn, "HTTP/1.1 407 Proxy Authentication Required\r\nProxy-Authenticate: Basic realm=\"toolbox\"\r\nContent-Length: 0\r\nConnection: close\r\n\r\n")
		return
	}
	address := req.Host
	if req.Method != http.MethodConnect {
		address = req.URL.Host
	}
	if _, _, err := net.SplitHostPort(address); err != nil {
		port := "80"
		if req.Method == http.MethodConnect || req.URL.Scheme == "https" {
			port = "443"
		}
		address = net.JoinHostPort(strings.Trim(address, "[]"), port)
	}
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	remote, err := toolProxyDial(ctx, name, address)
	cancel()
	if err != nil {
		_, _ = io.WriteString(conn, "HTTP/1.1 502 Bad Gateway\r\nContent-Length: 0\r\nConnection: close\r\n\r\n")
		return
	}
	s.track(remote, true)
	defer s.track(remote, false)
	defer remote.Close()

	if req.Method == http.MethodConnect {
		if _, err := io.WriteString(conn, "HTTP/1.1 200 Connection Established\r\n\r\n"); err != nil {
			return
		}
		if buffered := reader.Buffered(); buffered > 0 {
			data, _ := reader.Peek(buffered)
			if _, err := remote.Write(data); err != nil {
				return
			}
		}
	} else {
		req.Header.Del("Proxy-Authorization")
		req.Header.Del("Proxy-Connection")
		req.Header.Set("Connection", "close")
		req.RequestURI = ""
		if err := req.Write(remote); err != nil {
			return
		}
	}
	done := make(chan struct{}, 2)
	go func() {
		_, _ = io.Copy(remote, reader)
		if closer, ok := remote.(interface{ CloseWrite() error }); ok {
			_ = closer.CloseWrite()
		}
		done <- struct{}{}
	}()
	go func() {
		_, _ = io.Copy(conn, remote)
		_ = conn.Close()
		done <- struct{}{}
	}()
	<-done
	_ = remote.Close()
	_ = conn.Close()
	<-done
}

func HandleStartToolProxy() string {
	port, err := startToolProxy()
	if err != nil {
		return "0"
	}
	data, _ := json.Marshal(port)
	return string(data)
}

func HandleStopToolProxy() bool {
	stopToolProxy()
	releaseToolMemory()
	return true
}
