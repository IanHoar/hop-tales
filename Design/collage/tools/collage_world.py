import os, sys, json, random
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from collage_boards import PROJ, C, INK, PAPER, MUTED, WASH, RED, SAGE, PAPER_BG, dc_doc, preview, SIT_W, SIT_H, BND_W, BND_H
from PIL import Image

WD = os.path.join(C, "world")
META = json.load(open(os.path.join(WD, "meta.json")))
SW, SH = 1480, 700
S = 0.55
TOPS = {"far": 147, "mid": 200, "near": 245}
SPEED_NEAR = 42.0            # px per second at 1x
FACT = {"far": 0.3, "mid": 0.6, "near": 1.0}
PATH_Y = TOPS["near"] + 430 * S
FONT_LINK = ('<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Fraunces:opsz,wght@9..144,600;9..144,700&amp;'
             'family=Young+Serif&amp;family=Fredoka:wght@500;600&amp;display=swap">')


def dims(n):
    im = Image.open(os.path.join(C, f"{n}.png"))
    return im.size


def layer_css():
    css = []
    for n in ("far", "mid", "near"):
        tw = META[n]["w"] * S
        dur = tw / (SPEED_NEAR * FACT[n])
        css.append(f".lw-{n} {{ animation: lw{n} {dur:.1f}s linear infinite; }} "
                   f"@keyframes lw{n} {{ from {{ background-position-x: 0px; -webkit-mask-position-x: 0px; mask-position-x: 0px; }} "
                   f"to {{ background-position-x: -{tw:.1f}px; -webkit-mask-position-x: -{tw:.1f}px; mask-position-x: -{tw:.1f}px; }} }}")
    return "\n".join(css)


def layer(n):
    tw, th = META[n]["w"] * S, META[n]["h"] * S
    url = f"./collage/world/{n}-day.webp"
    return (f'<div class="lw-{n}" style="position: absolute; left: 0px; top: {TOPS[n]}px; width: {SW}px; height: {th:.0f}px; '
            f'background-image: url({url}); background-repeat: repeat-x; background-size: {tw:.1f}px {th:.1f}px; '
            f'-webkit-mask-image: url({url}); mask-image: url({url}); -webkit-mask-repeat: repeat-x; mask-repeat: repeat-x; '
            f'-webkit-mask-size: {tw:.1f}px {th:.1f}px; mask-size: {tw:.1f}px {th:.1f}px; background-blend-mode: multiply; '
            f'transition: background-color 3s ease; {{{{tint_{n}}}}}"></div>')


def soft_name(name):
    return name.replace("world/", "world/soft/") if name.startswith("world/") else "soft/" + name


def sticker(name, x, base, h, rot=0, extra="", soft=False):
    if soft:
        name = soft_name(name)
    w, hh = dims(name)
    ww = w * h / hh
    sh = "drop-shadow(0 2px 2px rgba(60,40,20,0.14))" if soft else "drop-shadow(0 4px 5px rgba(60,40,20,0.28))"
    return (f'<img src="./collage/{name}.png" alt="" style="position: absolute; left: {x:.0f}px; top: {base - h:.0f}px; width: {ww:.0f}px; height: {h:.0f}px; '
            f'transform: rotate({rot}deg); filter: {sh}; {extra}">')


def props_band(cls, items, period, soft=False):
    inner = "".join(sticker(*it, soft=soft) for it in items)
    band = f'<div style="position: absolute; left: 0px; top: 0px; width: {period}px; height: {SH}px;">{inner}</div>'
    band2 = f'<div style="position: absolute; left: {period}px; top: 0px; width: {period}px; height: {SH}px;">{inner}</div>'
    return f'<div class="{cls}" style="position: absolute; left: 0px; top: 0px; width: {period * 2}px; height: {SH}px;">{band}{band2}</div>'


