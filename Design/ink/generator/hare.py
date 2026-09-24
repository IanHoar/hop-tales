"""Hare character: smooth-blended 3D volumes, sphere-traced in numpy, rendered in several styles."""
import numpy as np, math, os, sys
from PIL import Image, ImageDraw, ImageFilter
from scipy import ndimage as ndi

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "hare")
os.makedirs(OUT, exist_ok=True)


def hx(h):
    h = h.lstrip("#")
    return np.array([int(h[i:i + 2], 16) for i in (0, 2, 4)], np.float32)


PAL = {
    "fur":   ["#3E2A22", "#6E4832", "#9E6E46", "#C99661", "#EDC68C"],
    "cream": ["#6A5A52", "#A8927E", "#D8C3A2", "#F0E2C4", "#FFF7E6"],
    "tip":   ["#16110F", "#241C19", "#3A2E29", "#54463E", "#76665A"],
    "inner": ["#6E3E3A", "#A8625A", "#D8938A", "#EDB6A8", "#FAD8CC"],
    "scarf": ["#4A1014", "#8E1A1E", "#C9302E", "#EE5A46", "#FF9C7E"],
    "nose":  ["#3A1E22", "#6A343A", "#9A5058", "#C27480", "#E6A0A8"],
    "far":   ["#2E1F19", "#553828", "#7E583A", "#A77A50", "#C99E70"],
}
MATS = list(PAL)
VPAL = {
    "fur":   ["#7C706C", "#A2958F", "#C2B6B0", "#D6CCC6", "#E6DED9"],
    "cream": ["#A89C94", "#D2C7BC", "#EDE5DA", "#F6F0E7", "#FFFBF5"],
    "tip":   ["#7C706C", "#A2958F", "#C2B6B0", "#D6CCC6", "#E6DED9"],
    "inner": ["#C45E62", "#E57C7C", "#F4999A", "#F8B4AE", "#FCD3CC"],
    "scarf": ["#4A1014", "#8E1A1E", "#C9302E", "#EE5A46", "#FF9C7E"],
    "nose":  ["#A85A62", "#C87880", "#E0989E", "#EDB4B8", "#F6D0D2"],
    "far":   ["#5E5450", "#7E726D", "#978B86", "#ABA09A", "#BDB2AC"],
}


def rot(a):
    c, s = math.cos(a), math.sin(a)
    return c, s


# primitive: (kind, center(3), radii(3) or radius, angle(z-rot, radians), material, extra)
def E(c, r, ang=0.0, m="fur"):
    return ("e", np.array(c, np.float32), np.array(r, np.float32), math.radians(ang), m)


def C(a, b, r, m="fur"):
    return ("c", np.array(a, np.float32), np.array(b, np.float32), r, m)


