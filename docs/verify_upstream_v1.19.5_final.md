# 上游 v1.19.5 合并 —— 最终提交状态收口复核（第二轮）

| 项 | 值 |
|---|---|
| 验证者 | `verifier`（独立验证者）|
| 复核对象 | **提交 `92aaf57b`**（`merge: 上游 v1.19.5（52 提交）并入鸿蒙移植分支`，分支 `ohos-port`，两父 = `61776f5b` + `111c5d91`）|
| 复核时间 | 2026-10-16 00:47–01:0x |
| 上一轮报告 | `docs/verify_upstream_v1.19.5.md`（已随 `92aaf57b` 入库）|
| 约束 | 只读复核；未修改 `lib/`、`core/`、`arb/`、`plugins/`、`ohos/`（唯一写入 = 本文件）|

> 本轮按 Lead 要求**不逐条确认**，而是用对抗性方法另找问题。因此结论分两部分：**§2 新增问题**（本轮自己找出来的，含 1 个真实不一致）、**§3 你列 5 项的复核结果**、**§4 我加做的攻击面**。

---

## 1. 结论摘要

| # | 复核项 | 结论 |
|---|---|---|
| 1 | 生成文件已重生成、无冲突标记、与源模型一致、l10n 完整 | **通过**（含 1 条覆盖面警告 → F2）|
| 2 | `picker.dart` 的 `_OhosPlatformFile` + `controller.dart` 的 `updateLocalNetwork` 修复 | **通过**（含 XFile/边界情况的独立实测）|
| 3 | 依赖向下钉（范围/类型冲突/lock 版本） | **通过**（额外追了「material_ui 与 flutter_localizations 是否会在运行期失配」这条静态检查抓不到的链）|
| 4 | `dart analyze lib test` = 1 issue | **通过**（独立复跑，逐字一致）|
| 5 | `.gitignore` + 文档约束（M-1/M-2） | **通过**，但 README 回退段仍需一处限定（F4） |
| **F1** | **提交 `92aaf57b` 内部版本不一致（`app.json5` 仍是 v1.19.4）** | **不通过** ← 本轮发现，见 §2.1 |

**一句话**：合并内容本身是干净的（0 冲突标记、0 构建产物入库、0 悬空引用、生成物与源模型一致、FRB hash 二进制级吻合）；**唯一实质问题是这次提交漏了 `ohos/AppScope/app.json5` 的版本同步**，它现在以「未提交改动」的形式躺在工作区里。

---

## 2. 本轮新发现的问题

### 🟠 F1（中-高）提交里 `ohos/AppScope/app.json5` 未随 pubspec 一起升到 1.19.5

**现象**：同一个提交里两个版本源不一致。

```bash
git show HEAD:ohos/AppScope/app.json5 | grep -E 'versionCode|versionName'
#   "versionCode": 2026100101,   "versionName": "1.19.4"      ← 提交里的值
git show HEAD:pubspec.yaml | grep -m1 '^version:'
#   version: 1.19.5+2026101301                                 ← 提交里的值
git diff -- ohos/AppScope/app.json5                            # 工作区里躺着正确值
#   -"versionCode": 2026100101, -"versionName": "1.19.4",
#   +"versionCode": 2026101301, +"versionName": "1.19.5",
```

**这不是「构建残留」，而是应当提交的同步结果**，三条独立证据：

1. **仓库既有约定**：`git log --oneline -- ohos/AppScope/app.json5` → `55831cdb chore(ohos): 应用版本号跟随上游 pubspec（1.19.3+2026092601）`；合并前 `61776f5b` 的 app.json5 = `2026100101/1.19.4`，与当时的 pubspec `1.19.4+2026100101` **完全一致**。
2. **文档明确**：`docs/harmonyos_audit_fixes.md:150` —— 「构建脚本 `scripts/build_ohos.py` 会把 pubspec 版本同步进 `AppScope/app.json5`（已同步为 1.19.3 / 2026091901）」。即在正文里记录同步后的值 = 它是版本化内容。
3. **不会被还原**：`scripts/build_ohos.py` 的 `app_json_backup` 只在 `:119` 初始化为 `None`、在 `:166` 被检查，**从未被赋值** → 还原分支是死代码（见 F6）；而 `:127` 的 `sync_app_version()` 是**无条件永久写入**。

**影响**：
* 新鲜克隆后第一次构建会让工作区自己变脏（冒出一处「不该有」的 diff），容易误判为合并污染或误 commit；
* 若不重新构建就打 tag / 出包，HAP 的 `versionName` 会是 **1.19.4**（与 pubspec、README、release 记录全部不符）；`AppPlugin.getPackageInfo`（`ohos/.../AppPlugin.ets`）读的就是这个字段 → 关于页/缓存键都会显示 1.19.4。

**建议修复**（一行命令）：把工作区那份一并提交 —— `git add ohos/AppScope/app.json5`（并确认 `git status` 变干净）。

### 🟡 F2（中）`dart analyze lib test` 对本轮重生成的 24 个产物**零覆盖**

`analysis_options.yaml:3-16` 排除了：`lib/l10n/intl/**`、`lib/clash/generated/**`、`lib/**/generated/**`、`**/*.g.dart`、`**/*.freezed.dart`、`plugins/**`。

