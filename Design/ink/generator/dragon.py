from ink import *
from knight import star

SCALE = Pal("#7C52C4", "#553A9E", "#A884EE", "#3C2878")
SCALE_FAR = Pal("#5C3DA0", "#432C7E")
BELLY = Pal("#F7C65C", "#D0922E", "#FFE59C")
HORN = Pal("#FFF0CF", "#D8C096", "#FFFFFF")
MEM = Pal("#9D74E4", "#7550C4", "#C3A6F6")
MEM_FAR = Pal("#6E4BB8", "#523596")
GOLD = Pal("#F6BB3E", "#C7861A", "#FFE39A")
GEM = Pal("#E23A4A", "#A01A2A", "#FF9AA0")
W = 4


def wing(x0, y0, pal, arm, far=False):
    # raised bat wing: arm bone to wrist, three finger spars, scalloped membrane
    wx, wy = x0 + 50, y0 - 80
    tips = [(x0 + 118, y0 - 58), (x0 + 106, y0 - 12), (x0 + 70, y0 + 14)]
    d = (f"M{x0} {y0} L {wx} {wy} C {wx+26} {wy-6} {tips[0][0]-10} {tips[0][1]-18} {tips[0][0]} {tips[0][1]} "
         f"C {tips[0][0]-18} {tips[0][1]+10} {tips[1][0]-6} {tips[1][1]-14} {tips[1][0]} {tips[1][1]} "
         f"C {tips[1][0]-18} {tips[1][1]+4} {tips[2][0]-2} {tips[2][1]-12} {tips[2][0]} {tips[2][1]} "
         f"C {tips[2][0]-24} {tips[2][1]-6} {x0+12} {y0+10} {x0} {y0} Z")
    shade = f"M{wx} {wy} L {tips[0][0]} {tips[0][1]} L {tips[1][0]} {tips[1][1]} L {tips[2][0]} {tips[2][1]} L {x0+30} {y0} Z"
    bones = "".join(line(f"M{wx} {wy} L {tx} {ty}", w=3 if far else 3.4, col=arm.shade) for tx, ty in tips)
    s = part(d, pal, shade=shade if not far else None, hi=f"M{x0} {y0} L {wx} {wy} L {wx+30} {wy+30} Z" if not far else None,
             w=W - 0.6, extra=bones)
    s += line(f"M{x0} {y0} L {wx} {wy}", w=9, col=INK) + line(f"M{x0} {y0} L {wx} {wy}", w=5, col=arm.base)
    s += part(f"M{wx-6} {wy} L {wx} {wy-14} L {wx+5} {wy} Z", HORN, w=2.4)
    return s


