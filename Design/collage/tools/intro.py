"""Launch image + intro sequence (sunrise -> hare turns and runs off -> home or onboarding)."""
import os, sys, json
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from collage_boards import INK, MUTED, PAPER, PAPER_BG, RED, SAGE, WASH, deckle, dc_doc
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
P = os.path.join(HERE, "..", "collage-canvas", "project")
META = json.load(open(os.path.join(HERE, "..", "wordhop", "project", "collage", "world", "meta.json")))
FONT = ('<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Fraunces:opsz,wght@9..144,600;9..144,700&amp;'
        'family=Young+Serif&amp;family=Fredoka:wght@500;600&amp;display=swap">')
CREAM = "#F4EBD8"


def dims(p):
    return Image.open(os.path.join(P, p)).size


FS = dims("collage/brand/hare-front-sit.png")
SS = dims("collage/hare-sit.png")
HOP = json.load(open(os.path.join(HERE, "..", "wordhop", "project", "collage", "sprites", "sprites.json")))["hop"]["frame"]

# timeline (s)
T_SUN0, T_SUN = 0.6, 4.0          # sunrise starts / lasts
T_HARE = 3.9                       # hare pops in facing us
T_TITLE = 4.2
T_TURN = 5.6                       # turns side-on
T_RUN, D_RUN = 6.0, 1.15           # runs off to the right
T_UI = 6.7                         # interface rises in


def S_for(W, H):
    return 0.42 * max(1.0, min(W, H) / 390 * 0.62)


