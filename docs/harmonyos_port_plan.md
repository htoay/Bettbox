# Bettbox 鸿蒙端（HarmonyOS NEXT）移植开发规划文档

## 1. 项目背景与技术选型

### 1.1 现状与目标
* **项目现状**：Bettbox 是基于 Mihomo (Clash Meta) 内核、Flutter UI 的多平台代理客户端，已支持 Windows、macOS、Linux、Android（含 Android TV）。
* **建设目标**：新建纯血鸿蒙（HarmonyOS NEXT / API 23+，Stage 模型）客户端，实现系统级 TUN 虚拟网卡代理接管、分应用代理分流、配置在线编辑与完整图形交互。

### 1.2 方案选型评估
| 评估维度 | 路线 A：全量 ArkTS 原生重构 | 路线 B：Flutter-OHOS + Go Core + RustLib + ArkTS VPN (推荐) |
|---|---|---|
| **UI 复用度** | 0%（需重写 100+ 视图与组件） | **95%+**（完全复用现有 Dart 视图、动画与逻辑） |
| **状态流维护** | 需将 Riverpod 移植到 ArkUI V2 状态管理 | 完全复用现有 Riverpod 状态流与多语言系统 |
| **核心维护成本** | 分叉出独立 ArkTS 仓库，两套代码并行 | 单一仓库多端共享，维护成本最小 |
| **技术成熟度** | 需长期适配与排错 | 同类 Flutter-OHOS 移植工程已验证整套编译与打通链路 |
| **结论** | **不予采纳** | **正式采纳方案** |

---

## 2. 总体架构设计

```
┌─────────────────────────────────────────────────────────────┐
│                    Bettbox UI (Flutter)                     │
│   - Dashboard / Proxies / Profiles / Config / Settings      │
│   - Riverpod State Management & Localization (i18n)         │
└──────────────┬───────────────────────────────┬──────────────┘
               │                               │
        Dart FFI / MethodChannel        MethodChannel ('service' / 'vpn')
               │                               │
               ▼                               ▼
┌──────────────────────────────┐ ┌─────────────────────────────┐
│     Native Dynamic Libs      │ │   ArkTS Stage Host (ohos/)   │
│ ┌──────────────────────────┐ │ │ ┌─────────────────────────┐ │
│ │ libcore.so (Go / Mihomo) │ │ │ │ EntryAbility            │ │
│ │  - sing_tun (TUN 读写)   │ │ │ │  - FlutterAbility 承载  │ │
│ │  - 规则分流与代理传输    │ │ │ └───────────┬─────────────┘ │
│ └──────────────────────────┘ │ │             │ IPC           │
│ ┌──────────────────────────┐ │ │ ┌───────────▼─────────────┐ │
│ │ libcode_forge.so (Rust)  │ │ │ │ BettboxVpnAbility       │ │
│ │  - aarch64-linux-ohos    │ │ │ │  - VpnExtensionAbility  │ │
│ │  - 高性能文本编辑器引擎  │ │ │ │  - vpnConnection.create │ │
│ └──────────────────────────┘ │ │ │  - 获取 tunFd & 防回环  │ │
└──────────────▲───────────────┘ │ └───────────┬─────────────┘ │
               │                               │               │
               └─────────── tunFd 传递 ────────┘               │
                                                               │
                                         System Network Manager│
                                                               ▼
                                       ┌───────────────────────────────┐
                                       │ HarmonyOS Kernel (vpn-tun 网卡)
                                       └───────────────────────────────┘
```

---

## 3. 核心技术攻坚与落地方案

### 3.1 代码编辑器 RustLib 鸿蒙交叉编译 (`code_forge`)
按决策，代码编辑器不采用降级方案，直接使用 `cargo` 配置 `aarch64-unknown-linux-ohos` 目标：
1. **工具链环境**：
   - Rust 目标：`aarch64-unknown-linux-ohos`（系统已通过 rustup 安装）。
   - 链接器：鸿蒙 NDK Clang（`<OHOS SDK 路径>/23/native/llvm/bin/aarch64-unknown-linux-ohos-clang`）。
   - Sysroot：`<OHOS SDK 路径>/23/native/sysroot`。
