"""Chain several generated sections of one parallax layer into a long seamless loop, joined with min-cost seam cuts (no crossfades)."""
import numpy as np, json, sys
from PIL import Image
from scipy import ndimage as ndi
from looper import key

OUT = '../wordhop/project/collage/world'
O = 260  # overlap width searched for the seam (overridden per layer)


def load(path):
    a = np.asarray(Image.open(path).convert('RGB')).astype(np.float32)
    al = key(a)
    return np.dstack([a, al * 255])


def path_band(rgba):
    a = rgba
    pale = ((a[..., 0] > 212) & (a[..., 1] > 196) & (a[..., 2] > 145) & (a[..., 2] < 228) & (a[..., 3] > 200)).mean(1)
    rows = np.nonzero(pale > 0.45)[0]
    # longest run
    runs, start = [], rows[0]
    for i in range(1, len(rows)):
        if rows[i] != rows[i - 1] + 1:
            runs.append((start, rows[i - 1])); start = rows[i]
    runs.append((start, rows[-1]))
    r = max(runs, key=lambda t: t[1] - t[0])
    return (r[0] + r[1]) / 2, r[1] - r[0]


def normalise_to(ref, sec):
    """scale + shift sec so its footpath band matches ref's (near layer only)."""
    cr, tr = path_band(ref)
    cs, ts = path_band(sec)
    s = tr / ts
    H, W, _ = sec.shape
    im = Image.fromarray(sec.clip(0, 255).astype(np.uint8), 'RGBA').resize((int(W * s), int(H * s)), Image.LANCZOS)
    b = np.asarray(im).astype(np.float32)
    out = np.zeros((ref.shape[0], b.shape[1], 4), np.float32)
    dy = int(round(cr - cs * s))
    ys0, yd0 = max(0, -dy), max(0, dy)
    hh = min(b.shape[0] - ys0, out.shape[0] - yd0)
    out[yd0:yd0 + hh] = b[ys0:ys0 + hh]
    # fill below with the section's own bottom rows if it ended early
    if yd0 + hh < out.shape[0]:
        out[yd0 + hh:] = out[yd0 + hh - 1]
    return out


def match_band(ref, sec):
    """vertically remap rows between (ridge-160) and the path top so the grass band has the same height as ref."""
    cr, tr = path_band(ref); cs, ts = path_band(sec)
    pr, ps = cr - tr / 2, cs - ts / 2
    rr, rs = np.median(ridge(ref)), np.median(ridge(sec))
    H = sec.shape[0]
    y = np.arange(H, dtype=np.float32)
    src = y.copy()
    a0 = rr - 200
    band = (y >= a0) & (y <= pr)
    # target rows [a0, pr] come from source rows [rs - 200 * (pr - rr) / (pr - rr), ps] mapped linearly by the ridge
    t = (y[band] - rr) / max(pr - rr, 1)
    src[band] = rs + t * (ps - rs)
    above = y < a0
    src[above] = y[above] - a0 + (rs + (a0 - rr) / max(pr - rr, 1) * (ps - rs))
    out = np.empty_like(sec)
    for c in range(4):
        out[..., c] = ndi.map_coordinates(sec[..., c], [np.repeat(src[:, None], sec.shape[1], 1), np.tile(np.arange(sec.shape[1], dtype=np.float32), (H, 1))], order=1, mode='nearest')
    return out


def ridge(rgba):
    return np.argmax(rgba[..., 3] > 128, axis=0).astype(np.float32)


def best_join(P, Q):
    rp, rq = ridge(P), ridge(Q)
    Wp, Wq = P.shape[1], Q.shape[1]
    H = P.shape[0]
    rows = slice(int(H * 0.45), H, 24)
    cp = P[rows, :, :3].mean(0)
    cq = Q[rows, :, :3].mean(0)
    best = None
    for xp in range(int(Wp * 0.58), Wp - O - 40, 8):
        for xq in range(40, int(Wq * 0.42), 8):
            c = np.abs(rp[xp:xp + O:6] - rq[xq:xq + O:6]).mean() + 0.25 * np.abs(cp[xp:xp + O:6] - cq[xq:xq + O:6]).mean()
            if best is None or c < best[0]:
                best = (c, xp, xq)
    return best


