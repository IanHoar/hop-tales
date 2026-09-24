"""Hare bounding gait: jointed legs posed per keyframe, rendered with hare.render."""
import math, os, sys
import numpy as np
from PIL import Image, ImageDraw
from hare import render, E, C, ground_shadow, OUT

GROUND = 0.8
A = dict(ear=1.0, earw=1.0, leg=1.0, body=1.0, scarf=True)
L1, L2, L3 = 0.55, 0.42, 0.55      # thigh, shin, foot
F1, F2 = 0.38, 0.36                 # upper, lower foreleg


def rot(v, deg):
    a = math.radians(deg)
    return np.array([v[0] * math.cos(a) - v[1] * math.sin(a), v[0] * math.sin(a) + v[1] * math.cos(a)])


def dirv(deg):
    a = math.radians(deg)
    return np.array([math.cos(a), math.sin(a)])


def up(deg):
    a = math.radians(deg)
    return np.array([math.sin(a), -math.cos(a)])


# keyframes: phi body pitch (+ = nose down), hind (thigh, shin, foot), front (upper, lower),
# ears (deg from vertical, - = back), head pitch, stretch, scarf trail angle, contact, air lift
KEYS = [
    dict(name="push-off",    phi=-26, ar=0.0,   hind=(130, 150, 160), front=(40, 120),  ear=-12, hp=12, st=1.06, sc=162, contact="any", lift=0),
    dict(name="launch",      phi=-16, ar=-0.25, hind=(150, 160, 168), front=(25, 95),   ear=-20, hp=10, st=1.1,  sc=168, contact="air", lift=0.45),
    dict(name="stretch",     phi=-4,  ar=-0.45, hind=(168, 174, 180), front=(10, 8),    ear=-26, hp=4,  st=1.16, sc=176, contact="air", lift=0.8),
    dict(name="descent",     phi=2,   ar=-0.3,  hind=(160, 168, 176), front=(28, 40),   ear=-24, hp=0,  st=1.12, sc=182, contact="air", lift=0.55),
    dict(name="front touch", phi=8,   ar=-0.05, hind=(140, 150, 140), front=(62, 72),   ear=-20, hp=-4, st=1.05, sc=184, contact="any", lift=0),
    dict(name="front plant", phi=14,  ar=0.5,   hind=(55, 160, 175),  front=(96, 106),  ear=-14, hp=-8, st=0.96, sc=178, contact="any", lift=0),
    dict(name="gather",      phi=10,  ar=1.0,   hind=(25, 105, 15),   front=(125, 140), ear=-8,  hp=-4, st=0.86, sc=170, contact="any", lift=0),
    dict(name="hind land",   phi=-4,  ar=0.8,   hind=(50, 150, 2),    front=(150, 160), ear=-8,  hp=4,  st=0.88, sc=164, contact="any", lift=0),
    dict(name="load",        phi=-16, ar=0.4,   hind=(90, 155, 8),    front=(60, 135),  ear=-10, hp=8,  st=0.96, sc=160, contact="any", lift=0),
]


