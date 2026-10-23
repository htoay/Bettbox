//go:build !windows

package toolbox

import (
	"net"
	"net/netip"
	"os"
	"runtime"

	"github.com/metacubex/mihomo/component/dialer"
	"golang.org/x/sys/unix"
)

const localPingStripHeader = 0x17

func newLocalICMPProber(dst netip.Addr, payload []byte) (localPingProber, error) {
	family, proto, network := unix.AF_INET, unix.IPPROTO_ICMP, "ip4"
	if dst.Is6() {
		family, proto, network = unix.AF_INET6, unix.IPPROTO_ICMPV6, "ip6"
	}
	dgram := true
	fd, err := unix.Socket(family, unix.SOCK_DGRAM, proto)
	if err != nil {
		raw, rawErr := unix.Socket(family, unix.SOCK_RAW, proto)
		if rawErr != nil {
			return nil, err
		}
		fd, dgram = raw, false
	}
	unix.CloseOnExec(fd)
	file := os.NewFile(uintptr(fd), "icmp")
	defer file.Close()
	raw, err := file.SyscallConn()
	if err != nil {
		return nil, err
	}
	if err := dialer.ICMPControl(dst)(network, dst.String(), raw); err != nil {
		return nil, err
	}
	if dgram {
		var bindErr error
		_ = raw.Control(func(fd uintptr) {
			if dst.Is4() {
				if runtime.GOOS == "darwin" || runtime.GOOS == "ios" {
					_ = unix.SetsockoptInt(int(fd), unix.IPPROTO_IP, localPingStripHeader, 1)
				}
				bindErr = unix.Bind(int(fd), &unix.SockaddrInet4{})
			} else {
				bindErr = unix.Bind(int(fd), &unix.SockaddrInet6{})
			}
		})
		if bindErr != nil {
			return nil, bindErr
		}
	}
	conn, err := net.FilePacketConn(file)
	if err != nil {
		return nil, err
	}
	var target net.Addr = &net.IPAddr{IP: dst.AsSlice(), Zone: dst.Zone()}
	if dgram {
		target = &net.UDPAddr{IP: dst.AsSlice(), Zone: dst.Zone()}
	}
	linuxDgram := dgram && (runtime.GOOS == "linux" || runtime.GOOS == "android")
	return newLocalSocketPinger(conn, dst, target, !linuxDgram, payload), nil
}
