//go:build !android && !ohos

package main

// 桌面（linux/darwin/windows）与 iOS 等：非「Android 同类」平台。
// 与 patch_platform_mobile.go 互补，保证任何 GOOS 组合下
// patchAndroidLike 都有定义（含 darwin/windows，二者两个标签都不命中 android||ohos）。
const patchAndroidLike = false