2. **编译配置 (`plugins/code_forge/rust/.cargo/config.toml`)**：
   ```toml
   [target.aarch64-unknown-linux-ohos]
   linker = "<OHOS SDK 路径>/23/native/llvm/bin/aarch64-unknown-linux-ohos-clang"
   rustflags = [
       "-C", "link-arg=--target=aarch64-linux-ohos",
       "-C", "link-arg=--sysroot=<OHOS SDK 路径>/23/native/sysroot",
       "-C", "link-arg=-Wl,-z,max-page-size=16384",
   ]
   ```
3. **输出与打包**：
   - 产物：`target/aarch64-unknown-linux-ohos/release/libcode_forge.so`。
   - 自动复制至：`ohos/entry/libs/arm64-v8a/libcode_forge.so`。
   - Dart 端：通过 `ExternalLibrary.open('libcode_forge.so')` 动态加载，行为与 Android/Linux 保持一致。

### 3.2 Go 核心 (Mihomo) 鸿蒙适配与 musl libc 兼容
1. **TLS initial-exec 冲突规避**：
   - **问题**：Go 运行时默认在 aarch64 上采用 initial-exec TLS 模型读取 `runtime.tls_g`，输出的共享库包含 `R_AARCH64_TLS_TPREL` 重定位，鸿蒙 musl 动态链接器直接拒绝 `dlopen`。
   - **解决**：应用 Go overlay 补丁 `src/runtime/tls_arm64.s`，利用 musl/aarch64 TP 上方 16 字节空档（`GAP_ABOVE_TP`），将 `runtime·tls_g` 转为普通全局变量，固定指向 `TP+8` 槽位。
2. **musl `.init_array` 启动越界规避**：
   - **问题**：musl 调用共享库构造函数时不传参数，R0/R1 为随机脏数据，Go `rt0_go` 初始化读取时触发 SIGSEGV。
   - **解决**：overlay 补丁 `src/runtime/asm_arm64.s`，强制将 `argc` 置 0 并提供静态全零 `argv` 缓冲，触发 `sysargs` 走 `/proc/self/auxv` 兜底读取 CPU 特性与页面尺寸。
3. **内存页对齐与校验**：
   - 链接参数加入 `-Wl,-z,max-page-size=16384`。
   - 编译完成后使用 NDK `llvm-readelf -r` 执行严格校验，杜绝 `R_AARCH64_TLS_TPREL`。

### 3.3 系统级 TUN 网卡管理 (`VpnExtensionAbility`)
1. **ExtensionAbility 声明**：
   - 在 `ohos/entry/src/main/module.json5` 中声明 `type: "vpn"` 的 `BettboxVpnAbility`。
2. **生命周期与网卡创建**：
   - 用户点击连接时，主界面通过 MethodChannel 触发 `vpnExtension.startVpnExtensionAbility(want)`。
   - 用户确认系统授权弹窗后，`BettboxVpnAbility.onCreate()` 运行。
   - 组装 `VpnConfig`：
     - `addresses`: 虚拟 IP 地址（如 `172.19.0.1/30`）。
     - `routes`: 默认路由（`0.0.0.0/0`，网卡设为 `vpn-tun`）。
     - `dnsAddresses`: DNS 劫持地址。
     - `trustedApplications` / `blockedApplications`: 映射 Bettbox 的分应用代理规则（白名单/黑名单），由系统在网卡入口直接分流。
     - `mtu`: 9000 或 1500。
   - 执行 `vpnConnection.create(config)` 获得 **TUN 文件描述符 `tunFd`**。
