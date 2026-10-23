# 上游合并记录（2026-10-23）：Bettbox v1.19.6 → v1.19.7 → 鸿蒙移植分支

## 1. 上游本次发布内容

| 项 | 说明 |
|---|---|
| 上游仓库 | `https://github.com/appshubcc/Bettbox.git`（remote `upstream`，只读）|
| 变化 | `9582976d`（v1.19.6）→ `5df714e0`（v1.19.7）|
| 新增提交 | **26 个**（含上一版遗留未同步的 4 个）|
| 规模 | 264 个文件变更（+50815 / −7655）|
| 共同祖先 | 上次合并落点 `9582976d`（正好是 v1.19.6）|
| 是否含鸿蒙实现 | **否**。`ohos/**`、`scripts/**`、`third_party/**` 上游零改动 |
| 标签 | 新增 `v1.19.7`、`v1.19.7-pre1`；`v1.19.7-test` 被上游移到主线历史 |

### 1.1 新增能力

- **网络工具箱**：全新页面（移动端在「更多」菜单），含 IP 查询、本地 Ping、路由跟踪、
  NAT 类型测试、DNS 查询、MRS 规则查询、iPerf3 内网测速、AGE 加密工具、网页测速等
  工具卡片；Go 侧新增 `core/toolbox/`（STUN、iPerf3、Speedtest、探活等，约 1500 行），
  经核心 FFI 通道调用，鸿蒙无需平台通道。
- **网页测速服务器选择**：支持自动选择或手动指定 Speedtest 服务器、出站与协议
  （HTTP/3 → HTTP/2 → HTTP/1.1 回退）、多线程连接数，并提供测速历史（保留 14 天）。
- **自动备份**：配置变更防抖后经 WebDAV 自动备份；备份页新增自动化开关。
- **TUN dns-mode**：TUN 配置支持 dns-mode 选择；仪表盘运行状态胶囊引入
  `realTunEnable`（运行中核心的真实 TUN 状态）参与点亮判定。
- **核心面板动态取色**：可从核心配置的调色板提取主题色（`lib/common/color.dart`）。

### 1.2 重构与优化

- **仪表盘重设计**：卡片系统重写（可增删、调大小、分组变体），「活跃连接」卡片新增
  TCP/UDP 分类与历史柱状图；「请求」页并入「连接」页（`requests.dart` 删除）。
- **核心运行时加固**：`core/action.go` / `hub.go` / `common.go` / `constant.go` 调整；
  Clash.Meta 子树更新（sudoku 传输重写、httpmask 拆分等）。
- **连接与代理**：媒体解锁检测改进；代码上「DNS 节点覆盖」整块移除（−687 行）。
- **Code Forge**：编辑器高亮与交互细节优化（Rust `plugins/code_forge/rust` 与 Dart 两侧）。
- **桌面端**：Linux 系统 DNS 管理（nmcli 设置/还原，取代旧的 TUN 路由排除补丁）、
  Windows 便携模式改进、macOS Dock 图标随窗口同步、按需关闭 Impeller。

### 1.3 上一版遗留 4 提交的处理

1. `8ce0b280` — README 文案微调：随本次合并带入（`README.md` 冲突取鸿蒙版）。
2. `cee22bbc` — Linux 系统 DNS 管理：**同步**。涉及 `system.dart` / `core/patch.go` /
   `providers/state.dart` 的平台判断已按鸿蒙语义复评（见 2.1）。
3. `4bd7a21d` — macOS Dock 图标同步：macOS 专属，随合并带入，无鸿蒙影响。
4. `7006a026` — 版本号 bump：本次同步后鸿蒙版本号对齐 `1.19.7+2026102201`。

## 2. 鸿蒙端同步内容

### 2.1 上游改动在鸿蒙端的适配

- **运行状态胶囊**：沿用「是否移动端」判定 VPN 形态（`system.isMobile`），吸收上游
  `realTunEnable` 参与点亮条件（`isVpn || realTunEnable`，移动端 VPN 语义下恒真，
  桌面端保持上游精确语义）；鸿蒙仍隐藏系统代理胶囊。
