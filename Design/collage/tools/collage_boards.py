import os, re, json, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
PROJ = os.path.join(HERE, "..", "wordhop", "project")
C = os.path.join(PROJ, "collage")

INK = "#3B2A20"      # sepia ink
PAPER = "#FBF4E4"
PAPER_D = "#EFE3C8"
MUTED = "#9C8B78"
WASH = "#F7D774"
RED = "#B8423A"
SAGE = "#7E9A6A"
SKY = "#CFE4EE"

FONTS = ('<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Fraunces:opsz,wght@9..144,500;9..144,700&amp;'
         'family=Young+Serif&amp;family=Fredoka:wght@500;600&amp;display=swap">')

WORDS = ["The", "hare", "ran", "up", "the", "hill"]
SLOT = 124
MEADOW_W, MEADOW_H = Image.open(os.path.join(C, "meadow.jpg")).size
SIT_W, SIT_H = Image.open(os.path.join(C, "hare-sit.png")).size
BND_W, BND_H = Image.open(os.path.join(C, "hare-bound.png")).size


def deckle(n=48, amp=1.4, seed=3):
    import random
    r = random.Random(seed)
    pts = []
    for i in range(n + 1):
        pts.append(f"{i * 100 / n:.2f}% {r.uniform(0, amp):.2f}%")
    for i in range(n + 1):
        pts.append(f"{100 - r.uniform(0, amp * 0.6):.2f}% {i * 100 / n:.2f}%")
    for i in range(n + 1):
        pts.append(f"{100 - i * 100 / n:.2f}% {100 - r.uniform(0, amp):.2f}%")
    for i in range(n + 1):
        pts.append(f"{r.uniform(0, amp * 0.6):.2f}% {100 - i * 100 / n:.2f}%")
    return "polygon(" + ", ".join(pts) + ")"


PAPER_BG = (f"background-color: {PAPER}; background-image: radial-gradient(rgba(120,90,50,0.05) 1px, transparent 1.4px), "
            f"radial-gradient(rgba(120,90,50,0.04) 1px, transparent 1.6px); background-size: 7px 7px, 11px 11px; background-position: 0 0, 3px 5px;")


def sticker_box(inner, pad="8px 14px", radius=999, extra=""):
    return (f'<div style="display: inline-flex; align-items: center; gap: 8px; padding: {pad}; border-radius: {radius}px; {PAPER_BG} '
            f'border: 4px solid #FFFFFF; box-shadow: 0 3px 8px rgba(60,40,20,0.28); {extra}">{inner}</div>')


CSS = """
.cg-bg { transition: transform 0.8s cubic-bezier(0.4, 0, 0.2, 1); }
.cg-row { transition: transform 0.56s cubic-bezier(0.45, 0, 0.25, 1); }
.cg-word { transition: transform 0.5s cubic-bezier(0.45, 0, 0.25, 1), color 0.4s; }
.cg-wash { transition: opacity 0.35s 0.2s; }
.cg-breathe { animation: cgBreathe 2.6s ease-in-out infinite; transform-origin: 50% 100%; }
.cg-ears { animation: cgEars 5.2s ease-in-out infinite; transform-origin: 285px 208px; }
.cg-blink { animation: cgBlink 4.4s linear infinite; transform-origin: 50% 0%; }
.cg-land { animation: cgLand 0.32s cubic-bezier(0.3, 0, 0.3, 1.4) 1; transform-origin: 50% 100%; }
.cg-hop { animation: cgHop 0.56s cubic-bezier(0.35, 0, 0.35, 1) 1 both; transform-origin: 50% 80%; }
.cg-shadow-hop { animation: cgShadow 0.56s ease-in-out 1 both; }
.cg-bob { animation: cgBob 2.6s ease-in-out infinite; }
@keyframes cgBreathe { 0%, 100% { transform: scale(1, 1); } 50% { transform: scale(1.012, 0.986); } }
@keyframes cgEars { 0%, 64%, 100% { transform: rotate(0deg); } 67% { transform: rotate(-6deg); } 70% { transform: rotate(2.5deg); } 73% { transform: rotate(-1deg); } 76% { transform: rotate(0deg); } 88% { transform: rotate(-2deg); } 92% { transform: rotate(0deg); } }
@keyframes cgBlink { 0%, 90% { transform: scaleY(0); } 92% { transform: scaleY(1); } 95% { transform: scaleY(0); } }
@keyframes cgLand { 0% { transform: scale(1.08, 0.9); } 60% { transform: scale(0.97, 1.04); } 100% { transform: scale(1, 1); } }
@keyframes cgHop { 0% { transform: translate(0px, 10px) rotate(-10deg); } 40% { transform: translate(14px, -84px) rotate(-3deg); } 70% { transform: translate(10px, -46px) rotate(6deg); } 100% { transform: translate(0px, 6px) rotate(10deg); } }
@keyframes cgShadow { 0% { transform: scale(1); opacity: 0.35; } 40% { transform: scale(0.55); opacity: 0.14; } 100% { transform: scale(0.95); opacity: 0.32; } }
@keyframes cgBob { 0%, 100% { transform: translateY(0px); } 50% { transform: translateY(-3px); } }
@media (prefers-reduced-motion: reduce) { .cg-breathe, .cg-ears, .cg-blink, .cg-land, .cg-hop, .cg-shadow-hop, .cg-bob { animation: none; } .cg-bg, .cg-row, .cg-word { transition: none; } }
"""