def scene(W, H, anim=True, title=True, hare=True):
    S = S_for(W, H)
    k = S / 0.42
    tops = {"far": H - 986 * S, "mid": H - 848 * S, "near": H - 705 * S}
    offs = {"far": 900, "mid": 1400, "near": 600}
    a = (lambda c: f'class="{c}" ') if anim else (lambda c: f'class="{c}-still" ')
    out = ['<div style="position: absolute; inset: 0; background: linear-gradient(#1E2A4E, #3B4776 55%, #6E6D92);"></div>',
           f'<div {a("it-dawn")}style="position: absolute; inset: 0; background: linear-gradient(#8FA6CF, #E7B6A2 58%, #F6D6A6); opacity: 0;"></div>',
           f'<div {a("it-day")}style="position: absolute; inset: 0; background: linear-gradient(#BCDCEE, #DCEBEF 60%, #EEF2E6); opacity: 0;"></div>']
    for i, (fx, fy, w) in enumerate([(0.10, 0.11, 16), (0.28, 0.21, 11), (0.77, 0.08, 14), (0.64, 0.18, 10), (0.88, 0.27, 12), (0.18, 0.35, 9), (0.47, 0.06, 10), (0.55, 0.30, 8)]):
        out.append(f'<img {a("it-stars")}src="./collage/world/soft/star-{1 + i % 3}.png" alt="" style="position: absolute; left: {fx * W:.0f}px; top: {fy * H:.0f}px; width: {w * k:.0f}px;">')
    sun_w = 295 * S
    sun_top = H - 1224 * S
    out.append(f'<div {a("it-glow")}style="position: absolute; left: {W / 2 - sun_w * 1.15:.0f}px; top: {sun_top - sun_w * 0.6:.0f}px; width: {sun_w * 2.3:.0f}px; height: {sun_w * 2.3:.0f}px; border-radius: 50%; '
               f'background: radial-gradient(closest-side, rgba(255,224,160,0.85), rgba(255,210,150,0.35) 55%, rgba(255,210,150,0)); opacity: 0;"></div>')
    out.append(f'<img {a("it-sun")}src="./collage/world/soft/sun.png" alt="" style="position: absolute; left: {W / 2 - sun_w / 2:.0f}px; top: {sun_top:.0f}px; width: {sun_w:.0f}px; transform: translateY({170 * k:.0f}px);">')
    out.append(f'<img {a("it-cloud1")}src="./collage/world/soft/cloud-2.png" alt="" style="position: absolute; left: {-0.08 * W:.0f}px; top: {tops["far"] - 180 * k:.0f}px; width: {130 * k:.0f}px; opacity: 0;">')
    out.append(f'<img {a("it-cloud2")}src="./collage/world/soft/cloud-3.png" alt="" style="position: absolute; left: {0.72 * W:.0f}px; top: {tops["far"] - 250 * k:.0f}px; width: {110 * k:.0f}px; opacity: 0;">')
    for n in ("far", "mid", "near"):
        tw, th = META[n]["w"] * S, META[n]["h"] * S
        u = f"./collage/world/{n}-day.webp"
        out.append(f'<div {a("it-" + n)}style="position: absolute; left: 0px; top: {tops[n]:.0f}px; width: {W}px; height: {th:.0f}px; background-image: url({u}); '
                   f'background-size: {tw:.1f}px {th:.1f}px; background-position: -{offs[n] * S:.0f}px 0px; background-repeat: repeat-x; '
                   f'transform: translateY({26 * k:.0f}px); filter: brightness(0.42) saturate(0.55) hue-rotate(12deg);"></div>')
    path_y = tops["near"] + 430 * S
    if hare:
        fh = 132 * k; fw = FS[0] * fh / FS[1]
        out.append(f'<img {a("it-front")}src="./collage/brand/hare-front-sit.png" alt="The hare" style="position: absolute; left: {W / 2 - fw / 2:.0f}px; top: {path_y + 8 * k - fh:.0f}px; width: {fw:.0f}px; height: {fh:.0f}px; opacity: 0; transform-origin: 50% 100%; filter: drop-shadow(0 4px 5px rgba(60,40,20,0.28));">')
        sh = 138 * k; sw = SS[0] * sh / SS[1]
        out.append(f'<img {a("it-side")}src="./collage/hare-sit.png" alt="" style="position: absolute; left: {W / 2 - sw * 0.52:.0f}px; top: {path_y + 8 * k - sh:.0f}px; width: {sw:.0f}px; height: {sh:.0f}px; opacity: 0; transform-origin: 50% 100%; filter: drop-shadow(0 4px 5px rgba(60,40,20,0.28));">')
        hh = 118 * k; hw = HOP[0] * hh / HOP[1]
        out.append(f'<div {a("it-run")}style="position: absolute; left: {W / 2 - hw / 2:.0f}px; top: {path_y + 10 * k - hh:.0f}px; width: {hw:.0f}px; height: {hh:.0f}px; opacity: 0; --run: {W / 2 + hw:.0f}px;">'
                   f'<div {a("it-runsprite")}style="width: {hw:.0f}px; height: {hh:.0f}px; background-image: url(./collage/sprites/hare-hop.webp); background-size: {hw * 8:.0f}px {hh:.0f}px; --sheet: -{hw * 8:.0f}px;"></div></div>')
    if title:
        ts = 46 * min(1.6, k)
        out.append(f'<div {a("it-title")}style="position: absolute; left: 0px; top: {H * 0.14:.0f}px; width: {W}px; display: flex; flex-direction: column; align-items: center; gap: {10 * k:.0f}px; opacity: 0;">'
                   f'<div style="filter: drop-shadow(0 3px 5px rgba(60,40,20,0.3));"><div style="padding: {12 * k:.0f}px {28 * k:.0f}px {16 * k:.0f}px; {PAPER_BG} clip-path: {deckle(28, 5, 4)}; transform: rotate(-2deg); '
                   f'font-family: Fraunces, Georgia, serif; font-weight: 700; font-size: {ts:.0f}px; line-height: 1; color: {INK};">Hop Tales</div></div>'
                   f'<div style="font-family: Young Serif, Georgia, serif; font-size: {17 * min(1.5, k):.0f}px; color: {INK}; opacity: 0.85;">a read-aloud adventure</div></div>')
    return "".join(out)


