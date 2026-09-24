import numpy as np
from PIL import Image, ImageDraw, ImageFilter
from scipy import ndimage as ndi
import math, os, sys

WW, WH = 2340, 844
TAU = 2 * math.pi / WW
OFFS = (-WW, 0, WW)
S = float(os.environ.get("PS", "1"))
W, H = int(WW * S), int(WH * S)
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "paint")
os.makedirs(OUT, exist_ok=True)
rng = np.random.default_rng(7)

Y, X = np.mgrid[0:H, 0:W].astype(np.float32)
YW, XW = Y / S, X / S


def ground(x):
    # periodic over WW: 2 and 6 whole cycles (was x/190 and x/63)
    return 448 - 10 * np.sin(x * 2 * TAU) - 6 * np.sin(x * 6 * TAU + 1)


def psin(x, k, ph=0.0):
    return np.sin(x * k * TAU + ph)


def pgrad(a):
    return (np.roll(a, -1, axis=-1) - np.roll(a, 1, axis=-1)) / 2



def c(hexs):
    hexs = hexs.lstrip("#")
    return np.array([int(hexs[i:i + 2], 16) for i in (0, 2, 4)], np.float32)


def ramp(t, stops):
    t = np.clip(t, 0, 1)
    out = np.zeros(t.shape + (3,), np.float32)
    ps = [p for p, _ in stops]
    cs = [c(col) for _, col in stops]
    for ch in range(3):
        out[..., ch] = np.interp(t, ps, [cc[ch] for cc in cs])
    return out


def smooth(a, b, x):
    t = np.clip((x - a) / (b - a), 0, 1)
    return t * t * (3 - 2 * t)


def paint_bands(s, bands=5, soft=0.18, mix=0.7):
    q = s * bands
    f = q - np.floor(q)
    q2 = (np.floor(q) + smooth(0.5 - soft, 0.5 + soft, f)) / bands
    return mix * q2 + (1 - mix) * s


def fbm(h, w, base, octaves=4, seed=0, aniso=(1, 1)):
    """tileable in x (period w)"""
    r = np.random.default_rng(seed)
    out = np.zeros((h, w), np.float32)
    amp, tot = 1.0, 0.0
    sc = base
    for _ in range(octaves):
        gh = max(2, int(round(h / (sc * aniso[0]))))
        gw = max(2, int(round(w / (sc * aniso[1]))))
        g = r.standard_normal((gh, gw)).astype(np.float32)
        z = ndi.zoom(g, (h / gh, w / gw), order=3, mode="grid-wrap", grid_mode=True)
        z = z[:h, :w]
        if z.shape != (h, w):
            z = np.pad(z, ((0, h - z.shape[0]), (0, w - z.shape[1])), mode="wrap")
        out += amp * z
        tot += amp
        amp *= 0.5
        sc /= 2
    return out / tot


def fbm1(n, base, octaves=4, seed=0):
    return fbm(1, n, base, octaves, seed)[0] if False else _fbm1(n, base, octaves, seed)


def _fbm1(n, base, octaves, seed):
    r = np.random.default_rng(seed)
    out = np.zeros(n, np.float32)
    amp, tot, sc = 1.0, 0.0, base
    xs = np.arange(n)
    for _ in range(octaves):
        k = max(2, int(round(n / sc)))
        g = r.standard_normal(k)
        out += amp * _cubic(xs * k / n, g)
        tot += amp
        amp *= 0.5
        sc /= 2
    return out / tot


def _cubic(t, g):
    n = len(g)
    i = np.floor(t).astype(int)
    f = t - i
    p0, p1, p2, p3 = g[(i - 1) % n], g[i % n], g[(i + 1) % n], g[(i + 2) % n]
    return p1 + 0.5 * f * (p2 - p0 + f * (2 * p0 - 5 * p1 + 4 * p2 - p3 + f * (3 * (p1 - p2) + p3 - p0)))


def save(name, rgb, alpha=None):
    rgb = np.clip(rgb, 0, 255).astype(np.uint8)
    if alpha is None:
        Image.fromarray(rgb, "RGB").save(f"{OUT}/{name}.png", optimize=True)
    else:
        a = (np.clip(alpha, 0, 1) * 255).astype(np.uint8)
        Image.fromarray(np.dstack([rgb, a]), "RGBA").save(f"{OUT}/{name}.png", optimize=True)


