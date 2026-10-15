# 上游合并记录（2026-09-27）：Bettbox 上游更新 → 鸿蒙移植分支

## 1. 上游发生了什么

| 项 | 说明 |
|---|---|
| 上游仓库 | `https://github.com/appshubcc/Bettbox.git`（origin）|
| 变化 | `origin/main` **强制更新**：`55067faf` → `26865630`（`Release v1.19.3`）|
| 原因 | 上游重写了 `Update core`（本地等价提交 `55067faf`，被上游重做为 `7395c5c6`，且内容更新了 7 个 `core/Clash.Meta` 文件）|
| 新增提交 | 18 个（+2949 / −630，101 个文件）|
| 共同祖先 | `efa8083a Fix app start configuration failed` |
| 是否含鸿蒙实现 | **否**。上游 `grep -i ohos` 命中的全部是 `plugins/flutter_distributor/examples/hello_world/ohos/`（插件示例）与字体资源；`ohos/` 应用宿主、`core/lib_ohos.go`、`scripts/*` 仍只存在本仓库 |

### 上游主要新功能（已并入）

- allow-lan 用户认证（用户名/密码、跳过本机认证）
- WebDAV 备份版本管理 + 轻量加密
- Windows 便携模式 + 便携版清理工具、Helper 服务健康检查重写
- Android 边到边优化、Android 17 兼容
- 代理列表吸顶（sticky header）、设置项行内按钮样式、更多解锁测试（YouTube Music 等）
- **核心库改名 `libclash.so/.h` → `libmeta.so/.h`**（`setup.dart`、Android CMake、`lib/clash/lib.dart` 全部同步）

## 2. 处理方式（分支布局）

```text
26865630  Release v1.19.3                      ← main（= origin/main，纯上游跟踪）
   └─ 4180f671  feat(ohos): 鸿蒙端移植（重放到上游 v1.19.3）+ 2026-09-27 缺陷修复
                                                  ← ohos-port（当前工作分支）
5b3258d2  chore(ohos): 备份（合并前的完整工作副本）  ← ohos-port-backup（+ tag ohos-port-backup-20260927）
```

做法与理由：

1. **先备份**：把合并前「未提交的鸿蒙移植 + 修复」整体提交到 `ohos-port-backup`，避免任何不可逆操作。
2. **丢弃被上游取代的本地提交**：本地唯一领先提交 `55067faf` 已被上游重写，合并它只会引入重复内容；因此直接把移植**重放**（cherry-pick）到 `origin/main` 之上：`git switch --detach origin/main && git cherry-pick --no-commit ohos-port-backup`。
3. **冲突解决**（仅 11 个文件，其余自动合并）：
   - `arb/intl_*.arb`（7 个）：两侧各自新增键，取**并集**，并用 `json.loads` 校验 JSON 合法；
   - `lib/l10n/l10n.dart`（生成文件）：以**上游文件为基准**，把「我方独有的 10 个 getter」插回 `AppLocalizations` 内（`descOhos`、`backgroundTask*`、`mode*`、`addPackageName`、`invalidPackageName`、`ohosAccessManualOnly`），共 770 个 getter；未做手工并集的 5 个冲突块；
   - `lib/common/path.dart`：保留上游的 Windows 便携模式分支 + 我方的 `catchError` 兜底（两侧都要）；
   - `lib/main.dart`：`flutter/services.dart` 与 `flutter_rust_bridge` 两个 import 都保留；
   - `lib/views/application_setting.dart`：`isMobile` 的导航栏触感项 + 上游新增的 macOS Dock 图标项都保留。
4. **合并适配（上游改名）**：鸿蒙侧同步 `libclash.so` → `libmeta.so`：
   - `scripts/build_native.py`：`-o` 输出改为 `libmeta.so`；
   - 删除遗留产物 `ohos/entry/libs/arm64-v8a/libclash.{so,h}`，重新构建出 `libmeta.{so,h}`；
   - `scripts/build_ohos.py` 注释、`lib/main.dart` 注释、`docs/*` 引用同步；
   - 说明：`lib/clash/lib.dart` 是上游代码，鸿蒙的 `ClashOhosLib` 复用同一个 `ClashLibHandler`，因此**产物名必须跟上游一致**，否则鸿蒙端 FFI 会找不到库。