def css():
    e = "cubic-bezier(0.3, 0, 0.25, 1)"
    return f"""
.it-dawn {{ animation: itDawn {T_SUN}s {T_SUN0}s ease-in-out both; }}
.it-day {{ animation: itDay {T_SUN}s {T_SUN0}s ease-in-out both; }}
.it-stars {{ animation: itStars {T_SUN}s {T_SUN0}s ease-out both; }}
.it-sun {{ animation: itSun {T_SUN}s {T_SUN0}s {e} both; }}
.it-glow {{ animation: itGlow {T_SUN}s {T_SUN0}s ease-in-out both; }}
.it-cloud1 {{ animation: itCloud1 6s {T_SUN0}s ease-out both; }}
.it-cloud2 {{ animation: itCloud2 6s {T_SUN0}s ease-out both; }}
.it-far {{ animation: itRise 4s {T_SUN0}s {e} both; }}
.it-mid {{ animation: itRise 4s {T_SUN0 + 0.12}s {e} both; }}
.it-near {{ animation: itRise 4s {T_SUN0 + 0.24}s {e} both; }}
.it-front {{ animation: itFront {T_TURN - T_HARE:.2f}s {T_HARE}s linear both; }}
.it-side {{ animation: itSide 0.5s {T_TURN}s linear both; }}
.it-run {{ animation: itRun {D_RUN}s {T_RUN}s cubic-bezier(0.45, 0, 0.9, 0.6) forwards; }}
.it-runsprite {{ animation: itSheet 0.57s {T_RUN}s steps(8) 2 forwards; }}
.it-title {{ animation: itTitle {T_UI - T_TITLE}s {T_TITLE}s ease-in-out both; }}
.it-ui {{ animation: itUI 0.7s {T_UI}s cubic-bezier(0.2, 0.8, 0.2, 1) both; }}
.it-top {{ animation: itTop 0.6s {T_UI + 0.15}s ease-out both; }}
.it-step {{ animation: itStep 0.35s ease-out both; }}
@keyframes itDawn {{ 0% {{ opacity: 0; }} 45%, 100% {{ opacity: 1; }} }}
@keyframes itDay {{ 0%, 40% {{ opacity: 0; }} 100% {{ opacity: 1; }} }}
@keyframes itStars {{ 0% {{ opacity: 1; }} 55%, 100% {{ opacity: 0; }} }}
@keyframes itSun {{ 100% {{ transform: translateY(-40px); }} }}
@keyframes itGlow {{ 0% {{ opacity: 0; transform: translateY(170px) scale(0.8); }} 50% {{ opacity: 1; }} 100% {{ opacity: 0.5; transform: translateY(-40px) scale(1.1); }} }}
@keyframes itCloud1 {{ 0% {{ transform: translateX(-24px); opacity: 0; }} 30%, 100% {{ opacity: 1; }} 100% {{ transform: translateX(10px); }} }}
@keyframes itCloud2 {{ 0% {{ transform: translateX(20px); opacity: 0; }} 35%, 100% {{ opacity: 1; }} 100% {{ transform: translateX(-6px); }} }}
@keyframes itRise {{ 35% {{ filter: brightness(0.62) saturate(0.75) sepia(0.25); }} 100% {{ transform: translateY(0px); filter: brightness(1) saturate(1); }} }}
@keyframes itFront {{ 0% {{ opacity: 0; transform: translateY(18px) scale(0.9, 1.08); }} 30% {{ opacity: 1; transform: translateY(-6px) scale(1.02, 0.98); }} 42% {{ opacity: 1; transform: none; }} 90% {{ opacity: 1; transform: scale(1, 1); }} 96% {{ opacity: 1; transform: scale(0.82, 1.03); }} 100% {{ opacity: 0; transform: scale(0.7, 1.03); }} }}
@keyframes itSide {{ 0% {{ opacity: 0; transform: scale(0.75, 1.02); }} 18% {{ opacity: 1; transform: scale(1.03, 0.97); }} 50% {{ opacity: 1; transform: scale(0.97, 1.03); }} 76% {{ opacity: 1; transform: scale(1.06, 0.9); }} 80%, 100% {{ opacity: 0; }} }}
@keyframes itRun {{ 0% {{ opacity: 1; transform: translateX(0px); }} 99% {{ opacity: 1; }} 100% {{ opacity: 0; transform: translateX(var(--run)); }} }}
@keyframes itSheet {{ from {{ background-position-x: 0px; }} to {{ background-position-x: var(--sheet); }} }}
@keyframes itTitle {{ 0% {{ opacity: 0; transform: translateY(10px); }} 25%, 70% {{ opacity: 1; transform: none; }} 100% {{ opacity: 0; transform: translateY(-24px); }} }}
@keyframes itUI {{ 0% {{ opacity: 0; transform: translateY(80px); }} 100% {{ opacity: 1; transform: none; }} }}
@keyframes itTop {{ 0% {{ opacity: 0; transform: translateY(-14px); }} 100% {{ opacity: 1; transform: none; }} }}
@keyframes itStep {{ 0% {{ opacity: 0; transform: translateX(18px); }} 100% {{ opacity: 1; transform: none; }} }}
@media (prefers-reduced-motion: reduce) {{ [class^=it-] {{ animation-duration: 0.01s !important; animation-delay: 0s !important; }} }}
"""


