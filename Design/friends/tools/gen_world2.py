"""Tall Grass, Harvest Field and Cottage Garden: three parallax layers like the meadow's, an idle strip and the
hop export, for one friend at a time. Bluebell Wood's gen_wood.py is the recipe this generalises.

uv run --with numpy --with pillow --with scipy python Design/friends/tools/gen_world2.py <key> gen [far mid near]
uv run --with numpy --with pillow --with scipy python Design/friends/tools/gen_world2.py <key> build [far mid near]
uv run --with numpy --with pillow --with scipy python Design/friends/tools/gen_world2.py <key> gen_idle
uv run --with numpy --with pillow --with scipy python Design/friends/tools/gen_world2.py <key> build_idle
uv run --with numpy --with pillow --with scipy python Design/friends/tools/gen_world2.py <key> hop
"""
import os, sys
import numpy as np
from PIL import Image

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..', '..'))
sys.path.insert(0, os.path.join(ROOT, 'Design', 'collage', 'tools'))
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import chain as C  # noqa: E402
import gen_wood as W  # noqa: E402

RES = os.path.join(ROOT, 'HopTalesPackage', 'Sources', 'World', 'Resources')
MEADOW = os.path.join(ROOT, 'Design', 'collage', 'raw')
TARGET = {'far': (5615, 826), 'mid': (4692, 834), 'near': (3555, 834)}
BAND = (419.5, 87)
SOURCES = {'far': ['far-src', 'far-src2', 'far-src3'], 'mid': ['mid-src', 'mid-src2', 'mid-src3'],
           'near': ['near-src3', 'near-src3', 'near-src3']}

EDIT = ("Edit this image. Keep the flat grey area at the top exactly as it is: plain untouched grey, the same size, "
        "nothing painted on it, no sky, nothing reaching up into it. Keep the torn paper strip exactly the same shape "
        "and position, with its ragged white rim along the top edge. Only repaint the scenery on the strip, and keep "
        "everything fully inside the strip. Same soft storybook watercolour with fine brown ink linework and paper "
        "grain as the original. No animals, no people, no text. ")

WORLDS = {
    'grasshopper': dict(
        name='Tall Grass', mode='path', light='calm summer daylight', far_ink=(1.5, 1.45, 1.6),
        far="Turn the rolling hills into a hazy distant view seen from deep in a summer meadow: pale green and "
            "straw-gold hills with a soft misty band of tall grass seed heads along some of the ridges. Very pale and "
            "low contrast, cooler than the original.",
        mid="Turn the green hills into a bank of tall summer grass seen close up from an insect's height: the same "
            "rise and fall of the top edge, the slopes thick with grass blades, seed heads, clover leaves and a few "
            "dandelion clocks and buttercups, all inside the strip. Mid-tone, softer than a foreground.",
        near="Keep the pale cream footpath band at exactly the same height and the same generous thickness, running "
             "straight across the whole width, completely clear and empty so dark lettering can be printed on it: a "
             "smooth bare earth path seen from an insect's height, no leaves or stems overlap it, and no white paper "
             "rim along the path's edges. On the bank above the path: big clover leaves, grass blades and a few "
             "daisies, drawn large as if we are tiny. Below the path, starting at its lower edge: giant clover "
             "leaves, grass stems, a buttercup and a few small pebbles, then the lower torn edge and deep green grass "
             "at the bottom as before."),
    'crow': dict(
        name='Harvest Field', mode='wall', light='warm golden autumn afternoon light', far_ink=(1.45, 1.5, 1.7),
        far="Turn the rolling hills into far autumn hills beyond a harvest field: hazy lilac, soft plum and pale "
            "ochre hills, with faint hedgerows along some ridges. Very pale and low contrast.",
        mid="Turn the green hills into golden harvested fields: the same rise and fall of the top edge, the slopes "
            "striped with pale gold stubble, a few round hay bales and small autumn hedgerow trees in russet and "
            "amber where the original has trees, the same size as the original trees and fully inside the strip. "
            "Mid-tone, softer than a foreground.",
        near="Turn the pale footpath band into the FACE of an old dry-stone wall running straight across the whole "
             "width: the band keeps exactly the same height and thickness, and is filled edge to edge with flat, "
             "dark slate-grey stones fitted tightly together, deep charcoal grey, with only thin darker joints, no "
             "moss and no leaves on the face, so that white chalk lettering could be written across it. The wall is "
             "taller than the band: above the band, the upper part of the bank becomes the top courses of the wall "
             "capped with a row of upright mossy coping stones, whose flat top runs straight across at about the "
             "middle of the old grassy bank. Above the coping, a thin strip of golden stubble and a few wheat "
             "stalks. Below the wall, starting at the band's lower edge: golden stubble, fallen leaves, a few poppies "
             "and wheat stalks, then the lower torn edge and ochre grass at the bottom as before."),
    'cat': dict(
        name='Cottage Garden', mode='wall', light='soft sunny late-spring light', far_ink=(1.55, 1.5, 1.6),
        far="Turn the rolling hills into gentle far hills beyond a cottage garden: soft sage and blue-green hills "
            "with faint patchwork fields and hedgerows. Very pale and low contrast, cooler than the original.",
        mid="Turn the green hills into cottage garden borders: the same rise and fall of the top edge, the slopes "
            "full of rose bushes, hollyhocks, foxgloves and lavender, with small rounded apple trees where the "
            "original has trees, the same size as the original trees and fully inside the strip. Mid-tone, softer "
            "than a foreground.",
        near="Turn the pale footpath band into the FACE of an old garden wall of soft pale brick running straight "
             "across the whole width: the band keeps exactly the same height and thickness, filled edge to edge with "
             "pale, weathered, warm cream and pale apricot bricks with faint mortar lines, very light in value, no "
             "flowers or leaves on the face, so that dark painted lettering could be written across it. The wall is "
             "taller than the band: above the band, the upper part of the bank becomes the top courses of the wall "
             "capped with a row of flat coping bricks, whose top runs straight across at about the middle of the old "
             "grassy bank. Above the coping, a thin strip of trailing flowers and a few small terracotta pots. Below "
             "the wall, starting at the band's lower edge: daisies, forget-me-nots, a watering can and small flower "
             "pots, then the lower torn edge and green grass at the bottom as before."),
}

