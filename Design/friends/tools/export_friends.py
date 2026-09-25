"""Build the Design/friends handoff folder (full-resolution assets, renders, canvas source, tools)."""
import os, sys, json, shutil, glob
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import numpy as np
from PIL import Image
import cut_cast as cc  # noqa: E402  (re-running it also refreshes the canvas assets; harmless)

HERE = os.path.dirname(os.path.abspath(__file__))
NB = os.path.join(HERE, "nb", "cast")
OUT = os.path.join(HERE, "..", "handoff", "Design", "friends")
shutil.rmtree(os.path.join(HERE, "..", "handoff"), ignore_errors=True)
for d in ("characters", "sprites", "worlds", "collectibles", "wardrobe", "reference/dressed", "reference/boards", "raw", "tools", "canvas"):
    os.makedirs(os.path.join(OUT, d), exist_ok=True)

meta = {"characters": {}, "sprites": {}, "collectibles": {}, "wardrobe": {}}
FPS = {"frog": 12, "crow": 12, "cat": 14, "crab": 16, "grasshopper": 14, "bunny": 14}
for k in cc.CAST:
    est = max(cc.cut(os.path.join(NB, f"est_{k}.png")), key=lambda f: f.shape[0] * f.shape[1])
    im = cc.to_img(est)
    im.save(os.path.join(OUT, "characters", f"{k}-sit.png"), optimize=True)
    meta["characters"][k] = list(im.size)
    src = "hop2_bunny.png" if k == "bunny" else f"hop_{k}.png"
    fr = cc.cut(os.path.join(NB, src), 20000)
    if k == "crab":
        fr = fr[:7] + [fr[0]]
    fr = fr[:8]
    lift = cc.LIFT[k]
    cen = [np.nonzero(f[..., 3] > 128)[1].mean() for f in fr]
    maxw = max(f.shape[1] for f in fr)
    ox = [int(maxw / 2 - c) for c in cen]
    mn = min(ox)
    ox = [o - mn for o in ox]
    pad = 20
    W = max(f.shape[1] + o for f, o in zip(fr, ox)) + pad * 2
    H = max(f.shape[0] - l for f, l in zip(fr, lift)) + pad * 2
    s = 440 / H
    w, h = round(W * s), round(H * s)
    sheet = Image.new("RGBA", (w * 8, h))
    for i, (f, o, l) in enumerate(zip(fr, ox, lift)):
        c = np.zeros((H, W, 4), np.float32)
        y0 = H - pad - f.shape[0] + l
        c[y0:y0 + f.shape[0], pad + o:pad + o + f.shape[1]] = f
        sheet.alpha_composite(cc.to_img(c).resize((w, h), Image.LANCZOS), (i * w, 0))
    sheet.save(os.path.join(OUT, "sprites", f"{k}-hop.png"), optimize=True)
    sheet.save(os.path.join(OUT, "sprites", f"{k}-hop.webp"), quality=90, method=6)
    meta["sprites"][k] = {"frame": [w, h], "frames": 8, "fps": FPS[k], "loop": False,
                          "note": "feet on a common baseline; air frames already lifted; body-centred, so play in place while the ground moves"}
    wi = Image.open(os.path.join(NB, f"world_{k}.png")).convert("RGB")
    wi.save(os.path.join(OUT, "worlds", f"{k}-postcard.jpg"), quality=92)

for n, f in zip(cc.names_c, cc.cut(os.path.join(NB, "items_collect.png"), 8000, rows=3)):
    im = cc.to_img(f)
    im.save(os.path.join(OUT, "collectibles", f"{n}.png"), optimize=True)
    meta["collectibles"][n] = list(im.size)
for n, f in zip(cc.names_w, cc.cut(os.path.join(NB, "items_wear.png"), 8000, rows=3)):
    im = cc.to_img(f)
    im.save(os.path.join(OUT, "wardrobe", f"{n}.png"), optimize=True)
    meta["wardrobe"][n] = list(im.size)
for k in ["straw", "bobble", "crown", "wizard", "pirate", "specs"]:
    f = max(cc.cut(os.path.join(NB, f"dress_{k}.png")), key=lambda x: x.shape[0] * x.shape[1])
    cc.to_img(f).save(os.path.join(OUT, "reference", "dressed", f"hare-{k}.png"), optimize=True)
json.dump(meta, open(os.path.join(OUT, "assets.json"), "w"), indent=1)

for p in sorted(glob.glob(os.path.join(NB, "*.png"))):
    n = os.path.basename(p)
    if n.startswith("world_"):
        Image.open(p).convert("RGB").save(os.path.join(OUT, "raw", n[:-4] + ".jpg"), quality=95)
    else:
        shutil.copy(p, os.path.join(OUT, "raw", n))

for n in ("gen_cast.py", "cut_cast.py", "export_friends.py", "cast_boards.py"):
    shutil.copy(os.path.join(HERE, n), os.path.join(OUT, "tools", n))
for p in sorted(glob.glob(os.path.join(HERE, "out", "cast", "*.png"))):
    Image.open(p).convert("RGB").save(os.path.join(OUT, "reference", "boards", os.path.basename(p)[:-4] + ".jpg"), quality=88)
shutil.copytree(os.path.join(HERE, "..", "cast-canvas", "project"), os.path.join(OUT, "canvas"), dirs_exist_ok=True)
os.remove(os.path.join(OUT, "canvas", "cast", "meta.json"))
print("ok")