3. **核心数据传递与流量防环**：
   - 将 `tunFd` 传递给 Go 核心（调用 `Core.startTun(tunFd)`）。
   - Mihomo 核心通过 `sing_tun` 接管该 `tunFd` 的 IP 数据包。
   - 启用 `vpnConnection.protectProcessNet()`（API 22+ 特性），使当前代理进程出站连接直接走物理网卡，彻底避免流量回环死锁。

### 3.4 后台保活与资源管理
1. **权限声明**：
   - `ohos.permission.INTERNET`
   - `ohos.permission.KEEP_BACKGROUND_RUNNING`，配置 `backgroundModes: ["dataTransfer"]`。
2. **内存感知调度**：
   - 监听 `AbilityConstant.MemoryLevel`，高内存告警时通知 Go 核心触发 GC 与清除冗余 DNS 缓存，防止被系统 OOM 终止。

### 3.5 剪贴板读取权限（粘贴能力）

- API 12 起系统对剪贴板读取增加权限管控：`ohos.permission.READ_PASTEBOARD`（受限 user_grant，需要签名 Profile 携带对应 ACL）。
- Flutter 使用自绘控件，无法集成系统粘贴控件（PasteButton），符合官方允许申请的场景「应用中使用了开源框架：由于不能使用粘贴控件，允许申请剪贴板权限」；PC/2in1 设备上的应用均可申请。
- `flutter_ohos` 引擎（embedding `PlatformPlugin.getClipboardData`）每次读取剪贴板时才向用户申请该权限，未声明或未授权时直接返回空数据（表现为「从剪贴板导入」、输入框粘贴等全部失效），因此 `module.json5` 必须声明该权限。
- 签名要求：声明受限权限后，签名 Profile 必须包含对应 ACL，否则**应用安装失败**。调试阶段使用 DevEco 自动签名（会自动向 AGC 申请），发布阶段在 AGC 手动申请（审核时长约 3 个工作日）。

### 3.6 PC/2in1 状态栏托盘（Desktop Extension Kit）

- 使用 `statusBarManager`（`@kit.DeskTopExtensionKit`，HarmonyOS 26 SDK 的 HMS 部分）接入 PC 状态栏托盘：
  - 左键点击图标：`statusBarIconClick` 事件 → 拉起自身 `EntryAbility` 把主窗口带回前台（`quickOperation.abilityName` 传空串，不走业务弹窗）。
  - 右键菜单与 Windows 版对齐：显示主界面 / 启动·停止代理 / 代理模式（带选中态）/ 代理组子菜单（⚡延迟测试 + 节点列表，节点标题带延迟、当前节点带选中态）/ 重启核心 / 保持唤醒（带选中态）；「退出」使用系统强制自带项。
  - 菜单是快照式的：Dart 侧监听 `trayStateProvider`（`OhosTrayManager`，300ms 防抖）把整份菜单结构以 JSON 下发给原生重建；菜单项点击通过 `notifyOnly + menuCode` → 自定义 commonEvent → `AppPlugin` 转发 Dart 分发（`mode:` / `proxy:` / `delayTest:` / `restartCore` / `wakelock`）。
- 平台限制（对齐时的取舍）：无分隔符（用分组替代）；一级项总数 ≤20、单个一级项 ≤20 个二级项（节点列表截断为 19）；菜单无副标题（延迟拼进标题）；鸿蒙 PC 无系统代理/TUN 开关、复制环境变量不适用。
- 保持唤醒：鸿蒙无 `wakelock_plus` 实现，改用原生 `window.setWindowKeepScreenOn`（托盘与仪表盘开关共用该通道）。
- 该能力为 PC 专属：`StatusBarTray.ets` 内含 PC 系统模块的静态 import，必须由 `AppPlugin` 在 `deviceInfo.deviceType === '2in1'` 时**动态 import**，避免手机/平板解析该模块失败。
- 图标资源：`resources/rawfile/tray_white.png` / `tray_black.png`（24vp 白色/黑色单色图标）。

### 3.7 包体积优化

