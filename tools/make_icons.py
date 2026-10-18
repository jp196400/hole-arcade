#!/usr/bin/env python3
"""Original Hole Arcade icons. Geometric mark only: no characters, no trademarks."""
import os
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
NAVY = (28, 41, 73, 255)
INK = (11, 16, 32, 255)
CYAN = (13, 189, 214, 255)
CREAM = (252, 247, 237, 255)
WARM = (242, 166, 74, 255)
LEAF = (72, 168, 104, 255)
FONT = os.path.join(ROOT, "assets", "fonts", "FredokaBold.ttf")


def paint_mark(canvas, cx, cy, radius):
    draw = ImageDraw.Draw(canvas, "RGBA")
    ring = max(4, int(radius * 0.16))
    draw.ellipse((cx - radius, cy - radius, cx + radius, cy + radius), fill=CYAN)
    inner = radius - ring
    draw.ellipse((cx - inner, cy - inner, cx + inner, cy + inner), fill=INK)
    hr = max(3, int(radius * 0.18))
    hx = cx - int(radius * 0.28)
    hy = cy - int(radius * 0.34)
    draw.ellipse((hx, hy, hx + hr, hy + hr), fill=(255, 255, 255, 170))
    # Three snacks, kept close so they sit inside an adaptive-icon safe circle.
    s = radius
    draw.ellipse((cx + int(s * 0.72), cy - int(s * 0.15), cx + int(s * 1.08), cy + int(s * 0.21)), fill=CREAM)
    side = int(s * 0.30)
    x0 = cx - int(s * 1.05)
    y0 = cy + int(s * 0.42)
    draw.rounded_rectangle((x0, y0, x0 + side, y0 + side), radius=max(2, side // 5), fill=WARM)
    d = int(s * 0.22)
    draw.ellipse((cx + int(s * 0.05), cy + int(s * 0.78), cx + int(s * 0.05) + d, cy + int(s * 0.78) + d), fill=LEAF)


def full_icon(size):
    img = Image.new("RGBA", (size, size), NAVY)
    paint_mark(img, size // 2, size // 2, int(size * 0.30))
    return img


def foreground(size):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    # Safe zone is the center 66 percent. Radius stays inside that circle.
    paint_mark(img, size // 2, size // 2, int(size * 0.22))
    return img


def splash(w, h):
    img = Image.new("RGBA", (w, h), NAVY)
    paint_mark(img, w // 2, int(h * 0.40), int(w * 0.28))
    draw = ImageDraw.Draw(img)
    font = ImageFont.truetype(FONT, 72)
    text = "Hole Arcade"
    box = draw.textbbox((0, 0), text, font=font)
    tw = box[2] - box[0]
    draw.text(((w - tw) / 2, int(h * 0.62)), text, font=font, fill=CREAM)
    return img


def save(img, rel):
    path = os.path.join(ROOT, rel)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    if img.mode == "RGBA" and rel.endswith("icon_1024.png") or rel.endswith("icon.png") or rel.endswith("play_512.png") or "icon_" in os.path.basename(rel):
        flat = Image.new("RGB", img.size, NAVY[:3])
        flat.paste(img, mask=img.split()[-1])
        flat.save(path, "PNG")
    else:
        img.save(path, "PNG")
    print(rel, img.size)


def main():
    save(full_icon(1024), "icons/icon.png")
    save(full_icon(1024), "icons/ios/icon_1024.png")
    save(full_icon(512), "icons/android/play_512.png")
    for size in (48, 72, 96, 144, 192):
        save(full_icon(size), "icons/android/icon_%d.png" % size)
    fg = foreground(432)
    fg.save(os.path.join(ROOT, "icons/android/adaptive_foreground.png"), "PNG")
    print("icons/android/adaptive_foreground.png", fg.size)
    bg = Image.new("RGBA", (432, 432), NAVY)
    bg.save(os.path.join(ROOT, "icons/android/adaptive_background.png"), "PNG")
    print("icons/android/adaptive_background.png", bg.size)
    sp = splash(720, 1280)
    flat = Image.new("RGB", sp.size, NAVY[:3])
    flat.paste(sp, mask=sp.split()[-1])
    flat.save(os.path.join(ROOT, "icons/splash.png"), "PNG")
    print("icons/splash.png", flat.size)


if __name__ == "__main__":
    main()
