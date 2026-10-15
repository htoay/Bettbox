<h4 align="right">
  <strong>简体中文</strong> | <a href="readme/README_ohos_en.md">English</a>
</h4>

# Bettbox for HarmonyOS NEXT（鸿蒙移植发行版）

本仓库是 [appshubcc/Bettbox](https://github.com/appshubcc/Bettbox) 的**鸿蒙（HarmonyOS NEXT / OpenHarmony）
移植分支**，基于上游 **v1.19.5**。除鸿蒙适配外不改变上游行为。

> 本 fork 只维护鸿蒙端；上游新版本通过 `upstream` 远程合并进来。

> ### ⚠️ 免责声明（摘要）
>
> 本项目是 Bettbox 的**第三方鸿蒙移植分支**，与上游作者、华为及任何服务提供商**无关联、无背书**。
> 本软件是通用代理客户端，**不提供任何代理服务、节点或订阅**，**仅供学习、研究与合法的网络技术调试使用**。
>
> **使用者须自行确保其使用行为符合所在国家/地区及使用地的全部适用法律法规**（电信、网络安全、
> 数据保护、进出口管制等）以及所涉服务的条款；**因使用本软件产生的一切后果由使用者自行承担**。
> 本软件按“现状”提供，**不附带任何担保**，作者与贡献者**不承担任何责任**。
>
> 完整条款见 **[DISCLAIMER.md](DISCLAIMER.md)**（English: **[DISCLAIMER_en.md](DISCLAIMER_en.md)**） —— 使用本软件即表示你已阅读、理解并同意该声明。


---

## 1. 当前状态（真机验证）

测试设备：**鸿蒙真机（HarmonyOS 7.0.0 / API 26，arm64）**

| 功能 | 状态 |
| --- | --- |
| VPN 启动与代理转发（HTTP/SOCKS5） | ✅ 已验证（隧道有收发、连通性测试出延迟） |
| 局域网连接（allow-lan） | ✅ 已验证（HTTP 204/200、SOCKS5 200、出口 IP 为代理节点） |
| 弹窗（备份与恢复 / 首页信息 / 隧道编辑） | ✅ 已验证 |
| 后台保活（长时任务 + 取消自愈） | ✅ 已实现（取消监听 + 秒级重申请 + 30s 看门狗） |
| 保活模式选择（数据传输 / 音频播放 / 计算任务） | ✅ 设置项与系统通知文案一致 |
| DNS 下推（设备 DNS → 核心） | ✅ 已验证 |
| 系统级 DNS 覆写开关 | ⚠️ 部分（鸿蒙无系统级接口，走 vNIC DNS 语义） |
| 脚本（Script，`libcode_forge.so` / rquickjs） | ✅ 已验证（v1.19.5 起改用 Rust 脚本引擎，随包提供） |
| 深链 `clash://install-config?url=…` 一键导入订阅 | ✅ 已实现（`uris` skills + `EntryAbility` want 转投 Dart） |
| 仪表盘「更多 IP 信息」（网络类型 / 网关 / 系统 DNS） | ✅ 已实现（原生 `getNetworkInfo`） |
| 应用列表全量枚举 / 连接页应用名与图标 | ⚠️ 未完成（`getPackages` 只返回自身；`PROCESS-*` 规则因此不生效，见「已知限制」） |

---

## 2. 构建

### 2.1 依赖

| 组件 | 说明 |
| --- | --- |
| **flutter_ohos 工具链** | 鸿蒙端依赖 Flutter 的 OHOS 分支（官方 Flutter 不支持 `TargetPlatform.ohos`）。（官方 Flutter 不支持 `TargetPlatform.ohos`，需使用 OHOS 分支工具链）
| HarmonyOS SDK | API 26（DevEco Command Line Tools 自带的 `sdk/`，或 `ohos/local.properties` 里的 `hwsdk.dir`） |
| Go 1.2x | 编译核心 `libmeta.so`（`-buildmode=c-shared -tags=with_gvisor,ohos`） |
| Rust | 编译 `libcode_forge.so` |
| python3 | 构建脚本 |

### 2.2 一键构建

```bash
python3 scripts/build_ohos.py                 # release（默认带 APP_ENV=stable）
python3 scripts/build_ohos.py --debug         # debug（自动注入 extensionProcessMode=runWithMainProcess）
python3 scripts/build_ohos.py --app-env pre   # 预发布（右上角显示 PRE 角标）
python3 scripts/build_ohos.py --sign          # 用 ohos/build-profile.json5 里已配置的材料直接出**已签名** HAP
python3 scripts/build_ohos.py --version-code 2026100200   # 临时提升构建号，便于覆盖安装
```

产物：`build/ohos/hap/entry-default-unsigned.hap`（默认未签名，**用你自己的证书签名后再安装**；
加 `--sign` 则直接产出已签名 HAP，可直接 `hdc install`）。

> ⚠️ **打包只能跑一次**。`flutter build hap` 会把 dart-define 通过 hvigor 扩展参数
> `-p DART_DEFINES=<base64>` 传给 `flutter assemble`；而 `devecocli build`（或直接跑 hvigorw）
> **不透传该参数却仍会重跑 assemble**，把 AOT 覆盖成没有 dart-define 的版本 ——
> 包会变成 `isPre=true`：正式版右上角冒出 PRE/DEBUG 角标，更新检查也会被静默关掉。
> `build_ohos.py` 构建后会核对 `ohos/.hvigor/report/report-*.json` 里的命令行，丢了就报错退出。

应用图标由 `scripts/gen_ohos_icon.py` 从 Android 自适应图标的矢量源生成鸿蒙侧资源
（分层图标 + 单层兜底 + 启动页图标），**上游换了图标后需要重跑一次**：

```bash
python3 scripts/gen_ohos_icon.py    # 需要 rsvg-convert（librsvg2-bin）与 Pillow
```

构建期还会把 `assets/data/{geoip.metadb,GeoSite.dat,ASN.mmdb}` 压成 gzip 随包
（hvigor 会把 `rawfile` 原样 **STORED** 进 HAP，这三份未压缩二进制因此白占空间；
实测 9.17MB → 3.77MB，**HAP 61.7MB → 56.3MB**），运行时由 `ClashCore.loadGeoAsset()`
透明解压，构建结束自动还原原文件。构建后脚本还会校验产物形状（`libapp.so` 存在、
无 `kernel_blob.bin`、图标字体已 tree-shake），任一不满足就报错退出。

> 排查经验：本机 `flutter pub get` 曾在离线/网络异常时失败，此时可复用已解析依赖直接用
> `flutter build hap --release --no-codesign --no-pub --dart-define=APP_ENV=stable`（需先
> `cp ohos/pubspec_overrides.yaml pubspec_overrides.yaml`，构建后删除）。
>
> ⚠️ 用 `--no-pub` 前请先确认 `pubspec.lock` 里仍是鸿蒙依赖：
> `grep -c gitcode pubspec.lock` 应 ≥ 4（`path_provider` / `shared_preferences` 本体与
> `*_ohos`）。一旦中间执行过不带注入文件的普通 `flutter pub get`，lock 会被换回 pub.dev
> 原版实现，此时 `--no-pub` 会**静默产出鸿蒙上不可用的包**，需改用 `scripts/build_ohos.py` 重建。

### 2.3 上游更新后必须重建核心

上游经常改核心源码（例如 v1.19.4 给 `t.Start(...)` 增加了拥塞控制参数；v1.19.5 把 JS 脚本引擎
从 `flutter_qjs` 换成了 `plugins/code_forge` 的 Rust 实现，并新增 `core/patch.go`、`core/bundle.go`）。
**只改 Dart 不重建核心会导致「新 Dart + 旧核心」错配**：

```bash
git fetch upstream && git merge upstream/main
python3 scripts/build_native.py     # 重建 libmeta.so + libcode_forge.so
python3 scripts/build_ohos.py
```

### 2.4 发行（Release）产物与命名

一键生成对外交付件（未签名 HAP + 同名 `.sha256` + 按模板渲染的 release note 草稿）：

```bash
python3 scripts/release_ohos.py
```

命名规则（完整规则与流程见 [docs/release_process_ohos.md](docs/release_process_ohos.md)）：

```
bettbox-<version>-ohos-vc<versionCode>-<unsigned|signed>.hap
bettbox-<version>-ohos-vc<versionCode>-<unsigned|signed>.hap.sha256
```

- **对外只发 `unsigned`**：签名后的 HAP 会把签名 Profile（`developer-id`、设备 UDID 列表）写进签名块，
  脚本会扫描并拒绝这类产物（`--allow-signed` 仅供本机自用）。
- 产物落在 `build/ohos/hap/`（已被 `.gitignore` 忽略）；校验：`sha256sum -c <同名 .sha256>`。
- Release 正文模板：`.github/release_template_ohos.md`；发布标签：`ohos-v<version>`。

---

## 3. 分支与远程

| 远程 / 分支 | 用途 |
| --- | --- |
| `upstream` | `appshubcc/Bettbox`（只读，用于跟进上游） |
| `origin` | 本 fork（推送目标） |
| `main` | **纯上游镜像**，只做快进 |
| `ohos-port-clean` | **对外公开的工作分支**：脱敏快照分支。首次为单根提交（剥离脱敏前的历史），此后**每版在上一次快照之上追加一个匿名提交**，因此发布推送是普通 fast-forward；推送到 fork 的 `ohos-port` |
| `ohos-port` / `ohos-port-backup` | 本地完整开发历史（含脱敏前的提交，**仅本地存档，不外推**） |
| 标签 `ohos-vX.Y.Z` | 对应上游版本的鸿蒙发行点（如 `ohos-v1.19.4`，已重指到干净提交） |

> ⚠️ **推送约定**：只推 `main`、`ohos-port-clean`（→ fork 的 `ohos-port`）与 `ohos-vX.Y.Z` 标签；
> **不要**推 `ohos-port`、`ohos-port-backup` 及 `ohos-port-backup-*` 标签（它们含脱敏前的历史）。
> 日常开发在 `ohos-port-clean` 上进行，需要回溯时查本地的 `ohos-port`。

---

## 4. 鸿蒙适配要点（与上游的差异）

### 4.1 关键结论：release 下必须用**抽象 socket**传 TUN fd

实测（HarmonyOS 7.0.0 / API 26）：

| 构建 | 应用主进程域 | VPN 扩展进程域 | 文件型 socket 传 fd |
| --- | --- | --- | --- |
| debug（`"debug": true`） | `debug_hap` | `debug_hap`（同域） | ✅ 可用 |
| **release** | `normal_hap` | **`vpn_isolate_hap`（隔离域）** | ❌ `EACCES(-13)` |

⇒ release 下扩展进程被 SELinux 隔离，`connect()` 到主进程创建的**文件型** unix socket 一律被拒；
改用 **Linux 抽象命名空间 socket（`@name`，无文件 inode）** 后交接成功：

```
[TunBridge] SendTunFd ok: fd 33 -> @bettbox_tun_xxx
VpnPlugin: startVpnInternal succeeded with tunFd: 33
```

实现位置：`lib/plugins/service.dart`（建抽象 socket）、`ohos/entry/src/main/ets/vpnability/BettboxVpnAbility.ets`
（重试与交接）、`ohos/entry/src/main/cpp/entry.cpp`（`sendTunFd`，非阻塞 connect + poll 限时）。

### 4.2 其它必须的适配

- **弹窗不显示**：flutter_ohos 把鸿蒙上 `AlertDialog` 默认改成 `scrollable: true`（原版 `false`），
  本应用弹窗内容自带滚动 + 固定宽高会渲染不出来 → `CommonDialog` 显式 `scrollable: false`。
- **打开即卡死**：`EntryAbility` 覆写 `onBackground/onForeground` 时**必须调用 `super`**
  （基类会通过 `delegate.onShow/onHide` 驱动 Flutter 生命周期，漏掉则视图不渲染）。
- **扩展被 appfreeze 杀**：原生 `sendTunFd` 不能在扩展 JS 线程上长时间同步阻塞（会被判无响应），
  改为单次 2.5s 限时 + ArkTS 异步重试。
- **长时任务保活**：Stage 模型下长时任务**只能由 UIAbility 申请**（扩展申请必然 `401`）；
  取消原因按 SDK 真实枚举记录；被取消后 1s 重申请 + 30s 看门狗兜底。
  `taskKeeping`（计算任务）需要 ACL 权限 `ohos.permission.KEEP_BACKGROUND_RUNNING_SYSTEM`。
- **打包**：只打 `arm64-v8a`（去掉模拟器用的 x86_64 `libflutter.so`，省约 40MB）。
- **核心侧**：OHOS 无 Go 标准 CA 路径 → 注入 overlay；DNS 用原生 `getSystemDns` 下推；
  Go TLS 槽位补丁保证 musl `dlopen` 安全。

---

## 5. 已知限制

- **系统级 DNS 覆写 / 系统 HTTP 代理**：鸿蒙不开放对应系统接口，仅 vNIC DNS 生效；
  「系统代理 / 绕过域名」两项在鸿蒙已隐藏，需要系统级代理的程序请手动指向 `127.0.0.1:<混合端口>`。
- **应用列表枚举 / 按应用分流**：鸿蒙 `getPackages` 只能返回自身，核心侧 `registerCallbacks`
  （uid → 包名）未接，因此 `PROCESS-NAME` / `PROCESS-PATH` 规则不会命中，连接页也不显示应用名与图标。
- **常驻通知速率 / 快捷方式 / 电池优化白名单**：鸿蒙无对应能力，相关入口保持隐藏。
- **签名**：本仓库不提供签名材料，产物为未签名 HAP（加 `--sign` 可用自己的材料直接出签名包）。

---

## 6. 目录结构（鸿蒙相关）

```
ohos/                          # 鸿蒙工程（Stage 模型）
  entry/src/main/ets/
    entryability/EntryAbility.ets        # 入口（注意 super 调用）
    vpnability/BettboxVpnAbility.ets     # VPN 扩展（建 TUN、交接 fd、保活）
    plugins/VpnPlugin.ets                # VPN 通道与网络状态
    plugins/AppPlugin.ets                # 长时任务、保活、应用信息等
  entry/src/main/cpp/entry.cpp           # sendTunFd（SCM_RIGHTS）
scripts/build_ohos.py                    # 一键构建（版本同步/进程模式注入/可选签名）
scripts/build_native.py                  # Go 核心 + Rust 插件
docs/                                     # 移植方案、审计与上游合并记录
```

---

## 7. 致谢

上游项目：[appshubcc/Bettbox](https://github.com/appshubcc/Bettbox)（Flutter + mihomo 核心）。
鸿蒙端适配、调试与文档由本 fork 维护。

## 8. 免责声明

**请务必阅读完整版：[DISCLAIMER.md](DISCLAIMER.md)**

- 本项目为**非官方第三方移植**，与上游项目作者、华为技术有限公司及任何服务提供商无隶属、
  合作、赞助或背书关系；不提供任何代理服务、节点、订阅或带宽。
- **仅供学习、研究与合法的网络技术调试使用**。使用者须自行确保使用行为符合所在国家/地区及
  使用地的全部适用法律法规（电信、网络安全、数据保护、密码与进出口管制等）及所涉服务条款；
  **一切后果由使用者自行承担**。
- 软件按 **“现状（AS IS）”** 提供，**不附带任何明示或暗示担保**；在适用法律允许的最大范围内，
  作者与贡献者**对因使用或无法使用本软件造成的任何直接或间接损失不承担任何责任**。
- 本分支**不新增遥测**；配置、订阅与日志仅保存在使用者本机。代理服务端与订阅提供方仍可看到
  你的网络元数据，请自行评估其可信度。
- 本项目沿用上游 **GPL-3.0**（见 [LICENSE](LICENSE)）：可自由使用、修改与再分发，但衍生作品
  须以相同许可证开源。本仓库**只提供源码**，不提供已签名应用包或证书。

### English (summary)

This is an **unofficial, community-maintained HarmonyOS port** of Bettbox, with **no affiliation
with, endorsement by, or support from** the upstream project, Huawei, or any service provider. It is
a generic proxy client and **provides no proxy service, servers or subscriptions**, and is intended
**for learning, research and lawful network debugging only**. You are solely responsible for
ensuring your use complies with all applicable laws, regulations and service terms in your
jurisdiction; the authors and contributors accept **no liability** for any consequences of use.
The software is provided **"AS IS", without warranty of any kind**, under **GPL-3.0**, and only as
source code (no signed binaries). Full text: **[DISCLAIMER_en.md](DISCLAIMER_en.md)**.
