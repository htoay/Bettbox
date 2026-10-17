# 上游合并记录（2026-10-17）：Bettbox v1.19.5 → v1.19.6 → 鸿蒙移植分支

## 1. 上游本次发布内容

| 项 | 说明 |
|---|---|
| 上游仓库 | `https://github.com/appshubcc/Bettbox.git`（remote `upstream`，只读）|
| 变化 | `111c5d91`（v1.19.5）→ `9582976d`（v1.19.6）|
| 新增提交 | **16 个** |
| 规模 | 95 个文件变更（+3647 / −1903）|
| 共同祖先 | 上次合并落点 `111c5d91`（正好是 v1.19.5）|
| 是否含鸿蒙实现 | **否**。`ohos/**`、`scripts/**`、`third_party/**` 上游零改动 |
| 标签 | 新增 `v1.19.6`、`v1.19.6-test`（后者不在主线历史，未采用）、`v1.19.7-test` |

上游 v1.19.6 之后，主线还追加了 4 个提交（README 文案、Linux 系统 DNS 管理、
macOS Dock 图标同步、版本号 bump 到 1.19.7-test），**本次未同步**，留待下一版。

### 1.1 新增能力

- **编辑器缩放**：桌面端 Ctrl/Cmd + 滚轮、触控板双指/平移缩放；移动端双指缩放路径重构
  （围绕焦点、手感一致）。移动端与桌面共用编辑器组件，鸿蒙随同步获得双指缩放。
- **首页「运行模式」卡片重做**：规则 / 全局 / 直连三档改为带图标的整行按钮；
  卡片头部新增运行状态胶囊（代理启动状态与当前模式），点击直达对应设置面板。
- **覆盖规则支持脚本模式**：脚本开启时覆盖规则仍然生效；规则编辑器直接读取
  「实际生效」的配置（脚本产物、已剔除禁用分组），可针对真实节点/分组编辑。
- **运行时配置合成**：新增 `core/runtime_config.go`，运行时配置改为以原始 YAML 为底
  合并实际生效改动 —— 保留键顺序、未改动内容与写法，展开锚点/合并键，补丁中的强制字段
  生效，不再整份重排或丢失自定义键。
- **禁用分组联动**：读取配置时递归剔除被关闭分组的节点，空且无来源的分组连带移除，
  界面看到的分组与实际运行一致。

### 1.2 修复

- **自定义字体不生效**（部分 Android 设备）：emoji 字体只作用于 emoji 片段，
  不再全局设置字体回退。
- **页面保活下的返回栈**：非活动页不再拦截系统返回。
- **滚动与底栏遮挡**：横向滚动条方向跟随内容方向；底部悬浮导航栏为列表预留高度。
- **编辑器长文件布局**：自动换行长文件末尾 256 行精确测量行高，滚动定位更准。
- **桌面渲染**：Windows/Linux 关闭 Impeller，macOS amd64 关闭、arm64 保留。
- **Linux 授权与权限**：安装包内嵌 polkit 规则；setcap 失败、nosuid 挂载、
  文件系统不支持 xattr 等场景分别提示并回退 setuid；TUN 启动后校验运行中核心的实际权限。

### 1.3 优化

- **全局视觉统一**：卡片 / 对话框 / 弹层 / 底部表单统一超椭圆圆角
  （`RoundedSuperellipseBorder`），卡片按层级区分阴影与描边；输入框改为描边样式；
  弹出菜单重做（更大圆角、图标统一配色、hover/按压反馈、更紧凑内边距）。
- **底部导航栏**：指示器自绘并跟手滑动，带惯性判定与跨页重排动画；tab 切换由淡入淡出
  改为滑动；「动效反馈」开关统一控制导航栏动画与震动，开启时各 tab 页保持状态。
- **进程图标加载**：串行加载队列、按应用 bundle 归并缓存、Linux 图标在 isolate 内缩放、
  缓存淘汰同步清理、无图标时给场景化占位。
