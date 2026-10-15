//go:build android && cgo

package tun

// Android 的 VpnService.setMtu 允许 1280..65535，Bettbox 沿用 9000 的默认值
// （与上游 Android 客户端一致）。
const (
	tunMtuMin     = 1280
	tunMtuMax     = 65535
	tunMtuDefault = 9000
)
