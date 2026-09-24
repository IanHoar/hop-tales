import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from collage_boards import INK, MUTED, PAPER, PAPER_BG, RED, SAGE, WASH, dc_doc, deckle, CSS as BASE_CSS
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
P = os.path.join(HERE, "..", "collage-canvas", "project")
APP_STORE = "https://apps.apple.com/app/id[APP_ID]"
SAGE_BG = "#A6BA92"
CREAM = "#F4EBD8"
NIGHT = "#1E2A4E"
STATIC = "class Component extends DCLogic {\n  renderVals() {\n    return {};\n  }\n}"


def dims(p):
    return Image.open(os.path.join(P, p)).size


def serif(size, color=INK, extra=""):
    return f"font-family: Fraunces, Georgia, serif; font-weight: 700; font-size: {size}px; line-height: 1.08; color: {color}; {extra}"


def body(size=18, color=INK, extra=""):
    return f"font-family: Fredoka, sans-serif; font-weight: 500; font-size: {size}px; line-height: 1.55; color: {color}; {extra}"


def paper_card(inner, pad="22px 24px", extra="", seed=9):
    return (f'<div style="position: relative; filter: drop-shadow(0 4px 7px rgba(60,40,20,0.26)); {extra}">'
            f'<div style="position: absolute; inset: 0; {PAPER_BG} clip-path: {deckle(40, 1.2, seed)};"></div>'
            f'<div style="position: relative; padding: {pad};">{inner}</div></div>')


def label(text, size=20, rot=-2, seed=5):
    return (f'<div style="display: inline-block; filter: drop-shadow(0 2px 3px rgba(60,40,20,0.28));"><div style="padding: 8px 18px 10px; {PAPER_BG} '
            f'clip-path: {deckle(24, 6, seed)}; transform: rotate({rot}deg); {serif(size)} white-space: nowrap;">{text}</div></div>')


def icon(s, radius=None):
    r = radius if radius is not None else s * 0.225
    return (f'<img src="./collage/brand/icon-v-1024.png" alt="Hop Tales app icon" style="width: {s}px; height: {s}px; border-radius: {r:.0f}px; display: block; '
            f'box-shadow: 0 3px 8px rgba(40,30,20,0.25); flex-shrink: 0;">')


def store_badge(h=54):
    # stand-in for Apple's official badge
    return (f'<a href="{APP_STORE}" style="display: inline-flex; align-items: center; gap: 10px; height: {h}px; padding: 0 {h * 0.4:.0f}px 0 {h * 0.3:.0f}px; border-radius: {h * 0.22:.0f}px; '
            f'background: #1B1714; text-decoration: none; box-shadow: 0 3px 8px rgba(40,30,20,0.3);">'
            f'<svg width="{h * 0.42:.0f}" height="{h * 0.42:.0f}" viewBox="0 0 24 24" aria-hidden="true"><path d="M12 4 V15 M7 10.5 L12 15.5 L17 10.5 M5 20 H19" stroke="#F4EBD8" stroke-width="2.4" fill="none" stroke-linecap="round" stroke-linejoin="round"></path></svg>'
            f'<span style="display: flex; flex-direction: column;"><span style="{body(h * 0.21, "#F4EBD8", "line-height: 1.1;")}">Download on the</span>'
            f'<span style="{serif(h * 0.4, "#F4EBD8", "line-height: 1.05;")}">App Store</span></span></a>')


def phone(src, w, rot=0):
    h = w * 844 / 390
    return (f'<div style="width: {w}px; height: {h:.0f}px; flex-shrink: 0; border-radius: {w * 0.13:.0f}px; border: {max(5, w // 38)}px solid #FFFFFF; overflow: hidden; '
            f'box-shadow: 0 10px 26px rgba(40,30,20,0.3); transform: rotate({rot}deg); background: #FFFFFF;">'
            f'<img src="./collage/shots/{src}" alt="" style="width: 100%; height: 100%; display: block; object-fit: cover;"></div>')


def world(w, h, src="world-golden.jpg", pos="center"):
    path = "./collage/meadow.jpg" if src == "meadow" else f"./collage/shots/{src}"
    return f'<img src="{path}" alt="" style="position: absolute; inset: 0; width: {w}px; height: {h}px; object-fit: cover; object-position: {pos};">'


