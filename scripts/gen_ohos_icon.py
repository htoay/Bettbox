#!/usr/bin/env python3
"""从 Android 自适应图标矢量源生成鸿蒙图标资源（可重复执行，幂等）。

上游把应用图标的**唯一矢量源**放在 Android 的自适应图标里：

    android/app/src/main/res/drawable/ic_launcher_background_dark.xml   # 纯色背景 #292C41
    android/app/src/main/res/drawable/ic_launcher_foreground_dark.xml   # 三根白色斜条 logo

本脚本把这两份矢量数据转成 SVG（`<vector>` 与 SVG 的差异只有属性名与 group 变换写法），
用 rsvg-convert 高分辨率栅格化后再降采样（保证边缘抗锯齿），最后生成鸿蒙侧资源：

    ohos/AppScope/resources/base/media/     app_icon.png（单层兜底，216²）
                                            app_foreground.png / app_background.png（分层）
                                            app_layered_image.json
    ohos/entry/src/main/resources/base/media/  icon.png（单层兜底，216²）
                                               foreground.png / background.png（分层）
                                               layered_image.json
                                               icon_startwindow.png（启动页图标，透明底深色 logo）

规范依据（华为官方《应用图标》《配置应用图标和名称》《应用图标配置与开发》）：
  · 图标资源必须为**分层资源**、尺寸 1024×1024px、正方形、**无需圆角**
    （系统按场景自动生成遮罩裁切）、PNG；背景图**不允许含透明像素**。
  · 前景元素不宜过于靠近背景四角，以免被圆角裁切；图形元素应占据较大比例。
    故本脚本先渲染一次量出 logo 实际占比，再按 `ARTWORK_SPAN` 缩放居中。
  · 单层图标：可解码为 PixelMap 的图片，同样不允许自行裁剪圆角、不允许加内间距，
    保留一份作为 `startWindowIcon` 之外的兜底（部分系统场景仍取单层图）。
  · AppScope 与 entry 下同名资源会互相覆盖（AppScope 覆盖 entry），
    因此两侧刻意用不同文件名（app_* / 不带前缀）。
"""

import re
import subprocess
import sys
import tempfile
from pathlib import Path

from PIL import Image

root = Path(__file__).resolve().parents[1]
android_drawable = root / 'android' / 'app' / 'src' / 'main' / 'res' / 'drawable'
background_xml = android_drawable / 'ic_launcher_background_dark.xml'
foreground_xml = android_drawable / 'ic_launcher_foreground_dark.xml'

app_media = root / 'ohos' / 'AppScope' / 'resources' / 'base' / 'media'
entry_media = root / 'ohos' / 'entry' / 'src' / 'main' / 'resources' / 'base' / 'media'

# 栅格化分辨率：108 视口 × 10，降采样到目标尺寸时抗锯齿最干净
SUPERSAMPLE = 1080
ICON_SIZE = 1024         # 官方要求：图标资源尺寸必须为 1024×1024px
LAYER_SIZE = 1024        # 分层图标前景/背景同上
SPLASH_SIZE = 512        # 启动页图标（实际显示尺寸很小，512 足够）
# 前景 logo 占画布的比例：太小显得图标空、太大容易被圆角/遮罩切到四角
ARTWORK_SPAN = 0.60
BRAND_COLOR = '#292C41'  # 与 Android 自适应图标背景一致


def _attr(tag: str, name: str) -> str | None:
    match = re.search(rf'android:{name}\s*=\s*"([^"]*)"', tag)
    return match.group(1) if match else None


def _parse_group(xml_text: str) -> str:
    """把 <group> 的 translate/scale 转成 SVG transform。"""
    match = re.search(r'<group\b([^>]*)>', xml_text, re.S)
    if not match:
        return ''
    tag = match.group(1)
    tx = float(_attr(tag, 'translateX') or 0)
    ty = float(_attr(tag, 'translateY') or 0)
    sx = float(_attr(tag, 'scaleX') or 1)
    sy = float(_attr(tag, 'scaleY') or 1)
    parts = []
    if tx or ty:
        parts.append(f'translate({tx},{ty})')
    if sx != 1 or sy != 1:
        parts.append(f'scale({sx},{sy})')
    return ' '.join(parts)


def vector_to_svg(
    xml_text: str,
    size: int,
    override_fill: str | None = None,
    outer_scale: float = 1.0,
) -> str:
    viewport_w = float(_attr(xml_text, 'viewportWidth') or 108)
    viewport_h = float(_attr(xml_text, 'viewportHeight') or 108)
    transform = _parse_group(xml_text)
    paths = []
    for match in re.finditer(r'<path\b([^>]*?)/>', xml_text, re.S):
        tag = match.group(1)
        fill = override_fill or _attr(tag, 'fillColor') or '#000000'
        data = _attr(tag, 'pathData') or ''
        if not data:
            continue
        paths.append(f'<path fill="{fill}" d="{data}"/>')
    body = '\n      '.join(paths)
    group_open = f'<g transform="{transform}">' if transform else '<g>'
    # 以视口中心为原点缩放，保证 logo 始终居中
    cx, cy = viewport_w / 2, viewport_h / 2
    outer = (
        f'<g transform="translate({cx},{cy}) scale({outer_scale}) translate({-cx},{-cy})">'
        if outer_scale != 1.0 else '<g>'
    )
    return (
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{size}" height="{size}" '
        f'viewBox="0 0 {viewport_w:g} {viewport_h:g}">\n'
        f'  {outer}\n    {group_open}\n      {body}\n    </g>\n  </g>\n</svg>\n'
    )


