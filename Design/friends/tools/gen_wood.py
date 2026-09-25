"""Bluebell Wood: generate three parallax layers like the meadow's and chain them into loops.

uv run --with numpy --with pillow --with scipy python Design/friends/tools/gen_wood.py gen [far mid near]
uv run --with numpy --with pillow --with scipy python Design/friends/tools/gen_wood.py build [far mid near]
"""
import os, sys, json
import numpy as np
from PIL import Image

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..', '..'))
sys.path.insert(0, os.path.join(ROOT, 'Design', 'collage', 'tools'))
import chain as C  # noqa: E402

RAW = os.path.join(ROOT, 'Design', 'friends', 'tools', 'nb', 'wood')
RES = os.path.join(ROOT, 'HopTalesPackage', 'Sources', 'World', 'Resources')
POSTCARD = os.path.join(ROOT, 'Design', 'friends', 'worlds', 'bunny-postcard.jpg')
MEADOW = os.path.join(ROOT, 'Design', 'collage', 'raw')

EDIT = ("Edit this image. Keep the flat grey area at the top exactly as it is: plain untouched grey, the same size, "
        "nothing painted on it, no sky, no trees reaching into it. Keep the torn paper strip exactly the same shape and "
        "position, with its ragged white rim along the top edge. Only repaint the scenery on the strip. Same soft "
        "storybook watercolour with fine brown ink linework and paper grain as the original, calm spring daylight. "
        "No animals, no people, no text. ")

LAYERS = {
    'far': EDIT + ("Turn the rolling hills into the far hills beyond a bluebell wood: hazy blue-green and soft lilac "
                   "hills, with a faint misty band of distant woodland, tiny pale trunks and soft rounded canopies, "
                   "along some of the ridges. Keep it very pale and low contrast, cooler than the original."),
    'mid': EDIT + ("Turn the green hills into a woodland bank: the same rise and fall of the top edge, but the slopes "
                   "carpeted in drifts of bluebells with soft green undergrowth, ferns and a few small hazel bushes. "
                   "Small rounded woodland trees and young silver birches stand on the slopes where the original has "
                   "trees, the same size as the original trees and fully inside the strip. Mid-tone, softer than a "
                   "foreground."),
    'near': EDIT + ("Keep the pale cream footpath band at exactly the same height and the same generous thickness, "
                    "running straight across the whole width, completely clear and empty so dark lettering can be "
                    "printed on it: no flowers, leaves or stems overlap the path, and no white paper rim along the "
                    "path's edges. Turn the meadow into a bluebell wood floor: on the bank above the path moss, small "
                    "ferns and a few bluebells; below the path, starting at the path's lower edge, a thick drift of "
                    "bluebells with ferns, a few white wood anemones and mossy stones, then the lower torn edge and "
                    "deep green moss at the bottom as before. No trees."),
}
SOURCES = {'far': ['far-src', 'far-src2', 'far-src3'], 'mid': ['mid-src', 'mid-src2', 'mid-src3'],
           'near': ['near-src', 'near-src2', 'near-src3']}
TARGET = {'far': (5615, 826), 'mid': (4692, 834), 'near': (3555, 834)}


def gen(names):
    sys.path.insert(0, os.path.join(ROOT, 'Design', 'collage', 'tools'))
    import nb  # noqa: needs the key
    os.makedirs(RAW, exist_ok=True)
    for name in names:
        for i, src in enumerate(SOURCES[name]):
            out = os.path.join(RAW, f'{name}-{i + 1}.png')
            if os.path.exists(out):
                continue
            ref = Image.open(os.path.join(MEADOW, f'{src}.png'))
            im, text, _ = nb.generate(LAYERS[name], [ref], aspect='21:9', size='2K')
            im.convert('RGB').resize(ref.size, Image.LANCZOS).save(out)
            print(out, im.size, text[:80], flush=True)


def load(p):
    flip = p.endswith('f')
    a = C.load(os.path.join(RAW, p.rstrip('f').removesuffix('.png') + '.png'))
    return a[:, ::-1].copy() if flip else a


def best_join(P, Q, span, mirror=False):
    rp, rq = C.ridge(P), C.ridge(Q)
    Wp, Wq, H = P.shape[1], Q.shape[1], P.shape[0]
    rows = slice(int(H * 0.45), H, 24)
    cp, cq = P[rows, :, :3].mean(0), Q[rows, :, :3].mean(0)
    best = None
    for xp in range(int(Wp * (1 - span)), Wp - C.O - 40, 8):
        for xq in range(40, int(Wq * span), 8):
            if mirror and abs((Wp - xp - C.O) - xq) < 500:
                continue
            c = np.abs(rp[xp:xp + C.O:6] - rq[xq:xq + C.O:6]).mean() + 0.25 * np.abs(cp[xp:xp + C.O:6] - cq[xq:xq + C.O:6]).mean()
            if best is None or c < best[0]:
                best = (c, xp, xq)
    return best


