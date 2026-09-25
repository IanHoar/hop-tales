"""A friend's world and idle, the Bluebell Wood recipe (gen_wood.py) generalised by friend key.

uv run --with numpy --with pillow --with scipy python Design/friends/tools/gen_world.py <key> gen [far mid near]
uv run --with numpy --with pillow --with scipy python Design/friends/tools/gen_world.py <key> build [far mid near]
uv run --with numpy --with pillow --with scipy python Design/friends/tools/gen_world.py <key> gen_idle
uv run --with numpy --with pillow --with scipy python Design/friends/tools/gen_world.py <key> build_idle
uv run --with numpy --with pillow --with scipy python Design/friends/tools/gen_world.py <key> hop

Section order for build is picked with FAR=1,2,1f MID=... NEAR=... (f = mirrored), as in gen_wood.py.
"""
import os, sys
import numpy as np
from PIL import Image

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..', '..'))
sys.path.insert(0, os.path.join(ROOT, 'Design', 'collage', 'tools'))
sys.path.insert(0, os.path.dirname(__file__))
import chain as C  # noqa: E402
import gen_wood as W  # noqa: E402

RES = W.RES
MEADOW = W.MEADOW
EDIT = W.EDIT
CLEAR_PATH = ("running straight across the whole width, completely clear and empty so dark lettering can be printed "
              "on it: nothing overlaps it, and no white paper rim along its edges. ")

WORLDS = {
    'frog': {
        'raw': 'pond',
        'far': EDIT + ("Turn the rolling hills into the far hills beyond a willow pond: hazy blue-green and soft lilac "
                       "hills with pale patchwork fields and a faint misty line of tiny distant willows. Keep it very "
                       "pale and low contrast, cooler than the original, and no higher than the original hills."),
        'mid': EDIT + ("Turn the green hills into the far bank of a pond: the same rise and fall of the top edge, "
                       "soft grassy banks with reeds and bulrushes, and small round weeping willows standing where the "
                       "original has trees, the same size as the original trees and fully inside the strip. Glimpses "
                       "of pale green still water between the banks lower down. Mid-tone, softer than a foreground."),
        'near': EDIT + ("Keep the pale cream path band at exactly the same height and the same generous thickness, "
                        "but paint it as a causeway of big flat pale cream stepping stones laid tightly edge to edge "
                        "across a pond, so together they make one continuous pale band " + CLEAR_PATH +
                        "Above the band: calm green pond water with lily pads and a few white water lilies, reeds at "
                        "the top edge. Below the band, starting at its lower edge: pond water with more lily pads, "
                        "then yellow marsh marigolds, rushes and forget-me-nots, then the lower torn edge and soft "
                        "green grass at the bottom as before. No trees."),
    },
    'crab': {
        'raw': 'rockpools',
        'far': EDIT + ("Turn the rolling hills into a far coastline: hazy blue-grey headlands and soft lilac cliffs "
                       "sloping down to a calm pale sea along the bottom of the strip, a tiny white lighthouse on one "
                       "headland. Keep it very pale and low contrast, cooler than the original, and no higher than "
                       "the original hills."),
        'mid': EDIT + ("Turn the green hills into a rocky shore: the same rise and fall of the top edge made of low "
                       "rounded grey-brown rocks draped in dark olive seaweed, with a small blue rock pool, a few "
                       "shells and pebbles, and calm pale sea showing between the rocks. Rocks no taller than the "
                       "original trees. Mid-tone, softer than a foreground."),
        'near': EDIT + ("Keep the pale cream path band at exactly the same height and the same generous thickness, "
                        "painted as smooth pale wet sand, " + CLEAR_PATH +
                        "Above the band: golden sand with pebbles, a few small rocks with tufts of seaweed and a "
                        "scallop shell or two. Below the band, starting at its lower edge: golden sand with shells, "
                        "pebbles, strands of seaweed and a little rock pool, then the lower torn edge and darker "
                        "damp sand at the bottom. No trees, no grass, no flowers."),
    },
}

POSE = ("Edit this image of a sticker of a {animal} on a flat grey background. Keep everything identical: the same "
        "{animal}, same size, same position, same body, same {accessory}, same watercolour painting, same white "
        "sticker border, same flat grey background. Change only this: ")

