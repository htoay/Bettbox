# Bettbox for HarmonyOS NEXT vVERSION（非官方移植版）

基于上游 [appshubcc/Bettbox](https://github.com/appshubcc/Bettbox) **vUPSTREAM_VERSION**（`UPSTREAM_COMMIT`）的鸿蒙移植发行版。
本分支只维护鸿蒙端适配；与上游作者、华为及任何服务提供商**无关联、无背书**（见 DISCLAIMER）。
对应本仓提交：`RELEASE_COMMIT`。

适用环境：**HarmonyOS NEXT / OpenHarmony，arm64-v8a**，设备类型 phone / tablet / 2in1。

<!--
发布说明模板（本仓鸿蒙移植版专用）。
占位符由 scripts/release_ohos.py 自动替换：
  VERSION / VERSION_CODE / HAP_NAME / HAP_SIZE / SHA256 / RELEASE_COMMIT / UPSTREAM_VERSION / UPSTREAM_COMMIT / TAG
每版需要人工维护的只有：标题下的上游版本、功能一览里的 🆕 标记、以及「本次更新」三节内容。
命名与流程规则见 docs/release_process_ohos.md；禁止把构建机路径、设备型号/序列号、账号信息写进来。
-->

---

## ⬇️ 下载

| 文件 | 大小 | 说明 |
| --- | --- | --- |
| `HAP_NAME` | HAP_SIZE MiB | **未签名** HAP，arm64-v8a |
| `HAP_NAME.sha256` | — | 上面文件的 SHA-256 |

```
版本：versionName VERSION / versionCode VERSION_CODE / bundleName com.appshub.bettbox
SHA-256：SHA256
校验：  sha256sum -c HAP_NAME.sha256
```

> **为什么只有未签名包**：鸿蒙签名必须绑定开发者证书与设备 UDID，签名后的 HAP 会内嵌签名者的
> developer-id 与设备 UDID 列表，属于签名者的隐私，不应随发行版分发。
> 请用你自己的证书/Profile 签名后安装（步骤见文末）。

---

## 鸿蒙端功能一览

> **🆕 = 相对上一版 `ohos-vPREV_VERSION` 新增或本次才可用**

### 代理与网络

- VPN（TUN）模式启动/停止；混合端口提供 **HTTP / SOCKS5** 代理；规则 / 全局 / 直连三种模式。
- **运行状态胶囊**：首页运行模式卡片显示 VPN 启停状态与当前模式，点击直达 VPN 设置面板。
- **局域网连接（allow-lan）**：同一局域网内的其它设备可经本机代理上网。
- **设备 DNS 下推**：把物理网络的真实 DNS 下发给核心，避免回退到内置公共 DNS 造成解析污染。
- 系统级 DNS 覆写开关：鸿蒙不开放系统 DNS 接口，按 vNIC DNS 语义生效（见「已知限制」）。
- **「网络变化时清空 DNS 缓存」开关**：切换 Wi-Fi / 移动网络后，不再出现已缓存域名仍指向
  旧网络、短时间内打不开的情况。
- **MTU 取值范围与鸿蒙 VPN 对齐**（576–1500，预设 1500/1400），设置值与实际生效值一致。
- 正式（release）构建下，VPN 扩展进程与主进程通过**抽象命名空间 socket** 交接 TUN fd，
  release 包与 debug 包同样可用。

### 后台与保活

- **长时任务保活**，可选模式：数据传输 / 音频播放 / 计算任务（设置项与系统通知文案一致）。
- **取消自愈**：长时任务被系统取消后秒级重申请，并有 30s 看门狗兜底，后台长时间运行不被冻结。
- **异常退出恢复**：进程被系统清理后再次启动时自动恢复一次当前配置。

### 交互与功能

- 🆕 **网络工具箱**：IP 查询、本地 Ping、路由跟踪、NAT 类型测试、DNS 查询、
  MRS 规则查询、iPerf3 内网测速、AGE 加密工具等，入口在侧栏「更多」菜单。
- 🆕 **网页测速**：支持自动选择或手动指定 Speedtest 服务器、选择出站与协议
  （HTTP/3 → HTTP/2 → HTTP/1.1 自动回退）、多线程并发，并保留 14 天测速历史。
- 🆕 **自动备份**：配置变更后经 WebDAV 自动备份（备份与恢复页开启）。
- **深链 `clash://install-config?url=…`**：从浏览器或二维码一键导入订阅。
- **脚本覆写（Script）**：由 Rust 引擎（rquickjs）执行，随包提供。
- **覆盖规则支持脚本模式**：规则编辑器读取实际生效的配置（脚本产物、已剔除禁用分组）。
- **运行时配置预览**：以原始配置为底合并生效改动，保留键顺序与未改动内容。
- **代码编辑器缩放**：编辑区支持双指缩放。
- **仪表盘「更多 IP 信息」**：网络类型、内网 IP、默认网关、系统 DNS。
- 订阅 / 配置 / 规则 / 代理组 / 连接 / 日志 / 备份与恢复等全部界面功能可用。

### 界面与显示

- **仪表盘卡片重设计**：卡片支持增删与调整大小；「活跃连接」卡片新增 TCP/UDP
  分类计数与历史柱状图；「请求」页并入「连接」页。
- **主题动态取色** 🆕：可从核心配置的调色板提取主题色。
- **运行模式卡片与底部导航**：状态胶囊 + 三档模式按钮；底部导航指示器跟手滑动，
  「动效反馈」开关统一控制导航栏动画与震动，开启时各页面保活。
- **全局视觉统一**：卡片 / 对话框 / 弹层统一超椭圆圆角，弹出菜单与输入框样式一致。
- **应用图标为上游正式图标**（含启动页图标），桌面名称显示为 **Bettbox**。
- 弹窗与对话框、页面生命周期渲染正常（打开即用，不会黑屏/卡死）。
- **中文与英文混排、数字与空格的字距正常**，不再出现被系统 emoji 字体接管导致的异常字距。

### 打包

- 仅打包 **arm64-v8a**（不含模拟器用的 x86_64 库）。

---

## 本次更新（相对 `ohos-vPREV_VERSION`）

### 同步上游

同步上游 **v1.19.7**（26 个提交，含上一版遗留的 4 个）。核心（Mihomo/Clash.Meta）更新：
sudoku 传输重写、多项传输与协议栈改进；Rust 脚本引擎与编辑器组件同步更新。

### 新增

- **网络工具箱**：IP 查询、本地 Ping、路由跟踪、NAT 类型测试、DNS 查询、MRS 规则查询、
  iPerf3 内网测速、AGE 加密工具（侧栏「更多」菜单进入）。
- **网页测速**：Speedtest 服务器可选（自动/手动指定），出站、协议（HTTP/3/2/1.1 回退）、
  多线程连接数可配置，保留 14 天测速历史。
- **自动备份**：配置变更后经 WebDAV 自动备份，在「备份与恢复」页开启。
- **TUN dns-mode**：TUN 配置支持 dns-mode 选择；仪表盘运行状态胶囊按运行中核心的
  真实 TUN 状态点亮。
- **主题动态取色**：从核心配置的调色板提取主题色。

### 修复

- 媒体解锁检测改进：检测项与判定更准确。

### 优化

- **仪表盘卡片重设计**：卡片支持增删与大小调整；「活跃连接」卡片新增 TCP/UDP 分类
  与历史柱状图；「请求」并入「连接」页。
- Code Forge 编辑器高亮与交互细节优化。
- 核心运行时加固与 Clash.Meta 更新。

---

## 已知限制

- **按应用分流暂不可用**：`PROCESS-NAME` / `PROCESS-PATH` 规则在鸿蒙上不会命中，
  连接列表也不显示应用名与图标。
- **系统 HTTP 代理**：鸿蒙未提供对应系统能力，「系统代理 / 绕过域名」两项在鸿蒙端已隐藏；
  需要走代理的程序请手动指向 `127.0.0.1:<混合端口>`。
- 常驻通知速率、桌面快捷方式、电池优化白名单：鸿蒙无对应能力，相关入口保持隐藏。
- **智能停机**在鸿蒙上为整机停止/启动（功能可用，但恢复时需重新建立 VPN）。
- 低版本系统上，部分依赖较新 API 的能力（防回环保护、PC 状态栏托盘等）可能不可用。

---

## 安装（未签名包需自行签名）

1. **准备签名材料**：用 DevEco Studio 的自动签名（需登录华为开发者账号并把你的设备 UDID 加入调试证书），
   或自行申请证书与 Profile。
2. **签名**：用 DevEco Studio 打开工程 → `Build > Generate Signed HAP/APP`，选中下载的 HAP；
   或用你自己的签名工具（hapsigner 等）签名。
3. **安装**：

   ```bash
   hdc install -r <已签名的>.hap
   ```

---

## English summary

Unofficial HarmonyOS NEXT port of Bettbox, based on upstream **vUPSTREAM_VERSION** (`UPSTREAM_COMMIT`),
commit `RELEASE_COMMIT`. Requires HarmonyOS NEXT / OpenHarmony on **arm64-v8a** (phone / tablet / 2in1).

<!-- 英文部分与中文一一对应：Already available / 🆕 New in this release / Known gaps / Artifact -->

**Artifact**: unsigned HAP (`HAP_NAME`, HAP_SIZE MiB) + `.sha256` (`SHA256`). Sign it with your own
certificate/profile before installing.
