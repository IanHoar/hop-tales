"""Wardrobe fit: sit-pose anchors per friend + per-item transforms, composited to check fit.

Coordinates are fractions of the sit sticker's width (x) and height (y).
Item width is a fraction of the sticker's width. Pivot per slot:
  head: bottom-centre of the item on the anchor · neck: top-centre · everything else: centre.
"""
import os, json
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
P = os.path.join(HERE, "..", "cast-canvas", "project")
SU = json.load(open(os.path.join(P, "cast", "suits", "suits.json")))

SIT = {k: f"cast/chars/{k}.png" for k in ("bunny", "frog", "crow", "cat", "crab", "grasshopper")}
SIT["hare"] = "collage/hare-sit.png"

# slot -> [x, y, width, rotation]
ANCHORS = {
    "bunny": {"head": [0.70, 0.335, 0.42, -8], "eyes": [0.735, 0.355, 0.28, 0], "neck": [0.73, 0.47, 0.34, 0], "body": [0.58, 0.60, 0.56, 0], "back": [0.34, 0.52, 0.34, -6]},
    "frog": {"head": [0.71, 0.21, 0.32, -4], "eyes": [0.735, 0.20, 0.28, 0], "neck": [0.75, 0.31, 0.30, 0], "body": [0.62, 0.58, 0.46, 0], "back": [0.46, 0.32, 0.30, 0]},
    "crow": {"head": [0.64, 0.20, 0.30, -6], "eyes": [0.71, 0.225, 0.24, 0], "neck": [0.66, 0.30, 0.28, 0], "body": [0.52, 0.52, 0.46, -18], "back": [0.43, 0.53, 0.26, -10]},
    "cat": {"head": [0.74, 0.155, 0.48, -4], "eyes": [0.80, 0.21, 0.34, 0], "neck": [0.72, 0.265, 0.30, 0], "body": [0.62, 0.52, 0.58, 0], "back": [0.50, 0.45, 0.40, 0]},
    "crab": {"head": [0.58, 0.16, 0.30, 0], "eyes": [0.60, 0.22, 0.26, 0], "body": [0.56, 0.50, 0.44, 0], "back": [0.40, 0.18, 0.24, 0],
             "claws": [0.41, 0.66, 0.17, -12], "claws2": [0.64, 0.60, 0.16, 14]},
    "grasshopper": {"head": [0.78, 0.31, 0.16, -8], "eyes": [0.79, 0.37, 0.16, 0], "neck": [0.73, 0.48, 0.13, 0], "body": [0.62, 0.50, 0.30, -6], "back": [0.55, 0.36, 0.24, 0],
                    "antennae": [0.885, 0.05, 0.07, 0], "antennae2": [0.95, 0.07, 0.07, 0]},
    "hare": {"head": [0.70, 0.33, 0.48, -6], "eyes": [0.74, 0.36, 0.30, 0], "neck": [0.66, 0.43, 0.46, 0], "body": [0.58, 0.64, 0.66, 0], "back": [0.46, 0.57, 0.40, 0]},
}
# per-item tweaks: dx, dy, width multiplier, extra rotation
TWEAK = {
    ("bunny", "headscarf"): (0, 0.01, 0.8, 0), ("bunny", "bluebell-crown"): (0, 0.01, 0.9, 0), ("bunny", "daisy-chain"): (0, 0.01, 0.85, 0),
    ("bunny", "shawl"): (0.04, -0.06, 0.95, 0),
    ("frog", "swim-ring"): (0, 0, 1.0, 0), ("frog", "raincoat"): (0, -0.02, 1.0, 0), ("frog", "frog-crown"): (0, 0.005, 0.8, 0),
    ("crow", "pocket-watch"): (0, 0.02, 0.6, 0), ("crow", "waistcoat"): (0, 0, 1.0, 0),
    ("cat", "rose-clip"): (-0.08, -0.06, 0.45, 20), ("cat", "red-bell-collar"): (0, 0, 0.85, 0), ("cat", "beret"): (0, 0, 0.8, 0),
    ("crab", "life-ring"): (0, 0, 1.0, 0),
    ("hare", "acorn"): (0.01, 0.005, 0.6, 0), ("hare", "cape"): (0, 0, 1.3, 0), ("hare", "satchel"): (0, 0.02, 0.9, 0),
}

