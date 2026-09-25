"""Generate the basket-full present stickers (closed and opened) with Nano Banana, then cut them out.

Writes Design/friends/collectibles/present.png and present-open.png. The key comes from the
git-ignored .gemini-key at the repo root (see Design/collage/tools/nb.py).
"""
import os
import sys

import numpy as np
from PIL import Image
from scipy import ndimage as ndi

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
sys.path.insert(0, os.path.join(ROOT, "Design", "collage", "tools"))
import nb  # noqa: E402

OUT = os.path.join(ROOT, "Design", "friends", "collectibles")
STYLE = ("Hand-painted in delicate watercolour washes with fine sepia ink pen lines and a little soft pencil texture, in the gentle, "
         "naturalistic manner of classic Edwardian English children's nature picture books — cozy, warm and quiet.")
STICKER = "Surrounded by one even, thick white paper border, as if carefully cut out of a printed book with scissors, with a very subtle soft drop shadow."
GREY = "Plain flat medium-grey background (#8a8a8a). No text, no ground, no other objects, nothing touching the edges."
JOBS = {
    "present": "A single small wrapped present box, seen from slightly above at three-quarters: a cube wrapped in cream paper printed with tiny "
               "sprigs of wild flowers, tied with a soft faded red ribbon crossing on the top and a generous hand-tied bow with two loops and "
               "two trailing tails. Slightly soft, hand-made, charming.",
    "present-open": "The same small present as image 2, now opened: its lid lifted off and resting tilted against the box, the faded red ribbon "
                    "loosened and draped over the side, a little tissue paper peeking out of the open box, a few tiny paper confetti pieces "
                    "floating just above it.",
}


def cut(image):
    a = np.asarray(image.convert("RGB")).astype(np.float32)
    bg = np.median(a[:10].reshape(-1, 3), 0)
    near = np.sqrt(((a - bg) ** 2).sum(2)) < 22
    lab, _ = ndi.label(near)
    edge = np.unique(np.concatenate([lab[:4][near[:4]], lab[-4:][near[-4:]], lab[:, :4][near[:, :4]], lab[:, -4:][near[:, -4:]]]))
    fg = ndi.binary_fill_holes(~np.isin(lab, edge[edge > 0]))
    fg = ndi.binary_opening(fg, iterations=2)
    lab, n = ndi.label(fg)
    if n == 0:
        raise SystemExit("nothing to cut out")
    sizes = ndi.sum(fg, lab, index=range(1, n + 1))
    keep = lab == (int(np.argmax(sizes)) + 1)
    alpha = ndi.gaussian_filter(keep.astype(np.float32), 0.8)
    rgba = np.dstack([a, np.clip(alpha * 255, 0, 255)]).astype(np.uint8)
    ys, xs = np.nonzero(keep)
    pad = 6
    return Image.fromarray(rgba).crop((max(xs.min() - pad, 0), max(ys.min() - pad, 0), xs.max() + pad, ys.max() + pad))


def run(name, refs):
    prompt = f"{JOBS[name]} {STYLE} {STICKER} {GREY} Match the paint, line and white paper-border style of image 1 exactly (image 1 shows a different object; use it only for style)."
    image, text, usage = nb.generate(prompt, refs, "1:1", "1K")
    raw = os.path.join(HERE, "nb", f"{name}-raw.png")
    os.makedirs(os.path.dirname(raw), exist_ok=True)
    image.save(raw)
    sticker = cut(image)
    sticker.save(os.path.join(OUT, f"{name}.png"))
    print(name, sticker.size, usage.get("totalTokenCount"), text[:80])
    return image


if __name__ == "__main__":
    style = Image.open(os.path.join(OUT, "basket.png"))
    closed = run("present", [style])
    if "--closed-only" not in sys.argv:
        run("present-open", [style, closed])