→ 你报的「1 issue」**数字正确**，但它对「重生成的 24 个产物是否正确」**不提供任何保证**（B-1 的两个冲突文件恰好全在被排除的集合里）。我因此另做了独立覆盖（见 §3.1），另外单独跑了被 `plugins/**` 排除的两个包：

```bash
PUB_CACHE=$PWD/.pubcache ./.toolchain/.../dart analyze plugins/code_forge/lib      # No issues found!
PUB_CACHE=$PWD/.pubcache ./.toolchain/.../dart analyze plugins/launch_at_startup/lib
#   1 issue found: info - unnecessary_library_name（既有，与本合并无关）
```

> 补充：对整个 `plugins/code_forge` 跑 analyze 会得到 63 issues，但 **63/63 全部落在 vendored 的 `cargokit/build_tool/**`**（它有自己的 pubspec、未被根依赖图解析，报 `uri_does_not_exist`），`code_forge/lib/**` 自身 0 issue。属既有噪声，不是本次问题。

**建议**：CI 增加一条不带 exclude 的定向 analyze（目标：`lib/models/generated lib/providers/generated lib/l10n/intl plugins/code_forge/lib plugins/launch_at_startup/lib`），或在合并手册写明「`dart analyze` 干净 ≠ 生成物正确，必须配合语法解析+键集比对」。

### 🟡 F3（中）`.toolchain/` 与 `.pubcache/` 只被**本地** `.git/info/exclude` 忽略

```bash
git check-ignore -v .toolchain   # → .git/info/exclude:9:.toolchain/
git check-ignore -v .pubcache    # → .git/info/exclude:7:.pubcache/
grep -cE 'toolchain|pubcache' .gitignore   # → 0
```

`.git/info/exclude` **不入库、不共享**：任何新克隆（或 CI）里这两个目录都是「未跟踪但可见」，一次 `git add -A` 就会把整份 flutter_ohos SDK 与 pub 缓存提交进去（比刚修的 M-2 严重一个量级：`.pubcache` 目前已有 git 源缓存，`.toolchain` 是一整份 Flutter 仓库）。

**建议**：`.gitignore` 追加 `/.toolchain/`、`/.pubcache/`。团队约定不应依赖个人 `info/exclude`。

### 🔵 F4（低）README 的离线回退说明缺一个关键限定（当前恰好安全，但会被下一次 `pub get` 打破）

`README.md:66-68`（英文版 `readme/README_ohos_en.md:73-76`）教人：

```
cp ohos/pubspec_overrides.yaml pubspec_overrides.yaml
flutter build hap --release --no-codesign --no-pub --dart-define=APP_ENV=stable
```

我复核的**当前**事实（与上一轮 M-1 相比已改善）：
* `pubspec.lock`（HEAD，与工作区一致）**已经包含 ohos 覆盖**：4 个 gitcode URL、`path_provider_ohos`、`shared_preferences_ohos`、`source: git` 共 4 条（`path_provider`/`shared_preferences` 本身也指向 gitcode fork）→ **因此这条 `--no-pub` 回退现在是安全的**。
* 但根 `pubspec.yaml:80-87` 的 `dependency_overrides` **只有** `flutter_rust_bridge` 与 `hotkey_manager_linux`，**没有**这两个 ohos 覆盖 → 任何一次**不带注入文件**的 `flutter pub get` / `flutter build hap`（不加 `--no-pub`）都会重新解析并把 lock 里的 4 个 git 源**换回 pub.dev**；此后若再照 README 用 `--no-pub` 回退，就会静默产出坏包。

**建议**：回退段补一句「先用 `grep -c gitcode pubspec.lock` 确认 ≥4，否则先跑一次 `python3 scripts/build_ohos.py` 让它重新注入并解析」。你在 `docs/upstream_merge_2026-09-27.md:156-167` 新写的 ⚠️ 段落（「不要直接 flutter build hap / 手动 pub get …能构建成功但装到鸿蒙上是坏包」）我逐句核对，**与实测完全一致，措辞足够**。

### 🔵 F5（低）`docs/upstream_merge_2026-10-16.md` §6/§7 仍是占位

`§6 验证结果 → 见 §7（合并完成后回填）`、`§7 → 见 docs/verify_upstream_v1.19.5.md 与本节回填内容`。建议回填：最终 `dart analyze` 结果（1 issue）、两份验证报告路径、以及 FRB hash 的**二进制级**证据（见 §4.1）与 `app.json5` 版本同步（F1）。

### 🔵 F6（低，代码卫生）`scripts/build_ohos.py` 的 `app_json_backup` 还原分支是死代码

`app_json_backup` 仅在 `:119` 赋 `None`、`:166` 被判断，**全文件无其它赋值**（`grep -n app_json_backup`）。行为上不影响正确性（`finally` 里 `:162-164` 先用还原后的 pubspec 调 `sync_app_version()` 重新同步 app.json5），但它会让人以为 app.json5 在构建后会被还原 —— 与 F1 的判断直接相关。建议删除该死分支，或补上真正的备份赋值。

