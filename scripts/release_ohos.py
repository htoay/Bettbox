#!/usr/bin/env python3
"""生成鸿蒙移植版的对外交付件（命名规则与检查项见 docs/release_process_ohos.md）。

做四件事：
  1. 校验构建产物（AOT 在不在、geo 资源全不全、图标字体是否已裁剪、版本号是否一致）；
  2. **发布安全扫描**：产物里若含签名 Profile（developer-id / device-ids / debug 标记）直接拒绝
     —— 签过名的 HAP 会泄漏签名者的开发者 ID 与设备 UDID 列表，对外只能发 unsigned；
  3. 按命名规则落盘：`bettbox-<version>-ohos-vc<versionCode>-<build>.hap` + 同名 `.sha256`；
  4. 用 `.github/release_template_ohos.md` 渲染 release note 草稿（已存在同名文件时不覆盖，
     改为生成 `*.generated.md`，避免冲掉人工润色过的正文）。

用法：
    python3 scripts/release_ohos.py                  # 默认取最新构建的 unsigned HAP
    python3 scripts/release_ohos.py --hap <路径>      # 指定 HAP
    python3 scripts/release_ohos.py --allow-signed   # 允许已签名包（仅本机自用）
"""

import argparse
import hashlib
import json
import re
import shutil
import subprocess
import sys
import zipfile
from pathlib import Path

root = Path(__file__).resolve().parents[1]

HAP_DIR = Path('ohos/entry/build/default/outputs/default')
DEFAULT_HAP = HAP_DIR / 'entry-default-unsigned.hap'
SIGNED_HAP = HAP_DIR / 'entry-default-signed.hap'
OUT_DIR = Path('build/ohos/hap')
TEMPLATE = Path('.github/release_template_ohos.md')
GEO_FILES = ('geoip.metadb', 'GeoSite.dat', 'ASN.mmdb')
SIGNATURE_MARKERS = {
    '开发者 ID': b'developer-id',
    '设备 UDID 列表': b'device-ids',
    'debug Profile': b'"type":"debug"',
    '调试证书': b'development-certificate',
}

parser = argparse.ArgumentParser(description='生成 Bettbox 鸿蒙版对外交付件')
parser.add_argument('--hap', type=Path, default=None, help=f'待发布的 HAP（默认 {DEFAULT_HAP}）')
parser.add_argument('--out', type=Path, default=OUT_DIR, help=f'输出目录（默认 {OUT_DIR}）')
parser.add_argument('--release-commit', default=None, help='写入 note 的发布提交（默认取 ohos-port-clean）')
parser.add_argument('--upstream-commit', default=None, help='写入 note 的上游提交（默认取 main）')
parser.add_argument('--prev-version', default=None, help='写入 note 的上一版版本号（默认按标签推断）')
parser.add_argument('--allow-signed', action='store_true', help='允许已签名包（仅本机自用；对外禁止）')
parser.add_argument('--no-note', action='store_true', help='不渲染 release note')
options = parser.parse_args()


def git(*args: str, default: str = '') -> str:
    try:
        out = subprocess.run(['git', *args], cwd=root, capture_output=True, text=True, check=True)
        return out.stdout.strip()
    except Exception:
        return default


def read_version() -> tuple[str, str]:
    """从 pubspec.yaml 读 version/versionCode，并与 ohos/AppScope/app.json5 交叉核对。"""
    text = (root / 'pubspec.yaml').read_text(encoding='utf-8')
    match = re.search(r'^version:\s*([0-9]+\.[0-9]+\.[0-9]+)\+([0-9]+)', text, re.M)
    if not match:
        raise SystemExit('pubspec.yaml 里找不到 version: x.y.z+<构建号>')
    version, code = match.group(1), match.group(2)
    app_json = root / 'ohos' / 'AppScope' / 'app.json5'
    if app_json.is_file():
        app = app_json.read_text(encoding='utf-8')
        name = re.search(r'"versionName"\s*:\s*"([^"]*)"', app)
        ver = re.search(r'"versionCode"\s*:\s*(\d+)', app)
        if name and name.group(1) != version:
            print(f'警告：app.json5 的 versionName={name.group(1)} 与 pubspec 的 {version} 不一致', flush=True)
        if ver and ver.group(1) != code:
            print(f'警告：app.json5 的 versionCode={ver.group(1)} 与 pubspec 的 {code} 不一致', flush=True)
    return version, code