def seam_cut(A, B):
    """A, B: H x O x 4 overlap blocks. Return blended block using a min-cost vertical seam."""
    d = np.abs(A[..., :3] - B[..., :3]).sum(2) + 3 * np.abs(A[..., 3] - B[..., 3])
    d = ndi.gaussian_filter(d, 1.5)
    H, W = d.shape
    # keep the seam away from the block edges
    d[:, :12] += 1e5; d[:, -12:] += 1e5
    cost = d.copy()
    back = np.zeros((H, W), np.int32)
    for y in range(1, H):
        prev = cost[y - 1]
        l = np.r_[np.inf, prev[:-1]]; r = np.r_[prev[1:], np.inf]
        stack = np.stack([l, prev, r])
        k = np.argmin(stack, 0)
        cost[y] += stack[k, np.arange(W)]
        back[y] = np.arange(W) + (k - 1)
    x = int(np.argmin(cost[-1]))
    seam = np.zeros(H, np.int32)
    for y in range(H - 1, -1, -1):
        seam[y] = x
        x = back[y, x]
    cols = np.arange(W)[None, :]
    m = (cols >= seam[:, None]).astype(np.float32)
    m = ndi.gaussian_filter(m, (0, 1.2))  # 1-2 px soften only
    return A * (1 - m[..., None]) + B * m[..., None]


def chain(name, paths):
    global O
    O = {'far': 520, 'mid': 420, 'near': 300}[name]
    secs = [load(p) for p in paths]
    if name == 'near':
        secs = [secs[0]] + [match_band(secs[0], normalise_to(secs[0], s)) for s in secs[1:]]
    n = len(secs)
    joins = []
    for i in range(n):
        P, Q = secs[i], secs[(i + 1) % n]
        c, xp, xq = best_join(P, Q)
        joins.append((xp, xq))
        print(name, f'join {i}->{(i + 1) % n}', 'cost', round(c, 2), xp, xq, flush=True)
    pieces = []
    seams = []
    for i in range(n):
        S_ = secs[i]
        x_in = joins[i - 1][1] + O          # after the seam coming in
        x_out = joins[i][0]                 # before the seam going out
        assert x_out > x_in + 400, (name, i, x_in, x_out)
        pieces.append(S_[:, x_in:x_out])
        xp, xq = joins[i]
        Q = secs[(i + 1) % n]
        seams.append(sum(p.shape[1] for p in pieces) + O // 2)
        pieces.append(seam_cut(S_[:, xp:xp + O], Q[:, xq:xq + O]))
    tile = np.concatenate(pieces, 1)
    rows = np.nonzero(tile[..., 3].max(1) > 10)[0]
    y0 = max(0, rows.min() - 4)
    out = tile[y0:].clip(0, 255).astype(np.uint8)
    Image.fromarray(out, 'RGBA').save(f'{OUT}/{name}-day.png', optimize=True)
    print(name, 'loop', out.shape[1], 'x', out.shape[0], 'top', y0, flush=True)
    return dict(w=int(out.shape[1]), h=int(out.shape[0]), top=int(y0), seams=[int(x) for x in seams])


if __name__ == '__main__':
    meta = json.load(open(f'{OUT}/meta.json'))
    for name, files in (('far', ['far-src', 'far-src2', 'far-src3']), ('mid', ['mid-src', 'mid-src2', 'mid-src3']), ('near', ['near-src', 'near-src3'])):
        if len(sys.argv) > 1 and name not in sys.argv[1:]:
            continue
        meta[name] = chain(name, [f'nb/world/{f}.png' for f in files])
    json.dump(meta, open(f'{OUT}/meta.json', 'w'), indent=1)