HARE_ITEMS = [("straw", "head"), ("bowtie", "neck"), ("neckerchief", "neck"), ("crown", "head"), ("satchel", "back"), ("bobble", "head"),
              ("specs", "eyes"), ("pirate", "head"), ("wizard", "head"), ("acorn", "head"), ("cape", "back"), ("paper-crown", "head")]


def items_for(k):
    if k == "hare":
        return [(i, s, f"cast/wear/{i}.png") for i, s in HARE_ITEMS]
    return [(it["id"], it["slot"], f"cast/suits/{k}/{it['id']}.png") for it in SU[k]["items"]]


def transform(k, iid, slot):
    x, y, w, r = ANCHORS[k][slot]
    dx, dy, wm, dr = TWEAK.get((k, iid), (0, 0, 1, 0))
    return {"slot": slot, "x": round(x + dx, 3), "y": round(y + dy, 3), "w": round(w * wm, 3), "rot": r + dr,
            "pivot": {"head": [0.5, 1.0], "neck": [0.5, 0.0]}.get(slot, [0.5, 0.5])}


PAIRS = ("claws", "antennae")


def halves(it):
    w = it.width
    return [it.crop((0, 0, w // 2, it.height)).crop(it.crop((0, 0, w // 2, it.height)).getbbox()),
            it.crop((w // 2, 0, w, it.height)).crop(it.crop((w // 2, 0, w, it.height)).getbbox())]


def compose(k, iid, slot, src, scale=1.0):
    raw = Image.open(os.path.join(P, SIT[k])).convert("RGBA")
    base = Image.new("RGBA", (raw.width + 2 * M, raw.height + 2 * M))
    base.alpha_composite(raw, (M, M))
    if slot in PAIRS:
        img = Image.open(os.path.join(P, src)).convert("RGBA")
        out = base
        for part, s2 in zip(halves(img), (slot, slot + "2")):
            out = place(out, k, iid, s2, part)
        return out.crop(out.getbbox())
    out = place(base, k, iid, slot, Image.open(os.path.join(P, src)).convert("RGBA"))
    return out.crop(out.getbbox())


M = 120


def place(base, k, iid, slot, it):
    W, H = base.width - 2 * M, base.height - 2 * M
    t = transform(k, iid, slot)
    iw = t["w"] * W
    it = it.resize((max(1, round(iw)), max(1, round(it.height * iw / it.width))), Image.LANCZOS)
    px, py = t["pivot"]
    # rotate around the pivot: pad so the pivot is the centre
    cw, ch = it.size
    pad = Image.new("RGBA", (cw * 2, ch * 2))
    pad.alpha_composite(it, (round(cw - px * cw), round(ch - py * ch)))
    pad = pad.rotate(-t["rot"], resample=Image.BICUBIC)
    out = base.copy()
    out.alpha_composite(pad, (round(M + t["x"] * W - cw), round(M + t["y"] * H - ch)))
    return out


def export():
    data = {}
    for k in ANCHORS:
        data[k] = {"sit": SIT[k], "anchors": {s: {"x": v[0], "y": v[1], "w": v[2], "rot": v[3]} for s, v in ANCHORS[k].items()},
                   "items": {iid: ([transform(k, iid, slot), transform(k, iid, slot + "2")] if slot in PAIRS else transform(k, iid, slot))
                             for iid, slot, _ in items_for(k)}}
    return data


def sheet(path, keys=None, cell=230):
    keys = keys or list(ANCHORS)
    cols = 12
    img = Image.new("RGB", (cell * cols, cell * len(keys)), (166, 186, 146))
    for r, k in enumerate(keys):
        for c, (iid, slot, src) in enumerate(items_for(k)):
            im = compose(k, iid, slot, src)
            im.thumbnail((cell - 10, cell - 10))
            img.paste(im, (c * cell + (cell - im.width) // 2, r * cell + (cell - im.height) // 2), im)
    img.save(path, quality=88)


if __name__ == "__main__":
    import sys
    sheet(sys.argv[1] if len(sys.argv) > 1 else "/tmp/claude-0/fit.jpg")
