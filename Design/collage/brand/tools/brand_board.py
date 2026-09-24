import os, sys, json
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from collage_boards import PROJ, INK, MUTED, PAPER, PAPER_BG, RED, dc_doc, preview, deckle
from PIL import Image

META = json.load(open(os.path.join(PROJ, "collage/world/meta.json")))
FS = Image.open(os.path.join(PROJ, "collage/brand/hare-front-sit.png")).size
FONT = ('<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Fraunces:opsz,wght@9..144,600;9..144,700&amp;'
        'family=Young+Serif&amp;family=Fredoka:wght@500;600&amp;display=swap">')
W, H = 390, 844
S = 0.42
TOPS = {"far": 430, "mid": 488, "near": 548}
OFF = {"far": 900, "mid": 1400, "near": 600}


def land(n):
    tw, th = META[n]["w"] * S, META[n]["h"] * S
    u = f"./collage/world/{n}-day.webp"
    return (f'<div class="ls-{n}" style="position: absolute; left: 0px; top: {TOPS[n]}px; width: {W}px; height: {th:.0f}px; background-image: url({u}); '
            f'background-size: {tw:.1f}px {th:.1f}px; background-position: -{OFF[n] * S:.0f}px 0px; background-repeat: repeat-x;"></div>')


def launch_scene(title=True):
    sky = ('<div style="position: absolute; inset: 0; background: linear-gradient(#1E2A4E, #3B4776 55%, #6E6D92);"></div>'
           '<div class="ls-dawn" style="position: absolute; inset: 0; background: linear-gradient(#8FA6CF, #E7B6A2 58%, #F6D6A6);"></div>'
           '<div class="ls-day" style="position: absolute; inset: 0; background: linear-gradient(#BCDCEE, #DCEBEF 60%, #EEF2E6);"></div>')
    stars = "".join(f'<img class="ls-stars" src="./collage/world/soft/star-{1 + i % 3}.png" alt="" style="position: absolute; left: {x}px; top: {y}px; width: {w}px;">'
                    for i, (x, y, w) in enumerate([(40, 90, 16), (110, 180, 11), (300, 70, 14), (250, 150, 10), (345, 230, 12), (70, 300, 9)]))
    glow = '<div class="ls-glow" style="position: absolute; left: 95px; top: 300px; width: 280px; height: 280px; border-radius: 50%; background: radial-gradient(closest-side, rgba(255,224,160,0.85), rgba(255,210,150,0.35) 55%, rgba(255,210,150,0));"></div>'
    sun = '<img class="ls-sun" src="./collage/world/soft/sun.png" alt="" style="position: absolute; left: 172px; top: 330px; width: 124px;">'
    clouds = ('<img class="ls-cloud1" src="./collage/world/soft/cloud-2.png" alt="" style="position: absolute; left: -30px; top: 250px; width: 130px;">'
              '<img class="ls-cloud2" src="./collage/world/soft/cloud-3.png" alt="" style="position: absolute; left: 280px; top: 180px; width: 110px;">')
    shade = ''
    hs = 132 / FS[1]
    hare = (f'<div class="ls-hare" style="position: absolute; left: {W / 2 - FS[0] * hs / 2:.0f}px; top: {TOPS["near"] + 430 * S - 124:.0f}px; width: {FS[0] * hs:.0f}px; height: 132px;">'
            f'<img src="./collage/brand/hare-front-sit.png" alt="The hare" style="width: 100%; height: 100%; display: block; filter: drop-shadow(0 4px 5px rgba(60,40,20,0.28));"></div>')
    t = ""
    if title:
        t = (f'<div class="ls-title" style="position: absolute; left: 0px; top: 118px; width: {W}px; display: flex; flex-direction: column; align-items: center; gap: 10px;">'
             f'<div style="filter: drop-shadow(0 3px 5px rgba(60,40,20,0.3));"><div style="padding: 12px 28px 16px; {PAPER_BG} clip-path: {deckle(28, 5, 4)}; transform: rotate(-2deg); '
             f'font-family: Fraunces, Georgia, serif; font-weight: 700; font-size: 46px; line-height: 1; color: {INK};">Hop Tales</div></div>'
             f'<div style="font-family: Young Serif, Georgia, serif; font-size: 17px; color: {INK}; opacity: 0.85;">a read-aloud adventure</div></div>')
    return sky + stars + glow + sun + clouds + land("far") + land("mid") + land("near") + shade + hare + t


