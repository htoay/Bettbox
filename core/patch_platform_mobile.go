//go:build android || ohos

package main

// 鸿蒙端以 GOOS=linux + `-tags ohos` 构建（ohos 不是 Go 已知 GOOS），
// runtime.GOOS 得到的是 "linux"，无法据此区分鸿蒙与桌面 Linux。
// 因此用构建标签给出编译期常量：鸿蒙与 Android 同属「非特权移动端」，
// 需要相同的配置改写（DNS listen :53→:10053、NTP 不写系统）。
// 见 core/patch.go 的 patchForAndroid / patchForLinux。
const patchAndroidLike = true