IDLES = {
    'frog': {
        'animal': 'frog', 'accessory': 'yellow neckerchief',
        'align': (0.05, 0.45, 0.45, 0.95),
        'boxes': {k: [(0.42, -0.06, 1.04, 0.62)] for k in
                  ['sniff', 'ear', 'blink', 'tilt', 'blink-half', 'ear-1', 'ear-2', 'tilt-1', 'tilt-2']},
        'changes': {
            'sniff': "his nostrils flare and his head lifts very slightly, about 3 degrees, as if sniffing the air.",
            'ear': "his throat is puffed out in a big round pale bubble under his chin, as frogs do when they croak.",
            'ear-1': "his throat is puffed out a little, a small pale swelling under his chin.",
            'ear-2': "his throat is puffed out halfway, a medium pale round swelling under his chin.",
            'blink': "his eye is gently closed, a calm blink, the eyelid drawn as a soft curved line.",
            'blink-half': "his eye is half closed, sleepy, the upper eyelid covering half of the eye.",
            'tilt': "his head is tilted upwards about 10 degrees, chin raised, looking up at something.",
            'tilt-1': "his head is tilted upwards about 3 degrees, chin a little raised.",
            'tilt-2': "his head is tilted upwards about 6 degrees, chin raised.",
        },
    },
    'crab': {
        'animal': 'crab', 'accessory': 'striped sailor neckerchief',
        'align': (0.15, 0.02, 0.5, 0.4),
        'inside': ('blink', 'blink-half', 'tilt', 'tilt-1', 'tilt-2'),
        'boxes': {
            **{k: [(0.5, -0.04, 0.82, 0.34)] for k in ['blink', 'blink-half', 'tilt', 'tilt-1', 'tilt-2']},
            **{k: [(0.68, -0.7, 1.08, 0.85)] for k in ['sniff', 'ear', 'ear-1', 'ear-2']},
        },
        'changes': {
            'sniff': "the pincer of the big claw on the right of the picture is opened wide, as if about to snip.",
            'ear': "the big claw on the right of the picture is raised high in a cheerful wave, well above the shell.",
            'ear-1': "the big claw on the right of the picture is lifted a little, raised about a quarter of the way.",
            'ear-2': "the big claw on the right of the picture is lifted halfway up, level with the top of the shell.",
            'blink': "both eyes are gently closed, a calm blink, the eyes on their stalks drawn as soft curved lines.",
            'blink-half': "both eyes are half closed, sleepy, the eyelids covering half of each eye.",
            'tilt': "both eye stalks lean over towards the right of the picture, about 20 degrees, curious.",
            'tilt-1': "both eye stalks lean a little towards the right of the picture, about 6 degrees.",
            'tilt-2': "both eye stalks lean towards the right of the picture, about 12 degrees.",
        },
    },
}
NAMES = W.NAMES


def band(rgba, thr=0.5):
    rgb = rgba[..., :3] / 255
    mx, mn = rgb.max(2), rgb.min(2)
    sat = (mx - mn) / np.maximum(mx, 1e-3)
    pale = ((mx > 0.84) & (sat < 0.22) & (rgba[..., 3] > 200)).mean(1)
    rows = np.nonzero(pale > thr)[0]
    runs, start = [], rows[0]
    for i in range(1, len(rows)):
        if rows[i] != rows[i - 1] + 1:
            runs.append((start, rows[i - 1]))
            start = rows[i]
    runs.append((start, rows[-1]))
    r = max(runs, key=lambda t: t[1] - t[0])
    return (r[0] + r[1]) / 2, r[1] - r[0]




NEAR_RIDGE, BAND_TOP, BAND_BOTTOM, NEAR_H = 188, 364, 504, 834


def normalise_near(a):
    from scipy import ndimage as ndi
    c, t = band(a)
    bt, bb = c - t / 2, c + t / 2
    r = float(np.median(C.ridge(a)))
    s = (BAND_TOP - NEAR_RIDGE) / (bt - r)
    H, Wd = a.shape[:2]
    im = Image.fromarray(a.clip(0, 255).astype(np.uint8), 'RGBA').resize((int(Wd * s), int(H * s)), Image.LANCZOS)
    b = np.asarray(im).astype(np.float32)
    r, bt, bb = r * s, bt * s, bb * s
    y = np.arange(NEAR_H, dtype=np.float32)
    src = np.where(y < BAND_TOP, r + (y - NEAR_RIDGE),
                   np.where(y <= BAND_BOTTOM, bt + (y - BAND_TOP) * (bb - bt) / (BAND_BOTTOM - BAND_TOP),
                            bb + (y - BAND_BOTTOM)))
    ys = np.repeat(src[:, None], b.shape[1], 1)
    xs = np.tile(np.arange(b.shape[1], dtype=np.float32), (NEAR_H, 1))
    out = np.stack([ndi.map_coordinates(b[..., k], [ys, xs], order=1, mode='nearest') for k in range(4)], -1)
    print('  section scale', round(s, 3), 'band squeeze', round((bb - bt) / (BAND_BOTTOM - BAND_TOP), 2),
          'width', out.shape[1], flush=True)
    return out