---

## 3. 你列的 5 项：复核结果与证据

### 3.1 生成文件重生成（不再有冲突标记、与源模型一致、l10n 完整）—— **通过**

| 检查 | 命令 | 结果 |
|---|---|---|
| 冲突标记（tracked，权威） | `git grep -IlE '^(<<<<<<< \|>>>>>>> \|\|\|\|\|\|\| )' HEAD -- .` | **0 个文件** |
| 冲突标记（全仓含未跟踪，排除 `.git`） | `grep -rIlE '^(<<<<<<< \|>>>>>>> )' --exclude-dir=.git .` | 仅 2 个文件，全在 `.pubcache/git/flutter_packages-*/packages/flutter_migrate/test/*`（第三方仓库自带的冲突解决测试夹具，不属于本仓） |
| `=======` 误报排除 | 对 `lib core arb plugins ohos scripts` 逐个做 open/sep/close **配对计数** | 源目录内 **0** 处 bare `=======` |
| 语法解析（覆盖被 analyze 排除的生成物） | 对全部 `git ls-files 'lib/**.dart'` 逐文件 `dart format --output=none` | **0 失败 / 242 个唯一文件**（上一轮的 2 个冲突文件已消失） |
| 源模型 → 生成物字段一致性 | 解析每个 `factory/const X({...})` 参数名，逐一在对应 `*.freezed.dart`/`*.g.dart` 中查找 | 14 个源文件、**462 个参数、461 命中**；唯一「缺口」是 `lib/models/common.dart` 的 `onPressed` —— 它是**同文件内的普通类** `PopupMenuItemData`（`lib/models/common.dart:915-925`，非 freezed/json_serializable），**误报** |
| 我方 + 上游字段抽查 | `grep -c` 计数 | `backgroundTaskMode` config.dart=1/freezed=21/g.dart=4、`backgroundTaskEnabled` 1/21/2、`keepDockIcon` 1/21/2、`enableNavBarHapticFeedback` 1/21/3、`mediaUnlockMoreStreamingPlatforms` 1/21/4 → 两侧都在 |
| 持久化 key 未漂移 | `lib/models/config.dart:333-336` vs `lib/models/generated/config.g.dart:363-400` | `backgroundTaskMode`/`backgroundTaskEnabled` 的读写键一致、`@Default(true)` 一致 → 旧存档不会因重生成而读不出 |
| l10n 键集 == 成员集 | Python 解析 `arb/intl_en.arb` 与 `lib/l10n/l10n.dart` | **完全相等**：arb en 830 键 = 810 `String get` + 20 带参方法；**双向差集均为空** |
| 我方 11 个鸿蒙键 | 逐个查 arb + 成员 | **全在**（`descOhos`、`backgroundTask*`、`mode*`、`addPackageName`、`invalidPackageName`、`ohosAccessManualOnly`）|
| 上游新增键 | 抽查 `geoBuiltInResources`/`userAuth`/`userAuthEmpty`/`navBarHapticFeedback`/`keepDockIcon`/`sidebarFlyout` | **全在**（arb + 成员）|
| 7 个 locale 覆盖 | 每个 `messages_*.dart` 的键集 vs 成员集 | 各 810 键，**覆盖全部 getter**；20 个带参消息以顶层函数引用形式存在（如 `"emptyTip": m4,`），非缺失 |

### 3.2 两处 error 修复 —— **通过**（并把「不会抛」验到了字节级）

**(a) `lib/common/picker.dart` 的 `_OhosPlatformFile`（`:164-209`）**

基类真源：`.pubcache/hosted/pub.dev/file_picker_platform_interface-4.2.0/lib/src/platform_file.dart:1` = `abstract base class PlatformFile`，抽象成员为 `name`、`uri`、`xFile`、`lengthSync()`、`length()`、`readAsBytes()`、`readAsByteStream()`（`path`/`extension` 是基类具体实现，由 `uri`/`name` 派生）。

* `_OhosPlatformFile` 覆写了 **name / uri / xFile / lengthSync / length / readAsBytes / readAsByteStream**，且 `path`/`extension` 由基类基于 `uri`/`name` 自动可用；
* 决定性证据：`dart analyze lib` **干净**（`lib/common/picker.dart` 在被分析范围内）**且**该类在 `picker.dart:69` 被实例化 —— Dart 只要有一个抽象成员未实现就会报 `non_abstract_class_inherits_abstract_member`/实例化错误 ⇒ **不可能存在未实现成员**；
* 调用方只用已实现成员：`lib/controller.dart:1613` `pickerFiles(allowMultiple:, allowedExtensions:)`（不再有 `withData`）、`lib/views/backup_and_recovery.dart:139` `.path`、`:148` `readAsBytes()`；全仓对 PlatformFile 的 `.bytes`/`.size` 使用为 **0**（file_picker 13 已删除这两个成员 —— 若还有调用点，analyze 会直接报错）。`backup_and_recovery.dart:398` 的 `file.size` 属于 WebDAV 列表项类型，**不是** PlatformFile。
* `xFile` 的构造（`picker.dart:184`）：
  * io 实现真源 `cross_file-0.3.5+5/lib/src/types/io.dart:31-39` → `_file = File(path)`，**构造期不做任何 I/O、不抛**；
  * `uri.toFilePath()` 我用 dart 实测三类输入（绝对路径 / 含空格·`#`·`?`·中文 / **空串**）：全部正常往返，**空串也不抛**（得到空 URI 与空路径）→ 即便原生侧返回空路径也不会因 `toFilePath()` 抛异常，`length()`/`readAsBytes()` 的 try/catch（`:61-67`、`:193-197`）已兜住后续 I/O。

