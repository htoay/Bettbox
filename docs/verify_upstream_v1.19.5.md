# 上游 v1.19.5 并入 ohos-port：独立对抗性验证报告

| 项 | 值 |
|---|---|
| 验证者 | `verifier`（独立验证者，非任何冲突文件作者）|
| 验证对象 | 工作区中的 git merge 未提交状态（`MERGE_HEAD=111c5d91`，`ORIG_HEAD=61776f5b`）|
| 我方基线 | `ohos-port-premerge-v1.19.5` = `61776f5b`（**权威基线**，见 §0.3）|
| 上游基线 | `upstream/main` = `111c5d91`（v1.19.5，52 提交）|
| 共同祖先 | `45d6fd37`（v1.19.4）|
| 规模 | 我方改动 142 文件 / 上游改动 735 文件 / 双侧都改 **61** 文件 / 合并结果 vs 祖先 814 文件 |
| 约束 | 全程未执行任何 git 写命令；未修改 `lib/`、`core/`、`arb/`、`plugins/`、`ohos/`（唯一写入 = 本文件）|

---

## 0. 验证方法与取证口径

### 0.1 三方对照 + 机械合并偏差分析（主力手段）

对每一个「双侧都改过」的文件（61 个）：

```bash
git show 45d6fd37:<f>              > base     # 祖先
git show ohos-port-premerge-v1.19.5:<f> > ours
git show upstream/main:<f>         > theirs
git merge-file -p --diff3 ours base theirs > mech   # 机械三方合并
diff mech <工作区文件>                                # → 人工裁决点（36 个文件）
```

再叠加「唯一新增行存活分析」：

* 我方唯一新增行 = `git diff 45d6fd37 ohos-port-premerge-v1.19.5 -- f` 的 `+` 行中，**既不在 base 也不在 theirs** 的行；
* 上游唯一新增行 = 反方向同理；
* 逐行判定是否仍存在于工作区；缺失的再区分「被取代」还是「疑似丢失」。

反向补齐三类盲区：

* 只被我方改动的文件（81 个）→ 工作区必须逐字节等于 ours；
* 只被上游改动的文件（M/A/T 共 334 个，另有 338 个纯删除文件）→ 工作区必须逐字节等于 upstream；
* **上游删除行复活检测**：`(base−theirs) ∩ 工作区 − ours` —— 检出「冲突里整块选了我方、把上游删除又带回来」这种最隐蔽的覆盖。

### 0.2 为什么不用 `dart analyze`

`.dart_tool/package_config.json` 指向已不存在的 pub 缓存，analyze 输出为级联噪声（`uri_does_not_exist` 等）。改用两个与包解析无关的证据源：

* `./.toolchain/flutter_ohos/bin/cache/dart-sdk/bin/dart format --output=none <file>` —— 纯语法解析（Dart 3.12.2，`dart` 可用）；
* 文本集合 / JSON / 键集比对（arb、l10n 生成物、import 迁移、调用点签名）。

> 注意：`dart format --output=none` 会因「**格式风格**可改」而 exit≠0（`Changed <f>`），这与「语法错误」是两回事。做了对照实验：**本次合并完全没碰过的**文件（如 `lib/common/archive.dart`、`lib/common/app_localizations.dart`）同样被报 `Changed` → 说明是格式化器风格/语言版本假设差异，不是合并缺陷。真正的语法失败会打印 `Could not format because the source could not be parsed`。

### 0.3 基线陷阱（值得写进合并手册）

用 `45d6fd37`（祖先）而不是 `61776f5b`（我方合并前）当基线，会得出**相反结论**：祖先里 `system.isMobile` 还不存在，`state.dart` 的那两处还是 `system.isAndroid`。本报告所有「我方改动」一律以 `ohos-port-premerge-v1.19.5` 为准。

### 0.4 环境限制

`/tmp` 每次 bash 调用后清空、`$HOME`/`~/.cache` 只读（`Read-only file system`）。所有脚本与分析都在**单次调用内**自包含执行；Go 构建缓存显式指到 `core/build/gocache`。

---

## 1. 结论摘要（6 项必查）