CSS = """
.ls-dawn { animation: lsDawn 4.2s ease-in-out both; }
.ls-day { animation: lsDay 4.2s ease-in-out both; }
.ls-stars { animation: lsStars 4.2s ease-out both; }
.ls-sun { animation: lsSun 4.2s cubic-bezier(0.3, 0, 0.25, 1) both; }
.ls-glow { animation: lsGlow 4.2s ease-in-out both; }
.ls-shade { animation: lsShade 4.2s ease-in-out both; }
.ls-cloud1 { animation: lsCloud1 6s ease-out both; }
.ls-cloud2 { animation: lsCloud2 6s ease-out both; }
.ls-far { animation: lsRise 4s cubic-bezier(0.3, 0, 0.2, 1) both; }
.ls-mid { animation: lsRise 4s 0.12s cubic-bezier(0.3, 0, 0.2, 1) both; }
.ls-near { animation: lsRise 4s 0.24s cubic-bezier(0.3, 0, 0.2, 1) both; }
.ls-hare { animation: lsHare 0.7s 3.1s cubic-bezier(0.3, 1.4, 0.4, 1) both; transform-origin: 50% 100%; }
.ls-title { animation: lsTitle 0.9s 3.5s ease-out both; }
@keyframes lsDawn { 0% { opacity: 0; } 45% { opacity: 1; } 100% { opacity: 1; } }
@keyframes lsDay { 0%, 40% { opacity: 0; } 100% { opacity: 1; } }
@keyframes lsStars { 0% { opacity: 1; } 55% { opacity: 0; } 100% { opacity: 0; } }
@keyframes lsSun { 0% { transform: translateY(170px); } 100% { transform: translateY(-40px); } }
@keyframes lsGlow { 0% { opacity: 0; transform: translateY(170px) scale(0.8); } 50% { opacity: 1; } 100% { opacity: 0.5; transform: translateY(-40px) scale(1.1); } }
@keyframes lsShade { 0% { opacity: 0.72; } 100% { opacity: 0; } }
@keyframes lsCloud1 { 0% { transform: translateX(-24px); opacity: 0; } 30% { opacity: 1; } 100% { transform: translateX(10px); opacity: 1; } }
@keyframes lsCloud2 { 0% { transform: translateX(20px); opacity: 0; } 35% { opacity: 1; } 100% { transform: translateX(-6px); opacity: 1; } }
@keyframes lsRise { 0% { transform: translateY(26px); filter: brightness(0.42) saturate(0.55) hue-rotate(12deg); } 35% { filter: brightness(0.62) saturate(0.75) sepia(0.25); } 100% { transform: translateY(0px); filter: brightness(1) saturate(1); } }
@keyframes lsHare { 0% { opacity: 0; transform: translateY(18px) scale(0.9, 1.08); } 60% { opacity: 1; transform: translateY(-6px) scale(1.02, 0.98); } 100% { opacity: 1; transform: translateY(0px) scale(1, 1); } }
@keyframes lsTitle { 0% { opacity: 0; transform: translateY(10px); } 100% { opacity: 1; transform: translateY(0px); } }
@media (prefers-reduced-motion: reduce) { .ls-dawn, .ls-day, .ls-stars, .ls-sun, .ls-glow, .ls-shade, .ls-cloud1, .ls-cloud2, .ls-far, .ls-mid, .ls-near, .ls-hare, .ls-title { animation-duration: 0.01s; animation-delay: 0s; } }
"""

LOGIC = """
class Component extends DCLogic {
  constructor(props) { super(props); this.state = { k: 0 }; }
  renderVals() {
    const k = this.state.k;
    return { a: k % 2 === 0, b: k % 2 === 1, replay: () => this.setState({ k: k + 1 }) };
  }
}
"""


def launch_body():
    scene = launch_scene()
    btn = (f'<button type="button" onClick="{{{{replay}}}}" style="position: absolute; left: 50%; bottom: 34px; transform: translateX(-50%); white-space: nowrap; padding: 8px 18px; '
           f'border-radius: 999px; border: 4px solid #FFFFFF; {PAPER_BG} box-shadow: 0 3px 8px rgba(60,40,20,0.3); font-family: Fredoka, sans-serif; font-weight: 600; font-size: 15px; '
           f'color: {INK}; cursor: pointer;">Replay sunrise</button>')
    return (f'<sc-if value="{{{{a}}}}" hint-placeholder-val="{{{{true}}}}"><div style="position: absolute; inset: 0;">{scene}</div></sc-if>'
            f'<sc-if value="{{{{b}}}}" hint-placeholder-val="{{{{false}}}}"><div style="position: absolute; inset: 0;">{scene}</div></sc-if>{btn}')


