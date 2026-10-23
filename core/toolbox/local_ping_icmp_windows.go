//go:build windows

package toolbox

import (
	"context"
	"encoding/binary"
	"net"
	"net/netip"
	"syscall"
	"time"
	"unsafe"

	"github.com/metacubex/mihomo/component/dialer"
	"golang.org/x/sys/windows"
)

const (
	localPingIPSuccess         = 0
	localPingIPNetUnreachable  = 11002
	localPingIPHostUnreachable = 11003
	localPingIPTimedOut        = 11010
	localPingIPTTLExpired      = 11013
)

var (
	localPingIphlpapi       = windows.NewLazySystemDLL("iphlpapi.dll")
	localPingIcmpCreateFile = localPingIphlpapi.NewProc("IcmpCreateFile")
	localPingIcmpClose      = localPingIphlpapi.NewProc("IcmpCloseHandle")
	localPingIcmpSendEcho   = localPingIphlpapi.NewProc("IcmpSendEcho2Ex")
)

type localEchoPinger struct {
	dst     netip.Addr
	source  uint32
	payload []byte
}

func localPingSourceAddress() uint32 {
	name := dialer.DefaultInterface.Load()
	if name == "" {
		return 0
	}
	iface, err := net.InterfaceByName(name)
	if err != nil {
		return 0
	}
	addrs, err := iface.Addrs()
	if err != nil {
		return 0
	}
	for _, addr := range addrs {
		if prefix, ok := addr.(*net.IPNet); ok {
			if ip4 := prefix.IP.To4(); ip4 != nil {
				return binary.LittleEndian.Uint32(ip4)
			}
		}
	}
	return 0
}

func localPingIPStatus(code uint32) string {
	switch code {
	case localPingIPSuccess:
		return localPingStatusOK
	case localPingIPTimedOut:
		return localPingStatusTimeout
	case localPingIPNetUnreachable, localPingIPHostUnreachable, localPingIPTTLExpired:
		return localPingStatusUnreachable
	}
	return localPingStatusError
}

func (p *localEchoPinger) ping(ctx context.Context, seq int) LocalPingReply {
	reply := LocalPingReply{Seq: seq}
	timeout := localPingWait
	if deadline, ok := ctx.Deadline(); ok {
		timeout = time.Until(deadline)
	}
	if timeout <= 0 {
		reply.Status = localPingStatusTimeout
		return reply
	}
	handle, _, err := localPingIcmpCreateFile.Call()
	if handle == uintptr(windows.InvalidHandle) {
		reply.Status = localPingStatus(err)
		return reply
	}
	defer localPingIcmpClose.Call(handle)
	request := p.payload
	if len(request) == 0 {
		request = []byte{0}
	}
	header := 16 + int(unsafe.Sizeof(uintptr(0)))
	buffer := make([]byte, header+16+len(p.payload)+8+32)
	dst := p.dst.As4()
	start := time.Now()
	count, _, callErr := localPingIcmpSendEcho.Call(
		handle, 0, 0, 0,
		uintptr(p.source),
		uintptr(binary.LittleEndian.Uint32(dst[:])),
		uintptr(unsafe.Pointer(&request[0])),
		uintptr(len(p.payload)),
		0,
		uintptr(unsafe.Pointer(&buffer[0])),
		uintptr(len(buffer)),
		uintptr(timeout.Milliseconds()),
	)
	end := time.Now()
	if count == 0 {
		if errno, ok := callErr.(syscall.Errno); ok {
			reply.Status = localPingIPStatus(uint32(errno))
		} else {
			reply.Status = localPingStatusError
		}
		return reply
	}
	reply.Status = localPingIPStatus(binary.LittleEndian.Uint32(buffer[4:8]))
	if reply.Status == localPingStatusOK {
		reply.RTT = localPingMillis(end.Sub(start))
		reply.Bytes = int(binary.LittleEndian.Uint16(buffer[12:14]))
		reply.TTL = int(buffer[header])
	}
	return reply
}

func (p *localEchoPinger) close() {}

func newLocalICMPProber(dst netip.Addr, payload []byte) (localPingProber, error) {
	if dst.Is4() {
		if err := localPingIcmpSendEcho.Find(); err != nil {
			return nil, err
		}
		return &localEchoPinger{dst: dst, source: localPingSourceAddress(), payload: payload}, nil
	}
	config := net.ListenConfig{Control: dialer.ICMPControl(dst)}
	conn, err := config.ListenPacket(context.Background(), "ip6:ipv6-icmp", "::")
	if err != nil {
		return nil, err
	}
	target := &net.IPAddr{IP: dst.AsSlice(), Zone: dst.Zone()}
	return newLocalSocketPinger(conn, dst, target, true, payload), nil
}