| # | 必查项 | 结论 | 关键证据 |
|---|---|---|---|
| 1 | 冲突标记残留 | **通过**（除 2 个已知生成文件） | 全仓 `^<<<<<<< / ^>>>>>>> / ^=======$` 扫描：仅 `lib/models/generated/config.freezed.dart`（13/13/13 配对）、`lib/providers/generated/state.g.dart`（1/1/1 配对）。其余唯一命中是未跟踪的 `~/.cargo` 镜像 README（`.gitignore:2 *.md` 已忽略）；`git ls-files` 把这 2 个路径各列 3 次，正因其是唯一 3 阶段未合并条目 |
| 2 | 我方鸿蒙改动被静默丢弃 | **通过**（1 处真实丢失，已由 Lead 修复并复核，见 §2） | 11 处初判「丢失」逐条追踪：8 处为格式化换行/等价语法/上游 API 重写后的适配、2 处为上游有意取代并给等价位置、**1 处为真实回归**（DNS/NTP 的平台判定，见 §2） |
| 3 | 上游新增被覆盖 | **通过** | 上游独有新增行仅 4 处被取代（全是 `system.isAndroid → isMobile` 的更宽条件，位置见 §4）；上游新增文件 97 个 **0 缺失**；只被上游改动（M/A/T）的 334 个文件中仅 2 个与上游不同且均为刻意鸿蒙适配（另有 338 个被上游删除的文件，`ohos/`、`scripts/` 均不在其中）；**上游删除行复活 = 0 行** |
| 4 | 争议点 1–5 复核 | **通过**（5/5 追调用链，结论与作者一致） | 见 §4，含每条的自证路径 |
| 5 | 鸿蒙不变量清单 | **通过** | `isOhos` 命中 19 文件；`taskKeeping` 链路（Dart enum/l10n/`AppPlugin.ets`）；`sendTunFd`（`BettboxVpnAbility.ets:205`+`entry.cpp:185`）；`libmeta.so` 命名；`ohos/**`+`scripts/**` 上游改动集为空 |
| 6 | 引用完整性 | **通过** | `lib/common/task.dart`、`lib/common/dns_override.dart`、`plugins/flutter_qjs` 路径与符号（`encodeYamlTask`/`encodeCompactYamlTask`/`applyDnsNodeOverride`/`matchDomainPattern`/`stripDnsSuffix`/`hostSpecificity`/`commonDnsList`）在 `lib/` 中引用数均为 **0**；`plugins/flutter_qjs` 目录已不存在 |

**总体判定**：在 Lead 已应用 `core/patch.go` 平台判定修复的前提下，本次合并**同时保留了两侧语义**，未发现新的静默丢失。唯一编译级阻塞是 2 个仍带冲突标记的生成文件（已由 Lead 明确接受并计划 `build_runner` 重生成，不在我的判定范围内）。

---

## 2. 【Lead 追加项】`core/patch.go` 平台判定修复的独立复核

> 我在 Lead 告知之前已独立发现同一问题（方法：以 `61776f5b` 为基线比对 `lib/state.dart`，再用 `git merge-file` 定位到上游把逻辑搬进 Go），结论与 native-core/Lead 一致。以下是对**修复后状态**的独立验证，不采信任何一方说法。

### 2.1 问题本体（修复前）

| 事实 | 证据命令 | 结果 |
|---|---|---|
| 我方合并前把两处适配放宽到 `isMobile`（含 ohos） | `git show ohos-port-premerge-v1.19.5:lib/state.dart \| sed -n '972,992p;1002,1004p'` | `system.isMobile && rawConfig['dns']['listen']…`（`:53→:10053`、`0.0.0.0→127.0.0.1`）、`if (system.isMobile) rawConfig['ntp']['write-to-system']=false` |
| 祖先/上游同处只认 Android | `git show 45d6fd37:lib/state.dart \| grep -n "10053\|write-to-system" -B6` | `system.isAndroid` |
| `isMobile` 覆盖 ohos | `git show 61776f5b:lib/common/system.dart \| grep isMobile` | `bool get isMobile => isAndroid \| isOhos;`（`:41`）|
| 合并后这两段 Dart 已消失，逻辑进了 Go | `grep -n "10053\|write-to-system" lib/state.dart` | 无命中；`lib/state.dart:789` 改发 `patch: await buildPatchParams(…)`，Go 侧 `core/patch.go:131`、`:270` |
| 鸿蒙构建是 `GOOS=linux` | `grep -n "GOOS\|tags" scripts/build_native.py` | `:116 GOOS='linux'`、`:133 -tags=with_gvisor,ohos` |

### 2.2 子项 1：三处平台分支 + 是否存在第三处漏网判断

```bash
sed -n '50,62p;131p;199p;270p' core/patch.go
grep -rn "runtime.GOOS" core/*.go            # 只看 core 根目录（Clash.Meta 属上游库代码）
grep -rn "patchForAndroid\|patchForLinux\|patchAndroidLike" --include=*.go core | grep -v Clash.Meta
```

* `core/patch.go:59` `var patchForAndroid = runtime.GOOS == "android" || patchAndroidLike`
* `core/patch.go:61` `var patchForLinux  = runtime.GOOS == "linux" && !patchAndroidLike`
* 使用点**恰好 3 处**：`:131`（NTP）、`:199`（`patchTunRouteExclude`，`!patchForLinux` 短路）、`:270`（DNS 块，`!patchForAndroid` 短路）。
* `runtime.GOOS` 在 `core/` 根目录**只出现在 `patch.go:59/61`**（其余命中全在 `core/Clash.Meta/**`，属上游库代码，本次未改动）→ **不存在第三处被漏掉的平台判断**。
* 互补标签：`core/patch_platform_mobile.go:1` = `//go:build android || ohos` → `:10 const patchAndroidLike = true`；`core/patch_platform_other.go:1` = `//go:build !android && !ohos` → `:8 = false`。两者严格互补，**任何 GOOS/标签组合下都恰好命中一个**，无 undefined 风险。

### 2.3 子项 2：用 `go list` 复现标签选择（5+1 种配置）

```bash
cd core
export GOMODCACHE=$PWD/build/gomodcache GOCACHE=$PWD/build/gocache
for cfg in "linux|with_gvisor,ohos" "linux|" "darwin|" "windows|" "android|with_gvisor"; do
  GOOS=${cfg%%|*}; GOARCH=arm64 go list -tags="${cfg##*|}" -f '{{.GoFiles}}' .
done
```

真实 `core` 包的结果（`patch.go` 恒被选中）：

