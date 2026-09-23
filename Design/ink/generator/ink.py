"""Tiny helper for building ink-outlined, cel-shaded SVG sprites.

Style rules (the Hop Tales "Ink & Ember" direction):
- one light, upper-left; shadows fall lower-right as hard-edged shapes
- every foreground form = base fill + clipped shadow + clipped highlight + ink outline
- outline weight carries depth: characters 5, foreground props 4, midground 3, far 0
"""
import itertools

INK = "#1D1A2C"

_ids = itertools.count()


def uid(prefix="c"):
    return f"{prefix}{next(_ids)}"


class Pal:
    def __init__(self, base, shade, hi=None, deep=None):
        self.base, self.shade, self.hi, self.deep = base, shade, hi, deep


def part(d, pal, shade=None, hi=None, deep=None, w=5, extra="", outline=True, transform=None, rim=None):
    """d: base path. shade/hi/deep: paths (or lists) clipped to base."""
    cid = uid()
    tf = f' transform="{transform}"' if transform else ""
    s = [f'<g{tf}>', f'<clipPath id="{cid}"><path d="{d}"/></clipPath>',
         f'<path d="{d}" fill="{pal.base}"/>']
    s.append(f'<g clip-path="url(#{cid})">')
    for p, col in ((shade, pal.shade), (deep, pal.deep), (hi, pal.hi)):
        if p is None or col is None:
            continue
        for pp in (p if isinstance(p, list) else [p]):
            s.append(f'<path d="{pp}" fill="{col}"/>')
    if rim:
        s.append(rim)
    s.append(extra)
    s.append('</g>')
    if outline and w:
        s.append(f'<path d="{d}" fill="none" stroke="{INK}" stroke-width="{w}" stroke-linejoin="round" stroke-linecap="round"/>')
    s.append('</g>')
    return "\n".join(s)


def line(d, w=4, col=INK, extra=""):
    return f'<path d="{d}" fill="none" stroke="{col}" stroke-width="{w}" stroke-linecap="round" stroke-linejoin="round" {extra}/>'


def blob(d, col, extra=""):
    return f'<path d="{d}" fill="{col}" {extra}/>'


def svg(w, h, body, vb=None, defs=""):
    vb = vb or f"0 0 {w} {h}"
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="{vb}">'
            f'<defs>{defs}</defs>{body}</svg>')


def ground_shadow(cx, cy, rx, ry, op=0.28):
    return f'<ellipse cx="{cx}" cy="{cy}" rx="{rx}" ry="{ry}" fill="{INK}" opacity="{op}"/>'
