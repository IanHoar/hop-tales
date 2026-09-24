import os, sys, json
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from collage_boards import PROJ, INK, MUTED, PAPER, PAPER_BG, dc_doc, preview, STATIC_LOGIC, MEADOW_W, MEADOW_H
M = json.load(open(os.path.join(PROJ, "collage/sprites/sprites.json")))
TL = json.load(open(os.path.join(PROJ, "collage/sprites/idle-timeline.json")))
NF = len(TL["names"])
IW, IH = M["idle"]["frame"]; JW, JH = M["hop"]["frame"]
NI = M["idle"]["frames"]
def lab(t, sub):
    return (f'<div style="display: flex; align-items: baseline; gap: 12px;"><div style="font-family: Fraunces, serif; font-weight: 700; font-size: 20px; color: {INK};">{t}</div>'
            f'<div style="font-family: Fredoka, sans-serif; font-weight: 500; font-size: 14px; color: {MUTED};">{sub}</div></div>')
def stage(inner, w, h):
    s = max(h / MEADOW_H, (w + 40) / MEADOW_W)
    return (f'<div style="position: relative; width: {w}px; height: {h}px; overflow: hidden; border-radius: 20px; border: 5px solid #FFFFFF; box-shadow: 0 4px 10px rgba(60,40,20,0.25);">'
            f'<img src="./collage/meadow.jpg" alt="" style="position: absolute; left: {-min(700 * s, MEADOW_W * s - w):.0f}px; top: {h - MEADOW_H * s:.0f}px; width: {MEADOW_W * s:.0f}px; height: {MEADOW_H * s:.0f}px;">{inner}</div>')
def word(x, y, t, cls=""):
    return (f'<div class="{cls}" style="position: absolute; left: {x}px; top: {y}px; transform: translateX(-50%); padding: 6px 16px 8px; border-radius: 14px; {PAPER_BG} '
            f'box-shadow: 0 3px 6px rgba(60,40,20,0.25); font-family: Young Serif, Georgia, serif; font-size: 34px; color: {INK};">{t}</div>')
def body():
    W = 1488
    ih = 300; iw = IW * ih / IH
    layers = "".join(
        f'<div class="sp-ev{k}" style="position: absolute; inset: 0; background-image: url(./collage/sprites/hare-idle-frames.webp); '
        f'background-size: {iw * NF:.0f}px {ih}px; background-position: -{iw * k:.0f}px 0px; background-repeat: no-repeat; opacity: {1 if k == 0 else 0};"></div>' for k in range(NF))
    idle = (f'<div role="img" aria-label="Idle: the hare sits and breathes, blinking and flicking an ear now and then" style="position: absolute; left: {(560 - iw) / 2:.0f}px; top: 70px; width: {iw:.0f}px; height: {ih}px;">'
            f'<div class="sp-breathe" style="position: absolute; inset: 0; transform-origin: 50% 96%;">{layers}</div></div>')
    jh = 250; jw = JW * jh / JH
    gy = 330
    hop = (f'<div class="sp-travel" style="position: absolute; left: 150px; top: {gy - jh}px; width: {jw:.0f}px; height: {jh}px;">'
           f'<div class="sp-hop" role="img" aria-label="Hop to the next word" style="width: {jw:.0f}px; height: {jh}px; background-image: url(./collage/sprites/hare-hop.webp); '
           f'background-size: {jw * 8:.0f}px {jh}px; background-repeat: no-repeat;"></div></div>')
    words = word(260, gy + 18, "the") + word(640, gy + 18, "hill")
    row1 = (f'<div style="display: flex; gap: 24px;">'
            f'<div style="display: flex; flex-direction: column; gap: 8px;">{stage(idle, 560, 400)}{lab("Idle", "10 drawings · slow breathing, blinks, an ear flick, a head tilt and a sniff eased in and out over an 18 s cycle")}</div>'
            f'<div style="display: flex; flex-direction: column; gap: 8px;">{stage(words + hop, 904, 400)}{lab("Hop to the next word", "8 frames at 14 fps · crouch, push-off, stretch, reach, front paws land, hind feet swing through, settle")}</div></div>')
    def sheet(src, n, fw, fh, h, title, sub):
        w = fw * h / fh * n
        return (f'<div style="display: flex; flex-direction: column; gap: 8px;"><div style="width: {W}px; height: {h + 20}px; border-radius: 18px; background: #E4EEDC; display: flex; align-items: center; justify-content: center;">'
                f'<img src="./collage/sprites/{src}" alt="" style="width: {min(w, W - 20):.0f}px; display: block;"></div>{lab(title, sub)}</div>')
    ks = sheet("hare-idle-frames.webp", NF, IW, IH, 200, "Idle drawings", "rest, sniff, ear back, eyes closed, head tilt + in-betweens: half blink, ear ¼ and ½, tilt ¼ and ½")
    hs = sheet("hare-hop.webp", 8, JW, JH, 170, "Hop sheet", "body-centred frames; the game moves the hare one word forward during frames 2–7")
    note = (f'<div style="font-family: Fredoka, sans-serif; font-weight: 500; font-size: 15px; line-height: 1.5; color: {INK}; background: {PAPER}; border: 5px solid #FFFFFF; border-radius: 20px; '
            f'padding: 16px 18px; box-shadow: 0 3px 8px rgba(60,40,20,0.22);"><b style="font-family: Fraunces, serif;">For SpriteKit:</b> each strip slices into an SKTextureAtlas (hare-idle, hare-hop); '
            f'frame sizes and timing are in <code>Design/collage/sprites/sprites.json</code>. Play idle with repeatForever; on a recognised word, run hop once while an SKAction.moveBy carries the node to the next word, then return to idle. '
            f'Generated from two Nano Banana 2 sheets, drawn from the same reference hare so he stays on-model.</div>')
    head = (f'<div style="display: flex; align-items: baseline; gap: 16px;"><div style="font-family: Fraunces, serif; font-weight: 700; font-size: 36px; color: {INK};">The hare · sprite sheets</div>'
            f'<div style="font-family: Fredoka, sans-serif; font-size: 16px; color: {MUTED};">a calm idle while waiting · a playful hop when a word is heard</div></div>')
    return f'<div style="position: absolute; left: 56px; top: 44px; width: {W}px; display: flex; flex-direction: column; gap: 24px;">{head}{row1}{ks}{hs}{note}</div>', iw, jw
