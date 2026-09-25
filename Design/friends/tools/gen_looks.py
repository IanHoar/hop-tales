"""Dressed looks: each friend painted wearing each wardrobe item, as a sitting sticker registered to the base.

  gen <friend> [item ...]   ask Nano Banana for the dressed sticker (raw into nb/looks/<friend>/<item>.png)
  build <friend> [item ...] key the raw out, register it to the base sticker, write look-<friend>-<item>.webp
  board <friend>            contact sheet of base + every look into the scratchpad

The look keeps the base sticker's canvas, so the app can draw it exactly where the base goes. Registration searches
scale and offset for the best overlap with the base silhouette below the head (items rarely reach there), then puts
the feet on the base's bottom row. A look whose item pokes outside the canvas is shrunk about the feet until it fits;
the factor is kept in nb/looks/fit.json.
"""
import concurrent.futures as cf
import json
import os
import sys

import numpy as np
from PIL import Image
from scipy import ndimage as ndi

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
sys.path.insert(0, os.path.join(ROOT, "Design", "collage", "tools"))
os.environ.setdefault("NB_MODEL", "gemini-3.1-flash-image")

RES = os.path.join(ROOT, "HopTalesPackage", "Sources", "World", "Resources")
WARDROBE = os.path.join(ROOT, "HopTalesPackage", "Sources", "Content", "Resources", "wardrobe.json")
RAW = os.path.join(HERE, "nb", "looks")
GREY = (128, 128, 128)

CAST = {
    "hare": ("a brown hare", "hare-sit", "red knitted scarf", "neck"),
    "bunny": ("a grey-brown wild rabbit called Bramble", "friend-bunny", "lilac ribbon bow on its ear", "head"),
    "frog": ("a green spotted frog called Puddle", "friend-frog", "yellow neckerchief", "neck"),
    "crow": ("a black crow called Button", "friend-crow", "blue knitted cap", "head"),
    "cat": ("a ginger tabby cat called Marmalade", "friend-cat", "sage-green ribbon collar with a bell", "neck"),
    "crab": ("a red shore crab called Nipper", "friend-crab", "striped sailor neckerchief", "neck"),
    "grasshopper": ("a green grasshopper called Sprig", "friend-grasshopper", "little brown leather satchel", "back"),
}

WHERE = {
    "head": "on its head",
    "eyes": "over its eyes",
    "neck": "around its neck",
    "body": "on its body",
    "back": "on its back",
    "claws": "on its claws",
    "antennae": "on its antennae",
}

ASPECTS = {"1:1": 1, "2:3": 2 / 3, "3:2": 3 / 2, "3:4": 3 / 4, "4:3": 4 / 3, "4:5": 4 / 5, "5:4": 5 / 4,
           "9:16": 9 / 16, "16:9": 16 / 9}


def items(friend):
    return json.load(open(WARDROBE))[friend]


def base(friend):
    return Image.open(os.path.join(RES, CAST[friend][1] + ".webp")).convert("RGBA")