def artwork_span(image: Image.Image) -> float:
    """前景 logo 的可见包围盒相对画布的占比（取 x/y 中较大者）。"""
    bbox = image.getchannel('A').getbbox()
    if bbox is None:
        return 0.0
    return max((bbox[2] - bbox[0]) / image.width, (bbox[3] - bbox[1]) / image.height)


def rasterize(svg_text: str, size: int, tmpdir: Path, name: str) -> Image.Image:
    svg_path = tmpdir / f'{name}.svg'
    png_path = tmpdir / f'{name}.png'
    svg_path.write_text(svg_text, encoding='utf-8')
    subprocess.run(
        ['rsvg-convert', '-w', str(size), '-h', str(size), '-o', str(png_path), str(svg_path)],
        check=True,
    )
    return Image.open(png_path).convert('RGBA')


def solid(size: int, color: str) -> Image.Image:
    return Image.new('RGBA', (size, size), color)


def main() -> int:
    for path in (background_xml, foreground_xml):
        if not path.is_file():
            print(f'缺少矢量源：{path}', file=sys.stderr)
            return 1
    try:
        subprocess.run(['rsvg-convert', '--version'], check=True,
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except (OSError, subprocess.CalledProcessError):
        print('需要 rsvg-convert（librsvg2-bin）来栅格化矢量源。', file=sys.stderr)
        return 1

    foreground_xml_text = foreground_xml.read_text(encoding='utf-8')
    background_svg = vector_to_svg(background_xml.read_text(encoding='utf-8'), SUPERSAMPLE)

    with tempfile.TemporaryDirectory() as tmp:
        tmpdir = Path(tmp)
        background = rasterize(background_svg, SUPERSAMPLE, tmpdir, 'background')

        # 第一遍：按原始矢量比例渲染，量出 logo 实际占比，再换算到 ARTWORK_SPAN
        probe = rasterize(
            vector_to_svg(foreground_xml_text, SUPERSAMPLE), SUPERSAMPLE, tmpdir, 'probe')
        measured = artwork_span(probe)
        if measured <= 0:
            print('前景矢量没有可见图形，检查 Android 矢量源。', file=sys.stderr)
            return 1
        scale = ARTWORK_SPAN / measured
        print(f'logo 原始占比 {measured:.3f} → 目标 {ARTWORK_SPAN:.2f}（缩放 ×{scale:.3f}）')

        foreground = rasterize(
            vector_to_svg(foreground_xml_text, SUPERSAMPLE, outer_scale=scale),
            SUPERSAMPLE, tmpdir, 'foreground')
        # 启动页背景是浅色，白色 logo 会看不见 —— 同一矢量换成品牌深色
        foreground_dark = rasterize(
            vector_to_svg(foreground_xml_text, SUPERSAMPLE, override_fill=BRAND_COLOR,
                          outer_scale=scale),
            SUPERSAMPLE, tmpdir, 'foreground_dark')

        full_bleed = Image.alpha_composite(background, foreground)

        app_media.mkdir(parents=True, exist_ok=True)
        entry_media.mkdir(parents=True, exist_ok=True)

        # 单层图标（满幅正方形：无圆角、无内间距，遮罩交给系统）
        full_bleed.resize((ICON_SIZE, ICON_SIZE), Image.LANCZOS) \
            .convert('RGB').save(app_media / 'app_icon.png')
        full_bleed.resize((ICON_SIZE, ICON_SIZE), Image.LANCZOS) \
            .convert('RGB').save(entry_media / 'icon.png')

        # 分层图标：前景透明 PNG + 背景纯色（不含透明像素）
        foreground.resize((LAYER_SIZE, LAYER_SIZE), Image.LANCZOS) \
            .save(app_media / 'app_foreground.png')
        foreground.resize((LAYER_SIZE, LAYER_SIZE), Image.LANCZOS) \
            .save(entry_media / 'foreground.png')
        solid(LAYER_SIZE, BRAND_COLOR).convert('RGB').save(app_media / 'app_background.png')
        solid(LAYER_SIZE, BRAND_COLOR).convert('RGB').save(entry_media / 'background.png')

        # 启动页图标：透明底 + 深色 logo（配 startWindowBackground 浅色）
        foreground_dark.resize((SPLASH_SIZE, SPLASH_SIZE), Image.LANCZOS) \
            .save(entry_media / 'icon_startwindow.png')

        for label, image in (('分层前景', foreground), ('单层图标', full_bleed)):
            print(f'  校验 {label}：logo 占比 {artwork_span(image):.3f}')

    layered = (
        '{\n'
        '  "layered-image":\n'
        '  {\n'
        '    "background": "$media:%s",\n'
        '    "foreground": "$media:%s"\n'
        '  }\n'
        '}\n'
    )
    (app_media / 'app_layered_image.json').write_text(
        layered % ('app_background', 'app_foreground'), encoding='utf-8')
    (entry_media / 'layered_image.json').write_text(
        layered % ('background', 'foreground'), encoding='utf-8')

    print('已生成鸿蒙图标资源：')
    for path in sorted(list(app_media.iterdir()) + list(entry_media.iterdir())):
        if path.is_file():
            print(f'  {path.relative_to(root)}  {path.stat().st_size} B')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