| GOOS | tags | 选中的平台文件 | 推出 |
|---|---|---|---|
| linux | `with_gvisor,ohos` | `patch_platform_mobile.go` | `patchAndroidLike=true` → **`patchForAndroid=true`、`patchForLinux=false`** ✅ 正是鸿蒙所需 |
| linux | （无） | `patch_platform_other.go` | `false` → `patchForAndroid=false`、`patchForLinux=true`（桌面 Linux 行为不变）|
| darwin | （无） | `patch_platform_other.go` | 同上 |
| windows | （无） | `patch_platform_other.go` | 同上 |
| android | `with_gvisor` | `patch_platform_mobile.go` | `patchForAndroid=true`、`patchForLinux=false`（Android 行为不变）|

并做了**可执行**验证（把两个真实文件原样复制到临时模块，表达式与 `patch.go:59,61` 逐字一致，构建/运行 6 种配置）：

```
GOOS=linux tags=<none>            selected=patch_platform_other.go   BUILD_OK
GOOS=linux tags=with_gvisor,ohos  selected=patch_platform_mobile.go  BUILD_OK
GOOS=linux tags=ohos              selected=patch_platform_mobile.go  BUILD_OK
GOOS=android tags=with_gvisor     selected=patch_platform_mobile.go  BUILD_OK
GOOS=darwin/windows               selected=patch_platform_other.go   BUILD_OK
  EXEC GOOS=linux patchAndroidLike=false => patchForAndroid=false patchForLinux=true
  EXEC GOOS=linux patchAndroidLike=true  => patchForAndroid=true  patchForLinux=false
```

`BUILD_OK` 全绿 = 每个配置下 `patchAndroidLike` 都有定义（**无 undefined 符号风险**），且**每个配置恰好一个**平台文件。

### 2.4 子项 3：反向验证「修复是否过度」

`patchForAndroid=true` 时**全部**会触发的分支只有两处（`:131`、`:270`）；逐条对齐合并前 Dart 实现：

| Go 分支（修复后 ohos 会执行） | 合并前 Dart 等价实现 | 判定 |
|---|---|---|
| `patch.go:131-133` `raw.NTP.WriteToSystem = false` | `ohos-port-premerge-v1.19.5:lib/state.dart:1002-1004` `if (system.isMobile) rawConfig['ntp']['write-to-system']=false` | 有对应，**恢复** |
| `patch.go:270-285` `:53→:10053` + `0.0.0.0→127.0.0.1` | 同文件 `:972-992`（`system.isMobile && …` 整块）| 有对应，**恢复** |

`patchForLinux` 一侧**没有**被放宽到鸿蒙（`= … && !patchAndroidLike` → ohos 为 false），这是**正确**的收敛，而非漏改：

```bash
git grep -n "bettbox-route-exclude" 45d6fd37 -- core     # → 无命中
git grep -n "bettbox-route-exclude" upstream/main -- core # → patch.go:54 / common.go:284,289,309
```

`patchTunRouteExclude`（`patch.go:197-215`）+ `core/common.go:284-309` 的 route-exclude-set 注入是 **v1.19.5 全新代码**，祖先与我方 Dart 都**没有**对应实现（Dart 只设置 `route-exclude-address`，该字段祖先即有）。因此若把它也开到鸿蒙，反而会**引入合并前不存在的新行为**；修复选择保持 `patchForLinux=false` 是对的（且 `auto-redirect` 在 Dart 侧是 `system.isLinux`，`lib/state.dart:1006`，与该分支自洽）。

**结论：修复未过度，未引入任何合并前不存在的行为；只把被静默丢弃的两项恢复回来。**

### 2.5 子项 4：上游测试仍可用

`core/patch_test.go:149-151`（`previous := patchForAndroid; patchForAndroid = true; defer …`）与 `:177-178,:194,:209`（`patchForLinux`）都依赖**可写 var**。修复保留了 `var`（未改成 `const`），测试改写路径不受影响；`patchAndroidLike` 是 const，不参与测试改写，语义正确。

> ⚠️ 我**没有**实际运行 `go test`（见 §6），只做了静态一致性核对。

### 2.6 产物侧独立复核

```bash
ls -la ohos/entry/libs/arm64-v8a/
stat -c '%s %y' ohos/entry/libs/arm64-v8a/libmeta.so
readelf -r ohos/entry/libs/arm64-v8a/libmeta.so | grep -c R_AARCH64_TLS_TPREL
```

* `libmeta.so`：74,236,144 B，mtime **2026-10-16 00:29:22**（与 Lead 所述「@00:29」一致，晚于 `core/patch.go` 修改）；`libmeta.h` 同为 00:29。
* `R_AARCH64_TLS_TPREL = 0` → TLS 重定位检查**通过**（我自己跑的，非转述）。
* `libcode_forge.so`：3,097,648 B，mtime 00:25。
* FRB 一致性：`plugins/code_forge/lib/src/rust/frb_generated.dart:67 codegenVersion => '2.13.0'`、`:70 rustContentHash => 834704942`；`plugins/code_forge/rust/Cargo.toml:10 flutter_rust_bridge = "=2.13.0"`；`plugins/code_forge/pubspec.yaml:14 flutter_rust_bridge: 2.13.0`；且 `git diff --stat upstream/main -- plugins/code_forge/rust/src` **为空**（Rust api 定义与上游逐字节相同，仅 `Cargo.toml` +8 行鸿蒙 bindgen 段）→ 重建产物的 content hash 必然等于 Dart 侧期望值。

