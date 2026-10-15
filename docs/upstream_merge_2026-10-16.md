# 上游合并记录（2026-10-16）：Bettbox v1.19.4 → v1.19.5 → 鸿蒙移植分支

## 1. 上游发生了什么

| 项 | 说明 |
|---|---|
| 上游仓库 | `https://github.com/appshubcc/Bettbox.git`（remote `upstream`，只读）|
| 变化 | `45d6fd37`（Release v1.19.4）→ `111c5d91`（v1.19.5 及之后若干提交）|
| 新增提交 | **52 个** |
| 规模 | 735 个文件变更（+54060 / −142309），其中 338 个删除、97 个新增 |
| 共同祖先 | `45d6fd37`（正好是 v1.19.4，上次合并的落点）|
| 是否含鸿蒙实现 | **否**。`ohos/**` 与 `scripts/**` 上游零改动 |
| 标签 | 新增 `v1.19.5`、`v1.19.5-test`、`v1.19.6-test`、`1.19.5-test` |

### 上游主要变化（本次合并的重点）

- **JS 脚本引擎换代**：删除 `plugins/flutter_qjs`（整份 quickjs C 源码，189 个文件），改为 `plugins/code_forge` 的 Rust 实现（`rust/src/script/**`，基于 `rquickjs`），Dart 侧入口变成 `package:code_forge/script.dart` 的 `rust.evaluateScriptFile(...)`。`lib/common/js_runtime_manager.dart` 整体重写，新增 `lib/common/rust.dart`（`ensureRustLib()`）。
- **UI 依赖换代**：`package:flutter/material.dart` → `package:material_ui/material_ui.dart`（140 个文件），新增 `cupertino_ui`；需要 MethodChannel 的文件改为额外 import `flutter/services.dart`。
- **状态管理换代**：riverpod 2.6 → 3.4、riverpod_generator 2.6 → 4.0、freezed 3 → 4、json_serializable / build_runner 升级。
- **flutter_rust_bridge 2.12.0 → 2.13.0**（`dependency_overrides` 也同步），code_forge 插件 10.9.0 → 10.14.0。
- **核心（Go）**：新增 `core/patch.go`（配置改写：DNS listen `:53→:10053`、NTP、TUN 路由排除）、`core/bundle.go`、`core/permission_unix.go`/`permission_other.go`、`core/hub_test.go`/`patch_test.go`/`bundle_test.go`；`handleSetupConfig` 返回值由 `string` 变为 `*SetupResult`。
- 依赖升级：`file_picker 8→13`、`win32 5→6`、`device_info_plus 12→13`、`package_info_plus 9→10`、`animations 2→3`、`dynamic_color 1.8→2.1`、`app_links 6→7`、`win32_registry 2→3`、`connectivity_plus`、`wakelock_plus`、`json_annotation`、`build_runner`、`intl_utils 2.8.11→2.8.17`。
- 删除依赖：`flutter_displaymode`；`launch_at_startup` 由 pub 包改为本地 `plugins/launch_at_startup`。
- 其他：桌面侧边栏 flyout、about 页重构、dashboard 控件增强、日志控制台 AI 搜索、DNS 网络变化刷新、Windows 兼容构建、媒体解锁相关上限 4→3、`core/Clash.Meta` wireguard/fakeip/doh/shadowsocks 修复。

## 2. 处理方式

```text
111c5d91  (upstream/main, v1.19.5)
   └─ <merge commit>  merge: 上游 v1.19.5（52 提交）并入鸿蒙移植分支   ← ohos-port
61776f5b  chore: 脱敏…                                                ← ohos-port-premerge-v1.19.5（合并前备份）
```

1. **先备份**：`git branch -f ohos-port-premerge-v1.19.5 HEAD`（+ tag `premerge-v1.19.5-20261016`）。
2. **合并而非重放**：本次上游**没有**重写历史（不像 v1.19.3 那次 force-push），共同祖先就是上次的落点，所以直接 `git merge --no-ff upstream/main`，历史可追溯。
3. **冲突 35 处**，按层分派并行解决（写范围互不重叠）：