def over(dst_rgb, dst_a, src_rgb, src_a):
    sa = src_a[..., None]
    out_a = src_a + dst_a * (1 - src_a)
    out = (src_rgb * sa + dst_rgb * dst_a[..., None] * (1 - sa)) / np.maximum(out_a[..., None], 1e-5)
    return out, out_a


# ---------- puff solids (clouds and tree crowns) ----------

def puff_field(circles, box=None):
    """circles in world units: (cx, cy, r, zbias). returns sd(px), nx, ny, nz, id over full canvas"""
    zbest = np.full((H, W), -1e9, np.float32)
    sd = np.full((H, W), -1e9, np.float32)
    nx = np.zeros((H, W), np.float32)
    ny = np.zeros((H, W), np.float32)
    nz = np.zeros((H, W), np.float32)
    circles = [(cx + o, cy, r, zb) for (cx, cy, r, zb) in circles for o in OFFS if -r - 4 < cx + o < WW + r + 4]
    for (cx, cy, r, zb) in circles:
        x0, x1 = int(max(0, (cx - r - 2) * S)), int(min(W, (cx + r + 2) * S))
        y0, y1 = int(max(0, (cy - r - 2) * S)), int(min(H, (cy + r + 2) * S))
        if x0 >= x1 or y0 >= y1:
            continue
        dx = XW[y0:y1, x0:x1] - cx
        dy = YW[y0:y1, x0:x1] - cy
        d2 = dx * dx + dy * dy
        d = np.sqrt(d2)
        s = (r - d) * S
        np.maximum(sd[y0:y1, x0:x1], s, out=sd[y0:y1, x0:x1])
        inside = d2 < r * r
        z = np.where(inside, np.sqrt(np.maximum(r * r - d2, 0)) + zb, -1e9)
        win = z > zbest[y0:y1, x0:x1]
        zbest[y0:y1, x0:x1] = np.where(win, z, zbest[y0:y1, x0:x1])
        nx[y0:y1, x0:x1] = np.where(win, dx / r, nx[y0:y1, x0:x1])
        ny[y0:y1, x0:x1] = np.where(win, dy / r, ny[y0:y1, x0:x1])
        nz[y0:y1, x0:x1] = np.where(win, np.sqrt(np.maximum(1 - d2 / (r * r), 0)), nz[y0:y1, x0:x1])
    return sd, nx, ny, nz


L = np.array([-0.55, -0.62, 0.56])
L = L / np.linalg.norm(L)


def form_light(sd, nx, ny, nz, sigma, k, mx):
    m = (sd > 0).astype(np.float32)
    B = ndi.gaussian_filter(m, sigma * S, mode=('nearest', 'wrap'))
    gy_ = np.gradient(B, axis=0)
    gx_ = pgrad(B)
    K = k * S
    gn = np.stack([-gx_ * K, -gy_ * K, np.ones_like(B)])
    gn /= np.linalg.norm(gn, axis=0) + 1e-6
    nx2, ny2, nz2 = nx * (1 - mx) + gn[0] * mx, ny * (1 - mx) + gn[1] * mx, nz * (1 - mx) + gn[2] * mx
    nn = np.sqrt(nx2 ** 2 + ny2 ** 2 + nz2 ** 2) + 1e-6
    return (nx2 * L[0] + ny2 * L[1] + nz2 * L[2]) / nn


def cloud_circles(cx, base, width, height, seed, n=70, up=(-2.7, -0.45)):
    r = np.random.default_rng(seed)
    circles = []
    # flat base row
    x = cx - width / 2
    while x < cx + width / 2:
        rr = r.uniform(46, 84) * (0.55 + 0.45 * (1 - abs(x - cx) / (width / 2)))
        circles.append([x, base - rr * 0.55, rr])
        x += rr * r.uniform(0.8, 1.1)
    for _ in range(n):
        p = circles[r.integers(len(circles))]
        ang = r.uniform(*up)
        rr = p[2] * r.uniform(0.62, 1.0)
        nxp = p[0] + math.cos(ang) * p[2] * 0.75
        nyp = p[1] + math.sin(ang) * p[2] * 0.75
        top = base - nyp
        env = height * (1 - ((nxp - cx) / (width * 0.5)) ** 2)
        if top + rr * 0.6 > env or rr < 20:
            continue
        circles.append([nxp, nyp, rr])
    return [(a, b, rr, (base - b) * 0.18) for a, b, rr in circles]


