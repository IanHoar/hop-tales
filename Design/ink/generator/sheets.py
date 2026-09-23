"""Prop export and fox rig breakdown."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from ink import svg
import fox as F


def rig_svg():
    parts = [
        ("tail", F.tail(), (-40, -20), (-24, -54)),
        ("legs · far", F.leg(-20, -30, F.FUR_FAR, False) + F.leg(18, -30, F.FUR_FAR, False), (-80, 0), (-20, -28)),
        ("body", F.body(), (0, -30), (0, -40)),
        ("legs · near", F.leg(-12, -28, F.FUR) + F.leg(26, -28, F.FUR), (80, 0), (-12, -26)),
        ("scarf", F.scarf_tail(), (-50, -60), (10, -60)),
        ("head", F.head(), (60, -40), (18, -66)),
        ("wrap", F.wrap(), (46, -4), (26, -58)),
    ]
    out = []
    for name, g, (dx, dy), (px, py) in parts:
        out.append(f'<g transform="translate({dx} {dy})">{g}'
                   f'<circle cx="{px}" cy="{py}" r="4" fill="#fff" stroke="#E0302E" stroke-width="2.4"/>'
                   f'<circle cx="{px}" cy="{py}" r="1.3" fill="#E0302E"/></g>')
    return svg(620, 440, "\n".join(out), vb="-170 -230 340 240")


def export_props():
    import props as P
    t = P.TOD["day"]
    items = {
        "prop-tree": (P.tree_round(0, 0, 1, t), "-80 -160 160 170"),
        "prop-pine": (P.tree_pine(0, 0, 1, t), "-50 -140 100 150"),
        "prop-bush": (P.bush(0, 0, 1.3, t), "-60 -60 120 70"),
        "prop-rock": (P.rock(0, 0, 1.6, t), "-50 -50 100 60"),
        "prop-flowers": (P.flower(-14, 0, "#FFFFFF", t, 1.4) + P.flower(8, 0, "#FF8FB0", t, 1.2) + P.flower(26, 0, "#FFD23F", t, 1.3), "-40 -40 90 50"),
        "prop-fence": (P.fence(-40, 0, 4, t), "-56 -56 112 64"),
        "prop-sign": (P.signpost(0, 0, t), "-60 -80 120 90"),
        "prop-torch": (P.torch(0, 0, P.TOD["dusk"], True), "-40 -120 80 130"),
        "prop-castle": (P.castle(0, 0, 1, t), "-120 -280 240 290"),
        "prop-windmill": (P.windmill(0, 0, 1, t), "-80 -170 160 180"),
        "prop-ruin": (P.ruin(0, 0, 1, t), "-70 -200 140 210"),
        "prop-cloud": (P.cloud(0, 0, 1, t), "-90 -70 180 90"),
    }
    defs = ('<radialGradient id="torchGlow" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#FFC96B" stop-opacity="0.85"/>'
            '<stop offset="0.45" stop-color="#FFA24A" stop-opacity="0.3"/><stop offset="1" stop-color="#FFA24A" stop-opacity="0"/></radialGradient>')
    for k, (g, vb) in items.items():
        x, y, w, h = map(float, vb.split())
        open(f"sprites/{k}.svg", "w").write(svg(int(w * 2), int(h * 2), g, vb=vb, defs=defs))
    return items


