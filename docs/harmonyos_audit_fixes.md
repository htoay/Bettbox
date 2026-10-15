# Bettbox 鸿蒙端问题排查、TLS 根因与修复记录

> 记录时间：2026-09-27 ｜ 对应代码：`docs/harmonyos_port_plan.md` 所述移植分支（未提交改动）
> 排查方式：静态审计（`lib/**`、`ohos/**`、`core/**`、Android 端对照）、重新编译 Go 核心、`dart analyze`、ArkTS 编译（hvigor 出 HAP）。
> 真机：本次环境无鸿蒙设备（`hdc list targets` 为空），所有结论标注「代码级证明」或「需真机确认」。

---

## 0. 结论速览

### 0.1 「有些网站有 TLS 问题」根因排序

| 排序 | 根因 | 置信度 | 是否已修 |
|---|---|---|---|
| C1 | 鸿蒙端从未把设备真实 DNS 下发给核心，`system` 解析器为空后**回退到内置的 `114.114.114.114:53` + `8.8.8.8:53`**（明文 UDP、直连），被墙域名拿到污染/伪造地址 ⇒ 该域名 TLS 握手/证书失败，其它域名正常 | 高（代码级证明 + 机制完整）| ✅ 已修 |
| C2 | 核心侧 `crypto/x509` 在鸿蒙（GOOS=linux）搜索不到系统根证书 ⇒ 核心自身 HTTPS 全线校验失败（DoH 解析 `proxy-server-nameserver`、`rule-providers` 拉取、TLS 节点校验）⇒ 规则集缺失导致部分站点走直连 | 中高（代码级证明）| ✅ 已修（补证书路径）|
| C3 | vNIC MTU 越界：官方要求 `[576,1500]`，应用默认下发 9000（Android 惯例），核心协议栈也按 9000 建栈 | 中（越界为实，症状为推断）| ✅ 已修 |
| C4 | `isIPv6Accepted:false` 硬编码，核心侧却可能启用 IPv6 ⇒ 双栈/AAAA 优先的站点绕过隧道（直连被 SNI 阻断 ⇒ 表现为 TLS 失败）| 中 | ✅ 已修 |
| C5 | Go 运行时 TLS 槽位补丁（TP+8）——**已证伪为 TLS 根因**，附证据 | — | 保留（见 §4.8）|
| C6 | 其它：`protectProcessNet` 失败静默降级、`extensionProcessMode` 非法值、fd 交接竞态 | 低（与 TLS 无直接关系）| ✅ 已修 |

### 0.2 关键机制：为什么是「部分网站」

代理客户端不会破坏站点证书（不做 MITM），能让**同一浏览器、同一节点**出现「有的站正常、有的站 TLS 报错」的只有三条路：
1. **解析到错误的地址**（DNS 污染/回退到不可信解析器）——客户端拿到伪造 A 记录，SNI 正确但目标错误；
2. **流量根本没进隧道**（IPv6 泄漏/路由未接管）——直连后被链路阻断；
3. **字节级损坏/大包丢弃**（MTU、协议栈）。

本次排查在 1、2、3 三条上都找到了鸿蒙端的真实缺陷；其中 **1 是唯一同时满足「按域名区分」「与 Android 行为分叉」两条的机制**，故列为首因。

---

## 1. C1 详细：DNS 回退导致部分域名解析污染

### 1.1 代码链路（全部为仓库内证据）

1. 鸿蒙构建把通用实现排除、替换成「只能被 Dart 填充」的实现：
   - `core/Clash.Meta/dns/system_common.go`：`//go:build !android` → `!android && !ohos`（通用 `/etc/resolv.conf` 路径被排除）；
   - `core/Clash.Meta/dns/patch_ohos.go`：`systemClient.getDnsClients()` 直接返回包级变量 `systemResolver`；
   - `systemResolver` **只有** `UpdateSystemDNS()` 会写（`core/Clash.Meta/dns/patch_android.go` 同款）。
2. 列表为空时核心静默改用内置公共 DNS：
   - `core/Clash.Meta/dns/system.go`：`init()` 里 `defaultNS = transform([114.114.114.114:53, 8.8.8.8:53])`；
   - 同文件 `ExchangeContext`：`len(dnsClients) == 0 && len(defaultNS) > 0` 时改用 `defaultNS`（无告警）；
   - `core/Clash.Meta/dns/util.go` 的 `batchExchange` 用 `picker` 竞速，**首个成功响应获胜**：国内 114 最先应答，8.8.8.8 不可达 ⇒ 被墙域名拿到 114 的污染应答。