# phone geometry
PW, PH = 390, 844
BG_S = PH / MEADOW_H
BG_X0 = -(800 * BG_S - 180)
CARD_X, CARD_Y, CARD_W, CARD_H = 14, 548, 362, 168
SIT_S = 176 / SIT_H
HARE_CX = 188
FEET_Y = CARD_Y + 14
BND_S = 0.205


def row_offset(pos):
    return CARD_W / 2 - (pos * SLOT + SLOT / 2)


def word_style(k, pos):
    if k == pos:
        return f"transform: scale(1); color: {INK};"
    if k < pos:
        return f"transform: scale(0.58); color: {INK};"
    return f"transform: scale(0.58); color: {MUTED};"


def hare_idle():
    w, h = SIT_W, SIT_H
    img = f'<img src="./collage/hare-sit.png" alt="" style="position: absolute; left: 0px; top: 0px; width: {w}px; height: {h}px; display: block;">'
    body = f'<div style="position: absolute; left: 0px; top: 0px; width: {w}px; height: {h}px; clip-path: inset(212px 0px 0px 0px);">{img}</div>'
    ears = f'<div class="cg-ears" style="position: absolute; left: 0px; top: 0px; width: {w}px; height: {h}px; clip-path: inset(0px 0px {h - 226}px 0px);">{img}</div>'
    lid = (f'<div class="cg-blink" style="position: absolute; left: 319px; top: 228px; width: 30px; height: 28px; border-radius: 50%; '
           f'background: #C99B63; box-shadow: inset 0 -3px 0 #6A4A30;"></div>')
    inner = f'<div class="cg-breathe" style="position: relative; width: {w}px; height: {h}px;">{body}{ears}{lid}</div>'
    left = HARE_CX - 232 * SIT_S
    top = FEET_Y - h * SIT_S
    return (f'<div class="cg-land" style="position: absolute; left: {left:.1f}px; top: {top:.1f}px; width: {w * SIT_S:.1f}px; height: {h * SIT_S:.1f}px;">'
            f'<div style="width: {w}px; height: {h}px; transform: scale({SIT_S:.4f}); transform-origin: 0 0;">{inner}</div></div>')


def hare_hop():
    w, h = BND_W * BND_S, BND_H * BND_S
    left = HARE_CX - 470 * BND_S
    top = FEET_Y - h + 8
    return (f'<div class="cg-hop" style="position: absolute; left: {left:.1f}px; top: {top:.1f}px; width: {w:.1f}px; height: {h:.1f}px;">'
            f'<img src="./collage/hare-bound.png" alt="" style="width: {w:.1f}px; height: {h:.1f}px; display: block;"></div>')