def build(names):
    for name in names:
        paths = sorted(p for p in os.listdir(RAW) if p.startswith(name + '-') and p.endswith('.png'))
        pick = os.environ.get(name.upper())
        if pick:
            paths = [f'{name}-{k}' for k in pick.split(',')]
        C.O = {'far': 520, 'mid': 420, 'near': 300}[name]
        secs = [load(p) for p in paths]
        if name == 'near':
            ref = np.asarray(Image.open(os.path.join(RES, 'near-day.webp'))).astype(np.float32)
        n = len(secs)
        span = float(os.environ.get(name.upper() + '_SPAN', 0.42))
        twin = lambda a, b: a.endswith('f') != b.endswith('f')
        joins = [best_join(secs[i], secs[(i + 1) % n], span, twin(paths[i], paths[(i + 1) % n]))[1:] for i in range(n)]
        pieces = []
        for i in range(n):
            x_in, x_out = joins[i - 1][1] + C.O, joins[i][0]
            assert x_out > x_in + 400, (name, i, x_in, x_out)
            pieces.append(secs[i][:, x_in:x_out])
            xp, xq = joins[i]
            A, B = secs[i][:, xp:xp + C.O], secs[(i + 1) % n][:, xq:xq + C.O]
            if name == 'far':
                w = np.linspace(0, 1, C.O)[None, :, None]
                w = w * w * (3 - 2 * w)
                blend = A * (1 - w) + B * w
                oa, ob = A[..., 3:] > 128, B[..., 3:] > 128
                blend[..., :3] = np.where(oa & ~ob, A[..., :3], np.where(ob & ~oa, B[..., :3], blend[..., :3]))
                blend[..., 3] = C.seam_cut(A, B)[..., 3]
                pieces.append(blend)
            else:
                pieces.append(C.seam_cut(A, B))
        tile = np.concatenate(pieces, 1)
        W, H = TARGET[name]
        if name == 'near':
            cr, tr = C.path_band(tile)
            rc, rt = C.path_band(ref)
            s = rt / tr
            im = Image.fromarray(tile.clip(0, 255).astype(np.uint8), 'RGBA')
            im = im.resize((int(im.width * s), int(im.height * s)), Image.LANCZOS)
            y0 = int(round(cr * s - rc))
        else:
            ref = np.asarray(Image.open(os.path.join(RES, f'{name}-day.webp')))
            r_ref = np.median(np.argmax(ref[..., 3] > 128, 0))
            rows = np.nonzero(tile[..., 3].max(1) > 10)[0]
            top = max(0, rows.min() - 4)
            r_t = np.median(np.argmax(tile[..., 3] > 128, 0)) - top
            im = Image.fromarray(tile.clip(0, 255).astype(np.uint8), 'RGBA')
            y0 = int(round(top + r_t - r_ref))
            y0 = min(y0, top - 6)
        a = np.asarray(im)
        canvas = np.zeros((H, a.shape[1], 4), np.uint8)
        ys, yd = max(0, y0), max(0, -y0)
        hh = min(a.shape[0] - ys, H - yd)
        canvas[yd:yd + hh] = a[ys:ys + hh]
        if yd + hh < H:
            canvas[yd + hh:] = canvas[yd + hh - 1]
        if name == 'far':
            k = np.array([1.7, 1.55, 1.7])
            rgb = canvas[..., :3].astype(np.float32)
            canvas[..., :3] = (255 - (255 - rgb) * k).clip(0, 255).astype(np.uint8)
        out = Image.fromarray(canvas, 'RGBA').resize((W, H), Image.LANCZOS)
        out.save(os.path.join(RES, f'{name}-bunny.webp'), quality=88, method=6)
        o = np.asarray(out).astype(np.float32)
        info = dict(size=out.size, chained=canvas.shape[1], sections=paths, ridge=float(np.median(np.argmax(o[..., 3] > 128, 0))))
        if name == 'near':
            info['path_band'] = [float(v) for v in C.path_band(o)]
        print(name, info, flush=True)


