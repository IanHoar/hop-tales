from ink import *

FUR = Pal("#F27B2B", "#C8521D", "#FFAA5E")
FUR_FAR = Pal("#CF5A20", "#A64316")
CREAM = Pal("#FFF4E0", "#EACFA8", "#FFFFFF")
SOCK = Pal("#3B2A33", "#231820", "#5E4652")
SCARF = Pal("#DB2A2E", "#A3141D", "#FF6A55")
GOLD = Pal("#F6BB3E", "#C7861A", "#FFE39A")
W = 3.6


def leg(x, top, pal, near=True, rot=0):
    # tapered leg, dark sock, rounded paw
    d = (f"M{x-6} {top} C {x-6} {top+10} {x-5} {-14} {x-6} {-6} "
         f"C {x-7} {-1} {x-4} 0 {x+1} 0 L {x+6} 0 C {x+10} 0 {x+10} {-4} {x+8} {-7} "
         f"C {x+6} {-14} {x+6} {top+10} {x+6} {top} Z")
    sock = f'<path d="M{x-12} -15 C {x-4} -17 {x+4} -17 {x+14} -15 L{x+14} 4 L{x-12} 4 Z" fill="{SOCK.base}"/>'
    sock_sh = f'<path d="M{x+2} -17 L{x+14} -17 L{x+14} 4 L{x+2} 4 Z" fill="{SOCK.shade}"/>'
    toe = f'<path d="M{x-4} -3 C {x-2} -5 {x+2} -5 {x+3} -3" stroke="{SOCK.hi}" stroke-width="1.6" fill="none" stroke-linecap="round"/>' if near else ""
    return part(d, pal, shade=f"M{x+1} {top-4} L{x+14} {top-4} L{x+14} 4 L{x+1} 4 Z", w=W, extra=sock + sock_sh + toe,
                transform=f"rotate({rot} {x} {top+2})" if rot else None)


def tail(angle=0):
    d = ("M-26 -46 C -52 -40 -82 -50 -96 -78 C -106 -100 -98 -124 -80 -130 "
         "C -76 -114 -72 -98 -62 -86 C -52 -74 -38 -64 -22 -62 Z")
    tip = "M-130 -150 L -50 -150 L -58 -108 C -70 -102 -86 -98 -102 -98 L -130 -94 Z"
    return part(d, FUR,
                shade="M-30 -50 C -56 -46 -84 -56 -100 -82 L -120 -40 L -20 -20 Z",
                hi="M-90 -116 C -92 -100 -88 -86 -76 -76 C -86 -90 -90 -102 -88 -114 Z",
                extra=f'<path d="{tip}" fill="{CREAM.base}"/>'
                      f'<path d="M-130 -94 L -102 -98 C -96 -98 -92 -100 -90 -102 L -130 -80 Z" fill="{CREAM.shade}"/>'
                      f'<path d="M-92 -124 C -94 -114 -92 -106 -88 -102 C -90 -110 -90 -118 -88 -126 Z" fill="#fff"/>',
                w=W, transform=f"rotate({angle} -24 -54)")


def body():
    d = "M-34 -40 C -38 -58 -16 -66 6 -63 C 28 -60 38 -48 33 -32 C 28 -19 -28 -18 -34 -40 Z"
    return part(d, FUR,
                shade="M-40 -33 C -16 -30 12 -30 40 -38 L 44 -8 L -44 -8 Z",
                hi="M-24 -56 C -12 -62 4 -62 14 -59 C 2 -57 -12 -55 -24 -50 Z",
                extra=f'<path d="M-20 -22 C -6 -32 16 -32 30 -26 C 22 -16 -12 -14 -20 -22 Z" fill="{CREAM.base}"/>'
                      f'<path d="M-20 -22 C -4 -24 16 -24 30 -26 C 22 -16 -12 -14 -20 -22 Z" fill="{CREAM.shade}"/>',
                w=W)


def scarf_tail(flap=0):
    d = (f"M12 -64 C 0 -68 -12 -{76+flap} -28 -{74+flap} C -24 -{68+flap/2} -18 -66 -12 -63 "
         f"C -22 -61 -30 -{56+flap/2} -36 -{48+flap/2} C -20 -50 -4 -55 10 -57 Z")
    return part(d, SCARF, shade="M-40 -60 L 20 -60 L 20 -40 L -40 -40 Z",
                hi=f"M-24 -{74+flap} C -14 -{74+flap} -4 -71 6 -67 C -6 -69 -14 -71 -24 -{71+flap} Z", w=W - 0.4)


