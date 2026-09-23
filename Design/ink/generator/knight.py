from ink import *

STEEL = Pal("#C9D3DE", "#8795A8", "#F4F8FC", "#5E6B80")
STEEL_D = Pal("#8795A8", "#5E6B80", "#B8C4D2")
RED = Pal("#DB2A2E", "#A3141D", "#FF6A55")
GOLD = Pal("#F6BB3E", "#C7861A", "#FFE39A")
LEATHER = Pal("#8A5A3A", "#5E3B24", "#B07A52")
WOOD = Pal("#B07A48", "#7D5230", "#D8A26A")
TEAL = Pal("#1E8C8C", "#136066", "#48B8B0")
W = 3.6


def star(cx, cy, r, fill, stroke=None, sw=0):
    import math
    pts = []
    for i in range(10):
        a = -math.pi / 2 + i * math.pi / 5
        rr = r if i % 2 == 0 else r * 0.45
        pts.append(f"{cx + rr*math.cos(a):.1f} {cy + rr*math.sin(a):.1f}")
    st = f' stroke="{stroke}" stroke-width="{sw}" stroke-linejoin="round"' if stroke else ""
    return f'<path d="M{" L".join(pts)} Z" fill="{fill}"{st}/>'


def knight(wave=0):
    p = [ground_shadow(0, 1, 44, 6, 0.3)]
    # banner pole behind (held in right hand, viewer's right)
    banner = []
    banner.append(part("M30 -150 L 35 -150 L 35 -6 L 30 -6 Z", WOOD, shade="M33 -160 L 40 -160 L 40 0 L 33 0 Z", w=3))
    flag = "M35 -148 C 52 -150 66 -144 80 -146 L 72 -132 L 82 -118 C 66 -116 52 -122 35 -120 Z"
    banner.append(part(flag, TEAL, shade="M35 -128 C 52 -130 66 -124 90 -126 L 90 -110 L 35 -110 Z",
                  hi="M38 -146 C 50 -147 60 -144 70 -144 C 60 -142 48 -142 38 -142 Z", w=3,
                  extra=star(55, -134, 7, GOLD.base, INK, 1.6)))
    banner.append(part("M28 -156 C 28 -160 37 -160 37 -156 C 37 -152 28 -152 28 -156 Z", GOLD, w=2.5))
    p.append(f'<g transform="rotate({wave} 32 -62)">' + "".join(banner) + "</g>")
    # legs + boots
    for x in (-12, 6):
        p.append(part(f"M{x-2} -44 L {x+10} -44 L {x+10} -14 L {x-2} -14 Z", STEEL_D, shade=f"M{x+5} -48 L{x+14} -48 L{x+14} -10 L{x+5} -10 Z", w=W))
        p.append(part(f"M{x-5} -16 L {x+11} -16 C {x+13} -16 {x+14} -12 {x+14} -8 L {x+14} 0 L {x-8} 0 C {x-9} -6 {x-8} -16 {x-5} -16 Z",
                      LEATHER, shade=f"M{x+4} -20 L{x+18} -20 L{x+18} 4 L{x+4} 4 Z", hi=f"M{x-4} -14 L {x+6} -14 L {x+6} -11 L {x-4} -11 Z", w=W))
    # chainmail torso under tabard
    p.append(part("M-26 -86 C -28 -70 -28 -52 -24 -40 L 24 -40 C 28 -52 28 -70 26 -86 Z", STEEL_D,
                  shade="M4 -90 L 30 -90 L 30 -36 L 4 -36 Z", w=W))
    # tabard
    tab = "M-20 -84 L 20 -84 C 22 -70 24 -54 26 -38 L 14 -32 L 0 -38 L -14 -32 L -26 -38 C -24 -54 -22 -70 -20 -84 Z"
    p.append(part(tab, RED, shade="M4 -90 L 32 -90 L 32 -30 L 4 -30 Z",
                  hi="M-18 -82 L -8 -82 L -12 -46 L -20 -44 Z", w=W,
                  extra=star(0, -62, 11, GOLD.base, INK, 2.2) + star(-1.5, -63.5, 5, GOLD.hi)))
    # belt
    p.append(part("M-24 -48 L 24 -48 L 25 -40 L -25 -40 Z", LEATHER, shade="M4 -50 L 30 -50 L 30 -38 L 4 -38 Z", w=3,
                  extra=f'<rect x="-5" y="-49" width="10" height="10" rx="2" fill="{GOLD.base}" stroke="{INK}" stroke-width="2"/>'))
    # arm holding pole
    p.append(part("M18 -82 C 30 -84 36 -74 34 -62 C 32 -56 26 -56 24 -62 C 24 -70 20 -74 16 -74 Z", STEEL,
                  shade="M26 -86 L 40 -86 L 40 -50 L 26 -50 Z", w=W))
    p.append(part("M26 -66 C 26 -72 38 -72 38 -66 C 38 -60 26 -60 26 -66 Z", LEATHER, w=3))
    # shield (viewer's left)
    sh = "M-46 -80 C -34 -84 -22 -84 -12 -80 C -12 -60 -18 -46 -29 -38 C -40 -46 -46 -60 -46 -80 Z"
    p.append(part(sh, TEAL, shade="M-29 -90 L -6 -90 L -6 -30 L -29 -30 Z",
                  hi="M-42 -78 C -38 -80 -34 -80 -32 -80 L -34 -58 C -38 -62 -41 -68 -42 -78 Z", w=W,
                  extra=f'<path d="M-46 -80 C -34 -84 -22 -84 -12 -80" stroke="{GOLD.base}" stroke-width="5" fill="none"/>'
                        + star(-29, -62, 9, GOLD.base, INK, 2)))
    # pauldrons
    for cx, sgn in ((-20, -1), (20, 1)):
        p.append(part(f"M{cx-12} -84 C {cx-12} -96 {cx+12} -96 {cx+12} -84 C {cx+12} -78 {cx-12} -78 {cx-12} -84 Z", STEEL,
                      shade=f"M{cx-14} -84 C {cx-4} -80 {cx+6} -80 {cx+14} -86 L {cx+14} -76 L {cx-14} -76 Z",
                      hi=f"M{cx-8} -90 C {cx-4} -94 {cx+2} -94 {cx+6} -92 C {cx+2} -90 {cx-4} -90 {cx-8} -88 Z", w=W))
    # helmet
    helm = "M-30 -112 C -30 -140 30 -140 30 -112 C 30 -98 26 -88 20 -86 L -20 -86 C -26 -88 -30 -98 -30 -112 Z"
    p.append(part(helm, STEEL,
                  shade="M6 -150 C 24 -140 34 -120 34 -100 L 34 -80 L 8 -80 Z",
                  deep="M-34 -94 C -10 -90 12 -90 34 -96 L 34 -80 L -34 -80 Z",
                  hi="M-22 -126 C -18 -134 -8 -138 0 -138 C -8 -134 -14 -128 -16 -118 Z", w=W + 0.4))
    # visor slit + breaths
    p.append(part("M-22 -114 L 22 -114 C 23 -110 23 -108 22 -105 L -22 -105 C -23 -108 -23 -110 -22 -114 Z",
                  Pal("#1D1A2C", "#1D1A2C"), w=2.6))
    p.append('<circle cx="-9" cy="-109.5" r="2.4" fill="#FFE39A"/><circle cx="9" cy="-109.5" r="2.4" fill="#FFE39A"/>')
    p.append(line("M0 -104 L 0 -90", w=3))
    for y in (-98, -93):
        p.append(line(f"M-12 {y} L -6 {y} M 6 {y} L 12 {y}", w=2.2))
    # crest ridge + plume
    p.append(part("M-4 -138 L 4 -138 L 4 -108 L -4 -108 Z", GOLD, shade="M1 -140 L 6 -140 L 6 -104 L 1 -104 Z", w=2.6))
    plume = "M-2 -138 C -6 -156 6 -170 24 -166 C 18 -160 20 -152 26 -146 C 16 -148 12 -142 14 -134 C 8 -140 2 -140 -2 -138 Z"
    p.append(part(plume, RED, shade="M4 -150 C 12 -146 20 -146 30 -148 L 30 -130 L 4 -130 Z",
                  hi="M4 -156 C 8 -162 14 -165 20 -165 C 14 -162 10 -158 8 -152 Z", w=W))
    return "\n".join(p)


if __name__ == "__main__":
    open("sprites/knight.svg", "w").write(svg(360, 400, knight(), vb="-90 -180 180 200"))