3. 鸿蒙端没有任何调用者（Android 有）：
   - Android：`android/app/src/main/kotlin/com/appshub/bettbox/plugins/VpnPlugin.kt` 注册 `NET_CAPABILITY_NOT_VPN` 的 `NetworkCallback`，取**物理网络**的 `linkProperties.dnsServers` → `invokeDart("dnsChanged", dns)` → Dart `clashLibHandler.updateDns()` → `UpdateSystemDNS()`；
   - 鸿蒙：修复前 `ohos/entry/src/main/ets/plugins/*.ets` 中 `grep dnsChanged|onDnsChanged` = 0 命中；`lib/main.dart:189` 的 `onDnsChanged` 挂在 `'vpn'` 通道上，而该通道的 Dart 入口 `Vpn? get vpn => globalState.isService ? Vpn() : null` 在鸿蒙恒为 `null`（无独立 service 进程）⇒ 即使原生推送也收不到。
4. 哪些域名真的会走 `system`：
   - 默认配置 `lib/models/clash_config.dart` 的 `nameserver-policy` 含 `'geosite:private': 'system'`；`'*': 'system'` 这一条**实测不生效**（见 §1.4），因此普通域名走 `nameserver: ['1.1.1.1']`；
   - 关闭 DNS 时应用会追加 `system://`（`lib/state.dart:825-827`）；用户/机场配置里显式写 `system`、`system://` 或依赖 `geosite:private`（局域网/内网域名）时同样命中；
   - 另外 `proxy-server-nameserver` 默认是 DoH（见 C2），DoH 失败后回落链路同样受污染影响。

### 1.2 已实施的修复

| 位置 | 改动 |
|---|---|
| `ohos/.../plugins/VpnPlugin.ets` | 新增 `@ohos.net.connection` 网络回调（`NET_CAPABILITY_INTERNET` + `NET_CAPABILITY_NOT_VPN`，仅物理承载），变化时向 `'service'` 通道推 `networkChanged`；新增 `getSystemDns`，把**物理网络**的 DNS 以 `ip:53` / `[v6]:53` 形式返回（严格排除 vNIC 自身 `198.51.100.2`，避免解析回环）|
| `ohos/.../plugins/VpnPlugin.ets` | 新增 `getLocalIpAddresses` / `getLocalGateways`（物理网络地址与默认网关），替代原来的空数组桩 |
| `lib/plugins/service.dart` | 新增 `pushSystemDns()`：调用 `getSystemDns` → `ClashOhosLib().updateDns()`（FFI → `UpdateSystemDNS`）；收到 `networkChanged` 时自动重推 |
| `lib/state.dart` `handleStart()` | 启动核心前先 `pushSystemDns()`，保证首个解析请求前系统 DNS 已在核心内 |
| `ohos/entry/src/main/module.json5` | 声明 `ohos.permission.GET_NETWORK_INFO`（读取物理网络信息所需）|

### 1.3 真机验证（建议按序执行）

```bash
# 1) 是否还在用内置公共 DNS（修复前会命中，修复后应只有真实 DNS）
hdc shell hilog | grep -iE "Clash|mihomo|Bettbox" | grep -E "114\.114\.114\.114|8\.8\.8\.8"
# 2) 是否已下发系统 DNS（修复后应出现）
hdc shell hilog | grep -iE "\[DNS\] updateDns|pushSystemDns|system dns:"
# 3) 复现失败站点时，在「连接」页记录目标 IP，与 PC 上 nslookup 对比：
#    拿到明显异常/无法归属的 IP ⇒ 解析污染确认
```

单变量实验（用于交叉验证）：设置 → DNS，把 `fake-ip-filter` 里的 `'*'` 去掉（或模式改 `whitelist`）让 fake-ip 生效，同时开启嗅探器（TLS `override-destination`）。若失败站点恢复，则 C1 成立。

### 1.4 与并行排查结论的差异（重要）

并行排查曾判断 `nameserver-policy` 的 `'*': 'system'` 会让**所有**域名走 `system`。本仓库实测**不成立**：`core/Clash.Meta/component/trie` 的 `DomainTrie` 中，单独一个 `*` 标签只在查询域名为字面 `"*"` 时命中（用 `go run` 探针验证：`Search("www.google.com") -> nil`）。因此默认配置下普通域名走 `nameserver: ['1.1.1.1']`，`'*'` 属于**无效配置项**（建议后续清理，见 §4.9）。这一点让 C1 的影响面从「全部域名」缩小为「命中 `system`/`system://` 的域名」，但机制与修复方向不变。