def serif(size, color=INK):
    return f"font-family: Fraunces, Georgia, serif; font-weight: 700; font-size: {size}px; line-height: 1.12; color: {color};"


def fred(size, color=INK, w=500):
    return f"font-family: Fredoka, sans-serif; font-weight: {w}; font-size: {size}px; line-height: 1.45; color: {color};"


def primary(label, handler, extra=""):
    return (f'<button type="button" onClick="{{{{{handler}}}}}" style="height: 56px; border-radius: 999px; border: 4px solid #FFFFFF; background: {RED}; color: #FFFFFF; {fred(18, "#FFFFFF", 600)} '
            f'box-shadow: 0 4px 10px rgba(60,40,20,0.3); cursor: pointer; padding: 0 28px; {extra}">{label}</button>')


def sheet(inner, top):
    return (f'<div style="position: absolute; left: 0px; top: {top}px; width: 390px; bottom: 0px; filter: drop-shadow(0 -4px 10px rgba(60,40,20,0.22));">'
            f'<div style="position: absolute; inset: 0; {PAPER_BG} clip-path: {deckle(40, 1.4, 21)};"></div>'
            f'<div style="position: relative; padding: 26px 24px 34px; box-sizing: border-box; height: 100%; display: flex; flex-direction: column; gap: 16px;">{inner}</div></div>')


def choice(label, sub, pick, style):
    return (f'<button type="button" onClick="{{{{{pick}}}}}" style="{{{{{style}}}}} text-align: left; width: 100%; padding: 14px 16px; border-radius: 18px; cursor: pointer; display: flex; flex-direction: column; gap: 2px;">'
            f'<span style="{serif(19)}">{label}</span>' + (f'<span style="{fred(14, MUTED)}">{sub}</span>' if sub else "") + '</button>')


def step_head(n, title, sub):
    return (f'<div style="{fred(13, MUTED, 600)} letter-spacing: 0.08em; text-transform: uppercase;">Step {n} of 4</div>'
            f'<h2 style="margin: 0; {serif(28)}">{title}</h2><p style="margin: 0; {fred(16, "#4A3F36")}">{sub}</p>')


