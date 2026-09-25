"""Dressed looks: each friend painted wearing each wardrobe item, as a sitting sticker registered to the base.

  gen <friend> [item ...]   ask Nano Banana for the dressed sticker (raw into nb/looks/<friend>/<item>.png)
  build <friend> [item ...] key the raw out, register it to the base sticker, write look-<friend>-<item>.webp
  redraw <friend> [item ...] repaint with the item made to fit inside the base sticker's outline
  board <friend>            contact sheet of base + every look into the scratchpad
  anim-gen <friend> <item> [rest|hop] ...        paint the dressed idle rest and the hop frames; the idle is the
                                                 base idle with the rest's item carried on the moving head
  anim-build <friend> <item>                     assemble look-<friend>-<item>-idle.webp and -hop.webp
  anim-board <friend> <item> <path>              base strips above dressed strips, for checking
  anim-heads <friend> <item> <path>              every frame's head at full size, base above dressed: check the
                                                 anatomy (ears, eyes, limbs, doubled items) before calling a look done

The look keeps the base sticker's canvas, so the app can draw it exactly where the base goes. Registration searches
scale and offset for the best overlap with the base silhouette below the head (items rarely reach there), then puts
the feet on the base's bottom row. The character is never shrunk: up to RIM px of sticker rim past the canvas is
clipped, and anything further fails the build so the item is redrawn to fit (`redraw`). Fits go in nb/looks/fit.json.
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
RIM = 4
DRIFT = 0.98
SIDES = ("top", "left", "right", "bottom")

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

EXTRA = {
    ("crab", "claw-mittens"): "Pull one striped mitten snugly over each of its two big front pincers, so the pincers are "
                              "inside the mittens; nothing floats loose.",
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
        f"{keep} {EXTRA.get((friend, item['id']), '')} "
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


FIT_NOTES = {
    ("hare", "crown"): "A small flower crown lying flat around the head at the base of the ears, like a ring on the "
                       "head, not standing up behind the ears.",
    ("crow", "autumn-scarf"): "A slim, snug knitted scarf close around the neck, not bulky, ends short.",
    ("bunny", "bluebell-crown"): "The crown sits up on top of the head between the bases of the ears, not low across them.",
    ("hare", "specs"): "Small round specs perched on the bridge of the nose, set back from the tip; nothing sticks out in front "
                       "of the tip of the nose.",
    ("frog", "lilypad-hat"): "The lily pad is worn like a little cape-hood: a thin flat pad draped over the back of the "
                             "head behind the eyes and down onto the neck, below the tops of the eyes; the bulging eyes "
                             "stay the highest points of the sticker.",
    ("crow", "top-hat"): "The top hat takes exactly the place of the blue knitted cap in image 1 and is no taller than "
                         "that cap: a squat, short top hat whose top edge is exactly where the top of the knitted cap "
                         "is in image 1.",
    ("cat", "garden-hat"): "A small straw garden hat with a round brim and a flower, clearly a hat, worn tilted back on "
                           "the head with the ears poking up through it; the ear tips stay the highest point.",
    ("cat", "beret"): "A flat beret lying flat and tilted to one side between and behind the ears; the ear tips stay "
                      "the highest point.",
    ("crab", "sailor-cap"): "A tiny sailor cap sitting on the front of the shell between the eye stalks, lower than the "
                            "tips of the eye stalks.",
    ("crab", "captain-hat"): "A very flat little captain's cap, hardly taller than its peak, lying on the front of the "
                             "shell between the eye stalks; the eye stalk tips stay clearly higher than the cap.",
}


def redraw_prompt(friend, item):
    who, _, accessory, accessory_slot = CAST[friend]
    name = item["name"].lower()
    animal = who.split(" called ")[0].replace("a ", "", 1)
    keep = (f"Take off its {accessory} and put the {name} on instead."
            if item["slot"] == accessory_slot else f"It keeps its {accessory}.")
    return (
        f"Image 1 is a sticker of {who}. Image 2 is a sticker of a {name}. "
        f"Paint the same sticker of the same {animal} wearing a {name} {WHERE[item['slot']]}. {keep} "
        f"{EXTRA.get((friend, item['id']), '')} {FIT_NOTES.get((friend, item['id']), '')} "
        f"The dressed sticker must fit inside exactly the same outline box as image 1 at exactly the same size: "
        f"nothing may reach higher than the highest point of the sticker in image 1, or further left or right than "
        f"its left and right edges. So draw the {name} smaller, lower-profile and snug, tucked close to the body or "
        f"head (between or behind the ears, tilted, or sitting lower) so it stays inside that outline. The {name} "
        f"does not have to match image 2 exactly: keep the same kind of item, colours and material, reshaped to fit. "
        "Keep the character exactly the same: the same pose, proportions, head and ear size, face, markings, "
        "colours and size in the frame. Same soft watercolour and fine ink line style, the item with its own shading. "
        "Keep one thick white die-cut paper sticker border, the same thickness as image 1, and the soft drop shadow. "
        "Plain flat mid-grey background, nothing else in the picture, no text."
    )


def redraw_one(friend, item):
    import nb
    b = base(friend)
    aspect = closest_aspect(*b.size)
    thing = Image.open(os.path.join(RES, f"wear-{friend}-{item['id']}.webp")).convert("RGBA")
    out, text, _ = nb.generate(redraw_prompt(friend, item),
                               [on_grey(b, ASPECTS[aspect]), on_grey(thing, 1.0, margin=0.1)], aspect, "1K")
    os.makedirs(os.path.join(RAW, friend), exist_ok=True)
    out.save(os.path.join(RAW, friend, f"{item['id']}.png"))
    return f"{friend}/{item['id']} redrawn {text[:60]}"


def key_alpha(rgb):
    """Flood the grey key in from every edge; generations sometimes leave a darker strip along one border."""
    edge = np.concatenate([rgb[:6].reshape(-1, 3), rgb[-6:].reshape(-1, 3),
                           rgb[:, :6].reshape(-1, 3), rgb[:, -6:].reshape(-1, 3)])
    bg = np.median(edge, 0)
    d = np.sqrt(((rgb - bg) ** 2).sum(2))
    sat = rgb.max(2) - rgb.min(2)
    cand = (d < 34) | ((sat < 14) & (rgb.mean(2) < 200) & (rgb.mean(2) > 60))
    lab, _ = ndi.label(cand)
    border = np.concatenate([lab[0], lab[-1], lab[:, 0], lab[:, -1]])
    bgm = np.isin(lab, np.unique(border[border > 0]))
    fg = ndi.binary_fill_holes(~bgm)
    fg = ndi.binary_opening(fg, iterations=1)
    alpha = ndi.gaussian_filter(fg.astype(np.float32), 0.8)
    alpha[ndi.binary_erosion(fg, iterations=2)] = 1
    alpha[~ndi.binary_dilation(fg, iterations=2)] = 0
    return alpha


def bbox(mask):
    r = np.nonzero(mask.any(1))[0]
    c = np.nonzero(mask.any(0))[0]
    return c.min(), r.min(), c.max() + 1, r.max() + 1


def body_rows(friend, h):
    top = {"hare": 0.45, "bunny": 0.4, "crow": 0.4, "cat": 0.45}.get(friend, 0.3)
    return int(h * top)


REACH = {"head": {"top"}, "eyes": {"right"}, "antennae": {"top", "left", "right"},
         "neck": set(), "body": set(), "back": {"left", "right"}, "claws": {"left", "right"}}


def overflow(m, ox, oy, W, H):
    ys, xs = np.nonzero(m)
    return {"top": -(ys.min() + oy), "left": -(xs.min() + ox),
            "right": xs.max() + ox - W + 1, "bottom": ys.max() + oy - H + 1}


def register(friend, gen_rgba, base_rgba, reach=frozenset({"top", "left", "right"})):
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
    return refine(ga, ba, cut, best, reach)


def refine(ga, ba, cut, coarse, reach):
    """Full-resolution pass around the coarse fit, in half-percent scale steps and single pixels."""
    H, W = ba.shape
    _, s0, ox0, oy0 = coarse
    bx0, by0, bx1, by1 = bbox(ba)
    best = None
    for s in s0 * np.linspace(0.94, 1.03, 19):
        w, h = int(ga.shape[1] * s), int(ga.shape[0] * s)
        m = np.asarray(Image.fromarray(ga.astype(np.uint8) * 255).resize((w, h), Image.BILINEAR)) > 128
        mx0, my0, mx1, my1 = bbox(m)
        cx = ox0 + int(ga.shape[1] * s0) // 2
        for dy in range(-4, 5):
            oy = by1 - my1 + dy
            for dx in range(-6, 7):
                ox = cx - w // 2 + dx
                canvas = np.zeros((H + 2 * h, W + 2 * w), bool)
                canvas[oy + h:oy + 2 * h, ox + w:ox + 2 * w] = m
                over = overflow(m, ox, oy, W, H)
                if any(v > RIM for side, v in over.items() if side not in reach):
                    continue
                c = canvas[h:h + H, w:w + W]
                inside = c[cut:].sum() / max(canvas[h + cut:, :].sum(), 1)
                iou = (c[cut:] & ba[cut:]).sum() / max((c[cut:] | ba[cut:]).sum(), 1) * inside
                if best is None or iou > best[0]:
                    best = (iou, s, ox, oy)
    return best or coarse


def build_one(friend, item, fit):
    raw = os.path.join(RAW, friend, f"{item['id']}.png")
    rgb = np.asarray(Image.open(raw).convert("RGB")).astype(np.float32)
    alpha = key_alpha(rgb)
    lab, n = ndi.label(alpha > 0.5)
    if n > 1:
        sizes = ndi.sum(np.ones_like(lab), lab, range(1, n + 1))
        alpha = alpha * ndi.binary_dilation(lab == 1 + int(np.argmax(sizes)), iterations=3)
    gen = Image.fromarray(np.dstack([rgb, alpha * 255]).clip(0, 255).astype(np.uint8), "RGBA")
    x0, y0, x1, y1 = bbox(np.asarray(gen)[..., 3] > 8)
    gen = gen.crop((x0, y0, x1, y1))
    b = base(friend)
    free = register(friend, gen, b, frozenset(SIDES))
    snug = register(friend, gen, b, frozenset())
    loose = register(friend, gen, b, REACH[item["slot"]])
    snug_fits = snug[1] >= free[1] * DRIFT and max(overflow(
        np.asarray(gen.resize((int(gen.width * snug[1]), int(gen.height * snug[1])), Image.LANCZOS))[..., 3] > 128,
        snug[2], snug[3], *b.size).values()) <= RIM
    iou, s, ox, oy = snug if snug_fits else loose
    W, H = b.size
    big = gen.resize((int(gen.width * s), int(gen.height * s)), Image.LANCZOS)
    solid = np.asarray(big)[..., 3] > 128
    ys, xs = np.nonzero(solid)
    over = {"top": -(ys.min() + oy), "left": -(xs.min() + ox),
            "right": xs.max() + ox - W + 1, "bottom": ys.max() + oy - H + 1}
    over = {k: int(max(0, v)) for k, v in over.items()}
    if max(over.values()) > RIM:
        raise SystemExit(f"{friend}/{item['id']} pokes past the base canvas at full scale {over}; redraw the item")
    layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    layer.alpha_composite(big.crop((max(0, -ox), max(0, -oy), big.width, big.height)), (max(0, ox), max(0, oy)))
    layer.save(os.path.join(RES, f"look-{friend}-{item['id']}.webp"), "WEBP", quality=90, method=6)
    fit[f"{friend}/{item['id']}"] = {"iou": round(float(iou), 3), "scale": round(float(s), 3), "shrink": 1.0,
                                    "vs_free_fit": round(float(s / free[1]), 3), "clipped": over}
    return f"{friend}/{item['id']} iou {iou:.2f} clipped {max(over.values())}px"


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


STRIPS = {friend: {"idle": (f"{friend}-idle-frames", 10, None), "hop": (f"{friend}-hop", 8, None)}
          for friend in CAST}
ANIM = os.path.join(HERE, "nb", "looks-anim")
CALLS = os.path.join(ANIM, "calls.log")
SCRATCH = os.environ.get("LOOKS_BOARDS", os.path.join(ANIM, "boards"))


def _count_calls():
    import nb
    if getattr(nb.generate, "counted", False):
        return
    plain = nb.generate

    def generate(*args, **kwargs):
        os.makedirs(ANIM, exist_ok=True)
        with open(CALLS, "a") as log:
            log.write(f"{args[0][:60]!r}\n")
        return plain(*args, **kwargs)
    generate.counted = True
    nb.generate = generate


def cells(name, count):
    strip = Image.open(os.path.join(RES, name + ".webp")).convert("RGBA")
    w = strip.width // count
    return [strip.crop((i * w, 0, (i + 1) * w, strip.height)) for i in range(count)]


def item_named(friend, item_id):
    return next(i for i in items(friend) if i["id"] == item_id)


def wearing(friend, item):
    who, _, accessory, accessory_slot = CAST[friend]
    name = item["name"].lower()
    swap = (f"Take off its {accessory} and put the {name} on instead, exactly as in image 2."
            if item["slot"] == accessory_slot else f"It keeps its {accessory}, and wears the {name} exactly as in image 2.")
    return name, swap


def anim_prompt(friend, item, what):
    who = CAST[friend][0]
    name, swap = wearing(friend, item)
    pose = {
        "rest": "Image 1 is a sticker of the character sitting. Image 2 is the same character dressed.",
        "idle": "Image 1 is a frame of the character's idle animation. Image 2 is the character's resting frame, dressed.",
        "hop": "Image 1 is a frame of the character mid-hop. Image 2 is the character dressed.",
        "hop-item": "Image 1 is a frame of the character mid-hop. Image 2 shows only the item it should wear, "
                    "cut out on its own.",
    }[what]
    return (
        f"{pose} The character is {who}. Repaint image 1 exactly, the same pose, framing, size, angle, face and "
        f"expression, eyes and ears exactly as in image 1, now wearing the {name}. {swap} "
        f"The {name} must be the same object as in image 2: same shape, colours, pattern and size relative to the "
        "head and body, fitted to this pose with its own shading, passing in front of or behind the body as it would. "
        f"{FIT_NOTES.get((friend, item['id']), '')} The {name} stays snug: nothing reaches beyond the character's "
        "outline in image 1 by more than a little. "
        "Same soft watercolour and fine ink line style. Keep one thick white die-cut paper sticker border around the "
        "whole outline. Plain flat mid-grey background, nothing else in the picture, no text."
    )


POSE = ("Image 1's pose is the one to paint, not image 2's: keep exactly the same crouch, stretch or landing, the "
        "same angle of the body, head and legs, and the same size. ")


def anim_gen_one(friend, item, what, index, frame, ref, hint=""):
    import nb
    aspect = closest_aspect(*frame.size)
    out, text, _ = nb.generate(hint + anim_prompt(friend, item, what),
                               [on_grey(frame, ASPECTS[aspect]), on_grey(ref, ASPECTS[closest_aspect(*ref.size)])],
                               aspect, "1K")
    folder = os.path.join(ANIM, friend, item["id"])
    os.makedirs(folder, exist_ok=True)
    out.save(os.path.join(folder, f"{what.split('-')[0]}-{index}.png"))
    return f"{friend}/{item['id']} {what}-{index} {text[:60]}"


def keyed_raw(path):
    rgb = np.asarray(Image.open(path).convert("RGB")).astype(np.float32)
    alpha = key_alpha(rgb)
    lab, n = ndi.label(alpha > 0.5)
    if n > 1:
        sizes = ndi.sum(np.ones_like(lab), lab, range(1, n + 1))
        alpha = alpha * ndi.binary_dilation(lab == 1 + int(np.argmax(sizes)), iterations=3)
    im = Image.fromarray(np.dstack([rgb, alpha * 255]).clip(0, 255).astype(np.uint8), "RGBA")
    return im.crop(bbox(np.asarray(im)[..., 3] > 8))


def fit_to(gen, target, cut=0, scales=np.linspace(0.86, 1.1, 13), reach=24, band=None):
    """Place gen on target's canvas by best silhouette overlap below row cut (or within rows band)."""
    ta = np.asarray(target)[..., 3] > 128
    H, W = ta.shape
    tx0, ty0, tx1, ty1 = bbox(ta)
    ga = np.asarray(gen)[..., 3] > 128
    s0 = (ty1 - ty0) / ga.shape[0]
    best = None
    for s in s0 * scales:
        w, h = max(1, int(gen.width * s)), max(1, int(gen.height * s))
        m = np.asarray(Image.fromarray(ga.astype(np.uint8) * 255).resize((w, h), Image.NEAREST)) > 128
        mb = bbox(m)
        for dy in range(-reach, reach + 1, 2):
            oy = ty1 - h + dy
            for dx in range(-reach * 2, reach * 2 + 1, 3):
                ox = (tx0 + tx1) // 2 - w // 2 + dx
                canvas = np.zeros((H, W), bool)
                ys, xs, ye, xe = max(0, oy), max(0, ox), min(H, oy + h), min(W, ox + w)
                if ye <= ys or xe <= xs:
                    continue
                if max(-(mb[1] + oy), -(mb[0] + ox), mb[2] - 1 + ox - W + 1, mb[3] - 1 + oy - H + 1) > RIM:
                    continue
                canvas[ys:ye, xs:xe] = m[ys - oy:ye - oy, xs - ox:xe - ox]
                lo, hi = band or (cut, H)
                c, t = canvas[lo:hi], ta[lo:hi]
                iou = (c & t).sum() / max((c | t).sum(), 1)
                if best is None or iou > best[0]:
                    best = (iou, s, ox, oy)
    if best is None:
        raise SystemExit("frame cannot sit inside its cell at this size; repaint it tucked in")
    iou, s, ox, oy = best
    layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    big = gen.resize((int(gen.width * s), int(gen.height * s)), Image.LANCZOS)
    ys, xs = np.nonzero(np.asarray(big)[..., 3] > 128)
    over = max(0, -(ys.min() + oy), -(xs.min() + ox), xs.max() + ox - W + 1, ys.max() + oy - H + 1)
    if over > RIM:
        raise SystemExit(f"frame pokes {over}px past its cell; repaint it tucked in")
    layer.alpha_composite(big.crop((max(0, -ox), max(0, -oy), big.width, big.height)), (max(0, ox), max(0, oy)))
    return layer, iou