SIT = os.path.join(ROOT, 'Design', 'friends', 'characters', 'bunny-sit.png')
HOP = os.path.join(ROOT, 'Design', 'friends', 'sprites', 'bunny-hop.png')
IDLE_RAW = os.path.join(ROOT, 'Design', 'friends', 'tools', 'nb', 'bunny-idle')
POSE = ("Edit this image of a sticker of a rabbit on a flat grey background. Keep everything identical: the same "
        "rabbit, same size, same position, same body, same lilac bow, same watercolour painting, same white sticker "
        "border, same flat grey background. Change only this: ")
IDLE = {
    'blink-half': "her eyes are half closed, sleepy, the upper eyelids covering half of each eye.",
    'blink': "her eyes are gently closed, a calm blink, drawn as soft curved lash lines.",
    'ear-1': "the ear at the back is tipped slightly backwards, about 10 degrees, as if listening.",
    'ear-2': "the ear at the back is tipped backwards about 20 degrees, as if listening.",
    'ear': "the ear at the back is tipped well back, about 35 degrees, as if listening to a sound behind her.",
    'tilt-1': "her head is tilted a little downwards, about 4 degrees, nose lower.",
    'tilt-2': "her head is tilted downwards about 8 degrees, nose lower, curious.",
    'tilt': "her head is tilted downwards about 12 degrees, nose lower, looking at something on the ground.",
    'sniff': "her nose is twitching, sniffing the air: nose slightly raised and wrinkled, whiskers fanned forward.",
}
NAMES = ['rest', 'sniff', 'ear', 'blink', 'tilt', 'blink-half', 'ear-1', 'ear-2', 'tilt-1', 'tilt-2']