---

## 3. 问题清单（按严重度）

### 🔴 阻塞（已知、已被 Lead 接受，仅登记）

**B-1 两个生成文件仍带冲突标记** — `lib/models/generated/config.freezed.dart:1030,1032,1034…`（13 个块）、`lib/providers/generated/state.g.dart:478,483,485`

* 现象：`dart format` 解析失败（`The '===' operator is not supported`，行号即 `=======` 处）；在重生成前 `dart analyze`/`flutter build` 必然失败。
* 证据：`grep -rlE '^(<<<<<<< |>>>>>>> |=======$)' --include=*.dart lib`（仅这 2 个文件）；逐个文件 `dart format --output=none` 确认全仓 `lib/` 292 个 dart 文件里**只有**这 2 个语法失败。
* 处置：Lead 已声明用 `dart run build_runner build --delete-conflicting-outputs` 重生成 —— **不属于我的判定范围**。我确认的是「除此之外无任何残留」。

### 🟠 高（已修复，保留记录待真机确认）

**H-1 `core/patch.go` 平台判定使鸿蒙丢失两项移动端适配** — 修复前 `core/patch.go:56,58`；修复后 `core/patch.go:59,61` + 新增 `core/patch_platform_{mobile,other}.go`

* 现象：上游把「DNS `:53→:10053`／`0.0.0.0→127.0.0.1`」与「`ntp.write-to-system=false`」从 Dart 搬进 Go，改用 `runtime.GOOS=="android"` 判定；鸿蒙是 `GOOS=linux -tags ohos` → 两项在鸿蒙上静默失效，而合并前 Dart 用 `isMobile`（含 ohos）**是在鸿蒙上生效的**。
* 证据：见 §2.1 全表。
* 修复：`//go:build android || ohos` / `!android && !ohos` 互补常量 + `var` 保留（测试可改写）。
* 我的复核：§2.2–2.6 全部通过（标签选择/可执行取值/无第三处/未过度/测试可用/产物重建）。
* **残留风险（需真机）**：`'auto-redirect': system.isLinux`（`lib/state.dart:1006`）这一层无法静态判定 —— 真机上 `Platform.isLinux` 的取值决定它是 true 还是 false。我推断为 false（`system.dart:37,39` 中 `isLinux` 与 `isOhos` 互斥，而移植分支能在真机跑起来说明 `isOhos=true`），此时 `patch.go:199` 的 `!patchForLinux` 会先短路，`patchTunRouteExclude` 在鸿蒙上不生效，与合并前一致。**建议真机验证时顺带确认 DNS 端口为 10053/127.0.0.1 且路由表未出现 `bettbox-route-exclude`。**

### 🟡 中

**M-1 提交进仓库的 `pubspec.lock` 是纯上游版本，OHOS 依赖覆盖只在构建期注入** — `pubspec.lock`（与 `upstream/main` **逐字节相同**）、`ohos/pubspec_overrides.yaml`、`scripts/build_ohos.py:58-94,158-161`

* 现象：`path_provider_ohos` / `shared_preferences_ohos` 及 gitcode 分支引用已不在 lock 里；它们由 `build_ohos.py` 在构建前把 `ohos/pubspec_overrides.yaml` 复制到仓库根 `pubspec_overrides.yaml`，构建后删除。
* 风险：**照 `docs/upstream_merge_2026-09-27.md:160` 的「同步上游」流程直接跑** `flutter build hap --release --no-codesign --dart-define=APP_ENV=stable`（或在 IDE 里直接构建/`flutter pub get`），会解析出 pub.dev 的原版 `path_provider`/`shared_preferences` → 产出在鸿蒙上 `MissingPluginException`/路径 API 不可用的包，且**构建会成功**，属于「静默产出坏包」。
* 证据：`diff <(git show upstream/main:pubspec.lock) pubspec.lock` → 空；`grep -n "gitcode" pubspec.lock` → 无；`grep -c "source: git" pubspec.lock` = 1（仅 `hotkey_manager_linux`，来自 `pubspec.yaml:76-83` 的 `dependency_overrides`）。
* 建议（择一）：① 在合并手册里把「构建必须走 `scripts/build_ohos.py`」写成硬约束并修掉 `:160` 那行；② 或把两个 ohos 覆盖直接写进 `pubspec.yaml` 的 `dependency_overrides`（代价是桌面侧 lock 被拖上 gitcode 依赖）。

**M-2 根目录 `pubspec_overrides.yaml` 未被忽略，构建被强杀时会残留**

* 现象：`build_ohos.py` 只在 `finally` 里删除注入文件；`SIGKILL`/断电不会走到 `finally`。残留文件会污染后续 `flutter pub get` 与工作区（`git status` 出现未跟踪文件），并且**不在 `.gitignore`**（`grep -n pubspec_overrides .gitignore` → 无）。
* 建议：`.gitignore` 增加 `/pubspec_overrides.yaml`；`build_ohos.py` 启动时先做一次「陈旧注入文件」清理与告警。

### 🔵 低