def render_cloud(circles, base, height, haze, seed):
    sd, nx, ny, nz = puff_field(circles)
    edge_noise = fbm(H, W, 18 * S, 3, seed) * 1.6 * S
    cut = smooth(0, 3 * S, (base - YW) * S + fbm(H, W, 40 * S, 2, seed + 1) * 6 * S)
    alpha = np.clip((sd + edge_noise) / 1.3 + 0.5, 0, 1) * cut
    lam = form_light(sd, nx, ny, nz, 30, 70, 0.72)
    lam = ndi.gaussian_filter(lam, 2.2 * S, mode=('nearest', 'wrap'))
    s = np.clip((lam + 0.2) / 1.1, 0, 1)
    s = paint_bands(s, 4, 0.2, 0.5)
    under = smooth(base - height * 0.6, base, YW)
    s = s * (1 - 0.6 * under)
    tex = fbm(H, W, 7 * S, 3, seed + 2)
    s = np.clip(s + tex * 0.035, 0, 1)
    col = ramp(s, [(0, "#7E8DB8"), (0.3, "#A7B6D6"), (0.55, "#DCE4F0"), (0.78, "#FBFCFD"), (1, "#FFF6E0")])
    rim = smooth(3 * S, 0, sd) * smooth(0.1, 0.5, -(nx * 0.7 + ny * 0.7)) * (sd > -1)
    col = col + rim[..., None] * (c("#FFFFFF") - col) * 0.6
    col = col * (1 - haze) + c("#D6E8F0") * haze
    return col, alpha


def sky():
    t = YW / 430
    col = ramp(t, [(0, "#2A66BD"), (0.35, "#4A8DD6"), (0.7, "#8FC1E6"), (0.92, "#C9E3EE"), (1, "#E3EFEA")])
    gdx = np.abs(XW - 150)
    gdx = np.minimum(gdx, WW - gdx)
    glow = np.exp(-((gdx / 900) ** 2 + ((YW + 80) / 520) ** 2))
    col = col + glow[..., None] * (c("#FFF4D6") - col) * 0.35
    col += fbm(H, W, 200 * S, 3, 11)[..., None] * 3
    a = np.ones((H, W), np.float32)
    # horizon cloud banks (small, hazy)
    r = np.random.default_rng(3)
    bank = []
    for i in range(34):
        x = r.uniform(0, WW)
        bank += cloud_circles(x, 372 + r.uniform(-8, 10), r.uniform(120, 260), r.uniform(40, 80), 100 + i, 18)
    cc, ca = render_cloud([(x, y, rr * 0.5, z) for x, y, rr, z in bank], 385, 60, 0.5, 5)
    col, a = over(col, a, cc, ca * 0.85)
    towers = [(250, 385, 540, 330, 1), (1080, 392, 420, 190, 2), (1760, 380, 700, 320, 4), (2260, 395, 340, 160, 6)]
    for (cx, base, w, h, sd) in towers:
        cir = cloud_circles(cx, base, w, h, sd, 260, (-2.35, -0.8))
        cc, ca = render_cloud(cir, base, h, 0.08, sd + 20)
        col, a = over(col, a, cc, ca)
    # high wisps
    wisp = fbm(H, W, 60 * S, 4, 31, aniso=(0.25, 3.0))
    wm = smooth(0.45, 0.95, wisp) * smooth(0, 60, YW) * (1 - smooth(120, 200, YW)) * 0.35
    col = col + wm[..., None] * (c("#F4F8FB") - col)
    save("sky-day", col)
    return col


def ridge_fill(top, color_fn, soft=1.0):
    alpha = np.clip((YW - top[None, :]) * S / soft + 0.5, 0, 1)
    return color_fn(), alpha