5. **上游新功能与鸿蒙的关系**（复核过，无需改动）：
   - `services.googleapis.cn` 的 store-fix 主机项上游已改为「仅 Android 注入/可删除」，鸿蒙与桌面同组行为正确；
   - Windows 便携模式、Helper 服务、macOS Dock 图标等与本端无关；
   - 上游 `plugins/code_forge` 改动只在 Dart 层（Rust crate 未变、`flutter_rust_bridge` 仍 `=2.12.0`），预编译的 `libcode_forge.so` 仍然有效。

## 3. 验证结果

| 项 | 结果 |
|---|---|
| `dart analyze lib test` | ✅ 0 error（仅 2 条既有 warning：`clash/core.dart:220`、`clash/ohos.dart:9`）|
| Go 核心重建（`scripts/build_native.py --go-only`，含上游新 core）| ✅ 产出 `libmeta.so` 72 MB；`TLS 重定位检查通过，无 R_AARCH64_TLS_TPREL` |
| 鸿蒙构建标签是否保留 | ✅ `features/android.go` = `android \|\| ohos`、`dns/system_common.go` = `!android && !ohos`、`tun/platform/android_bride` = `(android \|\| ohos) && cgo`、`lib_other.go` = `!android && !ohos && cgo` 全部完好 |
| 上游 core 是否新增需镜像的 android 专属文件 | ✅ 未新增（仍是原先 10 个，鸿蒙侧 `patch_ohos.go` 系列已覆盖）|
| l10n 双侧键 | ✅ `userAuth`（上游）与 `ohosAccessManualOnly`（我方）同时存在 |
| 生成模型双侧字段 | ✅ `keepDockIcon`（上游）与 `backgroundTaskMode/backgroundTaskEnabled`（我方）同时存在 |
| ArkTS/HAP | 本次合并未改动 `ohos/**`，沿用上一轮 `hvigorw assembleHap` 的 `BUILD SUCCESSFUL` 结论；建议合并后按 §4 完整跑一次 |

## 4. 后续上游更新流程（推荐）

```bash
# 1) 拉取上游
git fetch upstream

# 2) 在移植分支上合并（保持 main 为纯上游镜像）
git switch ohos-port
git merge upstream/main            # 或：git rebase upstream/main（历史更线性，冲突处理更集中）

# 3) 冲突解决要点（本仓库的经验）
#    - arb/*.arb：两侧新增键取并集，注意 JSON 逗号
#    - lib/l10n/l10n.dart、lib/models/generated/*：优先用上游版本，再把「我方新增」补回；
#      在可写环境可直接重生成：
#         flutter pub run intl_utils:generate
#         dart run build_runner build --delete-conflicting-outputs
#    - lib/common/path.dart、lib/common/system.dart、lib/state.dart、lib/controller.dart、
#      lib/views/*：逐块合并，原则是「上游新功能 + 我方 isOhos/isMobile 分支都要保留」
#    - core/Clash.Meta 的构建标签：确认 android → android || ohos 的 4 处镜像仍在
#      （features/android.go、features/android_stub.go、dns/system_common.go，以及 core/ 下 4 个文件）

# 4) 重新构建与验证
python3 scripts/build_native.py          # Go(libmeta.so) + Rust(libcode_forge.so)
python3 scripts/build_ohos.py            # 完整 HAP（含 pubspec_overrides 注入、版本同步）
```

## 5. 注意事项

1. **上游 core 引入了新依赖**（如 `github.com/enfein/mieru/v3`、`github.com/metacubex/mipstack` 新版本）。首次构建需要能联网拉取 Go module；若本机 `GOMODCACHE` 只读，可临时指定工作区内缓存：
   `GOMODCACHE=$PWD/core/build/gomodcache GOCACHE=$PWD/core/build/gocache python3 scripts/build_native.py --go-only`
2. 本次生成文件（`lib/l10n/l10n.dart`、`lib/models/generated/*`）是用「上游 + 我方新增」并集方式手工合并的，语义正确；如需与生成器输出完全一致，请在可写环境重跑 §4 中的生成命令（本机沙箱内 pub 缓存只读，无法执行）。
3. `ohos/entry/libs/` 下的 `libmeta.so`、`libcode_forge.so` 是构建产物（已被 `.gitignore` 忽略），不随提交分发；拉取代码后需自行执行 §4 的构建命令。


---

## 2026-10-03 第二次上游合并：v1.19.3 → v1.19.4

