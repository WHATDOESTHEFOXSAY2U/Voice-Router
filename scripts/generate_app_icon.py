from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter


SIZE = 1024
ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "VoiceRouter" / "Resources" / "Assets.xcassets" / "AppIcon.appiconset" / "AppIcon-1024.png"


def blend(a: tuple[int, int, int], b: tuple[int, int, int], t: float) -> tuple[int, int, int]:
    return tuple(int(a[i] * (1 - t) + b[i] * t) for i in range(3))


def make_background() -> Image.Image:
    top = (7, 12, 24)
    mid = (18, 34, 61)
    bottom = (4, 7, 14)

    image = Image.new("RGBA", (SIZE, SIZE))
    pixels = image.load()

    for y in range(SIZE):
        for x in range(SIZE):
            tx = x / (SIZE - 1)
            ty = y / (SIZE - 1)
            diagonal = min(max((tx * 0.58) + (ty * 0.72), 0.0), 1.0)

            if diagonal < 0.52:
                color = blend(top, mid, diagonal / 0.52)
            else:
                color = blend(mid, bottom, (diagonal - 0.52) / 0.48)

            pixels[x, y] = (*color, 255)

    return image


def add_blurred_circle(base: Image.Image, center: tuple[int, int], diameter: int, color: tuple[int, int, int], alpha: int, blur: int) -> None:
    layer = Image.new("RGBA", base.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    x, y = center
    r = diameter // 2
    draw.ellipse((x - r, y - r, x + r, y + r), fill=(*color, alpha))
    layer = layer.filter(ImageFilter.GaussianBlur(blur))
    base.alpha_composite(layer)


def draw_sheet(size: tuple[int, int], tint: tuple[int, int, int], highlight: tuple[int, int, int]) -> Image.Image:
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    w, h = size

    draw.rounded_rectangle((0, 0, w, h), radius=int(w * 0.12), fill=(*tint, 255))
    draw.rounded_rectangle((0, 0, w, h), radius=int(w * 0.12), outline=(255, 255, 255, 36), width=2)

    fold = Image.new("RGBA", size, (0, 0, 0, 0))
    fold_draw = ImageDraw.Draw(fold)
    fold_draw.polygon(
        [
            (w * 0.74, 0),
            (w, 0),
            (w, h * 0.22),
        ],
        fill=(255, 255, 255, 120),
    )
    image.alpha_composite(fold)

    for idx, offset in enumerate([0.22, 0.34, 0.46]):
        y = int(h * offset)
        left = int(w * 0.18)
        right = int(w * 0.72)
        line_color = highlight if idx == 0 else (178, 182, 190)
        draw.rounded_rectangle((left, y, right, y + 16), radius=8, fill=(*line_color, 255))

    return image


def draw_capsule(size: tuple[int, int]) -> Image.Image:
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    w, h = size

    draw.rounded_rectangle(
        (0, 0, w, h),
        radius=h // 2,
        fill=(14, 18, 30, 255),
        outline=(255, 255, 255, 20),
        width=2,
    )
    draw.rounded_rectangle(
        (8, 8, w - 8, h - 8),
        radius=(h - 16) // 2,
        outline=(93, 214, 243, 16),
        width=2,
    )

    return image


def add_shadow(base: Image.Image, shape: Image.Image, offset: tuple[int, int], blur: int, alpha: int) -> None:
    shadow = Image.new("RGBA", base.size, (0, 0, 0, 0))
    shadow.alpha_composite(shape, offset)
    a = shadow.split()[-1]
    a = a.point(lambda value: min(value, alpha))
    shadow.putalpha(a)
    shadow = shadow.filter(ImageFilter.GaussianBlur(blur))
    base.alpha_composite(shadow)


def add_wave(base: Image.Image, origin: tuple[int, int], size: tuple[int, int]) -> None:
    layer = Image.new("RGBA", base.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    x, y = origin
    w, h = size
    bar_width = int(w * 0.07)
    spacing = int(w * 0.07)
    heights = [0.38, 0.64, 1.0, 0.74, 0.52]
    colors = [
        (94, 222, 245),
        (121, 239, 199),
        (255, 193, 84),
        (121, 239, 199),
        (94, 222, 245),
    ]

    total_width = len(heights) * bar_width + (len(heights) - 1) * spacing
    start_x = x + (w - total_width) // 2

    glow = Image.new("RGBA", base.size, (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow)

    for index, height_factor in enumerate(heights):
        bar_height = int(h * height_factor)
        bx = start_x + index * (bar_width + spacing)
        by = y + (h - bar_height) // 2
        rect = (bx, by, bx + bar_width, by + bar_height)

        glow_draw.rounded_rectangle(rect, radius=bar_width // 2, fill=(*colors[index], 170))
        draw.rounded_rectangle(rect, radius=bar_width // 2, fill=(*colors[index], 255))

    glow = glow.filter(ImageFilter.GaussianBlur(18))
    base.alpha_composite(glow)
    base.alpha_composite(layer)


def add_spark(base: Image.Image, center: tuple[int, int], radius: int, color: tuple[int, int, int]) -> None:
    layer = Image.new("RGBA", base.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    x, y = center

    points = []
    for i in range(8):
        angle = math.pi / 4 * i - math.pi / 2
        distance = radius if i % 2 == 0 else radius * 0.38
        points.append((x + math.cos(angle) * distance, y + math.sin(angle) * distance))

    draw.polygon(points, fill=(*color, 255))
    blur = layer.filter(ImageFilter.GaussianBlur(10))
    base.alpha_composite(blur)
    base.alpha_composite(layer)


def main() -> None:
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)

    icon = make_background()
    add_blurred_circle(icon, center=(760, 230), diameter=360, color=(94, 222, 245), alpha=116, blur=70)
    add_blurred_circle(icon, center=(290, 760), diameter=320, color=(255, 107, 88), alpha=96, blur=80)
    add_blurred_circle(icon, center=(760, 760), diameter=240, color=(255, 193, 84), alpha=84, blur=58)

    back_sheet = draw_sheet((370, 470), tint=(226, 229, 236), highlight=(93, 214, 243))
    front_sheet = draw_sheet((392, 500), tint=(247, 240, 226), highlight=(255, 193, 84))

    capsule = draw_capsule((628, 224))

    add_shadow(icon, back_sheet, offset=(292, 235), blur=26, alpha=120)
    rotated_back = back_sheet.rotate(12, resample=Image.Resampling.BICUBIC, expand=True)
    icon.alpha_composite(rotated_back, (248, 190))

    add_shadow(icon, front_sheet, offset=(268, 212), blur=24, alpha=140)
    rotated_front = front_sheet.rotate(-11, resample=Image.Resampling.BICUBIC, expand=True)
    icon.alpha_composite(rotated_front, (230, 192))

    add_shadow(icon, capsule, offset=(200, 378), blur=28, alpha=150)
    icon.alpha_composite(capsule, (198, 372))

    add_wave(icon, origin=(198, 372), size=(628, 224))
    add_spark(icon, center=(748, 248), radius=34, color=(255, 115, 87))

    vignette = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    vignette_mask = Image.radial_gradient("L").resize((SIZE, SIZE))
    vignette_mask = ImageChops.invert(vignette_mask).point(lambda value: int(value * 0.38))
    vignette.putalpha(vignette_mask)
    icon.alpha_composite(vignette)

    final = Image.new("RGB", (SIZE, SIZE), (7, 12, 24))
    final.paste(icon.convert("RGB"))
    final.save(OUTPUT)
    print(OUTPUT)


if __name__ == "__main__":
    main()