def on_grey(im, aspect, margin=0.14):
    w, h = im.size
    cw = max(w, h * aspect) * (1 + margin * 2)
    ch = cw / aspect
    if ch < h * (1 + margin * 2):
        ch = h * (1 + margin * 2)
        cw = ch * aspect
    canvas = Image.new("RGBA", (int(cw), int(ch)), GREY + (255,))
    canvas.alpha_composite(im, ((int(cw) - w) // 2, int(ch) - h - int(h * margin * 0.6)))
    return canvas.convert("RGB")


def closest_aspect(w, h):
    r = w / h * 1.1
    return min(ASPECTS, key=lambda k: abs(np.log(ASPECTS[k] / r)))


def prompt(friend, item):
    who, _, accessory, accessory_slot = CAST[friend]
    name = item["name"].lower()
    keep = (f"Take off its {accessory} and put the {name} on instead."
            if item["slot"] == accessory_slot else f"It keeps its {accessory}.")
    return (
        f"Image 1 is a sticker of {who}. Image 2 is a sticker of a {name}. "
        f"Paint the same sticker of the same {who.split(' called ')[0].replace('a ', '', 1)} wearing the {name} {WHERE[item['slot']]}. "
        f"{keep} "
        "Keep the character exactly the same: the same pose, proportions, face, markings, colours and size in the frame. "
        f"Fit the {name} naturally to its body at the right scale, so parts of the animal pass in front of or behind it as they would, "
        "with its own shading, in the same soft watercolour and fine ink line style. "
        "Keep one thick white die-cut paper sticker border around the whole outline and the soft drop shadow. "
        "Plain flat mid-grey background, nothing else in the picture, no text."
    )


def gen_one(friend, item):
    import nb
    b = base(friend)
    aspect = closest_aspect(*b.size)
    thing = Image.open(os.path.join(RES, f"wear-{friend}-{item['id']}.webp")).convert("RGBA")
    ref_item = on_grey(thing, 1.0, margin=0.1)
    out, text, _ = nb.generate(prompt(friend, item), [on_grey(b, ASPECTS[aspect]), ref_item], aspect, "1K")
    os.makedirs(os.path.join(RAW, friend), exist_ok=True)
    out.save(os.path.join(RAW, friend, f"{item['id']}.png"))
    return f"{friend}/{item['id']} {aspect} {text[:80]}"


def key_alpha(rgb):
    from looper import key
    return key(rgb.astype(np.float32))


def bbox(mask):
    r = np.nonzero(mask.any(1))[0]
    c = np.nonzero(mask.any(0))[0]
    return c.min(), r.min(), c.max() + 1, r.max() + 1


def body_rows(friend, h):
    top = {"hare": 0.45, "bunny": 0.4, "crow": 0.4, "cat": 0.45}.get(friend, 0.3)
    return int(h * top)


def register(friend, gen_rgba, base_rgba):
    """Scale + offset putting the generated sticker onto the base canvas by best body overlap."""
    ga = np.asarray(gen_rgba)[..., 3] > 128
    ba = np.asarray(base_rgba)[..., 3] > 128
    H, W = ba.shape
    gx0, gy0, gx1, gy1 = bbox(ga)
    bx0, by0, bx1, by1 = bbox(ba)
    s0 = (by1 - by0) / (gy1 - gy0)
    cut = body_rows(friend, H)
    step = 3
    small_base = ba[::step, ::step]
    best = None
    for s in s0 * np.linspace(0.84, 1.08, 13):
        w, h = int(gen_rgba.width * s), int(gen_rgba.height * s)
        m = np.asarray(Image.fromarray(ga.astype(np.uint8) * 255).resize((w, h), Image.NEAREST)) > 128
        mx0, my0, mx1, my1 = bbox(m)
        for dy in range(-12, 13, 3):
            oy = by1 - my1 + dy
            for dx in range(-40, 41, 4):
                ox = (bx0 + bx1) // 2 - (mx0 + mx1) // 2 + dx
                canvas = np.zeros((H, W), bool)
                ys, xs = max(0, oy), max(0, ox)
                ye, xe = min(H, oy + h), min(W, ox + w)
                if ye <= ys or xe <= xs:
                    continue
                canvas[ys:ye, xs:xe] = m[ys - oy:ye - oy, xs - ox:xe - ox]
                c = canvas[cut:][::step, ::step]
                b = small_base[cut // step:][:c.shape[0]]
                iou = (c & b).sum() / max((c | b).sum(), 1)
                if best is None or iou > best[0]:
                    best = (iou, s, ox, oy)
    return best


def build_one(friend, item, fit):
    raw = os.path.join(RAW, friend, f"{item['id']}.png")
    rgb = np.asarray(Image.open(raw).convert("RGB")).astype(np.float32)
    alpha = key_alpha(rgb)
    lab, n = ndi.label(alpha > 0.5)
    if n > 1:
        sizes = ndi.sum(np.ones_like(lab), lab, range(1, n + 1))
        keep = np.isin(lab, [i + 1 for i, v in enumerate(sizes) if v > sizes.max() * 0.02])
        alpha = alpha * ndi.binary_dilation(keep, iterations=3)
    gen = Image.fromarray(np.dstack([rgb, alpha * 255]).clip(0, 255).astype(np.uint8), "RGBA")
    x0, y0, x1, y1 = bbox(np.asarray(gen)[..., 3] > 8)
    gen = gen.crop((x0, y0, x1, y1))
    b = base(friend)
    iou, s, ox, oy = register(friend, gen, b)
    W, H = b.size
    w, h = int(gen.width * s), int(gen.height * s)
    feet_y = oy + h
    feet_x = ox + w / 2
    shrink = min(1.0, feet_y / h if oy < 0 else 1.0,
                 (W - feet_x) / (w - (feet_x - ox)) if ox + w > W else 1.0,
                 feet_x / (feet_x - ox) if ox < 0 else 1.0)
    shrink = min(1.0, max(shrink, 0.7))
    w2, h2 = int(w * shrink), int(h * shrink)
    ox2 = int(round(feet_x - (feet_x - ox) * shrink))
    oy2 = int(round(feet_y - h2))
    layer = Image.new("RGBA", (W + 2 * w2, H + 2 * h2), (0, 0, 0, 0))
    layer.alpha_composite(gen.resize((w2, h2), Image.LANCZOS), (ox2 + w2, oy2 + h2))
    out = layer.crop((w2, h2, w2 + W, h2 + H))
    out.save(os.path.join(RES, f"look-{friend}-{item['id']}.webp"), "WEBP", quality=90, method=6)
    fit[f"{friend}/{item['id']}"] = {"iou": round(float(iou), 3), "scale": round(float(s), 3),
                                    "shrink": round(float(shrink), 3)}
    return f"{friend}/{item['id']} iou {iou:.2f} shrink {shrink:.2f}"


def board(friend, path):
    b = base(friend)
    looks = [b] + [Image.open(os.path.join(RES, f"look-{friend}-{i['id']}.webp")).convert("RGBA")
                   for i in items(friend) if os.path.exists(os.path.join(RES, f"look-{friend}-{i['id']}.webp"))]
    h = 300
    tiles = [im.resize((int(im.width * h / im.height), h)) for im in looks]
    cols = 5
    tw = max(t.width for t in tiles) + 10
    rows = (len(tiles) + cols - 1) // cols
    sheet = Image.new("RGBA", (tw * cols, (h + 10) * rows), (150, 150, 150, 255))
    for i, t in enumerate(tiles):
        sheet.alpha_composite(t, ((i % cols) * tw + 5, (i // cols) * (h + 10) + 5))
    sheet.convert("RGB").save(path)


def pick(friend, ids):
    all_items = items(friend)
    return [i for i in all_items if not ids or i["id"] in ids]


if __name__ == "__main__":
    step, friend, *ids = sys.argv[1:]
    if step == "gen":
        with cf.ThreadPoolExecutor(4) as ex:
            for f in cf.as_completed([ex.submit(gen_one, friend, i) for i in pick(friend, ids)]):
                try:
                    print(f.result(), flush=True)
                except SystemExit as e:
                    print("failed:", e, flush=True)
    elif step == "build":
        fit_path = os.path.join(RAW, "fit.json")
        fit = json.load(open(fit_path)) if os.path.exists(fit_path) else {}
        for i in pick(friend, ids):
            if os.path.exists(os.path.join(RAW, friend, f"{i['id']}.png")):
                print(build_one(friend, i, fit), flush=True)
        json.dump(fit, open(fit_path, "w"), indent=1)
    elif step == "board":
        board(friend, ids[0])