def hare(pose="idle"):
    P = []
    if pose == "idle":
        for z, far in ((0.27, 0), (-0.27, 1)):
            P.append(E((-0.42, 0.22, z), (0.56, 0.5, 0.3), -8))
            P.append(C((-0.52, 0.42, z), (-0.62, 0.68, z), 0.09))
            P.append(E((-0.16, 0.73, z), (0.5, 0.085, 0.12), 3))
            P.append(C((0.52, -0.05, z * 0.55), (0.6, 0.68, z * 0.55), 0.075))
            P.append(E((0.66, 0.73, z * 0.55), (0.13, 0.06, 0.08), 0))
        P.append(E((0.0, -0.08, 0), (0.74, 0.55, 0.46), -28))
        P.append(E((0.44, -0.36, 0), (0.4, 0.5, 0.4), -30))
        P.append(E((0.3, 0.05, 0.05), (0.42, 0.38, 0.38), -28, "cream"))
        P.append(E((0.78, -0.96, 0), (0.4, 0.31, 0.29), 14))
        P.append(E((0.86, -0.84, 0.02), (0.26, 0.21, 0.28), 10, "cream"))
        P.append(E((1.1, -0.88, 0), (0.19, 0.16, 0.16), 8))
        P.append(E((1.27, -0.9, 0), (0.035, 0.03, 0.04), 0, "nose"))
        P.append(E((0.46, -1.72, 0.1), (0.125, 0.56, 0.05), -16))
        P.append(E((0.38, -2.2, 0.1), (0.09, 0.16, 0.05), -18, "tip"))
        P.append(E((0.47, -1.66, 0.15), (0.075, 0.42, 0.02), -16, "inner"))
        P.append(E((0.26, -1.66, -0.12), (0.12, 0.54, 0.05), -26))
        P.append(E((0.07, -2.12, -0.12), (0.09, 0.16, 0.05), -28, "tip"))
        P.append(E((-0.93, -0.05, 0), (0.17, 0.16, 0.16), 0, "cream"))
        P.append(E((0.63, -0.66, 0), (0.27, 0.13, 0.43), -48, "scarf"))
        P.append(E((0.56, -0.56, 0.4), (0.085, 0.075, 0.07), 0, "scarf"))
        P.append(E((0.47, -0.3, 0.39), (0.085, 0.27, 0.035), 22, "scarf"))
        eye = (0.9, -1.02, 0.07)
    else:  # leap
        for z, far in ((0.26, 0), (-0.26, 1)):
            P.append(E((-0.62, -0.1, z), (0.52, 0.42, 0.28), 20))
            P.append(C((-0.92, 0.04, z), (-1.14, 0.2, z), 0.09))
            P.append(E((-1.44, 0.25, z), (0.34, 0.075, 0.11), 9))
            P.append(C((0.72, -0.12, z * 0.5), (1.18, 0.28, z * 0.5), 0.072))
            P.append(E((1.24, 0.32, z * 0.5), (0.12, 0.055, 0.08), 30))
        P.append(E((0.0, -0.2, 0), (0.95, 0.42, 0.42), -4))
        P.append(E((0.62, -0.3, 0), (0.42, 0.42, 0.38), -12))
        P.append(E((0.35, -0.02, 0.05), (0.55, 0.28, 0.34), -4, "cream"))
        P.append(E((1.2, -0.58, 0), (0.38, 0.3, 0.28), 4))
        P.append(E((1.3, -0.48, 0.02), (0.25, 0.2, 0.27), 0, "cream"))
        P.append(E((1.52, -0.5, 0), (0.18, 0.15, 0.15), 0))
        P.append(E((1.68, -0.52, 0), (0.035, 0.03, 0.04), 0, "nose"))
        P.append(E((0.52, -0.95, 0.1), (0.12, 0.56, 0.05), -62))
        P.append(E((0.04, -1.18, 0.1), (0.085, 0.16, 0.05), -64, "tip"))
        P.append(E((0.56, -0.93, 0.15), (0.07, 0.42, 0.02), -62, "inner"))
        P.append(E((0.48, -0.82, -0.12), (0.115, 0.52, 0.05), -70))
        P.append(E((0.0, -0.99, -0.12), (0.085, 0.15, 0.05), -72, "tip"))
        P.append(E((-0.98, -0.42, 0), (0.17, 0.16, 0.16), 0, "cream"))
        P.append(E((0.92, -0.42, 0), (0.15, 0.24, 0.41), -10, "scarf"))
        P.append(E((0.9, -0.5, 0.39), (0.08, 0.07, 0.07), 0, "scarf"))
        P.append(E((0.56, -0.62, 0.37), (0.32, 0.075, 0.035), -12, "scarf"))
        eye = (1.3, -0.64, 0.07)
    return P, eye


def sd_ellipsoid(px, py, pz, c, r, ang):
    x, y, z = px - c[0], py - c[1], pz - c[2]
    co, si = math.cos(-ang), math.sin(-ang)
    lx, ly = x * co - y * si, x * si + y * co
    k0 = np.sqrt((lx / r[0]) ** 2 + (ly / r[1]) ** 2 + (z / r[2]) ** 2)
    k1 = np.sqrt((lx / r[0] ** 2) ** 2 + (ly / r[1] ** 2) ** 2 + (z / r[2] ** 2) ** 2)
    return k0 * (k0 - 1.0) / np.maximum(k1, 1e-6)


