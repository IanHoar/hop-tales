import math, sys
from ink import *
from props import *

WW, WH = 2340, 844
GROUND = 448


def ridge(points, base=WH):
    d = f"M{points[0][0]} {base} " + " ".join(f"L{x} {y}" for x, y in points) + f" L{points[-1][0]} {base} Z"
    return d


def mountains(t, seed, y0, amp, step, col, snow=True, shade=True):
    rr = rng(seed)
    pts, x = [], -40
    peaks = []
    up = True
    while x < WW + 80:
        y = y0 - (rr.uniform(0.55, 1.0) * amp if up else rr.uniform(0.05, 0.3) * amp)
        pts.append((round(x), round(y)))
        if up:
            peaks.append((round(x), round(y)))
        up = not up
        x += rr.uniform(step * 0.6, step * 1.1)
    out = [f'<path d="{ridge(pts, WH)}" fill="{col.base}"/>']
    # right-face shading per peak, and snow caps
    for i in range(1, len(pts) - 1):
        px, py = pts[i]
        if (px, py) not in peaks:
            continue
        nx, ny = pts[i + 1]
        lx, ly = pts[i - 1]
        if shade:
            mx = px + (nx - px) * 0.15
            out.append(f'<path d="M{px} {py} L {nx} {ny} L {nx} {WH} L {mx+ (px-mx)*0} {WH} L {px+ (nx-px)*0.12} {py + (WH-py)*0.6} Z" fill="{col.shade}"/>')
        if snow and y0 - py > amp * 0.72:
            h = (ly - py) * 0.32
            sx1, sy1 = px + (lx - px) * 0.3, py + (ly - py) * 0.3
            sx2, sy2 = px + (nx - px) * 0.3, py + (ny - py) * 0.3
            out.append(f'<path d="M{px} {py} L {sx2:.0f} {sy2:.0f} L {sx2-6:.0f} {sy2-4:.0f} L {px+4} {sy2-2:.0f} L {px-6} {sy1+2:.0f} L {sx1+8:.0f} {sy1-4:.0f} L {sx1:.0f} {sy1:.0f} Z" fill="{t["snow"]}"/>')
    return "\n".join(out)


def hills(seed, y0, amp, period, pal, ink=None, w=0, hi=True):
    rr = rng(seed)
    d = f"M-20 {WH} L -20 {y0}"
    x = -20
    tops = []
    while x < WW + 40:
        span = rr.uniform(period * 0.7, period * 1.3)
        top = y0 - rr.uniform(0.4, 1) * amp
        d += f" C {x+span*0.25:.0f} {top:.0f} {x+span*0.75:.0f} {top:.0f} {x+span:.0f} {y0 + rr.uniform(-8, 8):.0f}"
        tops.append((x + span * 0.5, top))
        x += span
    d += f" L {WW+40} {WH} Z"
    out = part(d, pal, shade=f"M-20 {y0+40} L {WW+40} {y0+40} L {WW+40} {WH} L -20 {WH} Z",
               hi=[f"M{tx-60:.0f} {ty+12:.0f} C {tx-30:.0f} {ty+1:.0f} {tx+10:.0f} {ty:.0f} {tx+40:.0f} {ty+6:.0f} C {tx+10:.0f} {ty+6:.0f} {tx-30:.0f} {ty+8:.0f} {tx-60:.0f} {ty+16:.0f} Z" for tx, ty in tops] if hi else None,
               w=w)
    if ink:
        out = out.replace(f'stroke="{INK}"', f'stroke="{ink}"')
    return out