STEPS = [("1", "Say the word", "A big word sits on the paper card. Your child reads it out loud, and Hop Tales listens right on the device."),
         ("2", "The hare hops", "Heard it! The hare bounds to the next word, and the last one is washed in gold."),
         ("3", "The world changes", "Word by word the story walks on: clouds gather, rain falls, the sun sets and the moon comes up.")]
FEATURES = [("Private by design", "Speech is recognised on the device. No audio is recorded, stored or sent anywhere."),
            ("Made for new readers", "Big, calm words in a clear storybook typeface, one at a time."),
            ("Never a wrong answer", "Listening is forgiving. If a word gets stuck, the hare waits patiently and helps."),
            ("No ads, no sign-ups", "Nothing to click away to and no account to make. Open it, pick a story, read.")]
STORIES = [("phone-read.jpg", "The Meadow Walk", "a sunny morning"), ("phone-storm.jpg", "Storm on the Hill", "clouds and rain"),
           ("phone-golden.jpg", "Golden Hour", "the long way home"), ("phone-night.jpg", "Moonlight Hop", "a bedtime story")]


def nav(w, pad, mobile=False):
    links = "" if mobile else "".join(f'<a href="{h}" style="{body(17, INK, "font-weight: 600; text-decoration: none;")}">{t}</a>'
                                      for t, h in (("How it works", "#how"), ("For grown-ups", "#parents"), ("Privacy", "privacy.html"), ("Terms", "terms.html")))
    right = (f'<div style="display: flex; align-items: center; gap: 28px;">{links}{store_badge(46)}</div>' if not mobile
             else f'<a href="{APP_STORE}" style="{body(15, "#F4EBD8", "font-weight: 600; text-decoration: none;")} background: #1B1714; padding: 9px 16px; border-radius: 12px;">Get the app</a>')
    return (f'<div style="position: absolute; left: {pad}px; top: 22px; width: {w - 2 * pad}px; display: flex; align-items: center; justify-content: space-between;">'
            f'<a href="#" style="display: flex; align-items: center; gap: 12px; text-decoration: none;">{icon(46 if not mobile else 38)}'
            f'<span style="{serif(28 if not mobile else 22)}">Hop Tales</span></a>{right}</div>')


def footer(w, pad, mobile=False):
    lk = lambda t, h: f'<a href="{h}" style="{body(16, "#F4EBD8", "font-weight: 600; text-decoration: underline; text-underline-offset: 4px;")}">{t}</a>'
    return (f'<footer style="width: {w}px; box-sizing: border-box; padding: 40px {pad}px; background: #2E2620; display: flex; '
            f'{"flex-direction: column; gap: 18px;" if mobile else "align-items: center; justify-content: space-between;"}">'
            f'<div style="display: flex; align-items: center; gap: 12px;">{icon(40)}<span style="{serif(24, "#F4EBD8")}">Hop Tales</span></div>'
            f'<div style="display: flex; gap: 24px; align-items: center; flex-wrap: wrap;">{lk("Privacy Policy", "privacy.html")}{lk("Terms of Service", "terms.html")}{lk("Download", APP_STORE)}'
            f'<span style="{body(14, "#B9AE9C")}">© 2026 Hop Tales</span></div></footer>')


