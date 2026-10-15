//go:build ohos && cgo

package tun

// 鸿蒙系统的 VPN vNIC MTU 由 @ohos.net.vpnExtension.VpnConfig.mtu 决定，
// 官方声明取值范围为 [576,1500]（BettboxVpnAbility 已按同一区间夹取）。
// Go 侧的用户态协议栈必须使用同一 MTU，否则协议栈会按更大的 MTU 组包，
// 超过 vNIC MTU 的报文会被内核丢弃（UDP/QUIC 与非用户态终止的流量尤其明显）。
const (
	tunMtuMin     = 576
	tunMtuMax     = 1500
	tunMtuDefault = 1500
)