def head_onto(body, head, neck):
    """Rest body below the neck line, the frame's head above it, feathered across 18 rows."""
    b = np.asarray(body).astype(np.float32)
    h = np.asarray(head).astype(np.float32)
    rows = np.arange(b.shape[0], dtype=np.float32)[:, None, None]
    t = np.clip((neck - rows) / 18 + 0.5, 0, 1)
    out = h * t + b * (1 - t)
    return Image.fromarray(out.clip(0, 255).astype(np.uint8), "RGBA")


MAGENTA = "flat pure magenta (#FF00FF), fully opaque, with no shading, texture, outline or gradient"


def paint_mask(src, what, out):
    import nb
    aspect = closest_aspect(*src.size)
    prompt = (f"Recolour only the {what} in this sticker {MAGENTA}: all of it, crown, brim, band and anything "
              f"attached to it, with no gaps. The animal's own body is not part of the {what}: its ears, head, fur, "
              "eyes and face keep their natural colours exactly, including any ear that passes in front of or "
              "through the item. Leave everything else exactly as it is: the white sticker border, the position and "
              "the size. Do not add, remove or move anything. Plain flat mid-grey background.")
    im, _, _ = nb.generate(prompt, [on_grey(src, ASPECTS[aspect])], aspect, "1K")
    im.save(out)


