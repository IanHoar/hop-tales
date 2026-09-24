import numpy as np, json
from PIL import Image
from scipy import ndimage as ndi

OUT = '../wordhop/project/collage/world'


def key(a):
    bg = np.median(a[:10].reshape(-1, 3), 0)
    d = np.sqrt(((a - bg) ** 2).sum(2))
    cand = d < 22
    lab, _ = ndi.label(cand)
    tl = np.unique(lab[:4][cand[:4]]); tl = tl[tl > 0]
    bgm = np.isin(lab, tl)
    fg = ndi.binary_fill_holes(~bgm)
    fg = ndi.binary_opening(fg, iterations=1)
    alpha = ndi.gaussian_filter(fg.astype(np.float32), 0.8)
    alpha[ndi.binary_erosion(fg, iterations=2)] = 1
    alpha[~ndi.binary_dilation(fg, iterations=2)] = 0
    return alpha


def make_loop(name, O=140):
    a = np.asarray(Image.open(f'nb/world/{name}-src.png').convert('RGB')).astype(np.float32)
    H, W, _ = a.shape
    al = key(a)
    ridge = np.argmax(al > 0.5, axis=0).astype(np.float32)
    band = np.stack([a[np.clip(ridge.astype(int) + 60, 0, H - 1), np.arange(W)]], 0)[0]
    best = None
    win = np.arange(-80, 81, 4)
    for x1 in range(100, int(W * 0.3), 6):
        for x2 in range(int(W * 0.7), W - O - 90, 6):
            if x2 - x1 < W * 0.55:
                continue
            k1 = np.clip(x1 + win, 0, W - 1); k2 = np.clip(x2 + win, 0, W - 1)
            c = np.abs(ridge[k1] - ridge[k2]).mean() + 0.02 * np.abs(band[x1] - band[x2]).mean()
            # prefer overlapping region profiles to match too
            c += 0.5 * np.abs(ridge[x1:x1 + O:8] - ridge[x2:x2 + O:8]).mean()
            if best is None or c < best[0]:
                best = (c, x1, x2)
    c, x1, x2 = best
    rgba = np.dstack([a, al * 255])
    tile = rgba[:, x1:x2].copy()
    w = np.linspace(0, 1, O)[None, :, None]
    w = w * w * (3 - 2 * w)
    tile[:, :O] = rgba[:, x1:x1 + O] * w + rgba[:, x2:x2 + O] * (1 - w)
    rows = np.nonzero(tile[..., 3].max(1) > 10)[0]
    y0 = max(0, rows.min() - 4)
    out = tile[y0:].clip(0, 255).astype(np.uint8)
    Image.fromarray(out, 'RGBA').save(f'{OUT}/{name}-day.png')
    seam = np.abs(out[:, 0].astype(float) - out[:, -1]).mean(); adj = np.abs(np.diff(out.astype(float), axis=1)).mean()
    print(name, 'cut', x1, x2, 'cost', round(c, 2), 'tile', out.shape[1], out.shape[0], 'top', y0, 'seam', round(seam, 1), 'adj', round(adj, 1))
    return dict(w=int(out.shape[1]), h=int(out.shape[0]), top=int(y0), src_h=H)


if __name__ == '__main__':
    meta = {n: make_loop(n) for n in ('far', 'mid', 'near')}
    json.dump(meta, open(f'{OUT}/meta.json', 'w'), indent=1)
