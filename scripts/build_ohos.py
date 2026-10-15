#!/usr/bin/env python3
"""Bettbox 鸿蒙 HAP 构建主脚本。"""

import argparse
import base64
import gzip
import os
import re
import shutil
import subprocess
import sys
import time
from pathlib import Path

root = Path(__file__).resolve().parents[1]

# 构建期转 gzip 随包的 geo 数据（hvigor 把 rawfile 原样 STORED，压一下省 ~5.4MB）
GEO_ARCHIVE_FILES = ('geoip.metadb', 'GeoSite.dat', 'ASN.mmdb')


def sync_app_version():
    """把 pubspec.yaml 的版本同步进 AppScope/app.json5。

    鸿蒙没有 package_info_plus 实现，应用内版本改由原生 bundleManager 读取，
    因此 HAP 元数据必须与 pubspec 保持一致，否则「关于」页/更新检查会显示旧版本。
    """
    pubspec = root / 'pubspec.yaml'
    app_json5 = root / 'ohos' / 'AppScope' / 'app.json5'
    if not pubspec.is_file() or not app_json5.is_file():
        return
    match = re.search(r'^version:\s*([0-9]+\.[0-9]+\.[0-9]+)(?:\+([0-9]+))?', pubspec.read_text(encoding='utf-8'), re.M)
    if not match:
        print('警告：pubspec.yaml 未找到版本号，跳过版本同步。', flush=True)
        return
    version_name, build_number = match.group(1), match.group(2)
    content = app_json5.read_text(encoding='utf-8')
    updated = re.sub(r'("versionName"\s*:\s*)"[^"]*"', r'\1"' + version_name + '"', content, count=1)
    if build_number:
        updated = re.sub(r'("versionCode"\s*:\s*)\d+', r'\g<1>' + build_number, updated, count=1)
    if updated != content:
        app_json5.write_text(updated, encoding='utf-8')
        print(f'已同步应用版本：versionName={version_name} versionCode={build_number or "未变更"}', flush=True)

def archive_geo_assets(backup_dir: Path) -> list[tuple[Path, Path]]:
    """构建期把 geo 数据换成 gzip 版，构建后由调用方还原。

    hvigor 会把 `resources/rawfile/**` 原样 **STORED** 进 HAP（不压缩），
    而 geo 数据是未压缩的二进制：实测 9.17MB → 3.77MB，等于白省 **5.4MB**（约 -9%）。
    Dart 侧 `ClashCore.loadGeoAsset()` 会先找原文件、找不到再解压 `.gz`，
    所以这套「构建期替换」对运行时是透明的，gzip 自带 CRC 也保证了解压完整性。
    """
    moved: list[tuple[Path, Path]] = []
    data_dir = root / 'assets' / 'data'
    raw_total = gz_total = 0
    for name in GEO_ARCHIVE_FILES:
        raw = data_dir / name
        gz = data_dir / f'{name}.gz'
        backup = backup_dir / name
        # 自愈：上次构建若在「搬回原文件 / 删掉 .gz」之间被打断，会留下「原文件没有、
        # 备份还在 build/ 下」的死状态 —— 此时若直接跳过，产出的 HAP 会**完全没有 geo 资源**，
        # 应用启动即 exit(0)（见 core.dart initGeo）。所以先把备份搬回来。
        if not raw.is_file() and backup.is_file():
            if gz.is_file():
                gz.unlink()
            shutil.move(str(backup), str(raw))
            print(f'警告：检测到上次构建中断，已从备份恢复 {name}', flush=True)
        if not raw.is_file():
            continue
        with raw.open('rb') as src, gzip.open(gz, 'wb', compresslevel=9) as dst:
            shutil.copyfileobj(src, dst)
        backup = backup_dir / name
        shutil.move(str(raw), str(backup))
        moved.append((raw, backup))
        raw_total += backup.stat().st_size
        gz_total += gz.stat().st_size
    if moved:
        print(
            f'geo 资源已转为 gzip 随包：{raw_total / 1048576:.2f}MB -> {gz_total / 1048576:.2f}MB'
            f'（省 {(raw_total - gz_total) / 1048576:.2f}MB，构建后还原）',
            flush=True,
        )
    return moved