---

## 2. C2 详细：核心侧根证书库缺失

- Go 在 `GOOS=linux` 下只搜索 `/etc/ssl/certs/ca-certificates.crt`、`/etc/pki/...` 等路径；Android 专属的 `/system/etc/security/cacerts` 仅在 `goos.IsAndroid == 1` 时追加（`/usr/lib/go/src/crypto/x509/root_linux.go`）。鸿蒙用 `GOOS=linux`，因此这些路径**不会**被搜索。
- 鸿蒙应用沙箱通常不提供上述 Linux 路径 ⇒ `x509.SystemCertPool()` 得到空池（`core/Clash.Meta/component/ca/config.go`），核心发起的 HTTPS 全部校验失败：
  - `dns.proxy-server-nameserver: ['https://120.53.53.53/dns-query#DIRECT']`（应用默认）→ DoH 不可用；
  - `rule-providers` / 订阅型规则集的 `type: http(s)` 拉取失败 ⇒ 规则缺失 ⇒ 部分站点按 MATCH 走直连 ⇒ 在受限网络下表现为「打不开/TLS 失败」；
  - 带证书校验的 TLS 节点、延迟测试同样受影响。
- 修复：`scripts/ohos_build.py` 的 Go overlay 新增 `src/crypto/x509/zz_ohos_roots.go`，把鸿蒙/Android 风格证书目录追加进 `certDirectories` / `certFiles`（`zz_` 前缀保证 init 顺序在后，缺失路径自动跳过）。
- 已重建核心并在产物中确认路径生效：
  ```bash
  strings ohos/entry/libs/arm64-v8a/libmeta.so | grep security/cacerts   # 命中
  llvm-readelf -r ohos/entry/libs/arm64-v8a/libmeta.so | grep TLS_TPREL # 0（校验通过）
  ```
- 真机验证：`hdc shell "ls -l /etc/ssl/certs /system/etc/security/cacerts"`；触发订阅/规则更新与节点测速，日志中若出现 `x509: certificate signed by unknown authority` 则说明仍缺根证书（此时建议改为随包内置 CA bundle + `SSL_CERT_FILE`，见 §4.7）。

---

## 3. C3/C4 详细：MTU 与 IPv6

### 3.1 MTU（越界）

- 官方 `@ohos.net.vpnExtension.VpnConfig.mtu` 取值范围为 `[576,1500]`；应用默认 `Tun.mtu = 9000`（Android 惯例，`lib/models/clash_config.dart:298`），ArkTS 侧原实现 `options.mtu >= 1280 ? options.mtu : 9000` 会把 9000 直接传给系统。
- 同时 Go 侧 `core/tun/tun.go` 的夹取是 `<1280 || >65535 → 9000`，两个 mtU 语义不一致时可能出现「vNIC 1500 / 用户态协议栈 9000」的错配：协议栈按 9000 组包，超过 vNIC MTU 的报文被内核丢弃（用户态终止的 TCP 有 MSS 协商兜底，UDP/QUIC 及非用户态终止路径则会丢包）。
- 修复：
  - `BettboxVpnAbility.ets`：`mtu` 夹取到 `[576,1500]`，越界回落 1500；
  - `core/tun/mtu_ohos.go` / `core/tun/mtu_android.go`：按平台定义 `[576,1500]/1500` 与 `[1280,65535]/9000`，`core/tun/tun.go` 使用之。
- 真机验证：`hdc shell "cat /proc/net/dev"` 看 vpn-tun 的 MTU；用 `tun.mtu: 1400` 复测失败站点。

### 3.2 IPv6（未接管）

- 修复前 ArkTS 固定 `isIPv6Accepted: false` 且只配置 IPv4 地址/路由，而 Dart/Go 侧在 `General.IPv6 = true` 时会下发 `ipv6Address`（`fdfe:dcba:9876::1/126`，`core/state/state.go`）。结果：核心协议栈启用了 IPv6，OS 层 VPN 不接管 IPv6 ⇒ IPv6 流量绕过隧道直连（被 SNI 阻断即表现为部分站点 TLS 失败）。
- 修复：`BettboxVpnAbility.ets` 解析 `ipv6Address`，加入 IPv6 `LinkAddress` + IPv6 默认路由（`::/0`，`family: 2`），并在存在时置 `isIPv6Accepted: true`（地址非法则忽略并告警）。
- 真机验证：开启 IPv6 后，连接页应能看到失败站点的 IPv6 目标；关闭 VPN 前后 `hdc shell ip -6 route` 对比。