**L-1 `lib/main.dart:2` `import 'dart:ffi';` 未使用（上游遗留，非本次合并引入）** — `lib/main.dart:2`
* 证据：`grep -nE "\b(Pointer|NativeFunction|DynamicLibrary|Struct|Union|Abi|sizeOf|calloc|malloc|NativeApi)\b" lib/main.dart` → 0 命中；`git show upstream/main:lib/main.dart` 同样导入且同样 0 命中；`45d6fd37` 亦然。→ 属上游既有 `unused_import`（warning 级），修不修都不影响构建。
* 提示：`dart:async` 亦可能同病（`Future` 由 `dart:core` 导出），可在 pub 恢复后用 `dart analyze` 一次性清理。

**L-2 `.gitignore:73` 模式畸形：`/assets/data/zash.zip# Miscellaneous`**
* 现象：上游该行是 `/assets/data/zash.zip`（**无行尾换行**），我方分支在其后粘上了 `# Miscellaneous`，导致 `zash.zip` **不再被忽略**。
* 证据：`tail -3 .gitignore | cat -A`；`git check-ignore -v assets/data/zash.zip` → 未被忽略；`git status --porcelain -- .gitignore` → 空（**本次合并没有改动 `.gitignore`**，属既有问题）。
* 影响：当前 `assets/data/zash.zip` 不存在，暂无实际后果；一旦该文件出现会被误提交（大文件）。
* 建议：拆成两行（`/assets/data/zash.zip` 与 `# Miscellaneous`）。

**L-3 `lib/main.dart:88-89` 注释与事实不符**
* 注释称「鸿蒙分支保留 flutter_displaymode 依赖**与应用级设置**」，但 `enableHighRefreshRate` 已被上游 v1.19.5 移除且**未**恢复：`grep -rn "enableHighRefreshRate" lib` 只剩这条注释；`lib/models/config.dart` 无该字段，无 UI 项引用（`highRefreshRate` 只剩 arb/生成物里的孤儿键）。
* 另：高刷申请门控是 `system.isAndroid`（`lib/main.dart:87`、`lib/application.dart:159`），**鸿蒙不生效**——这与合并前一致（合并前 `lib/main.dart` 同处也是 `if (system.isAndroid)`、`lib/application.dart:95` 是 `system.isAndroid && appSetting.enableHighRefreshRate`），**不是回归**。
* 建议：把注释改成「保留依赖用于 Android 后台恢复时重申请高刷」；若鸿蒙也需要高刷，需显式决策（并恢复设置项）。

**L-4 `docs/upstream_merge_2026-09-27.md` 未记录本次 v1.19.5 合并**
* 该手册是历次合并的唯一经验载体，而本次踩到的坑（`core/patch.go` 用 `runtime.GOOS` 判平台、上游把 Dart 逻辑搬进 Go 后**平台语义被收窄**、`file_picker` 新 API 去掉 `withData`、`OtherSettingView` 改 StatefulWidget）都值得沉淀。建议追加一节，并把「基线必须用 `ohos-port-premerge-*` 而不是 merge-base」写进方法。

---

## 4. 争议点 4 的独立结论（含 1/2/3/5 复核）

> 要求：不采信作者说法，自己追调用链。以下每条都给出我自己的取证路径与文件:行号。

### 争议点 4（重点）：`RustLib.init(externalLibrary: …)` 语义是否丢失 —— **结论：语义完整保留，无未使用 import 引入，无重复初始化**

* `lib/main.dart:85` → `await ensureRustLib();`（**上游 v1.19.5 新增的调用点**，合并前此处是内联 `try { await RustLib.init(); }`）。
* `lib/common/rust.dart:8` `Future<bool> ensureRustLib() => _rustLibReady ??= _initRustLib();` → 幂等（首次后复用 Future，失败时 `_rustLibReady = null` 可重试，`:24`）。
* `lib/common/rust.dart:12-20`：`if (system.isOhos) { await RustLib.init(externalLibrary: ExternalLibrary.open('libcode_forge.so')); } else { await RustLib.init(); }` —— **我方语句逐字保留**，注释也在。
* `lib/common/common.dart:17 export 'rust.dart';` → `main.dart` 经 `common/common.dart` 拿到该符号（`grep -rn "RustLib.init" lib plugins` 全仓只有 `rust.dart:15/19` 两处，**无重复初始化**）。
* 未使用 import：合并后 `main.dart` 不再导入 `flutter_rust_bridge_for_generated`（已随逻辑一起搬进 `rust.dart:4`），因此**没有**留下悬空 import；`material_ui`/`flutter/services`/`dart:isolate`/`dart:ui`/`dart:io` 均有实际符号引用（`WidgetsFlutterBinding`/`runApp`/`immutable`、`SystemChrome`/`SystemUiMode`、`ReceivePort`、`IsolateNameServer`、`exit`/`HttpOverrides`）；唯一未使用的是上游遗留的 `dart:ffi`（见 L-1）。
* **额外收获**：`lib/common/js_runtime_manager.dart:42,73` 也调用 `ensureRustLib()`（上游新增的脚本引擎路径）→ 说明「上游把 JS 引擎换成 code_forge」这条新链路在鸿蒙上也走同一个 ohos 适配入口，覆盖完整。

### 争议点 1：`tunnel.dart` 的 `scrollable: false` workaround 是否仍生效 —— **结论：成立**

调用链（逐跳）：