def restore_geo_assets(moved: list[tuple[Path, Path]]) -> None:
    # 顺序很重要：**先**把原文件搬回来，**再**删 .gz。
    # 反过来的话，若在两步之间被 Ctrl-C / 异常打断，就会得到「原文件与 .gz 都没有」的死状态。
    for raw, backup in moved:
        if backup.is_file():
            shutil.move(str(backup), str(raw))
        gz = raw.with_name(f'{raw.name}.gz')
        if gz.is_file():
            gz.unlink()


def hvigor_report_snapshot() -> set[str]:
    report_dir = root / 'ohos' / '.hvigor' / 'report'
    return {p.name for p in report_dir.glob('report-*.json')} if report_dir.is_dir() else set()


def verify_dart_defines(app_env: str, started_at: float, before: set[str] | None = None) -> bool:
    """确认 `--dart-define=APP_ENV=...` 真的进了本次 Dart AOT 构建。

    踩过的坑（2026-10-16 真机）：`flutter build hap` 自己会调 hvigorw 并带
    `-p DART_DEFINES=<base64>`；但如果之后再用 `devecocli build` 打包一次，
    **hvigor 会在没有 DART_DEFINES 的情况下重跑 flutter assemble**，把 AOT 换成
    `isPre=true` 的版本 —— 表现为正式包里右上角出现 PRE 角标、且更新检查被静默关闭。
    flutter 插件只从 hvigor 的 `-p` 扩展参数读 DART_DEFINES（`getExtParam`，不受
    环境变量与 hvigor-config.json5 的 properties 影响），devecocli 又不透传 `-p`，
    所以正确做法是**只跑一次**：`flutter build hap`（可加 `--sign` 让 hvigor 直接签名）。
    这里用 hvigor 自己写的构建报告（`.hvigor/report/report-*.json` 记录完整命令行）复核。
    """
    expected = base64.b64encode(f'APP_ENV={app_env}'.encode()).decode()
    report_dir = root / 'ohos' / '.hvigor' / 'report'
    # 只认「构建前不存在」的报告：靠 mtime 取最新会误取紧邻上一次构建的报告（假通过）
    reports = [p for p in report_dir.glob('report-*.json')
               if (before is None or p.name not in before)
               and p.stat().st_mtime >= started_at - 5] if report_dir.is_dir() else []
    if not reports:
        print('警告：未找到本次 hvigor 构建报告，跳过 APP_ENV 校验。', flush=True)
        return True
    newest = max(reports, key=lambda p: p.stat().st_mtime)
    if expected in newest.read_text(encoding='utf-8', errors='ignore'):
        print(f'已确认 APP_ENV={app_env} 进入本次 Dart AOT 构建。', flush=True)
        return True
    print(
        f'错误：本次 hvigor 构建（{newest.relative_to(root)}）里没有 DART_DEFINES={expected}，\n'
        f'      说明 APP_ENV={app_env} 没传进 flutter assemble —— 这个包会是 isPre=true：\n'
        f'      应用右上角出现 PRE/DEBUG 角标，且**不会检查更新**。\n'
        f'      请用 `flutter build hap`（本脚本）一次成包；不要再叠一次 devecocli build。',
        flush=True,
    )
    return False