**(b) `lib/controller.dart:1406` `updateLocalIp()` → `updateLocalNetwork()`**

```bash
grep -rn "\bupdateLocalIp\b"  lib test   # → 仅 controller.dart:1407 的一条注释（历史说明）
grep -rn "\blocalIpProvider\b" lib test  # → 同上，注释
grep -rn "\bupdateLocalNetwork\b" lib    # → controller.dart:502(定义)、:1409、application.dart:247、
                                         #   views/dashboard/widgets/intranet_ip.dart:84
```

→ **代码引用 0，注释提及 2 处**（`controller.dart:1406-1408` 明确写了「上游 v1.19.5 用 …取代了 …改调上游新 API」）。无悬空引用。

### 3.3 依赖向下钉 —— **通过**（并额外验证了「运行时本地化查找」这条静态盲区）

**(a) 改动范围**：全仓 grep 证实四处 pin 只出现在两个文件

```
pubspec.yaml:74   material_ui: 1.2.0
pubspec.yaml:75   cupertino_ui: 1.0.2
pubspec.yaml:97   build_runner: 2.15.1
pubspec.yaml:103  freezed: ^4.0.0-dev.3
plugins/code_forge/pubspec.yaml:17  material_ui: 1.2.0
```

`plugins/code_forge/lib/editor/{theme.dart:4,view.dart:11}` 确实 `import 'package:material_ui/material_ui.dart'` ⇒ **该 pin 不是摆设**（否则 path 依赖求解也会失败）。`pubspec.yaml:70-73,95-102` 还写明了下钉原因（1.3.0/1.1.0 被 pub.dev 撤回、1.4.0+/1.1.1+ 要求 Dart ^3.13.0、analyzer 约束链），我未逐条上 pub.dev 核对撤回状态，但与 lock 的解析结果自洽。

**(b) `flutter/material.dart` / `flutter/cupertino.dart` 残留**：仓库自有源码中只剩 **1 处** —— `lib/l10n/l10n.dart:2`（intl_utils 生成物，属你允许的例外）。我做了穷举确认它**不会引入类型冲突**：

* 逐个 grep 该文件里 material 专属符号（`MaterialLocalizations`、`GlobalMaterialLocalizations`、`DefaultMaterialLocalizations`、`MaterialApp`、`ThemeData`、`Colors`、`Icons`、`WidgetsApp`、`MaterialPageRoute`、`MaterialButton`、`Scaffold`）→ **全部 0 命中**；它真正依赖的只有 `LocalizationsDelegate`/`Locale`（`l10n.dart:6833`），这些来自 `flutter/widgets.dart`（被 material_ui 与 flutter/material 双方共同导出，**同一个类**）；
* 这也解释了为什么 analyze 不报 `unused_import`：`LocalizationsDelegate` 确实由该 import 提供（`ignore_for_file` 里并没有 `unused_import`）。→ **无冲突，且不应手改**（生成物）。

**(c) 顺带追掉一条 analyze 抓不到的链（MaterialLocalizations 运行期失配）**：

`material_ui` 只 re-export `package:flutter/widgets.dart`（`material_ui-1.2.0/lib/material_ui.dart:20`），它**自带** `MaterialLocalizations`（`lib/src/material_localizations.dart:55`）与 `GlobalMaterialLocalizations`（`lib/src/global_material_localizations.dart:72`，由 `material_ui.dart:100,122` 导出）。而 `lib/application.dart:285-288` 注册的是 `...GlobalMaterialLocalizations.delegates`，且该文件**只 import 了 `material_ui`**（未 import `flutter_localizations`）→ 解析到的是 **material_ui 自己的**实现，与 material_ui 的 `MaterialApp` 同源 ⇒ 不会出现「`Localizations.of<MaterialLocalizations>` 查不到」的运行时失败。（`flutter_localizations` 仍作为 SDK 依赖声明在 `pubspec.yaml:11`，但 lib 内已无引用。）

**(d) lock 解析版本与约束一致**：

| 包 | 约束 | lock | 判定 |
|---|---|---|---|
| material_ui | `1.2.0` | **1.2.0**（hosted, pub.dev）| ✓ |
| cupertino_ui | `1.0.2` | **1.0.2**（hosted）| ✓ |
| freezed | `^4.0.0-dev.3` | **4.0.0-dev.3** | ✓ |
| freezed_annotation | `^3.1.0` | **3.1.0** | ✓ |
| build_runner | `2.15.1` | **2.15.1** | ✓ |
| analyzer | （传递，注释称需 13.0.x）| **13.0.0** | ✓ 与注释的约束链自洽 |
| flutter_rust_bridge | `2.13.0` | **2.13.0** | ✓ |
| file_picker | `^13.0.0` | **13.1.0** | ✓ |