1. `lib/views/config/tunnel.dart:62` `globalState.showCommonDialog(child: _TunnelDialog(…))`（上游 v1.19.5 把 `showDialog` 换成了它）；
2. `lib/state.dart:600-614` `showCommonDialog` → `showGeneralDialog(pageBuilder: (…) => child)`（**原样返回 child，不套壳**）；
3. `lib/views/config/tunnel.dart:127` `_TunnelDialogState.build` 现在 `return CommonDialog(…)`；
4. `lib/widgets/dialog.dart:77-82` `CommonDialog` 内构造 `AlertDialog(scrollable: false, …)`，注释正是鸿蒙原因；
5. `lib/widgets/dialog.dart:120-122` content = `SingleChildScrollView(child: child)`（`overrideScroll=false` 时）→ tunnel 未传 `overrideScroll`，因此自滚一层 + `scrollable:false` 关掉 AlertDialog 的第二层 → **不会触发当初那个「双层滚动 + IntrinsicWidth 渲染不出来」的问题**。
6. 交叉验证：`git show upstream/main:lib/widgets/dialog.dart | grep -n scrollable` → **无命中**（上游没有这行），说明该行是**我方改动被保留**，不是碰巧撞上。

### 争议点 2：`item.dart` 删掉 `&& system.isAndroid` 后鸿蒙是否会崩 —— **结论：不会崩，且是超集**

* 上游删除门控的依据：`git diff 45d6fd37 upstream/main -- lib/views/connection/item.dart` 中 `- state.findProcessMode == FindProcessMode.always && system.isAndroid`；上游改为 `always`（桌面也支持进程图标）。
* 我方的 `isMobile` 是 `always` 的**子集**（`system.dart:41`），故取上游写法是放宽而非收窄；合并结果 `lib/views/connection/item.dart:85-87` 保留 `always`。
* 鸿蒙取图标路径的**实际安全性**（我自己追的）：
  * `lib/views/connection/item.dart:232-237` `_loadIcon`：桌面走 `processIcon.get`，否则 `await app.getPackageIcon(key) ?? await _getDefaultPackageIcon()`；
  * `lib/plugins/app.dart:159-167` → MethodChannel `getPackageIcon`；
  * `ohos/entry/src/main/ets/plugins/AppPlugin.ets:443-445` → **`result.success(null)`**（鸿蒙不实现进程图标，返回 null 而不是抛错/notImplemented）；
  * 回到 Dart：null → 回落到 `_getDefaultPackageIcon()` → `getPackageIcon('')` → 仍是 null → 返回 null；`item.dart:248-257` 的 `.then(...)`/`whenComplete` 链路对 null 安全，`item.dart:213` 用 `?icon` 空安全展开 → **只是不显示图标，不会抛异常**。
  * 补充：`patchClashConfig` 在鸿蒙默认就是 `findProcessMode: always`（`lib/state.dart:50`，我方 `system.isMobile` 分支），所以这条路径在鸿蒙上**本来就会被走到**，不是新增暴露面。

### 争议点 3：`google_bottom_nav_bar.dart` 的「显示条件 vs 生效条件」是否一致 —— **结论：一致**

* 生效侧：`lib/widgets/google_bottom_nav_bar.dart:117-127` `_triggerHapticFeedback(bool enableFeedback)` → `if (system.isMobile && enableFeedback)`（我方门控随上游重写迁移，注释在 `:118-119`）；两个调用点 `:231`、`:289` 都在「触摸换 tab 且 index 变化」时触发；`enableFeedback` 来自 `:169` 的 `appSettingProvider…enableNavBarHapticFeedback`。
* 显示侧：`lib/views/application_setting.dart:605` `if (system.isMobile) ...[NavBarHapticFeedbackItem()]`（我方；上游 `:603` 是 `system.isAndroid`）。
* → 两侧都是 `isMobile`，**设置项「看得见」与「点了有用」在 ohos 上同时为真**，不再有「显示但无效」的错位。

### 争议点 5：`_toggleWakelock(context, enabled)` 形参与调用点是否一致 —— **结论：一致（2 参 ↔ 2 参）**

* 声明：`lib/views/dashboard/widgets/wakelock_switch.dart:13` `_toggleWakelock(BuildContext context, bool enabled)`；
* 调用：同文件 `:87-89` `onChanged: (_) => _toggleWakelock(context, wakelockEnabled)`（`wakelockEnabled` 来自 `:83` `ref.watch(wakelockStateProvider)`）→ **唯一调用点，无 1 参残留**；
* 上游版本是 1 参（`git show upstream/main:… | grep -n _toggleWakelock` → `:12` / `:79`），合并把调用点更新成了我方 2 参形态（`grep -n _toggleWakelock` 全文件仅 3 处，其中 2 处为声明+调用）→ 语义自洽：鸿蒙没有 `wakelock_plus` 查询能力，改由 Provider 当前值传入，`:15-24` 的 `system.isOhos → app.setKeepScreenOn(!enabled)` 分支完好。

---

## 5. 我尝试过但没有找到问题的攻击面（覆盖度自述）

> 目的：让 Lead 能判断「通过」背后的**覆盖度**，而不是只看结论。