- `module.json5` 开启 `compressNativeLibs: true`，`hvigor-config.json5` 配置 `ohos.pack.compressLevel: "ultimate"`，对 libs 下的 .so 压缩打包（官方推荐；rawfile 资源按打包工具规则不做压缩）。
- 实测 Release HAP：**133.5MB → 63.4MB**（libclash 74MB、libflutter 17MB、libapp 16MB 是压缩主体）。
- 剩余体积主要是 Flutter 资源（geoip/GeoSite/字体等约 22MB）与 Go 核心；进一步压缩需要裁剪 Go 构建标签（如 `with_gvisor`）或按需分发，属后续可选项。

---

## 4. 依赖适配矩阵

| 插件 | 当前用途 | 鸿蒙端解决方案 |
|---|---|---|
| `shared_preferences` | 本地轻量配置 | 引入 `CPF-Flutter` 适配版 `shared_preferences_ohos`（已接入）|
| `path_provider` | 沙箱文件路径 | 引入 `CPF-Flutter` 适配版 `path_provider_ohos`（已接入）|
| `connectivity_plus` | 网络状态监听 | ⚠️ 适配版**未接入**：改由原生 `VpnPlugin`（`@ohos.net.connection`）推送 `networkChanged`，见 `docs/harmonyos_audit_fixes.md` §4.6 |
| `device_info_plus` | 设备信息 | ⚠️ 适配版**未接入**：`system.version` 在鸿蒙直接返回 0（已加 try/catch）|
| `package_info_plus`| 应用版本信息 | ⚠️ 适配版**未接入**：改由原生 `AppPlugin.getPackageInfo`（`bundleManager`）提供，构建脚本同步 pubspec 版本到 `app.json5` |
| `url_launcher` | 外部网页跳转 | ⚠️ 适配版**未接入**：改由原生 `AppPlugin.openUrl`（`want.action.viewData`）提供 |
| `code_forge` | 配置文件代码编辑 | **使用 cargo 交叉编译 aarch64-unknown-linux-ohos 产出 .so**（已接入）|
| `mobile_scanner` | 扫码导入订阅 | 通过 MethodChannel 调用系统原生 **Scan Kit** (免申请相机权限)（已接入）|
| `flutter_qjs` | JS 分流规则覆写 | ❌ 仍待 NDK CMake 编译 QuickJS 动态库接入（当前脚本覆写静默失效）|
| `window_manager` | 桌面窗口缩放 | 在 `System.isOhos` 条件下禁用，避免调用（已处理）|
| `tray_manager` | 桌面系统托盘 | 在 `System.isOhos` 条件下禁用（PC 状态栏托盘改走 `StatusBarTray`）|
| `launch_at_startup`| 桌面开机自启 | 在 `System.isOhos` 条件下禁用（已处理）|
| `hotkey_manager` | 桌面全局快捷键 | 在 `System.isOhos` 条件下禁用（已处理）|

> 2026-09-27 完成一轮鸿蒙端缺陷排查与修复（DNS/根证书/MTU/IPv6/建链失败上报/fd 交接/返回退出/插件兜底等），
> 详见 **[harmonyos_audit_fixes.md](./harmonyos_audit_fixes.md)**；其中「部分网站 TLS 异常」的根因分析与真机验证步骤在该文档 §0–§2。
>
> 2026-09-27 上游合并（上游 main 强制更新 → v1.19.3，18 个新提交；含核心库改名 `libclash` → `libmeta`）
> 的处理方式、冲突解决记录与后续更新流程，见 **[upstream_merge_2026-09-27.md](./upstream_merge_2026-09-27.md)**。

---

## 5. 工程目录规划

