//go:build ohos && cgo

package main

import "C"
import (
	"context"
	bridge "core/dart-bridge"
	"core/platform"
	"core/state"
	t "core/tun"
	"encoding/json"
	"errors"
	"fmt"
	"github.com/metacubex/mihomo/component/dialer"
	"github.com/metacubex/mihomo/component/process"
	"github.com/metacubex/mihomo/constant"
	"github.com/metacubex/mihomo/dns"
	"github.com/metacubex/mihomo/listener/sing_tun"
	"github.com/metacubex/mihomo/log"
	"golang.org/x/sync/semaphore"
	"net"
	"os"
	"strconv"
	"strings"
	"sync"
	"sync/atomic"
	"syscall"
	"time"
	"unsafe"
)

type TunHandler struct {
	listener *sing_tun.Listener
	callback unsafe.Pointer

	limit *semaphore.Weighted
}

func (t *TunHandler) close() {
	_ = t.limit.Acquire(context.TODO(), 4)
	defer t.limit.Release(4)
	removeTunHook()
	if t.listener != nil {
		_ = t.listener.Close()
	}

	if t.callback != nil {
		releaseObject(t.callback)
	}
	t.callback = nil
	t.listener = nil
}

func (t *TunHandler) handleProtect(fd int) {
	_ = t.limit.Acquire(context.Background(), 1)
	defer t.limit.Release(1)

	cb := t.callback
	if cb == nil {
		return
	}

	Protect(cb, fd)
}

func (t *TunHandler) handleResolveProcess(source, target net.Addr) string {
	_ = t.limit.Acquire(context.Background(), 1)
	defer t.limit.Release(1)

	if t.listener == nil {
		return ""
	}
	var protocol int
	uid := -1
	switch source.Network() {
	case "udp", "udp4", "udp6":
		protocol = syscall.IPPROTO_UDP
	case "tcp", "tcp4", "tcp6":
		protocol = syscall.IPPROTO_TCP
	}
	if version < 29 {
		uid = platform.QuerySocketUidFromProcFs(source, target)
	}
	return ResolveProcess(t.callback, protocol, source.String(), target.String(), uid)
}

var (
	tunLock    sync.Mutex
	runTime    *time.Time
	errBlocked = errors.New("blocked")
	tunHandler atomic.Pointer[TunHandler]
)

func init() {
	dialer.DefaultSocketHook = func(network, address string, conn syscall.RawConn) error {
		if platform.ShouldBlockConnection() {
			return errBlocked
		}
		handler := tunHandler.Load()
		if handler != nil {
			return conn.Control(func(fd uintptr) {
				handler.handleProtect(int(fd))
			})
		}
		return nil
	}
}

// stopTunLocked 回收 TUN，调用方必须已持有 tunLock。
// 注意：tunLock 是普通 Mutex（不可重入），持锁时不能再调用 handleStopTun，
// 否则会自锁，之后所有 FFI 调用（如 getAndroidVpnOptions）永久挂起。
// tunStartedAt 记录最近一次 TUN 建立时间，用于判断「监听超时」是否属于预期
var tunStartedAt atomic.Int64

func markTunStarted() {
	tunStartedAt.Store(time.Now().UnixMilli())
}

// tunStartedSince 表示 since 之后是否已经有 TUN 建立（说明 fd 走了别的通道）
func tunStartedSince(since time.Time) bool {
	at := tunStartedAt.Load()
	return at > 0 && at >= since.UnixMilli()
}

func stopTunLocked() {
	runTime = nil
	handler := tunHandler.Swap(nil)
	if handler != nil {
		handler.close()
	}
}

func handleStopTun() {
	tunLock.Lock()
	defer tunLock.Unlock()
	stopTunLocked()
}

func handleStartTun(fd int, callback unsafe.Pointer) {
	tunLock.Lock()
	defer tunLock.Unlock()
	stopTunLocked()
	// 标记 TUN 已建立：其余仍在等待 fd 的桥接监听超时属于预期，不再报 Error
	defer markTunStarted()

	// fd 0/1/2 是标准输入输出，不可能是 vNIC；越小越可能是能力侧失败码
	if fd <= 2 {
		log.Warnln("[APP] handleStartTun called with invalid fd: %d", fd)
		return
	}
	if currentConfig == nil {
		log.Warnln("[APP] handleStartTun called before setupConfig")
		return
	}

	now := time.Now()
	runTime = &now
	handler := &TunHandler{
		callback: callback,
		limit:    semaphore.NewWeighted(4),
	}
	tunHandler.Store(handler)
	initTunHook()
	tunListener, err := t.Start(fd, currentConfig.General.Tun.Device, currentConfig.General.Tun.Stack, currentConfig.General.Tun.DisableICMPForwarding, uint32(currentConfig.General.Tun.MTU), currentConfig.General.IPv6, currentConfig.General.Tun.CongestionController)
	if tunListener != nil {
		log.Infoln("TUN address: %v", tunListener.Address())
		handler.listener = tunListener
	} else {
		log.Errorln("[APP] start TUN failed: %v", err)
		removeTunHook()
		tunHandler.Store(nil)
	}
}

