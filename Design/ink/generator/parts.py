import json
import os

import fox as F
from ink import svg, ground_shadow

CANVAS = "-120 -160 240 170"

FOX_PARTS = {
    "fox-shadow": (ground_shadow(2, 1, 50, 6, 0.3), (2, 1)),
    "fox-tail": (F.tail(), (-24, -54)),
    "fox-leg-far-rear": (F.leg(-20, -30, F.FUR_FAR, False), (-20, -28)),
    "fox-leg-far-front": (F.leg(18, -30, F.FUR_FAR, False), (18, -28)),
    "fox-body": (F.body(), (0, -40)),
    "fox-leg-near-rear": (F.leg(-12, -28, F.FUR, True), (-12, -26)),
    "fox-leg-near-front": (F.leg(26, -28, F.FUR, True), (26, -26)),
    "fox-scarf": (F.scarf_tail(), (10, -60)),
    "fox-head-idle": (F.head("idle"), (18, -66)),
    "fox-head-happy": (F.head("happy"), (18, -66)),
    "fox-wrap": (F.wrap(), (26, -58)),
}


def export(parts, out="../sprites/parts"):
    os.makedirs(out, exist_ok=True)
    pivots = {}
    for name, (body, pivot) in parts.items():
        open(f"{out}/{name}.svg", "w").write(svg(480, 340, body, vb=CANVAS))
        pivots[name] = {"x": pivot[0], "y": pivot[1]}
    x, y, w, h = map(float, CANVAS.split())
    json.dump({"canvas": {"x": x, "y": y, "width": w, "height": h}, "pivots": pivots},
              open(f"{out}/fox-pivots.json", "w"), indent=2)


if __name__ == "__main__":
    export(FOX_PARTS)
