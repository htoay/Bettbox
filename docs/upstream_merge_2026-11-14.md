# 上游合并记录（2026-11-14）：Bettbox v1.19.7 → v1.19.8 → 鸿蒙移植分支

## 1. 上游本次发布内容

| 项 | 说明 |
|---|---|
| 上游仓库 | `https://github.com/appshubcc/Bettbox.git`（remote `upstream`，只读）|
| 变化 | `5df714e0`（v1.19.7）→ `88b9597a`（v1.19.8）|
| 新增提交 | **26 个** |
| 规模 | 699 个文件变更（+55472 / −11769）|
| 共同祖先 | 上次合并落点 `5df714e0`（正好是 v1.19.7）|
| 是否含鸿蒙实现 | **否**。`ohos/**`、`scripts/**`、`third_party/**` 上游零改动 |
| 标签 | 新增 `v1.19.8`、`v1.19.8-pre1`、`v1.19.8-test`；上游 main 曾被强制更新，v1.19.8 为现行主线 |

### 1.1 新增能力

- **订阅用量展示**：订阅的上/下载量、总量与到期时间在配置页与仪表盘
  profile 卡片展示（`lib/models/profile_usage.dart`）。
- **IP 风险检测**：工具箱 IP 查询与详情弹窗展示 IP 风险项，支持详情展开与
  风险提示开关（`ipRiskDetail` / `ipRiskAlert` 设置）。
- **流量统计**：核心侧 `core/toolbox/traffic_stats.go`（约 1500 行含测试），
  经 FFI 通道在工具箱页展示分维度统计，鸿蒙无需平台通道。
- **配置合并与托管脚本**：多个订阅合并为一个配置（provider 扩容）；
  内置托管脚本 `managed.js` + 路由表 `routing.json`，带版本升级检查
  （`checkManagedScriptVersionUpgrade`）。
- **lite core 版本**：上游引入 `AppIdentity.isLite` 精简核心变体（TUN stack
  钉 mips、隐藏部分设置项）；鸿蒙发标准核心，`isLite` 恒 false。
- **核心（Mihomo/Clash.Meta）更新**：TUN IPv6（`core/tun_ipv6.go`）、
  bettbox 规则集常量与 RULE-SET 引用重写等。
- **扫码页相机权限修复**：权限判定改由 `controller.value.error` 驱动。

### 1.2 重构与优化

- **主题重构**：`_themeOf` + `_buildTheme` + 亮度级主题缓存，动态取色改为
  `genColorSchemeProvider`；`dns_override` 卡片删除，`pureBlack` 设置移除。
- **DNS 设置页移除**（`lib/views/config/dns.dart` −924 行）：设置项并入
  网络/工具页，`AutoSetSystemDnsItem` 连同 arb 键一并删除；
  `getLocalIpAddresses` / `getLocalGateways` 从 Service 迁到 Vpn。
- **连接卡片**：上游改用 `getConnectionsSummary()`（完整反序列化）。
- **smart auto stop 重写**：`NetworkMatcher.shouldStop` + 网络标识 override
  机制；`smartStop` / `smartResume` / `setSmartStopped` 退役，改
  `isSmartStopped` / `requestSmartAutoStopCheck`。
- **平台图标换 route SVG**：媒体平台图标从位图/内联改为 `assets/route_svg/`。
- 桌面端：Windows 助手与托盘改进、Linux 进程图标走 GTK icon theme。
- Code Forge 视口 delegate 泄漏修复；依赖升级（flutter_svg 2.3.2、
  restart_app 1.10.2 等，热键插件改为仓库内 path 依赖）。

## 2. 鸿蒙端同步内容

### 2.1 上游改动在鸿蒙端的适配

- **Android 桌面小组件**（上游 `80960832`/`fb4abf43`）：AndroidManager 在
  鸿蒙上共用（isMobile 分支），小组件接线（`onHomeWidgetAction` /
  `onHomeWidgetsChanged` / `_syncHomeWidgets`）按 `system.isAndroid` 门控，
  避免鸿蒙调用不存在的 Android 通道（MissingPluginException）。