### 3.4 `dart analyze lib test` —— **通过（1 issue，逐字一致）**

```bash
PUB_CACHE=$PWD/.pubcache ./.toolchain/flutter_ohos/bin/cache/dart-sdk/bin/dart analyze lib test
```

```
warning - lib/clash/ohos.dart:9:8 - Unused import: 'package:bettbox/enum/enum.dart'. Try removing the import directive. - unused_import
1 issue found.
```

与你的结论**完全一致**。补充两点：① 该 warning 是既有问题（本 fork 文件，与上游合并无关）；② 历史文档里记的 `clash/core.dart:220` 那条警告本次未再出现。**覆盖面限定见 F2。**

### 3.5 `.gitignore` 与文档措辞 —— **通过**（README 一处见 F4）

```bash
tail -4 .gitignore
#   # scripts/build_ohos.py 运行期从 ohos/pubspec_overrides.yaml 注入，构建后删除；
#   # 构建被中断时会残留，忽略它以免污染工作区（也避免误提交）。
#   /pubspec_overrides.yaml
git check-ignore -v pubspec_overrides.yaml   # → .gitignore:85:/pubspec_overrides.yaml
```

→ M-2 **已按建议修好，且带注释说明原因**。M-1 你选择的「保留脚本注入 + 强化文档约束」：`docs/upstream_merge_2026-09-27.md:156-167` 的 ⚠️ 段落措辞准确到位（我把结论与实测逐句比对：确实「能构建成功但装到鸿蒙上是坏包」）；README 端见 F4。

---

## 4. 我加做的攻击面（含本轮最有价值的正面结论）

### 4.1 FRB content hash 的**二进制级**确认（上一轮只能给间接证据）

上一轮我只证明了「Rust api 源码与上游逐字节相同 + 产物 mtime 晚于源码」；本轮直接把新 `.so` 里那个 12 字节的校验函数反汇编出来（无 aarch64 反汇编器 → 手工解码指令字）：

```bash
readelf -sW ohos/entry/libs/arm64-v8a/libcode_forge.so | grep content_hash
#  135: 00000000000fe0b0  12 FUNC GLOBAL DEFAULT 14 frb_get_rust_content_hash
```

字节 `c0 c5 92 52 00 38 a6 72 c0 03 5f d6` 解码为：

```
movz w0, #0x962e
movk w0, #0x31c0, lsl #16
ret
```

→ 常量 = **834704942 = 0x31c0962e**，与 `plugins/code_forge/lib/src/rust/frb_generated.dart:70 rustContentHash => 834704942` **完全一致** ⇒ FRB 的运行时 content-hash 校验必然通过（不是「应该能过」）。

### 4.2 提交内容审计：0 构建产物入库

```bash
git diff --name-only HEAD^1 HEAD | grep -cE '\.(so|a|o|dylib|dll|hap|jar)$|^\.pubcache|^\.dart_tool|^build/|^\.toolchain|ohos/entry/libs'   # → 0
for d in .pubcache .dart_tool build .toolchain core/build plugins/code_forge/rust/target ohos/entry/libs ohos/entry/build ohos/oh_modules; do
  git ls-files "$d" | wc -l; done    # → 全为 0
```

`git ls-tree -r -l HEAD` 体积榜前列全是正常资源（`assets/data/BundleMRS.7z` 4.8MB、字体、HAP 图标、`lib/models/generated/*.freezed.dart` 等），无异常大文件。

### 4.3 其他已核项

* **`.gitignore` 的 `*.md` + `!/docs/*.md` 组合**：两份验证报告都正常入库（`git ls-files docs/` 可见，`git log -1 -- docs/verify_upstream_v1.19.5.md` = `92aaf57b`）。
* **round-1 的 L-2**（`.gitignore:73` `/assets/data/zash.zip# Miscellaneous` 畸形模式）**仍未修**，但已确认非本次合并引入、且目标文件不存在 → 维持「低」。
* **工作区状态**：复核期间除 F1 的 `ohos/AppScope/app.json5` 外，还有 `docs/upstream_merge_2026-09-27.md` 的未提交修改（即 3.5 里的 ⚠️ 段落，内容正确，待提交）。无构建进程运行（`ps` 已确认），故 F1 不是「构建中」的瞬态。
* **`test/`（50 个 dart 文件）** 在被 analyze 的范围内且干净；`lib/l10n/l10n.dart` 也在范围内（被排除的只有 `lib/l10n/intl/**`）。

---

## 5. 未能验证的部分（与原因）