def onboarding():
    name = (step_head(1, "What should we call you?", "A first name, a nickname or anything familiar is perfect. We use it to say hello, and it never leaves this device.")
            + f'<label for="it-name" style="{fred(14, MUTED, 600)}">Name or nickname</label>'
            + f'<input id="it-name" type="text" value="{{{{name}}}}" onChange="{{{{setName}}}}" placeholder="[NAME]" style="height: 54px; border-radius: 16px; border: 3px solid #FFFFFF; background: rgba(255,255,255,0.7); padding: 0 16px; {serif(22)} box-shadow: inset 0 1px 3px rgba(60,40,20,0.15);">'
            + f'<div style="flex-grow: 1;"></div>{primary("Continue", "next", "align-self: stretch;")}')
    mic = (step_head(2, "Can Hop Tales use the microphone?", "The microphone lets Hop Tales hear your child read, so the hare can hop to the next word. Everything is heard on this device. Nothing is recorded, and nothing is sent anywhere.")
           + f'<sc-if value="{{{{micOn}}}}" hint-placeholder-val="{{{{false}}}}"><div style="display: flex; align-items: center; gap: 10px; {fred(16, "#46613A", 600)}">'
             f'<svg width="22" height="22" viewBox="0 0 24 24" aria-hidden="true"><circle cx="12" cy="12" r="10" fill="{SAGE}"></circle><path d="M7 12.5 l3.3 3.3 L17 9" stroke="#FFFFFF" stroke-width="2.6" fill="none" stroke-linecap="round" stroke-linejoin="round"></path></svg>Microphone allowed.</div></sc-if>'
           + f'<div style="flex-grow: 1;"></div>'
           + f'<sc-if value="{{{{micOff}}}}" hint-placeholder-val="{{{{true}}}}">{primary("Allow microphone", "allowMic", "align-self: stretch;")}'
             f'<div style="{fred(13, MUTED)} text-align: center;">iPhone will ask you to allow the microphone and speech recognition.</div></sc-if>'
           + f'<sc-if value="{{{{micOn}}}}" hint-placeholder-val="{{{{false}}}}">{primary("Continue", "next", "align-self: stretch;")}</sc-if>')
    lv = [("Just starting", "Short, simple words like cat, sun and mud."), ("Getting going", "Longer sentences and a few tricky words like knight."), ("Reading well", "Longer words and ideas, like dragon and purple.")]
    level = (step_head(3, "What's your reader's reading level?", "Hop Tales starts them on a story that fits. You can change this later.")
             + "".join(choice(t, s_, f"pickL{i}", f"lvl{i}") for i, (t, s_) in enumerate(lv))
             + f'<div style="flex-grow: 1;"></div>{primary("Continue", "next", "align-self: stretch;")}')
    acc = ["Canadian", "American", "British", "Australian"]
    accent = (step_head(4, "What's your reader's accent?", "Hop Tales listens for this accent, so it understands your child's words the way they say them.")
              + '<div style="display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 10px;">' + "".join(choice(t, "", f"pickA{i}", f"acc{i}") for i, t in enumerate(acc)) + "</div>"
              + f'<div style="flex-grow: 1;"></div>{primary("Start reading", "finish", "align-self: stretch;")}')
    steps = "".join(f'<sc-if value="{{{{s{i}}}}}" hint-placeholder-val="{{{{{str(i == 0).lower()}}}}}"><div class="it-step" style="display: flex; flex-direction: column; gap: 14px; flex-grow: 1;">{c}</div></sc-if>'
                    for i, c in enumerate((name, mic, level, accent)))
    dots = "".join(f'<span style="{{{{dot{i}}}}}"></span>' for i in range(4))
    inner = f'<div style="display: flex; gap: 7px; justify-content: center;">{dots}</div>{steps}'
    return sheet(inner, 330)