```text
Bettbox/
├── docs/
│   └── harmonyos_port_plan.md               # 本规划文档
├── core/
│   ├── lib_ohos.go                          # 鸿蒙环境专项挂载与保护回调
│   └── ...                                  # 保持既有 Go 核心代码
├── plugins/
│   └── code_forge/
│       └── rust/
│           ├── .cargo/config.toml           # 配置 aarch64-unknown-linux-ohos 链接器
│           └── ...
├── scripts/
│   ├── build_native.py                      # Go 核心与 Rust 核心交叉编译总入口
│   ├── build_ohos.py                        # 鸿蒙 HAP 构建、签名、打包总脚本
│   └── ohos_build.py                        # SDK 定位、Go Overlay 补丁生成与路径检查
├── ohos/                                    # 鸿蒙端宿主工程 (Stage 模型)
│   ├── AppScope/
│   │   ├── app.json5                        # 包名、版本号声明
│   │   └── resources/                       # 全局应用图标与文本
│   ├── build-profile.json5                  # compileSdkVersion: 6.1.0(23)
│   ├── hvigorfile.ts
│   ├── oh-package.json5                     # 引入 @ohos/flutter_ohos
│   ├── pubspec_overrides.yaml               # 鸿蒙专用 Flutter 插件依赖重定向表
│   └── entry/
│       ├── build-profile.json5
│       ├── oh-package.json5
│       ├── libs/
│       │   └── arm64-v8a/
│       │       ├── libcore.so               # 编译出的 Go 代理核心
│       │       └── libcode_forge.so         # cargo 编译出的 Rust 编辑器核心
│       └── src/main/
│           ├── module.json5                 # 声明 EntryAbility 及 VpnExtensionAbility
│           └── ets/
│               ├── entryability/
│               │   └── EntryAbility.ets      # 继承 FlutterAbility，初始化插件
│               ├── vpnability/
│               │   └── BettboxVpnAbility.ets # 继承 VpnExtensionAbility，管理 TUN 网卡
│               └── plugins/
│                   ├── VpnPlugin.ets         # MethodChannel: startVpn / stopVpn
│                   ├── ScanPlugin.ets        # Scan Kit 扫码原生桥接
│                   └── AppPlugin.ets         # 基础应用级通道
└── lib/
    └── common/
        └── system.dart                      # 扩展 isOhos 平台判断逻辑
```

---

## 6. 分步实施执行计划

### 第一阶段：Rust & Go 原生核心交叉编译打通
1. 在 `plugins/code_forge/rust` 配置 `.cargo/config.toml`，验证 `cargo build --target aarch64-unknown-linux-ohos --release`，产出合格的 `libcode_forge.so`。
2. 移植 `ohos_build.py` 的 Go overlay 生成器，编写 `core/lib_ohos.go`，执行 NDK 交叉编译产出 `libcore.so`。
3. 使用 `llvm-readelf -r` 检查验证两枚 `.so`，确保无 `R_AARCH64_TLS_TPREL` 违规重定位。

### 第二阶段：Flutter-OHOS 工程基建与依赖调试
1. 建立 `ohos/` 基础骨架，引入 OpenHarmony SDK 23 及 `@ohos/flutter_ohos`。
2. 注入 `pubspec_overrides.yaml` 覆盖标准插件。
3. 修改 `lib/common/system.dart` 及入口判断，隔离桌面端插件。
4. 运行 `flutter pub get` 与首屏构建打包测试。

### 第三阶段：`VpnExtensionAbility` 联动与网络代理联调
1. 编写 `BettboxVpnAbility.ets`，实现 `VpnConfig` 组装及 `vpnConnection.create()`。
2. 实现 `VpnPlugin.ets` 处理 Flutter 的 `startVpn`、`stopVpn` 调用。
3. 通过 C-FFI 将 `tunFd` 传递给 Go 核心，启动 `sing_tun` 监听器，开启 `protectProcessNet()`。
4. 真机/模拟器验证流量捕获与代理节点分流转发。

### 第四阶段：全功能对齐与分发打包
1. 接入 Scan Kit 原生扫码通道，替代 `mobile_scanner`。
2. 调通 `trustedApplications` / `blockedApplications` 分应用代理配置。
3. 完善 `scripts/build_ohos.py` 自动化签名打包流水线。