上游 `26865630` → `45d6fd37`（Release v1.19.4，18 个提交：策略组脚本设置、IP 信息弹窗、
UI 性能优化、核心稳定性、Windows bypass、mips 拥塞控制、更多媒体解锁测试等）。

### 冲突与解决（11 处，与上次同一批文件）

- `.gitignore`：并集
- `arb/intl_*.arb`（7 个）：并集（上游为主 + 我方独有键）
- `core/action.go`：采纳上游错误文案 + 保留我方 panic 日志
- `lib/controller.dart`：保留我方 `isDesktop` 门控 + 采纳上游 5s 延迟自动更新
- `lib/l10n/l10n.dart`：以上游为基准 + 我方 11 个 getter 完整块补回

### 生成文件（本次的坑，务必按此做）

`lib/l10n/intl/messages_*.dart` 不能用「按行插入」手改（多行条目会截断，且
`dart analyze` 不报、编译期才炸）。正确做法：

1. 以上游版本为**基准**；
2. 把我方独有的键（`descOhos`/`backgroundTask*`/`mode*`/`addPackageName`/
   `invalidPackageName`/`ohosAccessManualOnly`）从 `7146cbf0`（合并前）**按括号匹配
   整体提取**后补回（Dart map 字面量顺序无关）；
3. `messages_all.dart` 是纯加载器，**整体取上游**（两代生成规范不一致会导致
   `Future<dynamic> Function()` 类型错误）；
4. 有网络时更省事：`flutter pub run intl_utils:generate`。

### 核心侧（Go）

上游给 `t.Start(...)` 增加了第 7 个参数（拥塞控制算法）：
`core/lib_ohos.go` 调用点需与 `core/lib_android.go` 对齐，传
`currentConfig.General.Tun.CongestionController`。
构建标签镜像 `android || ohos`（4 处）保持有效。

### 验证

- `dart analyze lib`：干净（仅 2 条既有 warning）
- `flutter build hap --release --no-codesign --dart-define=APP_ENV=stable`：通过
  （本次因本机 `flutter pub get` 网络失败，构建用 `--no-pub` 复用已解析依赖）
- 原生核心：`libmeta.so` 72MB，TLS 重定位检查通过
- 产物：`build/ohos/hap/bettbox-1.19.4-ohos-unsigned.hap`（1.19.4，arm64-only，无探针）
- 我方标记完好：`isOhos`(19 文件)、抽象 socket、`taskKeeping`、`sendTunFd`


---

## 远程与分支约定（2026-10-03 起：自有 fork 作为鸿蒙发行版）

决定不向上游提 PR（上游无 CONTRIBUTING/PR 模板；且鸿蒙端依赖 flutter_ohos 分支工具链，
上游 CI 用官方 Flutter，无法构建）。改为维护自有 fork：

- `upstream` = https://github.com/appshubcc/Bettbox.git（只读，用于跟进）
- `origin`  = 自己的 fork（推送目标，创建 fork 后自行添加）
- `main`    = **纯上游镜像**（只 `git fetch upstream && git merge --ff-only`）
- `ohos-port` = 鸿蒙工作分支（所有移植改动 + 上游合并都在这里）
- 标签 `ohos-vX.Y.Z` = 对应上游版本的鸿蒙发行点（如 `ohos-v1.19.4`）

同步上游：
```bash
git fetch upstream && git merge upstream/main      # 在 ohos-port 上
python3 scripts/build_ohos.py                       # 推荐：内含 build_native.py（Go+Rust）+ 注入 ohos 依赖覆盖 + flutter build hap
```

> ⚠️ **不要**直接 `flutter build hap` / 手动 `flutter pub get`：鸿蒙端的 `shared_preferences` /
> `path_provider` 依赖 OHOS 实现，它们由 `scripts/build_ohos.py` 在构建期从
> `ohos/pubspec_overrides.yaml` 注入。绕过脚本会解析出 pub.dev 原版实现 —— **能构建成功，
> 但装到鸿蒙上是坏包**（2026-10-16 合并时复核确认）。
> 只重建核心不打包：`python3 scripts/build_native.py`。


### 公开分支策略（2026-10-03）

对外推送使用**干净快照分支** `ohos-port-clean`（单根提交、脱敏后的树），
本地 `ohos-port` / `ohos-port-backup` 保留完整开发历史但**不外推**。
后续开发在 `ohos-port-clean` 上进行；每次上游合并后照常重建核心并推送该分支。