1. **冲突标记**：全仓（含未跟踪文件，排除 `.git`/`build`/`.dart_tool`）扫 `^<<<<<<< `、`^>>>>>>> `、`^||||||| `、`^=======$`；对 `=======` 的误报用**配对计数**排除（`open/sep/close` 数量必须相等，且必须与 `<<<<<<<` 同文件共存）→ 唯一仓外命中是 gitignore 掉的 cargo 镜像 README 里的 Markdown setext 下划线。
2. **61 个双侧文件的唯一新增行存活**：我方 0 处未解释丢失（11 处初判全部定性，见 §1 第 2 行）；上游方面 4 处全部是 `isAndroid→isMobile` 更宽条件取代，位置：`lib/state.dart:1004-1005`、`lib/views/application_setting.dart:605`、`lib/views/config/network.dart:11,688,696,697,716`、`lib/widgets/google_bottom_nav_bar.dart:120`。
3. **上游删除行复活**：`(base−theirs) ∩ 工作区 − ours` = **0 行**（61 文件全扫）。
4. **单向文件守恒**：只被我方改的 81 个文件里，仅 5 个与 ours 不同 → 全部为我方有意的手工改动（`core/lib_ohos.go` +54B、`lib/manager/ohos_tray_manager.dart` +7B（material_ui 迁移）、`readme/README_ohos_en.md`、`readme/README_zh_upstream.md`（版本号/上游正文）、`scripts/build_native.py`（libclang/bindgen））；只被上游改的 334 个文件里仅 2 个与上游不同 → `lib/common/rust.dart`（ohos `ExternalLibrary` 分支）、`plugins/code_forge/rust/Cargo.toml`（ohos bindgen 段）——全部是刻意鸿蒙适配。
5. **新增文件守恒**：我方独有新增 67 个、上游独有新增 97 个，**全部存在于工作区**（0 缺失）；上游删除的 `lib/common/task.dart`、`lib/common/dns_override.dart`、`plugins/flutter_qjs` 相关 80+ 文件均已按上游意图消失（`plugins/flutter_qjs` 目录已不存在）。
6. **arb（7 个，全部 UU）**：`json.loads` 全部合法；与 `intl_en.arb` 的键集比对 → **没有任何语言缺 en 的键**；多出的键只有历史遗留（`zoom` 6 个语言、`ru` 另有 `lightIcon/lightIconDesc/tolerance/ua`）——上游亦然。
7. **l10n 生成物一致性**：`lib/l10n/l10n.dart` 解析出 **810** 个消息；7 个 `messages_*.dart` **各 810 个键且覆盖全部 getter**（0 缺）；我方 11 个键（`descOhos`、`backgroundTask*`、`modeDataTransfer/AudioPlayback/TaskKeeping`、`addPackageName`、`invalidPackageName`、`ohosAccessManualOnly`）在 7 个语言文件中**全部存在**；`lib/l10n/intl/messages_all.dart` 与 `upstream/main` **逐字节相同**（符合手册「整体取上游」）；en-arb 文本与 `l10n.dart` 内联文案 0 处不一致（20 个「无 getter」项经核全是 `String x(Object y)` 参数化方法）。
8. **`material_ui`/`cupertino_ui` 迁移完整性**：工作区 141 个文件用 `material_ui`，上游 140 个；差异 1 个 = `lib/manager/ohos_tray_manager.dart`（Lead 迁移）；**没有任何**「上游已迁 material_ui 而工作区仍用 `flutter/material`」的文件；唯一仍用 `flutter/material.dart` 的是 `lib/l10n/l10n.dart`——**上游也是它**。`lib/application.dart` 的 `cupertino_ui` 亦与上游一致。
9. **Dart 语法**：对全部 292 个受版本控制 `lib/**.dart` 逐文件 `dart format --output=none` → 失败 2 个（= B-1 的两个生成文件），其余 290 个仅「风格可改」（见 §0.2 对照实验）。
10. **`file_picker` 上游 API 重写**：上游 `v13` 新 API 去掉了 `withData` 参数并改用静态 `FilePicker.pickFiles/pickFile/saveFile`＋`skipEntitlementsChecks`；合并结果 `lib/common/picker.dart:11-20,45-51,100-103` **同时**保留我方 ohos 分支（`_pickerFilesOhos` / `app.pickFiles` / `app.saveFile`）与上游新调用形态，且全仓调用点（`lib/controller.dart:1610`、`lib/pages/editor.dart:469`、`lib/views/profiles/scripts.dart:508`、`lib/views/proxies/providers.dart:240`、`lib/views/backup_and_recovery.dart:138`）**没有一个**再传 `withData:` → 签名迁移闭合。
11. **`services.googleapis.cn` 行为**：工作区 `lib/state.dart:1031` 与 `upstream/main:937` **逐字相同**（`if (system.isAndroid || host.key != 'services.googleapis.cn')`）→ 无分歧。
12. **我方不变量**：`isOhos` 19 文件（逐文件列出核对）；`taskKeeping`/`BackgroundTaskMode` 链路（`lib/enum/enum.dart:120`、7 语言 l10n、`ohos/.../AppPlugin.ets:33,347,351,454,464,490`）；`sendTunFd`（`ohos/.../BettboxVpnAbility.ets:193-206`、`ohos/entry/src/main/cpp/entry.cpp:185`、Dart 侧 `lib/plugins/service.dart:87`+`lib/clash/lib.dart:281-303`）；`libmeta.so`（`scripts/build_native.py:124`、`lib/clash/lib.dart:168`；`lib/common/path.dart:101,171` 的 `libclash` 只是**上游**的 dev 目录名，`45d6fd37`/`upstream/main`/ours 三方都有，不是改名残留）；`DynamicLibrary.open` 仅 4 处且无 `libclash.so`。
13. **`ohos/**`、`scripts/**` 未被上游触碰**：`git diff --name-only 45d6fd37 upstream/main -- ohos scripts` → **空**。
14. **原生产物**：libmeta.so 尺寸/mtime/TLS 重定位、libcode_forge.so mtime、FRB codegen 版本三方一致 + `rustContentHash 834704942` + `plugins/code_forge/rust/src` 与上游逐字节相同（§2.6）。
15. **小项**：`lib/common/system.dart` 我方 `isOhos/isMobile` 定义完好且上游新增 `kDebugMode` 分支已并入；`lib/pages/scan.dart` 的 `material_ui` + `flutter/services` 双 import 注释合理；`lib/controller.dart` 已无 `_initHighRefreshRateDefault`/`enableHighRefreshRate` 悬空引用；`lib/common/tray.dart`、`lib/views/other_setting.dart`（我方 `BackgroundTaskItem` 与上游 StatefulWidget 结构并存）、`lib/views/tools.dart`（我方 `isMobile` + 上游新搜索项并存）均无丢失。