def raw_dir(key):
    return os.path.join(ROOT, 'Design', 'friends', 'tools', 'nb', WORLDS[key]['raw'])


def idle_dir(key):
    return os.path.join(ROOT, 'Design', 'friends', 'tools', 'nb', f'{key}-idle')


def gen(key, names):
    import nb  # noqa: needs the key
    raw = raw_dir(key)
    os.makedirs(raw, exist_ok=True)
    for name in names:
        for i, src in enumerate(W.SOURCES[name]):
            out = os.path.join(raw, f'{name}-{i + 1}.png')
            if os.path.exists(out):
                continue
            ref = Image.open(os.path.join(MEADOW, f'{src}.png'))
            im, text, _ = nb.generate(WORLDS[key][name], [ref], aspect='21:9', size='2K')
            im.convert('RGB').resize(ref.size, Image.LANCZOS).save(out)
            print(out, im.size, text[:80], flush=True)


def build_one(key, name):
    raw = raw_dir(key)
    paths = sorted(p[:-4] for p in os.listdir(raw) if p.startswith(name + '-') and p.endswith('.png'))
    pick = os.environ.get(name.upper())
    if pick:
        paths = [f'{name}-{k}' for k in pick.split(',')]
    C.O = {'far': 520, 'mid': 420, 'near': 300}[name]
    W.RAW = raw
    secs = [W.load(p) for p in paths]
    if name == 'near':
        secs = [normalise_near(a) for a in secs]
    n = len(secs)
    span = float(os.environ.get(name.upper() + '_SPAN', 0.42))
    twin = lambda a, b: a.endswith('f') != b.endswith('f')
    joins = [W.best_join(secs[i], secs[(i + 1) % n], span, twin(paths[i], paths[(i + 1) % n]))[1:] for i in range(n)]
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
    Wd, H = W.TARGET[name]
    im = Image.fromarray(tile.clip(0, 255).astype(np.uint8), 'RGBA')
    if name == 'near':
        y0 = 0
    else:
        ref = np.asarray(Image.open(os.path.join(RES, f'{name}-day.webp')))
        r_ref = np.median(np.argmax(ref[..., 3] > 128, 0))
        r_t = np.median(np.argmax(tile[..., 3] > 128, 0))
        y0 = int(round(r_t - r_ref))
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
    print('  horizontal resize', round(Wd / canvas.shape[1], 3), flush=True)
    out = Image.fromarray(canvas, 'RGBA').resize((Wd, H), Image.LANCZOS)
    out.save(os.path.join(RES, f'{name}-{key}.webp'), quality=88, method=6)
    o = np.asarray(out).astype(np.float32)
    info = dict(size=out.size, chained=canvas.shape[1], sections=paths, y0=y0,
                ridge=float(np.median(np.argmax(o[..., 3] > 128, 0))), clipped_top=int((o[0, :, 3] > 128).sum()))
    if name == 'near':
        info['path_band'] = [float(v) for v in band(o)]
    print(name, info, flush=True)


def sit(key):
    return os.path.join(ROOT, 'Design', 'friends', 'characters', f'{key}-sit.png')


def gen_idle(key, _):
    import nb  # noqa: needs the key
    spec = IDLES[key]
    d = idle_dir(key)
    os.makedirs(d, exist_ok=True)
    base = W.on_grey(sit(key))
    base.save(os.path.join(d, 'rest.png'))
    pose = POSE.format(animal=spec['animal'], accessory=spec['accessory'])
    only = set(sys.argv[3:])
    for name, change in spec['changes'].items():
        out = os.path.join(d, f'{name}.png')
        if os.path.exists(out) or (only and name not in only):
            continue
        im, _, _ = nb.generate(pose + change, [base], aspect='3:4', size='1K')
        im.convert('RGB').resize(base.size, Image.LANCZOS).save(out)
        print(out, flush=True)