IDLE_GESTURES = {
    'grasshopper': dict(
        subject="a grasshopper", border="same satchel",
        ear=("the long antenna at the back is swept backwards", "a little, about 10 degrees", "about 20 degrees",
             "well back, about 35 degrees"),
        sniff="the antennae are both raised and twitching forward, feeling the air.",
        tilt="head", eyes="eyes"),
    'crow': dict(
        subject="a crow", border="same blue knitted cap",
        ear=("the head feathers at the back of the head are ruffled up", "very slightly", "a little",
             "clearly, a fluffed-up crest"),
        sniff="the beak is slightly open and raised, as if about to caw softly.",
        tilt="head", eyes="eye"),
    'cat': dict(
        subject="a cat", border="same sage ribbon collar",
        ear=("the ear at the back is turned backwards", "slightly, about 10 degrees", "about 20 degrees",
             "well back, about 35 degrees, listening"),
        sniff="the nose is raised and the whiskers fanned forward, sniffing the air.",
        tilt="head", eyes="eyes"),
}
NAMES = W.NAMES


def cfg(key):
    return WORLDS[key]


def raw_dir(key):
    return os.path.join(ROOT, 'Design', 'friends', 'tools', 'nb', key)


def gen(key, names):
    import nb  # noqa: needs the key
    c = cfg(key)
    os.makedirs(raw_dir(key), exist_ok=True)
    for name in names:
        for i, src in enumerate(SOURCES[name]):
            out = os.path.join(raw_dir(key), f'{name}-{i + 1}.png')
            if os.path.exists(out):
                continue
            ref = Image.open(os.path.join(MEADOW, f'{src}.png'))
            prompt = EDIT + f"Light: {c['light']}. " + c[name]
            im, text, _ = nb.generate(prompt, [ref], aspect='21:9', size='2K')
            im.convert('RGB').resize(ref.size, Image.LANCZOS).save(out)
            with open(out + '.src', 'w') as f:
                f.write(src)
            print(out, im.size, text[:80], flush=True)


def source_of(key, p):
    s = os.path.join(raw_dir(key), p.rstrip('f') + '.png.src')
    if os.path.exists(s):
        return open(s).read().strip()
    i = int(p.rstrip('f').split('-')[1]) - 1
    return SOURCES[p.split('-')[0]][i % 3]


def load(key, p):
    flip = p.endswith('f')
    a = C.load(os.path.join(raw_dir(key), p.rstrip('f') + '.png'))
    return a[:, ::-1].copy() if flip else a