def magenta(path, target):
    """The magenta-painted copy, registered onto target like the rest, as a soft mask."""
    fitted, _ = fit_to(keyed_raw(path), target, cut=0)
    a = np.asarray(fitted).astype(np.float32)
    hit = (a[..., 0] > 200) & (a[..., 1] < 60) & (a[..., 2] > 200) & (a[..., 3] > 128)
    return ndi.binary_closing(ndi.binary_opening(hit, iterations=1), iterations=2)


APPENDAGES = {"hare": "two long ears", "bunny": "two ears", "cat": "two ears", "crab": "two eye stalks and eyes",
              "grasshopper": "two antennae"}
THROUGH = ("head",)


def paint_whole(src, friend, item, out):
    """The dressed rest with the appendages taken away, so the whole item shows with no holes cut for them."""
    import nb
    name, _ = wearing(friend, item)
    aspect = closest_aspect(*src.size)
    prompt = (f"Repaint this sticker exactly, but with the {APPENDAGES[friend]} removed completely, as if the "
              f"character had none, so the whole {name} is visible: a complete, intact {name} with no holes, "
              f"notches or gaps where the {APPENDAGES[friend]} were, drawn in the same place, size, angle and style. "
              "Everything else stays exactly as it is: the head, face, body, the other clothes, the white sticker "
              "border and the drop shadow. Plain flat mid-grey background.")
    im, _, _ = nb.generate(prompt, [on_grey(src, ASPECTS[aspect])], aspect, "1K")
    im.save(out)