- **编辑器选择体验**：选中文本工具栏优先贴选区；编辑区鼠标拖拽不再触发滚动，
  鼠标框选/全选更顺。
- **新装默认设置**：代理列表默认展开卡片、延迟动画默认脉冲、自动吸顶默认关闭；
  桌面侧边栏默认折叠。
- **文案**：中文「访问控制 / 应用访问控制」统一为「分应用代理」；
  「触感反馈」更名为「动效反馈」。

## 2. 鸿蒙端同步内容

### 2.1 上游改动在鸿蒙端的适配

- **运行状态胶囊按 VPN 语义显示**：上游新胶囊用「是否 Android」决定 VPN / TUN 形态；
  鸿蒙与 Android 同走 VPN 实现，改为按「是否移动端」判断 —— 显示 **VPN** 状态并打开
  VPN 设置面板；鸿蒙没有系统 HTTP 代理能力，对应胶囊隐藏。
- **异常退出恢复覆盖鸿蒙**：上游在移动端异常退出后恢复配置；鸿蒙同样写 `is_vpn_running`
  标记，恢复检测由「仅 Android」放宽到移动端，进程被杀后启动可恢复一次配置。
- **字体策略保持**：上游移除了主题级 emoji 字体回退；鸿蒙继续保留
  `SpaceFix` + Twemoji 全局回退与系统字体族 `HarmonyOS Sans`，
  数字、空格与中英混排字距保持正常（emoji 由上游新的分段 EmojiText 负责）。
- **平台门控**：底部导航栏触感反馈、首页返回键处理、托盘/窗口/唤醒锁等鸿蒙增量
  按上游新结构迁移后保留；`lib_ohos.go` 无需跟随（本轮核心未改其对应接口）。
- **生成物**：arb 7 语言取两侧键并集（鸿蒙 11 个键 + 上游 6 个键）；
  `build_runner` 与 `intl_utils` 用鸿蒙工具链重新生成，freezed/json 生成物保留
  `VpnProps` 的鸿蒙自有字段。
- **原生库**：Go 核心随 `core/runtime_config.go` 等改动重建 `libmeta.so`；
  Rust 插件本轮无改动，`libcode_forge.so` 的 FRB content hash 不变。

### 2.2 版本与依赖

- `pubspec.yaml` 版本对齐上游：`1.19.6+2026101601`
  （应用内 `versionName 1.19.6` / `versionCode 2026101601`）。
- 依赖无变化：`material_ui 1.2.0` / `cupertino_ui 1.0.2` 垫片、
  `flutter_rust_bridge 2.13.0`、`flutter_displaymode`、`restart_app` 等保持既有钉定；
  `pubspec.lock` 维持鸿蒙依赖覆盖（path_provider / shared_preferences 的 OHOS 实现）。
- 新增上游文案键 `runningMode`、`coreCapabilityNotEffective`、`coreMountNosuid`、
  `setcapFailedFallback`、`setcapNotInstalledFallback`、`xattrUnsupportedFallback`；
  删除 `overrideInvalidTip`。

## 3. 发布产物

- HAP：`bettbox-1.19.6-ohos-vc2026101601-unsigned.hap` + 同名 `.sha256`
  （arm64-v8a，release，`APP_ENV=stable`；命名与校验规则见 `release_process_ohos.md`）。
- 发布标签：`ohos-v1.19.6`（指向发布快照提交）。

## 4. 未同步的上游提交（下一版处理）

1. `8ce0b280` — README 文案微调（无代码影响）。
2. `cee22bbc` — Linux 系统 DNS 管理：`nmcli` 设置/还原默认网卡 DNS，移除旧的
   Linux TUN 路由排除补丁；会涉及 `system.dart`、`core/patch.go` 与
   `providers/state.dart` 的鸿蒙平台判断，同步时需重新评估。
3. `4bd7a21d` — macOS Dock 图标与窗口同步（macOS 专属）。
4. `7006a026` — 版本号 bump 到 `1.19.7+2026101601`（v1.19.7-test）。