func handleGetRunTime() string {
	if runTime == nil {
		return ""
	}
	return strconv.FormatInt(runTime.UnixMilli(), 10)
}

func initTunHook() {
	process.DefaultPackageNameResolver = func(metadata *constant.Metadata) (string, error) {
		src, dst := metadata.RawSrcAddr, metadata.RawDstAddr
		if src == nil || dst == nil {
			return "", process.ErrInvalidNetwork
		}
		handler := tunHandler.Load()
		if handler == nil {
			return "", errors.New("tun is closed")
		}
		return handler.handleResolveProcess(src, dst), nil
	}
}

func removeTunHook() {
	process.DefaultPackageNameResolver = nil
}

func handleGetAndroidVpnOptions() string {
	tunLock.Lock()
	defer tunLock.Unlock()
	if currentConfig == nil {
		log.Warnln("[APP] handleGetAndroidVpnOptions called before setupConfig")
		return ""
	}
	ipv6Address := ""
	if currentConfig.General.IPv6 {
		ipv6Address = state.DefaultIpv6Address
	}
	options := state.AndroidVpnOptions{
		Enable:                state.CurrentState.VpnProps.Enable,
		Port:                  currentConfig.General.MixedPort,
		Ipv4Address:           state.DefaultIpv4Address,
		Ipv6Address:           ipv6Address,
		AccessControl:         state.CurrentState.VpnProps.AccessControl,
		SystemProxy:           state.CurrentState.VpnProps.SystemProxy,
		AllowBypass:           state.CurrentState.VpnProps.AllowBypass,
		RouteAddress:          currentConfig.General.Tun.RouteAddress,
		RouteMode:             state.CurrentState.VpnProps.RouteMode,
		BypassDomain:          state.CurrentState.BypassDomain,
		DnsServerAddress:      state.GetDnsServerAddress(),
		DozeSuspend:           state.CurrentState.VpnProps.DozeSuspend,
		DisableIcmpForwarding: currentConfig.General.Tun.DisableICMPForwarding,
		Mtu:                   uint32(currentConfig.General.Tun.MTU),
	}
	data, err := json.Marshal(options)
	if err != nil {
		fmt.Println("Error:", err)
		return ""
	}
	return string(data)
}

func handleUpdateDns(value string) {
	go func() {
		log.Infoln("[DNS] updateDns %s", value)
		dns.UpdateSystemDNS(strings.Split(value, ","))
		dns.FlushCacheWithDefaultResolver()
	}()
}

func handleGetCurrentProfileName() string {
	if state.CurrentState == nil {
		return ""
	}
	return state.CurrentState.CurrentProfileName
}

func nextHandle(action *Action, result ActionResult) bool {
	switch action.Method {
	case getAndroidVpnOptionsMethod:
		result.success(handleGetAndroidVpnOptions())
		return true
	case updateDnsMethod:
		data := action.Data.(string)
		handleUpdateDns(data)
		result.success(true)
		return true
	case getRunTimeMethod:
		result.success(handleGetRunTime())
		return true
	case getCurrentProfileNameMethod:
		result.success(handleGetCurrentProfileName())
		return true
	}
	return false
}

//export quickStart
func quickStart(initParamsChar *C.char, paramsChar *C.char, stateParamsChar *C.char, port C.longlong) {
	i := int64(port)
	paramsString := C.GoString(initParamsChar)
	bytes := []byte(C.GoString(paramsChar))
	stateParams := C.GoString(stateParamsChar)
	go func() {
		res := handleInitClash(paramsString)
		if res == false {
			bridge.SendToPort(i, "init error")
			return
		}
		handleSetState(stateParams)
		result, _ := json.Marshal(handleSetupConfig(bytes))
		bridge.SendToPort(i, string(result))
	}()
}

//export startTUN
func startTUN(fd C.int, callback unsafe.Pointer) bool {
	handleStartTun(int(fd), callback)
	return true
}

//export getRunTime
func getRunTime() *C.char {
	return C.CString(handleGetRunTime())
}

