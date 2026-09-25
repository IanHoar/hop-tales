#!/usr/bin/env python3
"""Export the wardrobes from Design/friends into the app.

Reads the item stickers, Design/friends/wardrobe-suites/suits.json (names, slots and unlock order
for the six new friends), Hare's order below, and Design/friends/wardrobe-anchors.json (where each
item sits on its friend's sit sticker). Writes:

- HopTalesPackage/Sources/World/Resources/wear-<friend>-<item>.webp, 360 px on the long side
- HopTalesPackage/Sources/Content/Resources/wardrobe.json, every friend's items in unlock order

Both are generated and committed; re-run this after the anchors are tuned. Needs cwebp.
"""
import json
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
FRIENDS = ROOT / "Design/friends"
WORLD = ROOT / "HopTalesPackage/Sources/World/Resources"
CONTENT = ROOT / "HopTalesPackage/Sources/Content/Resources"

HARE = [
    ("straw", "Straw hat"), ("bowtie", "Bow tie"), ("neckerchief", "Spotty neckerchief"),
    ("crown", "Flower crown"), ("satchel", "Satchel"), ("bobble", "Bobble hat"),
    ("specs", "Round glasses"), ("pirate", "Pirate hat"), ("wizard", "Wizard hat"),
    ("acorn", "Acorn cap"), ("cape", "Cape"), ("paper-crown", "Paper crown"),
]


def export_sticker(source, name, scratch):
    resized = scratch / f"{name}.png"
    subprocess.run(["sips", "-Z", "360", str(source), "--out", str(resized)], check=True,
                   capture_output=True)
    subprocess.run(["cwebp", "-quiet", "-q", "90", "-alpha_q", "100", str(resized), "-o",
                    str(WORLD / f"{name}.webp")], check=True)


def parts(transform):
    transforms = transform if isinstance(transform, list) else [transform]
    return [{"x": t["x"], "y": t["y"], "w": t["w"], "rot": t["rot"], "pivot": t["pivot"]}
            for t in transforms]


def main():
    if not shutil.which("cwebp"):
        sys.exit("cwebp not found. brew install webp")
    anchors = json.loads((FRIENDS / "wardrobe-anchors.json").read_text())
    suits = json.loads((FRIENDS / "wardrobe-suites/suits.json").read_text())
    listing = {"hare": [(item_id, name, FRIENDS / "wardrobe" / f"{item_id}.png") for item_id, name in HARE]}
    for friend, suit in suits.items():
        listing[friend] = [(item["id"], item["name"], FRIENDS / "wardrobe-suites" / friend / f"{item['id']}.png")
                           for item in suit["items"]]

    wardrobe = {}
    with tempfile.TemporaryDirectory() as scratch:
        for friend, items in listing.items():
            placed = anchors[friend]["items"]
            wardrobe[friend] = []
            for item_id, name, source in items:
                transform = placed[item_id]
                slot = (transform[0] if isinstance(transform, list) else transform)["slot"]
                export_sticker(source, f"wear-{friend}-{item_id}", Path(scratch))
                wardrobe[friend].append(
                    {"id": item_id, "name": name, "slot": slot.rstrip("2"), "parts": parts(transform)}
                )
            print(f"exported {friend}: {len(items)} items")
    (CONTENT / "wardrobe.json").write_text(json.dumps(wardrobe, indent=2) + "\n")


if __name__ == "__main__":
    main()