def shadow(cls):
    return (f'<div class="{cls}" style="position: absolute; left: {HARE_CX - 46}px; top: {FEET_Y - 9}px; width: 92px; height: 16px; border-radius: 50%; '
            f'background: radial-gradient(closest-side, rgba(70,50,30,0.5), rgba(70,50,30,0)); opacity: 0.35;"></div>')


def top_bar():
    back = sticker_box(f'<svg width="20" height="20" viewBox="0 0 24 24" aria-hidden="true"><path d="M15 5 L8 12 L15 19" stroke="{INK}" stroke-width="3" fill="none" stroke-linecap="round" stroke-linejoin="round"></path></svg>', "10px", 999)
    title = (f'<div style="padding: 8px 18px 9px; {PAPER_BG} clip-path: {deckle(24, 6, 5)}; transform: rotate(-2deg); '
             f'font-family: Fraunces, Georgia, serif; font-weight: 700; font-size: 18px; color: {INK}; filter: drop-shadow(0 2px 3px rgba(60,40,20,0.3));">The Meadow Walk</div>')
    star = sticker_box(f'<svg width="20" height="20" viewBox="0 0 24 24" aria-hidden="true"><path d="M12 2.5 l2.8 6 6.5 0.7 -4.9 4.4 1.4 6.4 -5.8 -3.3 -5.8 3.3 1.4 -6.4 -4.9 -4.4 6.5 -0.7 z" fill="{WASH}" stroke="#B8862E" stroke-width="1.4" stroke-linejoin="round"></path></svg>'
                       f'<span style="font-family: Fraunces, Georgia, serif; font-weight: 700; font-size: 17px; color: {INK};">{{{{stars}}}}</span>', "7px 14px 7px 10px")
    return (f'<div style="position: absolute; left: 16px; top: 54px; width: 358px; display: flex; align-items: center; justify-content: space-between;">'
            f'{back}<div style="filter: drop-shadow(0 0 0 transparent);">{title}</div>{star}</div>')


def card(words_html, row_style, dots_html):
    return (f'<div style="position: absolute; left: {CARD_X}px; top: {CARD_Y}px; width: {CARD_W}px; height: {CARD_H}px; filter: drop-shadow(0 5px 7px rgba(60,40,20,0.3));">'
            f'<div style="position: absolute; left: 0px; top: 0px; width: {CARD_W}px; height: {CARD_H}px; {PAPER_BG} clip-path: {deckle(40, 1.6, 9)};"></div>'
            f'<div style="position: absolute; left: 0px; top: 26px; width: {CARD_W}px; height: 90px; overflow: hidden;">'
            f'<div class="cg-row" style="position: absolute; left: 0px; top: 0px; height: 90px; display: flex; {row_style}">{words_html}</div></div>'
            f'<div style="position: absolute; left: 0px; top: 128px; width: {CARD_W}px; display: flex; justify-content: center; gap: 9px;">{dots_html}</div></div>')


def word_slot(text, style, wash_op):
    return (f'<div style="width: {SLOT}px; height: 90px; flex-shrink: 0; display: flex; align-items: center; justify-content: center;">'
            f'<div class="cg-word" style="position: relative; font-family: Young Serif, Georgia, serif; font-weight: 400; font-size: 54px; line-height: 1; {style}">'
            f'<span class="cg-wash" style="position: absolute; left: -12px; right: -12px; top: 8px; bottom: 2px; border-radius: 40% 55% 45% 60%; '
            f'background: radial-gradient(ellipse at 50% 55%, rgba(247,215,116,0.95) 0%, rgba(247,215,116,0.75) 55%, rgba(247,215,116,0) 72%); opacity: {wash_op};"></span>'
            f'<span style="position: relative;">{text}</span></div></div>')


def dot(state):
    fill = {"done": WASH, "now": "#FFFFFF", "todo": "rgba(156,139,120,0.25)"}[state]
    ring = "#B8862E" if state != "todo" else "rgba(156,139,120,0.45)"
    return f'<span style="width: 12px; height: 12px; border-radius: 50%; background: {fill}; border: 2px solid {ring}; box-sizing: border-box; display: block;"></span>'