//export stopTun
func stopTun() {
	handleStopTun()
}

//export getCurrentProfileName
func getCurrentProfileName() *C.char {
	return C.CString(handleGetCurrentProfileName())
}

//export getAndroidVpnOptions
func getAndroidVpnOptions() *C.char {
	return C.CString(handleGetAndroidVpnOptions())
}

//export setState
func setState(s *C.char) {
	paramsString := C.GoString(s)
	handleSetState(paramsString)
}

//export updateDns
func updateDns(s *C.char) {
	dnsList := C.GoString(s)
	handleUpdateDns(dnsList)
}

var (
	// 允许多个「待接收 fd」的桥接监听同时存在：每次启动用的 socket 路径都不同，
	// 扩展侧是按启动时下发的路径来投递 fd 的。旧实现会在新的一次 listenTunBridge
	// 里直接 Close 掉上一次仍在 Accept 的监听，导致那次投递必然失败
	// （日志表现为 accept ...: use of closed network connection）。每个监听都有
	// 120s 期限并自行清理，因此不需要互相关闭。
	tunBridgeListeners []net.Listener
	tunBridgeLock      sync.Mutex
)

//export listenTunBridge
func listenTunBridge(sockPathChar *C.char) C.int {
	sockPath := C.GoString(sockPathChar)
	tunBridgeLock.Lock()
	defer tunBridgeLock.Unlock()

	// '@' 开头是 Linux 抽象命名空间：没有文件，不能也不需要在文件系统里删除
	isAbstract := strings.HasPrefix(sockPath, "@")

	// 记录在案的监听会在自身结束（已投递/超时）时从切片里移除，这里无需额外清理
	if !isAbstract {
		_ = os.Remove(sockPath)
	}
	l, err := net.Listen("unix", sockPath)
	if err != nil {
		log.Errorln("[TUN Bridge] Listen error: %v", err)
		return -1
	}
	tunBridgeListeners = append(tunBridgeListeners, l)
	log.Infoln("[TUN Bridge] listening on %s (abstract=%v)", sockPath, isAbstract)

	go func(listener net.Listener, path string) {
		defer listener.Close()
		if !strings.HasPrefix(path, "@") {
			defer os.Remove(path)
		}
		defer func() {
			tunBridgeLock.Lock()
			for i, item := range tunBridgeListeners {
				if item == listener {
					tunBridgeListeners = append(tunBridgeListeners[:i], tunBridgeListeners[i+1:]...)
					break
				}
			}
			tunBridgeLock.Unlock()
		}()

		startedAt := time.Now()
		if ul, ok := listener.(*net.UnixListener); ok {
			// 系统 VPN 授权弹窗由用户决定耗时，accept 必须等到 fd 真正送来
			_ = ul.SetDeadline(time.Now().Add(120 * time.Second))
		}

		conn, err := listener.Accept()
		if err != nil {
			// fd 可能已经从另一条通道（抽象 socket）送达并建好 TUN：
			// 此时本监听的超时属于预期，用低级别日志，避免应用把核心 Error 当提示弹出
			if tunStartedSince(startedAt) {
				log.Infoln("[TUN Bridge] listener %s expired after tun already started", path)
			} else {
				log.Errorln("[TUN Bridge] Accept error: %v", err)
			}
			return
		}
		defer conn.Close()

		uconn, ok := conn.(*net.UnixConn)
		if !ok {
			log.Errorln("[TUN Bridge] not unix conn")
			return
		}

		_ = uconn.SetReadDeadline(time.Now().Add(30 * time.Second))

		buf := make([]byte, 1)
		oob := make([]byte, syscall.CmsgSpace(4))
		_, oobn, _, _, err := uconn.ReadMsgUnix(buf, oob)
		if err != nil {
			log.Errorln("[TUN Bridge] ReadMsgUnix error: %v", err)
			return
		}

		msgs, err := syscall.ParseSocketControlMessage(oob[:oobn])
		if err != nil {
			log.Errorln("[TUN Bridge] ParseSocketControlMessage error: %v", err)
			return
		}
		for _, msg := range msgs {
			fds, err := syscall.ParseUnixRights(&msg)
			if err == nil && len(fds) > 0 {
				log.Infoln("[TUN Bridge] Received valid tun fd via SCM_RIGHTS: %d", fds[0])
				handleStartTun(fds[0], nil)
				return
			}
		}
		log.Errorln("[TUN Bridge] No fd found in SCM_RIGHTS control message")
	}(l, sockPath)

	return 0
}