def desktop():
    W, pad = 1440, 80
    hw, hh = dims("collage/hare-bound.png")
    hero = (f'<section style="position: relative; width: {W}px; height: 820px; overflow: hidden;">{world(W, 820, "meadow", "60% 60%")}'
            f'<div style="position: absolute; inset: 0; background: linear-gradient(90deg, rgba(244,235,216,0.92) 0%, rgba(244,235,216,0.7) 38%, rgba(244,235,216,0) 62%);"></div>'
            f'{nav(W, pad)}'
            f'<div style="position: absolute; left: {pad}px; top: 190px; width: 600px; display: flex; flex-direction: column; gap: 24px; align-items: flex-start;">'
            f'{label("A read-aloud adventure", 18)}'
            f'<h1 style="margin: 0; {serif(76)}">Read a word.<br>Watch him hop.</h1>'
            f'<p style="margin: 0; {body(21, "#4A3F36")} max-width: 520px;">Hop Tales listens while your child reads aloud. Every word they say carries the hare a little further through a storybook meadow that changes as the story goes.</p>'
            f'<div style="display: flex; align-items: center; gap: 18px;">{store_badge(58)}<span style="{body(15, MUTED)}">iPhone &amp; iPad<br>Plays on your TV with AirPlay</span></div></div>'
            f'<img src="./collage/hare-bound.png" alt="" style="position: absolute; left: 690px; top: 470px; width: 430px; height: {470 * hh / hw:.0f}px; transform: rotate(-6deg); filter: drop-shadow(0 10px 12px rgba(40,30,20,0.3));">'
            f'<div style="position: absolute; left: 1160px; top: 150px;">{phone("phone-read.jpg", 220, 5)}</div></section>')
    steps = "".join(paper_card(f'<div style="display: flex; flex-direction: column; gap: 12px;"><div style="{serif(44, RED)}">{n}</div>'
                               f'<div style="{serif(28)}">{t}</div><p style="margin: 0; {body(17, "#4A3F36")}">{x}</p></div>', "30px 30px 34px", "width: 400px;", 10 + i)
                    for i, (n, t, x) in enumerate(STEPS))
    how = (f'<section id="how" style="width: {W}px; box-sizing: border-box; padding: 110px {pad}px; background: {CREAM}; display: flex; flex-direction: column; align-items: center; gap: 54px;">'
           f'<div style="display: flex; flex-direction: column; align-items: center; gap: 12px;"><h2 style="margin: 0; {serif(54)}">How it works</h2>'
           f'<p style="margin: 0; {body(20, MUTED)}">Three beats, over and over, until the story is done.</p></div>'
           f'<div style="display: flex; gap: 40px;">{steps}</div></section>')
    cards = "".join(f'<div style="display: flex; flex-direction: column; align-items: center; gap: 18px;">{phone(s, 230, r)}'
                    f'<div style="text-align: center;"><div style="{serif(24)}">{t}</div><div style="{body(16, MUTED)}">{sub}</div></div></div>'
                    for (s, t, sub), r in zip(STORIES, (-3, 1, -1, 3)))
    stories = (f'<section style="width: {W}px; box-sizing: border-box; padding: 100px {pad}px 110px; background: {SAGE_BG}; display: flex; flex-direction: column; align-items: center; gap: 50px;">'
               f'<div style="display: flex; flex-direction: column; align-items: center; gap: 12px;"><h2 style="margin: 0; {serif(54)}">A world that keeps going</h2>'
               f'<p style="margin: 0; {body(20, "#33402B")} max-width: 720px; text-align: center;">The meadow never runs out. Morning turns to golden hour, storms roll in and clear, and the moon rises, so every story feels like its own little journey.</p></div>'
               f'<div style="display: flex; gap: 46px;">{cards}</div></section>')
    tv = (f'<section style="width: {W}px; box-sizing: border-box; padding: 110px {pad}px; background: {CREAM}; display: flex; align-items: center; gap: 70px;">'
          f'<div style="width: 440px; display: flex; flex-direction: column; gap: 18px;"><h2 style="margin: 0; {serif(50)}">Play it on the big screen</h2>'
          f'<p style="margin: 0; {body(19, "#4A3F36")}">AirPlay Hop Tales to your Apple TV. The phone stays in your child\'s hands and does the listening, while the TV shows the whole meadow.</p></div>'
          f'<div style="border: 12px solid #FFFFFF; border-radius: 22px; overflow: hidden; box-shadow: 0 14px 34px rgba(40,30,20,0.3);">'
          f'<img src="./collage/shots/tv.jpg" alt="Hop Tales on an Apple TV" style="width: 760px; height: 428px; display: block; object-fit: cover;"></div></section>')
    feats = "".join(paper_card(f'<div style="{serif(24)}">{t}</div><p style="margin: 8px 0 0; {body(17, "#4A3F36")}">{x}</p>', "26px 28px 28px", "", 20 + i) for i, (t, x) in enumerate(FEATURES))
    parents = (f'<section id="parents" style="width: {W}px; box-sizing: border-box; padding: 20px {pad + 100}px 120px; background: {CREAM}; display: flex; flex-direction: column; gap: 40px;">'
               f'<h2 style="margin: 0; text-align: center; {serif(50)}">For grown-ups</h2>'
               f'<div style="display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 28px;">{feats}</div></section>')
    cta = (f'<section style="position: relative; width: {W}px; height: 560px; overflow: hidden;">{world(W, 560, "world-night.jpg", "center 60%")}'
           f'<div style="position: absolute; inset: 0; background: linear-gradient(90deg, rgba(20,26,52,0.75) 0%, rgba(20,26,52,0.3) 50%, rgba(20,26,52,0) 75%);"></div>'
           f'<div style="position: absolute; left: {pad}px; top: 150px; width: 620px; display: flex; flex-direction: column; gap: 22px; align-items: flex-start;">'
           f'<h2 style="margin: 0; {serif(62, "#FBF4E4")}">Ready for a story?</h2>'
           f'<p style="margin: 0; {body(20, "#E6E0F2")}">Download Hop Tales and read the first one together tonight.</p>{store_badge(62)}</div></section>')
    return f'<div style="width: {W}px; display: flex; flex-direction: column; background: {CREAM};">{hero}{how}{stories}{tv}{parents}{cta}{footer(W, pad)}</div>'