def appendage_masks(friend, kind, frames):
    """Per base frame, the parts that pass in front of or through a hat, painted magenta once and cached."""
    folder = os.path.join(ANIM, friend, "appendages")
    os.makedirs(folder, exist_ok=True)
    jobs = {}
    with cf.ThreadPoolExecutor(4) as ex:
        for i, frame in enumerate(frames):
            path = os.path.join(folder, f"{kind}-{i}.png")
            if not os.path.exists(path):
                jobs[ex.submit(paint_mask, frame, f"{APPENDAGES[friend]} (only those, nothing else)", path)] = i
        for f in cf.as_completed(jobs):
            f.result()
    return [magenta(os.path.join(folder, f"{kind}-{i}.png"), frame) for i, frame in enumerate(frames)]


def paint_bare(frame, friend, out):
    import nb
    who, _, accessory, _ = CAST[friend]
    aspect = closest_aspect(*frame.size)
    prompt = (f"Repaint this sticker of {who} exactly, but without its {accessory}: where the {accessory} was, "
              "its own fur, feathers or skin continues naturally, with the same colours, markings, texture, shading "
              "and fine ink lines as the rest of it. Everything else stays exactly as it is: the pose, head, face, "
              "expression, ears, body, the white sticker border and the drop shadow, at the same size and position. "
              "Plain flat mid-grey background, nothing else, no text.")
    im, _, _ = nb.generate(prompt, [on_grey(frame, ASPECTS[aspect])], aspect, "1K")
    im.save(out)


def bare_frames(friend, kind, frames):
    """Each base frame with its built-in accessory painted out, from that frame's own repaint, cached per friend."""
    folder = os.path.join(ANIM, friend, "bare")
    os.makedirs(folder, exist_ok=True)
    jobs = []
    with cf.ThreadPoolExecutor(4) as ex:
        for i, frame in enumerate(frames):
            bare, where = (os.path.join(folder, f"{kind}-{i}{x}.png") for x in ("", "-mask"))
            if not os.path.exists(bare):
                jobs.append(ex.submit(paint_bare, frame, friend, bare))
            if not os.path.exists(where):
                jobs.append(ex.submit(paint_mask, frame, CAST[friend][2], where))
        for f in cf.as_completed(jobs):
            f.result()
    out = []
    for i, frame in enumerate(frames):
        where = magenta(os.path.join(folder, f"{kind}-{i}-mask.png"), frame)
        out.append(patch(frame, keyed_raw(os.path.join(folder, f"{kind}-{i}.png")), where))
    return out


def grow_into(where, frame, reach=20):
    """Painted masks miss fringes and outlines now and then; take in nearby pixels of the accessory's own colour."""
    f = np.asarray(frame).astype(np.float32)
    ref = f[..., :3][where]
    if not len(ref):
        return where
    lo, hi = np.percentile(ref, 3, 0), np.percentile(ref, 97, 0)
    like = np.all((f[..., :3] > lo - 12) & (f[..., :3] < hi + 12), 2)
    dark = f[..., :3].mean(2) < 110
    near = ndi.binary_dilation(where, iterations=reach)
    grown = where | (near & (like | dark) & ndi.binary_dilation(where | (near & like), iterations=2))
    return ndi.binary_closing(grown, iterations=2)


def sharpen_to(r, f, ring, region):
    """Unsharp the repaint until its fine detail in the ring matches the frame's."""
    def energy(a):
        g = a[..., :3].mean(2)
        return np.abs(g - ndi.gaussian_filter(g, 1.2))[ring].mean()
    target = energy(f)
    out = r
    for amount in np.linspace(0, 2.5, 11):
        blur = ndi.gaussian_filter(r[..., :3], (1.2, 1.2, 0))
        test = r.copy()
        test[..., :3] = r[..., :3] + amount * (r[..., :3] - blur)
        out = test
        if energy(test) >= target:
            break
    return out


def patch(frame, repaint, where):
    """The frame, with only the accessory's area taken from its own bare repaint, snapped and tone matched."""
    where = grow_into(where, frame)
    grown = ndi.binary_dilation(where, iterations=3)
    fitted, _ = fit_to(repaint, frame, cut=0)
    f = np.asarray(frame).astype(np.float32)
    r = np.asarray(fitted).astype(np.float32)
    ring = ndi.binary_dilation(grown, iterations=14) & ~grown & (f[..., 3] > 200) & (r[..., 3] > 200)
    best = None
    for dy in range(-4, 5):
        for dx in range(-4, 5):
            m = np.roll(np.roll(r, dy, 0), dx, 1)
            c = np.abs(m[..., :3] - f[..., :3]).mean(2)[ring].mean()
            if best is None or c < best[0]:
                best = (c, dx, dy)
    r = np.roll(np.roll(r, best[2], 0), best[1], 1)
    r = sharpen_to(r, f, ring, grown)
    ring = ndi.binary_dilation(grown, iterations=8) & ~grown & (f[..., 3] > 200) & (r[..., 3] > 200)
    ring &= ndi.binary_erosion(f[..., 3] > 200, iterations=8) & (f[..., :3].min(2) < 215)
    for c in range(3):
        fm, fs = f[..., c][ring].mean(), f[..., c][ring].std() + 1e-3
        rm, rs = r[..., c][ring].mean(), r[..., c][ring].std() + 1e-3
        r[..., c] = (r[..., c] - rm) * (fs / rs) + fm
    a = np.clip(ndi.gaussian_filter(grown.astype(np.float32), 1.5), 0, 1)[..., None] * (r[..., 3:4] / 255)
    rgb = r[..., :3] * a + f[..., :3] * (1 - a)
    return Image.fromarray(np.dstack([rgb, f[..., 3:4]]).clip(0, 255).astype(np.uint8), "RGBA")


