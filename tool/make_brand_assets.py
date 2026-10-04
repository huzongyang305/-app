# 生成 App 品牌资源（启动图标与启动页标记）。
#
# 用法（开发期，需要 Pillow + numpy）：
#   python tool/make_brand_assets.py
#
# 产物：
#   android/app/src/main/res/mipmap-*/ic_launcher.png        传统启动图标（圆角方形）
#   android/app/src/main/res/mipmap-*/ic_launcher_round.png  圆形启动图标
#   android/app/src/main/res/drawable-*/splash_mark.png      启动页的白色标记
#   store/icon_512.png                                       应用商店用大图
#
# 自适应图标（API 26+）的前景与背景是矢量绘制，见
#   res/drawable/ic_launcher_foreground.xml
#   res/drawable/ic_launcher_background.xml
# 两处几何参数与本脚本保持一致：mark_scale=0.76、dy=0.028。
from __future__ import annotations

from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

# 品牌色：与 lib/theme/app_theme.dart 的签名渐变保持一致。
BRAND_TOP = (0x6C, 0x8F, 0xF8)
BRAND_BOTTOM = (0x41, 0x66, 0xD9)

SUPERSAMPLE = 4
MARK_SCALE = 0.76
MARK_DY = 0.028
STROKE_RATIO = 0.115

# Android 密度桶：目录名 -> 图标边长（px）
ICON_DENSITIES = {
    'mdpi': 48,
    'hdpi': 72,
    'xhdpi': 96,
    'xxhdpi': 144,
    'xxxhdpi': 192,
}

# 启动页标记：统一按 96dp 呈现
SPLASH_DENSITIES = {
    'mdpi': 96,
    'hdpi': 144,
    'xhdpi': 192,
    'xxhdpi': 288,
    'xxxhdpi': 384,
}


def brand_gradient(size: int) -> Image.Image:
    '''135 度线性渐变（左上 -> 右下）。'''
    axis = np.arange(size, dtype=np.float32)
    t = (axis[:, None] + axis[None, :]) / (2 * (size - 1))
    top = np.array(BRAND_TOP, dtype=np.float32)
    bottom = np.array(BRAND_BOTTOM, dtype=np.float32)
    rgb = top * (1 - t)[..., None] + bottom * t[..., None]
    return Image.fromarray(rgb.round().astype(np.uint8), 'RGB').convert('RGBA')


def rounded_square_mask(size: int, radius_ratio: float = 0.22) -> Image.Image:
    mask = Image.new('L', (size, size), 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        (0, 0, size - 1, size - 1),
        radius=int(size * radius_ratio),
        fill=255,
    )
    return mask


def circle_mask(size: int) -> Image.Image:
    mask = Image.new('L', (size, size), 0)
    ImageDraw.Draw(mask).ellipse((0, 0, size - 1, size - 1), fill=255)
    return mask


def draw_code_mark(
    size: int,
    color: tuple[int, int, int, int],
    scale: float = MARK_SCALE,
    dy: float = MARK_DY,
) -> Image.Image:
    '''绘制代码尖括号标记，4 倍超采样后缩小，边缘更平滑。'''
    canvas = size * SUPERSAMPLE
    layer = Image.new('RGBA', (canvas, canvas), (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)

    box = canvas * scale
    cx = canvas / 2
    cy = canvas / 2 + canvas * dy
    stroke = box * STROKE_RATIO
    radius = stroke / 2

    def point(nx: float, ny: float) -> tuple[float, float]:
        return (cx + nx * box, cy + ny * box)

    def stroke_path(points: list[tuple[float, float]]) -> None:
        draw.line(points, fill=color, width=round(stroke), joint='curve')
        # Pillow 的 line 没有圆头，端点补圆点即可得到圆角端点与拐角。
        for x, y in points:
            draw.ellipse((x - radius, y - radius, x + radius, y + radius), fill=color)

    # 左尖括号 <
    stroke_path([point(-0.16, -0.30), point(-0.34, -0.06), point(-0.16, 0.18)])
    # 中间的斜杠 /
    stroke_path([point(0.10, -0.32), point(-0.10, 0.20)])
    # 右尖括号 >
    stroke_path([point(0.16, -0.30), point(0.34, -0.06), point(0.16, 0.18)])

    return layer.resize((size, size), Image.LANCZOS)


def launcher_icon(size: int, mask: Image.Image) -> Image.Image:
    base = brand_gradient(size)
    base.putalpha(mask)
    base.alpha_composite(draw_code_mark(size, (255, 255, 255, 255)))
    return base


def save(image: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path, 'PNG', optimize=True)
    print(f'生成 {path}  ({path.stat().st_size / 1024:.1f} KB)')


def main() -> None:
    root = Path(__file__).resolve().parent.parent
    res = root / 'android' / 'app' / 'src' / 'main' / 'res'

    for density, size in ICON_DENSITIES.items():
        save(
            launcher_icon(size, rounded_square_mask(size)),
            res / f'mipmap-{density}' / 'ic_launcher.png',
        )
        save(
            launcher_icon(size, circle_mask(size)),
            res / f'mipmap-{density}' / 'ic_launcher_round.png',
        )

    for density, size in SPLASH_DENSITIES.items():
        # 启动页只需要白色标记本身，背景由 drawable 决定。
        mark = draw_code_mark(size, (255, 255, 255, 255), scale=0.62, dy=0.02)
        save(mark, res / f'drawable-{density}' / 'splash_mark.png')

    save(launcher_icon(512, rounded_square_mask(512)), root / 'store' / 'icon_512.png')


if __name__ == '__main__':
    main()