def home():
    top = (f'<div class="it-top" style="position: absolute; left: 20px; top: 58px; width: 350px; display: flex; align-items: center; justify-content: space-between;">'
           f'<div style="display: flex; align-items: center; gap: 10px;"><img src="./collage/brand/icon-v-1024.png" alt="" style="width: 40px; height: 40px; border-radius: 9px; box-shadow: 0 3px 7px rgba(40,30,20,0.25);">'
           f'<span style="{serif(24)}">Hop Tales</span></div>'
           f'<button type="button" aria-label="Settings for grown-ups" style="width: 46px; height: 46px; border-radius: 50%; border: 4px solid #FFFFFF; {PAPER_BG} box-shadow: 0 3px 7px rgba(60,40,20,0.25); display: flex; align-items: center; justify-content: center; padding: 0;">'
           f'<svg width="20" height="20" viewBox="0 0 24 24" aria-hidden="true"><circle cx="12" cy="12" r="3.2" fill="none" stroke="{INK}" stroke-width="2"></circle><path d="M12 3v3M12 18v3M3 12h3M18 12h3M5.6 5.6l2.1 2.1M16.3 16.3l2.1 2.1M5.6 18.4l2.1-2.1M16.3 7.7l2.1-2.1" stroke="{INK}" stroke-width="2" stroke-linecap="round"></path></svg></button></div>'
           f'<div class="it-top" style="position: absolute; left: 22px; top: 132px; filter: drop-shadow(0 2px 3px rgba(60,40,20,0.28));"><div style="padding: 8px 18px 10px; {PAPER_BG} clip-path: {deckle(24, 6, 7)}; transform: rotate(-3deg); {serif(21)} white-space: nowrap;">{{{{greeting}}}}</div></div>')
    rows = [("phone-storm.jpg", "Storm on the Hill", "14 words"), ("phone-golden.jpg", "Golden Hour", "16 words"), ("phone-night.jpg", "Moonlight Hop", "18 words")]
    lst = "".join(f'<a href="#" style="text-decoration: none; display: flex; align-items: center; gap: 12px; padding: 8px 10px; border-radius: 16px; background: rgba(255,255,255,0.55);">'
                  f'<span style="width: 50px; height: 50px; border-radius: 11px; overflow: hidden; border: 3px solid #FFFFFF; flex-shrink: 0; display: block;"><img src="./collage/shots/{s}" alt="" style="width: 100%; height: 100%; object-fit: cover; object-position: 50% 30%; display: block;"></span>'
                  f'<span style="display: flex; flex-direction: column;"><span style="{serif(17)}">{t}</span><span style="{fred(13, MUTED)}">{m}</span></span></a>' for s, t, m in rows)
    cont = (f'<a href="#" style="text-decoration: none; display: flex; align-items: center; gap: 12px; padding: 12px; border-radius: 20px; background: #FFFFFF; box-shadow: 0 2px 6px rgba(60,40,20,0.14);">'
            f'<span style="width: 62px; height: 62px; border-radius: 12px; overflow: hidden; flex-shrink: 0; display: block;"><img src="./collage/shots/phone-read.jpg" alt="" style="width: 100%; height: 100%; object-fit: cover; object-position: 50% 30%; display: block;"></span>'
            f'<span style="display: flex; flex-direction: column; flex-grow: 1; min-width: 0;"><span style="{fred(12, MUTED, 600)} letter-spacing: 0.06em; text-transform: uppercase;">{{{{contLabel}}}}</span>'
            f'<span style="{serif(19)} white-space: nowrap;">{{{{contTitle}}}}</span><span style="{fred(13, MUTED)}">{{{{contMeta}}}}</span></span>'
            f'<span style="width: 46px; height: 46px; border-radius: 50%; background: {RED}; display: flex; align-items: center; justify-content: center; border: 4px solid #FFFFFF; box-shadow: 0 3px 6px rgba(60,40,20,0.3); flex-shrink: 0;">'
            f'<svg width="18" height="18" viewBox="0 0 24 24" aria-hidden="true"><path d="M8 5 L19 12 L8 19 Z" fill="#FFFFFF"></path></svg></span></a>')
    inner = f'{cont}<div style="{serif(20)} margin-top: 4px;">More stories</div>{lst}'
    return top + sheet(inner, 430)