def item_mask(folder, friend, item, target, name="mask-0.png"):
    """The item alone, grown to take its rim and shadow, feathered."""
    mask = magenta(os.path.join(folder, name), target)
    grown = ndi.binary_dilation(mask, iterations=4)
    return np.clip(ndi.gaussian_filter(grown.astype(np.float32), 1.5), 0, 1)


def head_motion(base_rest, frame, mask, reach=18, turns=(-8, -6, -4, -2, 0, 2, 4, 6, 8), skip=None):
    """Shift and turn that carries the rest pose onto this frame around the item (the head it rides on)."""
    region = ndi.binary_dilation(mask > 0.2, iterations=30)
    ys, xs = np.nonzero(region)
    cy, cx = ys.mean(), xs.mean()
    grey = lambda im: ndi.gaussian_filter(np.asarray(im).astype(np.float32)[..., :3].mean(2)
                                          * (np.asarray(im)[..., 3] > 128), 1.5)
    src, dst = grey(base_rest), grey(frame)
    keep = region & ~ndi.binary_dilation(mask > 0.2, iterations=4)
    keep[: int(cy)] = False
    keep[int(cy) + 90:] = False
    if skip is not None:
        keep &= ~ndi.binary_dilation(skip, iterations=4)
    keep &= (np.asarray(frame)[..., 3] > 128) & (np.asarray(base_rest)[..., 3] > 128)
    best = None
    for turn in turns:
        rot = ndi.rotate(src, turn, reshape=False, order=1) if turn else src
        rot = shift_about(rot, turn, cx, cy, src.shape)
        for dy in range(-reach, reach + 1, 2):
            for dx in range(-reach, reach + 1, 2):
                m = np.roll(np.roll(rot, dy, 0), dx, 1)
                c = np.abs(m - dst)[keep].mean()
                if best is None or c < best[0]:
                    best = (c, turn, dx, dy)
    _, turn, dx0, dy0 = best
    for dy in range(dy0 - 2, dy0 + 3):
        for dx in range(dx0 - 2, dx0 + 3):
            rot = shift_about(ndi.rotate(src, turn, reshape=False, order=1) if turn else src, turn, cx, cy, src.shape)
            c = np.abs(np.roll(np.roll(rot, dy, 0), dx, 1) - dst)[keep].mean()
            if c < best[0]:
                best = (c, turn, dx, dy)
    return best[1:], (cx, cy)


def shift_about(rotated, turn, cx, cy, shape):
    """ndi.rotate turns about the image centre; move it so the turn is about the item's centre instead."""
    if not turn:
        return rotated
    h, w = shape
    t = np.deg2rad(turn)
    ox, oy = cx - w / 2, cy - h / 2
    nx = ox * np.cos(t) + oy * np.sin(t)
    ny = -ox * np.sin(t) + oy * np.cos(t)
    return ndi.shift(rotated, (oy - ny, ox - nx), order=1)


def move(layer, motion, centre):
    (turn, dx, dy), (cx, cy) = motion, centre
    out = []
    for c in range(layer.shape[2]):
        ch = layer[..., c]
        if turn:
            ch = shift_about(ndi.rotate(ch, turn, reshape=False, order=3), turn, cx, cy, ch.shape)
        out.append(np.roll(np.roll(ch, dy, 0), dx, 1))
    return np.dstack(out)


OVERLAP = 5


def transplant(dressed, base_rest, frame, mask, appendages=None, rest_appendages=None):
    """The base frame, whole, with the item from the dressed rest laid over it where the head has moved to.

    With appendages, the whole item goes on and that frame's own ears (or stalks, antennae) go back over it, so
    they come out through the item in whatever pose the frame has. The item's white rim is kept only outside the
    frame's own silhouette, where it is the sticker's edge."""
    skip = appendages if appendages is not None else None
    if skip is not None and rest_appendages is not None:
        skip = skip | rest_appendages
    motion, centre = head_motion(base_rest, frame, mask, skip=skip)
    item = np.dstack([np.asarray(dressed).astype(np.float32), mask[..., None] * 255])
    moved = move(item, motion, centre)
    f = np.asarray(frame).astype(np.float32)
    a = (moved[..., 4] / 255) * (moved[..., 3] / 255)
    white = moved[..., :3].min(2) > 222
    inside = ndi.binary_erosion(f[..., 3] > 128, iterations=2)
    a = ndi.gaussian_filter(a * ~(white & inside), 0.6)
    if appendages is not None:
        hat = a > 0.5
        rows = np.arange(hat.shape[0])[:, None]
        top = np.where(hat.any(0), np.argmax(hat, 0), hat.shape[0])[None, :]
        above = np.clip((top + OVERLAP - rows) / 3.0, 0, 1)
        ears = np.clip(ndi.gaussian_filter(ndi.binary_dilation(appendages, iterations=1).astype(np.float32), 1.0), 0, 1)
        a = a * (1 - ears * above)
    a = a[..., None]
    rgb = moved[..., :3] * a + f[..., :3] * (1 - a)
    alpha = np.maximum(f[..., 3:4], a * 255)
    return Image.fromarray(np.dstack([rgb, alpha]).clip(0, 255).astype(np.uint8), "RGBA"), motion


def anim_gen(friend, item_id, whats):
    item = item_named(friend, item_id)
    (idle_name, idle_count, _), (hop_name, hop_count, _) = STRIPS[friend]["idle"], STRIPS[friend]["hop"]
    idle, hops = cells(idle_name, idle_count), cells(hop_name, hop_count)
    look = Image.open(os.path.join(RES, f"look-{friend}-{item_id}.webp")).convert("RGBA")
    folder = os.path.join(ANIM, friend, item_id)
    jobs = []
    if "rest" in whats:
        print(anim_gen_one(friend, item, "rest", 0, idle[0], look), flush=True)
    if "whole" in whats:
        paint_whole(keyed_raw(os.path.join(folder, "rest-0.png")), friend, item, os.path.join(folder, "whole-0.png"))
        name, _ = wearing(friend, item)
        paint_mask(keyed_raw(os.path.join(folder, "whole-0.png")), name, os.path.join(folder, "whole-mask.png"))
        print(f"{friend}/{item_id} whole item", flush=True)
    if "mask" in whats:
        name, _ = wearing(friend, item)
        paint_mask(keyed_raw(os.path.join(folder, "rest-0.png")), name, os.path.join(folder, "mask-0.png"))
        print(f"{friend}/{item_id} masks", flush=True)
    rest_path = os.path.join(folder, "rest-0.png")
    rest = keyed_raw(rest_path) if os.path.exists(rest_path) else look
    with cf.ThreadPoolExecutor(4) as ex:
        if "idle" in whats:
            jobs += [ex.submit(anim_gen_one, friend, item, "idle", i, idle[i], rest) for i in range(1, idle_count)]
        if "hop" in whats:
            jobs += [ex.submit(anim_gen_one, friend, item, "hop", i, hops[i], rest) for i in range(hop_count)]
        for f in cf.as_completed(jobs):
            try:
                print(f.result(), flush=True)
            except SystemExit as e:
                print("failed:", e, flush=True)


