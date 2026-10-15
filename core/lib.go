//go:build cgo

package main

/*
#include <stdlib.h>
*/
import "C"
import (
	bridge "core/dart-bridge"
	"encoding/json"
	"unsafe"
)

var messagePort int64 = -1

//export initNativeApiBridge
func initNativeApiBridge(api unsafe.Pointer) {
	bridge.InitDartApi(api)
}

//export attachMessagePort
func attachMessagePort(mPort C.longlong) {
	messagePort = int64(mPort)
}

//export getTraffic
func getTraffic() *C.char {
	return C.CString(handleGetTraffic())
}

//export getTotalTraffic
func getTotalTraffic() *C.char {
	return C.CString(handleGetTotalTraffic())
}

//export setRemoteMode
func setRemoteMode(on C.int) {
	// 鸿蒙 release：核心跑在 VPN 扩展进程里，进程内没有 Dart VM，
	// 结果与事件改为写入内存队列，由扩展侧 RPC 服务轮询取走。
	bridge.SetRemoteMode(on != 0)
}

//export invokeActionBuffered
func invokeActionBuffered(paramsChar *C.char) {
	// 与 invokeAction 相同，但结果不投递到 Dart 端口，而是进入缓冲队列；
	// 调用方按 ActionResult.Id 在 pollEvents() 里取回。
	params := C.GoString(paramsChar)
	var action = &Action{}
	if err := json.Unmarshal([]byte(params), action); err != nil {
		bridge.SendToPort(0, err.Error())
		return
	}
	result := ActionResult{
		Id:     action.Id,
		Method: action.Method,
		Port:   0,
	}
	go handleAction(action, result)
}

//export pollEvents
func pollEvents() *C.char {
	events := bridge.PollEvents()
	if len(events) == 0 {
		return C.CString("[]")
	}
	data, err := json.Marshal(events)
	if err != nil {
		return C.CString("[]")
	}
	return C.CString(string(data))
}

//export freeCString
func freeCString(s *C.char) {
	C.free(unsafe.Pointer(s))
}

func (result ActionResult) send() {
	data, err := result.Json()
	if err != nil {
		return
	}
	bridge.SendToPort(result.Port, string(data))
}

//export invokeAction
func invokeAction(paramsChar *C.char, port C.longlong) {
	params := C.GoString(paramsChar)
	i := int64(port)
	var action = &Action{}
	err := json.Unmarshal([]byte(params), action)
	if err != nil {
		bridge.SendToPort(i, err.Error())
		return
	}
	result := ActionResult{
		Id:     action.Id,
		Method: action.Method,
		Port:   i,
	}
	go handleAction(action, result)
}

func sendMessage(message Message) {
	if !bridge.IsRemoteMode() && messagePort == -1 {
		return
	}
	result := ActionResult{
		Method: messageMethod,
		Port:   messagePort,
		Data:   message,
	}
	result.send()
}

//export getConfig
func getConfig(s *C.char) *C.char {
	paramsString := C.GoString(s)
	var params GetConfigParams
	err := json.Unmarshal([]byte(paramsString), &params)
	if err != nil {
		params.Path = paramsString
	}
	config, err := handleGetConfig(&params)
	if err != nil {
		return C.CString("")
	}
	marshal, err := json.Marshal(config)
	if err != nil {
		return C.CString("")
	}
	return C.CString(string(marshal))
}

//export startListener
func startListener() {
	handleStartListener()
}

//export stopListener
func stopListener() {
	handleStopListener()
}

//export suspend
func suspend(suspended C.int) {
	handleSuspend(int(suspended))
}