- **连接卡片**：维持鸿蒙轻量 `getConnectionsStats()`（原始 JSON 正则计数 +
  分类，不建 isolate），不采纳上游 `getConnectionsSummary()`。
- **smart auto stop**：采纳上游 override / `NetworkMatcher.shouldStop` 新
  逻辑；移动端 IP/网关仍走原生通道（方法随上游迁移改从 `Vpn` 调用）。
- **主题**：整体采纳 `_themeOf` / `_buildTheme` / `genColorSchemeProvider`
  新结构；鸿蒙两处字体修复加回 `_buildTheme` —— 显式系统族名
  `HarmonyOS Sans`（未开「字体修复」时）与 `SpaceFix` + Twemoji
  `fontFamilyFallback`（空格/数字不被 emoji 字体接管）。
- **网络设置**：VPN 重启提示抽为 `showVpnRestartTip()` 并按 isMobile 门控；
  Strict Route、DnsHijack 保持桌面端展示；`AutoSetSystemDnsItem` 随上游移除
  （isMacOS/isLinux 在鸿蒙恒 false，零行为影响）。
- **切网清 DNS 缓存**：上游删除了该设置，鸿蒙保留 —— `AppSettingProps`
  恢复自有字段 `flushDnsOnNetworkChange`，工具页/其它设置入口保留。
- **扫码页**：上游重构权限流程移除了 `_permissionChecking`，鸿蒙原生 Scan Kit
  路径仍依赖它（原生返回前不挂 MobileScanner），恢复字段与占位门控。
- **异常退出恢复**：鸿蒙沿用 `applyProfile(silence: true)`（isMobile 分支），
  Android 新增的 `is_vpn_running` 标记清理并存为独立 isAndroid 分支。
- **Go 平台补丁**：`patchAndroidLike` 编译期补丁保留；吸收上游 bettbox
  规则集常量与 RULE-SET 引用正则。
- **仪表盘/配置页归并判断**：`dashboardWidgetsSafeFromJson` 上游新结构内置
  未知枚举容错（`?_dashboardWidgetNames`），归并判断沿用 isMobile；
  profiles 页列数判断同。

### 2.2 生成物与依赖

- **arb 七语言取两侧键并集**：上游全量增删 + 鸿蒙 11 个自有键
  （`descOhos`、`backgroundTask*`、分应用代理手动添加等）；上游删除的 DNS
  页键按并集保留（未用访问器不影响编译，部分键仍被鸿蒙流程引用）。
  intl_utils 用鸿蒙工具链重新生成。
- **freezed/json 生成物**：build_runner 用鸿蒙工具链重新生成，含上游新增的
  home_widget / traffic_stats 模型；AppSettingProps 鸿蒙自有字段
  `flushDnsOnNetworkChange` 保留。生成器仍为钉定的 `freezed 4.0.0-dev.3`
  （正式版要求 Dart ≥3.13，鸿蒙工具链为 3.12.2）。
- **依赖**：上游常规依赖升级照收（flutter_svg/crypto/wakelock_plus/
  synchronized/restart_app）；material_ui / cupertino_ui 维持鸿蒙垫片钉定
  （上游 ^1.8.0 / ^1.1.4 要求 Dart ^3.13）；build_runner 2.15.1 /
  freezed 4.0.0-dev.3 维持（上游 2.16.2 / 4.0.3 同样要求 Dart ≥3.13）；
  热键插件采纳上游 `plugins/hotkey_manager_linux` path 形式。
- **版本对齐上游**：`1.19.8+2026111101`（应用内 `versionName 1.19.8` /
  `versionCode 2026111101`）。

### 2.3 原生库

- `libmeta.so`：随 `core/toolbox/traffic_stats.go`、Clash.Meta 更新与
  profile merge 相关 Go 改动重建。
- `libcode_forge.so`：Rust 侧无实质改动则不重建（frb content hash 不变）。

## 3. 发布产物

- HAP：`bettbox-1.19.8-ohos-vc2026111101-unsigned.hap` + 同名 `.sha256`
  （arm64-v8a，release，`APP_ENV=stable`；命名与校验规则见 `release_process_ohos.md`）。
- 发布标签：`ohos-v1.19.8`（指向发布快照提交）。
