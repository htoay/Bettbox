# 鸿蒙 release：抽象 socket 已解决 fd 交接（核心搬迁方案暂缓）

> **2026-09-27 更新（真机结论，优先读这段）**
>
> 加了「第三条通道」后再测 release（隔离域 `vpn_isolate_hap`）：
>
> ```
> sendTunFd .../cache//tun_bridge_xxx.sock  result: -13   EACCES
> sendTunFd .../files/tun_bridge_xxx.sock   result: -13   EACCES
> [TunBridge] SendTunFd ok: fd 33 -> @bettbox_tun_xxx     ← 抽象 socket 成功
> VpnPlugin: startVpnInternal succeeded with tunFd: 33
> ```
>
> **Linux 抽象命名空间 socket（`@name`，无文件 inode）不受文件标签策略限制**，
> 所以 release 下 fd 交接可用：VPN 正常启动，实测有流量、8 条活跃连接、
> 连通性测试全通（Reddit 870ms / Gemini 1330ms / Cloudflare 1144ms）。
>
> ⇒ **原架构（Go 核心在主进程 + socket 传 fd）在 release 下成立**，
> 「把核心搬进扩展进程」不再是必需项，本文档降级为备选方案（若未来某版本
> 连抽象 socket 也禁掉再启用）。配套改动：
> 1. 抽象 socket 优先，文件 socket 仅兜底；
> 2. 未被使用的兜底监听 120s 超时不再报 Error（改为 Info），
>    否则应用会把核心错误日志当提示弹出，用户会周期性看到无关报错。

## （以下为原备选方案）把 Go 核心搬进 VPN 扩展进程

## 背景：为什么 release 用不了

真机（HarmonyOS 7.0.0 / API 26）实测：

| 构建 | 应用主进程 SELinux 域 | VPN 扩展进程域 | unix socket 传 TUN fd |
| --- | --- | --- | --- |
| debug（module.json `"debug": true`） | `debug_hap` | `debug_hap`（同域） | ✅ `SendTunFd ok` → 代理可用 |
| release（`"debug": false`） | `normal_hap` | `vpn_isolate_hap`（隔离域） | ❌ `connect` 返回 `EACCES(-13)` → 启动失败 |

- 官方《VPN流程问题排查指南》《后台保活方案》均说明 VPN 扩展是**独立进程**；`extensionProcessMode` 对其无效。
- debug 包之所以一直能用，是因为鸿蒙对 debuggable 应用不隔离扩展域，端口作者的
  「Go 核心在主进程 + unix socket 传 fd」才成立。
- release 下扩展被隔离，fd 无法跨域交接；文件 socket（cache/files）与抽象 socket 都不行
  （`connect` 一律 EACCES，见 Phase 0 日志）。

结论：release 必须让**核心与 TUN 处于同一进程**，即按官方架构把核心放进扩展进程；
UI 进程（Flutter/Go 主进程）改为通过 IPC 控制。

## 关键发现：需要远程化的接口面很小

`lib/clash/lib.dart` 的 `ClashLibHandler` 对 Go 的调用基本只有：

```
invokeAction(String actionParams) -> Future<String>   // 请求/响应，JSON
attachMessagePort(int port)                            // Go -> Dart 异步事件（ActionResult JSON）
updateDns(String dns)                                  // 单向
setState(CoreState state)                              // 单向
getCurrentProfileName() -> String                      // 同步
getAndroidVpnOptions() -> JSON                         // 同步
```

所以 Dart 业务代码（controller/state/views）**不需要改**，只要：
1. 新增 `ClashRemoteLib implements ClashHandlerInterface`：把上面 6 个调用换成 RPC；
2. 两个同步 getter 改成异步或预缓存（`getAndroidVpnOptions` 目前只在启动 VPN 时用一次）。

## 目标架构

```
┌─ VPN 扩展进程（release 下 vpn_isolate_hap）────────────────┐
│ BettboxVpnAbility                                          │
│   create(config) -> tunFd                                  │
│   ↓ 同进程调用                                              │
│ libentry.so  ──dlopen──▶  libmeta.so (Go 核心)              │
│   coreStart(configJson, homeDir, stateJson)                 │
│   startTUN(tunFd)          ← fd 直接交给同进程的核心         │
│   coreInvoke(actionJson) -> resultJson                      │
│   coreStop()                                                │
└───────────────▲────────────────────────────────────────────┘
                │ 控制通道（双向 JSON 帧）：127.0.0.1 TCP
                │ 失败则回退 @ohos.commonEvent 请求/响应
┌───────────────┴─ 主进程（normal_hap）──────────────────────┐
│ Flutter UI / Dart：ClashRemoteLib（RPC 客户端）             │
│ VpnPlugin：startVpnExtensionAbility(want{ vpnConfig,       │
│            controlPort, ... }) → 启动扩展并等 TUN_CREATED   │
│ （不再加载 libmeta.so；不再需要 tun_bridge socket）         │
└────────────────────────────────────────────────────────────┘
```