HEADROOM = 220


def unstretch(path, size):
    Wd, H = size
    H0 = H - HEADROOM
    im = Image.open(path).convert('RGB').resize((round(H0 * 3 / 4), H0), Image.LANCZOS)
    k = Wd / im.width
    im = im.resize((Wd, round(H0 * k)), Image.LANCZOS)
    top = (im.height - H0) // 2
    canvas = Image.new('RGB', (Wd, H), (138, 138, 138))
    canvas.paste(im.crop((0, max(0, top - HEADROOM), Wd, top + H0)), (0, max(0, HEADROOM - top)))
    return canvas


def keyed_frame(path, size):
    from looper import key
    a = np.asarray(unstretch(path, size)).astype(np.float32)
    alpha = key(a) * 255
    grey = (np.abs(a - 138).max(2) < 16)
    alpha[grey] = 0
    return np.dstack([a, alpha])


def box_mask(shape, bbox, boxes):
    left, top, right, bottom = bbox
    wid, hgt = right - left, bottom - top
    yy, xx = np.mgrid[:shape[0], :shape[1]].astype(np.float32)
    m = np.zeros(shape, bool)
    for x0, y0, x1, y1 in boxes:
        m |= (xx >= left + wid * x0) & (xx <= left + wid * x1) & (yy >= top + hgt * y0) & (yy <= top + hgt * y1)
    return m


def build_idle(key, _):
    from scipy import ndimage as ndi
    spec = IDLES[key]
    d = idle_dir(key)
    rest = W.keyed(os.path.join(d, 'rest.png'))
    rest = np.concatenate([np.zeros((HEADROOM,) + rest.shape[1:], np.float32), rest], 0)
    ys, xs = np.nonzero(rest[..., 3] > 128)
    bbox = (xs.min(), ys.min(), xs.max(), ys.max())
    hgt = bbox[3] - bbox[1]
    region = box_mask(rest.shape[:2], bbox, [spec['align']])
    frames = [rest]
    for name in NAMES[1:]:
        f = W.fit_head(rest, keyed_frame(os.path.join(d, f'{name}.png'), (rest.shape[1], rest.shape[0])), region)
        m = box_mask(rest.shape[:2], bbox, spec['boxes'][name])
        if name in spec.get('inside', ()):
            m &= ndi.binary_erosion((rest[..., 3] > 128) & (f[..., 3] > 128), iterations=10)
        m = ndi.gaussian_filter(m.astype(np.float32), 8)[..., None]
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
    sheet.save(os.path.join(RES, f'{key}-idle-frames.webp'), quality=90, method=6)
    a = np.asarray(sheet)[..., 3][:, :w]
    ys, xs = np.nonzero(a > 128)
    feet = xs[ys > ys.max() - 6].mean()
    print('idle', sheet.size, 'cell', (w, h), 'rest bbox', (xs.min(), ys.min(), xs.max(), ys.max()),
          'anchor', (round(feet), ys.max()), flush=True)


def hop(key, _):
    im = Image.open(os.path.join(ROOT, 'Design', 'friends', 'sprites', f'{key}-hop.png')).convert('RGBA')
    s = 346 / im.height
    w = int(round(im.width / 8 * s))
    out = Image.new('RGBA', (w * 8, 346))
    cw = im.width // 8
    for i in range(8):
        out.alpha_composite(im.crop((i * cw, 0, (i + 1) * cw, im.height)).resize((w, 346), Image.LANCZOS), (i * w, 0))
    out.save(os.path.join(RES, f'{key}-hop.webp'), quality=90, method=6)
    a = np.asarray(out)[..., 3]
    for i in range(8):
        ys, xs = np.nonzero(a[:, i * w:(i + 1) * w] > 128)
        feet = xs[ys > ys.max() - 6].mean()
        print('hop', i, 'bbox', (xs.min(), ys.min(), xs.max(), ys.max()), 'feet', round(feet))
    print('hop', out.size, 'cell', (w, 346), flush=True)


if __name__ == '__main__':
    key, step = sys.argv[1], sys.argv[2]
    names = [n for n in sys.argv[3:] if n in ('far', 'mid', 'near')] or ['far', 'mid', 'near']
    {'gen': gen, 'build': lambda k, n: [build_one(k, x) for x in n], 'gen_idle': gen_idle,
     'build_idle': build_idle, 'hop': hop}[step](key, names)