def verify_package(started_at: float, check_icon_shake: bool = True) -> bool:
    """校验产物形状（以下每条都是实测踩过 / 差点踩到的致命回归）：

    · 没有 `libapp.so` 或出现 `kernel_blob.bin` ⇒ JIT 包，装到真机起来就退；
    · geo 资源（`geoip.metadb` / `GeoSite.dat` / `ASN.mmdb`，原文件或 .gz 皆可）缺任何一个
      ⇒ `initGeo()` 直接 `exit(0)`，应用**起来就退**，且现场几乎没有日志；
    · release 下 `MaterialIcons-Regular.otf` 应被 tree-shake 到 ~29KB/226 字形：
      丢了 `TREE_SHAKE_ICONS` 会涨到 ~1.6MB（白胖 1.5MB），字体整个缺失同样是异常。

    只校验本次构建产出的 HAP（mtime ≥ 构建开始时间）。
    """
    import zipfile

    hap_dir = root / 'build' / 'ohos' / 'hap'
    haps = [p for p in hap_dir.glob('*.hap')
            if p.stat().st_mtime >= started_at - 5] if hap_dir.is_dir() else []
    if not haps:
        print('警告：未找到本次构建的 HAP 产物（build/ohos/hap/*.hap），跳过产物校验。', flush=True)
        return True

    hap = max(haps, key=lambda p: p.stat().st_mtime)
    with zipfile.ZipFile(hap) as archive:
        names = archive.namelist()
        app_so = [n for n in names if n.endswith('libapp.so')]
        kernel = [n for n in names if 'kernel_blob' in n]
        icons = [n for n in names if n.endswith('MaterialIcons-Regular.otf')]
        icon_size = archive.getinfo(icons[0]).file_size if icons else 0
        missing_geo = [
            name for name in GEO_ARCHIVE_FILES
            if not any(n.endswith(f'assets/data/{name}') or n.endswith(f'assets/data/{name}.gz')
                       for n in names)
        ]

    print(
        f'产物校验：{hap.name}  {hap.stat().st_size / 1048576:.1f}MB  '
        f'libapp.so={len(app_so)}  kernel_blob={len(kernel)}  MaterialIcons={icon_size}B  '
        f'geo 缺失={missing_geo or "无"}',
        flush=True,
    )

    ok = True
    if not app_so or kernel:
        print(
            '错误：产物里没有 libapp.so 或含 kernel_blob.bin —— 这是 JIT 包，装到真机起来就退。\n'
            '      请确认走的是 `flutter build hap`（本脚本），而不是 hvigor/devecocli 直编。',
            flush=True,
        )
        ok = False
    if missing_geo:
        print(
            f'错误：HAP 里缺少 geo 资源 {missing_geo} —— 应用启动时会 exit(0)（起来 1 秒就没）。\n'
            '      先跑 `dart run setup.dart assets --force` 恢复 assets/data/，再重新构建；\n'
            '      若 assets/data/ 里有 .gz 却没有原文件，本脚本下次运行会自动从 build/geo-src 恢复。',
            flush=True,
        )
        ok = False
    if check_icon_shake and not icons:
        print(
            '错误：release 产物里没有 MaterialIcons-Regular.otf —— 应用大量使用 Icons.*，\n'
            '      字体缺失会让所有图标变成方框/空白。',
            flush=True,
        )
        ok = False
    elif check_icon_shake and icon_size > 400 * 1024:
        print(
            f'错误：MaterialIcons-Regular.otf 有 {icon_size}B，说明图标字体没被 tree-shake'
            '（正常约 29KB）——\n'
            '      通常是 TREE_SHAKE_ICONS 丢了，和白包 1.5MB 一起出现于「二次打包」场景。',
            flush=True,
        )
        ok = False
    return ok


parser = argparse.ArgumentParser(description='构建 Bettbox 鸿蒙 HAP')
parser.add_argument('--native-only', action='store_true', help='仅编译原生核心库 (Go + Rust)')
parser.add_argument('--clean', action='store_true', help='清理鸿蒙临时覆盖与构建缓存')
parser.add_argument('--debug', action='store_true', help='构建 Debug 版本的 HAP')
parser.add_argument('--sign', action='store_true',
                    help='用 ohos/build-profile.json5 里已配置的签名材料签名（需先有 signingConfigs）')