def icons_body():
    def lab(t, sub):
        return (f'<div style="display: flex; flex-direction: column; gap: 3px;"><div style="font-family: Fraunces, serif; font-weight: 700; font-size: 19px; color: {INK};">{t}</div>'
                f'<div style="font-family: Fredoka, sans-serif; font-weight: 500; font-size: 14px; line-height: 1.4; color: {MUTED};">{sub}</div></div>')
    def icon(src, s):
        return (f'<img src="./collage/brand/{src}" alt="" style="width: {s}px; height: {s}px; border-radius: {s * 0.225:.0f}px; display: block; '
                f'box-shadow: 0 {max(2, s // 40)}px {max(4, s // 16)}px rgba(40,30,20,0.22);">')
    rows = [
        ("Your pick · mid-hop with a paper moon", [("icon-v.png", "V · Just the hop", "T without the moon: the hare leaping on plain sage paper"),
                     ("icon-t.png", "T · Moon behind", "the frame you picked, leaping across a large torn-paper crescent"),
                     ("icon-u.png", "U · Past the moon", "smaller crescent up and to the left, more open sage around him")]),
        ("Mid-hop", [("icon-q.png", "Q · Through the ring", "side-on leap through a cream stroke circle · nose and feet break out of it"),
                     ("icon-r.png", "R · Over the moon", "leaping over a cream crescent · most playful"),
                     ("icon-s.png", "S · Night hop", "deeper sage, crescent and paper stars · the bedtime-story version")]),
        ("Stroke circle", [("icon-j.png", "J · Brush ring", "hand-painted cream ring, ears break the top"),
                           ("icon-k.png", "K · Ink ring", "fine sepia pen line"),
                           ("icon-l.png", "L · Paper ring", "white paper ring with a soft shadow"),
                           ("icon-m.png", "M · Double ring", "cream ring with a thin scarf-red rule")]),
        ("Crescent moon", [("icon-n.png", "N · Moon cradle", "the portrait resting in a cream crescent"),
                           ("icon-o.png", "O · Moon outline", "the same crescent as a stroke only"),
                           ("icon-p.png", "P · Night portrait", "deeper sage, small crescent and stars")]),
    ]
    def card(src, t, sub):
        return (f'<div style="display: flex; flex-direction: column; gap: 14px; width: 340px;">'
                f'<div style="height: 230px; border-radius: 22px; background: #E9E1CF; display: flex; align-items: center; justify-content: center; gap: 22px;">'
                f'{icon(src, 170)}<div style="display: flex; flex-direction: column; gap: 16px; align-items: center;">{icon(src, 60)}{icon(src, 40)}</div></div>{lab(t, sub)}</div>')
    sections = "".join(f'<div style="display: flex; flex-direction: column; gap: 14px;"><div style="font-family: Fraunces, serif; font-weight: 700; font-size: 24px; color: {INK};">{name}</div>'
                       f'<div style="display: flex; gap: 42px;">{"".join(card(*o) for o in opts)}</div></div>' for name, opts in rows)
    head = (f'<div style="display: flex; align-items: baseline; gap: 16px;"><div style="font-family: Fraunces, serif; font-weight: 700; font-size: 36px; color: {INK};">App icon · sage</div>'
            f'<div style="font-family: Fredoka, sans-serif; font-size: 16px; color: {MUTED};">stroke circles, crescent moons and a side-on mid-hop · shown at 170, 60 and 40 pt</div></div>')
    return f'<div style="position: absolute; left: 56px; top: 44px; width: 1488px; display: flex; flex-direction: column; gap: 30px;">{head}{sections}</div>'


if __name__ == "__main__":
    doc = dc_doc("Hop Tales · launch sunrise", W, H, launch_body(), "#1E2A4E", LOGIC, CSS).replace(
        '<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Fraunces:opsz,wght@9..144,500;9..144,700&amp;family=Young+Serif&amp;family=Fredoka:wght@500;600&amp;display=swap">', FONT)
    open(os.path.join(PROJ, "CollageLaunch.dc.html"), "w").write(doc)
    icons = icons_body()
    open(os.path.join(PROJ, "CollageIcon.dc.html"), "w").write(dc_doc("Hop Tales · app icon options", 1600, 1590, icons, "#F4EBD8",
                                                                         "class Component extends DCLogic {\n  renderVals() {\n    return {};\n  }\n}"))
    preview("CollageIcon.html", 1600, 1590, icons, "#F4EBD8")
    # static previews of the launch at start / middle / end
    here = os.path.dirname(os.path.abspath(__file__))
    for name, delay in (("start", 0), ("mid", -1.9), ("end", -9)):
        css = CSS.replace("both;", f"both; animation-delay: {delay}s !important; animation-play-state: paused;")
        preview(f"Launch-{name}.html", W, H, launch_scene(), "#1E2A4E")
        q = os.path.join(here, "out", f"Launch-{name}.html")
        t = open(q).read().replace("</style>", css + "</style>", 1).replace("url(./collage", f"url(file://{PROJ}/collage")
        open(q, "w").write(t)
    print("ok")