---

## 6. 未能验证的部分与原因

| 项 | 原因 | 影响 |
|---|---|---|
| `dart analyze` / 编译级类型检查 | `.dart_tool/package_config.json` 指向已不存在的 pub 缓存，pub 不可用；analyze 输出为级联噪声 | 「无语法错误」已由 `dart format` 证明；**跨文件类型/参数不匹配只能靠人工追签名**（我已追了 picker/wakelock/rust/tunnel 等热点）。建议 pub 恢复后由 Lead 跑一次 `dart analyze lib` 作为最终门禁 |
| `build_runner` / `intl_utils:generate` 重生成 | 同上（需 pub） | B-1 的最终判定以重生成结果为准 |
| `go test ./...`（含 `patch_test.go`） | 需要完整依赖 + cgo 工具链；我只做了 `go list`/`go build`（临时模块）与静态核对 | 修复的**标签选择与取值**已被证明（§2.3），但上游 `core/patch_test.go` 我**未实际执行**。建议 Lead 在有 Go 环境时跑 `CGO_ENABLED=0 go test -run TestApplyPatch ./...` |
| HAP 全量构建 / 真机运行 | 沙箱内无 DevEco/hdc 与签名材料；`flutter` 包装脚本只读 | 运行期行为（DNS 端口、NTP、FRB 加载、material_ui 渲染、`isLinux` 真实取值）未验证 |
| 二进制语义比对（libmeta.so 内是否真含修复后的常量） | 我只能证明「标签选择正确 + 产物 mtime 晚于源码修改 + TLS 检查通过」 | 严格意义上是**间接**证据；`strings` 能查到 `bettbox-route-exclude`（该常量随两版都存在）不足以区分新旧。建议真机日志确认 DNS 监听端口 |
| `dart format` 的 `Changed` 名单 | 无 package_config → 语言版本/风格假设与仓库实际不同（对照组证明） | 该名单**不作为**合并缺陷证据；也因此无法据此判断格式合规性 |

---

## 7. 复现命令速查

```bash
# 基线
git log --oneline -1 45d6fd37 upstream/main ohos-port-premerge-v1.19.5

# ① 冲突标记（带配对验证）
grep -rInE '^(<<<<<<< |>>>>>>> |\|\|\|\|\|\|\| )' --exclude-dir=.git --exclude-dir=build --exclude-dir=.dart_tool .
for f in lib/models/generated/config.freezed.dart lib/providers/generated/state.g.dart; do
  echo "$f open=$(grep -c '^<<<<<<< ' $f) sep=$(grep -c '^=======$' $f) close=$(grep -c '^>>>>>>> ' $f)"; done

# ② 我方改动是否还在（示例：任选文件）
git diff 45d6fd37 ohos-port-premerge-v1.19.5 -- lib/<file>
git diff 45d6fd37 upstream/main            -- lib/<file>

# ③ 机械三方合并偏差（我方→base→上游）
git show 45d6fd37:<f> >/tmp/b; git show ohos-port-premerge-v1.19.5:<f> >/tmp/o; git show upstream/main:<f> >/tmp/t
git merge-file -p --diff3 /tmp/o /tmp/b /tmp/t | diff - <f>

# ④ 平台标签矩阵
cd core && GOMODCACHE=$PWD/build/gomodcache GOCACHE=$PWD/build/gocache \
  bash -c 'for g in linux darwin windows android; do GOOS=$g GOARCH=arm64 go list -tags=with_gvisor,ohos -f "{{.GoFiles}}" . ; done'

# ⑤ Dart 纯语法（不依赖包解析）
./.toolchain/flutter_ohos/bin/cache/dart-sdk/bin/dart format --output=none lib/<file>
#    语法错误会打印：Could not format because the source could not be parsed

# ⑥ 产物
stat -c '%s %y' ohos/entry/libs/arm64-v8a/libmeta.so
readelf -r ohos/entry/libs/arm64-v8a/libmeta.so | grep -c R_AARCH64_TLS_TPREL
```

---

## 8. 报告文件路径

`docs/verify_upstream_v1.19.5.md`（仓库内相对路径）