def trim_above_rim(a, allowance=140, fade=60):
    from scipy import ndimage as ndi
    bright = (a[..., :3].mean(2) > 228) & (a[..., 3] > 128)
    H, Wd = bright.shape
    rim = np.full(Wd, H, np.float32)
    for x in range(Wd):
        ys = np.nonzero(bright[int(H * 0.25):int(H * 0.85), x])[0]
        if len(ys):
            rim[x] = ys[0] + int(H * 0.25)
    rim = ndi.median_filter(rim, 301, mode='wrap')
    y = np.arange(H, dtype=np.float32)[:, None]
    keep = np.clip((y - (rim[None, :] - allowance - fade)) / fade, 0, 1)
    rgb = a[..., :3]
    grey = ((np.abs(rgb[..., 0] - rgb[..., 1]) < 10) & (np.abs(rgb[..., 1] - rgb[..., 2]) < 10)
            & (rgb.mean(2) > 110) & (rgb.mean(2) < 165) & (y < rim[None, :] - 4))
    grey = ndi.binary_dilation(ndi.binary_opening(grey, iterations=2), iterations=2)
    out = a.copy()
    out[..., 3] *= keep * ~grey
    return out


def normalise(sec, band, ref_band):
    cs, ts = band
    cr, tr = ref_band
    s = tr / ts if 0.8 < tr / ts < 1.25 else 1.0
    H, Wd, _ = sec.shape
    im = Image.fromarray(sec.clip(0, 255).astype(np.uint8), 'RGBA').resize((int(Wd * s), int(H * s)), Image.LANCZOS)
    b = np.asarray(im).astype(np.float32)
    out = np.zeros((H, b.shape[1], 4), np.float32)
    dy = int(round(cr - cs * s))
    ys0, yd0 = max(0, -dy), max(0, dy)
    hh = min(b.shape[0] - ys0, H - yd0)
    out[yd0:yd0 + hh] = b[ys0:ys0 + hh]
    if yd0 + hh < H:
        out[yd0 + hh:] = out[yd0 + hh - 1]
    return out


def band_of(mode, a, key):
    if mode == 'path':
        return C.path_band(a)
    r, g, b, al = a[..., 0], a[..., 1], a[..., 2], a[..., 3] > 200
    if key == 'crow':
        lum = (r + g + b) / 3
        hit = (lum < 125) & (np.abs(r - b) < 40) & al
    else:
        hit = (r > 200) & (g > 170) & (b > 140) & (r - b > 12) & al
    frac = hit.mean(1)
    rows = np.nonzero(frac > float(os.environ.get('WALL_FRAC', 0.45)))[0]
    runs, start = [], rows[0]
    for i in range(1, len(rows)):
        if rows[i] > rows[i - 1] + 3:
            runs.append((start, rows[i - 1]))
            start = rows[i]
    runs.append((start, rows[-1]))
    lo, hi = max(runs, key=lambda t: t[1] - t[0])
    return (lo + hi) / 2, hi - lo


def build(key, names):
    c = cfg(key)
    for name in names:
        paths = sorted(p[:-4] for p in os.listdir(raw_dir(key)) if p.startswith(name + '-') and p.endswith('.png'))
        pick = os.environ.get(name.upper())
        if pick:
            paths = [f'{name}-{k}' for k in pick.split(',')]
        C.O = {'far': 520, 'mid': 420, 'near': 300}[name]
        secs = [load(key, p) for p in paths]
        if name != 'near':
            allow = int(os.environ.get(name.upper() + '_ALLOW', 90))
            secs = [trim_above_rim(s, allowance=allow) for s in secs]
        if name == 'near':
            secs = [trim_above_rim(s, allowance=int(os.environ.get('NEAR_ALLOW', 110)), fade=40) for s in secs]
            ref_band = band_of(c['mode'], secs[0], key)
            secs = [normalise(s, band_of(c['mode'], s, key), ref_band) for s in secs]
            print('bands', [band_of(c['mode'], s, key) for s in secs], flush=True)
        n = len(secs)
        span = float(os.environ.get(name.upper() + '_SPAN', 0.42))
        twin = lambda a, b: a.rstrip('f') == b.rstrip('f') and a.endswith('f') != b.endswith('f')
        joins = [W.best_join(secs[i], secs[(i + 1) % n], span, twin(paths[i], paths[(i + 1) % n]))[1:]
                 for i in range(n)]
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
        Wt, Ht = TARGET[name]
        im = Image.fromarray(tile.clip(0, 255).astype(np.uint8), 'RGBA')
        if name == 'near':
            cr, tr = ref_band
            s = BAND[1] / tr
            im = im.resize((int(im.width * s), int(im.height * s)), Image.LANCZOS)
            y0 = int(round(cr * s - BAND[0]))
        else:
            ref = np.asarray(Image.open(os.path.join(RES, f'{name}-day.webp')))
            r_ref = np.median(np.argmax(ref[..., 3] > 128, 0))
            r_t = np.median(np.argmax(tile[..., 3] > 128, 0))
            y0 = int(round(r_t - r_ref))
        a = np.asarray(im)
        canvas = np.zeros((Ht, a.shape[1], 4), np.uint8)
        ys, yd = max(0, y0), max(0, -y0)
        hh = min(a.shape[0] - ys, Ht - yd)
        canvas[yd:yd + hh] = a[ys:ys + hh]
        if yd + hh < Ht:
            canvas[yd + hh:] = canvas[yd + hh - 1]
        rgb = canvas[..., :3].astype(np.float32)
        grey = ((np.abs(rgb[..., 0] - rgb[..., 1]) < 9) & (np.abs(rgb[..., 1] - rgb[..., 2]) < 9)
                & (rgb.mean(2) > 110) & (rgb.mean(2) < 165) & (canvas[..., 3] > 100))
        grey[int(Ht * 0.42):] = False
        from scipy import ndimage as ndi
        grey = ndi.binary_dilation(ndi.binary_opening(grey, iterations=2), iterations=3)
        canvas[..., 3][grey] = 0
        ramp = np.clip(np.arange(Ht, dtype=np.float32) / 40, 0, 1)[:, None]
        canvas[..., 3] = (canvas[..., 3] * ramp).astype(np.uint8)
        if name == 'far':
            k = np.array(c['far_ink'])
            rgb = canvas[..., :3].astype(np.float32)
            canvas[..., :3] = (255 - (255 - rgb) * k).clip(0, 255).astype(np.uint8)
        out = Image.fromarray(canvas, 'RGBA').resize((Wt, Ht), Image.LANCZOS)
        out.save(os.path.join(RES, f'{name}-{key}.webp'), quality=88, method=6)
        o = np.asarray(out).astype(np.float32)
        print(name, dict(size=out.size, sections=paths, ridge=float(np.median(np.argmax(o[..., 3] > 128, 0)))),
              flush=True)


