"""Environment kit for the Ink & Ember direction.

Depth rule: near props use black ink (4), mid props use a tinted ink (3),
far shapes use no outline and fade toward the sky colour.
"""
import math, random
from ink import *

TOD = {
    "day": dict(
        sky=["#3FA3D6", "#7CC6E8", "#BDE6F2", "#EAF7EC"],
        far=Pal("#9DC3DE", "#7FA6C8", "#C6E0F0"), far2=Pal("#B7D5E8", "#98BCD8", "#D6EAF5"), snow="#FFFFFF",
        midink="#2E5A3A", hill_mid=Pal("#86C95E", "#62A84A", "#A8DE7A"), hill_far=Pal("#B0DC8E", "#92C678", "#C8EAA8"),
        ground=Pal("#6DB84A", "#4E9A3A", "#94D466"), path=Pal("#F0D9A0", "#CDAE70", "#FFF0C8"),
        leaf=Pal("#4FAF4A", "#2F8A3C", "#86D46A"), pine=Pal("#3F9A55", "#26744A", "#6CC474"),
        stone=Pal("#E4DCCB", "#B7A98E", "#FFF8EA"), roof=Pal("#D9432E", "#A42A1E", "#FF7A5A"),
        wood=Pal("#B07A48", "#7D5230", "#D8A26A"), cloud=Pal("#FFFFFF", "#D2E6F2", "#FFFFFF"),
        haze="#EAF7EC", window="#3A2C24", light=None, rock=Pal("#B8B2AA", "#8A847E", "#DDD8D0")),
    "gold": dict(
        sky=["#3A7FC0", "#88B8D8", "#F4D2A0", "#FFC27A"],
        far=Pal("#A8B4CE", "#8A94B6", "#D4C8D0"), far2=Pal("#C8C4D0", "#AAA6BE", "#E6D8D0"), snow="#FFF2E0",
        midink="#4A4020", hill_mid=Pal("#A6C45A", "#7EA046", "#D0DC7A"), hill_far=Pal("#C8CC8A", "#AAB076", "#E4DEA0"),
        ground=Pal("#86B24A", "#62903A", "#B4D060"), path=Pal("#F6D694", "#D2A860", "#FFEAB8"),
        leaf=Pal("#6AAE44", "#437E34", "#A8D45A"), pine=Pal("#4E9050", "#316C40", "#86BC64"),
        stone=Pal("#F0DCC0", "#C6A882", "#FFF2DC"), roof=Pal("#E0482E", "#A82E1E", "#FF8A5A"),
        wood=Pal("#BA7E48", "#84542E", "#E2AA6A"), cloud=Pal("#FFF4E4", "#F0C0A8", "#FFFFFF"),
        haze="#FFD8A0", window="#3A2C24", light=None, rock=Pal("#C8B8A4", "#9A8874", "#EAD8C4")),
    "dusk": dict(
        sky=["#0E0C2A", "#2A1E5A", "#7A3E7C", "#E27440"],
        far=Pal("#3E2F6E", "#2E225A", "#56408A"), far2=Pal("#553E80", "#44306C", "#6C509A"), snow="#B9A8E0",
        midink="#120E24", hill_mid=Pal("#2F3F62", "#22304E", "#44567A"), hill_far=Pal("#44466E", "#34385C", "#5A5A86"),
        ground=Pal("#2B4A4A", "#1E3638", "#3E6660"), path=Pal("#8A7A8A", "#665A6E", "#B09AA0"),
        leaf=Pal("#2C5A56", "#1C4040", "#44807A"), pine=Pal("#244A4E", "#16343A", "#3A6E6E"),
        stone=Pal("#6E6488", "#4E4668", "#8C80A8"), roof=Pal("#7A2E4A", "#541E34", "#A4466A"),
        wood=Pal("#5E4450", "#402E38", "#7E5E6A"), cloud=Pal("#5A3E7E", "#3E2A60", "#7A5A9E"),
        haze="#E27440", window="#FFC45A", light="#FFB23F", rock=Pal("#4E4A66", "#36344C", "#6A6686")),
}


def rng(seed):
    return random.Random(seed)


# ---------- near props (black ink) ----------

