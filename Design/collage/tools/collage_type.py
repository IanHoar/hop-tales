import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from collage_boards import *

OPTS = [
    ("A", "Storybook serif", "Young Serif", 400, "Fraunces", 700, "Chosen. Reads like a printed picture book, and still has the single-storey a and g early readers are taught.", True),
    ("B", "Friendly hand", "Playpen Sans", 600, "Fraunces", 700, "Rounded hand-drawn letters, single-storey a and g. Playful, but less bookish next to the watercolour.", True),
    ("C", "School print", "Edu SA Beginner", 600, "Young Serif", 400, "A real classroom handwriting model. Very authentic for learning, but the slant makes big single words harder to scan.", True),
    ("D", "Classic book", "Literata", 600, "Alegreya", 700, "The most literary look, but double-storey a and g — the letter shapes differ from what he learns to write.", False),
]
FONT_LINK = ('<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Fraunces:opsz,wght@9..144,700&amp;family=Young+Serif&amp;'
             'family=Playpen+Sans:wght@600&amp;family=Edu+SA+Beginner:wght@600&amp;family=Literata:opsz,wght@7..72,600&amp;family=Alegreya:wght@700&amp;'
             'family=Fredoka:wght@500;600&amp;display=swap">')


def tile(o):
    key, name, wf, ww, tf, tw, note, infant = o
    W, H = 344, 520
    s = 1.02
    bgw = MEADOW_W * (H / MEADOW_H)
    bg = f'<img src="./collage/meadow.jpg" alt="" style="position: absolute; left: {-(820 * H / MEADOW_H - 160):.0f}px; top: 0px; width: {bgw:.0f}px; height: {H}px;">'
    title = (f'<div style="position: absolute; left: 18px; top: 18px; filter: drop-shadow(0 2px 3px rgba(60,40,20,0.3));"><div style="padding: 7px 16px 8px; {PAPER_BG} clip-path: {deckle(24, 6, 5)}; '
             f'transform: rotate(-2deg); font-family: \'{tf}\', serif; font-weight: {tw}; font-size: 18px; color: {INK};">The Meadow Walk</div></div>')
    cy, ch = 300, 150
    words = [("hare", "read"), ("ran", "now"), ("up", "next")]
    ws = "".join(
        f'<div style="position: relative; font-family: \'{wf}\', sans-serif; font-weight: {ww}; line-height: 1; font-size: {58 if st == "now" else 32}px; color: {MUTED if st == "next" else INK};">'
        + (f'<span style="position: absolute; left: -10px; right: -10px; top: 4px; bottom: 0px; border-radius: 40% 55% 45% 60%; background: radial-gradient(ellipse at 50% 55%, rgba(247,215,116,0.95) 0%, rgba(247,215,116,0.75) 55%, rgba(247,215,116,0) 72%);"></span>' if st == "read" else "")
        + f'<span style="position: relative;">{t}</span></div>' for t, st in words)
    card = (f'<div style="position: absolute; left: 12px; top: {cy}px; width: {W - 24}px; height: {ch}px; filter: drop-shadow(0 5px 7px rgba(60,40,20,0.3));">'
            f'<div style="position: absolute; inset: 0; {PAPER_BG} clip-path: {deckle(40, 1.6, 9)};"></div>'
            f'<div style="position: absolute; left: 0px; top: 0px; width: {W - 24}px; height: {ch - 30}px; display: flex; align-items: center; justify-content: center; gap: 30px;">{ws}</div>'
            f'<div style="position: absolute; left: 0px; bottom: 16px; width: {W - 24}px; text-align: center; font-family: \'{wf}\', sans-serif; font-weight: {ww}; font-size: 17px; color: {MUTED};">a g · ball · dog · hill</div></div>')
    hs = 128 / SIT_H
    hare = (f'<img src="./collage/hare-sit.png" alt="" style="position: absolute; left: {W / 2 - 232 * hs:.0f}px; top: {cy + 12 - 128}px; width: {SIT_W * hs:.0f}px; height: 128px; '
            f'filter: drop-shadow(0 4px 5px rgba(60,40,20,0.25));">')
    mic = (f'<div style="position: absolute; left: 50%; top: {H - 64}px; transform: translateX(-50%); white-space: nowrap; padding: 8px 20px; border-radius: 999px; {PAPER_BG} '
           f'border: 4px solid #FFFFFF; box-shadow: 0 3px 8px rgba(60,40,20,0.3); font-family: \'{tf}\', serif; font-weight: {tw}; font-size: 17px; color: {INK};">Say the word</div>')
    scene = f'<div style="position: relative; width: {W}px; height: {H}px; overflow: hidden; border-radius: 22px; border: 5px solid #FFFFFF; box-shadow: 0 4px 10px rgba(60,40,20,0.25);">{bg}{title}{card}{hare}{mic}</div>'
    badge = (f'<span style="align-self: flex-start; font-family: Fredoka, sans-serif; font-weight: 600; font-size: 13px; padding: 3px 10px; border-radius: 999px; '
             f'background: {"#E3EDD8" if infant else "#F3DDD5"}; color: {"#46613A" if infant else "#8A3A2E"};">{"single-storey a · g" if infant else "double-storey a · g"}</span>')
    meta = (f'<div style="display: flex; flex-direction: column; gap: 8px; width: {W + 10}px;">'
            f'<div style="display: flex; align-items: baseline; gap: 10px;"><span style="font-family: Fraunces, serif; font-weight: 700; font-size: 22px; color: {INK};">{key} · {name}</span></div>'
            f'<div style="font-family: Fredoka, sans-serif; font-weight: 600; font-size: 14px; color: {INK};">Words: {wf} · Titles and buttons: {tf}</div>{badge}'
            f'<div style="font-family: Fredoka, sans-serif; font-weight: 500; font-size: 14px; line-height: 1.45; color: {MUTED};">{note}</div></div>')
    return f'<div style="display: flex; flex-direction: column; gap: 16px;">{scene}{meta}</div>'


def body():
    head = (f'<div style="display: flex; align-items: baseline; gap: 16px;"><div style="font-family: Fraunces, serif; font-weight: 700; font-size: 38px; color: {INK};">Type for the collage storybook</div>'
            f'<div style="font-family: Fredoka, sans-serif; font-size: 16px; color: {MUTED};">four pairings on the same reading card · all free Google Fonts (OFL)</div></div>')
    row = '<div style="display: flex; gap: 30px;">' + "".join(tile(o) for o in OPTS) + "</div>"
    return f'<div style="position: absolute; left: 56px; top: 50px; width: 1488px; display: flex; flex-direction: column; gap: 30px;">{head}{row}</div>'


if __name__ == "__main__":
    b = body()
    doc = dc_doc("Hop Tales · collage type options", 1600, 860, b, "#F4EBD8", STATIC_LOGIC).replace(FONTS, FONT_LINK)
    open(os.path.join(PROJ, "CollageType.dc.html"), "w").write(doc)
    preview("CollageType.html", 1600, 860, b, "#F4EBD8")
    print("ok")