def clouds_band(cls, names, period, ys, hs, seed, soft=False):
    r = random.Random(seed)
    items = []
    x = 60
    i = 0
    while x < period - 300:
        n = names[i % len(names)]
        h = hs[i % len(hs)] * r.uniform(0.85, 1.15)
        items.append((f"world/{n}", x, ys[i % len(ys)] + h, h, r.uniform(-3, 3)))
        w, hh = dims(f"world/{n}")
        x += w * h / hh + r.uniform(140, 420)
        i += 1
    inner = "".join(sticker(*it, soft=soft) for it in items)
    band = f'<div style="position: absolute; left: 0px; top: 0px; width: {period}px; height: 320px;">{inner}</div>'
    band2 = f'<div style="position: absolute; left: {period}px; top: 0px; width: {period}px; height: 320px;">{inner}</div>'
    return f'<div class="{cls}" style="position: absolute; left: 0px; top: 0px; width: {period * 2}px; height: 320px;">{band}{band2}</div>'


def hare_walk():
    s = 0.3
    w, h = BND_W * s, BND_H * s
    return (f'<div class="hw-hop" style="position: absolute; left: 380px; top: {PATH_Y - h + 52:.0f}px; width: {w:.0f}px; height: {h:.0f}px;">'
            f'<img src="./collage/hare-bound.png" alt="The hare bounding along the path" style="width: {w:.0f}px; height: {h:.0f}px; display: block; filter: drop-shadow(0 6px 6px rgba(60,40,20,0.28));"></div>')


def hare_wait():
    s = 168 / SIT_H
    w, h = SIT_W, SIT_H
    img = f'<img src="./collage/hare-sit.png" alt="" style="position: absolute; left: 0px; top: 0px; width: {w}px; height: {h}px; display: block;">'
    body = f'<div style="position: absolute; left: 0px; top: 0px; width: {w}px; height: {h}px; clip-path: inset(212px 0px 0px 0px);">{img}</div>'
    ears = f'<div class="cg-ears" style="position: absolute; left: 0px; top: 0px; width: {w}px; height: {h}px; clip-path: inset(0px 0px {h - 226}px 0px);">{img}</div>'
    lid = (f'<div class="cg-blink" style="position: absolute; left: 319px; top: 228px; width: 30px; height: 28px; border-radius: 50%; '
           f'background: #C99B63; box-shadow: inset 0 -3px 0 #6A4A30;"></div>')
    inner = f'<div class="cg-breathe" style="position: relative; width: {w}px; height: {h}px;">{body}{ears}{lid}</div>'
    return (f'<div class="cg-land" style="position: absolute; left: {470 - 232 * s:.0f}px; top: {PATH_Y + 10 - h * s:.0f}px; width: {w * s:.0f}px; height: {h * s:.0f}px; filter: drop-shadow(0 5px 5px rgba(60,40,20,0.28));">'
            f'<div style="width: {w}px; height: {h}px; transform: scale({s:.4f}); transform-origin: 0 0;">{inner}</div></div>')


def button_row(label, key, opts):
    items = "".join(
        f'<button type="button" onClick="{{{{pick_{key}_{i}}}}}" style="{{{{btn_{key}_{i}}}}}">{o}</button>' for i, o in enumerate(opts))
    return (f'<div style="display: flex; align-items: center; gap: 10px;"><span style="font-family: Fraunces, serif; font-weight: 700; font-size: 17px; color: {INK}; width: 86px;">{label}</span>'
            f'<div style="display: flex; gap: 8px; flex-wrap: wrap;">{items}</div></div>')


TIMES = ["Day", "Golden hour", "Dusk", "Night"]
WEATHERS = ["Clear", "Clouds", "Storm", "Rain"]
MODES = ["Walking", "Waiting for a word"]
SCENERY = ["Painted in", "Stickers"]