def item_only(friend, item, folder):
    """The worn item alone, cut from the dressed rest by its magenta mask, as a reference with no pose in it."""
    rest = keyed_raw(os.path.join(folder, "rest-0.png"))
    m = magenta(os.path.join(folder, "mask-0.png"), rest)
    a = np.asarray(rest).astype(np.float32)
    a[..., 3] *= ndi.binary_dilation(m, iterations=3)
    im = Image.fromarray(a.clip(0, 255).astype(np.uint8), "RGBA")
    return im.crop(bbox(np.asarray(im)[..., 3] > 8))


def overlay(frame, item_rgba, alpha):
    f = np.asarray(frame).astype(np.float32)
    it = np.asarray(item_rgba).astype(np.float32)
    a = (alpha * it[..., 3] / 255)[..., None]
    rgb = it[..., :3] * a + f[..., :3] * (1 - a)
    out = np.dstack([rgb, np.maximum(f[..., 3:4], a * 255)])
    return Image.fromarray(out.clip(0, 255).astype(np.uint8), "RGBA")


def own_frame_item(friend, item, folder, i, frame):
    """The item painted onto this very frame, cut out by its own magenta mask, laid on the untouched frame."""
    raw, where = (os.path.join(folder, f"idle-{i}{x}.png") for x in ("", "-mask"))
    rest = keyed_raw(os.path.join(folder, "rest-0.png"))
    if not os.path.exists(raw):
        anim_gen_one(friend, item, "idle", i, frame, rest)
    painted = keyed_raw(raw)
    if not os.path.exists(where):
        paint_mask(painted, wearing(friend, item)[0], where)
    fitted, _ = fit_to(painted, frame, cut=0)
    m = magenta(where, frame)
    soft = np.clip(ndi.gaussian_filter(ndi.binary_dilation(m, iterations=3).astype(np.float32), 1.5), 0, 1)
    return overlay(frame, fitted, soft)


def tips(antennae, near, reach=90):
    """The antenna point near `near` that is furthest from where the antennae meet the head."""
    ys, xs = np.nonzero(antennae)
    if not len(ys):
        return None
    root = np.array([ys[ys > np.percentile(ys, 90)].mean(), xs[ys > np.percentile(ys, 90)].mean()])
    close = (ys - near[0]) ** 2 + (xs - near[1]) ** 2 < reach ** 2
    if not close.any():
        return None
    d = (ys[close] - root[0]) ** 2 + (xs[close] - root[1]) ** 2
    k = np.argmax(d)
    return np.array([ys[close][k], xs[close][k]])


def on_tips(rest, frame, mask, rest_antennae, antennae):
    """Each pom rides its own antenna tip: moved by how far that tip moved from the rest pose."""
    lab, n = ndi.label(mask > 0.3)
    out = frame
    for c in range(1, n + 1):
        part = lab == c
        if part.sum() < 60:
            continue
        cy, cx = np.nonzero(part)
        centre = np.array([cy.mean(), cx.mean()])
        t0 = tips(rest_antennae, centre)
        t1 = tips(antennae, t0 if t0 is not None else centre)
        dy, dx = (np.round(t1 - t0).astype(int) if t0 is not None and t1 is not None else (0, 0))
        soft = np.clip(ndi.gaussian_filter(ndi.binary_dilation(part, iterations=2).astype(np.float32), 1.2), 0, 1)
        layer = np.dstack([np.asarray(rest).astype(np.float32), soft[..., None] * 255])
        layer = np.roll(np.roll(layer, dy, 0), dx, 1)
        out = overlay(out, Image.fromarray(layer[..., :4].clip(0, 255).astype(np.uint8), "RGBA"), layer[..., 4] / 255)
    return out


def anim_all(friend, ids):
    """Everything a look needs, skipping what is already painted, then the strips and the heads board."""
    for item_id in ids:
        item = item_named(friend, item_id)
        folder = os.path.join(ANIM, friend, item_id)
        os.makedirs(folder, exist_ok=True)
        need = [w for w, f in (("rest", "rest-0.png"), ("mask", "mask-0.png")) if not os.path.exists(os.path.join(folder, f))]
        if item["slot"] in THROUGH and friend in APPENDAGES and not os.path.exists(os.path.join(folder, "whole-mask.png")):
            need.append("whole")
        if any(not os.path.exists(os.path.join(folder, f"hop-{i}.png")) for i in range(8)):
            need.append("hop")
        for step in ("rest", "mask", "whole"):
            if step in need:
                anim_gen(friend, item_id, [step])
        if "hop" in need:
            anim_gen(friend, item_id, ["hop"])
        report = anim_build(friend, item_id)
        weak = [i for i in range(8) if report.get(f"hop-{i}", 1) < 0.85]
        if weak:
            hops = cells(STRIPS[friend]["hop"][0], 8)
            ref = item_only(friend, item, folder)
            with cf.ThreadPoolExecutor(4) as ex:
                list(ex.map(lambda i: anim_gen_one(friend, item, "hop-item", i, hops[i], ref, POSE), weak))
            report = anim_build(friend, item_id)
        print(json.dumps({k: v for k, v in report.items() if k.startswith("hop")}), flush=True)
        print(item_id, "sticker", sticker_from_rest(friend, item_id), flush=True)
        anim_heads(friend, item_id, os.path.join(SCRATCH, f"heads-{friend}-{item_id}.png"))


def check_items(strip, base_cells, label, floor=0.6):
    """Every dressed frame must carry the item: its changed area stays near frame 0's."""
    w = base_cells[0].width
    areas = []
    for i, b in enumerate(base_cells):
        d = np.asarray(strip.crop((i * w, 0, (i + 1) * w, strip.height))).astype(np.int16)
        areas.append(int((np.abs(d - np.asarray(b).astype(np.int16)).max(2) > 40).sum()))
    low = [i for i, a in enumerate(areas) if a < floor * areas[0]]
    if low:
        raise SystemExit(f"{label}: frames {low} lost the item (changed area {areas})")
    return areas


ANCHORS = os.path.join(ROOT, "Design", "friends", "wardrobe-anchors.json")


def anchors(friend):
    path = ANCHORS if os.path.exists(ANCHORS) else os.path.join(HERE, "nb", "anchors.json")
    return json.load(open(path))[friend]["anchors"]


