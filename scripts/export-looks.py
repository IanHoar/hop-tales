#!/usr/bin/env python3
"""List the wardrobe items each friend has been painted wearing, in full.

A look is complete when World/Resources has its sitting sticker, idle strip and hop strip:
look-<friend>-<item>.webp, look-<friend>-<item>-idle.webp and look-<friend>-<item>-hop.webp.
Writes Content/Resources/looks.json, which the wardrobe reads to decide what it offers.
Run it after adding or removing look art.
"""
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ART = ROOT / "HopTalesPackage/Sources/World/Resources"
OUT = ROOT / "HopTalesPackage/Sources/Content/Resources/looks.json"
WARDROBE = ROOT / "HopTalesPackage/Sources/Content/Resources/wardrobe.json"

names = {path.stem for path in ART.glob("look-*.webp")}
looks = {}
for friend, items in json.loads(WARDROBE.read_text()).items():
    complete = [
        item["id"] for item in items
        if all(f"look-{friend}-{item['id']}{part}" in names for part in ("", "-idle", "-hop"))
    ]
    looks[friend] = complete

OUT.write_text(json.dumps(looks, indent=2, sort_keys=True) + "\n")
print(f"wrote {sum(map(len, looks.values()))} complete looks to {OUT.relative_to(ROOT)}")
for friend, items in sorted(looks.items()):
    print(f"  {friend}: {', '.join(items) or '-'}")