| 层 | 文件 | 要点 |
|---|---|---|
| 本地化 | `arb/intl_*.arb`(7)、`lib/l10n/l10n.dart`、`lib/l10n/intl/messages_*.dart`(7) | arb 取**两侧键的并集**；生成文件以上游为基准 + 按括号匹配补回我方 11 个独有键 |
| Dart 核心 | state / controller / main / clash/lib / common/picker / common/tray | 上游新结构 + 重放我方鸿蒙增量 |
| Dart 视图 | views/**、pages/scan、widgets/google_bottom_nav_bar | 上游新 UI + 我方 isMobile/isOhos 门控 |
| 原生/插件 | core/**、plugins/code_forge | 构建标签镜像核对 + 编译断裂修复 |
| Lead | pubspec.yaml、pubspec.lock、README.md、生成文件 | 版本与依赖裁决、代码生成 |

### 关键裁决

0. **依赖版本必须向下钉：上游基线是 Flutter 3.47 / Dart 3.13+，鸿蒙工具链只有 Dart 3.12.2**
   上游 v1.19.5 把 UI 迁到 `material_ui`、把代码生成迁到 `freezed 4`，这两条都把 SDK 下限抬到了 Dart 3.13
   （`material_ui >=1.4.0` 要求 `sdk ^3.13.0 && flutter >=3.47.0`、`freezed 4.0.0` 要求 `sdk >=3.13.0`），
   而 OHOS Flutter fork 目前最新只到 **3.44.9（Dart 3.12.2）**，没有 3.47-ohos 可用 → **必须在不改上游源码的前提下向下钉版本**：

   | 包 | 上游 | 本仓钉定 | 原因 |
   |---|---|---|---|
   | `material_ui` | `^1.6.0` | **`1.2.0`** | 1.4.0+ 要求 Dart ^3.13.0；1.3.0 已被 pub.dev **撤回**（retracted） |
   | `cupertino_ui` | `^1.1.2` | **`1.0.2`** | 1.1.1+ 要求 Dart ^3.13.0；1.1.0 亦被**撤回** |
   | `freezed` | `^4.0.2` | **`^4.0.0-dev.3`** | 4.0.0 正式版要求 Dart >=3.13.0；dev.3 的 `sdk >=3.12.0`，且 `analyzer ^13` 与 riverpod_generator 4.0.9 相容 |
   | `build_runner` | `^2.16.2` | **`2.15.1`** | 约束链：`flutter_test`(sdk) 钉死 `meta 1.18.0` → `analyzer` 必须 `<13.1.0` → `build_runner` 必须 `<2.15.2` |
   | `plugins/code_forge` 的 `material_ui` | `^1.6.0` | **`1.2.0`** | 与根 pubspec 对齐（否则 path 依赖求解失败） |

   运行时依赖（`riverpod 3.4.3` / `flutter_riverpod 3.4.3` / `riverpod_annotation 4.0.7` / `riverpod_generator 4.0.9` /
   `json_serializable 6.14.1` / `json_annotation 4.12.0`）都支持 Dart 3.12，**与上游一致，无需降级** →
   上游的 riverpod 3 迁移与 freezed 4 生成文件可以原样保留。

   ⚠️ **技术债**：等 OHOS Flutter 升到 ≥3.47（Dart ≥3.13）后，应把上表 4 项恢复成上游的版本区间。

0. **`pubspec.lock`**：以上游 v1.19.5 的 lock 为基准重新解析（工作区 PUB_CACHE），
   因为鸿蒙依赖覆盖（`ohos/pubspec_overrides.yaml` 把 `shared_preferences` / `path_provider` 指向 OHOS 实现）只在
   `scripts/build_ohos.py` 运行期注入，所以**必须走 `scripts/build_ohos.py` 构建**，直接 `flutter build hap` 会解析出
   pub.dev 原版实现 → 能编译出包但鸿蒙上不可用（静默坏包）。

1. **`pubspec.yaml`**：整体采上游（riverpod 3.4 / freezed 4 / FRB 2.13 / material_ui / cupertino_ui / launch_at_startup 本地路径），**保留我方两处**：
   - `flutter_displaymode: ^0.7.0`（上游删除，但 `lib/main.dart`、`lib/application.dart` 仍在用）；
   - `flutter_rust_bridge: 2.13.0` 作为直接依赖（上游只在 dev_dependencies 给 `any`，而 `lib/common/rust.dart` 直接 import 它）。
   - **删除 `flutter_qjs`**：上游弃用，且全仓已无引用。
2. **`README.md`**：本 fork 的 README 是鸿蒙移植文档（2026-10-03 起替换了上游 README），上游的营销段落与其冲突 → **整体取我方**，只把版本号与「上游更新后必须重建核心」的例子更新到 v1.19.5。`readme/README_zh_upstream.md` 重新同步为「上游 v1.19.5 README + 顶部鸿蒙提示块」。
3. **首次构建后必须重建两个原生库**（见 §3）。
4. **`core/patch.go` 的 `runtime.GOOS` 分支必须补鸿蒙（本次合并发现并修复的回归）**：
   合并前（HEAD `61776f5b`）这两件事是 Dart 做的，且条件是我方刻意放宽过的 `system.isMobile`（= `isAndroid || isOhos`）：
   - `lib/state.dart:972` DNS `listen` 的 `:53 → :10053` 改写与 `0.0.0.0 → 127.0.0.1` 收窄；
   - `lib/state.dart:1002` `ntp.write-to-system = false`。

   上游 v1.19.5 把这段逻辑搬进了 Go 的 `core/patch.go`，条件改成 `patchForAndroid = runtime.GOOS == "android"`；而鸿蒙是 `GOOS=linux` + `-tags ohos`，`runtime.GOOS` 得到 `"linux"` → **这两项在鸿蒙上被静默丢弃**（迁移即回归）。

   修法：新增两个**互补**的编译期常量文件（`android || ohos` 与 `!android && !ohos` 覆盖全集，避免 macOS/Windows 出现未定义符号）：
   - `core/patch_platform_mobile.go`（`//go:build android || ohos`）→ `const patchAndroidLike = true`
   - `core/patch_platform_other.go`（`//go:build !android && !ohos`）→ `const patchAndroidLike = false`
   - `core/patch.go`：`patchForAndroid = runtime.GOOS == "android" || patchAndroidLike`；`patchForLinux = runtime.GOOS == "linux" && !patchAndroidLike`（保持 `var`，`patch_test.go` 的改写不受影响）。

   真值表（`go list`/编译实测）：

   | 构建 | `patch_platform_*` 选中 | patchForAndroid | patchForLinux |
   |---|---|---|---|
   | `GOOS=linux -tags with_gvisor,ohos`（鸿蒙） | mobile | **true**（恢复 DNS/NTP 改写） | false |
   | `GOOS=linux`（桌面） | other | false | true（行为不变） |
   | `GOOS=darwin` / `GOOS=windows` | other | false | false（无未定义符号） |
   | `GOOS=android` | mobile | true | false（行为不变） |

   注意：`framework` 里的 `Platform.isLinux` 在鸿蒙上为 false（`isOhos` 与 `isLinux` 互斥判断同一个 `operatingSystem` 字符串），因此 `patchForLinux` 变 false 只影响 `patchTunRouteExclude`，而它本就因 `tun.auto-redirect = system.isLinux` 为 false 而提前返回 → 无可观测行为变化。

5. **`material_ui` / `cupertino_ui` 必须换成 OHOS 垫片（本次第二个阻塞级适配）**：
   上游把 UI 迁到外部包 `material_ui` / `cupertino_ui`（Flutter 官方 material/cupertino 库的**整份再发布副本**）。
   但 flutter_ohos 分支给 `TargetPlatform` 枚举加了 `ohos`，而那份副本里所有**穷举** `TargetPlatform` 的 switch 都没有 `ohos` 分支
   → Dart 前端直接报 `The type 'TargetPlatform' is not exhaustively matched ... 'TargetPlatform.ohos'`，
   **HAP 构建在 `kernel_snapshot_program` 阶段失败**（实测 166 处，分布在两个包的 40+ 文件；
   `dart analyze` 不会报，只有真正编译才暴露）。

   修法：新增两个本地垫片包 `third_party/material_ui` 与 `third_party/cupertino_ui`，
   直接 `export 'package:flutter/material.dart'` / `export 'package:flutter/cupertino.dart'`
   （**加上** `flutter_localizations`，因为上游代码靠 material_ui 顺带拿到 `GlobalMaterialLocalizations`），
   再用 `dependency_overrides` 指向它们。好处：
   - 上游 140 个文件的 `import 'package:material_ui/material_ui.dart';` **逐字不变**（不产生合并分歧）；
   - 用的正是 flutter_ohos 自带的、已处理 `TargetPlatform.ohos` 的 material（该工具链里有 82 个文件带 ohos 处理）；
   - 顺带摆脱了「material_ui 1.3.0/1.1.0 被 pub.dev 撤回、1.4.0+ 要 Dart ^3.13」的版本坑。

   ⚠️ **`ohos/pubspec_overrides.yaml` 必须重复根 pubspec 的所有 overrides**：pub 会用该文件的
   `dependency_overrides` **整体替换**（而非合并）根 pubspec 的同名段 —— 本仓已因此静默丢过一次（垫片不生效、
   构建又回到 166 处报错）。文件里已写明这条约定。

## 3. 原生库重建（本次必做）

| 库 | 结论 | 证据 |
|---|---|---|
| `libmeta.so`（Go 核心） | **必须重建** | 上游改了核心（新增 patch.go/bundle.go/permission_*.go，`handleSetupConfig` 返回值变更）|
| `libcode_forge.so`（Rust 插件） | **必须重建** | FRB 2.12→2.13：旧 .so 的 `frb_get_rust_content_hash` 反汇编为 `434014572`（合并前的值），而新 Dart 侧期望 `834704942`；旧 .so 里也没有新增的 `evaluate_script_file` 等 API |

### 发现的编译断裂（已修）

- **`core/lib_ohos.go`**：上游把 `core/hub.go: handleSetupConfig` 的返回值从 `string` 改成 `*SetupResult`，而 `core/dart-bridge/lib.go: SendToPort(port int64, msg string)` 只接受 string。`lib_ohos.go` 是 `lib_android.go` 的**手工双份拷贝**，不会自动跟随 → 鸿蒙编译期必失败。修复：镜像上游 `lib_android.go` 的写法（补 `return`、`json.Marshal` 后转 string）。
- **`plugins/code_forge/rust/Cargo.toml`**：鸿蒙 triple 的 cfg 是 `target_os="linux"` + `target_env="ohos"`，**不会命中**上游的 `cfg(target_os="android")` bindgen 分支；而 `rquickjs-sys` 在未开 bindgen 时会 `include!(bindings/aarch64-unknown-linux-ohos.rs)`，该文件不存在 → 编译必失败。修复：照抄上游 android 写法新增 `[target.'cfg(target_env = "ohos")'.dependencies]` 开 bindgen（`bindgen 0.72.1` 本就在 Cargo.lock 里，不动 lock）。
- **`scripts/build_native.py`**：`rust_ohos_env()` 增加 `LIBCLANG_PATH` 与 `BINDGEN_EXTRA_CLANG_ARGS`（从已探测的 NDK 布局推导，不写死本机路径）——bindgen 需要 NDK 自带的 libclang 与目标 sysroot 头文件。

### 构建命令

```bash
export GOMODCACHE=$PWD/core/build/gomodcache GOCACHE=$PWD/core/build/gocache
python3 scripts/build_native.py            # Go(libmeta.so) + Rust(libcode_forge.so)
```

产物校验：
- `libmeta.so` ≈ 72.5 MB，`llvm-readelf -r` 无 `R_AARCH64_TLS_TPREL`（musl 无法 dlopen 的 initial-exec TLS 重定位）；
- `libcode_forge.so` ≈ 3.0 MB，`frb_get_rust_content_hash` 反汇编必须等于 Dart 侧 `FLUTTER_RUST_BRIDGE_CODEGEN_CONTENT_HASH`。

## 4. 鸿蒙构建标签镜像清单（核对结论）

上游本次新增的 8 个 core 文件**没有任何 android 构建标签**，被改文件也未新增标签 → **无需新增镜像**。清单最终态：

| 类别 | 数量 | 文件 |
|---|---|---|
| 单文件真镜像 `android \|\| ohos` | 4 | `core/android_bride.go`、`core/platform/limit.go`、`core/tun/tun.go`、`core/Clash.Meta/constant/features/android.go` |
| 负向排除 `!android && !ohos` | 3 | `core/lib_other.go`、`core/Clash.Meta/constant/features/android_stub.go`、`core/Clash.Meta/dns/system_common.go` |
| 手工「双份拷贝」 | 8 对 | `lib_android.go↔lib_ohos.go`、`tun/mtu_android.go↔mtu_ohos.go`、`Clash.Meta/android_tz.go↔ohos_tz.go`、5 对 `patch_android.go↔patch_ohos.go`（dns、hub/route、listener/http、rules/provider、tunnel/statistic）|

- `permission_unix.go`(`(darwin||linux) && !android`) 在 `GOOS=linux -tags ohos` 下自动命中，`permission_other.go` 自动排除，无重复/缺失符号；`isPrivileged()` 在鸿蒙扩展进程恒为 false → no-op。
- `t.Start(...)` 两侧仍是 7 参数，一致（历史坑未复现）。
- 5 对 `patch_android.go↔patch_ohos.go` 除 build tag 外**逐字节一致**，上游本次一个都没改。

## 5. 需要后续真机验证/跟进的事项

1. **`core/patch.go` 的平台判断（本次已修，但仍建议真机确认）**：修好后鸿蒙与 Android 同语义，DNS `listen` 会被改写到 `:10053`、NTP 不写系统 —— 这正是合并前 Dart `system.isMobile` 分支的行为（真机验证过可用）。若真机上出现 DNS 端口相关异常，优先回看这一处。
2. **`*_ohos.go` 必须写显式 `//go:build ohos`**：`ohos` 不是 Go 已知 GOOS（`go tool dist list` 无此项），文件名后缀 `_ohos` **不产生隐式约束**——漏写会静默编进 linux 构建且不报错。反之 `_android` 是有效后缀。
3. **8 对双份拷贝没有编译期保护**：上游下次改 `lib_android.go` / `patch_android.go` / `android_tz.go` / `mtu_android.go` 时，鸿蒙侧会静默不跟随。建议后续在 CI 加一个「除 build tag 行外应完全一致」的 diff 校验。
4. **`material_ui` 迁移**：本 fork 自有的 `lib/manager/ohos_tray_manager.dart` 已同步改为 `package:material_ui`；后续新增文件不要再 import `package:flutter/material.dart`（两套 Material 类型互不兼容）。

## 6. 验证结果

| 项 | 结果 |
|---|---|
| 冲突标记残留 | ✅ 0（全仓；`.pubcache` 内第三方测试夹具不计） |
| `dart analyze lib test` | ✅ **1 issue**：仅既有 warning `lib/clash/ohos.dart:9 unused_import`（合并前就有）；error 0 |
| Go 核心交叉编译（ohos arm64） | ✅ `libmeta.so` 74,235,960 B；`R_AARCH64_TLS_TPREL` = 0；ohos 专属导出符号（quickStart/startTUN/listenTunBridge/…）齐全 |
| Rust 插件交叉编译 | ✅ `libcode_forge.so` 3,097,424 B；`frb_get_rust_content_hash` 反汇编 = `0x31c0962e` = **834704942**，与 `plugins/code_forge/lib/src/rust/frb_generated.dart:70` 一致 |
| 代码生成 | ✅ `build_runner` 24 个产物 + `intl_utils` 7 语言；`arb` 键集 == `AppLocalizations` 公开成员集（830 = 810 getter + 20 带参方法，双向差集为空） |
| HAP 构建 | ✅ `python3 scripts/build_ohos.py` → `build/ohos/hap/entry-default-unsigned.hap`（50.9 MB，118 项，release，`versionName 1.19.5` / `versionCode 2026101301`）；内含重建的 `libmeta.so` / `libcode_forge.so` / `libapp.so` |
| 独立验证 | ✅ `docs/verify_upstream_v1.19.5.md` + `docs/verify_upstream_v1.19.5_final.md`（对抗性复核：我方改动存活逐行核对、上游删除行复活 = 0、l10n 交叉一致性、FRB hash 二进制级确认） |

### 本机环境注意（沙箱特有，非仓库问题）

本次构建在只读 `$HOME` 的沙箱里完成，需要把各类缓存重定向到工作区，否则会失败：

| 需要 | 做法 |
|---|---|
| flutter 工具链要写 `bin/cache`，而 `~/tools/flutter_ohos` 只读 | 复制一份到 `.toolchain/flutter_ohos` 并用它构建 |
| pub / cargo / go / ohpm 缓存只读 | `PUB_CACHE=$PWD/.pubcache`、`CARGO_HOME=$PWD/.cargohome`、`GOMODCACHE`/`GOCACHE` 指向 `core/build/`、`HOME=$PWD/.home`（ohpm 只认 `$HOME/.ohpm`，`OHPM_HOME` 无效） |
| `$HOME` 重定向后 rustup 找不到工具链 | 显式 `RUSTUP_HOME=<原 $HOME>/.rustup` |

正常开发机（`$HOME` 可写）不需要这些。

## 7. 冲突解决明细

逐文件明细见独立验证报告 `docs/verify_upstream_v1.19.5.md`（§2 我方改动存活核对、§3 上游新增覆盖核对）与 `docs/verify_upstream_v1.19.5_final.md`（§3 生成物/依赖/垫片复核）。要点：

- 35 处冲突文件：`arb/*.arb`(7)、`lib/l10n/**`(8)、Dart 源码 18 个、`pubspec.yaml`/`pubspec.lock`/`README.md`
- 我方在 `lib/` 下的鸿蒙增量逐行存活（仅 3 处被上游更优/超集实现取代，均有据可查）
- 上游 v1.19.5 的新增行未被误覆盖（仅 4 处 `isAndroid → isMobile` 的有意放宽）