def pose_prims(k, dy=0.0):
    phi, st = k["phi"], k["st"]
    B = np.array([0.0, -0.05])
    ar = k.get("ar", 0.0)
    L = lambda v: B + rot((v[0] * st, v[1]), phi)
    R_ = lambda v: L((v[0] + 0.12 * ar, v[1] + 0.2 * ar))
    F_ = lambda v: L((v[0] - 0.08 * ar, v[1] + 0.12 * ar))
    P = []
    joints = {}
    hip = R_((-0.5, 0.12))
    sho = F_((0.5, 0.06))
    for z, far in ((0.26, 0), (-0.26, 1)):
        mat = "far" if far else "fur"
        t1, t2, t3 = k["hind"]
        kn = hip + L1 * dirv(t1)
        an = kn + L2 * dirv(t2)
        to = an + L3 * dirv(t3)
        m = (hip + kn) / 2
        P.append(E((m[0], m[1], z), (0.46, 0.36, 0.29), t1, mat))
        P.append(C((kn[0], kn[1], z), (an[0], an[1], z), 0.085 * A["leg"], mat))
        fm = (an + to) / 2
        P.append(E((fm[0], fm[1], z), (L3 / 2 + 0.05, 0.075 * A["leg"], 0.11 * A["leg"]), t3, mat))
        u1, u2 = k["front"]
        zf = z * 0.55
        el = sho + F1 * dirv(u1)
        wr = el + F2 * dirv(u2)
        P.append(C((sho[0], sho[1], zf), (el[0], el[1], zf), 0.078 * A["leg"], mat))
        P.append(C((el[0], el[1], zf), (wr[0], wr[1], zf), 0.066 * A["leg"], mat))
        pw = wr + 0.06 * dirv(u2 - 60)
        P.append(E((pw[0], pw[1], zf), (0.11, 0.055, 0.075), u2 - 90, mat))
        joints.setdefault("toes", []).append(max(to[1], an[1]) + 0.075)
        joints.setdefault("paws", []).append(pw[1] + 0.055)
    c = L((0, -0.1 - 0.08 * ar)); P.append(E((c[0], c[1], 0), (0.72 * st - 0.06 * ar, (0.46 + 0.04 * ar) * A["body"], 0.44 * A["body"]), phi))
    c = R_((-0.52, -0.02)); P.append(E((c[0], c[1], 0), (0.46, 0.43 * A["body"], 0.4 * A["body"]), phi + 28 * ar))
    c = F_((0.46, -0.16)); P.append(E((c[0], c[1], 0), (0.42, 0.44 * A["body"], 0.38 * A["body"]), phi - 8 - 14 * ar))
    c = L((0.22, 0.14 + 0.04 * ar)); P.append(E((c[0], c[1], 0.05), (0.55 * st, 0.25, 0.34), phi, "cream"))
    neck = F_((0.72, -0.42))
    ha = phi + k["hp"]
    hc = neck + rot((0.3, -0.22), ha)
    P.append(E((hc[0], hc[1], 0), (0.38, 0.3, 0.28), ha + 6))
    q = hc + rot((0.1, 0.1), ha); P.append(E((q[0], q[1], 0.02), (0.25, 0.2, 0.27), ha + 4, "cream"))
    q = hc + rot((0.31, 0.08), ha); P.append(E((q[0], q[1], 0), (0.18, 0.15, 0.15), ha + 2))
    q = hc + rot((0.48, 0.06), ha); P.append(E((q[0], q[1], 0), (0.035, 0.03, 0.04), 0, "nose"))
    for z, off, dz in ((0.1, 0, 0), (-0.12, -8, -0.04)):
        a = k["ear"] + off
        base = hc + rot((-0.12, -0.2), ha)
        el_, ew = A["ear"], A["earw"]
        cen = base + 0.52 * el_ * up(a)
        tip = base + 0.98 * el_ * up(a)
        P.append(E((cen[0], cen[1], z), (0.12 * ew, 0.54 * el_, 0.05), a))
        P.append(E((tip[0], tip[1], z), (0.088 * ew, 0.16, 0.05), a, "tip"))
        if z > 0:
            ic = base + 0.52 * el_ * up(a)
            P.append(E((ic[0], ic[1], 0.15), (0.074 * ew * 1.12, 0.43 * el_, 0.02), a, "inner"))
    c = R_((-0.96, -0.24)); P.append(E((c[0], c[1], 0), (0.17, 0.16, 0.16), 0, "cream"))
    if A["scarf"]:
        sc = F_((0.7, -0.36)); P.append(E((sc[0], sc[1], 0), (0.2, 0.13, 0.42), phi - 48, "scarf"))
        kn_ = sc + rot((-0.04, 0.08), phi); P.append(E((kn_[0], kn_[1], 0.4), (0.08, 0.07, 0.07), 0, "scarf"))
        tl = kn_ + 0.3 * dirv(k["sc"]); P.append(E((tl[0], tl[1], 0.37), (0.3, 0.07, 0.035), k["sc"], "scarf"))
    else:
        c = F_((0.66, -0.22)); P.append(E((c[0], c[1], 0.08), (0.19, 0.27, 0.25), phi - 30, "cream"))
    eye = hc + rot((0.12, -0.06), ha)
    def lowest(P):
        lo = -9
        for p in P:
            if p[0] == "e":
                a_ = p[3]
                ext = math.sqrt((p[2][0] * math.sin(a_)) ** 2 + (p[2][1] * math.cos(a_)) ** 2)
                lo = max(lo, p[1][1] + ext)
            else:
                lo = max(lo, p[1][1] + p[3], p[2][1] + p[3])
        return lo
    low = lowest(P)
    dy = GROUND - low - (k["lift"] if k["contact"] == "air" else 0)
    out = []
    for p in P:
        if p[0] == "e":
            out.append(("e", p[1] + np.array([0, dy, 0], np.float32), p[2], p[3], p[4]))
        else:
            off = np.array([0, dy, 0], np.float32)
            out.append(("c", p[1] + off, p[2] + off, p[3], p[4]))
    return out, (eye[0], eye[1] + dy, 0.07), dy