LOGIC = r"""
class Component extends DCLogic {
  constructor(props) {
    super(props);
    this.state = { k: 0, returning: true, step: 0, name: '', mic: false, lvl: -1, acc: -1, done: false };
  }
  renderVals() {
    const st = this.state;
    const replay = (ret) => this.setState({ k: st.k + 1, returning: ret, step: 0, name: '', mic: false, lvl: -1, acc: -1, done: false });
    const showHome = st.returning || st.done;
    const pill = (on) => "font-family: Fredoka, sans-serif; font-weight: 600; font-size: 15px; padding: 9px 16px; border-radius: 999px; cursor: pointer; border: 3px solid #FFFFFF; box-shadow: 0 2px 6px rgba(60,40,20,0.2); " +
      (on ? "background: #3B2A20; color: #FBF4E4;" : "background: #FBF4E4; color: #3B2A20;");
    const opt = (on) => "border: 3px solid " + (on ? "#B8423A" : "#FFFFFF") + "; background: " + (on ? "#FFF3E6" : "rgba(255,255,255,0.6)") + "; box-shadow: 0 2px 5px rgba(60,40,20,0.12);";
    const v = {
      a: st.k % 2 === 0, b: st.k % 2 === 1,
      replayReturning: () => replay(true), replayFirst: () => replay(false),
      btnRet: pill(st.returning), btnFirst: pill(!st.returning),
      showHome, showOnb: !showHome,
      name: st.name,
      setName: (e) => this.setState({ name: e.target.value }),
      next: () => this.setState({ step: Math.min(3, st.step + 1) }),
      allowMic: () => this.setState({ mic: true }),
      micOn: st.mic, micOff: !st.mic,
      finish: () => this.setState({ done: true }),
      greeting: st.done && st.name.trim() ? "Good morning, " + st.name.trim() + "!" : "Good morning, [NAME]!",
      contLabel: st.done ? "Start here" : "Keep reading",
      contTitle: st.done ? ["The Meadow Walk", "Storm on the Hill", "Moonlight Hop"][Math.max(0, st.lvl)] : "The Meadow Walk",
      contMeta: st.done ? "your first story" : "word 3 of 12",
    };
    for (let i = 0; i < 4; i++) {
      v["s" + i] = st.step === i;
      v["dot" + i] = "width: " + (st.step === i ? 22 : 8) + "px; height: 8px; border-radius: 4px; display: block; transition: width 0.3s; background: " + (st.step >= i ? "#B8423A" : "rgba(156,139,120,0.35)") + ";";
      v["pickA" + i] = () => this.setState({ acc: i });
      v["acc" + i] = opt(st.acc === i);
    }
    for (let i = 0; i < 3; i++) {
      v["pickL" + i] = () => this.setState({ lvl: i });
      v["lvl" + i] = opt(st.lvl === i);
    }
    return v;
  }
}
"""


def intro_body():
    phone_inner = (f'{scene(390, 844)}'
                   f'<div class="it-ui" style="position: absolute; inset: 0;">'
                   f'<sc-if value="{{{{showHome}}}}" hint-placeholder-val="{{{{true}}}}">{home()}</sc-if>'
                   f'<sc-if value="{{{{showOnb}}}}" hint-placeholder-val="{{{{false}}}}">{onboarding()}</sc-if></div>')
    run = lambda: f'<div style="position: relative; width: 390px; height: 844px; overflow: hidden;">{phone_inner}</div>'
    phone = (f'<div style="position: absolute; left: 0px; top: 0px; width: 390px; height: 844px; overflow: hidden;">'
             f'<sc-if value="{{{{a}}}}" hint-placeholder-val="{{{{true}}}}">{run()}</sc-if><sc-if value="{{{{b}}}}" hint-placeholder-val="{{{{false}}}}">{run()}</sc-if></div>')
    panel = (f'<div style="position: absolute; left: 430px; top: 40px; width: 300px; display: flex; flex-direction: column; gap: 14px;">'
             f'<div style="{serif(24)}">Play the intro</div>'
             f'<button type="button" onClick="{{{{replayReturning}}}}" style="{{{{btnRet}}}}">Returning reader → home</button>'
             f'<button type="button" onClick="{{{{replayFirst}}}}" style="{{{{btnFirst}}}}">First launch → onboarding</button>'
             f'<div style="{fred(14, MUTED)}">0.0 s launch image (identical to frame 0)<br>0.6 s sunrise begins<br>3.9 s hare pops up, facing us<br>4.2 s title<br>5.6 s hare turns side-on<br>6.0 s runs off to the right<br>6.7 s interface rises in</div></div>')
    return phone + panel