def idle_prompts(key):
    g = IDLE_GESTURES[key]
    base = (f"Edit this image of a sticker of {g['subject']} on a flat grey background. Keep everything identical: "
            f"the same {g['subject'].split()[-1]}, same size, same position, same body, same legs and feet, the "
            f"{g['border']}, same watercolour painting, same white sticker border, same flat grey background. "
            "Change only this: ")
    ear, e1, e2, e3 = g['ear']
    e = g['eyes']
    return base, {
        'blink-half': f"the {e} half closed, sleepy, the upper eyelids covering half of each eye.",
        'blink': f"the {e} gently closed, a calm blink, drawn as soft curved lash lines.",
        'ear-1': f"{ear} {e1}.",
        'ear-2': f"{ear} {e2}.",
        'ear': f"{ear} {e3}.",
        'tilt-1': "the head is tilted a little downwards, about 4 degrees.",
        'tilt-2': "the head is tilted downwards about 8 degrees, curious.",
        'tilt': "the head is tilted downwards about 12 degrees, looking at something on the ground.",
        'sniff': g['sniff'],
    }


def sit(key):
    return os.path.join(ROOT, 'Design', 'friends', 'characters', f'{key}-sit.png')


def idle_raw(key):
    return os.path.join(raw_dir(key), 'idle')


def gen_idle(key, _):
    import nb  # noqa: needs the key
    os.makedirs(idle_raw(key), exist_ok=True)
    base_img = W.on_grey(sit(key))
    base_img.save(os.path.join(idle_raw(key), 'rest.png'))
    base, changes = idle_prompts(key)
    for name, change in changes.items():
        out = os.path.join(idle_raw(key), f'{name}.png')
        if os.path.exists(out):
            continue
        im, _, _ = nb.generate(base + change, [base_img], aspect='3:4', size='1K')
        im.convert('RGB').resize(base_img.size, Image.LANCZOS).save(out)
        print(out, flush=True)


def head_regions(key, rest):
    ys, xs = np.nonzero(rest[..., 3] > 128)
    top, bottom, left, right = ys.min(), ys.max(), xs.min(), xs.max()
    yy, xx = np.mgrid[:rest.shape[0], :rest.shape[1]].astype(np.float32)
    h, w = bottom - top, right - left
    face_side = rest[..., 3][:int(top + h * 0.4)] > 128
    cols = np.nonzero(face_side.any(0))[0]
    facing_right = cols.mean() > (left + right) / 2
    side = (xx > left + w * 0.35) if facing_right else (xx < right - w * 0.35)
    fit = (yy > top + h * 0.1) & (yy < top + h * 0.45) & side
    head = (yy < top + h * float(os.environ.get('HEAD', 0.48))) & side
    tops = yy < top + h * float(os.environ.get('TOP', 0.2))
    face = head & (yy > top + h * float(os.environ.get('FACE_TOP', 0.22)))
    return fit, head | tops, face, (top, bottom)