def body():
    period_back = 5300
    period_front = 3900
    near_top = TOPS["near"]
    back = [("prop-oak", 150, PATH_Y - 70, 250, -1), ("prop-bush", 760, PATH_Y - 64, 92, 0), ("prop-fence", 1180, PATH_Y - 58, 86, 1),
            ("prop-bush", 1330, PATH_Y - 60, 70, 0), ("prop-signpost", 1900, PATH_Y - 60, 104, 2), ("prop-oak", 2450, PATH_Y - 72, 210, 1),
            ("prop-fence", 3000, PATH_Y - 58, 80, -1),
            ("prop-bush", 3520, PATH_Y - 62, 84, 0), ("prop-oak", 4150, PATH_Y - 70, 180, 0), ("prop-bush", 4420, PATH_Y - 60, 64, 0), ("prop-signpost", 4900, PATH_Y - 60, 96, -2)]
    front = [("prop-flowers", 120, SH + 8, 150, -3), ("prop-mushrooms", 900, SH + 4, 110, 2), ("prop-flowers", 1700, SH + 10, 130, 2),
             ("prop-mushrooms", 2250, SH + 2, 90, -2),
             ("prop-flowers", 3050, SH + 8, 160, 1), ("prop-mushrooms", 3500, SH + 2, 100, 3)]
    sky = "".join(f'<div style="position: absolute; inset: 0; transition: opacity 3s ease; {{{{sky_{i}}}}}"></div>' for i in range(4))
    storm_sky = '<div style="position: absolute; inset: 0; background: linear-gradient(#6E7684, #A4AAB0 70%, #BFC2C0); transition: opacity 3s ease; {{stormSky}}"></div>'
    sun = f'<div style="position: absolute; left: 1250px; width: 150px; transition: top 4s ease, opacity 3s ease; {{{{sunStyle}}}}"><img src="./collage/world/soft/sun.png" alt="" style="width: 150px; display: block; filter: drop-shadow(0 4px 6px rgba(60,40,20,0.25));"></div>'
    moon = f'<div style="position: absolute; left: 260px; top: 40px; width: 96px; transition: opacity 3s ease; {{{{moonStyle}}}}"><img src="./collage/world/soft/moon.png" alt="" style="width: 96px; display: block;"></div>'
    stars = "".join(f'<img src="./collage/world/soft/star-{1 + i % 3}.png" alt="" style="position: absolute; left: {x}px; top: {y}px; width: {w}px; transition: opacity 3s ease; {{{{starStyle}}}}">'
                    for i, (x, y, w) in enumerate([(120, 60, 30), (430, 110, 22), (640, 40, 26), (880, 90, 20), (1010, 30, 28), (1300, 70, 24), (1400, 130, 18)]))
    clouds = ""
    for soft, key in ((True, "softOn"), (False, "stickerOn")):
        fair = clouds_band("cl-fair", ["cloud-1", "cloud-2", "cloud-3", "cloud-4"], 2400, [22, 60, 12, 48], [96, 70, 84, 110], 3, soft)
        storm = clouds_band("cl-storm", ["storm-1", "storm-2", "storm-3"], 2200, [4, 30, 10], [150, 130, 160], 7, soft)
        clouds += (f'<div style="position: absolute; inset: 0; transition: opacity 0.6s ease; {{{{{key}}}}}">'
                   f'<div style="position: absolute; left: 0px; top: 0px; width: {SW}px; height: 320px; transition: opacity 3s ease; {{{{fairStyle}}}}">{fair}</div>'
                   f'<div style="position: absolute; left: 0px; top: 0px; width: {SW}px; height: 320px; transition: opacity 3s ease; {{{{stormStyle}}}}">{storm}</div></div>')
    land = layer("far") + layer("mid") + layer("near")
    props = (f'<div style="position: absolute; inset: 0; transition: filter 3s ease; {{{{propFilter}}}}">'
             f'<div style="position: absolute; inset: 0; transition: opacity 0.6s ease; {{{{softOn}}}}">{props_band("pb-back", back, period_back, True)}</div>'
             f'<div style="position: absolute; inset: 0; transition: opacity 0.6s ease; {{{{stickerOn}}}}">{props_band("pb-back", back, period_back)}</div></div>')
    front_props = (f'<div style="position: absolute; inset: 0; transition: filter 3s ease; {{{{propFilter}}}}">'
                   f'<div style="position: absolute; inset: 0; transition: opacity 0.6s ease; {{{{softOn}}}}">{props_band("pb-front", front, period_front, True)}</div>'
                   f'<div style="position: absolute; inset: 0; transition: opacity 0.6s ease; {{{{stickerOn}}}}">{props_band("pb-front", front, period_front)}</div></div>')
    hare = (f'<div style="position: absolute; inset: 0; transition: filter 3s ease; {{{{propFilter}}}}">'
            f'<sc-if value="{{{{walking}}}}" hint-placeholder-val="{{{{true}}}}">{hare_walk()}</sc-if>'
            f'<sc-if value="{{{{waiting}}}}" hint-placeholder-val="{{{{false}}}}">{hare_wait()}</sc-if></div>')
    rain = ('<div class="rain-a" style="position: absolute; inset: 0; background-image: repeating-linear-gradient(104deg, rgba(0,0,0,0) 0px, rgba(0,0,0,0) 22px, rgba(88,104,132,0.42) 22px, rgba(88,104,132,0.42) 23.5px); '
            'background-size: 180px 260px; transition: opacity 2.5s ease; {{rainStyle}}"></div>'
            '<div class="rain-b" style="position: absolute; inset: 0; background-image: repeating-linear-gradient(100deg, rgba(0,0,0,0) 0px, rgba(0,0,0,0) 34px, rgba(88,104,132,0.3) 34px, rgba(88,104,132,0.3) 35px); '
            'background-size: 260px 340px; transition: opacity 2.5s ease; {{rainStyle}}"></div>')
    flash = '<div class="flash" style="position: absolute; inset: 0; background: #FFFDF4; pointer-events: none; {{flashStyle}}"></div>'
    stage = (f'<div style="position: relative; width: {SW}px; height: {SH}px; overflow: hidden; border-radius: 22px; border: 6px solid #FFFFFF; box-shadow: 0 5px 14px rgba(60,40,20,0.28); {{{{paused}}}}">'
             f'{sky}{storm_sky}{stars}{moon}{sun}{clouds}{land}{props}{hare}{front_props}{rain}{flash}</div>')
    controls = (f'<div style="display: flex; gap: 40px; align-items: flex-start; flex-wrap: wrap;">'
                f'<div style="display: flex; flex-direction: column; gap: 12px;">{button_row("Time", "t", TIMES)}{button_row("Weather", "w", WEATHERS)}{button_row("Hare", "m", MODES)}{button_row("Scenery", "s", SCENERY)}</div>'
                f'<div style="display: flex; flex-direction: column; gap: 10px; align-items: flex-start;">'
                f'<button type="button" onClick="{{{{toggleAuto}}}}" style="{{{{autoBtn}}}}">{{{{autoLabel}}}}</button>'
                f'<div style="font-family: Fredoka, sans-serif; font-weight: 500; font-size: 14px; line-height: 1.45; color: {MUTED}; width: 420px;">Plays a little story arc: a clear morning, clouds gather, a storm, rain, it clears to golden hour, then dusk and night. Every change is a slow crossfade on the same looping world.</div></div></div>')
    head = (f'<div style="display: flex; align-items: baseline; gap: 16px;"><div style="font-family: Fraunces, serif; font-weight: 700; font-size: 36px; color: {INK};">The endless meadow</div>'
            f'<div style="font-family: Fredoka, sans-serif; font-size: 16px; color: {MUTED};">three long seamless paper layers + a live sky · scenery painted into the world, only the hare is a sticker</div></div>')
    return f'<div style="position: absolute; left: 60px; top: 44px; width: {SW + 12}px; display: flex; flex-direction: column; gap: 22px;">{head}{stage}{controls}</div>'