def mic_button(onclick=True):
    icon = (f'<span style="width: 40px; height: 40px; border-radius: 50%; background: {SAGE}; display: flex; align-items: center; justify-content: center;">'
            f'<svg width="20" height="20" viewBox="0 0 24 24" aria-hidden="true"><rect x="9" y="3" width="6" height="11" rx="3" fill="#FFFFFF"></rect>'
            f'<path d="M6 11 a6 6 0 0 0 12 0 M12 17 v3" stroke="#FFFFFF" stroke-width="2.4" fill="none" stroke-linecap="round"></path></svg></span>')
    label = f'<span style="font-family: Fraunces, Georgia, serif; font-weight: 700; font-size: 19px; color: {INK};">{{{{micLabel}}}}</span>'
    return (f'<button type="button" onClick="{{{{say}}}}" aria-label="Say the word" style="position: absolute; left: 50%; top: 752px; transform: translateX(-50%); '
            f'display: flex; align-items: center; gap: 12px; white-space: nowrap; padding: 7px 22px 7px 8px; border-radius: 999px; {PAPER_BG} border: 5px solid #FFFFFF; '
            f'box-shadow: 0 4px 10px rgba(60,40,20,0.3); cursor: pointer;">{icon}{label}</button>')


def phone_template():
    bg = (f'<div class="cg-bg" style="position: absolute; left: 0px; top: 0px; width: {MEADOW_W * BG_S:.0f}px; height: {PH}px; {{{{bgStyle}}}}">'
          f'<img src="./collage/meadow.jpg" alt="" style="width: {MEADOW_W * BG_S:.0f}px; height: {PH}px; display: block;"></div>')
    words = (f'<sc-for list="{{{{words}}}}" as="w" hint-placeholder-count="6">'
             f'<div style="width: {SLOT}px; height: 90px; flex-shrink: 0; display: flex; align-items: center; justify-content: center;">'
             f'<div class="cg-word" style="{{{{w.style}}}}">'
             f'<span class="cg-wash" style="{{{{w.washStyle}}}}"></span><span style="position: relative;">{{{{w.text}}}}</span></div></div></sc-for>')
    dots = (f'<sc-for list="{{{{dots}}}}" as="d" hint-placeholder-count="6"><span style="{{{{d.style}}}}"></span></sc-for>')
    body = (bg + top_bar() + card(words, "{{rowStyle}}", dots)
            + f'<sc-if value="{{{{hopping}}}}" hint-placeholder-val="{{{{false}}}}">{shadow("cg-shadow-hop")}{hare_hop()}</sc-if>'
            + f'<sc-if value="{{{{idle}}}}" hint-placeholder-val="{{{{true}}}}">{shadow("")}{hare_idle()}</sc-if>'
            + f'<sc-if value="{{{{done}}}}" hint-placeholder-val="{{{{false}}}}"><div class="cg-bob" style="position: absolute; left: 0px; top: 470px; width: {PW}px; display: flex; justify-content: center;">'
            + sticker_box(f'<span style="font-family: Fraunces, Georgia, serif; font-weight: 700; font-size: 22px; color: {RED};">Well read!</span>', "8px 20px", 999, "transform: rotate(-3deg);")
            + '</div></sc-if>'
            + mic_button())
    return body


def word_style_full(k, pos):
    return (f"position: relative; font-family: Young Serif, Georgia, serif; font-weight: 400; font-size: 54px; line-height: 1; " + word_style(k, pos))


def wash_style(k, pos):
    return ("position: absolute; left: -12px; right: -12px; top: 8px; bottom: 2px; border-radius: 40% 55% 45% 60%; "
            "background: radial-gradient(ellipse at 50% 55%, rgba(247,215,116,0.95) 0%, rgba(247,215,116,0.75) 55%, rgba(247,215,116,0) 72%); "
            f"opacity: {1 if k < pos else 0};")