def tree_round(x, y, s, t, seed=1, ink=True):
    L, Wd = t["leaf"], t["wood"]
    w = 4 if ink else 0
    g = [f'<g transform="translate({x} {y}) scale({s})">', ground_shadow(4, 2, 38, 7, 0.25)]
    g.append(part("M-7 0 C -6 -20 -5 -40 -4 -58 L 5 -58 C 6 -40 7 -20 9 0 Z", Wd,
                  shade="M1 -60 L 14 -60 L 14 4 L 1 4 Z", w=w))
    g.append(line("M-3 -46 C -12 -54 -20 -58 -28 -58", w=5, col=INK) + line("M-3 -46 C -12 -54 -20 -58 -28 -58", w=2.4, col=Wd.base))
    canopy = ("M-44 -70 C -60 -76 -58 -104 -40 -110 C -40 -134 -12 -148 8 -136 C 24 -150 54 -136 50 -110 "
              "C 66 -104 66 -76 48 -70 C 40 -58 18 -56 4 -62 C -12 -54 -34 -58 -44 -70 Z")
    g.append(part(canopy, L,
                  shade="M-60 -76 C -30 -66 20 -66 70 -84 L 70 -40 L -60 -40 Z",
                  deep="M20 -130 C 44 -126 56 -110 58 -92 C 48 -104 34 -112 20 -112 Z",
                  hi=["M-36 -106 C -34 -126 -12 -136 4 -130 C -10 -126 -22 -116 -26 -100 Z",
                      "M14 -134 C 26 -140 40 -136 46 -126 C 38 -130 28 -130 20 -126 Z"],
                  w=w))
    rr = rng(seed)
    for _ in range(3):
        cx, cy = rr.uniform(-30, 30), rr.uniform(-120, -86)
        g.append(line(f"M{cx-5} {cy} q5 -5 10 0", w=2.2, col=L.shade))
    g.append('</g>')
    return "\n".join(g)


def tree_pine(x, y, s, t, ink=True, ink_col=INK, w=4):
    P, Wd = t["pine"], t["wood"]
    w = w if ink else 0
    g = [f'<g transform="translate({x} {y}) scale({s})">', ground_shadow(3, 2, 26, 5, 0.25)]
    g.append(part("M-5 0 L 5 0 L 5 -22 L -5 -22 Z", Wd, shade="M1 -26 L 9 -26 L 9 4 L 1 4 Z", w=w))
    for (top, bot, half) in ((-128, -84, 20), (-106, -56, 28), (-80, -18, 36)):
        d = f"M0 {top} C 8 {top+14} {half-6} {bot-8} {half} {bot} C {half/2} {bot+6} {-half/2} {bot+6} {-half} {bot} C {-half+6} {bot-8} -8 {top+14} 0 {top} Z"
        g.append(part(d, P, shade=f"M0 {top-4} L {half+8} {top-4} L {half+8} {bot+10} L 0 {bot+10} Z",
                      hi=f"M-2 {top+6} C -6 {top+18} {-half/2} {bot-10} {-half+8} {bot-4} C {-half/2+4} {bot-14} -6 {top+20} -2 {top+6} Z",
                      w=w))
    g.append('</g>')
    return "\n".join(g).replace(f'stroke="{INK}"', f'stroke="{ink_col}"')


def bush(x, y, s, t, ink=True):
    L = t["leaf"]
    d = "M-30 0 C -40 -2 -40 -20 -28 -22 C -26 -36 -8 -40 0 -32 C 8 -42 28 -38 28 -24 C 42 -22 42 0 30 0 Z"
    return (f'<g transform="translate({x} {y}) scale({s})">' + ground_shadow(2, 1, 34, 5, 0.22) +
            part(d, L, shade="M-44 -10 C -10 -4 20 -6 46 -14 L 46 6 L -44 6 Z",
                 hi="M-24 -22 C -22 -32 -10 -34 -4 -30 C -12 -28 -18 -24 -20 -18 Z", w=4 if ink else 0) + '</g>')


def rock(x, y, s, t):
    R = t["rock"]
    d = "M-22 0 C -26 -12 -14 -26 2 -24 C 16 -22 26 -12 22 0 Z"
    return (f'<g transform="translate({x} {y}) scale({s})">' + ground_shadow(2, 1, 24, 4, 0.2) +
            part(d, R, shade="M2 -30 L 30 -30 L 30 4 L 4 4 C 8 -10 6 -20 2 -30 Z",
                 hi="M-14 -14 C -10 -20 -4 -22 2 -22 C -4 -18 -8 -14 -10 -8 Z", w=3.6) + '</g>')