def dragon(expr="idle", wing_a=0):
    p = [ground_shadow(0, 1, 120, 9, 0.32)]
    p.append(f"<g transform=\"translate(-34 -18) rotate(-12 -4 -128)\">" + wing(-4, -128, MEM_FAR, SCALE_FAR, far=True) + "</g>")
    # tail along the ground, curling up into a spade
    tail = ("M36 -30 C 70 -10 110 -4 132 -20 C 146 -30 150 -48 142 -60 C 138 -48 130 -40 118 -36 "
            "C 96 -28 66 -34 44 -52 Z")
    p.append(part(tail, SCALE, shade="M30 -36 C 70 -20 110 -16 150 -34 L 150 10 L 30 10 Z",
                  hi="M60 -30 C 80 -24 104 -24 120 -30 C 104 -28 80 -28 60 -32 Z", w=W))
    p.append(part("M136 -62 C 132 -80 140 -94 154 -98 C 152 -86 160 -78 170 -76 C 160 -66 148 -60 136 -62 Z",
                  BELLY, shade="M140 -64 C 150 -70 160 -74 172 -76 L 172 -56 L 136 -56 Z", w=3.4))
    for x, y in ((72, -26), (98, -24), (120, -30)):
        p.append(part(f"M{x-6} {y-6} L {x} {y-18} L {x+6} {y-6} Z", BELLY, w=2.6))
    # body (pear, sitting)
    body = ("M-40 -24 C -62 -62 -54 -118 -16 -130 C 24 -140 60 -104 60 -64 C 60 -32 44 -8 12 -4 "
            "C -14 -2 -32 -10 -40 -24 Z")
    p.append(part(body, SCALE,
                  shade="M14 -140 C 50 -126 70 -90 64 -40 C 58 0 20 6 0 6 L 80 10 L 80 -150 Z",
                  hi="M-26 -120 C -14 -130 4 -132 16 -128 C 2 -124 -12 -118 -20 -106 Z", w=W,
                  extra="".join(f'<path d="M{x} {y} q7 -7 14 0" stroke="{SCALE.shade}" stroke-width="2.4" fill="none" stroke-linecap="round"/>'
                                for x, y in ((0, -100), (16, -96), (8, -84), (24, -80), (30, -64), (14, -66)))))
    # belly plates
    belly = ("M-44 -26 C -60 -62 -52 -104 -30 -122 C -18 -106 -18 -60 -6 -6 C -22 -6 -36 -12 -44 -26 Z")
    p.append(part(belly, BELLY, shade="M-20 -130 C -14 -80 -12 -40 -4 0 L 20 0 L 20 -130 Z",
                  hi="M-40 -60 C -42 -80 -38 -100 -30 -112 C -34 -96 -36 -80 -36 -62 Z", w=W - 0.8,
                  extra="".join(line(f"M{-58+i*2} {y} C {-40} {y+4} {-24} {y+4} {-10} {y+2}", w=2.2, col=BELLY.shade)
                                for i, y in enumerate((-104, -86, -68, -50, -32)))))
    # hind leg haunch + foot
    p.append(part("M4 -60 C 22 -76 58 -70 62 -40 C 64 -18 50 -8 32 -8 C 14 -8 -2 -24 4 -60 Z", SCALE,
                  shade="M30 -80 C 60 -70 70 -40 60 -10 L 70 0 L 70 -80 Z",
                  hi="M10 -62 C 20 -70 34 -72 44 -68 C 32 -66 20 -62 14 -54 Z", w=W))
    p.append(part("M-6 -14 C 10 -18 34 -16 44 -12 C 50 -10 50 0 44 0 L -8 0 C -14 0 -14 -12 -6 -14 Z", SCALE,
                  shade="M10 -6 L 60 -6 L 60 4 L 10 4 Z", w=W))
    for x in (-10, 0, 10):
        p.append(part(f"M{x-4} -6 L {x-12} 0 L {x+2} 0 Z", HORN, w=2.4))
    # neck
    neck = "M-34 -108 C -44 -138 -46 -158 -54 -172 L -20 -186 C -12 -164 -2 -140 8 -118 Z"
    p.append(part(neck, SCALE, shade="M-10 -190 C -4 -160 6 -136 14 -114 L 30 -114 L 30 -190 Z",
                  hi="M-44 -150 C -46 -160 -48 -166 -52 -172 L -44 -176 C -42 -168 -40 -160 -40 -150 Z", w=W))
    p.append(part("M-40 -110 C -48 -136 -52 -156 -58 -168 L -46 -172 C -42 -156 -38 -138 -28 -116 Z", BELLY,
                  shade="M-36 -172 L -20 -172 L -20 -110 L -36 -110 Z", w=3))
    for x, y in ((-10, -176), (-2, -156), (6, -136)):
        p.append(part(f"M{x} {y} L {x+14} {y-4} L {x+4} {y+8} Z", BELLY, w=2.6))
    # front arm resting on the hoard
    p.append(part("M-30 -96 C -46 -92 -60 -76 -70 -58 C -74 -50 -66 -44 -58 -48 C -48 -62 -36 -72 -22 -78 Z", SCALE,
                  shade="M-60 -40 C -48 -58 -36 -68 -18 -74 L -10 -40 Z",
                  hi="M-34 -92 C -44 -88 -52 -80 -58 -72 C -52 -78 -44 -84 -34 -88 Z", w=W))
    # the hoard
    hoard = "M-134 0 C -132 -26 -104 -46 -76 -46 C -52 -46 -30 -28 -22 0 Z"
    coins = "".join(f'<ellipse cx="{x}" cy="{y}" rx="7" ry="4" fill="{GOLD.hi}" stroke="{GOLD.shade}" stroke-width="1.8"/>'
                    for x, y in ((-110, -18), (-92, -30), (-70, -36), (-56, -22), (-84, -12), (-44, -10), (-120, -6), (-100, -4)))
    p.append(part(hoard, GOLD, shade="M-80 -50 C -56 -46 -36 -30 -22 4 L -20 4 L -20 -50 Z",
                  hi="M-118 -18 C -110 -32 -96 -40 -84 -42 C -96 -36 -106 -28 -112 -16 Z", w=W, extra=coins))
    p.append(part("M-58 -48 C -58 -56 -50 -56 -48 -52 C -46 -48 -50 -44 -54 -44 C -58 -44 -60 -46 -58 -48 Z", GOLD, w=2.4))
    for x, y in ((-68, -52), (-58, -54), (-50, -52)):
        p.append(part(f"M{x-4} {y} L {x} {y-8} L {x+4} {y} Z", HORN, w=2.2))
    p.append(part("M-100 -44 L -90 -56 L -80 -44 L -90 -34 Z", GEM, hi="M-96 -46 L -90 -54 L -88 -48 Z", w=2.8))
    p.append(part("M-126 -2 L -126 -24 L -106 -24 L -106 -2 Z", Pal("#A36A3E", "#734526", "#C98C58"),
                  shade="M-116 -30 L -100 -30 L -100 4 L -116 4 Z", w=3,
                  extra=f'<rect x="-128" y="-16" width="24" height="4" fill="{GOLD.base}"/>'))
    p.append(star(-72, -64, 6, "#FFF6C8"))
    p.append(star(-112, -46, 4, "#FFF6C8"))
    # head
    horn_far = "M-36 -208 C -28 -224 -14 -232 4 -232 C -10 -224 -18 -214 -22 -202 Z"
    p.append(part(horn_far, Pal("#D8C096", "#B09A70"), w=3.4))
    headd = ("M-20 -190 C -16 -214 -48 -226 -70 -212 C -84 -204 -98 -202 -114 -196 C -128 -190 -130 -172 -116 -166 "
             "C -100 -160 -84 -162 -70 -158 C -44 -150 -24 -164 -20 -190 Z")
    p.append(part(headd, SCALE,
                  shade="M-130 -170 C -100 -164 -70 -160 -40 -162 C -24 -166 -16 -176 -14 -190 L -10 -140 L -130 -140 Z",
                  hi="M-66 -212 C -52 -220 -36 -218 -28 -208 C -38 -212 -50 -212 -62 -206 Z", w=W + 0.4))
    # jaw underside + mouth
    p.append(part("M-120 -172 C -104 -168 -86 -168 -70 -162 C -84 -156 -104 -158 -116 -164 Z", BELLY, w=2.6))
    if expr == "roar":
        p.append(part("M-124 -178 C -108 -176 -90 -174 -76 -170 C -90 -156 -112 -154 -124 -166 Z", Pal("#6A1A2A", "#4A1020"), w=3))
    else:
        p.append(line("M-122 -176 C -110 -172 -94 -172 -82 -174", w=3.2))
        p.append(part("M-96 -174 L -93 -166 L -90 -174 Z", HORN, w=2))
    p.append(part("M-112 -196 C -110 -200 -104 -200 -104 -196 C -104 -192 -110 -192 -112 -196 Z", Pal(INK, INK), w=1.5))
    # eye
    p.append(part("M-78 -196 C -78 -210 -58 -210 -58 -196 C -58 -184 -78 -184 -78 -196 Z", Pal("#FFFDF4", "#E8E0D0"),
                  shade="M-80 -190 C -72 -186 -64 -186 -56 -190 L -56 -180 L -80 -180 Z", w=3,
                  extra='<ellipse cx="-71" cy="-196" rx="5.5" ry="7.5" fill="#1D1A2C"/><circle cx="-69" cy="-200" r="2.4" fill="#fff"/>'))
    p.append(line("M-84 -210 C -76 -216 -64 -216 -56 -210", w=4))
    p.append('<ellipse cx="-86" cy="-178" rx="7" ry="3.6" fill="#FF7A9A" opacity="0.5"/>')
    horn = "M-44 -212 C -36 -232 -18 -242 4 -242 C -12 -232 -22 -220 -28 -204 Z"
    p.append(part(horn, HORN, shade="M-36 -212 C -24 -222 -8 -232 8 -238 L 10 -200 L -30 -200 Z",
                  hi="M-40 -214 C -34 -226 -24 -234 -12 -238 C -22 -230 -30 -222 -36 -212 Z", w=3.4))
    p.append(part("M-26 -196 L -8 -206 L -14 -190 Z", BELLY, w=2.6))
    # near wing, raised
    p.append(f'<g transform="rotate({wing_a} 8 -122)">' + wing(8, -122, MEM, SCALE) + "</g>")
    return "\n".join(p)


if __name__ == "__main__":
    open("sprites/dragon.svg", "w").write(svg(640, 560, dragon(), vb="-150 -260 320 280"))
    open("sprites/dragon-flap-up.svg", "w").write(svg(640, 560, dragon("idle", -16), vb="-150 -260 320 280"))
    open("sprites/dragon-flap-down.svg", "w").write(svg(640, 560, dragon("roar", 22), vb="-150 -260 320 280"))
