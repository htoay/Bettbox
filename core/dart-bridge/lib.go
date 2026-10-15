//go:build cgo

package dart_bridge

/*
#include <stdlib.h>
#include "stdint.h"
#include "include/dart_api_dl.h"
#include "include/dart_api_dl.c"
#include "include/dart_native_api.h"

bool GoDart_PostCObject(Dart_Port_DL port, Dart_CObject* obj) {
  return Dart_PostCObject_DL(port, obj);
}
*/
import "C"
import (
	"fmt"
	"sync"
	"unsafe"
)

func InitDartApi(api unsafe.Pointer) {
	if C.Dart_InitializeApiDL(api) != 0 {
		panic("failed to create dart bridge")
	} else {
		fmt.Println("Dart Api DL is initialized")
	}
}

// ---------------------------------------------------------------------------
// 远程（remote）模式
//
// 鸿蒙 release 下 VPN 扩展处于隔离 SELinux 域，无法把 TUN fd 交给主进程；
// 按官方架构把 Go 核心放进扩展进程后，扩展进程里**没有 Dart VM**，
// Dart_PostCObject 不可用。因此提供一种「缓冲模式」：
//   · 所有本应发往 Dart 端口的结果/事件改为写入内存队列；
//   · 由扩展侧的 RPC 服务轮询 PollEvents() 取走并按请求 id 回给主进程。
// 主进程（有 Dart VM）保持原有行为，仅在显式调用 SetRemoteMode(true) 时切换。
// ---------------------------------------------------------------------------

const remoteEventLimit = 2048

var (
	remoteMode   bool
	remoteMutex  sync.Mutex
	remoteEvents []string
)

func SetRemoteMode(on bool) {
	remoteMutex.Lock()
	defer remoteMutex.Unlock()
	remoteMode = on
	if !on {
		remoteEvents = nil
	}
}

func IsRemoteMode() bool {
	remoteMutex.Lock()
	defer remoteMutex.Unlock()
	return remoteMode
}

func appendRemoteEvent(msg string) {
	remoteMutex.Lock()
	defer remoteMutex.Unlock()
	if len(remoteEvents) >= remoteEventLimit {
		// 丢最旧的，避免扩展进程被核心日志拖垮内存
		remoteEvents = remoteEvents[1:]
	}
	remoteEvents = append(remoteEvents, msg)
}

// PollEvents 取走并清空缓冲的事件（JSON 字符串数组）
func PollEvents() []string {
	remoteMutex.Lock()
	defer remoteMutex.Unlock()
	if len(remoteEvents) == 0 {
		return nil
	}
	events := remoteEvents
	remoteEvents = nil
	return events
}

func SendToPort(port int64, msg string) bool {
	if IsRemoteMode() {
		appendRemoteEvent(msg)
		return true
	}
	var obj C.Dart_CObject
	obj._type = C.Dart_CObject_kString
	msgString := C.CString(msg)
	defer C.free(unsafe.Pointer(msgString))
	ptr := unsafe.Pointer(&obj.value[0])
	*(**C.char)(ptr) = msgString
	isSuccess := C.GoDart_PostCObject(C.Dart_Port_DL(port), &obj)
	if !isSuccess {
		return false
	}
	return true
}