if __name__ == "__main__":
    b, iw, jw = body()
    T = TL["loop_seconds"]
    EVENTS = {}
    for ev in TL["timeline"]:
        t = ev["at"]
        for fr in ev["frames"]:
            EVENTS.setdefault(fr["frame"], []).append((t, t + fr["hold"])); t += fr["hold"]
    def kf(spans):
        pts = [(0, 0)]
        for a0, a1 in sorted(spans):
            f = min(0.05, (a1 - a0) / 3)
            pts += [(a0 - 0.02, 0), (a0 + f, 1), (a1 - f, 1), (a1 + 0.02, 0)]
        pts += [(T, 0)]
        return " ".join(f"{t / T * 100:.3f}% {{ opacity: {o}; }}" for t, o in pts)
    css = "".join(f".sp-ev{k} {{ animation: spEv{k} {T}s linear infinite; }} @keyframes spEv{k} {{ {kf(v)} }}\n" for k, v in EVENTS.items())
    css += (".sp-breathe { animation: spBreathe 3.8s ease-in-out infinite; } "
            "@keyframes spBreathe { 0%, 100% { transform: scale(1, 1); } 45% { transform: scale(1.006, 1.014); } }\n")
    css += (''
           f".sp-hop {{ animation: spHop 2.4s steps(1) infinite; }}\n"
           "@keyframes spHop { " + " ".join(f"{p}% {{ background-position-x: -{jw * k:.0f}px; }}" for p, k in
                                            [(0, 0), (8, 0), (12, 1), (16, 2), (20, 3), (24, 4), (28, 5), (32, 6), (36, 7), (100, 7)]) + " }\n"
           ".sp-travel { animation: spTravel 2.4s cubic-bezier(0.4, 0, 0.3, 1) infinite; }\n"
           "@keyframes spTravel { 0%, 10% { transform: translateX(0px); } 36% { transform: translateX(380px); } 88% { transform: translateX(380px); opacity: 1; } 94% { transform: translateX(380px); opacity: 0; } 95% { transform: translateX(0px); opacity: 0; } 100% { transform: translateX(0px); opacity: 1; } }\n"
           "@media (prefers-reduced-motion: reduce) { .sp-breathe, [class^=sp-ev], .sp-hop, .sp-travel { animation: none; } }\n")
    doc = dc_doc("Hop Tales · hare sprite sheets", 1600, 1220, b, "#F4EBD8", STATIC_LOGIC, css)
    doc = doc.replace("family=Andika:wght@700&amp;", "family=Young+Serif&amp;")
    open(os.path.join(PROJ, "CollageSprites.dc.html"), "w").write(doc)
    preview("CollageSprites.html", 1600, 1220, b, "#F4EBD8")
    q = os.path.join(os.path.dirname(os.path.abspath(__file__)), "out", "CollageSprites.html")
    t = open(q).read().replace("</style>", css + "</style>", 1).replace("url(./collage", f"url(file://{PROJ}/collage")
    open(q, "w").write(t)
    print("ok")