| 项 | 原因 | 影响 |
|---|---|---|
| HAP 构建与**真机运行** | 沙箱无 DevEco/hdc/签名材料，`flutter` 包装脚本只读 | DNS `:53→:10053`、NTP、material_ui 渲染、VPN、FRB 加载等运行期行为未验证 |
| `go test`（`core/patch_test.go` 等） | 需要 Go 环境实跑；本轮 Go 侧无新改动 | 上一轮已做静态核对（`var` 可改写、标签矩阵实测），仍未实跑 |
| build_runner 输出的**可复现性** | 需联网/完整 pub 环境重跑一次并比对 | 「重生成是否 byte-identical」未验证；如需保证，可在 CI 加 `dart run build_runner build --delete-conflicting-outputs && git diff --exit-code` |
| `material_ui 1.3.0/1.1.0 被撤回`、各版本 `sdk` 下限 | 未访问 pub.dev 核对 | 只验证了「约束 ↔ lock 自洽」；下钉的**动机**沿用你的记录，若要在发布说明里引用请再确认一次 |
| `dart format` 的 `Changed` 名单 | 无 package_config → 风格假设与仓库不同（对照实验证明） | 不作为缺陷证据（沿用上一轮结论）|

---

## 6. 建议的最小收口动作（按优先级）

1. **`git add ohos/AppScope/app.json5`（F1）** —— 这是唯一影响「最终提交状态正确性」的一项；顺手 `git add docs/upstream_merge_2026-09-27.md`。
2. `.gitignore` 追加 `/.toolchain/`、`/.pubcache/`（F3）。
3. README/README_ohos_en 的离线回退段补一句 lock 校验（F4）；回填 `docs/upstream_merge_2026-10-16.md` 的 §6/§7（F5）。
4. （可选）CI 增加生成物的定向 analyze（F2）；删除 `build_ohos.py` 的死还原分支（F6）。

---

## 7. 报告文件路径

`docs/verify_upstream_v1.19.5_final.md`
（第一轮报告：`docs/verify_upstream_v1.19.5.md`，已随 `92aaf57b` 入库）

---
---

# 第三轮：UI 垫片机制与最终提交 `bbaf9f45` 收口验证（task-6）

| 项 | 值 |
|---|---|
| 复核对象 | `bbaf9f45`（fix: UI 垫片、依赖覆盖补齐、版本同步）+ 合并提交 `92aaf57b` |
| 新增机制 | `third_party/{material_ui,cupertino_ui}` 垫片 + 两处 `dependency_overrides` + HAP 构建 |
| 结论 | **6 项全部通过**；新增 1 条低-中问题（垫片自身 2 条 analyzer warning）、1 条信息性残留风险（垫片非等价替换，已量化）|

## 8. 结论摘要（task-6 六项）

| # | 必查项 | 结论 | 关键证据 |
|---|---|---|---|
| 1 | 垫片语义完备性 | **通过** | 垫片可用面（flutter/material + flutter_localizations）**2528** 个顶层公开声明 ⊇ material_ui 1.2.0 的 **2286** 个；真差集只有 **2** 个（`MaterialUiCompatibilityBridge`、`StyleVariant`），**使用点均为 0**；cupertino_ui 差集 **1** 个（`CupertinoUiCompatibilityBridge`）**使用点 0**。另 178 处 `import 'package:material_ui/material_ui.dart'` 全部是包入口，**0 处深路径 import**（`grep` 证实），垫片只需提供入口即可 |
| 2 | 两处 overrides 一致 | **通过**（且**实测证明了「整体替换」这一前提**）| 根 `pubspec.yaml` 的 4 个键（`material_ui`/`cupertino_ui`/`flutter_rust_bridge`/`hotkey_manager_linux`）在 `ohos/pubspec_overrides.yaml` 中**逐条值相同**；ohos 侧额外含 `path_provider`/`shared_preferences`（桌面路径不需要，设计使然）。**没有「根有而 ohos 无」的键** ⇒ 替换语义下不会静默丢失。`plugins/code_forge/pubspec.yaml:17 material_ui: 1.2.0` == 垫片 `version: 1.2.0` ✓ |
| 3 | `bbaf9f45` 内容审计 | **通过** | 13 个文件变更，构建产物/缓存命中 **0**；`third_party/` 入库**恰好 4 个文件**；`.toolchain/.pubcache/.cargohome/.ohpm/.home` 全部**新增进 `.gitignore`**（`:88-92`）且生效（`git check-ignore` 现在指向 `.gitignore` 而非 `.git/info/exclude`）；9 个缓存目录 tracked 文件数全为 0 |
| 4 | HAP 与提交树一致 | **通过** | `entry-default-unsigned.hap` 50,930,139 B / mtime **00:57:19**，**晚于全部源码输入**（`lib` 00:46:29、`pubspec.yaml` 00:52:51、`third_party` 00:56:07、`ohos/pubspec_overrides.yaml` 00:53:39、`pubspec.lock` 00:53:47、`libmeta.so` 00:56:26）；`module.json` → **versionName 1.19.5 / versionCode 2026101301** ✓；`libs/arm64-v8a/libmeta.so` **74,235,960 B**、`libcode_forge.so` **3,097,424 B** ✓；与 `ohos/entry/build/...` 同 md5；118 个条目。**唯一比 HAP 新的 tracked 文件是文档** `docs/upstream_merge_2026-10-16.md`（00:59:52），不影响产物 |
| 5 | `app.json5` 一致性 + `--version-code` 路径 | **通过** | `pubspec.yaml` `1.19.5+2026101301` ↔ `app.json5` `2026101301`/`1.19.5`，HEAD 与工作区**都一致**（上一轮 F1 已修）。`--version-code` 路径：`sync_app_version()`（`:17-38`）从 pubspec 重写两字段；`finally` 先还原 pubspec（`:163`）**再**调 `sync_app_version()`（`:164`）⇒ 构建后 app.json5 回到与还原后 pubspec 一致的状态 ✓（上一轮 F6 的 `app_json_backup` 死分支仍在，但不影响该结论）|
| 6 | 回归 | **通过** | `dart analyze lib test` = **1 issue**（仅既有 `lib/clash/ohos.dart:9 unused_import`）；`git status` **干净（0 项）**；`92aaf57b` 的两个父提交正是 `111c5d91` + `61776f5b` ✓ |