---

## 4. 其它已修 / 未修问题

### 4.1 已修：VPN 建链失败被当成成功（阻断级）

- `VpnPlugin.ets` 中 `EVENT_VPN_START_FAILED` 分支被**重复写了两遍**，第一遍是 `resolve(data.code)`（`code = -1`），第二遍 `reject` 是死代码；Dart `Service.startVpn()` 判的是 `result != null && result != false` ⇒ `-1` 被当作成功，UI 显示「已连接」但核心没有 TUN。
- 修复：失败一律 `reject`；对返回的 fd 做 `> 2` 校验；失败时同 Android `ServicePlugin.notifyVpnStartFailed` 语义向 Dart 发 `vpnStartFailed`（触发既有回滚与提示）；Dart 侧 `startVpn()` 捕获 `PlatformException` 并返回 false，`handleStart()` 在建链失败时终止启动序列。

### 4.2 已修：TUN fd 交接竞态 + 失败静默

- 原实现：Dart 先 `listenTunBridge`（Go 侧 accept 超时 35s），再拉起 VPN 扩展等用户授权；授权超过 35s 后 socket 已删除，`sendTunFd` 失败，但扩展仍然广播 `EVENT_VPN_TUN_CREATED` ⇒ 「VPN 起来了，核心没有 TUN」，Dart 仍显示成功。
- 修复：Go accept 超时 35s → 120s、读超时 5s → 30s；C++ `sendTunFd` 连接重试 1.5s → 10s；扩展在 `sendTunFd` 返回非 0 时**抛出并广播 `EVENT_VPN_START_FAILED`**，同时 `destroy()` 已建立的 vNIC（避免系统侧残留 VPN）；`handleStartTun` 增加 fd 合法性校验。

### 4.3 已修：`handleStartTun` 自锁

`core/lib_ohos.go` 原代码在持有 `tunLock` 时调用 `handleStopTun()`（内部再次 `Lock`，Go 的 `sync.Mutex` 不可重入）⇒ 命中即永久挂起，后续所有 FFI 调用（如 `getAndroidVpnOptions`）卡死。改为抽出 `stopTunLocked()` 供持锁路径调用。

### 4.4 已修：fd 上限为 0 时全网被阻断

`core/platform/limit.go` 用 `int(limit.Cur)/4*3` 作为「最大 fd」阈值，若系统返回 `RLIM_INFINITY`（-1 或极大值）会得到 0 或负值 ⇒ `ShouldBlockConnection()` 对每个 socket 返回 true，**所有出站连接被屏蔽**。已加 `<= 0 || > 1<<20 → 1024` 兜底。

### 4.5 已修：返回键 / 退出无效

- `AppPlugin.moveTaskToBack` 原为 `result.success(true)` 空实现（`window` 在移动端为 null，Dart `System.back()` 因此完全无效）⇒ 改为 `UIAbilityContext.moveAbilityToBackground()`。
- 引擎 `popSystemNavigator()` 默认返回 false，`SystemNavigator.pop()` 退化成 `router.back()`，「退出」永远不结束进程 ⇒ `EntryAbility` 覆写为 `terminateSelf()` 并返回 true。

### 4.6 已修：缺失插件导致的死功能（外部链接 / 版本号 / 网络监听）

鸿蒙只注册了 `shared_preferences_ohos`、`path_provider_ohos` 两个插件，`connectivity_plus`、`url_launcher`、`package_info_plus`、`mobile_scanner`、`wakelock_plus`、`app_links`、`file_picker` 等无鸿蒙实现（调用抛 `MissingPluginException`，release 下静默）。本次用原生通道兜底：

| 功能 | 修复 |
|---|---|
| 外部链接（关于页/GitHub/Telegram/更新下载等）| 新增 `AppPlugin.openUrl`（`ohos.want.action.viewData`）+ Dart `app.openUrl`，`globalState.openUrl` 在鸿蒙走原生 |
| 应用版本号（关于页/缓存键）| 新增 `AppPlugin.getPackageInfo`（`bundleManager`）替代写死的 1.19.3；构建脚本 `scripts/build_ohos.py` 会把 pubspec 版本同步进 `AppScope/app.json5`（已同步为 1.19.3 / 2026091901）|
| 网络变化监听（断网重连/清连接/智能停机触发）| `ConnectivityManager` 在鸿蒙改用原生 `networkChanged`；`SmartAutoStopManager` 不再订阅 connectivity_plus；网关/IP 改走原生查询 |
| 扫码页首帧 | `lib/pages/scan.dart` 鸿蒙分支置位 `_permissionChecking`，避免先渲染一帧 `MobileScanner` |
| 平台兜底 | `SupportPlatform.currentPlatform` 未知平台不再伪装成 OHOS，恢复抛错 |