def flower(x, y, col, t, s=1):
    st = t["leaf"].shade
    return (f'<g transform="translate({x} {y}) scale({s})">' + line("M0 0 C 1 -6 -1 -10 0 -16", w=2.4, col=st) +
            "".join(f'<circle cx="{4.5*math.cos(a):.1f}" cy="{-18+4.5*math.sin(a):.1f}" r="3.6" fill="{col}" stroke="{INK}" stroke-width="1.6"/>'
                    for a in [i * 2 * math.pi / 5 for i in range(5)]) +
            f'<circle cx="0" cy="-18" r="2.6" fill="#FFD23F" stroke="{INK}" stroke-width="1.4"/></g>')


def grass_edge(x0, x1, ypath, t, seed=3):
    """scalloped grass lip along the top of the ground"""
    rr = rng(seed)
    G = t["ground"]
    out = []
    x = x0
    while x < x1:
        w = rr.uniform(10, 18)
        y = ypath(x)
        out.append(f'<path d="M{x:.1f} {y+4:.1f} Q {x+w/2:.1f} {y-rr.uniform(6,11):.1f} {x+w:.1f} {ypath(x+w)+4:.1f}" fill="{G.hi}" stroke="{INK}" stroke-width="3" stroke-linejoin="round"/>')
        x += w * 0.8
    return "\n".join(out)


def tuft(x, y, t, s=1):
    c = t["leaf"].shade
    return (f'<g transform="translate({x} {y}) scale({s})">' +
            line("M0 0 q-3 -10 -8 -15 M4 0 q1 -12 5 -17 M8 0 q5 -8 11 -11", w=3, col=c) + '</g>')


def fence(x, y, n, t):
    Wd = t["wood"]
    g = [f'<g transform="translate({x} {y})">']
    for i in range(n):
        px = i * 26
        g.append(part(f"M{px-4} 0 L {px-4} -34 L {px} -40 L {px+4} -34 L {px+4} 0 Z", Wd, shade=f"M{px} -44 L {px+8} -44 L {px+8} 4 L {px} 4 Z", w=3.4))
    for yy in (-28, -14):
        g.append(part(f"M-8 {yy} L {n*26-18} {yy-2} L {n*26-18} {yy+5} L -8 {yy+7} Z", Wd, shade=f"M-10 {yy+3} L {n*26} {yy+1} L {n*26} {yy+10} L -10 {yy+10} Z", w=3.2))
    g.append('</g>')
    return "\n".join(g)


def signpost(x, y, t):
    Wd = t["wood"]
    g = [f'<g transform="translate({x} {y})">', ground_shadow(0, 1, 16, 3, 0.25)]
    g.append(part("M-4 0 L -4 -64 L 4 -64 L 4 0 Z", Wd, shade="M0 -70 L 8 -70 L 8 4 L 0 4 Z", w=3.6))
    g.append(part("M-2 -62 L 38 -62 L 48 -52 L 38 -42 L -2 -42 Z", Wd, shade="M-4 -48 L 52 -48 L 52 -38 L -4 -38 Z",
                  hi="M2 -60 L 36 -60 L 38 -58 L 2 -58 Z", w=3.6,
                  extra=line("M6 -52 L 32 -52", w=2.2, col=Wd.shade)))
    g.append(part("M2 -38 L -38 -38 L -46 -29 L -38 -20 L 2 -20 Z", Wd, shade="M-50 -26 L 6 -26 L 6 -16 L -50 -16 Z", w=3.6,
                  extra=line("M-32 -29 L -6 -29", w=2.2, col=Wd.shade)))
    g.append('</g>')
    return "\n".join(g)


def torch(x, y, t, lit=False):
    g = [f'<g transform="translate({x} {y})">']
    g.append(part("M-3 0 L -3 -58 L 3 -58 L 3 0 Z", Pal("#4A3F5E", "#2E2640"), shade="M0 -60 L 6 -60 L 6 4 L 0 4 Z", w=3))
    g.append(part("M-9 -58 L 9 -58 L 7 -66 L -7 -66 Z", Pal("#6A5A7E", "#4A3F5E"), w=3))
    if lit:
        g.append('<circle cx="0" cy="-78" r="34" fill="url(#torchGlow)"/>')
        g.append(part("M0 -96 C 8 -86 10 -76 6 -70 C 4 -66 -4 -66 -6 -70 C -10 -76 -8 -86 0 -96 Z",
                      Pal("#FF8A2A", "#E0501A", "#FFE08A"), hi="M0 -86 C 4 -80 4 -74 2 -70 L -2 -70 C -4 -74 -3 -80 0 -86 Z", w=2.6))
    g.append('</g>')
    return "\n".join(g)


