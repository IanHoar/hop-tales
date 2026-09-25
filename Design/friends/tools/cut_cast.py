"""Cut the Nano Banana sheets into canvas assets for the cast canvas."""
import os, json
import numpy as np
from PIL import Image
from scipy import ndimage as ndi

HERE = os.path.dirname(os.path.abspath(__file__))
NB = os.path.join(HERE, "nb", "cast")
P = os.path.join(HERE, "..", "cast-canvas", "project", "cast")
for d in ("chars", "sprites", "worlds", "items", "wear", "dress"):
    os.makedirs(os.path.join(P, d), exist_ok=True)


def cut(path, min_area=12000, rows=2):
    a = np.asarray(Image.open(path).convert("RGB")).astype(np.float32)
    bg = np.median(a[:10].reshape(-1, 3), 0)
    d = np.sqrt(((a - bg) ** 2).sum(2))
    cand = d < 22
    lab, _ = ndi.label(cand)
    edge = np.unique(np.concatenate([lab[:4][cand[:4]], lab[-4:][cand[-4:]], lab[:, :4][cand[:, :4]], lab[:, -4:][cand[:, -4:]]]))
    edge = edge[edge > 0]
    fg = ndi.binary_fill_holes(~np.isin(lab, edge))
    # background showing through holes (rings, straps, handles): key those out too
    tight = d < 16
    hl, hn = ndi.label(tight & fg)
    if hn:
        areas = ndi.sum(np.ones_like(d), hl, index=np.arange(1, hn + 1))
        big = np.nonzero(areas > 600)[0] + 1
        for h in big:
            hole = hl == h
            ring = ndi.binary_dilation(hole, iterations=4) & ~hole
            # a real hole is framed by the white paper rim; grey paint inside an item is not
            if a[ring].min(1).mean() > 132:
                fg &= ~hole
    fg = ndi.binary_opening(fg, iterations=2)
    lab, n = ndi.label(fg)
    parts = []
    for i in range(1, n + 1):
        m = lab == i
        if m.sum() < min_area:
            continue
        al = ndi.gaussian_filter(m.astype(np.float32), 0.8)
        al[ndi.binary_erosion(m, iterations=2)] = 1
        ys, xs = np.nonzero(m)
        y0, y1, x0, x1 = ys.min(), ys.max() + 1, xs.min(), xs.max() + 1
        parts.append(((y0 + y1) / 2, (x0 + x1) / 2, np.dstack([a, al * 255])[y0:y1, x0:x1]))
    rh = a.shape[0] / rows
    parts.sort(key=lambda t: (int(t[0] / rh), t[1]))
    return [p[2] for p in parts]


def to_img(arr):
    return Image.fromarray(arr.clip(0, 255).astype(np.uint8), "RGBA")


def save(im, path, maxw=None, maxh=None):
    if maxw or maxh:
        s = min((maxw or 9e9) / im.width, (maxh or 9e9) / im.height, 1)
        im = im.resize((round(im.width * s), round(im.height * s)), Image.LANCZOS)
    if path.endswith(".webp"):
        im.save(path, quality=86, method=6)
    else:
        im.save(path, optimize=True)
    return im.size


LIFT = {"frog": [0, 0, -40, -90, -60, -10, 0, 0], "crow": [0, 0, -20, -70, -50, 0, 0, 0], "cat": [0, 0, -10, -60, -40, 0, 0, 0],
        "crab": [0, 0, -30, -60, -30, 0, 0, 0], "grasshopper": [0, 0, -60, -130, -110, -50, 0, 0], "bunny": [0, 0, -30, -60, -30, 0, 0, 0]}
CAST = ["frog", "crow", "cat", "crab", "grasshopper", "bunny"]
meta = {}
for k in CAST:
    est = cut(os.path.join(NB, f"est_{k}.png"))
    est = max(est, key=lambda f: f.shape[0] * f.shape[1])
    meta.setdefault(k, {})["sit"] = save(to_img(est), os.path.join(P, "chars", f"{k}.png"), 420, 420)
    src = "hop2_bunny.png" if k == "bunny" else f"hop_{k}.png"
    fr = cut(os.path.join(NB, src), 20000)
    if k == "crab":
        fr = fr[:7] + [fr[0]]
    fr = fr[:8]
    assert len(fr) == 8, (k, len(fr))
    lift = LIFT[k]
    cen = [np.nonzero(f[..., 3] > 128)[1].mean() for f in fr]
    maxw = max(f.shape[1] for f in fr)
    ox = [int(maxw / 2 - c) for c in cen]
    mn = min(ox)
    ox = [o - mn for o in ox]
    pad = 20
    W = max(f.shape[1] + o for f, o in zip(fr, ox)) + pad * 2
    H = max(f.shape[0] - l for f, l in zip(fr, lift)) + pad * 2
    cells = []
    for f, o, l in zip(fr, ox, lift):
        c = np.zeros((H, W, 4), np.float32)
        y0 = H - pad - f.shape[0] + l
        c[y0:y0 + f.shape[0], pad + o:pad + o + f.shape[1]] = f
        cells.append(c)
    s = 220 / H
    w, h = round(W * s), round(H * s)
    sheet = Image.new("RGBA", (w * 8, h))
    for i, c in enumerate(cells):
        sheet.alpha_composite(to_img(c).resize((w, h), Image.LANCZOS), (i * w, 0))
    sheet.save(os.path.join(P, "sprites", f"{k}-hop.webp"), quality=86, method=6)
    meta[k]["hop"] = [w, h]
    wi = Image.open(os.path.join(NB, f"world_{k}.png")).convert("RGB")
    wi.resize((1400, round(1400 * wi.height / wi.width)), Image.LANCZOS).save(os.path.join(P, "worlds", f"{k}.jpg"), quality=82)

names_c = ["carrot", "lily", "yarn", "shell", "clover", "strawberry", "basket", "rosette", "carrot-gold", "button", "clover-four", "star"]
it = cut(os.path.join(NB, "items_collect.png"), 8000, rows=3)
assert len(it) == 12, len(it)
for n, f in zip(names_c, it):
    meta.setdefault("items", {})[n] = save(to_img(f), os.path.join(P, "items", f"{n}.png"), 200, 200)
names_w = ["straw", "bobble", "crown", "acorn", "paper-crown", "wizard", "pirate", "specs", "bowtie", "neckerchief", "satchel", "cape"]
it = cut(os.path.join(NB, "items_wear.png"), 8000, rows=3)
assert len(it) == 12, len(it)
for n, f in zip(names_w, it):
    meta.setdefault("wear", {})[n] = save(to_img(f), os.path.join(P, "wear", f"{n}.png"), 200, 200)
hs = cut(os.path.join(HERE, "..", "collage-canvas", "project", "collage", "hare-sit.png")) if False else None
for k in ["straw", "bobble", "crown", "wizard", "pirate", "specs"]:
    f = cut(os.path.join(NB, f"dress_{k}.png"))
    f = max(f, key=lambda x: x.shape[0] * x.shape[1])
    meta.setdefault("dress", {})[k] = save(to_img(f), os.path.join(P, "dress", f"hare-{k}.png"), 340, 460)
json.dump(meta, open(os.path.join(P, "meta.json"), "w"), indent=1)
print(json.dumps(meta)[:1500])