def dot_style(k, pos):
    st = "done" if k < pos else ("now" if k == pos else "todo")
    fill = {"done": WASH, "now": "#FFFFFF", "todo": "rgba(156,139,120,0.25)"}[st]
    ring = "#B8862E" if st != "todo" else "rgba(156,139,120,0.45)"
    return f"width: 12px; height: 12px; border-radius: 50%; background: {fill}; border: 2px solid {ring}; box-sizing: border-box; display: block;"


LOGIC = """
class Component extends DCLogic {
  constructor(props) {
    super(props);
    this.state = { pos: 0, hopping: false };
  }
  componentWillUnmount() { clearTimeout(this.t); }
  renderVals() {
    const WORDS = %(words)s;
    const pos = this.state.pos;
    const n = WORDS.length;
    const done = pos >= n;
    const say = () => {
      if (this.state.hopping) return;
      if (this.state.pos >= n) { this.setState({ pos: 0 }); return; }
      this.setState({ pos: this.state.pos + 1, hopping: true });
      clearTimeout(this.t);
      this.t = setTimeout(() => this.setState({ hopping: false }), 560);
    };
    const shown = Math.min(pos, n - 1);
    const rowX = %(half)s - (Math.min(pos, n) * %(slot)s + %(slot)s / 2);
    const words = WORDS.map((text, k) => ({
      text,
      style: "position: relative; font-family: Young Serif, Georgia, serif; font-weight: 400; font-size: 54px; line-height: 1; " +
        (k === pos ? "transform: scale(1); color: %(ink)s;" : (k < pos ? "transform: scale(0.58); color: %(ink)s;" : "transform: scale(0.58); color: %(muted)s;")),
      washStyle: "position: absolute; left: -12px; right: -12px; top: 8px; bottom: 2px; border-radius: 40%% 55%% 45%% 60%%; " +
        "background: radial-gradient(ellipse at 50%% 55%%, rgba(247,215,116,0.95) 0%%, rgba(247,215,116,0.75) 55%%, rgba(247,215,116,0) 72%%); opacity: " + (k < pos ? 1 : 0) + ";"
    }));
    const dots = WORDS.map((_, k) => {
      const st = k < pos ? "done" : (k === pos ? "now" : "todo");
      const fill = st === "done" ? "%(wash)s" : (st === "now" ? "#FFFFFF" : "rgba(156,139,120,0.25)");
      const ring = st === "todo" ? "rgba(156,139,120,0.45)" : "#B8862E";
      return { style: "width: 12px; height: 12px; border-radius: 50%%; background: " + fill + "; border: 2px solid " + ring + "; box-sizing: border-box; display: block;" };
    });
    return {
      words, dots, say,
      rowStyle: "transform: translateX(" + rowX + "px);",
      bgStyle: "transform: translateX(" + (%(bgx)s - pos * 34) + "px);",
      hopping: this.state.hopping,
      idle: !this.state.hopping,
      done: done && !this.state.hopping,
      stars: 12 + pos,
      micLabel: done ? "Read it again" : "Say the word",
    };
  }
}
"""


def dc_doc(title, w, h, body, bg, logic, extra_css=""):
    return (f'<!doctype html>\n<html lang="en">\n<head>\n<meta charset="utf-8">\n<title>{title}</title>\n<script src="./support.js"></script>\n</head>\n<body>\n<x-dc>\n<helmet>\n'
            f'{FONTS}\n<style>\nbody {{ margin: 0; background: {bg}; -webkit-font-smoothing: antialiased; }}\nbutton {{ font: inherit; }}\n{CSS}{extra_css}</style>\n</helmet>\n'
            f'<div style="position: relative; width: {w}px; height: {h}px; overflow: hidden; background: {bg};">\n{body}\n</div>\n</x-dc>\n'
            f'<script type="text/x-dc" data-dc-script data-props=\'{{"$preview":{{"width":{w},"height":{h}}}}}\'>\n{logic}\n</script>\n</body>\n</html>\n')


STATIC_LOGIC = "class Component extends DCLogic {\n  renderVals() {\n    return {};\n  }\n}"