def head(expr="idle"):
    h = []
    ear_far = "M22 -104 C 20 -118 22 -130 28 -140 C 38 -130 44 -120 46 -110 Z"
    h.append(part(ear_far, FUR_FAR, w=W,
                  extra=f'<path d="M14 -126 C 20 -134 24 -140 28 -146 C 34 -140 38 -134 40 -128 Z" fill="{SOCK.base}"/>'))
    skull = ("M14 -84 C 10 -108 34 -120 54 -112 C 66 -106 70 -96 80 -90 C 88 -86 92 -80 86 -75 "
             "C 76 -68 62 -64 48 -61 C 30 -58 16 -66 14 -84 Z")
    h.append(part(skull, FUR,
                  shade="M18 -64 C 40 -66 66 -70 96 -78 L 96 -50 L 8 -50 Z",
                  hi="M24 -104 C 32 -114 46 -116 54 -110 C 44 -109 34 -104 28 -96 Z",
                  extra=(f'<path d="M46 -80 C 58 -80 72 -84 92 -84 L 92 -60 C 74 -58 54 -56 40 -62 Z" fill="{CREAM.base}"/>'
                         f'<path d="M44 -67 C 60 -65 78 -69 92 -73 L 92 -58 L 42 -58 Z" fill="{CREAM.shade}"/>'
                         f'<path d="M10 -82 C 18 -74 24 -66 36 -61 C 24 -60 14 -66 10 -74 Z" fill="{CREAM.base}"/>'),
                  w=W))
    ear_near = "M34 -104 C 32 -120 34 -132 40 -144 C 52 -134 60 -122 62 -110 Z"
    h.append(part(ear_near, FUR, shade="M48 -146 L 72 -146 L 72 -96 L 50 -104 Z", w=W,
                  extra=(f'<path d="M40 -108 C 40 -118 41 -126 44 -132 C 50 -124 53 -118 54 -110 Z" fill="{CREAM.shade}"/>'
                         f'<path d="M26 -128 C 32 -136 36 -142 40 -150 C 48 -142 52 -136 54 -130 Z" fill="{SOCK.base}"/>')))
    h.append(part("M79 -89 C 84 -93 92 -92 93 -86 C 94 -80 86 -79 82 -81 C 78 -83 77 -87 79 -89 Z",
                  SOCK, hi="M83 -90 C 86 -92 89 -91 90 -89 C 87 -89 85 -89 83 -88 Z", w=2.6))
    if expr == "happy":
        h.append(line("M48 -94 Q 55 -103 62 -94", w=4))
        h.append(line("M74 -76 Q 66 -64 56 -71", w=3))
        h.append('<path d="M60 -71 Q 66 -66 72 -73 Q 66 -69 60 -71 Z" fill="#E4574F"/>')
    else:
        h.append(part("M48 -94 C 48 -105 62 -105 62 -94 C 62 -84 48 -84 48 -94 Z", SOCK, w=2.6,
                      extra='<circle cx="57.5" cy="-98" r="3.4" fill="#fff"/><circle cx="52.5" cy="-89.5" r="1.6" fill="#fff"/>'))
        h.append(line("M73 -75 Q 67 -71 61 -73", w=2.8))
    h.append(line("M46 -106 Q 54 -110 62 -107", w=3))
    h.append('<ellipse cx="42" cy="-80" rx="6.5" ry="3.8" fill="#FF6F6F" opacity="0.5"/>')
    return "<g>" + "\n".join(h) + "</g>"


def wrap():
    d = "M8 -72 C 16 -60 34 -56 50 -62 C 53 -56 51 -50 46 -48 C 30 -43 12 -47 3 -60 Z"
    return part(d, SCARF, shade="M0 -54 C 16 -50 34 -48 56 -54 L 56 -40 L 0 -40 Z",
                hi="M14 -66 C 24 -60 36 -58 46 -60 C 36 -56 24 -58 14 -62 Z", w=W - 0.4,
                extra=f'<circle cx="46" cy="-56" r="4.2" fill="{GOLD.base}"/><circle cx="44.8" cy="-57.6" r="1.7" fill="{GOLD.hi}"/>')


def fox(expr="idle", legs=(0, 0, 0, 0), tail_a=0, bob=0, flap=0, shadow=True):
    a, b, c, d = legs
    up = [tail(tail_a), leg(-20, -30, FUR_FAR, False, a), leg(18, -30, FUR_FAR, False, b),
          body(), leg(-12, -28, FUR, True, c), leg(26, -28, FUR, True, d), scarf_tail(flap), head(expr), wrap()]
    sh = ground_shadow(2, 1, 50 - abs(bob) * 0.8, 6, 0.3) if shadow else ""
    return sh + f'<g transform="translate(0 {bob})">' + "\n".join(up) + "</g>"


def frames():
    trot = [((18, -14, -18, 14), 4, -1, 2), ((6, -4, -6, 4), -2, -3, 4), ((-14, 18, 14, -18), -4, -1, 6), ((-4, 6, 4, -6), 2, -3, 3)]
    out = {}
    for i, (lg, ta, bob, fl) in enumerate(trot):
        out[f"fox-trot-{i}"] = fox("idle", lg, ta, bob, fl)
    out["fox-jump"] = fox("happy", (-24, 20, -28, 24), -10, -22, 8)
    out["fox-sit"] = fox("happy", (0, 0, 0, 0), 8, 0, 0)
    return out


if __name__ == "__main__":
    open("sprites/fox.svg", "w").write(svg(480, 340, fox(), vb="-120 -160 240 170"))
    open("sprites/fox-happy.svg", "w").write(svg(480, 340, fox("happy"), vb="-120 -160 240 170"))
    for k, v in frames().items():
        open(f"sprites/{k}.svg", "w").write(svg(480, 340, v, vb="-120 -160 240 170"))
