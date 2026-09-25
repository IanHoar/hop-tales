"""Open the paper-white centre of ring-shaped stickers (garlands), keeping a white rim."""
import numpy as np, sys
from PIL import Image
from scipy import ndimage as ndi


def open_ring(path, rim=None):
    im = Image.open(path).convert("RGBA")
    a = np.asarray(im).astype(np.float32)
    rim = rim or max(4, round(min(im.size) * 0.035))
    white = (a[..., :3].min(2) > 232) & (a[..., 3] > 200)
    lab, n = ndi.label(white)
    if not n:
        return
    edge = set(np.unique(np.concatenate([lab[0], lab[-1], lab[:, 0], lab[:, -1]])))
    areas = ndi.sum(np.ones(lab.shape), lab, index=np.arange(1, n + 1))
    # the largest white blob that doesn't touch the image edge = the centre
    cands = [(ar, i + 1) for i, ar in enumerate(areas) if (i + 1) not in edge]
    if not cands:
        return
    ar, idx = max(cands)
    if ar < 0.04 * white.size:
        return
    centre = lab == idx
    dist = ndi.distance_transform_edt(centre)
    alpha = a[..., 3].copy()
    cut = dist > rim
    soft = np.clip((dist - rim) / 1.5, 0, 1)
    alpha[cut] = alpha[cut] * (1 - soft[cut])
    a[..., 3] = alpha
    Image.fromarray(a.clip(0, 255).astype(np.uint8), "RGBA").save(path, optimize=True)
    print("opened", path)


if __name__ == "__main__":
    for p in sys.argv[1:]:
        open_ring(p)