- **仪表盘保存/尺寸**：上游以 `_saveWidgets` / `_currentSizes` 取代旧 `_handleSave`，
  移动端归并判断由 `isAndroid` 放宽为 `isMobile`（三处）。
- **网络设置**：`AutoSetSystemDns` 采纳上游扩展（macOS → macOS+Linux）；
  Strict Route 维持桌面端展示（移动端 VPN 语义不适用）。
- **连接卡片**：上游改为取整份连接列表统计 TCP/UDP 分类；鸿蒙侧轻量接口由
  `getConnectionsCount()`（仅计数）扩展为 `getConnectionsStats()`（计数 + 分类，
  直接在原始 JSON 上正则统计），仍不每 2s 建 isolate 反序列化。
- **Go 平台补丁**：上游移除 Linux TUN 路由排除机制（`tunRouteExcludeSet` /
  `patchForLinux`，被 nmcli DNS 管理取代），鸿蒙侧随删——该路径在鸿蒙构建中
  本来就不生效（`patchAndroidLike=true` ⇒ `patchForLinux` 恒 false）；
  `patchAndroidLike` 编译期补丁（`patch_platform_mobile.go` / `patch_platform_other.go`）保留。
- **工具箱**：入口走通用导航（移动端「更多」菜单）；页面零平台通道调用，
  iPerf 的 Android 局域网扫描在鸿蒙自然降级为服务端模式；Go 侧随 `core/toolbox/`
  一并编入 `libmeta.so`。
- **既有鸿蒙增量迁移**：系统字体族 `HarmonyOS Sans` + `SpaceFix` 回退、长时任务保活、
  底部导航触感门控、异常退出恢复（`is_vpn_running` 标记 + `system.isMobile` 检测）、
  动态取色的鸿蒙门控（无 `dynamic_color` 实现）等均随新结构保留。

### 2.2 生成物与依赖

- **arb 七语言取两侧键并集**：上游新增键（工具箱/测速约 90 键、`script` 等）全量带入，
  鸿蒙 11 个自有键（`descOhos`、`backgroundTask*`、分应用代理手动添加等）保留；
  `intl_utils` 用鸿蒙工具链重新生成。
- **freezed/json/riverpod 生成物**：`build_runner` 用鸿蒙工具链重新生成（含新增的
  toolbox / speed_test / stun_test / iperf / local_ping 模型）；`VpnProps` 鸿蒙自有字段
  保留。生成器仍为钉定的 `freezed 4.0.0-dev.3`（正式版要求 Dart ≥3.13，鸿蒙工具链
  为 3.12.2），生成风格与上游略有差异属预期。
- **依赖**：上游新增 `shared_preferences_platform_interface`（直接依赖，纯 Dart 接口包，
  鸿蒙无碍）、`archive` 约束升至 `^4.5.1`（纯 Dart）。`material_ui 1.2.0` /
  `cupertino_ui 1.0.2` 垫片、FRB 2.13.0、`pubspec_overrides.yaml` 的 OHOS fork 覆盖
  （shared_preferences / path_provider）保持不变。
- **版本对齐上游**：`1.19.7+2026102201`（应用内 `versionName 1.19.7` /
  `versionCode 2026102201`）。

### 2.3 原生库

- `libmeta.so`：随 `core/toolbox/`、Clash.Meta 更新与 go.mod 新依赖
  （`github.com/appshubcc/go-iperf3 v0.1.0`）重建。
- `libcode_forge.so`：Rust 侧本轮有改动（`plugins/code_forge/rust/src/editor`），
  FRB content hash 变化，随重建。

## 3. 发布产物

- HAP：`bettbox-1.19.7-ohos-vc2026102201-unsigned.hap` + 同名 `.sha256`
  （arm64-v8a，release，`APP_ENV=stable`；命名与校验规则见 `release_process_ohos.md`）。
- 发布标签：`ohos-v1.19.7`（指向发布快照提交）。

## 4. 未同步的上游提交（下一版处理）

1. `1fb8806f` — README 文案微调（无代码影响）。