def mobile():
    W, pad = 390, 20
    hw, hh = dims("collage/hare-bound.png")
    hero = (f'<section style="position: relative; width: {W}px; height: 780px; overflow: hidden;">{world(W, 780, "meadow", "35% 60%")}'
            f'<div style="position: absolute; inset: 0; background: linear-gradient(rgba(244,235,216,0.95) 0%, rgba(244,235,216,0.8) 48%, rgba(244,235,216,0) 72%);"></div>'
            f'{nav(W, pad, True)}'
            f'<div style="position: absolute; left: {pad}px; top: 110px; width: {W - 2 * pad}px; display: flex; flex-direction: column; gap: 16px; align-items: flex-start;">'
            f'{label("A read-aloud adventure", 15)}<h1 style="margin: 0; {serif(41)}">Read a word.<br>Watch him hop.</h1>'
            f'<p style="margin: 0; {body(17, "#4A3F36")}">Every word your child reads aloud carries the hare a little further through a storybook meadow.</p>{store_badge(52)}</div>'
            f'<img src="./collage/hare-bound.png" alt="" style="position: absolute; left: 60px; top: 560px; width: 280px; height: {280 * hh / hw:.0f}px; transform: rotate(-6deg); filter: drop-shadow(0 8px 10px rgba(40,30,20,0.3));"></section>')
    steps = "".join(paper_card(f'<div style="display: flex; align-items: baseline; gap: 12px;"><span style="{serif(32, RED)}">{n}</span><span style="{serif(24)}">{t}</span></div>'
                               f'<p style="margin: 8px 0 0; {body(16, "#4A3F36")}">{x}</p>', "22px 22px 24px", "", 10 + i) for i, (n, t, x) in enumerate(STEPS))
    how = (f'<section id="how" style="width: {W}px; box-sizing: border-box; padding: 56px {pad}px; background: {CREAM}; display: flex; flex-direction: column; gap: 22px;">'
           f'<h2 style="margin: 0; {serif(36)}">How it works</h2>{steps}</section>')
    fan = (f'<div style="position: relative; width: {W - 2 * pad}px; height: 380px;">'
           f'<div style="position: absolute; left: 0px; top: 30px;">{phone("phone-storm.jpg", 150, -7)}</div>'
           f'<div style="position: absolute; right: 0px; top: 30px;">{phone("phone-night.jpg", 150, 7)}</div>'
           f'<div style="position: absolute; left: {(W - 2 * pad - 164) / 2:.0f}px; top: 0px;">{phone("phone-read.jpg", 164, 0)}</div></div>')
    stories = (f'<section style="width: {W}px; box-sizing: border-box; padding: 56px {pad}px; background: {SAGE_BG}; display: flex; flex-direction: column; gap: 20px;">'
               f'<h2 style="margin: 0; {serif(36)}">A world that keeps going</h2>'
               f'<p style="margin: 0; {body(16, "#33402B")}">Morning turns to golden hour, storms roll in and clear, and the moon rises.</p>{fan}</section>')
    tv = (f'<section style="width: {W}px; box-sizing: border-box; padding: 56px {pad}px; background: {CREAM}; display: flex; flex-direction: column; gap: 16px;">'
          f'<h2 style="margin: 0; {serif(34)}">Play it on the big screen</h2><p style="margin: 0; {body(16, "#4A3F36")}">AirPlay to your Apple TV. The phone does the listening; the TV shows the whole meadow.</p>'
          f'<div style="border: 7px solid #FFFFFF; border-radius: 16px; overflow: hidden; box-shadow: 0 8px 20px rgba(40,30,20,0.28);">'
          f'<img src="./collage/shots/tv.jpg" alt="Hop Tales on an Apple TV" style="width: 336px; height: 189px; display: block; object-fit: cover;"></div></section>')
    feats = "".join(paper_card(f'<div style="{serif(21)}">{t}</div><p style="margin: 6px 0 0; {body(15, "#4A3F36")}">{x}</p>', "20px 22px 22px", "", 20 + i) for i, (t, x) in enumerate(FEATURES))
    parents = (f'<section id="parents" style="width: {W}px; box-sizing: border-box; padding: 8px {pad}px 60px; background: {CREAM}; display: flex; flex-direction: column; gap: 18px;">'
               f'<h2 style="margin: 0; {serif(34)}">For grown-ups</h2>{feats}</section>')
    cta = (f'<section style="position: relative; width: {W}px; height: 460px; overflow: hidden;">{world(W, 460, "world-night.jpg", "30% 60%")}'
           f'<div style="position: absolute; inset: 0; background: linear-gradient(rgba(20,26,52,0.8) 0%, rgba(20,26,52,0.2) 70%);"></div>'
           f'<div style="position: absolute; left: {pad}px; top: 56px; width: {W - 2 * pad}px; display: flex; flex-direction: column; gap: 16px; align-items: flex-start;">'
           f'<h2 style="margin: 0; {serif(40, "#FBF4E4")}">Ready for a story?</h2><p style="margin: 0; {body(16, "#E6E0F2")}">Read the first one together tonight.</p>{store_badge(52)}</div></section>')
    return f'<div style="width: {W}px; display: flex; flex-direction: column; background: {CREAM};">{hero}{how}{stories}{tv}{parents}{cta}{footer(W, pad, True)}</div>'