### 4.7 已修：PC/2in1 状态栏托盘菜单不更新

`lib/common/ohos.dart` 下发的是一级数组，而原生 `StatusBarTray.ets` 读 `spec.groups` ⇒ 每次 `JSON.parse` 后取属性为 undefined，菜单重建抛错。改为下发 `{ groups: [...] }`（真机仍需 PC 设备确认）。

### 4.8 未修但已定性：Go 运行时 TLS 槽位补丁（非 TLS 根因）

证据（对已构建产物 `libmeta.so` 的全文件指令扫描 + musl 源码）：

- 全文件仅有 **2 处** `MRS TPIDR_EL0`，即 `runtime.load_g` / `runtime.save_g`，语义为 `g = *(TP+8)` / `*(TP+8) = g`；
- `llvm-readelf -r`：**0 个 `R_AARCH64_TLS_TPREL`**（324887 个 RELATIVE、57 个 JUMP_SLOT、5 个 GLOB_DAT），无 `__tls_get_addr` 引用 ⇒ musl 可以正常 `dlopen`；
- musl/aarch64：`TLS_ABOVE_TP`、`GAP_ABOVE_TP 16`，首个 TLS 块落在 **TP+16**，`dtv` 在 **TP-8**、`canary` 在 TP-16 ⇒ **TP+8 落在 ABI 保留空档内**，不会踩 musl 的 `dtv`/`canary`；
- 因此该补丁不会造成「按站点区分的证书错误」，其真实风险是：为线程族共享一个固定槽位，若某线程的 TP+8 被非 Go 代码初始化/复用，`g` 可能非法（表现为崩溃/内存异常），而非 TLS 报错。

仍建议后续加固（属独立技术债）：改用 Go 自身在 Android 上的做法（`runtime/cgo/gcc_android.c` 的 `inittls()` 动态取槽位，Go Android 用 `$16` 而非 `$8`），并在启动时断言槽位可用；同时 `rt0_go` 强制 `argc=0/argv=零缓冲` 会让 `/proc/self/auxv` 不可读时丢失 hwcap（AES/SHA/PMULL/LSE 汇编路径退化为软件实现，性能下降但功能正确）。

### 4.9 未修：确认存在但不在本次范围的缺口

| 优先级 | 缺口 | 说明 |
|---|---|---|
| 高 | `registerCallbacks` / `startTun(fd, cb)` 未接 | `libmeta.h` 导出了 `registerCallbacks`，但 `ohos/entry/src` 无任何调用 ⇒ 核心进程解析回调为 nil ⇒ 连接页看不到应用名/图标，`PROCESS-NAME` 规则永不命中；同时 `handleProtect` 也是死代码（当前只靠 `protectProcessNet()` 防回环）。需按 Android `JNI_OnLoad` 的做法在 N-API 层注册 protect/resolve 回调 |
| 高 | 长时任务通知 | `dataTransfer` 长时任务需周期更新进度通知（10 分钟内首次），当前无通知能力 ⇒ 后台约 10 分钟后可能被系统取消；`VpnExtensionAbility` 自身申请长时任务也不被支持（应以 UIAbility 上下文申请）|
| 中 | Script（JS 覆写）| `flutter_qjs` 无鸿蒙实现、无 `libqjs.so`，脚本静默失效（须按规划用 NDK 编译 QuickJS）|
| 中 | 深链导入 `clash://install-config` | Dart 侧 `link.dart` 直接 return，`module.json5` 也无 `uris` skills，功能完全未实现 |
| 中 | 分应用列表 | 三方应用无法枚举已安装应用（需 `GET_BUNDLE_INFO_PRIVILEGED`），`getPackages` 仅返回自身。本次已在 UI 上阻止「智能选择」产生错误配置，只保留手动录入 |
| 中 | API 等级 | `build-profile.json5` 的 `compatibleSdkVersion: "5.0.5(17)"` 低于代码实际依赖（`want.parameters` 传递 VPN 配置、`protectProcessNet` 均为 API 22+）⇒ 17–21 设备上 VPN 配置无法送达；建议抬到 `6.0.2(22)` 以上或在文档中明确最低版本 |
| 低 | 签名流水线 | `signingConfigs: []` 且 `signingConfig: "default"`，`--sign` 实际不可用（仅能出未签名包）|
| 低 | 托盘菜单 API | 用到 `@since 22/24` 字段（`hoverTips`、`options.selected`）与废弃的 `menuCode`，低版本 PC 上会退化 |
| 低 | `ohos_tz.go` 未参与编译 | 文件位于 mihomo 模块根目录，而构建目标是 `core` ⇒ `time.Local` 保持 UTC（Android 端同样问题，属上游历史债）；仅影响核心日志时间显示 |
| 低 | 智能停机语义 | 鸿蒙原生 `smartStop/smartResume` 返回 false，Dart 侧退回「完整停/启 VPN」的桌面分支（功能可用但与 Android 省电语义不同）|
| 低 | 默认配置项 | `nameserver-policy['*']` 实测无效、`fake-ip-filter` 以 `'*'` 开头导致 fake-ip 实际关闭，建议后续清理这些历史配置（与 TLS 相关，属产品侧决策）|