def sky_layer(tod):
    t = TOD[tod]
    s = t["sky"]
    defs = (f'<linearGradient id="sky" x1="0" y1="0" x2="0" y2="1">'
            f'<stop offset="0" stop-color="{s[0]}"/><stop offset="0.35" stop-color="{s[1]}"/>'
            f'<stop offset="0.62" stop-color="{s[2]}"/><stop offset="0.9" stop-color="{s[3]}"/></linearGradient>'
            '<radialGradient id="glow" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#FFF6D0" stop-opacity="0.95"/>'
            '<stop offset="0.35" stop-color="#FFE9A0" stop-opacity="0.45"/><stop offset="1" stop-color="#FFE9A0" stop-opacity="0"/></radialGradient>')
    b = [f'<rect width="{WW}" height="{WH}" fill="url(#sky)"/>']
    if tod == "day":
        b += ['<circle cx="300" cy="130" r="170" fill="url(#glow)"/>',
              part("M256 130 C 256 72 344 72 344 130 C 344 188 256 188 256 130 Z", Pal("#FFE27A", "#FFC23A", "#FFF6CC"),
                   shade="M250 150 C 280 170 320 170 350 140 L 350 200 L 250 200 Z", hi="M272 112 C 280 96 296 90 310 92 C 296 98 286 106 282 120 Z", w=0)]
        for i, (cx, cy, sc, v) in enumerate(((120, 190, 0.9, 0), (560, 120, 1.3, 0), (900, 230, 0.8, 1), (1260, 150, 1.1, 0),
                                              (1640, 210, 0.9, 1), (2000, 130, 1.2, 0), (2260, 240, 0.7, 1))):
            b.append(cloud(cx, cy, sc, t, v))
    elif tod == "gold":
        b += ['<circle cx="120" cy="280" r="260" fill="url(#glow)"/>',
              part("M80 280 C 80 226 160 226 160 280 C 160 334 80 334 80 280 Z", Pal("#FFD06A", "#FFA23A", "#FFF0C0"),
                   shade="M76 300 C 100 318 140 318 164 294 L 164 340 L 76 340 Z", w=0)]
        for cx, cy, sc, v in ((340, 150, 1.2, 0), (760, 200, 0.9, 1), (1100, 120, 1.3, 0), (1500, 230, 0.8, 1), (1900, 160, 1.1, 0), (2240, 110, 0.9, 1)):
            b.append(cloud(cx, cy, sc, t, v))
    else:
        rr = rng(9)
        for _ in range(140):
            x, y, r = rr.uniform(0, WW), rr.uniform(0, 330), rr.choice((1, 1.2, 1.5, 2))
            b.append(f'<circle cx="{x:.0f}" cy="{y:.0f}" r="{r}" fill="#FFF3D6" opacity="{rr.uniform(0.5, 1):.2f}"/>')
        for x, y in ((300, 180), (900, 90), (1420, 200), (1880, 70), (2200, 160)):
            b.append(f'<path d="M{x} {y-9} L {x+2.5} {y-2.5} L {x+9} {y} L {x+2.5} {y+2.5} L {x} {y+9} L {x-2.5} {y+2.5} L {x-9} {y} L {x-2.5} {y-2.5} Z" fill="#FFF3D6"/>')
        b += ['<circle cx="200" cy="140" r="170" fill="url(#glow)" opacity="0.55"/>',
              part("M160 140 C 160 86 240 86 240 140 C 240 194 160 194 160 140 Z", Pal("#FFF4D6", "#E4D2A8", "#FFFFFF"),
                   shade="M150 124 C 176 140 206 150 250 146 L 250 200 L 150 200 Z", w=0,
                   extra='<circle cx="186" cy="122" r="9" fill="#E4D2A8"/><circle cx="214" cy="156" r="6" fill="#E4D2A8"/><circle cx="196" cy="166" r="4" fill="#E4D2A8"/>')]
        for cx, cy, sc, v in ((520, 260, 1.2, 0), (1200, 300, 1.0, 1), (1760, 250, 1.3, 0), (2200, 290, 0.9, 1)):
            b.append(f'<g opacity="0.8">{cloud(cx, cy, sc, t, v)}</g>')
    return svg(WW, WH, "\n".join(b), defs=defs)


def far_layer(tod):
    t = TOD[tod]
    b = [mountains(t, 4, 330, 150, 150, t["far2"], snow=True),
         mountains(t, 7, 370, 130, 120, t["far"], snow=True),
         f'<rect x="0" y="330" width="{WW}" height="80" fill="{t["haze"]}" opacity="{0.35 if tod != "dusk" else 0.18}" filter="url(#fog)"/>',
         hills(11, 380, 34, 260, t["hill_far"], hi=False)]
    defs = '<filter id="fog" x="-10%" y="-100%" width="120%" height="300%"><feGaussianBlur stdDeviation="18"/></filter>'
    return svg(WW, WH, "\n".join(b), defs=defs)


def mid_layer(tod):
    t = TOD[tod]
    b = [hills(21, 418, 40, 300, t["hill_mid"], ink=t["midink"], w=3)]
    ink = t["midink"]
    for x, y, s in ((60, 400, 0.55), (110, 404, 0.45), (460, 392, 0.5), (1040, 398, 0.5), (1090, 402, 0.4), (1700, 396, 0.55), (1760, 400, 0.45), (2150, 394, 0.6)):
        b.append(tree_pine(x, y, s, t, ink_col=ink, w=5))
    b.append(windmill(300, 404, 0.8, t))
    b.append(castle(820, 404, 0.9, t))
    b.append(ruin(1460, 398, 0.85, t))
    for x, y, s in ((200, 404, 0.5), (620, 396, 0.45), (1250, 404, 0.5), (1980, 398, 0.55), (2280, 402, 0.5)):
        b.append(tree_round(x, y, s, t).replace(f'stroke="{INK}"', f'stroke="{ink}"'))
    return svg(WW, WH, "\n".join(b))