def preview(name, w, h, body, bg):
    body = body.replace('src="./', f'src="file://{PROJ}/').replace("url(./", f"url(file://{PROJ}/")
    html = (f"<html><head><style>body{{margin:0;background:{bg}}}{CSS}</style></head><body>"
            f'<div style="position: relative; width:{w}px; height:{h}px; overflow:hidden; background:{bg}">{body}</div></body></html>')
    open(os.path.join(HERE, "out", name), "w").write(html)


def phone_static(pos=2, hopping=False):
    t = phone_template()
    words = "".join(f'<div style="width: {SLOT}px; height: 90px; flex-shrink: 0; display: flex; align-items: center; justify-content: center;">'
                    f'<div class="cg-word" style="{word_style_full(k, pos)}"><span class="cg-wash" style="{wash_style(k, pos)}"></span>'
                    f'<span style="position: relative;">{t_}</span></div></div>' for k, t_ in enumerate(WORDS))
    dots = "".join(f'<span style="{dot_style(k, pos)}"></span>' for k in range(len(WORDS)))
    t = re.sub(r'<sc-for list="\{\{words\}\}".*?</sc-for>', lambda m: words, t, flags=re.S)
    t = re.sub(r'<sc-for list="\{\{dots\}\}".*?</sc-for>', lambda m: dots, t, flags=re.S)
    t = t.replace("{{rowStyle}}", f"transform: translateX({row_offset(pos)}px);").replace("{{bgStyle}}", f"transform: translateX({BG_X0 - pos * 34}px);")
    t = t.replace("{{stars}}", str(12 + pos)).replace("{{micLabel}}", "Say the word").replace('onClick="{{say}}"', "")
    t = re.sub(r'<sc-if value="\{\{hopping\}\}"[^>]*>(.*?)</sc-if>', lambda m: m.group(1) if hopping else "", t, flags=re.S)
    t = re.sub(r'<sc-if value="\{\{idle\}\}"[^>]*>(.*?)</sc-if>', lambda m: "" if hopping else m.group(1), t, flags=re.S)
    t = re.sub(r'<sc-if value="\{\{done\}\}"[^>]*>(.*?)</sc-if>', "", t, flags=re.S)
    return t


def tv_body():
    W, H = 1920, 1080
    s = H / MEADOW_H
    bx = -(MEADOW_W * s - W) / 2
    b = [f'<img src="./collage/meadow.jpg" alt="" style="position: absolute; left: {bx:.0f}px; top: 0px; width: {MEADOW_W * s:.0f}px; height: {H}px;">']
    def prop(n, x, y, hgt, rot=0):
        im = Image.open(os.path.join(C, f"prop-{n}.png"))
        w = im.width * hgt / im.height
        return (f'<img src="./collage/prop-{n}.png" alt="" style="position: absolute; left: {x:.0f}px; top: {y - hgt:.0f}px; width: {w:.0f}px; height: {hgt}px; '
                f'transform: rotate({rot}deg); filter: drop-shadow(0 6px 8px rgba(60,40,20,0.3));">')
    # depth scale: things sitting higher on the ground (further away) are smaller
    b.append(prop("oak", -60, 860, 760, -1))
    b.append(prop("bush", 1150, 792, 150, 0))
    b.append(prop("fence", 1290, 800, 140, 1))
    b.append(prop("signpost", 1650, 770, 150, 2))
    b.append(prop("flowers", 1470, 1100, 210, -3))
    b.append(prop("mushrooms", 1700, 1100, 150, 2))
    hb = 0.46
    b.append(f'<img src="./collage/hare-bound.png" alt="" style="position: absolute; left: 700px; top: 470px; width: {BND_W * hb:.0f}px; height: {BND_H * hb:.0f}px; '
             f'transform: rotate(-4deg); filter: drop-shadow(0 10px 12px rgba(60,40,20,0.28));">')
    b.append(f'<div style="position: absolute; left: 800px; top: 840px; width: 260px; height: 30px; border-radius: 50%; background: radial-gradient(closest-side, rgba(70,50,30,0.35), rgba(70,50,30,0));"></div>')
    pos = 3
    cw, ch = 980, 210
    words = "".join(f'<div style="width: 190px; flex-shrink: 0; display: flex; justify-content: center;"><div style="position: relative; font-family: Young Serif, Georgia, serif; font-weight: 400; '
                    f'font-size: 96px; line-height: 1; transform: scale({1 if k == pos else 0.58}); color: {INK if k <= pos else MUTED};">'
                    f'<span style="{wash_style(k, pos)}"></span><span style="position: relative;">{t}</span></div></div>' for k, t in enumerate(WORDS))
    b.append(f'<div style="position: absolute; left: {(W - cw) / 2:.0f}px; top: 836px; width: {cw}px; height: {ch}px; filter: drop-shadow(0 8px 12px rgba(60,40,20,0.3));">'
             f'<div style="position: absolute; inset: 0; {PAPER_BG} clip-path: {deckle(60, 1.4, 11)};"></div>'
             f'<div style="position: absolute; left: 0px; top: 46px; width: {cw}px; height: 120px; overflow: hidden;"><div style="position: absolute; top: 0px; display: flex; '
             f'transform: translateX({cw / 2 - (pos * 190 + 95)}px);">{words}</div></div></div>')
    title = (f'<div style="position: absolute; left: 70px; top: 60px; padding: 12px 30px 14px; {PAPER_BG} clip-path: {deckle(24, 6, 5)}; transform: rotate(-2deg); '
             f'font-family: Fraunces, Georgia, serif; font-weight: 700; font-size: 34px; color: {INK};">The Meadow Walk</div>')
    b.append(f'<div style="filter: drop-shadow(0 3px 5px rgba(60,40,20,0.3));">{title}</div>')
    return "\n".join(b)


