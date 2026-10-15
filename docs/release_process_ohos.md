# 鸿蒙移植版：发行流程与产物命名规则

> 面向本仓维护者。规则以 `scripts/release_ohos.py` 为准（本文是说明与依据）。

---

## 1. 版本号与发布标签

| 项 | 取值来源 | 说明 |
| --- | --- | --- |
| `version`（如 `1.19.5`） | 根 `pubspec.yaml` 的 `version:` 主版本号 | 与上游版本保持一致 |
| `versionCode`（如 `2026101301`） | `pubspec.yaml` 的 `version: x.y.z+<构建号>` | 同时写入 `ohos/AppScope/app.json5`（构建脚本会同步） |
| 发布标签 | `ohos-v<version>` | 指向该版本的**发布快照提交**；一版一个标签，已发布的标签不移动 |

## 2. 产物命名规则

```
bettbox-<version>-ohos-vc<versionCode>-<build>.hap
bettbox-<version>-ohos-vc<versionCode>-<build>.hap.sha256
```

- 全小写；`<build>` = `unsigned`（**对外发布**）或 `signed`（本机自用、不外发）。
- 校验文件与 HAP **同名**加后缀 `.sha256`，内容为标准 `sha256sum` 输出（`<hash>  <文件名>`），
  可用 `sha256sum -c <文件>` 直接验证。
- 存放目录：`build/ohos/hap/`（已被 `.gitignore` 忽略，不入库）。
- 示例：`bettbox-1.19.5-ohos-vc2026101301-unsigned.hap` + 同名 `.sha256`。

### 2.1 为什么对外只发 unsigned

鸿蒙的签名 Profile（debug 类型）会被写进 HAP 的签名块，内含签名者的 `developer-id` 与
`device-ids`（设备 UDID 列表）。发布签名包等于把这些信息公开出去 ⇒ **对外只发 unsigned**，
由使用者用自己的证书/Profile 签名后安装。`release_ohos.py` 会扫描产物并在命中签名 Profile 时
直接拒绝（除非显式加 `--allow-signed`，仅本机自用场景）。

## 3. 发布前必须通过的检查（脚本自动执行）

1. 产物含 `libapp.so` 且**不含** `kernel_blob.bin`（否则是 JIT 包，装到设备上一启动就退）。
2. `geoip.metadb` / `GeoSite.dat` / `ASN.mmdb` 以**原文件或 `.gz`** 形式随包（缺失会让应用启动即退出）。
3. release 构建下 `MaterialIcons-Regular.otf` 已被 tree-shake（约 29 KB；丢失会白胖约 1.5 MB）。
4. HAP 内 `module.json` 的 `versionName` / `versionCode` 与 `pubspec.yaml` 一致。
5. HAP 内**不含签名 Profile**（`developer-id` / `device-ids` / `"type":"debug"`）。
6. 命名与校验文件符合第 2 节规则，且重新计算 SHA-256 与原文件一致。

## 4. 发布步骤

```bash
# ① 构建并本机验证（签名包只用于自己安装验证，不外发）
python3 scripts/build_ohos.py --sign
./.home/deveco.sh devecocli run --device <你的设备> --skip-build

# ② 生成对外交付件：未签名 HAP + 同名 .sha256 + 由模板渲染的 release note
python3 scripts/release_ohos.py

# ③ 自查与发布
python3 .home/sanitize_check.py          # 入库面零命中
#   在 GitHub 创建 Release：tag 选 ohos-v<version>，
#   正文粘贴 ② 生成的 release-note-ohos-v<version>.md，上传 ② 的两个文件
```

## 5. 分支与发布快照

- 对外只发布**脱敏快照分支** `ohos-port-clean` 的内容（推到远端 `ohos-port`）；
  本机开发历史 `ohos-port`、`ohos-port-backup*` 及备份标签**永不外推**。
- 快照规则：**在上一次快照之上追加一个匿名提交**（`parent` = 上一版快照，
  author/committer 为匿名身份），因此发布推送是普通 fast-forward，**不需要 force**。
- 推送前的两项强制自查：
  - 文件内容：`python3 .home/sanitize_check.py`（本机标识清单只在该脚本里，不入库）；
  - 元数据（文件扫描器覆盖不到）：提交作者与标签 tagger 必须是匿名身份，
    见 `git log -1 --format='%an <%ae>' <快照提交>` 与 `git cat-file tag <tag> | sed -n 4p`。

## 6. Release Note

- 模板：`.github/release_template_ohos.md`；占位符由 `scripts/release_ohos.py` 替换
  （`VERSION`、`VERSION_CODE`、`HAP_NAME`、`HAP_SIZE`、`SHA256`、`RELEASE_COMMIT`、
  `UPSTREAM_VERSION`、`UPSTREAM_COMMIT`、`PREV_VERSION`）。
- 写作要求：面向用户，只讲功能与影响；**不写**构建机路径、设备型号/序列号、账号信息，
  也不写内部排查过程或测试记录。
- 新增能力在「功能一览」里用 **🆕** 标注，并在「本次更新 › 新增」逐条列全（不要用「见上」这类模糊指代）。