---

## 5. 本次验证记录

| 验证项 | 命令 | 结果 |
|---|---|---|
| Go 核心（含新 MTU/锁/fd/证书路径改动）| `scripts/build_native.py --go-only` | ✅ 编译通过；`TLS 重定位检查通过，无 R_AARCH64_TLS_TPREL`；产物 72 MB |
| 证书路径进入二进制 | `strings libmeta.so \| grep security/cacerts` | ✅ 命中 |
| Dart 静态检查 | `dart analyze lib` | ✅ 0 error（3 条既有 warning：`clash/core.dart:220`、`clash/ohos.dart:9`）|
| ArkTS 编译（含 VPN 配置/插件/Ability 全部改动）| `hvigorw --mode module -p module=entry@default assembleHap` | ✅ `BUILD SUCCESSFUL`，产出 `entry-default-unsigned.hap`（versionName 1.19.3 / versionCode 2026091901）|
| ArkTS 规则检查 | `codelinter entry/src/main/ets` | ✅ No defects |
| 真机联调 | 无设备（`hdc list targets` 为空）| ⏳ 待做，重点：§1.3 DNS 日志、§3 MTU/IPv6、§4.1 失败上报、§4.5 返回/退出 |

编译期修掉的两个 ArkTS 错误（供后续留意）：`arkts-limited-throw`（只能 `throw new Error(...)`）、`NetCapabilities` 字段名是 `networkCap` 而非 `networkCapabilities`。

---

## 6. 需要真机确认的行为变更与回滚点

1. **路由表语义对齐 Android**（`BettboxVpnAbility.buildRoutes`）：当配置下发了 `route-address`（默认开启「绕过私有网段」时会下发公网段列表）时，vNIC 不再无条件加 `0.0.0.0/0`，而是按列表下发；`route-address` 为空时仍回落默认路由。若真机发现「连接正常但流量不进隧道」，优先回滚这一处（改回固定 `0.0.0.0/0` + `isDefaultRoute: true`）。
2. ~~**`extensionProcessMode`**：原值 `runWithMainProcess` 不在 `type: vpn` 的 schema 枚举内（允许 `type`/`bundle`，默认 `bundle`）。现依赖默认值 `bundle` 以保持「扩展与 Flutter/Go 同进程」，`protectProcessNet()` 才能覆盖核心出站 socket。真机需确认扩展进程与主进程一致：~~

   > ⚠️ **2026-10-03 更新：上述结论已被真机推翻，请以本节之后的「2026-09-27 真机验证结论」为准。**
   > 实测无论配 `bundle` 还是 `runWithMainProcess`，VPN 扩展都跑在**独立进程**
   > `com.appshub.bettbox:vpn`（SELinux 域 `vpn_isolate_hap`），`protectProcessNet()` 覆盖不到
   > 主进程里的核心；release 下向文件型 socket 传 fd 一律 `EACCES(-13)`。
   > **现行方案：release 用抽象命名空间 socket（`@name`）完成 TUN fd 交接**（见下文真机结论一节）。
   ```bash
   hdc shell "ps -ef | grep bettb"   # 期望只看到 1 个应用进程承载 EntryAbility 与 VpnExtension
   ```
   若发现是两个进程，则需改走 `registerCallbacks` + 逐 socket `protect(fd)` 方案（见 §4.9 高优先级项）。