# ---------- mid props (tinted ink) ----------

def castle(x, y, s, t):
    S, R, ink = t["stone"], t["roof"], t["midink"]
    w = 3
    g = [f'<g transform="translate({x} {y}) scale({s})">']
    # curtain wall with crenellations
    wall = "M-76 0 L -76 -92 L -66 -92 L -66 -100 L -54 -100 L -54 -92 L -42 -92 L -42 -100 L -30 -100 L -30 -92 L -18 -92 L -18 -100 L -6 -100 L -6 -92 L 6 -92 L 6 -100 L 18 -100 L 18 -92 L 30 -92 L 30 -100 L 42 -100 L 42 -92 L 54 -92 L 54 -100 L 66 -100 L 66 -92 L 76 -92 L 76 0 Z"
    g.append(part(wall, S, shade="M30 -110 L 90 -110 L 90 6 L 30 6 Z", hi="M-72 -88 L -60 -88 L -60 -4 L -72 -4 Z", w=w,
                  extra="".join(f'<rect x="{bx}" y="{by}" width="14" height="6" rx="1.5" fill="{S.shade}" opacity="0.55"/>'
                                for bx, by in ((-60, -70), (-34, -50), (-50, -30), (4, -76), (14, -40), (-12, -24), (40, -60)))))
    # gate
    g.append(part("M-18 0 L -18 -36 C -18 -52 18 -52 18 -36 L 18 0 Z", Pal(t["window"], t["window"]), w=w,
                  extra="".join(line(f"M{gx} -48 L {gx} 0", w=2, col=t["wood"].base) for gx in (-10, -3, 4, 11)) +
                        line("M-18 -30 L 18 -30 M -18 -16 L 18 -16", w=2, col=t["wood"].base)))
    # towers
    for tx, th, tw in ((-86, 150, 38), (86, 136, 34), (0, 196, 44)):
        body = f"M{tx-tw/2} 0 L {tx-tw/2} {-th} L {tx+tw/2} {-th} L {tx+tw/2} 0 Z"
        g.append(part(body, S, shade=f"M{tx+tw*0.15} {-th-10} L {tx+tw} {-th-10} L {tx+tw} 6 L {tx+tw*0.15} 6 Z",
                      hi=f"M{tx-tw/2+4} {-th+4} L {tx-tw/2+10} {-th+4} L {tx-tw/2+10} -4 L {tx-tw/2+4} -4 Z", w=w))
        roof = f"M{tx-tw/2-8} {-th} L {tx} {-th-tw*1.25} L {tx+tw/2+8} {-th} Z"
        g.append(part(roof, R, shade=f"M{tx} {-th-tw*1.3} L {tx+tw} {-th-tw*1.3} L {tx+tw} {-th+4} L {tx} {-th+4} Z",
                      hi=f"M{tx-tw/2-2} {-th-2} L {tx-2} {-th-tw*1.15} L {tx-6} {-th-2} Z", w=w))
        for wy in range(int(-th + 26), -30, 40):
            g.append(part(f"M{tx-5} {wy+14} L {tx-5} {wy+5} C {tx-5} {wy-2} {tx+5} {wy-2} {tx+5} {wy+5} L {tx+5} {wy+14} Z",
                          Pal(t["window"], t["window"]), w=2.4))
        g.append(line(f"M{tx} {-th-tw*1.25} L {tx} {-th-tw*1.25-22}", w=2.6, col=ink))
        g.append(part(f"M{tx} {-th-tw*1.25-22} L {tx+20} {-th-tw*1.25-17} L {tx} {-th-tw*1.25-11} Z",
                      Pal("#1E8C8C", "#136066", "#48B8B0") if tx else Pal("#F6BB3E", "#C7861A"), w=2.4))
    g.append('</g>')
    return "\n".join(g).replace(f'stroke="{INK}"', f'stroke="{ink}"')