def still_css():
    # first-frame values for the launch image
    return ""


if __name__ == "__main__":
    doc = dc_doc("Hop Tales · intro", 760, 844, intro_body(), CREAM, LOGIC, css())
    doc = doc.replace(doc[doc.index('<link rel="stylesheet"'):doc.index('>', doc.index('<link rel="stylesheet"')) + 1], FONT)
    open(os.path.join(P, "Intro.dc.html"), "w").write(doc)
    for name, W, H in (("LaunchPhone", 390, 844), ("LaunchPadPortrait", 1024, 1366), ("LaunchPadLandscape", 1366, 1024)):
        body = f'<div style="position: relative; width: {W}px; height: {H}px; overflow: hidden;">{scene(W, H, anim=False, title=False, hare=False)}</div>'
        d = dc_doc(f"Hop Tales · launch image {W}×{H}", W, H, body, "#1E2A4E", "class Component extends DCLogic {\n  renderVals() {\n    return {};\n  }\n}")
        open(os.path.join(P, name + ".dc.html"), "w").write(d)
        # also a full sequence preview at this size (for checking iPad layout)
        prev = (f"<html><head><style>body{{margin:0}}{css()}</style></head><body><div style='position:relative;width:{W}px;height:{H}px;overflow:hidden'>"
                + scene(W, H) + "</div></body></html>").replace('src="./', f'src="file://{P}/').replace("url(./", f"url(file://{P}/")
        open(os.path.join(HERE, "out", name + ".html"), "w").write(prev)
        still = (f"<html><head><style>body{{margin:0}}</style></head><body>" + body + "</body></html>").replace('src="./', f'src="file://{P}/').replace("url(./", f"url(file://{P}/")
        open(os.path.join(HERE, "out", name + "-still.html"), "w").write(still)
    # static previews of the intro at points in time
    for t in (0.0, 3.0, 5.0, 5.5, 5.8, 6.1, 6.4, 8.0):
        c = css().replace(" both;", f" both; animation-play-state: paused;")
        import re
        c = re.sub(r"(\d+(?:\.\d+)?)s (ease|linear|cubic|steps)", lambda m: m.group(0), c)
        body = intro_body()
        prev = (f"<html><head><style>body{{margin:0;background:{CREAM}}}{c}</style><script>document.addEventListener('DOMContentLoaded',()=>{{"
                f"document.getAnimations().forEach(a=>{{a.currentTime={t * 1000};a.pause();}});}});</script></head><body>"
                + f'<div style="position:relative;width:390px;height:844px;overflow:hidden">{scene(390, 844)}<div class="it-ui" style="position:absolute;inset:0">'
                + (home() if t < 7.9 else onboarding()) + "</div></div></body></html>")
        prev = prev.replace('src="./', f'src="file://{P}/').replace("url(./", f"url(file://{P}/")
        prev = re.sub(r"\{\{[^}]+\}\}", "", prev)
        open(os.path.join(HERE, "out", f"intro-{t}.html"), "w").write(prev)
    print("ok")