def cell_to_sticker(friend):
    """Scale and offset that lay idle frame 0 exactly over the base sitting sticker."""
    f0 = cells(*STRIPS[friend]["idle"][:2])[0]
    fa = np.asarray(f0)[..., 3] > 128
    x0, y0, x1, y1 = bbox(fa)
    crop = f0.crop((x0, y0, x1, y1))
    b = base(friend)
    ba = np.asarray(b)[..., 3] > 128
    bx0, by0, bx1, by1 = bbox(ba)
    H, W = ba.shape
    best = None
    s0 = (by1 - by0) / (y1 - y0)
    ga = np.asarray(crop)[..., 3] > 128
    for sc in s0 * np.linspace(0.96, 1.04, 17):
        w, h = int(crop.width * sc), int(crop.height * sc)
        m = np.asarray(Image.fromarray(ga.astype(np.uint8) * 255).resize((w, h), Image.BILINEAR)) > 128
        for dy in range(-6, 7):
            oy = by1 - h + dy
            for dx in range(-10, 11):
                ox = (bx0 + bx1) // 2 - w // 2 + dx
                c = np.zeros((H + 2 * h, W + 2 * w), bool)
                c[oy + h:oy + 2 * h, ox + w:ox + 2 * w] = m
                c = c[h:h + H, w:w + W]
                iou = (c & ba).sum() / max((c | ba).sum(), 1)
                if best is None or iou > best[0]:
                    best = (iou, sc, ox - x0 * sc, oy - y0 * sc)
    return best


def sticker_from_rest(friend, item_id):
    """The sitting sticker is the dressed idle's frame 0, laid where the base sticker is."""
    iou, sc, ox, oy = cell_to_sticker(friend)
    name, count, _ = STRIPS[friend]["idle"]
    dressed = cells(f"look-{friend}-{item_id}-idle", count)[0]
    plain = cells(name, count)[0]
    b = base(friend)
    W, H = b.size

    def place(cell):
        big = cell.resize((round(cell.width * sc), round(cell.height * sc)), Image.LANCZOS)
        layer = Image.new("RGBA", (W + 2 * big.width, H + 2 * big.height), (0, 0, 0, 0))
        layer.alpha_composite(big, (round(ox) + big.width, round(oy) + big.height))
        full = np.asarray(layer)[..., 3] > 128
        inner = full[big.height:big.height + H, big.width:big.width + W]
        spill = full.sum() - inner.sum()
        return layer.crop((big.width, big.height, big.width + W, big.height + H)), spill
    sticker, spill = place(dressed)
    if spill > RIM * (W + H):
        raise SystemExit(f"{friend}/{item_id}: rest pose spills {spill}px past the sticker canvas")
    plain_sticker, _ = place(plain)
    old_path = os.path.join(RES, f"look-{friend}-{item_id}.webp")
    old = np.asarray(Image.open(old_path).convert("RGBA")).astype(np.int16) if os.path.exists(old_path) else None
    item = ndi.binary_opening(np.abs(np.asarray(sticker).astype(np.int16)
                                     - np.asarray(plain_sticker).astype(np.int16)).max(2) > 40, iterations=2)
    placed = check_anchor(friend, item_named(friend, item_id), item, W, H)
    sticker.save(old_path, "WEBP", quality=90, method=6)
    change = float(np.abs(np.asarray(sticker).astype(np.int16) - old).max(2).__gt__(60).mean()) if old is not None else 1
    return {"fit": round(float(iou), 3), "changed": round(change, 3), "anchor": placed}


def check_anchor(friend, item, mask, W, H):
    slot = item["slot"]
    spot = anchors(friend).get(slot)
    if spot is None or not mask.any():
        return "no anchor" if spot is None else "no item"
    pair = anchors(friend).get(slot + "2")
    if pair:
        spot = {"x": (spot["x"] + pair["x"]) / 2, "y": (spot["y"] + pair["y"]) / 2}
    ax, ay = spot["x"] * W, spot["y"] * H
    ys, xs = np.nonzero(mask)
    if slot == "head":
        d = np.sqrt(((xs - ax) ** 2 + (ys - ay) ** 2).min())
        limit = 0.12 * W
    else:
        d = np.hypot(xs.mean() - ax, ys.mean() - ay)
        limit = (0.24 if slot in ("body", "antennae") else 0.18) * W
    if d > limit:
        raise SystemExit(f"{friend}/{item['id']}: {slot} item sits {d:.0f}px from its anchor (limit {limit:.0f})")
    return round(float(d / W), 3)


def anim_build(friend, item_id):
    (idle_name, idle_count, _), (hop_name, hop_count, _) = STRIPS[friend]["idle"], STRIPS[friend]["hop"]
    item = item_named(friend, item_id)
    idle, hops = cells(idle_name, idle_count), cells(hop_name, hop_count)
    folder = os.path.join(ANIM, friend, item_id)
    report = {}
    rest, iou = fit_to(keyed_raw(os.path.join(folder, "rest-0.png")), idle[0], cut=0)
    report["rest"] = round(float(iou), 3)
    replaces = item["slot"] == CAST[friend][3]
    base_idle = bare_frames(friend, "idle", idle) if replaces else idle
    mask = item_mask(folder, friend, item, idle[0])
    snap, centre = head_motion(rest, base_idle[0], mask, reach=6, turns=(-2, -1, 0, 1, 2))
    rest = Image.fromarray(move(np.asarray(rest).astype(np.float32), snap, centre).clip(0, 255).astype(np.uint8))
    mask = move(mask[..., None], snap, centre)[..., 0]
    Image.fromarray((mask * 255).astype(np.uint8)).save(os.path.join(folder, "mask.png"))
    ears = [None] * idle_count
    whole_path = os.path.join(folder, "whole-0.png")
    if item["slot"] in THROUGH and friend in APPENDAGES and os.path.exists(whole_path):
        whole, _ = fit_to(keyed_raw(whole_path), idle[0], cut=int(idle[0].height * 0.45))
        whole_mask = item_mask(folder, friend, item, idle[0], "whole-mask.png")
        if (whole_mask > 0.5).sum() > 1.5 * (mask > 0.5).sum():
            whole_path = None
    if whole_path and item["slot"] in THROUGH and friend in APPENDAGES and os.path.exists(whole_path):
        snap, centre = head_motion(whole, idle[0], whole_mask, reach=6, turns=(-2, -1, 0, 1, 2))
        rest = Image.fromarray(move(np.asarray(whole).astype(np.float32), snap, centre).clip(0, 255).astype(np.uint8))
        mask = move(whole_mask[..., None], snap, centre)[..., 0]
        ears = appendage_masks(friend, "idle", idle)
    if item["slot"] == "antennae":
        ears = appendage_masks(friend, "idle", idle)
    strip = Image.new("RGBA", (idle[0].width * idle_count, idle[0].height), (0, 0, 0, 0))
    region = ndi.binary_dilation(mask > 0.2, iterations=8)
    a0 = np.asarray(base_idle[0]).astype(np.float32)
    for i in range(idle_count):
        change = np.abs(np.asarray(base_idle[i]).astype(np.float32) - a0).max(2)[region].mean()
        if item["slot"] == "antennae" and i:
            frame = own_frame_item(friend, item, folder, i, base_idle[i])
            report[f"idle-{i}"] = "own"
        elif item["slot"] == "antennae":
            frame = overlay(base_idle[0], rest, mask)
            report["idle-0"] = "rest"
        elif item["slot"] == "claws" and i and change > 12:
            frame = own_frame_item(friend, item, folder, i, base_idle[i])
            report[f"idle-{i}"] = "own"
        else:
            frame, motion = transplant(rest, base_idle[0], base_idle[i], mask, ears[i], ears[0])
            report[f"idle-{i}"] = list(map(int, motion))
        strip.alpha_composite(frame, (i * idle[0].width, 0))
    check_items(strip, idle, f"{friend}/{item_id} idle")
    strip.save(os.path.join(RES, f"look-{friend}-{item_id}-idle.webp"), "WEBP", quality=90, method=6)
    strip = Image.new("RGBA", (hops[0].width * hop_count, hops[0].height), (0, 0, 0, 0))
    for i in range(hop_count):
        path = os.path.join(folder, f"hop-{i}.png")
        try:
            frame, iou = fit_to(keyed_raw(path), hops[i]) if os.path.exists(path) else (hops[i], 0)
        except SystemExit:
            frame, iou = hops[i], 0
        report[f"hop-{i}"] = round(float(iou), 3)
        strip.alpha_composite(frame, (i * hops[0].width, 0))
    strip.save(os.path.join(RES, f"look-{friend}-{item_id}-hop.webp"), "WEBP", quality=90, method=6)
    return report


