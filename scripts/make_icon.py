#!/usr/bin/env python3
"""Draws the EzWoW - Data icon.

Outputs docs/images/icon_256.png (project logo), Media/Icon.png (256 x 256) and
Media/Icon.tga (64 x 64, 32-bit, top-left origin) used by the .toc and the windows.
The frame follows the shared EzWoW icon frame; the accent ring uses the addon accent
(0.478, 0.635, 0.969) muted like the other icons. Emblem: a stack of three data disks.

usage: python scripts/make_icon.py .   (needs Pillow)
"""
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

SS = 4                      # supersampling
N = 256 * SS

FRAME = "#344c5b"
PANEL = "#1d2831"
RING = "#c99a4a"            # muted accent (amber)
DARK = "#0b1217"
DOT = "#485e70"
PARCH = "#efe2bf"
PARCH_SHADE = "#d3bd8a"
ROLL = "#c9ad74"
ROLL_HI = "#e6d3a3"
GOLD = "#ffd23f"
GOLD_SHADE = "#e0a91c"


def s(v):
    return round(v * SS)


def box(x0, y0, x1, y1):
    return [s(x0), s(y0), s(x1), s(y1)]


def mask_of(draw_fn):
    m = Image.new("L", (N, N), 0)
    draw_fn(ImageDraw.Draw(m))
    return m


def dilate(mask, width):
    """Round dilation by `width` icon pixels (blur + threshold)."""
    r = width * SS
    blurred = mask.filter(ImageFilter.GaussianBlur(r / 2))
    return blurred.point(lambda v: 255 if v > 8 else 0)


def paint(img, mask, color):
    img.paste(Image.new("RGBA", (N, N), color), (0, 0), mask)


DISK_TOP = "#f2d48a"
DISK_SIDE = "#d4a64a"
DISK_EDGE = "#a8782a"


def disk_shapes(d, fill=255):
    for y in (70, 112, 154):
        d.rounded_rectangle(box(66, y + 12, 190, y + 46), radius=s(8), fill=fill)
        d.ellipse(box(66, y, 190, y + 26), fill=fill)
        d.ellipse(box(66, y + 33, 190, y + 59), fill=fill)


def draw():
    img = Image.new("RGBA", (N, N), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # shared EzWoW frame
    d.rounded_rectangle(box(4, 4, 252, 252), radius=s(60), fill=FRAME)
    d.rounded_rectangle(box(12, 12, 244, 244), radius=s(52), fill=PANEL)
    d.rounded_rectangle(box(14, 14, 242, 242), radius=s(50), fill=RING)
    d.rounded_rectangle(box(20, 20, 236, 236), radius=s(44), fill=DARK)
    d.rounded_rectangle(box(24, 24, 232, 232), radius=s(40), fill=PANEL)
    d.ellipse(box(43, 34, 61, 52), fill=DOT)
    # outline of the whole stack
    paint(img, dilate(mask_of(disk_shapes), 7), DARK)
    # disks from the bottom up: side band, bottom rim, top face, groove line
    for y in (154, 112, 70):
        d.ellipse(box(66, y + 33, 190, y + 59), fill=DISK_EDGE)
        d.rectangle(box(66, y + 13, 190, y + 46), fill=DISK_SIDE)
        d.rectangle(box(150, y + 13, 190, y + 46), fill=DISK_EDGE)
        d.ellipse(box(66, y, 190, y + 26), fill=DISK_TOP)
        d.ellipse(box(150, y + 26, 162, y + 36), fill=DARK)
    return img.resize((256, 256), Image.LANCZOS)


def main(root: Path):
    root = root.resolve()
    icon = draw()
    out = root / "docs" / "images"
    out.mkdir(parents=True, exist_ok=True)
    icon.save(out / "icon_256.png", optimize=True)
    icon.save(root / "Media" / "Icon.png", optimize=True)
    small = icon.resize((64, 64), Image.LANCZOS)
    small.save(root / "Media" / "Icon.tga", orientation=1, compression=None)
    print("wrote", out / "icon_256.png")


if __name__ == "__main__":
    main(Path(sys.argv[1] if len(sys.argv) > 1 else "."))