def home():
    W, H = 390, 844
    sw, sh = dims("collage/brand/hare-front-sit.png")
    hs = 150 / sh
    head = (f'<div style="position: absolute; left: 0px; top: 0px; width: {W}px; height: 380px; overflow: hidden;">{world(W, 380, "meadow", "30% 55%")}'
            f'<div style="position: absolute; left: 0px; bottom: 0px; width: {W}px; height: 90px; background: linear-gradient(rgba(244,235,216,0), {CREAM});"></div></div>'
            f'<div style="position: absolute; left: 20px; top: 58px; width: 350px; display: flex; align-items: center; justify-content: space-between;">'
            f'<div style="display: flex; align-items: center; gap: 10px;">{icon(40)}<span style="{serif(24)}">Hop Tales</span></div>'
            f'<button type="button" aria-label="Settings for grown-ups" style="width: 46px; height: 46px; border-radius: 50%; border: 4px solid #FFFFFF; {PAPER_BG} box-shadow: 0 3px 7px rgba(60,40,20,0.25); display: flex; align-items: center; justify-content: center; padding: 0;">'
            f'<svg width="20" height="20" viewBox="0 0 24 24" aria-hidden="true"><circle cx="12" cy="12" r="3.2" fill="none" stroke="{INK}" stroke-width="2"></circle><path d="M12 3v3M12 18v3M3 12h3M18 12h3M5.6 5.6l2.1 2.1M16.3 16.3l2.1 2.1M5.6 18.4l2.1-2.1M16.3 7.7l2.1-2.1" stroke="{INK}" stroke-width="2" stroke-linecap="round"></path></svg></button></div>'
            f'<img src="./collage/brand/hare-front-sit.png" alt="The hare" style="position: absolute; left: {W / 2 - sw * hs / 2 + 90:.0f}px; top: 196px; width: {sw * hs:.0f}px; height: 150px; filter: drop-shadow(0 5px 6px rgba(60,40,20,0.3));">'
            f'<div style="position: absolute; left: 20px; top: 200px;">{label("Good morning, [NAME]!", 20, -3, 7)}</div>')
    cont = (f'<a href="#" style="position: absolute; left: 20px; top: 360px; width: 350px; text-decoration: none; display: block;">'
            + paper_card(f'<div style="display: flex; align-items: center; gap: 12px;"><div style="width: 62px; height: 62px; border-radius: 12px; overflow: hidden; border: 4px solid #FFFFFF; flex-shrink: 0; box-shadow: 0 2px 5px rgba(60,40,20,0.2);">'
                         f'<img src="./collage/shots/phone-read.jpg" alt="" style="width: 100%; height: 100%; object-fit: cover; object-position: 50% 30%; display: block;"></div>'
                         f'<div style="flex-grow: 1; min-width: 0;"><div style="{body(12, MUTED, "font-weight: 600; letter-spacing: 0.06em; text-transform: uppercase;")}">Keep reading</div>'
                         f'<div style="{serif(19)} white-space: nowrap;">The Meadow Walk</div><div style="{body(14, MUTED)}">word 3 of 12</div></div>'
                         f'<span style="width: 46px; height: 46px; border-radius: 50%; background: {RED}; display: flex; align-items: center; justify-content: center; border: 4px solid #FFFFFF; box-shadow: 0 3px 6px rgba(60,40,20,0.3); flex-shrink: 0;">'
                         f'<svg width="20" height="20" viewBox="0 0 24 24" aria-hidden="true"><path d="M8 5 L19 12 L8 19 Z" fill="#FFFFFF"></path></svg></span></div>', "14px 14px", "", 31)
            + '</a>')
    rows = [("phone-storm.jpg", "Storm on the Hill", "14 words", "new"), ("phone-golden.jpg", "Golden Hour", "16 words", "done"), ("phone-night.jpg", "Moonlight Hop", "18 words", "")]
    def badge(k):
        if k == "new":
            return f'<span style="{body(12, "#FFFFFF", "font-weight: 600;")} background: {SAGE}; padding: 3px 10px; border-radius: 999px;">New</span>'
        if k == "done":
            return (f'<span style="display: flex; gap: 2px;">' + "".join(
                f'<svg width="16" height="16" viewBox="0 0 24 24" aria-hidden="true"><path d="M12 2.5 l2.8 6 6.5 0.7 -4.9 4.4 1.4 6.4 -5.8 -3.3 -5.8 3.3 1.4 -6.4 -4.9 -4.4 6.5 -0.7 z" fill="{WASH}" stroke="#B8862E" stroke-width="1.4"></path></svg>' for _ in range(3)) + '</span>')
        return ""
    lst = "".join(f'<a href="#" style="text-decoration: none; display: flex; align-items: center; gap: 14px; padding: 10px 12px; border-radius: 18px; background: rgba(255,255,255,0.55);">'
                  f'<div style="width: 58px; height: 58px; border-radius: 12px; overflow: hidden; border: 3px solid #FFFFFF; flex-shrink: 0;"><img src="./collage/shots/{s}" alt="" style="width: 100%; height: 100%; object-fit: cover; object-position: 50% 30%; display: block;"></div>'
                  f'<div style="flex-grow: 1;"><div style="{serif(19)}">{t}</div><div style="{body(13, MUTED)}">{m}</div></div>{badge(k)}</a>' for s, t, m, k in rows)
    stories = (f'<div style="position: absolute; left: 20px; top: 500px; width: 350px; display: flex; flex-direction: column; gap: 12px;">'
               f'<div style="{serif(22)}">More stories</div>{lst}</div>')
    return f'<div style="position: relative; width: {W}px; height: {H}px; overflow: hidden; background: {CREAM};">{head}{cont}{stories}</div>'


def write(name, title, w, h, content, bg):
    open(os.path.join(P, name), "w").write(dc_doc(title, w, h, content, bg, STATIC))
    prev = (f"<html><head><style>body{{margin:0;background:{bg}}}{BASE_CSS}</style></head><body>"
            + content.replace('src="./', f'src="file://{P}/') + "</body></html>")
    open(os.path.join(HERE, "out", name.replace(".dc.html", ".html")), "w").write(prev)


if __name__ == "__main__":
    write("CollageHome.dc.html", "Hop Tales · home", 390, 844, home(), CREAM)
    write("SiteDesktop.dc.html", "Hop Tales · site desktop", 1440, int(sys.argv[1]) if len(sys.argv) > 1 else 4200, desktop(), CREAM)
    write("SiteMobile.dc.html", "Hop Tales · site mobile", 390, int(sys.argv[2]) if len(sys.argv) > 2 else 3600, mobile(), CREAM)
    print("ok")