数据面：TUN fd 与核心同进程，**不需要任何转发**；核心出站流量仍由
`VpnConfig.blockedApplications`（排除自身）避免回环，`protectProcessNet()` 也可用。

## 分期任务

### Phase 0（已完成，待真机验证）

- `libentry` 增加 `probeCoreLib()`：扩展进程内 `dlopen("libmeta.so")` + dlsym 关键符号。
- 控制通道探针：Dart 侧 `ServerSocket.bind(loopback, 0)`，扩展侧 `@kit.NetworkKit` TCPSocket
  连接、发 `ping` 收 `pong`，日志记录 rtt/错误。
- 产物：`bettbox-1.19.3-release-phase0-unsigned.hap`。

**判定标准**：
- `core lib probe: result=0` ⇒ 可以在扩展进程里跑核心；
- `control channel probe OK ... rtt=Nms` ⇒ 用 TCP 做控制通道；若 FAILED 则改用 CommonEvent。

### Phase 1：控制通道与 RPC 协议

- 协议：4 字节长度前缀 + UTF-8 JSON `{id, method, params}` / `{id, ok, result|error}`。
- 主进程：`lib/plugins/service.dart` 起 `ServerSocket`（回环随机端口），客户端连接后
  由 Dart 侧 `ClashRemoteLib` 收发；多请求用 `id` 关联。
- 扩展：`libentry` 提供 `coreRpcServe(port)`（或由 ArkTS 建连后把 socket fd 交给 native），
  收到 method 分发到 Go 的 `invokeAction` 等导出函数。

### Phase 2：扩展侧核心宿主

- `libentry` 新增（dlopen + dlsym 调用）：
  - `coreStart(configJson, homeDir, stateJson)`
  - `coreStartTun(tunFd)`
  - `coreInvoke(actionJson) -> resultJson`
  - `coreUpdateDns(dnsJson)` / `coreSetState(stateJson)` / `coreStop()`
  - `corePollEvents() -> json[]`（替代 `attachMessagePort` 的异步推送，主进程轮询）
- `BettboxVpnAbility`：`create()` 得到 tunFd 后 → `coreStart(...)` → `coreStartTun(tunFd)`
  → 发布 `VPN_TUN_CREATED`；`onDestroy` 时 `coreStop()`。

### Phase 3：主进程改为 RPC 客户端

- 新增 `lib/clash/remote.dart`（`ClashRemoteLib implements ClashHandlerInterface`）。
- `lib/state.dart` / `lib/controller.dart` 中 OHOS 分支改用 `ClashRemoteLib`。
- `ClashOhosLib().listenTunBridge(...)` 与 C++ `sendTunFd` 在 OHOS 上不再使用
  （保留给 debug 兼容路径）。
- 两个同步 getter 异步化：`Service.startVpn` 改为先 RPC 取 options 再下发 want。

### Phase 4：生命周期与保活

- 扩展被系统冻结/杀死：主进程检测控制通道断开 → 提示重连 / 自动 `startVpnExtensionAbility`。
- 修 `start VPN keep-alive task failed: {"code":"401"}`：按《后台保活方案》申请长时任务
  （extension 侧或主进程侧，注意 backgroundModes 与 KEEP_BACKGROUND_RUNNING 的匹配）。
- 日志/流量事件改为轮询 `corePollEvents()`（保留现有 UI 刷新节奏）。

## 风险与未知

- 控制通道权限：Phase 0 结论待定；CommonEvent 兜底（本应用已在用，跨进程可用，但有大小/延迟代价）。
- 扩展进程内存上限与后台冻结策略：核心常驻扩展进程需要长时任务保活。
- 核心在扩展进程的初始化路径要与主进程版本一致（homeDir/profiles/geo 均通过共享沙箱读写，扩展已能访问 `el2/base/haps/entry/{cache,files}`）。
- 调试期仍可用 debug 包（扩展与主进程同域，现有架构可用），不影响本方案的开发与验证。