## 9. 本轮发现的问题

### 🟡 S1（低-中）垫片自身带 2 条 analyzer warning：把工具链的 `@internal` 符号导出成了公开 API

```bash
PUB_CACHE=$PWD/.pubcache ./.toolchain/flutter_ohos/bin/cache/dart-sdk/bin/dart analyze third_party
#   warning - cupertino_ui/lib/cupertino_ui.dart:9:1 - The member 'TranslateAnimationSource' can't be exported
#             as a part of a package's public API. … - invalid_export_of_internal_element
#   warning - material_ui/lib/material_ui.dart:19:1 - （同上）
```

* 成因：`export 'package:flutter/material.dart'`（及 cupertino）会连带导出 flutter_ohos 在 `packages/flutter/lib/src/widgets/binding.dart:57-59` 用 `@internal` 标注的 **OHOS LTPO 专用枚举 `TranslateAnimationSource`**（本仓库代码使用数 **0**）→ 它变成了 `material_ui` 的公开面。
* 影响面：**仅 warning，不影响构建**（HAP 已成功）；**CI 目前不跑 analyze**（`.github/workflows/*.yaml` 无 analyze 调用）⇒ 当前零影响。但 `analysis_options.yaml` **没有**排除 `third_party/**`，所以任何一次仓库级 `dart analyze`（不带路径）都会多出这 2 条；将来若加 `--fatal-warnings` 门禁就会红。另外属 API 卫生：把 OHOS 内部 API 暴露成上游包的公开符号。
* 建议：`third_party/material_ui/lib/material_ui.dart:19` → `export 'package:flutter/material.dart' hide TranslateAnimationSource;`（cupertino 同理，`cupertino_ui.dart:9`）。比把 `third_party/**` 加进 exclude 更好——后者会让垫片彻底失去静态检查。

### 🔵 S2（信息性，需知情）垫片**不是等价替换**：material/cupertino 存在整份实现漂移

量化（同名 src 文件逐字节 + 去空白后比对）：

| 对比 | 文件数 | 原始差异行 | 去空白/空行后 | 结论 |
|---|---|---|---|---|
| material_ui 1.2.0 vs 工具链 material | 182（另有 2 个工具链没有）| 8203 | **7904** | 96% 是**真实差异**，不是排版噪声 |
| cupertino_ui 1.0.2 vs 工具链 cupertino | 52（另有 2 个工具链没有）| 1666 | **1655** | 同上 |

* 归因：`material_ui 1.2.0` 是 Flutter 官方 material 在**较新 Flutter** 上的再发布（其 pubspec 要求 `flutter >=3.44.0`，上游 v1.19.5 要 3.47），而工具链是 **3.44.9-ohos** ⇒ 差异 = 上游 material 版本漂移 + ohos 补丁，**两者都不可避免**（真包根本没法在含 `ohos` 的 `TargetPlatform` 上编译）。
* 已被覆盖的部分：**API/签名层面**由「2528 ⊇ 2286、差集 2 个且零使用」+ **HAP 编译成功**共同证明 —— 用到的符号与签名都存在。
* 未能覆盖的部分：**行为/样式**层面（Material 组件内部实现细节）静态无法穷尽。垫片 docstring 已自认这一副作用。
* 建议：真机对主要界面做一轮目视回归（对话框/主题/滚动/导航栏/输入框）；保留「flutter_ohos ≥3.47 后删除垫片」的 TODO（文档已有）。

## 10. 本轮最有价值的两项独立取证

### 10.1 实测证明 `pubspec_overrides.yaml` 是**整体替换**而非合并（机制前提成立）

这是整个垫片/依赖覆盖机制的基石，之前只在注释里被断言。我用一个最小离线实验独立验证：

```
/tmp/pubtest/root/pubspec.yaml            → dependencies: {bar, baz};  dependency_overrides: {bar: path ../bar_v1}
/tmp/pubtest/root/pubspec_overrides.yaml  → dependency_overrides: {baz: path ../baz_v1}
PUB_CACHE=/tmp/pubcache dart pub get --offline
```

结果：**失败** —— `Because rootpkg depends on bar any which doesn't exist (could not find package bar in cache)`。
即 `bar` 的 override 被 pubspec_overrides.yaml 的 dependency_overrides **整段取代而丢失**（若为合并，两个 path 覆盖都会生效、离线解析会成功）。
⇒ `ohos/pubspec_overrides.yaml:3-5` 的警告与「根 pubspec 的每条 overrides 都必须在这里再写一遍」的约定**正确且必要**，也解释了本地那次「垫片被静默丢弃」。

