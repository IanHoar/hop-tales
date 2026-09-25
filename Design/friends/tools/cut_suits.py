"""Cut the wardrobe-suite sheets into per-friend item stickers (canvas size + full size for the handoff)."""
import os, json
from PIL import Image
import cut_cast as cc
from gen_suits import SUITS

HERE = os.path.dirname(os.path.abspath(__file__))
NB = os.path.join(HERE, "nb", "cast")
CAN = os.path.join(HERE, "..", "cast-canvas", "project", "cast", "suits")
FULL = os.path.join(HERE, "..", "handoff", "Design", "friends", "wardrobe-suites")

# top row of the cat sheet is good; the rest came from a four-item sheet
cat = Image.open(os.path.join(NB, "suit_cat.png"))
cat.crop((0, 0, cat.width, cat.height // 2)).save(os.path.join(NB, "suitq_cat_1.png"))

SRC = {"bunny": [("suitq_bunny_1.png", 1), ("suitq_bunny_2.png", 1)], "frog": [("suit_frog.png", 2)], "crow": [("suit_crow.png", 2)],
       "cat": [("suitq_cat_1.png", 1), ("suitq_cat_2.png", 1)], "crab": [("suitq_crab_1.png", 1), ("suitq_crab_2.png", 1)],
       "grasshopper": [("suitq_grasshopper_1.png", 1), ("suitq_grasshopper_2.png", 1)]}
meta = {}
for k, srcs in SRC.items():
    parts = []
    for f, rows in srcs:
        parts += cc.cut(os.path.join(NB, f), 8000, rows=rows)
    items = SUITS[k][1]
    assert len(parts) == 8, (k, len(parts))
    os.makedirs(os.path.join(CAN, k), exist_ok=True)
    os.makedirs(os.path.join(FULL, k), exist_ok=True)
    meta[k] = {"items": [], "dressed": {}}
    for (iid, name, slot, desc), arr in zip(items, parts):
        im = cc.to_img(arr)
        im.save(os.path.join(FULL, k, f"{iid}.png"), optimize=True)
        sz = cc.save(im, os.path.join(CAN, k, f"{iid}.png"), 200, 200)
        meta[k]["items"].append({"id": iid, "name": name, "slot": slot, "size": list(sz), "full": list(im.size)})
    for tag in "ab":
        arr = max(cc.cut(os.path.join(NB, f"suitdress_{k}_{tag}.png")), key=lambda x: x.shape[0] * x.shape[1])
        im = cc.to_img(arr)
        im.save(os.path.join(FULL, k, f"_dressed-{tag}.png"), optimize=True)
        meta[k]["dressed"][tag] = list(cc.save(im, os.path.join(CAN, k, f"dressed-{tag}.png"), 360, 300))
json.dump(meta, open(os.path.join(CAN, "suits.json"), "w"), indent=1)
json.dump(meta, open(os.path.join(FULL, "suits.json"), "w"), indent=1)
print({k: [i["id"] for i in v["items"]] for k, v in meta.items()})