HEADS = {"hare": {"idle": (0, 0, 260, 200), "hop": None}}


def moving_box(frames, pad=24):
    a0 = np.asarray(frames[0]).astype(np.float32)
    moved = np.zeros(a0.shape[:2], bool)
    for f in frames[1:]:
        a = np.asarray(f).astype(np.float32)
        moved |= (np.abs(a - a0).max(2) > 40)
    moved = ndi.binary_opening(moved, iterations=2)
    if not moved.any():
        return None
    x0, y0, x1, y1 = bbox(moved)
    h, w = moved.shape
    return max(0, x0 - pad), max(0, y0 - pad), min(w, x1 + pad), min(h, y1 + pad)


def anim_heads(friend, item_id, path):
    rows = []
    for key in ("idle", "hop"):
        name, count, _ = STRIPS[friend][key]
        base_cells = cells(name, count)
        dressed = cells(f"look-{friend}-{item_id}-{key}", count)
        box = HEADS.get(friend, {}).get(key) if friend in HEADS else (moving_box(base_cells) if key == "idle" else None)
        crop = (lambda im: im.crop(box)) if box else (lambda im: im)
        for strip in (base_cells, dressed):
            row = [crop(c) for c in strip]
            rows.append(row)
    width = max(sum(c.width + 6 for c in r) for r in rows)
    sheet = Image.new("RGBA", (width, sum(r[0].height + 10 for r in rows)), (150, 150, 150, 255))
    y = 0
    for i, r in enumerate(rows):
        x = 0
        for n, c in enumerate(r):
            sheet.alpha_composite(c, (x, y))
            x += c.width + 6
        y += r[0].height + (24 if i % 2 else 4)
    sheet.convert("RGB").save(path)


def anim_board(friend, item_id, path):
    rows = []
    for key in ("idle", "hop"):
        name, count, _ = STRIPS[friend][key]
        rows.append(Image.open(os.path.join(RES, name + ".webp")).convert("RGBA"))
        rows.append(Image.open(os.path.join(RES, f"look-{friend}-{item_id}-{key}.webp")).convert("RGBA"))
    width = max(r.width for r in rows)
    sheet = Image.new("RGBA", (width, sum(r.height + 8 for r in rows)), (150, 150, 150, 255))
    y = 0
    for r in rows:
        sheet.alpha_composite(r, (0, y))
        y += r.height + 8
    sheet.convert("RGB").save(path)


if __name__ == "__main__":
    step, friend, *ids = sys.argv[1:]
    if step.startswith("anim"):
        _count_calls()
    if step == "gen":
        with cf.ThreadPoolExecutor(4) as ex:
            for f in cf.as_completed([ex.submit(gen_one, friend, i) for i in pick(friend, ids)]):
                try:
                    print(f.result(), flush=True)
                except SystemExit as e:
                    print("failed:", e, flush=True)
    elif step == "redraw":
        with cf.ThreadPoolExecutor(4) as ex:
            for f in cf.as_completed([ex.submit(redraw_one, friend, i) for i in pick(friend, ids)]):
                try:
                    print(f.result(), flush=True)
                except SystemExit as e:
                    print("failed:", e, flush=True)
    elif step == "build":
        fit_path = os.path.join(RAW, "fit.json")
        fit = json.load(open(fit_path)) if os.path.exists(fit_path) else {}
        failed = False
        for i in pick(friend, ids):
            if os.path.exists(os.path.join(RAW, friend, f"{i['id']}.png")):
                try:
                    print(build_one(friend, i, fit), flush=True)
                except SystemExit as e:
                    print("FAILED", e, flush=True)
                    failed = True
        json.dump(fit, open(fit_path, "w"), indent=1)
        if failed:
            sys.exit(1)
    elif step == "board":
        board(friend, ids[0])
    elif step == "anim-gen":
        anim_gen(friend, ids[0], ids[1:] or ["rest", "idle", "hop"])
    elif step == "anim-build":
        print(json.dumps(anim_build(friend, ids[0])), flush=True)
    elif step == "anim-all":
        anim_all(friend, ids)
    elif step == "anim-sticker":
        for item_id in ids:
            try:
                print(item_id, sticker_from_rest(friend, item_id), flush=True)
            except SystemExit as e:
                print("FAILED", e, flush=True)
    elif step == "anim-check":
        for item_id in ids:
            name, count, _ = STRIPS[friend]["idle"]
            strip = Image.open(os.path.join(RES, f"look-{friend}-{item_id}-idle.webp")).convert("RGBA")
            print(item_id, check_items(strip, cells(name, count), item_id), flush=True)
    elif step == "anim-heads":
        anim_heads(friend, ids[0], ids[1])
    elif step == "anim-board":
        anim_board(friend, ids[0], ids[1])