### 10.2 HAP 里编进去的是**垫片**而不是真包（产物级判别）

真 `material_ui 1.2.0` 的 pubspec 声明了自己的着色器
`flutter: shaders: - packages/material_ui/shaders/ink_sparkle.frag`。若它被真正打包，HAP 里会出现 `flutter_assets/packages/material_ui/shaders/ink_sparkle.frag`。实测 HAP：

```
resources/rawfile/flutter_assets/shaders/ink_sparkle.frag        ← 工具链自带（无 packages/ 前缀）
resources/rawfile/flutter_assets/shaders/stretch_effect.frag
contains packages/material_ui/: False
```

⇒ 该 HAP 确实是用垫片（= 工具链 material）编出来的。配合 `.dart_tool/package_config.json` 中 `material_ui → ../third_party/material_ui`、`pubspec.lock` 中 `source: path`，三路互证。

## 11. 主动攻击过、但没找到问题的面

1. **垫片是否漏符号**：material_ui 差集 2 个 + cupertino_ui 差集 1 个，全部零使用；垫片可用面比原包**更大**（2528 vs 2286）；且 178 处 import 全是入口路径，无深路径依赖。
2. **`GlobalMaterialLocalizations` 归属**：`application.dart:285-288` 用 `GlobalMaterialLocalizations.delegates`，经垫片的 `export flutter_localizations` 解析到 SDK 的 `flutter_localizations/lib/src/material_localizations.dart:72`，其 `MaterialLocalizations` 与 `MaterialApp`（同样来自 SDK material）**同源** ⇒ 不存在运行期 `Localizations.of` 查不到的问题（这是上一轮我追过、这轮垫片让结论更强的点）。
3. **是否还有别的包踩同样的坑**：按 `.dart_tool/package_config.json` 遍历**全部 193 个已解析包**，筛「≥4 个 `case TargetPlatform.`、无 `TargetPlatform.ohos`、无 `default:`」→ **0 命中**。另单独确认工具链 `flutter_localizations` 不 switch TargetPlatform（0 处）。
4. **修复前提**：工具链 `TargetPlatform` 枚举确实含 `ohos`（`packages/flutter/lib/src/foundation/platform.dart:65-86`，`ohos` 为末位成员），工具链 material/cupertino 分别有 **39/73**、**11/17** 个文件/处 ohos 分支；而真 `material_ui 1.2.0`/`cupertino_ui 1.0.2` 的 ohos 分支数为 **0**，实例见 `material_ui-1.2.0/lib/src/theme_data.dart:436-442` 的穷举 switch（android/fuchsia/iOS/linux/macOS/windows，无 default）→ **失败机理成立**。
5. **提交卫生**：13 个文件里 0 构建产物；`third_party` 恰好 4 文件；9 个缓存目录 tracked 数全 0；`.gitignore` 新增 5 条且生效。
6. **被 analyze 排除的区域逐个补跑**：`lib/models/generated`、`lib/providers/generated`、`lib/l10n/intl` → **No issues**；`plugins/code_forge/lib` → **No issues**；`plugins/launch_at_startup/lib` → 1 条既有 info；`third_party` → 2 条（= S1）。
7. **HAP 新鲜度**：`module.json` 版本、native 库尺寸/md5、着色器判别、以及「HAP mtime 晚于全部源码输入」四路一致。
8. **`--version-code` 之后的一致性**：静态追踪 `sync_app_version()` + `finally` 的调用顺序，确认构建后 app.json5 与还原后的 pubspec 一致。

## 12. 未能验证 / 无法判定

| 项 | 原因 | 影响 |
|---|---|---|
| 「实测 **166 处** / 40+ 文件」的精确复现 | 需要把真 `material_ui`/`cupertino_ui` 换回来重新触发 `kernel_snapshot` 失败；我不能改依赖也不能重跑构建 | 我用代理量度：真两包中含 `case TargetPlatform.` 且**无** ohos 的文件 **35** 个、`case TargetPlatform.` 行 **378** 行（与「40+ 文件」同量级；「166 处」很可能是前端报错条数而非 case 行数）。**机理与结论不受影响**（已由实例+枚举独立证明）|
| 真机 UI 行为回归（S2 的漂移后果）| 沙箱无设备 | 静态只能证明 API 兼容；样式/交互差异需目视回归 |
| 自己重跑 `scripts/build_ohos.py` | 需要网络（gitcode/pub.dev）+ 只读外的工具链写入，且会改动工作区 | 改为对**产物**做四路交叉验证（版本/md5/尺寸/着色器）+ 时间序验证 |
| `flutter_ohos` 何时升到 3.47+（垫片何时可删）| 外部依赖 | 文档已记 TODO |

**第三轮结论**：`bbaf9f45` 可以接受为最终提交状态。除 S1（2 条垫片内部 warning，建议 `hide` 一行修掉）外，没有发现功能性缺陷；垫片机制的前提（pub 替换语义、工具链已处理 `ohos`、真包必然编译失败）均已被**独立实验/二进制与产物级证据**确认。