CSS = """
.cl-fair { animation: clFair 220s linear infinite; }
.cl-storm { animation: clStorm 150s linear infinite; }
@keyframes clFair { from { transform: translateX(0px); } to { transform: translateX(-2400px); } }
@keyframes clStorm { from { transform: translateX(0px); } to { transform: translateX(-2200px); } }
.pb-back { animation: pbBack PB_S linear infinite; }
.pb-front { animation: pbFront PF_S linear infinite; }
@keyframes pbBack { from { transform: translateX(0px); } to { transform: translateX(-5300px); } }
@keyframes pbFront { from { transform: translateX(0px); } to { transform: translateX(-3900px); } }
.hw-hop { animation: hwHop 0.62s cubic-bezier(0.4, 0, 0.4, 1) infinite; transform-origin: 50% 90%; }
@keyframes hwHop { 0% { transform: translateY(0px) rotate(-6deg); } 45% { transform: translateY(-46px) rotate(0deg); } 100% { transform: translateY(0px) rotate(6deg); } }
.rain-a { animation: rainA 0.5s linear infinite; }
.rain-b { animation: rainB 0.8s linear infinite; }
@keyframes rainA { from { background-position: 0px 0px; } to { background-position: -64px 260px; } }
@keyframes rainB { from { background-position: 0px 0px; } to { background-position: -60px 340px; } }
.flash { animation: flash 7s linear infinite; }
@keyframes flash { 0%, 88%, 91%, 100% { opacity: 0; } 89% { opacity: 0.55; } 90% { opacity: 0.1; } 90.5% { opacity: 0.4; } }
.cg-breathe { animation: cgBreathe 2.6s ease-in-out infinite; transform-origin: 50% 100%; }
.cg-ears { animation: cgEars 5.2s ease-in-out infinite; transform-origin: 285px 208px; }
.cg-blink { animation: cgBlink 4.4s linear infinite; transform-origin: 50% 0%; }
.cg-land { animation: cgLand 0.32s cubic-bezier(0.3, 0, 0.3, 1.4) 1; transform-origin: 50% 100%; }
@keyframes cgBreathe { 0%, 100% { transform: scale(1, 1); } 50% { transform: scale(1.012, 0.986); } }
@keyframes cgEars { 0%, 64%, 100% { transform: rotate(0deg); } 67% { transform: rotate(-6deg); } 70% { transform: rotate(2.5deg); } 73% { transform: rotate(-1deg); } 76% { transform: rotate(0deg); } }
@keyframes cgBlink { 0%, 90% { transform: scaleY(0); } 92% { transform: scaleY(1); } 95% { transform: scaleY(0); } }
@keyframes cgLand { 0% { transform: scale(1.08, 0.9); } 60% { transform: scale(0.97, 1.04); } 100% { transform: scale(1, 1); } }
.paused .lw-far, .paused .lw-mid, .paused .lw-near, .paused .pb-back, .paused .pb-front { animation-play-state: paused; }
@media (prefers-reduced-motion: reduce) { .lw-far, .lw-mid, .lw-near, .pb-back, .pb-front, .cl-fair, .cl-storm, .hw-hop, .rain-a, .rain-b, .flash, .cg-breathe, .cg-ears, .cg-blink { animation: none; } }
"""