3. **`protectProcessNet()` 时机**：保持「create 前先试、失败则在 create 后重试」，并在两次都失败时记录 error 级日志（此时防回环降级，需排查）。


---

## 2026-09-27 真机验证结论：release 已可用（HarmonyOS 7.0.0 / API 26）

### 1. 弹窗「只剩遮罩、内容不显示」——已确认修复

根因：flutter_ohos 把鸿蒙上 `AlertDialog` 的默认改成了 `scrollable: true`（原版默认 false），
本应用弹窗内容自带 `SingleChildScrollView` + 固定宽高，叠进 fork 的双层滚动 + `IntrinsicWidth`
结构后渲染不出来。修复：`CommonDialog` 与隧道编辑弹窗显式 `scrollable: false`。
**用户真机确认：备份与恢复 / 首页内容信息 / 隧道编辑弹窗均正常。**

### 2. TUN fd 交接在 release 下失败——用抽象 socket 解决

真机证据：

| 构建 | 应用主进程域 | VPN 扩展域 | 文件 socket 交接 |
| --- | --- | --- | --- |
| debug（`"debug": true`） | `debug_hap` | `debug_hap`（同域） | ✅ 可用 |
| release（`"debug": false`） | `normal_hap` | `vpn_isolate_hap`（隔离） | ❌ `EACCES(-13)` |

进一步实测（release）：`cache`、`files` 两个目录下的文件 socket 都返回 `-13`，
但 **Linux 抽象命名空间 socket（`@name`，无文件 inode）成功**：

```
sendTunFd .../cache//tun_bridge_xxx.sock  result: -13
sendTunFd .../files/tun_bridge_xxx.sock   result: -13
[TunBridge] SendTunFd ok: fd 33 -> @bettbox_tun_xxx
VpnPlugin: startVpnInternal succeeded with tunFd: 33
```

结论与修复：
- 抽象 socket 作为唯一通道（文件 socket 在 release 下永远不通，无兜底价值）；
- 未被使用的兜底监听超时不再报 Error（否则应用会把核心错误日志当提示周期性弹出）；
- 原架构（Go 核心在主进程 + socket 传 fd）在 release 下成立，**不需要把核心搬进扩展进程**
  （该备选方案与 Phase 0 探针结论见 `docs/harmonyos_release_core_in_extension_plan.md`）。

### 3. 一并修掉的扩展进程问题

- 原生 `sendTunFd` 在扩展 JS 线程上同步阻塞 10s → 被系统判 appfreeze 杀进程
  （`DfxFaultLogger` 栈：#00 musl ← #01 libentry.so ← napi ← onCreate）。
  改为非阻塞 `connect` + `poll` 限时（单次 2.5s），重试移到 ArkTS 异步循环（总 25s）。
- `OH_LOG_*` 未定义 `LOG_DOMAIN/LOG_TAG` → C++ 日志不落盘；已补齐，并统一返回 `-errno`。
- `extensionProcessMode` 对 `type: vpn` 无效（官方仅状态栏扩展生效），已移除；
  debug 构建由 `scripts/build_ohos.py` 临时注入，release 不注入。

### 4. 交付面

- HAP 只打包 `arm64-v8a`（`externalNativeOptions.abiFilters` + `napiLibFilterOption` 兜底），
  不再携带模拟器用的 x86_64 `libflutter.so`（约 40MB）；
- release 默认 `--dart-define=APP_ENV=stable`：无右上角 DEBUG/PRE 角标，并启用更新检查
  （可用 `--app-env pre` 覆盖）；
- 实测 release 包：隧道有收发、活跃连接有数、连通性测试全通、无周期性误报提示。

---

## 5. 后台保活：从「10 分 03 秒必死」到 taskKeeping（2026-10-09 真机实测）

设备：HarmonyOS 7.0.0 / API 26 真机。
原始 hilog 证据：`keepalive_evidence_2026-10-09.log`（仓库根目录，`*.log` 已被 gitignore）。

### 5.1 三个被实测推翻的旧假设