def far():
    xs = np.arange(W) / S
    col = np.zeros((H, W, 3), np.float32)
    a = np.zeros((H, W), np.float32)
    # distant range
    t1 = 318 + _fbm1(W, 300 * S, 5, 41) * 55 - 22 * psin(xs, 1)
    haze = smooth(280, 420, YW)
    c1 = ramp(haze, [(0, "#9DBAD6"), (1, "#C9DDE6")])
    lit = ndi.gaussian_filter1d(pgrad(ndi.gaussian_filter1d(t1, 14 * S, mode='wrap')) * S, 10 * S, mode='wrap')
    near_top = np.exp(-np.maximum(YW - t1[None, :], 0) / 40)
    c1 = c1 + (np.clip(-lit * 30, -10, 16)[None, :] * near_top)[..., None] * np.array([1.0, 1.0, 0.8])
    rr, aa = ridge_fill(t1, lambda: c1, 0.9)
    col, a = over(col, a, rr, aa)
    # forested nearer range with scalloped crowns
    base2 = 378 + _fbm1(W, 280 * S, 4, 42) * 20
    bumps = np.zeros(W, np.float32)
    r = np.random.default_rng(9)
    x = 0
    while x < WW:
        rad = r.uniform(5, 11)
        i0, i1 = int((x - rad) * S), int((x + rad) * S)
        seg = np.arange(max(0, i0), min(W, i1))
        dx = seg / S - x
        bumps[seg] = np.maximum(bumps[seg], np.sqrt(np.maximum(rad ** 2 - dx ** 2, 0)) * 0.8)
        x += rad * r.uniform(1.0, 1.6)
    t2 = base2 - bumps
    tex = fbm(H, W, 6 * S, 3, 43)
    v = smooth(360, 460, YW)
    c2 = ramp(v, [(0, "#7FA7A6"), (1, "#A9C7C6")])
    c2 = c2 + tex[..., None] * 6
    rr, aa = ridge_fill(t2, lambda: c2, 0.9)
    col, a = over(col, a, rr, aa)
    # haze band
    hz = smooth(350, 470, YW) * 0.45
    col = col + hz[..., None] * (c("#D2E4E8") - col)
    save("far-day", col, a)
    return col, a


def tree_circles(cx, gy, h, w, seed, n=26):
    r = np.random.default_rng(seed)
    out = []
    cyc = gy - h * 0.6
    clumps = max(4, int(w / 14))
    for i in range(clumps):
        ang = r.uniform(math.pi * 0.95, math.pi * 2.05)
        rad = r.uniform(0.2, 1.0)
        kx = cx + math.cos(ang) * rad * w * 0.34
        ky = cyc + math.sin(ang) * rad * h * 0.3 + h * 0.06
        kr = r.uniform(0.2, 0.3) * w
        for j in range(7):
            a2 = r.uniform(0, 2 * math.pi)
            rr = kr * r.uniform(0.35, 0.6)
            x = kx + math.cos(a2) * kr * 0.55
            y = ky + math.sin(a2) * kr * 0.45
            out.append((x, y, rr, -(y - cyc) * 0.5 + r.uniform(0, 3)))
        out.append((kx, ky, kr * 0.8, -(ky - cyc) * 0.5))
    return out


def render_trees(trees, seed, lit_mix=1.0, far_haze=0.0, pal=None):
    pal = pal or [(0, "#1F4A3E"), (0.28, "#2F6446"), (0.5, "#4F8A4A"), (0.72, "#86B75A"), (1, "#C9DC86")]
    circles, trunks = [], []
    for (cx, gy, h, w, sd) in trees:
        circles += tree_circles(cx, gy, h, w, sd)
        trunks.append((cx, gy, h, w))
    sd, nx, ny, nz = puff_field(circles)
    en = fbm(H, W, 4 * S, 2, seed) * 1.8 * S
    alpha = np.clip((sd + en) / 1.2 + 0.5, 0, 1)
    lam = form_light(sd, nx, ny, nz, 10, 30, 0.5)
    s = np.clip((lam + 0.3) / 1.2, 0, 1)
    dap = fbm(H, W, 5 * S, 3, seed + 1)
    s = paint_bands(np.clip(s + dap * 0.12, 0, 1), 5, 0.12, 0.75)
    col = ramp(s, pal)
    col = col * (1 - far_haze) + c("#B9D3CC") * far_haze
    # trunks
    tr = np.zeros((H, W), np.float32)
    for (cx, gy, h, w) in trunks:
        tw = max(1.5, w * 0.04)
        dxw = np.abs(XW - cx)
        dxw = np.minimum(dxw, WW - dxw)
        m = (dxw < tw) & (YW > gy - h * 0.45) & (YW < gy + 2)
        tr = np.maximum(tr, m.astype(np.float32))
    tcol = np.broadcast_to(c("#5A4A3A") * (1 - far_haze) + c("#8FA7A0") * far_haze, (H, W, 3))
    out_c, out_a = over(np.zeros((H, W, 3), np.float32), np.zeros((H, W), np.float32), tcol, tr)
    out_c, out_a = over(out_c, out_a, col, alpha)
    return out_c, out_a


