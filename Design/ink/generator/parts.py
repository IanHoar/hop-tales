import json
import os

import dragon as D
import fox as F
import knight as K
from ink import svg, ground_shadow

CANVAS = "-120 -160 240 170"
DRAGON_CANVAS = "-150 -260 320 280"
KNIGHT_CANVAS = "-90 -180 180 200"

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


def without_near_wing(body):
    return body.rsplit('\n<g transform="rotate(', 1)[0]


DRAGON_PARTS = {
    "dragon-body-idle": (without_near_wing(D.dragon("idle", 0)), (0, 0)),
    "dragon-body-roar": (without_near_wing(D.dragon("roar", 0)), (0, 0)),
    "dragon-wing": (D.wing(8, -122, D.MEM, D.SCALE), (8, -122)),
}

KNIGHT_PARTS = {
    "knight-idle": (K.knight(0), (0, 0)),
    "knight-wave": (K.knight(20), (0, 0)),
}


def export(prefix, parts, canvas=CANVAS, out="../sprites/parts"):
    os.makedirs(out, exist_ok=True)
    x, y, w, h = map(float, canvas.split())
    pivots = {}
    for name, (body, pivot) in parts.items():
        open(f"{out}/{name}.svg", "w").write(svg(int(w * 2), int(h * 2), body, vb=canvas))
        pivots[name] = {"x": pivot[0], "y": pivot[1]}
    json.dump({"canvas": {"x": x, "y": y, "width": w, "height": h}, "pivots": pivots},
              open(f"{out}/{prefix}-pivots.json", "w"), indent=2)


if __name__ == "__main__":
    export("fox", FOX_PARTS)
    export("dragon", DRAGON_PARTS, DRAGON_CANVAS)
    export("knight", KNIGHT_PARTS, KNIGHT_CANVAS)
