package toolbox

import (
	"context"
	"crypto/rand"
	"encoding/binary"
	"net"
	"net/netip"
	"sync"
	"time"

	"golang.org/x/net/icmp"
	"golang.org/x/net/ipv4"
	"golang.org/x/net/ipv6"
)

type localICMPResult struct {
	at    time.Time
	ttl   int
	bytes int
}

type localSocketPinger struct {
	conn    net.PacketConn
	p4      *ipv4.PacketConn
	p6      *ipv6.PacketConn
	dst     netip.Addr
	target  net.Addr
	id      int
	matchID bool
	payload []byte

	mu      sync.Mutex
	waiting map[int]chan localICMPResult
	done    chan struct{}
	once    sync.Once
}

func newLocalSocketPinger(conn net.PacketConn, dst netip.Addr, target net.Addr, matchID bool, payload []byte) *localSocketPinger {
	var random [2]byte
	_, _ = rand.Read(random[:])
	p := &localSocketPinger{
		conn:    conn,
		dst:     dst,
		target:  target,
		id:      int(binary.BigEndian.Uint16(random[:])),
		matchID: matchID,
		payload: payload,
		waiting: map[int]chan localICMPResult{},
		done:    make(chan struct{}),
	}
	if dst.Is4() {
		p.p4 = ipv4.NewPacketConn(conn)
		_ = p.p4.SetControlMessage(ipv4.FlagTTL, true)
	} else {
		p.p6 = ipv6.NewPacketConn(conn)
		_ = p.p6.SetControlMessage(ipv6.FlagHopLimit, true)
	}
	go p.readLoop()
	return p
}

func (p *localSocketPinger) readLoop() {
	buf := make([]byte, 65536)
	proto := 1
	if p.dst.Is6() {
		proto = 58
	}
	for {
		var (
			n   int
			ttl int
			err error
		)
		if p.p4 != nil {
			var cm *ipv4.ControlMessage
			n, cm, _, err = p.p4.ReadFrom(buf)
			if cm != nil {
				ttl = cm.TTL
			}
		} else {
			var cm *ipv6.ControlMessage
			n, cm, _, err = p.p6.ReadFrom(buf)
			if cm != nil {
				ttl = cm.HopLimit
			}
		}
		at := time.Now()
		if err != nil {
			select {
			case <-p.done:
				return
			default:
			}
			if netErr, ok := err.(net.Error); ok && netErr.Timeout() {
				continue
			}
			return
		}
		msg, err := icmp.ParseMessage(proto, buf[:n])
		if err != nil || (msg.Type != ipv4.ICMPTypeEchoReply && msg.Type != ipv6.ICMPTypeEchoReply) {
			continue
		}
		echo, ok := msg.Body.(*icmp.Echo)
		if !ok || (p.matchID && echo.ID != p.id) {
			continue
		}
		p.mu.Lock()
		ch := p.waiting[echo.Seq]
		p.mu.Unlock()
		if ch != nil {
			select {
			case ch <- localICMPResult{at: at, ttl: ttl, bytes: len(echo.Data)}:
			default:
			}
		}
	}
}

func (p *localSocketPinger) ping(ctx context.Context, seq int) LocalPingReply {
	reply := LocalPingReply{Seq: seq}
	var kind icmp.Type = ipv4.ICMPTypeEcho
	if p.dst.Is6() {
		kind = ipv6.ICMPTypeEchoRequest
	}
	key := seq & 0xffff
	msg := icmp.Message{Type: kind, Body: &icmp.Echo{ID: p.id, Seq: key, Data: p.payload}}
	data, err := msg.Marshal(nil)
	if err != nil {
		reply.Status = localPingStatusError
		return reply
	}
	ch := make(chan localICMPResult, 1)
	p.mu.Lock()
	p.waiting[key] = ch
	p.mu.Unlock()
	defer func() {
		p.mu.Lock()
		delete(p.waiting, key)
		p.mu.Unlock()
	}()
	start := time.Now()
	if _, err = p.conn.WriteTo(data, p.target); err != nil {
		reply.Status = localPingStatus(err)
		return reply
	}
	select {
	case result := <-ch:
		reply.Status = localPingStatusOK
		reply.RTT = localPingMillis(result.at.Sub(start))
		reply.TTL = result.ttl
		reply.Bytes = result.bytes
	case <-ctx.Done():
		reply.Status = localPingStatus(ctx.Err())
	}
	return reply
}

func (p *localSocketPinger) close() {
	p.once.Do(func() {
		close(p.done)
		_ = p.conn.Close()
	})
}