def hill(top, pal, seed, shadow_seed, light_k=60, stripe=True):
    v = smooth(0, 220, YW - top[None, :])
    col = ramp(v, pal)
    slope = pgrad(top) * S
    litv = np.clip(-slope * light_k, -26, 26)[None, :] * np.exp(-(YW - top[None, :]) / 90)
    col = col + litv[..., None] * np.array([0.9, 1.0, 0.55])
    if stripe:
        st = fbm(H, W, 30 * S, 3, seed, aniso=(0.12, 2.5))
        col = col + st[..., None] * np.array([7, 9, 4])
    cs = fbm(H, W, 260 * S, 3, shadow_seed)
    sh = 0 * smooth(0.1, 0.35, cs) * 0.4
    col = col * (1 - sh[..., None]) + sh[..., None] * col * np.array([0.55, 0.72, 0.98])
    rim = np.exp(-np.maximum(YW - top[None, :], 0) / 3.5) * 0.45
    col = col + rim[..., None] * (c("#E6F0A6") - col)
    alpha = np.clip((YW - top[None, :]) * S + 0.5, 0, 1)
    return col, alpha


def mid():
    xs = np.arange(W) / S
    col = np.zeros((H, W, 3), np.float32)
    a = np.zeros((H, W), np.float32)
    tA = 398 + 20 * psin(xs, 1, 1) + 12 * psin(xs, 4) + _fbm1(W, 200 * S, 3, 51) * 6
    ca, aa = hill(tA, [(0, "#9CC77A"), (0.5, "#7FB364"), (1, "#6CA55A")], 52, 53)
    # distant tree line sitting on hill A
    r = np.random.default_rng(55)
    trees = []
    for cx in list(r.uniform(0, WW, 38)):
        gy = float(np.interp(cx, xs, tA)) + 6
        sz = r.uniform(18, 34)
        trees.append((cx, gy, sz, sz * r.uniform(0.9, 1.4), int(r.integers(1e6))))
    tc, ta = render_trees(trees, 56, far_haze=0.35, pal=[(0, "#35604F"), (0.3, "#46775A"), (0.55, "#6A9A62"), (0.8, "#A3C47E"), (1, "#D5E3A4")])
    col, a = over(col, a, tc, ta)
    col, a = over(col, a, ca, aa)
    tB = 428 + 16 * psin(xs, 1, 3) + 10 * psin(xs, 5, 2) + _fbm1(W, 180 * S, 3, 57) * 6
    cb, ab = hill(tB, [(0, "#8CC063"), (0.45, "#69A64E"), (1, "#4F8C41")], 58, 59)
    # hedgerow + trees along hill B crest
    trees = []
    for cx in [150, 640, 700, 1210, 1590, 2010, 2080]:
        cx += r.uniform(-20, 20)
        gy = float(np.interp(cx, xs, tB)) + 8
        sz = r.uniform(95, 150)
        trees.append((cx, gy, sz, sz * r.uniform(0.8, 1.2), int(r.integers(1e6))))
    for cx in r.uniform(0, WW, 60):
        gy = float(np.interp(cx, xs, tB)) + 10
        sz = r.uniform(22, 36)
        trees.append((cx, gy, sz, sz * 1.5, int(r.integers(1e6))))
    tc, ta = render_trees(trees, 60, far_haze=0.12)
    col, a = over(col, a, tc, ta)
    col, a = over(col, a, cb, ab)
    save("mid-day", col, a)
    return col, a