def on_grey(path, pad=80):
    im = Image.open(path).convert('RGBA')
    W, H = im.width + pad * 2, im.height + pad * 2
    W = max(W, int(H * 3 / 4))
    bg = Image.new('RGBA', (W, H), (138, 138, 138, 255))
    bg.alpha_composite(im, ((W - im.width) // 2, pad))
    return bg.convert('RGB')


def gen_idle(_):
    sys.path.insert(0, os.path.join(ROOT, 'Design', 'collage', 'tools'))
    import nb  # noqa: needs the key
    os.makedirs(IDLE_RAW, exist_ok=True)
    base = on_grey(SIT)
    base.save(os.path.join(IDLE_RAW, 'rest.png'))
    for name, change in IDLE.items():
        out = os.path.join(IDLE_RAW, f'{name}.png')
        if os.path.exists(out):
            continue
        im, _, _ = nb.generate(POSE + change, [base], aspect='3:4', size='1K')
        im.convert('RGB').resize(base.size, Image.LANCZOS).save(out)
        print(out, flush=True)


def keyed(path):
    from looper import key
    a = np.asarray(Image.open(path).convert('RGB')).astype(np.float32)
    return np.dstack([a, key(a) * 255])


def align(ref, f, region=None):
    ra, fa = ref[..., 3] > 128, f[..., 3] > 128
    ys, xs = np.nonzero(ra)
    if region is None:
        region = np.zeros_like(ra)
        region[int(ys.min() + (ys.max() - ys.min()) * 0.55):] = True
    lum_r = ref[..., :3].mean(2) * ra
    lum_f = f[..., :3].mean(2) * fa
    best = None
    for dy in range(-30, 31, 2):
        for dx in range(-30, 31, 2):
            m = np.roll(np.roll(lum_f, dy, 0), dx, 1)
            s = np.abs(m - lum_r)[region].mean()
            if best is None or s < best[0]:
                best = (s, dx, dy)
    _, dx, dy = best
    return np.roll(np.roll(f, dy, 0), dx, 1)


def body_width(f):
    m = f[..., 3] > 128
    ys, _ = np.nonzero(m)
    lo = int(ys.min() + (ys.max() - ys.min()) * 0.6)
    xs = np.nonzero(m[lo:].any(0))[0]
    return xs.max() - xs.min(), ys.max() - ys.min()


def match_scale(ref, f):
    s = body_width(ref)[0] / body_width(f)[0]
    if abs(s - 1) < 0.005:
        return f
    H, W = f.shape[:2]
    im = Image.fromarray(f.clip(0, 255).astype(np.uint8), 'RGBA').resize((int(W * s), int(H * s)), Image.LANCZOS)
    b = np.asarray(im).astype(np.float32)
    out = np.zeros_like(f)
    h, w = min(H, b.shape[0]), min(W, b.shape[1])
    out[:h, :w] = b[:h, :w]
    return out


def fit_head(rest, f, region):
    from scipy import ndimage as ndi
    q = 4
    small = lambda a: a[::q, ::q]
    lr = small(rest[..., :3].mean(2) * (rest[..., 3] > 128))
    rg = small(region)
    H, W = rest.shape[:2]
    best = None
    for sc in np.linspace(0.82, 1.12, 16):
        im = Image.fromarray(f.clip(0, 255).astype(np.uint8), 'RGBA').resize((int(W * sc), int(H * sc)), Image.LANCZOS)
        b = np.zeros_like(f)
        bb = np.asarray(im).astype(np.float32)
        h, w = min(H, bb.shape[0]), min(W, bb.shape[1])
        b[:h, :w] = bb[:h, :w]
        lf = small(b[..., :3].mean(2) * (b[..., 3] > 128))
        for dy in range(-40, 41, 1):
            for dx in range(-40, 41, 1):
                m = np.roll(np.roll(lf, dy, 0), dx, 1)
                c = np.abs(m - lr)[rg].mean()
                if best is None or c < best[0]:
                    best = (c, sc, dx * q, dy * q, b)
    _, sc, dx, dy, b = best
    return np.roll(np.roll(b, dy, 0), dx, 1)


def build_idle(_):
    from scipy import ndimage as ndi
    rest = keyed(os.path.join(IDLE_RAW, 'rest.png'))
    ys, xs = np.nonzero(rest[..., 3] > 128)
    top, bottom = ys.min(), ys.max()
    left, right = xs.min(), xs.max()
    yy, xx = np.mgrid[:rest.shape[0], :rest.shape[1]].astype(np.float32)
    hgt, wid = bottom - top, right - left
    ears = yy < top + hgt * 0.28
    face = (yy < top + hgt * 0.50) & (xx > left + wid * 0.45)
    region = (yy > top + hgt * 0.18) & (yy < top + hgt * 0.45) & (xx > left + wid * 0.5)
    frames = [rest]
    for name in NAMES[1:]:
        f = fit_head(rest, keyed(os.path.join(IDLE_RAW, f'{name}.png')), region)
        inner = ndi.binary_erosion(f[..., 3] > 128, iterations=14) & ndi.binary_erosion(rest[..., 3] > 128, iterations=14)
        m = ears | (face & inner)
        m = ndi.gaussian_filter(m.astype(np.float32), 6)[..., None]
        frames.append(rest * (1 - m) + f * m)
    alpha = np.max([f[..., 3] for f in frames], 0) > 10
    ys, xs = np.nonzero(alpha)
    pad = 24
    y0, y1 = max(0, ys.min() - pad), min(rest.shape[0], ys.max() + pad)
    x0, x1 = max(0, xs.min() - pad), min(rest.shape[1], xs.max() + pad)
    cells = [f[y0:y1, x0:x1] for f in frames]
    S = 344 / hgt
    w, h = int(round((x1 - x0) * S)), int(round((y1 - y0) * S))
    sheet = Image.new('RGBA', (w * len(cells), h))
    for i, c in enumerate(cells):
        sheet.alpha_composite(Image.fromarray(c.clip(0, 255).astype(np.uint8), 'RGBA').resize((w, h), Image.LANCZOS), (i * w, 0))
    sheet.save(os.path.join(RES, 'bunny-idle-frames.webp'), quality=90, method=6)
    a = np.asarray(sheet)[..., 3][:, :w]
    ys, xs = np.nonzero(a > 128)
    feet = xs[ys > ys.max() - 6].mean()
    print('idle', sheet.size, 'cell', (w, h), 'names', NAMES, 'rest bbox', (xs.min(), ys.min(), xs.max(), ys.max()),
          'anchor', (round(feet), ys.max()), flush=True)


def hop(_):
    im = Image.open(HOP).convert('RGBA')
    s = 346 / im.height
    w = int(round(im.width / 8 * s))
    out = Image.new('RGBA', (w * 8, 346))
    cw = im.width // 8
    for i in range(8):
        out.alpha_composite(im.crop((i * cw, 0, (i + 1) * cw, im.height)).resize((w, 346), Image.LANCZOS), (i * w, 0))
    out.save(os.path.join(RES, 'bunny-hop.webp'), quality=90, method=6)
    a = np.asarray(out)[..., 3]
    for i in range(8):
        ys, xs = np.nonzero(a[:, i * w:(i + 1) * w] > 128)
        print('hop', i, 'bbox', (xs.min(), ys.min(), xs.max(), ys.max()))
    print('hop', out.size, 'cell', (w, 346), flush=True)


if __name__ == '__main__':
    step, names = sys.argv[1], sys.argv[2:] or ['far', 'mid', 'near']
    {'gen': gen, 'build': build, 'gen_idle': gen_idle, 'build_idle': build_idle, 'hop': hop}[step](names)
