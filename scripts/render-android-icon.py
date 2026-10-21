#!/usr/bin/env python3
"""Render the Android adaptive launcher icon from the iOS icon layers.

Reads ios/HopTales/AppIcon.icon (Hare.png over Paper.png on the sage fill in icon.json) and writes
android/app/src/main/res/mipmap-<density>/ic_launcher_{foreground,background,monochrome}.webp.

An adaptive icon is a 108 dp square of which only the middle 66 dp circle is sure to show, so the
hare is scaled until its furthest opaque pixel sits inside that circle. The monochrome layer is the
hare's inked body without its sticker rim, which the launcher tints for themed icons. The outputs
are generated and committed; re-run this when the iOS icon changes. Needs Pillow.
"""
import json
import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parent.parent
ICON = ROOT / "ios/HopTales/AppIcon.icon"
RES = ROOT / "android/app/src/main/res"
DENSITIES = {"mdpi": 1, "hdpi": 1.5, "xhdpi": 2, "xxhdpi": 3, "xxxhdpi": 4}
CANVAS_DP = 108
SAFE_RADIUS_DP = 33
MARGIN_DP = 0.5
RIM_WHITE = 235


def fill_colour():
    spec = json.loads((ICON / "icon.json").read_text())["fill"]["solid"]
    channels = [float(value) for value in spec.split(":")[1].split(",")]
    return tuple(round(value * 255) for value in channels[:3])


def furthest_radius(image):
    alpha = image.getchannel("A")
    width, height = image.size
    cx, cy = width / 2, height / 2
    pixels = alpha.load()
    furthest = 0.0
    for y in range(0, height, 2):
        for x in range(0, width, 2):
            if pixels[x, y] > 24:
                furthest = max(furthest, math.hypot(x - cx, y - cy))
    return furthest


def silhouette_of(image):
    """The hare without its white sticker rim or drop shadow: the inked body, filled from inside."""
    pixels = image.load()
    mask = Image.new("L", image.size, 0)
    marks = mask.load()
    for y in range(image.height):
        for x in range(image.width):
            red, green, blue, alpha = pixels[x, y]
            if alpha > 200 and min(red, green, blue) < RIM_WHITE:
                marks[x, y] = 255
    left, top, right, bottom = mask.getbbox()
    cx, cy = (left + right) / 2, (top + bottom) / 2
    seed = min(
        ((x, y) for y in range(top, bottom, 4) for x in range(left, right, 4) if marks[x, y]),
        key=lambda point: math.hypot(point[0] - cx, point[1] - cy),
    )
    ImageDraw.floodfill(mask, seed, 128)
    body = mask.point(lambda value: 255 if value == 128 else 0)
    body = body.filter(ImageFilter.MaxFilter(5)).filter(ImageFilter.MinFilter(5))
    shape = Image.new("RGBA", image.size, (255, 255, 255, 0))
    shape.putalpha(body)
    return shape


def centred(image):
    left, top, right, bottom = image.getchannel("A").getbbox()
    shift = ((image.width - (left + right)) // 2, (image.height - (top + bottom)) // 2)
    moved = Image.new("RGBA", image.size, (0, 0, 0, 0))
    moved.paste(image, shift)
    return moved


def main():
    hare = centred(Image.open(ICON / "Assets/Hare.png").convert("RGBA"))
    paper = Image.open(ICON / "Assets/Paper.png").convert("RGBA")
    background = Image.alpha_composite(Image.new("RGBA", paper.size, fill_colour() + (255,)), paper)
    radius = furthest_radius(hare)
    silhouette = silhouette_of(hare)

    for density, factor in DENSITIES.items():
        side = round(CANVAS_DP * factor)
        hare_side = round(hare.width * (SAFE_RADIUS_DP - MARGIN_DP) * factor / radius)
        offset = ((side - hare_side) // 2,) * 2
        folder = RES / f"mipmap-{density}"
        folder.mkdir(parents=True, exist_ok=True)

        foreground = Image.new("RGBA", (side, side), (0, 0, 0, 0))
        foreground.paste(hare.resize((hare_side, hare_side), Image.LANCZOS), offset)
        foreground.save(folder / "ic_launcher_foreground.webp", quality=92, method=6)

        monochrome = Image.new("RGBA", (side, side), (255, 255, 255, 0))
        monochrome.paste(silhouette.resize((hare_side, hare_side), Image.LANCZOS), offset)
        monochrome.save(folder / "ic_launcher_monochrome.webp", lossless=True, method=6)

        background.convert("RGB").resize((side, side), Image.LANCZOS).save(
            folder / "ic_launcher_background.webp", quality=90, method=6
        )
        print(f"rendered mipmap-{density} ({side} px)")


if __name__ == "__main__":
    main()