LOGIC = r"""
class Component extends DCLogic {
  constructor(props) {
    super(props);
    this.state = { t: 0, w: 0, m: 0, s: 0, auto: false, step: 0 };
    this.arc = [[0, 0], [0, 1], [0, 2], [0, 3], [1, 0], [2, 1], [3, 0]];
  }
  componentWillUnmount() { clearInterval(this.iv); }
  toggleAuto() {
    if (this.state.auto) { clearInterval(this.iv); this.setState({ auto: false }); return; }
    const go = () => {
      const s = (this.state.step + 1) % this.arc.length;
      this.setState({ step: s, t: this.arc[s][0], w: this.arc[s][1] });
    };
    this.setState({ auto: true, step: 0, t: 0, w: 0 });
    clearInterval(this.iv);
    this.iv = setInterval(go, 5000);
  }
  renderVals() {
    const { t, w, m, s, auto } = this.state;
    const SKY = [
      "linear-gradient(#BCDCEE, #DCEBEF 60%, #EEF2E6)",
      "linear-gradient(#F0C9A4, #F7DDB8 60%, #FBEBCB)",
      "linear-gradient(#7F74A6, #C98FA2 55%, #F0B48E)",
      "linear-gradient(#18223F, #2C3A63 60%, #46557E)"
    ];
    const TINT = [
      ["rgba(255,255,255,1)", "rgba(255,255,255,1)", "rgba(255,255,255,1)"],
      ["rgba(252,214,170,1)", "rgba(255,222,180,1)", "rgba(255,232,196,1)"],
      ["rgba(196,160,200,1)", "rgba(214,172,190,1)", "rgba(232,190,190,1)"],
      ["rgba(92,108,160,1)", "rgba(96,112,160,1)", "rgba(104,118,160,1)"]
    ];
    const STORM = [1, 0.92, 0.74, 0.8];
    const dim = STORM[w];
    const mix = (c) => {
      const p = c.match(/[\d.]+/g).map(Number);
      return "rgba(" + Math.round(p[0] * dim) + "," + Math.round(p[1] * dim) + "," + Math.round(p[2] * (dim + (1 - dim) * 0.3)) + ",1)";
    };
    const btn = (on) => "font-family: Fredoka, sans-serif; font-weight: 600; font-size: 15px; padding: 8px 16px; border-radius: 999px; cursor: pointer; " +
      "border: 3px solid #FFFFFF; box-shadow: 0 2px 6px rgba(60,40,20,0.22); " +
      (on ? "background: #3B2A20; color: #FBF4E4;" : "background: #FBF4E4; color: #3B2A20;");
    const vals = {
      stormSky: "opacity: " + [0, 0.25, 0.85, 0.6][w] * (t === 3 ? 0.5 : 1) + ";",
      sunStyle: "top: " + [34, 150, 238, 330][t] + "px; opacity: " + (t === 3 ? 0 : [1, 0.8, 0.12, 0.25][w]) + ";",
      moonStyle: "opacity: " + (t === 3 ? [1, 0.7, 0.15, 0.3][w] : 0) + ";",
      starStyle: "opacity: " + (t === 3 && w < 2 ? (w === 0 ? 1 : 0.4) : 0) + ";",
      fairStyle: "opacity: " + [0.9, 1, 0.25, 0.4][w] + ";" + (t === 3 ? " filter: brightness(0.55) saturate(0.7);" : (t === 2 ? " filter: sepia(0.25) saturate(1.2);" : "")),
      stormStyle: "opacity: " + [0, 0.35, 1, 0.9][w] + ";" + (t === 3 ? " filter: brightness(0.6);" : ""),
      rainStyle: "opacity: " + [0, 0, 0.75, 1][w] + ";",
      flashStyle: w === 2 ? "" : "animation: none; opacity: 0;",
      propFilter: "filter: " + [
        "brightness(" + (1 - (1 - dim) * 0.9).toFixed(2) + ")",
        "brightness(" + (1 - (1 - dim) * 0.9).toFixed(2) + ") sepia(0.18) saturate(1.1)",
        "brightness(" + (0.86 - (1 - dim) * 0.6).toFixed(2) + ") sepia(0.2) hue-rotate(-8deg)",
        "brightness(" + (0.56 - (1 - dim) * 0.3).toFixed(2) + ") saturate(0.7)"
      ][t] + ";",
      tint_far: "background-color: " + mix(TINT[t][0]) + ";",
      tint_mid: "background-color: " + mix(TINT[t][1]) + ";",
      tint_near: "background-color: " + mix(TINT[t][2]) + ";",
      softOn: "opacity: " + (s === 0 ? 1 : 0) + ";",
      stickerOn: "opacity: " + (s === 1 ? 1 : 0) + ";",
      walking: m === 0,
      waiting: m === 1,
      paused: m === 1 ? "animation-play-state: paused;" : "",
      toggleAuto: () => this.toggleAuto(),
      autoBtn: btn(auto),
      autoLabel: auto ? "Stop the story" : "Play the story",
    };
    for (let i = 0; i < 4; i++) {
      vals["sky_" + i] = "background: " + SKY[i] + "; opacity: " + (t === i ? 1 : 0) + ";";
      vals["pick_t_" + i] = () => { clearInterval(this.iv); this.setState({ t: i, auto: false }); };
      vals["btn_t_" + i] = btn(t === i);
      vals["pick_w_" + i] = () => { clearInterval(this.iv); this.setState({ w: i, auto: false }); };
      vals["btn_w_" + i] = btn(w === i);
    }
    for (let i = 0; i < 2; i++) {
      vals["pick_m_" + i] = () => this.setState({ m: i });
      vals["btn_m_" + i] = btn(m === i);
      vals["pick_s_" + i] = () => this.setState({ s: i });
      vals["btn_s_" + i] = btn(s === i);
    }
    return vals;
  }
}
"""