def blades(img_w, img_h, ss, specs):
    im = Image.new("RGBA", (img_w * ss, img_h * ss), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    specs = [(x + o * S, y, h, lean, wid, col) for (x, y, h, lean, wid, col) in specs for o in OFFS if -60 * S < x + o * S < W + 60 * S]
    for (x, y, h, lean, wid, col) in specs:
        x, y, h, wid = x * ss, y * ss, h * ss, wid * ss
        tipx = x + lean * h
        mx = x + lean * h * 0.45
        pts = [(x - wid, y), (mx - wid * 0.5, y - h * 0.55), (tipx, y - h), (mx + wid * 0.3, y - h * 0.5), (x + wid, y)]
        d.polygon(pts, fill=col)
    return im.resize((img_w, img_h), Image.LANCZOS)


def near():
    xs = np.arange(W) / S
    g = ground(xs)
    col = np.zeros((H, W, 3), np.float32)
    a = np.zeros((H, W), np.float32)
    # meadow body
    dv = YW - g[None, :]
    base = ramp(smooth(0, 380, dv), [(0, "#A7CB63"), (0.25, "#8DBD55"), (0.6, "#6FA447"), (1, "#4D8639")])
    wind = fbm(H, W, 26 * S, 4, 71, aniso=(0.18, 1.8))
    base = base + wind[..., None] * np.array([16, 18, 8])
    cs = fbm(H, W, 300 * S, 3, 72)
    sh = 0 * smooth(0.1, 0.45, cs) * 0.3
    base = base * (1 - sh[..., None]) + sh[..., None] * base * np.array([0.6, 0.74, 0.95])
    ma = np.clip(dv * S + 0.5, 0, 1)
    col, a = over(col, a, base, ma)
    # worn path: soft earth band just below ground line
    pw = 30 + 6 * psin(xs, 3)
    pm = smooth(-2, 3, dv) * (1 - smooth(pw[None, :] - 8, pw[None, :] + 4, dv))
    pm = pm * np.clip(0.85 + fbm(H, W, 10 * S, 3, 73) * 0.5, 0, 1)
    pc = ramp(smooth(0, 34, dv), [(0, "#E8D3A2"), (1, "#C9AD7A")]) + fbm(H, W, 3 * S, 2, 74)[..., None] * 8
    col = col * (1 - pm[..., None]) + pc * pm[..., None]
    col = np.clip(col, 0, 255)
    # grass blades: short fringe above ground line, long blades along path bottom and foreground
    r = np.random.default_rng(75)
    specs = []
    greens = [(118, 170, 72), (142, 189, 84), (96, 150, 64), (174, 206, 104), (80, 132, 58)]
    for _ in range(int(9000)):
        x = r.uniform(0, WW)
        gy = float(ground(x))
        h = r.uniform(4, 13)
        cc = greens[r.integers(len(greens))]
        specs.append((x, gy + r.uniform(0, 3), h, r.uniform(0.1, 0.5), r.uniform(0.7, 1.5), cc + (255,)))
    for _ in range(int(16000)):
        x = r.uniform(0, WW)
        pwx = 30 + 6 * math.sin(x * 3 * TAU)
        y = float(ground(x)) + pwx + r.uniform(-4, 380) ** 1.0
        depth = (y - ground(x)) / 400
        h = r.uniform(10, 28) * (0.7 + depth * 1.4)
        cc = greens[r.integers(len(greens))]
        lift = 1 - 0.35 * depth
        cc = tuple(int(v * lift + (1 - lift) * 70) for v in cc)
        specs.append((x, y, h, r.uniform(0.2, 0.7), r.uniform(0.9, 2.2) * (0.8 + depth), cc + (255,)))
    specs.sort(key=lambda s: s[1])
    bl = np.asarray(blades(W, H, 2, [(x * S, y * S, h * S, ln, w * S, cc) for x, y, h, ln, w, cc in specs])).astype(np.float32)
    ba = bl[..., 3] / 255
    col, a = over(col, a, bl[..., :3], ba)
    # sunlit tips highlight on fringe
    # wildflowers
    fl = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(fl)
    for k in range(1400):
        cx = r.uniform(0, WW)
        patch = 0.5 + 0.5 * math.sin(cx * 2 * TAU + 2) * math.sin(cx * 6 * TAU)
        if r.uniform() > patch:
            continue
        pwx = 30 + 6 * math.sin(cx * 3 * TAU)
        y = float(ground(cx)) + pwx + r.uniform(6, 360)
        rad = (1.2 + (y - ground(cx)) / 160) * S
        colr = [(255, 252, 240), (255, 226, 120), (255, 250, 250), (240, 120, 110), (200, 190, 250)][int(r.choice(5, p=[0.45, 0.3, 0.15, 0.05, 0.05]))]
        for o in OFFS:
            ox = (cx + o) * S
            d.ellipse([ox - rad, y * S - rad, ox + rad, y * S + rad], fill=colr + (255,))
    fa = np.asarray(fl).astype(np.float32)
    col, a = over(col, a, fa[..., :3], fa[..., 3] / 255)
    save("near-day", col, a)
    return col, a


if __name__ == "__main__":
    which = sys.argv[1:] or ["sky", "far", "mid", "near"]
    for w in which:
        globals()[w]()
        print("done", w, flush=True)