parser.add_argument(
    '--version-code',
    type=int,
    default=None,
    help='覆盖 AppScope/app.json5 里的 versionCode（测试包用，便于区分是否真的装上；构建后还原）',
)
parser.add_argument(
    '--app-env',
    default=None,
    help='APP_ENV dart-define（stable = 正式版，无右上角角标）；release 默认 stable，debug 默认不设置',
)
options = parser.parse_args()

overrides_file = root / 'pubspec_overrides.yaml'
template_overrides = root / 'ohos' / 'pubspec_overrides.yaml'

if options.clean:
    if overrides_file.is_file():
        overrides_file.unlink()
        print('已移除 pubspec_overrides.yaml。', flush=True)
    subprocess.run(['cargo', 'clean'], cwd=root / 'plugins' / 'code_forge' / 'rust')
    print('已清理完成。', flush=True)
    raise SystemExit(0)

# 1. 编译原生核心 (Go libmeta.so + Rust libcode_forge.so)
subprocess.run([sys.executable, str(root / 'scripts' / 'build_native.py')], check=True)
if options.native_only:
    print('原生核心编译完成 (--native-only)。', flush=True)
    raise SystemExit(0)

# 2. 检查 Flutter OHOS 工具链
flutter = shutil.which('flutter')
if not flutter or 'flutter_ohos' not in flutter:
    # 可用 FLUTTER_OHOS_BIN 指定；否则按 ~/tools/flutter_ohos 约定推导
    candidate = Path(os.environ.get('FLUTTER_OHOS_BIN', '')) if os.environ.get('FLUTTER_OHOS_BIN') \
        else Path.home() / 'tools' / 'flutter_ohos' / 'bin' / 'flutter'
    if candidate.is_file():
        flutter = str(candidate)
    else:
        raise SystemExit(
            '未找到 OpenHarmony Flutter：请把 flutter_ohos 放到 ~/tools/flutter_ohos，'
            '或用环境变量 FLUTTER_OHOS_BIN 指定其 bin/flutter 路径。'
        )

print(f'使用 Flutter 工具链：{flutter}', flush=True)

# 3. 注入依赖覆盖
if template_overrides.is_file():
    shutil.copy2(template_overrides, overrides_file)
    print('已应用 ohos/pubspec_overrides.yaml', flush=True)

# 3.5 Debug 包注入 extensionProcessMode: runWithMainProcess
#
# 真机实测（HarmonyOS 7.0.0 / API 26）：
#  · debug 包：该字段生效，VPN 扩展与 Flutter/Go 主进程同进程 ⇒ unix socket 传 TUN fd 成功、代理可用；
#  · release 包：系统强制执行独立隔离进程（SELinux 域 vpn_isolate_hap），扩展 connect 主进程
#    的 socket 返回 EACCES(-13) ⇒ fd 交接失败。
# 因此仅在 debug 构建里注入，保证 debug 包可用；release 的数据面需要改成在扩展进程内中继。
module_json = root / 'ohos' / 'entry' / 'src' / 'main' / 'module.json5'
module_json_backup = None
if options.debug and module_json.is_file():
    original = module_json.read_text(encoding='utf-8')
    if '"extensionProcessMode"' not in original:
        patched = original.replace(
            '"type": "vpn",',
            '"type": "vpn",\n        "extensionProcessMode": "runWithMainProcess",',
            1,
        )
        if patched != original:
            module_json_backup = original
            module_json.write_text(patched, encoding='utf-8')
            print('已为 debug 构建注入 extensionProcessMode: runWithMainProcess', flush=True)

app_json = root / 'ohos' / 'AppScope' / 'app.json5'
app_json_backup = None
pubspec_file = root / 'pubspec.yaml'
pubspec_backup = None