def verify_hap(hap: Path, version: str, code: str, allow_signed: bool) -> bool:
    ok = True
    raw = hap.read_bytes()
    with zipfile.ZipFile(hap) as archive:
        names = archive.namelist()
        app_so = [n for n in names if n.endswith('libapp.so')]
        kernel = [n for n in names if 'kernel_blob' in n]
        icons = [n for n in names if n.endswith('MaterialIcons-Regular.otf')]
        icon_size = archive.getinfo(icons[0]).file_size if icons else 0
        missing_geo = [
            name for name in GEO_FILES
            if not any(n.endswith(f'assets/data/{name}') or n.endswith(f'assets/data/{name}.gz') for n in names)
        ]
        module = json.loads(archive.read('module.json').decode()) if 'module.json' in names else {}

    print(f'产物：{hap.name}  {len(raw) / 1048576:.1f} MiB  条目 {len(names)}')
    print(f'  libapp.so={len(app_so)}  kernel_blob={len(kernel)}  MaterialIcons={icon_size} B  '
          f'geo 缺失={missing_geo or "无"}')

    if not app_so or kernel:
        print('  ❌ 缺 libapp.so 或含 kernel_blob.bin —— JIT 包，装到设备起来就退', flush=True)
        ok = False
    if missing_geo:
        print(f'  ❌ 缺 geo 资源 {missing_geo} —— 应用启动即退出', flush=True)
        ok = False
    if icons and icon_size > 400 * 1024:
        print(f'  ❌ MaterialIcons 未 tree-shake（{icon_size} B，正常约 29 KB）', flush=True)
        ok = False
    if not icons:
        print('  ⚠️ 未找到 MaterialIcons-Regular.otf（若为 release 包应视为异常）', flush=True)

    app_meta = (module or {}).get('app', {})
    if app_meta:
        got_name, got_code = app_meta.get('versionName'), str(app_meta.get('versionCode', ''))
        print(f'  包内版本：versionName={got_name}  versionCode={got_code}')
        if got_name != version or got_code != code:
            print(f'  ❌ 包内版本与 pubspec（{version} / {code}）不一致', flush=True)
            ok = False

    leaked = [label for label, marker in SIGNATURE_MARKERS.items() if marker in raw]
    if leaked:
        if allow_signed:
            print(f'  ⚠️ 产物含签名信息（{", ".join(leaked)}）—— 已按 --allow-signed 放行，切勿对外发布', flush=True)
        else:
            print(f'  ❌ 产物含签名 Profile（{", ".join(leaked)}）：会泄漏开发者 ID 与设备 UDID 列表，'
                  f'对外只能发 unsigned 包（本机自用可加 --allow-signed）', flush=True)
            ok = False
    else:
        print('  ✅ 未含签名 Profile（可对外发布）')
    return ok


def prev_version(current: str) -> str:
    tags = [t for t in git('tag', '-l', 'ohos-v*').splitlines() if t.strip()]
    versions = sorted(
        (t[len('ohos-v'):] for t in tags if re.fullmatch(r'ohos-v[0-9.]+', t)),
        key=lambda v: [int(x) for x in v.split('.')],
    )
    older = [v for v in versions if [int(x) for x in v.split('.')] < [int(x) for x in current.split('.')]]
    return older[-1] if older else current


def render_note(path: Path, values: dict[str, str]) -> None:
    template = (root / TEMPLATE).read_text(encoding='utf-8')
    body = re.sub(r'<!--.*?-->\n?', '', template, flags=re.S)   # 去掉给维护者看的注释
    for key, value in values.items():
        body = body.replace(key, value)
    path.write_text(body.rstrip() + '\n', encoding='utf-8')


def main() -> int:
    version, code = read_version()
    kind = 'signed' if options.allow_signed else 'unsigned'
    hap = options.hap or (SIGNED_HAP if kind == 'signed' else DEFAULT_HAP)
    hap = (root / hap) if not hap.is_absolute() else hap
    if not hap.is_file():
        raise SystemExit(f'找不到 HAP：{hap}（先跑 scripts/build_ohos.py --sign）')

    if hap.name.endswith('-signed.hap') and not options.allow_signed:
        print(f'提示：检测到已签名产物 {hap.name}，改用未签名产物校验（对外只发 unsigned）', flush=True)
        unsigned = root / DEFAULT_HAP
        if unsigned.is_file():
            hap = unsigned

    print(f'=== 校验与打包 v{version}（versionCode {code}）===')
    if not verify_hap(hap, version, code, options.allow_signed):
        raise SystemExit('产物校验未通过，已终止（见上面 ❌ 项）')

    name = f'bettbox-{version}-ohos-vc{code}-{kind}.hap'
    out_dir = (root / options.out) if not options.out.is_absolute() else options.out
    out_dir.mkdir(parents=True, exist_ok=True)
    target = out_dir / name
    shutil.copyfile(hap, target)
    digest = hashlib.sha256(target.read_bytes()).hexdigest()
    (out_dir / f'{name}.sha256').write_text(f'{digest}  {name}\n', encoding='utf-8')

    print('\n=== 交付件 ===')
    print(f'  {target}  ({target.stat().st_size} B)')
    print(f'  {out_dir / (name + ".sha256")}')
    print(f'  SHA-256: {digest}')

    if not options.no_note:
        values = {
            'PREV_VERSION': options.prev_version or prev_version(version),
            # note 里引用的应是**该版本标签指向的发布提交**：优先取 tag，其次快照分支，最后 HEAD
            'RELEASE_COMMIT': options.release_commit or git('rev-parse', '--short', f'ohos-v{version}^{{commit}}', default='')
            or git('rev-parse', '--short', 'ohos-port-clean', default=git('rev-parse', '--short', 'HEAD')),
            'UPSTREAM_VERSION': version,
            'UPSTREAM_COMMIT': options.upstream_commit or git('rev-parse', '--short', 'main'),
            'VERSION_CODE': code,
            'HAP_SIZE': f'{target.stat().st_size / 1048576:.1f}',
            'SHA256': digest,
            'HAP_NAME': name,
            'VERSION': version,
        }
        note = out_dir / f'release-note-ohos-v{version}.md'
        if note.is_file():
            note = out_dir / f'release-note-ohos-v{version}.generated.md'
            print(f'  （已存在人工润色的 note，草稿改写到 {note.name}）')
        render_note(note, values)
        print(f'  {note}')
        print('\n提示：note 里「功能一览」的 🆕 标记与「本次更新」三节需要按本版内容人工确认。')

    print('\n下一步：GitHub 新建 Release → tag 选 ohos-v' + version +
          '，粘贴上面的 note，上传 HAP 与 .sha256 两个文件。')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