def near_layer(tod):
    t = TOD[tod]
    G = t["ground"]

    def ytop(x):
        return GROUND - 10 * math.sin(x / 190) - 6 * math.sin(x / 63 + 1)

    pts = " ".join(f"L{x} {ytop(x):.1f}" for x in range(-20, WW + 41, 20))
    ground = f"M-20 {WH} {pts} L {WW+40} {WH} Z"
    b = []
    # background props behind the ground lip
    b += [tree_round(-10, ytop(0) + 6, 1.0, t, 1), bush(120, ytop(120) + 4, 1, t), tree_round(360, ytop(360) + 6, 0.9, t, 2),
          tree_pine(430, ytop(430) + 6, 0.85, t), tree_round(640, ytop(640) + 6, 1.05, t, 3), bush(700, ytop(700) + 4, 0.9, t),
          tree_pine(1340, ytop(1340) + 6, 0.95, t), tree_round(1420, ytop(1420) + 6, 0.95, t, 4),
          tree_pine(1700, ytop(1700) + 6, 1.05, t), tree_pine(1760, ytop(1760) + 6, 0.85, t),
          tree_pine(2040, ytop(2040) + 6, 1.1, t), tree_pine(2330, ytop(2330) + 6, 1.15, t)]
    b.append(part(ground, G, shade=f"M-20 {GROUND+24} L {WW+40} {GROUND+24} L {WW+40} {WH} L -20 {WH} Z", w=4))
    b.append(grass_edge(-20, WW + 40, ytop, t))
    rr = rng(17)
    for _ in range(70):
        x, y = rr.uniform(0, WW), rr.uniform(GROUND + 70, WH - 20)
        b.append(tuft(x, y, t, rr.uniform(0.7, 1.2)))
    for _ in range(40):
        x, y = rr.uniform(0, WW), rr.uniform(GROUND + 60, WH - 10)
        b.append(f'<ellipse cx="{x:.0f}" cy="{y:.0f}" rx="{rr.uniform(4,9):.1f}" ry="{rr.uniform(2,4):.1f}" fill="{G.shade}"/>')
    for _ in range(8):
        x, y = rr.uniform(0, WW), rr.uniform(GROUND + 90, WH - 40)
        b.append(f'<path d="M{x-60:.0f} {y:.0f} C {x-30:.0f} {y-14:.0f} {x+30:.0f} {y-14:.0f} {x+60:.0f} {y:.0f} C {x+30:.0f} {y+8:.0f} {x-30:.0f} {y+8:.0f} {x-60:.0f} {y:.0f} Z" fill="{G.hi}" opacity="0.35"/>')
    # path
    b.append(f'<path d="M-20 {GROUND+30} C 300 {GROUND+14} 600 {GROUND+44} 900 {GROUND+28} S 1500 {GROUND+18} 1800 {GROUND+36} S 2200 {GROUND+26} 2360 {GROUND+30}" '
             f'stroke="{INK}" stroke-width="26" fill="none" stroke-linecap="round"/>'
             f'<path d="M-20 {GROUND+30} C 300 {GROUND+14} 600 {GROUND+44} 900 {GROUND+28} S 1500 {GROUND+18} 1800 {GROUND+36} S 2200 {GROUND+26} 2360 {GROUND+30}" '
             f'stroke="{t["path"].base}" stroke-width="19" fill="none" stroke-linecap="round"/>')
    # foreground props on the lip
    b += [fence(20, ytop(40) + 2, 4, t), rock(260, ytop(260) + 3, 1, t), signpost(1300, ytop(1300) + 3, t),
          rock(1580, ytop(1580) + 3, 1.2, t), rock(2010, ytop(2010) + 3, 1.3, t)]
    for x in (170, 300, 520, 780, 960, 1120, 1480, 1640, 1860, 2100, 2240):
        b.append(tuft(x, ytop(x) + 2, t))
    if tod != "dusk":
        for x, c in ((140, "#FFFFFF"), (152, "#FF8FB0"), (310, "#FFD23F"), (540, "#FFFFFF"), (560, "#FF8FB0"), (820, "#FFD23F"), (1180, "#FFFFFF"), (1200, "#FF8FB0")):
            b.append(flower(x, ytop(x) + 3, c, t))
    b += [torch(2000, ytop(2000) + 2, t, lit=tod == "dusk"), torch(2250, ytop(2250) + 2, t, lit=tod == "dusk")]
    defs = ('<radialGradient id="torchGlow" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#FFC96B" stop-opacity="0.85"/>'
            '<stop offset="0.45" stop-color="#FFA24A" stop-opacity="0.3"/><stop offset="1" stop-color="#FFA24A" stop-opacity="0"/></radialGradient>')
    return svg(WW, WH, "\n".join(b), defs=defs)


if __name__ == "__main__":
    import os
    os.makedirs("world", exist_ok=True)
    for tod in ("day", "gold", "dusk"):
        open(f"world/sky-{tod}.svg", "w").write(sky_layer(tod))
        open(f"world/far-{tod}.svg", "w").write(far_layer(tod))
        open(f"world/mid-{tod}.svg", "w").write(mid_layer(tod))
        open(f"world/near-{tod}.svg", "w").write(near_layer(tod))
    print("ok")