def kit_body():
    x0, cw = 64, 1472
    def lab(t, sub=""):
        return (f'<div style="display: flex; align-items: baseline; gap: 12px;"><div style="font-family: Fraunces, Georgia, serif; font-weight: 700; font-size: 20px; color: {INK};">{t}</div>'
                f'<div style="font-family: Fredoka, sans-serif; font-weight: 500; font-size: 15px; color: {MUTED};">{sub}</div></div>')
    def tile(src, w, h, bgc=SKY):
        return (f'<div style="width: {w}px; height: {h}px; border-radius: 18px; background: {bgc}; display: flex; align-items: center; justify-content: center; overflow: hidden;">'
                f'<img src="./collage/{src}" alt="" style="max-width: {w - 30}px; max-height: {h - 30}px; filter: drop-shadow(0 5px 7px rgba(60,40,20,0.28));"></div>')
    parts = [f'<div style="display: flex; align-items: baseline; gap: 16px;"><div style="font-family: Fraunces, Georgia, serif; font-weight: 700; font-size: 40px; color: {INK};">Collage storybook · concept kit</div>'
             f'<div style="font-family: Fredoka, sans-serif; font-size: 17px; color: {MUTED};">watercolour and ink cut-outs on a painted paper world · generated with Nano Banana 2</div></div>']
    parts.append(f'<div style="display: flex; flex-direction: column; gap: 10px;">{lab("The hare", "one establishing image, then poses generated from it so he stays on-model")}'
                 f'<div style="display: flex; gap: 20px;">{tile("hare-a.png", 400, 400)}{tile("hare-sit.png", 330, 400)}{tile("hare-bound.png", 702, 400)}</div></div>')
    props = "".join(tile(f"prop-{n}.png", 228, 228, "#E4EEDC") for n in ("oak", "bush", "flowers", "fence", "mushrooms", "signpost"))
    parts.append(f'<div style="display: flex; flex-direction: column; gap: 10px;">{lab("Props", "one sticker sheet, split into six cut-outs")}<div style="display: flex; gap: 20px;">{props}</div></div>')
    sw = [("Sepia ink", INK), ("Paper", PAPER), ("Paper shade", PAPER_D), ("Wash gold", WASH), ("Scarf red", RED), ("Sage", SAGE), ("Sky", SKY), ("Muted", MUTED)]
    sws = "".join(f'<div style="display: flex; flex-direction: column; gap: 6px; width: 120px;"><div style="height: 64px; border-radius: 14px; background: {c}; border: 4px solid #FFFFFF; box-shadow: 0 2px 6px rgba(60,40,20,0.25);"></div>'
                  f'<div style="font-family: Fredoka, sans-serif; font-weight: 600; font-size: 13px; color: {INK};">{n}</div><div style="font-family: Fredoka, sans-serif; font-size: 12px; color: {MUTED};">{c}</div></div>' for n, c in sw)
    type_ = (f'<div style="display: flex; flex-direction: column; gap: 10px;"><div style="font-family: Fraunces, Georgia, serif; font-weight: 700; font-size: 30px; color: {INK}; white-space: nowrap;">Fraunces · titles &amp; labels</div>'
             f'<div style="font-family: Young Serif, Georgia, serif; font-weight: 400; font-size: 30px; color: {INK}; white-space: nowrap;">Young Serif · the words he reads</div></div>')
    parts.append(f'<div style="display: flex; gap: 48px; align-items: flex-start;"><div style="display: flex; flex-direction: column; gap: 10px;">{lab("Palette")}<div style="display: flex; gap: 14px;">{sws}</div></div>'
                 f'<div style="display: flex; flex-direction: column; gap: 10px; flex: 1 1 0;">{lab("Type")}{type_}</div></div>')
    def note(t, x, fill=PAPER):
        return (f'<div style="flex: 1 1 0; min-width: 0; font-family: Fredoka, sans-serif; font-weight: 500; font-size: 15px; line-height: 1.5; color: {INK}; background: {fill}; '
                f'border: 5px solid #FFFFFF; border-radius: 20px; padding: 16px 18px; box-shadow: 0 3px 8px rgba(60,40,20,0.22);"><div style="font-family: Fraunces, Georgia, serif; font-weight: 700; font-size: 18px; margin-bottom: 6px;">{t}</div>{x}</div>')
    parts.append('<div style="display: flex; gap: 20px;">'
                 + note("The system", "Characters and props are cut-out stickers: watercolour with fine sepia ink, a thick white paper border and a soft shadow. The world behind is torn-paper collage. UI pieces (word card, labels, mic) are paper too, so everything feels like it came from the same book.")
                 + note("The hare is the ball", "He replaces the bouncing ball. While he waits he breathes, twitches his ears and blinks; when a word is heard he hops to the next one and the words slide under him. Try it on the phone artboard: tap Say the word.", "#EAF1E2")
                 + note("Spend so far", "Five images on Nano Banana 2 at 1K: the hare, two poses, the meadow and the prop sheet. Well under a dollar. Once the look is approved, the full suite is roughly 40 to 60 images: hop frames, idles, the castle and dragon chapters, golden-hour and dusk worlds.", "#FBEBD6")
                 + '</div>')
    return f'<div style="position: absolute; left: {x0}px; top: 56px; width: {cw}px; display: flex; flex-direction: column; gap: 34px;">' + "".join(parts) + "</div>"


if __name__ == "__main__":
    logic = LOGIC % dict(words=json.dumps(WORDS), half=CARD_W / 2, slot=SLOT, ink=INK, muted=MUTED, wash=WASH, bgx=round(BG_X0))
    open(os.path.join(PROJ, "CollagePhone.dc.html"), "w").write(dc_doc("Hop Tales · collage reading screen", PW, PH, phone_template(), "#DCEBF0", logic))
    preview("CollagePhone.html", PW, PH, phone_static(2), "#DCEBF0")
    preview("CollagePhoneHop.html", PW, PH, phone_static(3, True), "#DCEBF0")
    open(os.path.join(PROJ, "CollageTV.dc.html"), "w").write(dc_doc("Hop Tales · collage TV", 1920, 1080, tv_body(), "#DCEBF0", STATIC_LOGIC))
    preview("CollageTV.html", 1920, 1080, tv_body(), "#DCEBF0")
    open(os.path.join(PROJ, "CollageKit.dc.html"), "w").write(dc_doc("Hop Tales · collage concept kit", 1600, 1340, kit_body(), "#F4EBD8", STATIC_LOGIC))
    preview("CollageKit.html", 1600, 1340, kit_body(), "#F4EBD8")
    print("ok")