try:
    print('=== 正在执行 flutter pub get ===', flush=True)
    subprocess.run([flutter, 'pub', 'get'], cwd=root, check=True)

    sync_app_version()

    # HAP 的 versionCode 实际由 pubspec 的构建号驱动（flutter 工具注入），
    # 因此测试/覆盖安装需要临时提升 pubspec 的 +N，构建后还原。
    if options.version_code is not None and pubspec_file.is_file():
        pubspec_backup = pubspec_file.read_text(encoding='utf-8')
        bumped = re.sub(r'(^version:\s*[\d.]+)\+\d+',
                        lambda m: f"{m.group(1)}+{options.version_code}", pubspec_backup,
                        count=1, flags=re.M)
        if bumped != pubspec_backup:
            pubspec_file.write_text(bumped, encoding='utf-8')
            sync_app_version()          # 同步到 AppScope/app.json5
            print(f'已临时提升构建号 -> versionCode = {options.version_code}', flush=True)
        else:
            pubspec_backup = None

    build_mode = 'debug' if options.debug else 'release'
    codesign_args = [] if options.sign else ['--no-codesign']
    if options.sign:
        # 签名材料由 ohos/build-profile.json5 的 signingConfigs 提供（DevEco 自动签名，或
        # `devecocli signature generate` 生成后写入）；缺了就直接报错，
        # 免得出一个「以为签好了其实没签」的包。
        profile_file = root / 'ohos' / 'build-profile.json5'
        profile_text = profile_file.read_text(encoding='utf-8') if profile_file.is_file() else ''
        if re.search(r'signingConfigs\s*:\s*\[\s*\]', profile_text) or 'signingConfigs' not in profile_text:
            raise SystemExit(
                '--sign 需要 ohos/build-profile.json5 里已有 signingConfigs。\n'
                '请先用 DevEco Studio 的自动签名，或 `devecocli signature generate --product default` '
                '生成签名材料并写入该文件的 signingConfigs 后再构建。'
            )
    # APP_ENV 与上游 CI 约定一致：stable = 正式版，isPre=false
    # （不显示右上角 DEBUG/PRE 角标，且启用更新提示）；debug 包默认保留角标便于区分测试包
    app_env = options.app_env
    if app_env is None:
        app_env = None if options.debug else 'stable'
    define_args = [f'--dart-define=APP_ENV={app_env}'] if app_env else []
    print(f'=== 正在构建鸿蒙 HAP ({build_mode}{"  APP_ENV=" + app_env if app_env else ""}) ===', flush=True)
    build_started_at = time.time()
    reports_before = hvigor_report_snapshot()
    geo_backup_dir = root / 'build' / 'geo-src'
    geo_backup_dir.mkdir(parents=True, exist_ok=True)
    geo_moved = archive_geo_assets(geo_backup_dir)
    try:
        subprocess.run(
            [flutter, 'build', 'hap', f'--{build_mode}', *codesign_args, *define_args],
            cwd=root,
            check=True,
        )
    finally:
        restore_geo_assets(geo_moved)
    if app_env and not verify_dart_defines(app_env, build_started_at, reports_before):
        raise SystemExit(2)
    if not verify_package(build_started_at, check_icon_shake=build_mode == 'release'):
        raise SystemExit(3)
    print('=== 鸿蒙 HAP 构建成功！ ===', flush=True)
finally:
    if overrides_file.is_file():
        overrides_file.unlink()
        print('已还原 pubspec_overrides.yaml', flush=True)
    if pubspec_backup is not None and pubspec_file.is_file():
        pubspec_file.write_text(pubspec_backup, encoding='utf-8')
        sync_app_version()
        print('已还原 pubspec.yaml 构建号', flush=True)
    if app_json_backup is not None and app_json.is_file():
        app_json.write_text(app_json_backup, encoding='utf-8')
        print('已还原 app.json5', flush=True)
    if module_json_backup is not None and module_json.is_file():
        module_json.write_text(module_json_backup, encoding='utf-8')
        print('已还原 module.json5', flush=True)