def sd_capsule(px, py, pz, a, b, r):
    pa = np.stack([px - a[0], py - a[1], pz - a[2]])
    ba = (b - a)[:, None]
    h = np.clip((pa * ba).sum(0) / float((ba * ba).sum()), 0, 1)
    d = pa - ba * h
    return np.sqrt((d * d).sum(0)) - r


def prim_d(p, px, py, pz):
    if p[0] == "e":
        return sd_ellipsoid(px, py, pz, p[1], p[2], p[3])
    return sd_capsule(px, py, pz, p[1], p[2], p[3])


def smin(a, b, k):
    h = np.clip(0.5 + 0.5 * (b - a) / k, 0, 1)
    return b * (1 - h) + a * h - k * h * (1 - h)


K_BLEND = {"far": 0.05, "fur": 0.09, "cream": 0.07, "tip": 0.03, "inner": 0.01, "scarf": 0.02, "nose": 0.01}


def scene_d(P, px, py, pz, fuzz=None):
    d = None
    for p in P:
        di = prim_d(p, px, py, pz)
        k = K_BLEND[p[4]]
        d = di if d is None else smin(d, di, k)
    if fuzz is not None:
        d = d - fuzz
    return d


def render(P, eye, N=900, box=(-1.7, 1.95, -2.5, 1.0), style="painted", seed=3):
    x0, x1, y0, y1 = box
    wpx = N
    hpx = int(N * (y1 - y0) / (x1 - x0))
    xs = np.linspace(x0, x1, wpx, dtype=np.float32)
    ys = np.linspace(y0, y1, hpx, dtype=np.float32)
    PX, PY = np.meshgrid(xs, ys)
    px, py = PX.ravel(), PY.ravel()
    npx = px.size
    rng = np.random.default_rng(seed)
    # fur fuzz: 2D high-frequency noise, tied to image position
    g = rng.standard_normal((hpx // 7 + 2, wpx // 7 + 2)).astype(np.float32)
    fz = ndi.zoom(g, (hpx / (hpx // 7 + 2), wpx / (wpx // 7 + 2)), order=1)[:hpx, :wpx]
    fz = np.pad(fz, ((0, hpx - fz.shape[0]), (0, wpx - fz.shape[1])), mode="edge").ravel()
    fuzz_amp = 0.0 if style == "vector" else 0.006
    # sphere trace (orthographic, looking down -z)
    z = np.full(npx, 1.2, np.float32)
    hit = np.zeros(npx, bool)
    alive = np.ones(npx, bool)
    for it in range(90):
        idx = np.nonzero(alive)[0]
        if idx.size == 0:
            break
        d = scene_d(P, px[idx], py[idx], z[idx], fz[idx] * fuzz_amp)
        z[idx] -= d * 0.9
        done = d < 0.0015
        hit[idx[done]] = True
        gone = z[idx] < -1.2
        alive[idx[done | gone]] = False
    H = hit.reshape(hpx, wpx)
    Z = np.where(hit, z, -2).reshape(hpx, wpx)
    # normals by central differences on the hit points
    hi = np.nonzero(hit)[0]
    hx_, hy_, hz_ = px[hi], py[hi], z[hi]
    e = 0.004
    fzh = fz[hi] * fuzz_amp
    nx = scene_d(P, hx_ + e, hy_, hz_, fzh) - scene_d(P, hx_ - e, hy_, hz_, fzh)
    ny = scene_d(P, hx_, hy_ + e, hz_, fzh) - scene_d(P, hx_, hy_ - e, hz_, fzh)
    nz = scene_d(P, hx_, hy_, hz_ + e, fzh) - scene_d(P, hx_, hy_, hz_ - e, fzh)
    nl = np.sqrt(nx * nx + ny * ny + nz * nz) + 1e-9
    nx, ny, nz = nx / nl, ny / nl, nz / nl
    # material weights
    ds = np.stack([prim_d(p, hx_, hy_, hz_) for p in P])
    mats = np.array([MATS.index(p[4]) for p in P])
    wts = np.exp(-np.maximum(ds, 0) * 60)
    mw = np.zeros((len(MATS), hi.size), np.float32)
    for mi in range(len(MATS)):
        sel = mats == mi
        if sel.any():
            mw[mi] = wts[sel].max(0)
    # small materials win cleanly when on/inside them
    for m in ("tip", "inner", "scarf", "nose", "cream"):
        mi = MATS.index(m)
        sel = mats == mi
        if sel.any():
            inside = ds[sel].min(0) < 0.004
            mw[mi] = np.where(inside, 50 + mw[mi], mw[mi])
    mw /= mw.sum(0, keepdims=True) + 1e-9
    # ambient occlusion (5 taps along the normal)
    ao = np.zeros(hi.size, np.float32)
    for k in range(1, 6):
        h = 0.035 * k
        dd = scene_d(P, hx_ + nx * h, hy_ + ny * h, hz_ + nz * h)
        ao += (h - dd) / (2 ** k)
    ao = np.clip(1 - 2.2 * ao, 0.35, 1)
    # lighting
    L = np.array([-0.55, -0.62, 0.56]); L /= np.linalg.norm(L)
    lam = nx * L[0] + ny * L[1] + nz * L[2]
    s = np.clip((lam + 0.28) / 1.2, 0, 1)
    # directional fur strokes (image space)
    gg = rng.standard_normal((hpx // 2 + 2, wpx // 10 + 2)).astype(np.float32)
    st = ndi.zoom(gg, (hpx / (hpx // 2 + 2), wpx / (wpx // 10 + 2)), order=3)[:hpx, :wpx]
    st = np.pad(st, ((0, hpx - st.shape[0]), (0, wpx - st.shape[1])), mode="edge")
    st = ndi.rotate(st, 25, reshape=False, mode="reflect").ravel()[hi]
    if style == "vector":
        sm = lambda a, b, x: np.clip((x - a) / (b - a), 0, 1) ** 2 * (3 - 2 * np.clip((x - a) / (b - a), 0, 1))
        simg = np.zeros(hpx * wpx, np.float32)
        simg[hi] = s * (0.8 + 0.2 * ao)
        wimg = ndi.gaussian_filter(H.astype(np.float32), wpx / 90)
        simg = ndi.gaussian_filter(simg.reshape(hpx, wpx), wpx / 90) / np.maximum(wimg, 1e-3)
        sb = simg.ravel()[hi]
        s2 = 0.36 + 0.28 * sm(0.24, 0.3, sb) + 0.1 * sm(0.74, 0.8, sb)
    elif style == "cel":
        s2 = np.where(s > 0.46, 0.78, 0.3)
        s2 = np.where(s > 0.86, 0.95, s2)
    else:
        q = s * 5
        f = q - np.floor(q)
        t = np.clip((f - 0.34) / 0.32, 0, 1)
        s2 = 0.6 * (np.floor(q) + t * t * (3 - 2 * t)) / 5 + 0.4 * s
        s2 = np.clip(s2 + st * 0.05 * (style != "cel"), 0, 1)
        s2 = s2 * (0.55 + 0.45 * ao)
    col = np.zeros((hi.size, 3), np.float32)
    for mi, m in enumerate(MATS):
        stops = [hx(cc) for cc in (VPAL if style == "vector" else PAL)[m]]
        cm = np.stack([np.interp(s2, [0, 0.25, 0.5, 0.75, 1.0], [c_[ch] for c_ in stops]) for ch in range(3)], 1)
        col += cm * mw[mi][:, None]
    if style not in ("cel", "vector"):
        # cool sky fill on the shadow side, warm rim on the lit silhouette
        fill = np.clip(-lam, 0, 1) * (1 - np.abs(nz)) ** 0.5
        col += fill[:, None] * np.array([18, 30, 52]) * 0.55
        rim = np.clip(1 - nz, 0, 1) ** 2.5 * np.clip(-(nx * 0.7 + ny * 0.7), 0, 1)
        col += rim[:, None] * (np.array([255, 240, 205]) - col) * 0.55
        # bounce light from the grass on under-surfaces
        bounce = np.clip(ny, 0, 1) ** 2
        col += bounce[:, None] * np.array([10, 26, 4])
    img = np.zeros((hpx * wpx, 3), np.float32)
    img[hi] = col
    img = img.reshape(hpx, wpx, 3)
    alpha = H.astype(np.float32)
    # silhouette anti-alias via slight blur of alpha (we downsample later anyway)
    # lines
    if style in ("line", "cel"):
        dz = np.hypot(ndi.sobel(Z, 0), ndi.sobel(Z, 1))
        edge_depth = (dz > (0.6 if style == "line" else 0.3)) & H
        sil = H & ~ndi.binary_erosion(H, iterations=1)
        lw = 3 if style == "line" else 4
        lm = ndi.binary_dilation(sil | edge_depth, iterations=lw)
        lcol = hx("#3A2620") if style == "line" else hx("#1D1A2C")
        a_line = lm.astype(np.float32)
        if style == "line":
            # vary line weight: thinner on lit side
            a_line *= 0.85
        img = img * (1 - a_line[..., None]) + lcol * a_line[..., None]
        alpha = np.maximum(alpha, lm.astype(np.float32))
    # eye
    im = Image.fromarray(np.dstack([np.clip(img, 0, 255), alpha * 255]).astype(np.uint8), "RGBA")
    d = ImageDraw.Draw(im)
    tx = lambda x: (x - x0) / (x1 - x0) * wpx
    ty = lambda y: (y - y0) / (y1 - y0) * hpx
    ex, ey = tx(eye[0]), ty(eye[1])
    u = wpx / (x1 - x0)
    if style == "vector":
        rw, rh = 0.058 * u, 0.066 * u
        d.ellipse([ex - rw, ey - rh, ex + rw, ey + rh], fill=(52, 36, 32, 255))
        d.ellipse([ex - rw * 0.78, ey - rh * 0.78, ex + rw * 0.78, ey + rh * 0.78], fill=(96, 62, 46, 255))
        d.ellipse([ex - rw * 0.5, ey - rh * 0.5, ex + rw * 0.5, ey + rh * 0.5], fill=(34, 24, 22, 255))
        d.ellipse([ex - rw * 0.55, ey - rh * 0.62, ex - rw * 0.05, ey - rh * 0.1], fill=(255, 252, 246, 255))
        d.arc([ex - rw * 1.3, ey - rh * 1.35, ex + rw * 1.3, ey + rh * 1.0], 205, 335, fill=(122, 108, 102, 255), width=max(2, int(u * 0.014)))
        return im
    rw, rh = 0.078 * u, 0.088 * u
    d.ellipse([ex - rw * 1.18, ey - rh * 1.15, ex + rw * 1.18, ey + rh * 1.15], fill=(58, 36, 28, 255))
    d.ellipse([ex - rw, ey - rh, ex + rw, ey + rh], fill=(176, 108, 34, 255))
    d.ellipse([ex - rw * 0.8, ey - rh * 0.25, ex + rw * 0.8, ey + rh * 0.95], fill=(214, 150, 58, 255))
    d.ellipse([ex - rw * 0.52, ey - rh * 0.56, ex + rw * 0.52, ey + rh * 0.56], fill=(24, 16, 14, 255))
    d.ellipse([ex - rw * 0.62 - rw * 0.1, ey - rh * 0.72, ex - rw * 0.02, ey - rh * 0.08], fill=(255, 252, 244, 255))
    d.ellipse([ex + rw * 0.25, ey + rh * 0.3, ex + rw * 0.5, ey + rh * 0.55], fill=(255, 240, 220, 210))
    d.arc([ex - rw * 1.25, ey - rh * 1.3, ex + rw * 1.25, ey + rh * 1.05], 200, 340, fill=(40, 24, 20, 255), width=max(2, int(u * 0.018)))
    # whiskers
    if style != "cel":
        wx, wy = tx(eye[0] + 0.33), ty(eye[1] + 0.13)
        for dy_, ln in ((-0.02, 0.36), (0.03, 0.4), (0.08, 0.33)):
            d.line([wx, wy + dy_ * u, wx + ln * u, wy + dy_ * u + (dy_ * 1.6 + 0.02) * u], fill=(255, 248, 232, 150), width=max(1, int(u * 0.006)))
    return im


def ground_shadow(im, cx, cy, rx, ry):
    sh = Image.new("RGBA", im.size, (0, 0, 0, 0))
    ImageDraw.Draw(sh).ellipse([cx - rx, cy - ry, cx + rx, cy + ry], fill=(40, 58, 30, 110))
    sh = sh.filter(ImageFilter.GaussianBlur(ry * 0.6))
    return Image.alpha_composite(sh, im)


def lerp_pose(A, B, t, dy=0.0):
    out = []
    for a, b in zip(A, B):
        if a[0] == "e":
            c_ = a[1] * (1 - t) + b[1] * t
            c_ = c_ + np.array([0, dy, 0], np.float32)
            out.append(("e", c_, a[2] * (1 - t) + b[2] * t, a[3] * (1 - t) + b[3] * t, a[4]))
        else:
            off = np.array([0, dy, 0], np.float32)
            out.append(("c", a[1] * (1 - t) + b[1] * t + off, a[2] * (1 - t) + b[2] * t + off, a[3] * (1 - t) + b[3] * t, a[4]))
    return out


def hop_sheet(N=800, style="painted"):
    A, ea = hare("idle")
    B, eb = hare("leap")
    assert len(A) == len(B)
    ts = [0, 0.2, 0.65, 1.0, 0.95, 0.6, 0.22, 0]
    dys = [0, 0.04, -0.3, -0.55, -0.5, -0.22, 0.02, 0]
    box = (-1.95, 1.95, -2.6, 1.0)
    frames = []
    for t, dy in zip(ts, dys):
        P = lerp_pose(A, B, t, dy)
        eye = tuple(np.array(ea) * (1 - t) + np.array(eb) * t + np.array([0, dy, 0]))
        im = render(P, eye, N, box, style)
        u = N / (box[1] - box[0])
        air = min(1, -dy / 0.55) if dy < 0 else 0
        im = ground_shadow(im, (0.1 - box[0]) * u, (0.8 - box[2]) * u, (0.95 - 0.3 * air) * u, 0.09 * u)
        frames.append(im.resize((im.width // 2, im.height // 2), Image.LANCZOS))
    w, h = frames[0].size
    sheet = Image.new("RGBA", (w * len(frames), h), (0, 0, 0, 0))
    for i, f in enumerate(frames):
        sheet.alpha_composite(f, (i * w, 0))
    sheet.save(f"{OUT}/hare-hop-{style}.png")
    print("hop", sheet.size, flush=True)


if __name__ == "__main__":
    if sys.argv[1:2] == ["hop"]:
        hop_sheet(int(os.environ.get("HN", "800")))
        sys.exit()
    N = int(os.environ.get("HN", "1400"))
    jobs = sys.argv[1:] or ["idle:painted", "idle:line", "idle:cel", "leap:line"]
    for j in jobs:
        pose, style = j.split(":")
        P, eye = hare(pose)
        box = (-1.7, 1.95, -2.5, 1.0) if pose == "idle" else (-1.95, 1.95, -1.6, 0.75)
        im = render(P, eye, N, box, style)
        u = N / (box[1] - box[0])
        gy = (0.8 - box[2]) * u
        if pose == "idle":
            im = ground_shadow(im, (0.1 - box[0]) * u, gy, 0.95 * u, 0.09 * u)
        im = im.resize((im.width // 2, im.height // 2), Image.LANCZOS)
        im.save(f"{OUT}/hare-{pose}-{style}.png")
        print("done", j, im.size, flush=True)