def windmill(x, y, s, t):
    S, R, Wd, ink = t["stone"], t["roof"], t["wood"], t["midink"]
    g = [f'<g transform="translate({x} {y}) scale({s})">']
    g.append(part("M-20 0 L -14 -80 L 14 -80 L 20 0 Z", S, shade="M2 -86 L 26 -86 L 26 6 L 4 6 Z", w=3))
    g.append(part("M-18 -80 L 0 -104 L 18 -80 Z", R, shade="M0 -108 L 22 -108 L 22 -76 L 0 -76 Z", w=3))
    g.append(part("M-6 0 L -6 -16 C -6 -24 6 -24 6 -16 L 6 0 Z", Pal(t["window"], t["window"]), w=2.4))
    for a in (20, 110, 200, 290):
        g.append(f'<g transform="rotate({a} 0 -84)">' +
                 part("M-3 -84 L -3 -150 L 3 -150 L 3 -84 Z", Wd, w=2.4) +
                 part("M3 -144 L 22 -144 L 22 -98 L 3 -98 Z", Pal(S.hi, S.shade), w=2.4,
                      extra=line("M3 -128 L 22 -128 M3 -113 L 22 -113 M 12 -144 L 12 -98", w=1.6, col=S.shade)) + '</g>')
    g.append(f'<circle cx="0" cy="-84" r="5" fill="{Wd.base}" stroke="{INK}" stroke-width="2.4"/>')
    g.append('</g>')
    return "\n".join(g).replace(f'stroke="{INK}"', f'stroke="{ink}"')


def ruin(x, y, s, t):
    S, ink = t["stone"], t["midink"]
    g = [f'<g transform="translate({x} {y}) scale({s})">']
    g.append(part("M-60 0 L -60 -54 L -48 -60 L -44 -30 L -30 -30 L -30 0 Z", S, shade="M-44 -64 L -28 -64 L -28 4 L -44 4 Z", w=3))
    body = "M-32 0 L -32 -170 L -20 -184 L -10 -170 L 0 -178 L 10 -168 L 22 -190 L 32 -176 L 32 0 Z"
    g.append(part(body, S, shade="M8 -200 L 40 -200 L 40 6 L 8 6 Z", hi="M-28 -166 L -22 -166 L -22 -6 L -28 -6 Z", w=3,
                  extra="".join(f'<rect x="{bx}" y="{by}" width="14" height="6" rx="1.5" fill="{S.shade}" opacity="0.6"/>'
                                for bx, by in ((-24, -150), (-14, -110), (-26, -70), (6, -130), (10, -50)))))
    for wy in (-140, -96, -52):
        g.append(part(f"M-6 {wy+18} L -6 {wy+6} C -6 {wy-4} 6 {wy-4} 6 {wy+6} L 6 {wy+18} Z", Pal(t["window"], t["window"]), w=2.4))
    g.append(part("M32 0 L 32 -48 L 52 -40 L 58 -12 L 58 0 Z", S, shade="M40 -52 L 64 -52 L 64 4 L 40 4 Z", w=3))
    g.append('</g>')
    return "\n".join(g).replace(f'stroke="{INK}"', f'stroke="{ink}"')


# ---------- sky ----------

def cloud(x, y, s, t, variant=0):
    C = t["cloud"]
    shapes = [
        "M-60 0 C -76 0 -76 -22 -58 -24 C -56 -44 -30 -52 -14 -38 C -6 -60 30 -62 40 -38 C 60 -44 76 -26 66 -10 C 76 -4 70 6 58 6 L -52 6 C -62 6 -66 2 -60 0 Z",
        "M-40 0 C -52 0 -50 -18 -36 -18 C -34 -34 -12 -38 -2 -26 C 6 -40 28 -38 32 -22 C 46 -22 48 0 36 2 Z",
    ]
    d = shapes[variant % 2]
    return (f'<g transform="translate({x} {y}) scale({s})">' +
            part(d, C, shade="M-80 -6 C -30 -2 30 -2 80 -10 L 80 12 L -80 12 Z",
                 hi="M-48 -22 C -44 -38 -26 -44 -16 -36 C -26 -34 -36 -28 -40 -18 Z", w=2.6).replace(f'stroke="{INK}"', f'stroke="{C.shade}"') + '</g>')