SIT = dict(name="sit", phi=-40, ar=0.5, hind=(8, 178, 0), front=(84, 92), ear=-4, hp=34, st=0.95, sc=150, contact="any", lift=0)
GRAZE = dict(name="graze", phi=14, ar=0.7, hind=(28, 168, 2), front=(92, 96), ear=-30, hp=36, st=0.92, sc=170, contact="any", lift=0)

VECTOR_ANAT = dict(ear=1.2, earw=1.12, leg=0.9, body=0.9, scarf=False)


def lerp_key(a, b, t):
    k = {}
    for n in ("phi", "ar", "ear", "hp", "st", "sc", "lift"):
        k[n] = a[n] * (1 - t) + b[n] * t
    for n in ("hind", "front"):
        k[n] = tuple(x * (1 - t) + y * t for x, y in zip(a[n], b[n]))
    k["contact"] = a["contact"] if t < 0.5 else b["contact"]
    return k


def frames(sub=2):
    out = []
    n = len(KEYS)
    for i in range(n):
        for j in range(sub):
            t = j / sub
            a, b = KEYS[i], KEYS[(i + 1) % n]
            k = lerp_key(a, b, t)
            if t > 0:
                # blend ground offsets so contact switches don't pop
                _, _, da = pose_prims(dict(k, contact=a["contact"]))
                _, _, db = pose_prims(dict(k, contact=b["contact"]))
                k["_dy"] = da * (1 - t) + db * t
            out.append(k)
    return out


def render_frame(k, N, box, style="painted"):
    P, eye, dy = pose_prims(k)
    if "_dy" in k:
        P, eye, _ = pose_prims(k)
        shift = k["_dy"] - dy
        P = [("e", p[1] + np.array([0, shift, 0], np.float32), p[2], p[3], p[4]) if p[0] == "e"
             else ("c", p[1] + np.array([0, shift, 0], np.float32), p[2] + np.array([0, shift, 0], np.float32), p[3], p[4]) for p in P]
        eye = (eye[0], eye[1] + shift, eye[2])
    im = render(P, eye, N, box, style)
    u = N / (box[1] - box[0])
    ys = [p[1][1] + (p[2][1] if p[0] == "e" else 0) for p in P]
    low = max(ys)
    air = float(np.clip((GROUND - low) / 0.25, 0, 1))
    return ground_shadow(im, (0.05 - box[0]) * u, (GROUND - box[2]) * u, (1.0 - 0.3 * air) * u, 0.085 * u)


if __name__ == "__main__":
    N = int(os.environ.get("HN", "900"))
    style = os.environ.get("HS", "painted")
    box = (-2.1, 2.1, -2.9, 1.0)
    which = sys.argv[1] if len(sys.argv) > 1 else "cycle"
    if style == "vector":
        A.update(VECTOR_ANAT)
    if which == "keys":
        fr = [dict(k) for k in KEYS]
    elif which == "poses":
        fr = [dict(SIT), dict(KEYS[0]), dict(KEYS[2]), dict(KEYS[3]), dict(KEYS[5])]
    else:
        fr = frames(2)
    ims = []
    for k in fr:
        im = render_frame(k, N, box, style)
        ims.append(im.resize((im.width // 2, im.height // 2), Image.LANCZOS))
        print(".", end="", flush=True)
    w, h = ims[0].size
    sheet = Image.new("RGBA", (w * len(ims), h), (0, 0, 0, 0))
    for i, f in enumerate(ims):
        sheet.alpha_composite(f, (i * w, 0))
    name = f"{OUT}/hare-{ {'keys': 'keys', 'poses': 'poses'}.get(which, 'bound') }-{style}.png"
    sheet.save(name)
    print("\n", name, sheet.size, len(ims))