def build_idle(key, _):
    from scipy import ndimage as ndi
    rest = W.keyed(os.path.join(idle_raw(key), 'rest.png'))
    fit, move_all, face, (top, bottom) = head_regions(key, rest)
    frames = [rest]
    stand_in = {'ear': 'ear-2', 'ear-2': 'ear-1', 'sniff': 'ear-1', 'tilt': 'blink-half', 'tilt-1': 'rest',
                'tilt-2': 'rest', 'blink-half': 'blink', 'ear-1': 'rest'}
    for name in NAMES[1:]:
        pick = name
        while not os.path.exists(os.path.join(idle_raw(key), f'{pick}.png')):
            pick = stand_in[pick]
        if pick != name:
            print('stand-in', name, '->', pick, flush=True)
        if pick == 'rest':
            frames.append(rest)
            continue
        f = W.fit_head(rest, W.keyed(os.path.join(idle_raw(key), f'{pick}.png')), fit)
        inner = ndi.binary_erosion(f[..., 3] > 128, iterations=10) | ndi.binary_erosion(rest[..., 3] > 128,
                                                                                        iterations=10)
        move = face if pick.startswith('blink') else move_all
        m = ndi.gaussian_filter(ndi.binary_erosion(move, iterations=6).astype(np.float32), 4)[..., None]
        blended = rest * (1 - m) + f * m
        solid = ndi.binary_opening(blended[..., 3] > 60, iterations=2)
        lab, k = ndi.label(solid)
        if k > 1:
            sizes = ndi.sum(solid, lab, range(1, k + 1))
            keep = np.isin(lab, 1 + np.nonzero(sizes > sizes.max() * 0.1)[0])
            blended[..., 3] *= ndi.binary_dilation(keep, iterations=3)
        frames.append(blended)
    alpha = np.max([f[..., 3] for f in frames], 0) > 10
    ys, xs = np.nonzero(alpha)
    pad = 24
    y0, y1 = max(0, ys.min() - pad), min(rest.shape[0], ys.max() + pad)
    x0, x1 = max(0, xs.min() - pad), min(rest.shape[1], xs.max() + pad)
    cells = [f[y0:y1, x0:x1] for f in frames]
    S = 344 / (bottom - top)
    w, h = int(round((x1 - x0) * S)), int(round((y1 - y0) * S))
    sheet = Image.new('RGBA', (w * len(cells), h))
    for i, cimg in enumerate(cells):
        sheet.alpha_composite(
            Image.fromarray(cimg.clip(0, 255).astype(np.uint8), 'RGBA').resize((w, h), Image.LANCZOS), (i * w, 0))
    sheet.save(os.path.join(RES, f'{key}-idle-frames.webp'), quality=90, method=6)
    a = np.asarray(sheet)[..., 3][:, :w]
    ys, xs = np.nonzero(a > 128)
    feet = xs[ys > ys.max() - 6].mean()
    print('idle', sheet.size, 'cell', (w, h), 'rest top', ys.min(), 'anchor', (round(feet), ys.max() + 1),
          flush=True)


def hop(key, _):
    im = Image.open(os.path.join(ROOT, 'Design', 'friends', 'sprites', f'{key}-hop.png')).convert('RGBA')
    s = 346 / im.height
    w = int(round(im.width / 8 * s))
    out = Image.new('RGBA', (w * 8, 346))
    cw = im.width // 8
    for i in range(8):
        out.alpha_composite(im.crop((i * cw, 0, (i + 1) * cw, im.height)).resize((w, 346), Image.LANCZOS),
                            (i * w, 0))
    out.save(os.path.join(RES, f'{key}-hop.webp'), quality=90, method=6)
    a = np.asarray(out)[..., 3]
    for i in range(8):
        ys, xs = np.nonzero(a[:, i * w:(i + 1) * w] > 128)
        feet = xs[ys > ys.max() - 15].mean()
        print('hop', i, 'top', ys.min(), 'bottom', ys.max(), 'h', ys.max() - ys.min(), 'feet x', round(feet))
    print('hop', out.size, 'cell', (w, 346), flush=True)


if __name__ == '__main__':
    key, step, names = sys.argv[1], sys.argv[2], sys.argv[3:] or ['far', 'mid', 'near']
    {'gen': gen, 'build': build, 'gen_idle': gen_idle, 'build_idle': build_idle, 'hop': hop}[step](key, names)