def static_fill(t, vals, wait=False):
    import re
    for k, v in vals.items():
        t = t.replace("{{" + k + "}}", v)
    t = re.sub(r'onClick="\{\{[^}]+\}\}"', "", t)
    t = re.sub(r'<sc-if value="\{\{walking\}\}"[^>]*>(.*?)</sc-if>', lambda m: "" if wait else m.group(1), t, flags=re.S)
    t = re.sub(r'<sc-if value="\{\{waiting\}\}"[^>]*>(.*?)</sc-if>', lambda m: m.group(1) if wait else "", t, flags=re.S)
    t = re.sub(r"\{\{[^}]+\}\}", "", t)
    return t


if __name__ == "__main__":
    pb = 5300 / SPEED_NEAR
    pf = 3900 / SPEED_NEAR
    css = CSS.replace("PB_S", f"{pb:.1f}s").replace("PF_S", f"{pf:.1f}s") + layer_css()
    b = body()
    # paused class: the root stage gets a style hole; we use animation-play-state via a wrapping class instead
    b = b.replace('box-shadow: 0 5px 14px rgba(60,40,20,0.28); {{paused}}">', 'box-shadow: 0 5px 14px rgba(60,40,20,0.28);" class="{{pausedClass}}">')
    logic = LOGIC.replace('paused: m === 1 ? "animation-play-state: paused;" : "",', 'pausedClass: m === 1 ? "paused" : "",')
    doc = dc_doc("Hop Tales · endless meadow", 1600, 1000, b, "#F4EBD8", logic, css)
    doc = doc.replace('<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Fraunces', FONT_LINK + '\n<!-- -->', 1) if False else doc
    open(os.path.join(PROJ, "CollageWorld.dc.html"), "w").write(doc)
    # previews for four states
    SKY = ["linear-gradient(#BCDCEE, #DCEBEF 60%, #EEF2E6)", "linear-gradient(#F0C9A4, #F7DDB8 60%, #FBEBCB)",
           "linear-gradient(#7F74A6, #C98FA2 55%, #F0B48E)", "linear-gradient(#18223F, #2C3A63 60%, #46557E)"]
    def st(t, w):
        tint = [["#FFFFFF"] * 3, ["#FCD6AA", "#FFDEB4", "#FFE8C4"], ["#C4A0C8", "#D6ACBE", "#E8BEBE"], ["#5C6CA0", "#6070A0", "#6876A0"]][t]
        v = {f"sky_{i}": f"background: {SKY[i]}; opacity: {1 if i == t else 0};" for i in range(4)}
        v.update(stormSky=f"opacity: {[0, 0.25, 0.85, 0.6][w]};", sunStyle=f"top: {[34, 150, 238, 330][t]}px; opacity: {0 if t == 3 else [1, .8, .12, .25][w]};",
                 moonStyle=f"opacity: {1 if t == 3 else 0};", starStyle=f"opacity: {1 if t == 3 and w == 0 else 0};",
                 fairStyle=f"opacity: {[0.9, 1, 0.25, 0.4][w]};" + (" filter: brightness(0.55) saturate(0.7);" if t == 3 else ""),
                 stormStyle=f"opacity: {[0, 0.35, 1, 0.9][w]};", rainStyle=f"opacity: {[0, 0, 0.75, 1][w]};", flashStyle="animation: none; opacity: 0;",
                 propFilter="filter: " + ["brightness(1)", "sepia(0.18) saturate(1.1)", "brightness(0.86) sepia(0.2)", "brightness(0.56) saturate(0.7)"][t] + ";",
                 tint_far=f"background-color: {tint[0]};", tint_mid=f"background-color: {tint[1]};", tint_near=f"background-color: {tint[2]};", pausedClass="", softOn="opacity: 1;", stickerOn="opacity: 0;")
        return v
    for name, t, w in (("day", 0, 0), ("storm", 0, 2), ("golden", 1, 0), ("night", 3, 0), ("wait", 2, 1)):
        preview(f"World-{name}.html", 1600, 1000, static_fill(b, st(t, w), name == "wait"), "#F4EBD8")
        p = os.path.join(os.path.dirname(os.path.abspath(__file__)), "out", f"World-{name}.html")
        txt = open(p).read().replace("</style>", css + "</style>", 1)
        open(p, "w").write(txt)
    print("ok")