| # | 旧假设（代码注释里写着） | 实测结论 |
| --- | --- | --- |
| 1 | 「taskKeeping 申请会一直挂住」 | **不成立**。ACL 已授予时 `startBackgroundRunning(ctx,['taskKeeping'],agent)` 正常返回：22:53:25.434 TUN 建好 → 22:53:25.547 系统创建连续任务（113ms） |
| 2 | 「dataTransfer 实测稳定，可作兜底」 | **相反**：`MODE_DATA_TRANSFER` 带 C4 进度义务（10 分钟内必须更新，且只能经实况窗），本机 `startLiveView` 返回 401 ⇒ 每次都在 **10 分 03 秒**被 `StopContinuousTaskByUserInner ... because notification remove` 取消 |
| 3 | 「模式降级链」 | **是空链**。`startTaskWithFallback` 里 `candidates = [requested]` 只有一个元素，失败即彻底没有长时任务；且 `keepAliveDesired` 只在成功后置位，watchdog / onBackground 补申请全部失效 |

设备侧 ACL 核实（`atm dump -t -b com.appshub.bettbox`）：`ohos.permission.KEEP_BACKGROUND_RUNNING_SYSTEM`
`grantStatus=0`（已授予），定义 `SYSTEM_GRANT` / `SYSTEM_BASIC`。
`module.json5` 的 `backgroundModes` 实际落盘为位掩码 259 = dataTransfer(1) | audioPlayback(2) | taskKeeping(9)。

### 5.2 真机对照（同一条隧道、同一判定：10 分钟点）

| 模式 | 任务创建时刻 | 结果 |
| --- | --- | --- |
| `dataTransfer`（另一工程两次独立复现） | 21:50:09.775 / 22:04:52.488 | **均在 10 分 03 秒被系统取消**，隧道被拆 |
| **`taskKeeping`** | 22:53:25.547（锁屏 22:55:12 起全程息屏） | **14 分 04 秒无任何 `continuousTaskCancel` / `StopContinuousTask`**；`vpn-tun` 在、两个进程在、RX/TX 持续增长（27KB→523KB） |

结论：**这台设备上保活成立的模式是 taskKeeping**，dataTransfer 在实况窗（AGC 场景权限）开通前不可用。

### 5.3 本次改动

1. **默认模式改为 taskKeeping**（`VpnProps.backgroundTaskMode` + `backgroundTaskEnabled` 默认 true）。
   旧默认是 dataTransfer + 保活关闭 —— 前者必死，后者等于完全没有豁免。
2. **`parseBgModes` 不再给 audioPlayback 自动补 dataTransfer**。旧代码的「兜底」实际是把
   C4 进度义务注入整个任务，把本来无义务的 audioPlayback 一起送进 10 分 03 秒的取消点。
3. **降级链做成真的**：`requested → taskKeeping → dataTransfer`；每级失败先回查
   `getAllContinuousTasks`，确认「超时 ≠ 没受理」再决定是否降级。
4. **音频打断后的任务收敛目标改为 taskKeeping**（原为 dataTransfer-only）。
5. **取消原因分模式处置**：reason 12/4（进度未更新 / 低速）说明 dataTransfer 义务无法履行，
   重申请时换 taskKeeping 而不是重试同一模式；并加 3 次连败预算，避免对系统管控死缠烂打。
6. **先申请长时任务，再起 VPN**（`GlobalState.handleStart`），建链失败回收任务。
   旧顺序在建链期间切后台会让申请落在后台而失败（9800005 #15）。
7. **可观测性**：release 包（`app.json5 debug:false`）的 ArkTS `hilog.info` 会被系统过滤
   （同机 debug 包可见、release 包 0 条 info），因此保活链路日志一律提到 WARN，
   并在 Dart 侧 `commonPrint.log('Background task effective modes: ...')` 落一行系统实报的模式。

### 5.4 未做 / 待办

- **location 未实现**：它在 wireguard 那台设备上能长期存活，但需要追加 `backgroundModes: location`
  与 `APPROXIMATELY_LOCATION`/`LOCATION` 两个 user_grant 权限；且**权限申请绝不能放进连接路径**
  （弹窗会把连接永久挂起且无错误日志）。本机 taskKeeping 已成立，故按「优先 taskKeeping」收口。
- **实况窗（AGC 场景权限）**：开通后 dataTransfer 才重新可用，可作为第二条路线。
- 本次交付产物为未签名 HAP：`build/ohos/hap/bettbox-1.19.4-ohos-vc2026100901-unsigned.hap`
  （flutter 产物 `entry-default-unsigned.hap` 按交付命名惯例重命名，附同名 `.sha256`；
  versionCode 2026100901 / versionName 1.19.4，已核验新增保活代码在包内），
  需用项目原有签名流程签名后安装。
