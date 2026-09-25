"""Characters, collectibles, levels and dress-up - planning canvas boards."""
import os, sys, json
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import path_words as pw
from collage_boards import INK, MUTED, PAPER, PAPER_BG, RED, SAGE, WASH, deckle, sticker_box, dc_doc, STATIC_LOGIC, FONTS
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
P = os.path.abspath(os.path.join(HERE, "..", "cast-canvas", "project"))
M = json.load(open(os.path.join(P, "cast", "meta.json")))
pw.P = P
pw.END_EXTRA = 200
CREAM = "#F4EBD8"
SHADE = "#EFE3C8"
SKY = "linear-gradient(#BCDCEE, #DCEBEF 60%, #EEF2E6)"

FRIENDS = [
    # key, name, species, accent, collectible key, collectible name (plural), world, hop label, reading level
    ("bunny", "Bramble", "wild rabbit", "lilac ear bow", "strawberry", "wild strawberries", "Bluebell Wood", "round bounce", "Reading level 1"),
    ("hare", "Hare", "brown hare", "red knitted scarf", "carrot", "carrots", "The Meadow", "long bound", "Reading level 2"),
    ("frog", "Puddle", "common frog", "yellow neckerchief", "lily", "water lilies", "Willow Pond", "long leap", "Reading level 3"),
    ("crow", "Button", "carrion crow", "blue knitted cap", "button", "shiny buttons", "Harvest Field", "two-footed hop", "Reading level 4"),
    ("cat", "Marmalade", "ginger tabby cat", "sage ribbon collar", "yarn", "balls of wool", "Cottage Garden", "pounce and bound", "Reading level 5"),
    ("crab", "Nipper", "shore crab", "striped sailor neckerchief", "shell", "seashells", "Rock Pools", "sideways scuttle-hop", "Reading level 6"),
    ("grasshopper", "Sprig", "meadow grasshopper", "brown leather satchel", "clover", "clover leaves", "Tall Grass", "big spring", "Reading level 7"),
]
FR = {f[0]: f for f in FRIENDS}
# reading level -> (focus, example words, sentences, steps to fill the path to the next friend)
TIERS = {
    "bunny": ("short vowels, 3-letter words", "sat · hop · red · bug", "3 to 5 words", 300),
    "hare": ("blends and digraphs", "frog · ship · hill · chat", "5 to 7 words", 400),
    "frog": ("long vowels, magic e", "lake · kite · home · tune", "6 to 8 words", 500),
    "crow": ("vowel teams, two beats", "rain · boat · garden · paper", "7 to 9 words", 600),
    "cat": ("-ing, -ed, compound words", "jumping · sunflower · rested", "8 to 10 words", 700),
    "crab": ("longer words, tricky spellings", "because · beautiful · island", "9 to 12 words", 800),
    "grasshopper": ("big words, longer sentences", "adventure · enormous · whispered", "10 to 14 words", None),
}


def img(key):
    if key == "hare":
        return "./collage/hare-sit.png", Image.open(os.path.join(P, "collage", "hare-sit.png")).size
    return f"./cast/chars/{key}.png", tuple(M[key]["sit"])


def item(n):
    return f"./cast/items/{n}.png", tuple(M["items"][n])


def wear(n):
    return f"./cast/wear/{n}.png", tuple(M["wear"][n])


def fit(src_size, w=None, h=None):
    sw, sh = src_size
    s = min((w or 9e9) / sw, (h or 9e9) / sh)
    return sw * s, sh * s


def sticker(src, size, w=None, h=None, style="", alt=""):
    ww, hh = fit(size, w, h)
    return f'<img src="{src}" alt="{alt}" style="width: {ww:.0f}px; height: {hh:.0f}px; display: block; {style}">'


def T(txt, size=16, weight=500, fam="Fredoka", color=INK, extra=""):
    ff = {"Fredoka": "Fredoka, sans-serif", "Fraunces": "Fraunces, Georgia, serif", "Young": "'Young Serif', Georgia, serif"}[fam]
    return f'<div style="font-family: {ff}; font-weight: {weight}; font-size: {size}px; line-height: 1.35; color: {color}; {extra}">{txt}</div>'


def head(title, sub, x=56, y=44, w=1560):
    return (f'<div style="position: absolute; left: {x}px; top: {y}px; width: {w}px;">'
            + T(title, 38, 700, "Fraunces") + T(sub, 16, 500, "Fredoka", MUTED, "margin-top: 6px;") + "</div>")


def paper(inner, w, h, seed=3, amp=1.6, pad=18, extra=""):
    return (f'<div style="position: relative; width: {w}px; height: {h}px; filter: drop-shadow(0 4px 7px rgba(60,40,20,0.24)); {extra}">'
            f'<div style="position: absolute; inset: 0; {PAPER_BG} clip-path: {deckle(40, amp, seed)};"></div>'
            f'<div style="position: absolute; left: {pad}px; top: {pad}px; right: {pad}px; bottom: {pad}px;">{inner}</div></div>')


def label(txt, size=18, rot=-2, seed=5):
    return (f'<div style="display: inline-block; filter: drop-shadow(0 2px 3px rgba(60,40,20,0.3));"><div style="padding: 7px 16px 8px; {PAPER_BG} clip-path: {deckle(24, 6, seed)}; '
            f'transform: rotate({rot}deg); font-family: Fraunces, Georgia, serif; font-weight: 700; font-size: {size}px; color: {INK}; white-space: nowrap;">{txt}</div></div>')


def btn(txt, primary=True, extra=""):
    if primary:
        return (f'<div style="display: inline-flex; align-items: center; justify-content: center; height: 50px; padding: 0 26px; border-radius: 999px; background: {RED}; '
                f'border: 4px solid #FFFFFF; box-shadow: 0 3px 8px rgba(60,40,20,0.3); font-family: Fraunces, Georgia, serif; font-weight: 700; font-size: 18px; color: #FFFFFF; white-space: nowrap; {extra}">{txt}</div>')
    return (f'<div style="display: inline-flex; align-items: center; justify-content: center; height: 50px; padding: 0 22px; border-radius: 999px; {PAPER_BG} '
            f'border: 4px solid #FFFFFF; box-shadow: 0 3px 8px rgba(60,40,20,0.25); font-family: Fraunces, Georgia, serif; font-weight: 700; font-size: 18px; color: {INK}; white-space: nowrap; {extra}">{txt}</div>')


def rosette(n, w=90):
    src, size = item("rosette")
    ww, hh = fit(size, w=w)
    return (f'<div style="position: relative; width: {ww:.0f}px; height: {hh:.0f}px;">{sticker(src, size, w=w)}'
            f'<div style="position: absolute; left: 0px; top: {hh * 0.13:.0f}px; width: {ww:.0f}px; text-align: center; font-family: Fraunces, Georgia, serif; font-weight: 700; '
            f'font-size: {w * 0.3:.0f}px; line-height: {ww * 0.62:.0f}px; color: {RED};">{n}</div></div>')


def ribbon(frac, w=220, h=16):
    return (f'<div style="position: relative; width: {w}px; height: {h}px; border-radius: 999px; background: {SHADE}; box-shadow: inset 0 1px 2px rgba(60,40,20,0.2); overflow: hidden;">'
            f'<div style="position: absolute; left: 0px; top: 0px; bottom: 0px; width: {frac * 100:.0f}%; background: {WASH}; border-right: 2px solid #E0B94E; '
            f'clip-path: polygon(0 0, 100% 0, 97% 30%, 100% 55%, 96% 80%, 100% 100%, 0 100%);"></div></div>')


def back_chip(x=18, y=58):
    return pw.back_chip().replace("left: 18px; top: 58px;", f"left: {x}px; top: {y}px;")


# ---------------------------------------------------------------- boards

def board_plan():
    W, H = 1680, 1180
    # the loop diagram
    steps = [("Read", "Every word read moves the friend along the path.", None),
             ("Collect", "Treats sit on the path. Landing on one picks it up.", "carrot"),
             ("Fill the basket", "Each level needs a few more treats than the last.", "basket"),
             ("Level up", "A rosette and a wrapped present.", "rosette"),
             ("Unlock", "Something to wear, a new story or a new friend.", None)]
    cx = [120, 420, 720, 1020, 1320]
    loop = [f'<svg width="1560" height="320" viewBox="0 0 1560 320" style="position: absolute; left: 0px; top: 0px;" aria-hidden="true">'
            f'<path d="M 240 110 H 300 M 540 110 H 600 M 840 110 H 900 M 1140 110 H 1200" stroke="{INK}" stroke-width="2.5" stroke-dasharray="2 7" stroke-linecap="round" fill="none"></path>'
            f'<path d="M 1400 190 C 1400 290, 180 300, 150 200" stroke="{INK}" stroke-width="2.5" stroke-dasharray="2 7" stroke-linecap="round" fill="none"></path>'
            + "".join(f'<path d="M {x} 103 l 9 7 -9 7" stroke="{INK}" stroke-width="2.5" fill="none" stroke-linecap="round" stroke-linejoin="round"></path>' for x in (293, 593, 893, 1193))
            + f'<path d="M 143 208 l 7 -9 7 9" stroke="{INK}" stroke-width="2.5" fill="none" stroke-linecap="round" stroke-linejoin="round"></path>'
            f'<text x="780" y="292" text-anchor="middle" font-family="Fredoka, sans-serif" font-size="15" fill="{MUTED}">dress up · meet a friend · read again</text></svg>']
    for (t, d, ic), x in zip(steps, cx):
        icon = ""
        if ic:
            s, z = item(ic)
            icon = f'<div style="position: absolute; right: -14px; top: -22px; transform: rotate(8deg);">{sticker(s, z, h=54)}</div>'
        elif t == "Read":
            s, z = img("hare")
            icon = f'<div style="position: absolute; right: -8px; top: -44px;">{sticker(s, z, h=74)}</div>'
        else:
            s, z = wear("straw")
            icon = f'<div style="position: absolute; right: -16px; top: -18px; transform: rotate(-8deg);">{sticker(s, z, w=70)}</div>'
        loop.append(f'<div style="position: absolute; left: {x - 100}px; top: 40px;">'
                    + paper(T(t, 21, 700, "Fraunces") + T(d, 14, 500, "Fredoka", INK, "margin-top: 4px;"), 220, 140, seed=x % 17) + icon + "</div>")
    loop_html = f'<div style="position: absolute; left: 56px; top: 150px; width: 1560px; height: 320px;">{"".join(loop)}</div>'

    def col(title, rows, x, w):
        body = "".join(f'<div style="display: flex; gap: 10px; margin-top: 9px;"><div style="flex: none; width: 7px; height: 7px; margin-top: 8px; border-radius: 50%; background: {RED};"></div>'
                       f'<div style="font-family: Fredoka, sans-serif; font-weight: 500; font-size: 15px; line-height: 1.45; color: {INK};">{r}</div></div>' for r in rows)
        return f'<div style="position: absolute; left: {x}px; top: 510px; width: {w}px;">' + T(title, 22, 700, "Fraunces") + body + "</div>"

    c1 = col("Collectibles", [
        "Each friend has one treat that suits them: carrots, strawberries, water lilies, buttons, wool, shells, clover.",
        "About one treat every three words, placed where the friend lands, so it's picked up in the same hop.",
        "A <b>golden</b> treat at the end of any sentence read without help. Rare, never required.",
        "Treats replace stars as what kids see. Keep counting words read for the grown-up screen."], 56, 360)
    c2 = col("Levels", [
        "Every friend has their own level, 1 to 10. It's a friendship level, not a test score.",
        "Level n needs 10 + 5n treats: 15 to reach level 2, 60 to reach level 10. That's about one level per story early on.",
        "Every level gives a present. Levels 3, 6 and 9 give that friend's signature item.",
        "Nothing ever goes down. No streaks to break, no timers, nothing to lose."], 456, 360)
    c3 = col("Friends and worlds", [
        "New friends join as more stories are read: Bramble after 2, then Puddle 4, Button 6, Marmalade 9, Nipper 12, Sprig 15.",
        "Each friend brings a world and 3 to 4 stories set in it. The friend in the story is the one who hops.",
        "Any story can be read with any friend who lives in its world. The meadow is shared by Hare and Bramble.",
        "A new friend arrives in its own moment on the path, never as a pop-up in the middle of a sentence."], 856, 360)
    c4 = col("Dress-up", [
        "One wardrobe shared by every friend, in four slots: hat, glasses, neck and back.",
        "Each item has an anchor on each friend (head, eyes, neck, back) with a scale, so one sticker fits every animal.",
        "What a friend is wearing shows on the path while reading, and on home.",
        "Grown-up rule: no shop, no purchases, no ads. Everything is unlocked by reading."], 1256, 370)
    phases = [("1 · Treats", "Carrots on the path, the basket chip, golden carrots, the tally at The end. Hare only."),
              ("2 · Levels and wardrobe", "Level ribbon, the level-up moment, the wardrobe with the first 6 hats, what's worn shows while reading."),
              ("3 · Friends", "The friends screen, Bramble and Bluebell Wood, the new-friend moment, the collection book."),
              ("4 · One friend at a time", "Puddle, Button, Marmalade, Nipper, Sprig: world, hop sheet, treat and 3 to 4 stories each.")]
    build = (f'<div style="position: absolute; left: 56px; top: 800px; width: 1568px;">' + T("Suggested build order", 22, 700, "Fraunces")
             + '<div style="display: flex; gap: 16px; margin-top: 12px;">'
             + "".join(f'<div style="flex: 1; padding: 14px 16px; border-radius: 16px; background: rgba(251,244,228,0.8);">{T(t, 17, 700, "Fraunces")}{T(d, 14, 500, "Fredoka", INK, "margin-top: 4px;")}</div>' for t, d in phases)
             + "</div></div>")
    notes = (f'<div style="position: absolute; left: 56px; top: 1000px; width: 1568px;">'
             + paper(T("Open questions", 19, 700, "Fraunces")
                     + T("1. Keep stars as a grown-up-only stat, or drop them entirely?  2. Can a friend be chosen per story, or does each world have its own friend?  "
                         "3. Should levels also unlock story chapters (a longer adventure at level 5)?  4. Do we name the hare, or keep him simply Hare?  "
                         "5. How much to show while reading: a basket that appears only on pickup (shown here), or nothing until the end of the page?", 15, 500, "Fredoka", INK, "margin-top: 6px;"),
                     1568, 130, seed=11) + "</div>")
    b = head("How the new features fit together", "reading is still the only verb · everything else is a reward for it, and nothing can be lost") + loop_html + c1 + c2 + c3 + c4 + build + notes
    return "CastPlan", W, H, b, STATIC_LOGIC, "", "Plan · read, collect, level up, unlock"


def board_lineup():
    W, H = 1680, 720
    ground = 330
    heights = {"hare": 200, "bunny": 150, "frog": 118, "crow": 190, "cat": 200, "crab": 100, "grasshopper": 96}
    xs = [56 + i * 226 for i in range(7)]
    parts = [f'<div style="position: absolute; left: 40px; top: {ground + 4}px; width: 1600px; height: 3px; background: repeating-linear-gradient(90deg, rgba(59,42,32,0.35) 0 8px, transparent 8px 16px);"></div>']
    for (k, name, sp, acc, col, coln, world, hop, unlock), x in zip(FRIENDS, xs):
        s, z = img(k)
        ww, hh = fit(z, 200, heights[k])
        parts.append(f'<div style="position: absolute; left: {x + 100 - ww / 2:.0f}px; top: {ground - hh + 8:.0f}px;">{sticker(s, z, 200, heights[k], alt=name)}</div>')
        cs, cz = item(col)
        card = (T(name, 24, 700, "Fraunces") + T(sp, 14, 500, "Fredoka", MUTED)
                + f'<div style="display: flex; align-items: center; gap: 8px; margin-top: 10px;">{sticker(cs, cz, h=34)}{T(coln, 14, 600)}</div>'
                + T(f"<b>Wears:</b> {acc}", 13, 500, "Fredoka", INK, "margin-top: 8px;")
                + T(f"<b>Lives in:</b> {world}", 13, 500, "Fredoka", INK, "margin-top: 3px;")
                + T(f"<b>Moves:</b> {hop}", 13, 500, "Fredoka", INK, "margin-top: 3px;")
                + T(f"<b>Joins:</b> {unlock}", 13, 500, "Fredoka", INK, "margin-top: 3px;"))
        parts.append(f'<div style="position: absolute; left: {x}px; top: {ground + 40}px;">{paper(card, 206, 236, seed=x % 23)}</div>')
    note = T("On screen every friend sits at a similar size (the hare is about 124 pt), whatever their real size; each world is drawn at that friend's scale instead. "
             "Names are placeholders. Every design is original: natural anatomy, one small signature accessory in the palette, white sticker border.",
             15, 500, "Fredoka", MUTED, f"position: absolute; left: 56px; top: {ground + 300}px; width: 1560px;")
    b = head("New friends", "six more hoppers join the hare · each has a treat, a world and a way of moving") + "".join(parts) + note
    return "CastLineup", W, H, b, STATIC_LOGIC, "", "Cast · the new friends"


MOTION = {
    "frog": ("12 fps · 0.67 s", "Launch with the hind legs fully straight, body long in the air, front hands land first and the legs fold back in. Big arc, 90 pt."),
    "crow": ("12 fps · 0.67 s", "Crouch, spring with both feet together, wings open for balance, land feet first with wings up, then tuck and tilt the head. Arc 70 pt."),
    "cat": ("14 fps · 0.57 s", "Weight shifts back before the push. Long stretch with the tail streaming, front paws land, back arches, hind paws land close behind."),
    "crab": ("16 fps · 0.5 s", "Moves sideways, low and quick. Legs spread in the air, lands on the tips of the legs, then a little claw wave. Arc 60 pt."),
    "grasshopper": ("14 fps · 0.57 s", "Hind legs coil then snap straight for a steep launch. Wings flick open to glide, fold, and the front legs touch down. Highest arc, 130 pt."),
    "bunny": ("14 fps · 0.57 s", "Rounder and bouncier than the hare. Body stays compact, ears go back, the cottontail shows at the top. Arc 60 pt."),
}


def board_motion():
    W, H = 1680, 1830
    cw, ch = 760, 322
    cards = []
    css = []
    for i, k in enumerate(["frog", "crow", "cat", "crab", "grasshopper", "bunny"]):
        x = 56 + (i % 2) * (cw + 48)
        y = 140 + (i // 2) * 560
        fw, fh = M[k]["hop"]
        dh = 150
        dw = fw * dh / fh
        fps = int(MOTION[k][0].split()[0])
        dur = 8 / fps
        tot = dur + 0.9
        p = dur / tot * 100
        css.append(f".ms-{k} {{ animation: ms{k} {tot:.2f}s linear infinite; }}\n@keyframes ms{k} {{ 0% {{ background-position: 0px 0px; animation-timing-function: steps(8, end); }} "
                   f"{p:.1f}% {{ background-position: {-dw * 8:.0f}px 0px; }} {p + 0.01:.2f}% {{ background-position: 0px 0px; }} 100% {{ background-position: 0px 0px; }} }}")
        scene = (f'<div style="position: relative; width: {cw}px; height: {ch}px; border-radius: 18px; overflow: hidden; box-shadow: 0 0 0 5px #FFFFFF, 0 5px 12px rgba(60,40,20,0.25);">'
                 f'<img src="./cast/worlds/{k}.jpg" alt="" style="position: absolute; left: 0px; top: 0px; width: {cw}px; height: {ch}px; object-fit: cover;">'
                 f'<div style="position: absolute; left: {cw / 2 - dw / 2 - 60:.0f}px; top: {ch - dh - 18}px; width: {dw:.0f}px; height: {dh}px; background-image: url(./cast/sprites/{k}-hop.webp); '
                 f'background-size: {dw * 8:.0f}px {dh}px; filter: drop-shadow(0 3px 4px rgba(60,40,20,0.3));" class="ms-{k}"></div></div>')
        sw = 86
        sh = fh * sw / fw
        strip = "".join(f'<div style="position: relative; width: {sw}px; height: {sh:.0f}px; background-image: url(./cast/sprites/{k}-hop.webp); background-size: {sw * 8}px {sh:.0f}px; '
                        f'background-position: {-sw * j}px 0px;"><div style="position: absolute; left: 2px; bottom: -16px; font-family: Fredoka, sans-serif; font-size: 11px; color: {MUTED};">{j + 1}</div></div>'
                        for j in range(8))
        f = FR[k]
        cards.append(f'<div style="position: absolute; left: {x}px; top: {y}px; width: {cw}px;">{scene}'
                     f'<div style="display: flex; gap: 9px; margin-top: 16px; padding: 8px 10px 18px; border-radius: 12px; background: rgba(251,244,228,0.7);">{strip}</div>'
                     f'<div style="display: flex; gap: 16px; align-items: baseline; margin-top: 10px;">{T(f"{f[1]} · {f[7]}", 20, 700, "Fraunces")}{T(MOTION[k][0], 14, 600, "Fredoka", MUTED)}</div>'
                     + T(MOTION[k][1], 14, 500, "Fredoka", INK, "margin-top: 2px;") + "</div>")
    ctrl = (f'<button type="button" onClick="{{{{toggle}}}}" style="position: absolute; left: 1420px; top: 60px; display: flex; align-items: center; gap: 10px; padding: 10px 22px 10px 16px; '
            f'border-radius: 999px; {PAPER_BG} border: 4px solid #FFFFFF; box-shadow: 0 3px 8px rgba(60,40,20,0.28); cursor: pointer; font-family: Fraunces, Georgia, serif; font-weight: 700; font-size: 17px; color: {INK};">'
            f'<span style="width: 26px; height: 26px; border-radius: 50%; background: {SAGE}; color: #FFFFFF; display: flex; align-items: center; justify-content: center; font-size: 13px;">{{{{icon}}}}</span>{{{{label}}}}</button>')
    b = (f'<div class="{{{{cls}}}}" style="position: absolute; inset: 0;">' + head("Motion studies", "each friend has its own 8-frame move from word to word, in place while the ground slides · starts paused to keep the canvas light", w=1300)
         + ctrl + "".join(cards) + "</div>")
    logic = """
class Component extends DCLogic {
  constructor(props) { super(props); this.state = { play: false }; }
  renderVals() {
    const play = this.state.play;
    return {
      cls: play ? "" : "frozen",
      toggle: () => this.setState({ play: !this.state.play }),
      label: play ? "Pause motion" : "Play motion",
      icon: play ? "II" : "\\u25B6",
    };
  }
}
"""
    extra = "\n".join(css) + "\n.frozen, .frozen * { animation-play-state: paused !important; }\n"
    return "CastMotion", W, H, b, logic, extra, "Motion studies · tap Play motion"


WORLD_PATH = {  # y of the word line, y of the feet, as fractions of the card height
    "frog": (0.705, 0.70, "Words float on the lily pads; Puddle leaps pad to pad."),
    "crow": (0.875, 0.80, "Words are chalked on the stones of the wall; Button hops along the top."),
    "cat": (0.73, 0.62, "Words are painted on the brick face; Marmalade walks the top of the wall."),
    "crab": (0.86, 0.9, "Words are written in the wet sand; the tide smooths them after they're read."),
    "grasshopper": (0.9, 0.93, "An insect-height path; the words are pressed into the earth between pebbles."),
    "bunny": (0.93, 0.95, "A soft woodland path; the words sit in the earth like on the meadow path."),
}


def board_worlds():
    W, H = 1680, 1390
    cw, ch = 760, 322
    out = []
    words = ["one", "two", "three"]
    sample = {"frog": ["The", "frog", "can"], "crow": ["Up", "on", "the"], "cat": ["The", "cat", "sat"],
              "crab": ["A", "red", "crab"], "grasshopper": ["Hop", "up", "high"], "bunny": ["In", "the", "wood"]}
    chalk = ["#FBF4E4", "#FFFFFF", "rgba(251,244,228,0.6)"]
    for i, k in enumerate(["frog", "crow", "cat", "crab", "grasshopper", "bunny"]):
        x = 56 + (i % 2) * (cw + 48)
        y = 140 + (i // 2) * 410
        wy, fy, note = WORLD_PATH[k]
        s, z = img(k)
        hh = 92 if k not in ("crab", "grasshopper", "frog") else 64
        ww, hh2 = fit(z, h=hh)
        cs, cz = item(FR[k][4])
        ws = sample[k]
        wx = [290, 420, 640]
        wd = "".join(f'<div style="position: absolute; left: {x_}px; top: {wy * ch:.0f}px; transform: translate(-50%, -60%) perspective(260px) rotateX(22deg) scale({1 if j == 1 else 0.72}); '
                     f'font-family: \'Young Serif\', Georgia, serif; font-size: 40px; line-height: 1; color: {chalk[j] if k == "crow" else ("#2E2018" if j == 1 else ("#3B2A20" if j == 0 else "rgba(59,42,32,0.42)"))}; {"text-shadow: 0 1px 1px rgba(40,30,20,0.4);" if k == "crow" else "mix-blend-mode: multiply;"} white-space: nowrap;">'
                     + (f'<span style="position: absolute; left: -12px; right: -12px; top: 6px; bottom: -2px; border-radius: 42% 55% 45% 60%; {pw.WASH_BG}"></span>' if j == 0 else "")
                     + f'<span style="position: relative;">{t}</span></div>' for j, (t, x_) in enumerate(zip(ws, wx)))
        char = f'<div style="position: absolute; left: {215 - ww / 2:.0f}px; top: {fy * ch - hh2 + 6:.0f}px; filter: drop-shadow(0 3px 4px rgba(60,40,20,0.3));">{sticker(s, z, h=hh)}</div>'
        coll = f'<div style="position: absolute; left: 510px; top: {fy * ch - 40:.0f}px; transform: rotate(-8deg);">{sticker(cs, cz, h=40)}</div>'
        card = (f'<div style="position: relative; width: {cw}px; height: {ch}px; border-radius: 18px; overflow: hidden; box-shadow: 0 0 0 5px #FFFFFF, 0 5px 12px rgba(60,40,20,0.25);">'
                f'<img src="./cast/worlds/{k}.jpg" alt="" style="position: absolute; left: 0px; top: 0px; width: {cw}px; height: {ch}px; object-fit: cover;">{wd}{coll}{char}</div>')
        out.append(f'<div style="position: absolute; left: {x}px; top: {y}px; width: {cw}px;">{card}'
                   f'<div style="display: flex; gap: 14px; align-items: baseline; margin-top: 14px;">{T(FR[k][6], 21, 700, "Fraunces")}{T(FR[k][1] + "&#39;s world", 14, 600, "Fredoka", MUTED)}</div>'
                   + T(note, 14, 500, "Fredoka", INK, "margin-top: 2px;") + "</div>")
    b = head("Worlds for the new friends", "one painted postcard each, to set the look · each becomes a 3-layer endless world like the meadow, with the words on that world's own path") + "".join(out)
    return "CastWorlds", W, H, b, STATIC_LOGIC, "", "Worlds · where each friend lives"


def board_collect():
    W, H = 1680, 1000
    row = []
    for i, f in enumerate(FRIENDS):
        x = 56 + i * 226
        cs, cz = item(f[4])
        s, z = img(f[0])
        row.append(f'<div style="position: absolute; left: {x}px; top: 150px; width: 206px; height: 230px; border-radius: 18px; background: rgba(251,244,228,0.75);">'
                   f'<div style="position: absolute; left: 16px; top: 16px; opacity: 0.9;">{sticker(s, z, h=58)}</div>'
                   f'<div style="position: absolute; right: 18px; top: 34px; transform: rotate(6deg);">{sticker(cs, cz, h=96)}</div>'
                   f'<div style="position: absolute; left: 16px; top: 150px; width: 180px;">{T(f[5].capitalize(), 18, 700, "Fraunces")}{T(f[1], 13, 600, "Fredoka", MUTED)}</div></div>')
    gs, gz = item("carrot-gold")
    fs, fz = item("clover-four")
    bs, bz = item("basket")
    ss, sz = item("star")
    rares = (f'<div style="position: absolute; left: 56px; top: 420px; width: 700px;">' + T("Golden finds", 22, 700, "Fraunces")
             + T("A sentence read without tapping for help ends with a golden treat. It counts as 3, and it gets its own slot in the collection book.", 15, 500, "Fredoka", INK, "margin-top: 4px; width: 640px;")
             + f'<div style="display: flex; gap: 28px; align-items: flex-end; margin-top: 16px;">{sticker(gs, gz, h=120)}{sticker(fs, fz, h=110)}'
             + f'<div style="width: 96px; height: 110px; border-radius: 16px; border: 3px dashed rgba(59,42,32,0.3); display: flex; align-items: center; justify-content: center; text-align: center; font-family: Fredoka, sans-serif; font-size: 13px; color: {MUTED};">golden<br>strawberry,<br>shell, button…<br>to paint</div></div></div>')
    moments_data = [
        ("1 · Pick up", "The friend lands on the treat; it springs up and flies into a small basket that shows up top-right for a moment.", "carrot"),
        ("2 · Golden", "End of a sentence read without help: a golden treat sparkles on the path.", "carrot-gold"),
        ("3 · Tally", "At The end sign, the basket counts up and the level ribbon fills.", "basket"),
        ("4 · Level up", "Rosette, paper confetti and a wrapped present to open.", "rosette"),
        ("5 · Try it on", "The present goes straight into the wardrobe, with a Try it on button.", None),
        ("6 · New friend", "After enough stories, a new friend waits on the path at The end sign.", None),
    ]
    ms = []
    for i, (t, d, ic) in enumerate(moments_data):
        x = 56 + i * 262
        if ic == "rosette":
            icon = rosette(4, 84)
        elif ic:
            s_, z_ = item(ic)
            icon = sticker(s_, z_, h=80)
        elif t.startswith("5"):
            icon = sticker(f"./cast/dress/hare-straw.png", tuple(M["dress"]["straw"]), h=96)
        else:
            s_, z_ = img("bunny")
            icon = sticker(s_, z_, h=86)
        ms.append(f'<div style="position: absolute; left: {x}px; top: 740px; width: 240px;">'
                  f'<div style="height: 104px; display: flex; align-items: flex-end;">{icon}</div>'
                  + T(t, 19, 700, "Fraunces", INK, "margin-top: 12px;") + T(d, 14, 500, "Fredoka", INK, "margin-top: 3px;") + "</div>")
    lvl = (f'<div style="position: absolute; left: 820px; top: 420px; width: 800px;">' + T("The basket and the level ribbon", 22, 700, "Fraunces")
           + f'<div style="display: flex; gap: 26px; align-items: center; margin-top: 16px;">{sticker(bs, bz, h=130)}<div>'
           + f'<div style="display: flex; gap: 12px; align-items: center;">{rosette(3, 70)}<div>{T("Hare · Level 3", 20, 700, "Fraunces")}{T("12 more carrots to level 4", 14, 600, "Fredoka", MUTED)}</div></div>'
           + f'<div style="margin-top: 14px;">{ribbon(0.62, 420, 18)}</div>'
           + T("Level n needs 10 + 5n treats · the ribbon is torn paper filling with gold wash · a rosette per level goes in the book", 13, 500, "Fredoka", MUTED, "margin-top: 10px; width: 440px;")
           + "</div></div></div>")
    b = (head("Collectibles and levelling-up moments", "one treat per friend, always a soft, natural thing that friend would love · the moments stay short so reading keeps going")
         + "".join(row) + rares + lvl + T("The moments, in the order a child meets them", 22, 700, "Fraunces", INK, "position: absolute; left: 56px; top: 690px;") + "".join(ms))
    return "CastCollect", W, H, b, STATIC_LOGIC, "", "Collectibles and level-up moments"


WEAR_TABLE = [("straw", "Hat", "Hare level 2"), ("bobble", "Hat", "Hare level 6"), ("crown", "Hat", "Bramble level 3"), ("acorn", "Hat", "Sprig level 3"),
              ("paper-crown", "Hat", "Any friend level 10"), ("wizard", "Hat", "Hare level 9"), ("pirate", "Hat", "Nipper level 3"), ("specs", "Glasses", "Hare level 7"),
              ("bowtie", "Neck", "Hare level 3"), ("neckerchief", "Neck", "Puddle level 3"), ("satchel", "Back", "Hare level 8"), ("cape", "Back", "Hare level 10")]
NAMES = {"straw": "Straw hat", "bobble": "Bobble hat", "crown": "Flower crown", "acorn": "Acorn cap", "paper-crown": "Paper crown", "wizard": "Wizard hat",
         "pirate": "Pirate hat", "specs": "Round glasses", "bowtie": "Bow tie", "neckerchief": "Spotty neckerchief", "satchel": "Satchel", "cape": "Cape"}


def board_wardrobe():
    W, H = 1680, 1030
    tiles = []
    for i, (k, slot, unlock) in enumerate(WEAR_TABLE):
        x = 56 + (i % 6) * 190
        y = 140 + (i // 6) * 230
        s, z = wear(k)
        tiles.append(f'<div style="position: absolute; left: {x}px; top: {y}px; width: 172px; height: 210px; border-radius: 18px; background: rgba(251,244,228,0.75);">'
                     f'<div style="position: absolute; left: 0px; top: 14px; width: 172px; height: 106px; display: flex; align-items: center; justify-content: center;">{sticker(s, z, 118, 100)}</div>'
                     f'<div style="position: absolute; left: 14px; top: 130px; width: 150px;">{T(NAMES[k], 17, 700, "Fraunces")}{T(slot + " · " + unlock, 13, 600, "Fredoka", MUTED)}</div></div>')
    dressed = []
    for i, k in enumerate(["straw", "bobble", "crown", "wizard", "pirate", "specs"]):
        x = 56 + i * 196
        dressed.append(f'<div style="position: absolute; left: {x}px; top: 660px; width: 180px; text-align: center;">'
                       f'<div style="height: 280px; display: flex; align-items: flex-end; justify-content: center;">{sticker(f"./cast/dress/hare-{k}.png", tuple(M["dress"][k]), h=270)}</div>'
                       + T(NAMES[k], 15, 700, "Fraunces", INK, "margin-top: 8px;") + "</div>")
    notes = (f'<div style="position: absolute; left: 1230px; top: 140px; width: 400px;">' + T("How items fit every friend", 22, 700, "Fraunces")
             + "".join(T(t, 15, 500, "Fredoka", INK, "margin-top: 10px;") for t in [
                 "Items are separate stickers drawn once, side view facing right, with a fixed pivot (the bottom middle of a hat, the bridge of the glasses, the knot of a neck item, the strap of a bag).",
                 "Each friend defines an anchor per slot it uses (<b>head, eyes, neck, body, back</b>, plus claws or antennae for Nipper and Sprig) in its sit pose and on each hop frame, each with a position, rotation and scale.",
                 "An item follows its anchor frame by frame while hopping, so a hat bobs with the ears. Ears and antennae stay drawn over hats where needed (a front mask per friend).",
                 "Neck items replace the friend's own accessory while worn (see the glasses look: the neckerchief replaces the scarf).",
                 "The dressed hares below are full paintings made to set the target look. In the app they're built from the separate stickers."]) + "</div>")
    b = (head("Dress-up items", "12 unlockables to start, in four slots · every one is earned by levelling up a friend", w=1150)
         + "".join(tiles) + notes + T("The target look, painted", 22, 700, "Fraunces", INK, "position: absolute; left: 56px; top: 612px;") + "".join(dressed))
    return "CastWardrobe", W, H, b, STATIC_LOGIC, "", "Dress-up items and how they fit"


# ---------------------------------------------------------------- phones
PW_, PH_ = 390, 844
BOOK = [4, 10]


def reading_scene(pos, signs=True, chrome="none"):
    return pw.scene("ink", "day", pos, chrome=chrome, signs=signs)


def carrot_on_path(pos, gx):
    s, z = item("carrot")
    c = pw.cam(pos)
    return (f'<div style="position: absolute; left: {gx - c - 18:.0f}px; top: {pw.PATH_Y - 6}px; transform: rotate(-24deg); filter: drop-shadow(0 2px 2px rgba(60,40,20,0.3));">'
            f'{sticker(s, z, h=44)}</div>')


def basket_chip(n, x=270, y=56):
    bs, bz = item("basket")
    cs, cz = item("carrot")
    return (f'<div style="position: absolute; left: {x}px; top: {y}px;">'
            + sticker_box(f'{sticker(bs, bz, h=30)}<span style="font-family: Fraunces, Georgia, serif; font-weight: 700; font-size: 19px; color: {INK};">{n}</span>', "5px 14px 5px 8px") + "</div>")


def phone_pickup_before():
    b = reading_scene(1) + carrot_on_path(1, pw.XS[2] - 128) + carrot_on_path(1, pw.XS[4] - 128)
    return "PhonePickup", PW_, PH_, b, STATIC_LOGIC, "", "Reading · a carrot where he'll land"


def phone_pickup_after():
    cs, cz = item("carrot")
    b = (reading_scene(2) + carrot_on_path(2, pw.XS[4] - 128)
         + f'<svg width="390" height="844" style="position: absolute; left: 0px; top: 0px;" aria-hidden="true"><path d="M 120 520 C 170 330, 260 200, 300 110" stroke="{WASH}" stroke-width="3" stroke-dasharray="2 8" stroke-linecap="round" fill="none"></path></svg>'
         + f'<div style="position: absolute; left: 218px; top: 238px; transform: rotate(18deg); filter: drop-shadow(0 3px 3px rgba(60,40,20,0.3));">{sticker(cs, cz, h=46)}</div>'
         + basket_chip(7)
         + T("the basket shows up for 1.2 s, then fades", 12, 600, "Fredoka", INK, "position: absolute; left: 222px; top: 108px; width: 150px; text-align: right; opacity: 0.7;"))
    return "PhonePickupAfter", PW_, PH_, b, STATIC_LOGIC, "", "Reading · picked up, into the basket"


def phone_tally():
    bs, bz = item("basket")
    cs, cz = item("carrot")
    gs, gz = item("carrot-gold")
    pile = "".join(f'<div style="position: absolute; left: {x}px; top: {y}px; transform: rotate({r}deg);">{sticker(cs, cz, h=46)}</div>'
                   for x, y, r in ((18, -8, -30), (40, -16, -8), (62, -10, 18), (84, -4, 38)))
    basket = f'<div style="position: relative; width: 140px; height: 136px;">{pile}<div style="position: absolute; left: 0px; top: 10px;">{sticker(bs, bz, h=126)}</div></div>'
    sheet = paper(
        f'<div style="text-align: center;">{T("The end!", 30, 700, "Fraunces")}</div>'
        f'<div style="display: flex; gap: 18px; align-items: center; margin-top: 12px;">{basket}<div>'
        f'<div style="font-family: Fraunces, Georgia, serif; font-weight: 700; font-size: 44px; line-height: 1; color: {INK};">12</div>{T("carrots", 17, 600)}'
        f'<div style="display: flex; gap: 6px; align-items: center; margin-top: 8px;">{sticker(gs, gz, h=30)}{T("+1 golden", 14, 600, "Fredoka", "#9A7420")}</div></div></div>'
        f'<div style="display: flex; gap: 12px; align-items: center; margin-top: 16px;">{rosette(3, 58)}<div style="flex: 1;">{T("Hare · Level 3", 17, 700, "Fraunces")}'
        f'<div style="margin-top: 6px;">{ribbon(0.85, 230, 16)}</div>{T("3 more carrots to level 4", 13, 600, "Fredoka", MUTED, "margin-top: 4px;")}</div></div>'
        f'<div style="display: flex; gap: 10px; justify-content: center; margin-top: 18px;">{btn("Read again", False, "height: 46px; font-size: 16px;")}{btn("Keep going", True, "height: 46px; font-size: 16px;")}</div>',
        358, 420, seed=13, pad=22)
    b = reading_scene(len(pw.WORDS)) + f'<div style="position: absolute; left: 16px; top: 400px;">{sheet}</div>'
    return "PhoneTally", PW_, PH_, b, STATIC_LOGIC, "", "End of story · basket tally and level ribbon"


def confetti():
    import random
    r = random.Random(4)
    cols = [RED, WASH, "#A6BA92", "#9EC3DA", "#F2B8A6", "#FBF4E4"]
    return "".join(f'<div style="position: absolute; left: {r.uniform(10, 370):.0f}px; top: {r.uniform(90, 520):.0f}px; width: {r.uniform(8, 16):.0f}px; height: {r.uniform(5, 10):.0f}px; '
                   f'background: {r.choice(cols)}; transform: rotate({r.uniform(-60, 60):.0f}deg); border-radius: 1px; box-shadow: 0 1px 2px rgba(60,40,20,0.2);"></div>' for _ in range(34))


def phone_levelup():
    s, z = wear("straw")
    parcel = (f'<button type="button" onClick="{{{{open}}}}" aria-label="Open the present" style="position: relative; width: 150px; height: 124px; border: 0; padding: 0; background: transparent; cursor: pointer;">'
              f'<div style="position: absolute; left: 0px; top: 18px; width: 150px; height: 106px; background: #D9C3A0; background-image: radial-gradient(rgba(120,90,50,0.08) 1px, transparent 1.5px); background-size: 6px 6px; '
              f'clip-path: {deckle(20, 2.2, 8)}; box-shadow: 0 4px 8px rgba(60,40,20,0.25);"></div>'
              f'<div style="position: absolute; left: 68px; top: 18px; width: 14px; height: 106px; background: {RED};"></div>'
              f'<div style="position: absolute; left: 0px; top: 62px; width: 150px; height: 14px; background: {RED};"></div>'
              f'<div style="position: absolute; left: 44px; top: 0px; width: 30px; height: 26px; border: 7px solid {RED}; border-radius: 50% 50% 10% 50%; transform: rotate(-20deg);"></div>'
              f'<div style="position: absolute; left: 76px; top: 0px; width: 30px; height: 26px; border: 7px solid {RED}; border-radius: 50% 50% 50% 10%; transform: rotate(20deg);"></div></button>')
    hare_plain = sticker("./collage/hare-sit.png", Image.open(os.path.join(P, "collage", "hare-sit.png")).size, h=190)
    hare_hat = sticker("./cast/dress/hare-straw.png", tuple(M["dress"]["straw"]), h=204)
    b = (reading_scene(len(pw.WORDS))
         + '<div style="position: absolute; inset: 0; background: rgba(247,240,222,0.86);"></div>' + confetti()
         + f'<div style="position: absolute; left: 0px; top: 92px; width: 390px; display: flex; flex-direction: column; align-items: center;">{rosette(4, 118)}'
         + T("Level 4!", 40, 700, "Fraunces", INK, "margin-top: 4px;") + T("Hare has found 60 carrots", 16, 600, "Fredoka", MUTED) + "</div>"
         + f'<div style="position: absolute; left: 40px; top: 360px; width: 150px; height: 220px; display: flex; align-items: flex-end; justify-content: center;">'
         + f'<sc-if value="{{{{plain}}}}" hint-placeholder-val="{{{{true}}}}">{hare_plain}</sc-if><sc-if value="{{{{worn}}}}" hint-placeholder-val="{{{{false}}}}">{hare_hat}</sc-if></div>'
         + f'<div style="position: absolute; left: 200px; top: 400px; width: 170px; height: 180px; display: flex; flex-direction: column; align-items: center; justify-content: flex-end;">'
         + f'<sc-if value="{{{{closed}}}}" hint-placeholder-val="{{{{true}}}}">{parcel}{T("Tap to open", 14, 600, "Fredoka", MUTED, "margin-top: 10px;")}</sc-if>'
         + f'<sc-if value="{{{{opened}}}}" hint-placeholder-val="{{{{false}}}}"><div class="lv-pop">{sticker(s, z, w=150)}</div>{T("Straw hat", 20, 700, "Fraunces", INK, "margin-top: 10px;")}{T("new in your wardrobe", 13, 600, "Fredoka", MUTED)}</sc-if></div>'
         + f'<div style="position: absolute; left: 0px; top: 640px; width: 390px; display: flex; flex-direction: column; align-items: center; gap: 12px;">'
         + f'<sc-if value="{{{{opened}}}}" hint-placeholder-val="{{{{false}}}}"><button type="button" onClick="{{{{tryOn}}}}" style="border: 0; padding: 0; background: transparent; cursor: pointer;">{btn("{{tryLabel}}")}</button></sc-if>'
         + f'{btn("Keep reading", False)}</div>')
    logic = """
class Component extends DCLogic {
  constructor(props) { super(props); this.state = { open: false, worn: false }; }
  renderVals() {
    const s = this.state;
    return {
      closed: !s.open, opened: s.open, plain: !s.worn, worn: s.worn,
      open: () => this.setState({ open: true }),
      tryOn: () => this.setState({ worn: !this.state.worn }),
      tryLabel: s.worn ? "Take it off" : "Try it on",
    };
  }
}
"""
    css = ".lv-pop { animation: lvPop 0.5s cubic-bezier(0.3, 1.6, 0.5, 1) 1 both; }\n@keyframes lvPop { from { transform: scale(0.3) rotate(-20deg); opacity: 0; } to { transform: scale(1) rotate(0deg); opacity: 1; } }\n"
    return "PhoneLevelUp", PW_, PH_, b, logic, css, "Level up · tap the present, then Try it on"


WARD = [("none", None, None), ("straw", "straw", None), ("bobble", "bobble", None), ("crown", "crown", None), ("pirate", "pirate", None),
        ("wizard", "wizard", None), ("specs", "specs", None), ("acorn", None, "Meet Sprig"), ("paper-crown", None, "Level 10")]


def phone_wardrobe():
    stage = (f'<div style="position: absolute; left: 0px; top: 0px; width: 390px; height: 430px; overflow: hidden; background: {SKY};">'
             f'<img src="./collage/world/soft/cloud-2.png" alt="" style="position: absolute; left: 230px; top: 120px; width: 130px;">'
             f'<div style="position: absolute; left: 0px; top: 250px; width: 390px; height: 200px; background-image: url(./collage/world/near-day.webp); background-size: 1480px 347px; background-position: -520px -40px; background-repeat: repeat-x;"></div></div>')
    heroes = ""
    for k, render, _ in WARD:
        if k == "none":
            src, size = "./collage/hare-sit.png", Image.open(os.path.join(P, "collage", "hare-sit.png")).size
            hh = 250
        elif render:
            src, size = f"./cast/dress/hare-{render}.png", tuple(M["dress"][render])
            hh = 266
        else:
            continue
        heroes += (f'<sc-if value="{{{{show_{k.replace("-", "_")}}}}}" hint-placeholder-val="{{{{{"true" if k == "none" else "false"}}}}}">'
                   f'<div style="position: absolute; left: 0px; top: {400 - hh}px; width: 390px; display: flex; justify-content: center;">{sticker(src, size, h=hh)}</div></sc-if>')
    tabs = "".join(f'<div style="padding: 7px 14px; border-radius: 999px; font-family: Fraunces, Georgia, serif; font-weight: 700; font-size: 15px; '
                   + (f'background: {INK}; color: {PAPER};' if i == 0 else f'color: {INK}; background: rgba(251,244,228,0.9); border: 2px solid rgba(59,42,32,0.15);') + f'">{t}</div>'
                   for i, t in enumerate(["Hats", "Glasses", "Neck", "Back"]))
    tiles = []
    for i, (k, render, lock) in enumerate(WARD):
        x = 16 + (i % 4) * 90
        y = 548 + (i // 4) * 92
        if k == "none":
            icon = f'<div style="font-family: Fredoka, sans-serif; font-weight: 600; font-size: 13px; color: {MUTED}; text-align: center; line-height: 1.2;">Just<br>me</div>'
        else:
            s, z = wear(k)
            icon = sticker(s, z, 58, 54, "opacity: 0.4; filter: grayscale(0.6);" if (lock or not render) else "")
        badge = ""
        if lock:
            badge = (f'<div style="position: absolute; left: 0px; bottom: 4px; width: 82px; text-align: center; font-family: Fredoka, sans-serif; font-weight: 600; font-size: 10.5px; color: {INK};">'
                     f'<span style="padding: 1px 6px; border-radius: 999px; background: {PAPER};">&#128274; {lock}</span></div>')
        inner = (f'<div style="position: absolute; inset: 0; {PAPER_BG} border-radius: 16px; box-shadow: 0 2px 5px rgba(60,40,20,0.2);"></div>'
                 f'<div style="position: absolute; inset: 0; display: flex; align-items: center; justify-content: center;">{icon}</div>{badge}')
        if render or k == "none":
            key = k.replace("-", "_")
            tiles.append(f'<button type="button" onClick="{{{{pick_{key}}}}}" aria-label="{NAMES.get(k, "No hat")}" style="position: absolute; left: {x}px; top: {y}px; width: 82px; height: 82px; border: 0; padding: 0; '
                         f'background: transparent; cursor: pointer; border-radius: 18px; {{{{ring_{key}}}}}">{inner}</button>')
        else:
            tiles.append(f'<div style="position: absolute; left: {x}px; top: {y}px; width: 82px; height: 82px; border-radius: 18px;">{inner}</div>')
    b = (f'<div style="position: absolute; inset: 0; background: {CREAM};"></div>' + stage + heroes + back_chip()
         + f'<div style="position: absolute; left: 70px; top: 56px;">{label("Wardrobe", 19)}</div>'
         + f'<div style="position: absolute; left: 0px; top: 408px; width: 390px; display: flex; justify-content: center;">'
         + sticker_box(f'{rosette(4, 30)}<span style="font-family: Fraunces, Georgia, serif; font-weight: 700; font-size: 17px; color: {INK};">Hare · Level 4</span>', "4px 16px 4px 8px") + "</div>"
         + f'<div style="position: absolute; left: 16px; top: 494px; display: flex; gap: 8px;">{tabs}</div>' + "".join(tiles))
    keys = [k.replace("-", "_") for k, r, _ in WARD if r or k == "none"]
    logic = ("class Component extends DCLogic {\n  constructor(props) { super(props); this.state = { sel: \"none\" }; }\n  renderVals() {\n    const sel = this.state.sel;\n    const v = {};\n"
             f"    for (const k of {json.dumps(keys)}) {{\n"
             "      v[\"show_\" + k] = sel === k;\n      v[\"pick_\" + k] = () => this.setState({ sel: k });\n"
             f"      v[\"ring_\" + k] = sel === k ? \"box-shadow: 0 0 0 3px {RED};\" : \"\";\n    }}\n    return v;\n  }}\n}}\n")
    return "PhoneWardrobe", PW_, PH_, b, logic, "", "Wardrobe · tap a hat"


def phone_friends():
    cards = []
    state = {"hare": ("Level 4", 64, None, True), "bunny": ("Level 1", 6, None, False), "frog": (None, 0, "Read 2 more stories", False),
             "crow": (None, 0, "Read 4 more stories", False), "cat": (None, 0, "Read 7 more stories", False), "crab": (None, 0, "Read 10 more", False), "grasshopper": (None, 0, "Read 13 more", False)}
    for i, f in enumerate(FRIENDS + [("more", "More soon", "", "", None, "", "", "", "")]):
        x = 16 + (i % 2) * 184
        y = 128 + (i // 2) * 204
        if f[0] == "more":
            cards.append(f'<div style="position: absolute; left: {x}px; top: {y}px; width: 174px; height: 190px; border-radius: 18px; border: 3px dashed rgba(59,42,32,0.25); '
                         f'display: flex; align-items: center; justify-content: center; text-align: center;">{T("More friends<br>on the way", 15, 600, "Fredoka", MUTED)}</div>')
            continue
        lv, cnt, lock, reading = state[f[0]]
        s, z = img(f[0])
        pic = sticker(s, z, 130, 92, "filter: brightness(0) opacity(0.22);" if lock else "")
        if lock:
            foot = T(f[1], 17, 700, "Fraunces", MUTED) + T(lock, 12.5, 600, "Fredoka", MUTED)
        else:
            cs, cz = item(f[4])
            foot = (T(f[1], 18, 700, "Fraunces")
                    + f'<div style="display: flex; align-items: center; gap: 6px; margin-top: 2px;">{rosette(int(lv.split()[1]), 24)}{T(lv, 13, 600)}'
                    + f'<div style="margin-left: auto; display: flex; align-items: center; gap: 3px;">{sticker(cs, cz, h=20)}{T(str(cnt), 13, 700)}</div></div>')
        ring = f"box-shadow: 0 0 0 3px {RED}, 0 3px 8px rgba(60,40,20,0.25);" if reading else "box-shadow: 0 3px 8px rgba(60,40,20,0.2);"
        tag = (f'<div style="position: absolute; right: 10px; top: 10px; padding: 2px 8px; border-radius: 999px; background: {RED}; color: #FFFFFF; font-family: Fredoka, sans-serif; font-weight: 600; font-size: 11px;">reading</div>'
               if reading else (f'<div style="position: absolute; right: 10px; top: 10px; padding: 2px 8px; border-radius: 999px; background: {WASH}; color: {INK}; font-family: Fredoka, sans-serif; font-weight: 600; font-size: 11px;">new!</div>' if f[0] == "bunny" else ""))
        cards.append(f'<div style="position: absolute; left: {x}px; top: {y}px; width: 174px; height: 190px; border-radius: 18px; {PAPER_BG} {ring}">'
                     f'<div style="position: absolute; left: 0px; top: 12px; width: 174px; height: 96px; display: flex; align-items: flex-end; justify-content: center;">{pic}</div>{tag}'
                     f'<div style="position: absolute; left: 14px; right: 14px; top: 116px;">{foot}</div></div>')
    b = (f'<div style="position: absolute; inset: 0; background: {CREAM};"></div>' + back_chip()
         + f'<div style="position: absolute; left: 70px; top: 56px;">{label("Friends", 19)}</div>' + "".join(cards))
    return "PhoneFriends", PW_, PH_, b, STATIC_LOGIC, "", "Friends · who you read with"


def phone_book():
    cs, cz = item("carrot")
    gs, gz = item("carrot-gold")
    tabs = ""
    for i, f in enumerate(FRIENDS[:4]):
        s, z = img(f[0])
        on = i == 0
        tabs += (f'<div style="position: absolute; left: {326 if on else 332}px; top: {150 + i * 74}px; width: 60px; height: 64px; border-radius: 0 14px 14px 0; '
                 f'background: {PAPER if on else SHADE}; box-shadow: 2px 2px 5px rgba(60,40,20,0.15); display: flex; align-items: center; justify-content: center;">'
                 f'{sticker(s, z, 44, 48, "" if i < 2 else "filter: brightness(0) opacity(0.22);")}</div>')
    slots = lambda n, filled, icon, h: "".join(
        (f'<div style="width: 50px; height: 56px; display: flex; align-items: center; justify-content: center;">{icon}</div>' if j < filled else
         f'<div style="width: 46px; height: 52px; border-radius: 12px; border: 2.5px dashed rgba(59,42,32,0.25);"></div>') for j in range(n))
    ros = "".join((f'<div style="width: 50px; display: flex; justify-content: center;">{rosette(j + 1, 40)}</div>' if j < BOOK[0] else
                   f'<div style="width: 44px; height: 54px; border-radius: 50% 50% 12px 12px; border: 2.5px dashed rgba(59,42,32,0.25);"></div>') for j in range(BOOK[1]))
    stories = "".join(f'<div style="padding: 6px 10px; border-radius: 10px; background: {SHADE}; font-family: Fraunces, Georgia, serif; font-weight: 700; font-size: 13px; color: {INK}; transform: rotate({r}deg);">{t}</div>'
                      for t, r in (("The Meadow Walk", -2), ("Golden Hour", 1.5), ("Storm on the Hill", -1), ("Moonlight Hop", 2)))
    page = paper(
        T("Hare&#39;s basket", 26, 700, "Fraunces")
        + f'<div style="display: flex; align-items: center; gap: 14px; margin-top: 10px;"><div style="position: relative; width: 110px; height: 70px;">'
        + "".join(f'<div style="position: absolute; left: {x}px; top: {y}px; transform: rotate({r}deg);">{sticker(cs, cz, h=54)}</div>' for x, y, r in ((0, 8, -40), (26, 0, -12), (52, 6, 16), (74, 12, 40)))
        + f'</div><div><div style="font-family: Fraunces, Georgia, serif; font-weight: 700; font-size: 40px; line-height: 1; color: {INK};">64</div>{T("carrots found", 14, 600, "Fredoka", MUTED)}</div></div>'
        + T("Golden carrots", 17, 700, "Fraunces", INK, "margin-top: 18px;")
        + f'<div style="display: flex; flex-wrap: wrap; gap: 6px; margin-top: 6px;">{slots(5, 3, sticker(gs, gz, h=52), 52)}</div>'
        + T("Rosettes", 17, 700, "Fraunces", INK, "margin-top: 14px;")
        + f'<div style="display: flex; flex-wrap: wrap; gap: 6px 4px; margin-top: 6px; width: 280px;">{ros}</div>'
        + T("Stories read", 17, 700, "Fraunces", INK, "margin-top: 14px;")
        + f'<div style="display: flex; flex-wrap: wrap; gap: 8px; margin-top: 8px; width: 290px;">{stories}</div>',
        320, 660, seed=21, pad=22)
    b = (f'<div style="position: absolute; inset: 0; background: {CREAM};"></div>' + back_chip()
         + f'<div style="position: absolute; left: 70px; top: 56px;">{label("Collection book", 19)}</div>' + tabs
         + f'<div style="position: absolute; left: 14px; top: 124px;">{page}</div>')
    return "PhoneBook", PW_, PH_, b, STATIC_LOGIC, "", "Collection book · what each friend has found"


def phone_meet():
    s, z = img("bunny")
    ww, hh = fit(z, h=96)
    bunny = f'<div style="position: absolute; left: {262 - ww / 2:.0f}px; top: {pw.PATH_Y + 30 - hh:.0f}px; filter: drop-shadow(0 3px 4px rgba(60,40,20,0.28));">{sticker(s, z, h=96)}</div>'
    card = paper(
        f'<div style="display: flex; gap: 14px; align-items: center;"><img src="./cast/worlds/bunny.jpg" alt="" style="width: 118px; height: 78px; object-fit: cover; border-radius: 10px; box-shadow: 0 0 0 3px #FFFFFF;">'
        f'<div>{T("A new friend!", 24, 700, "Fraunces")}{T("Bramble the rabbit wants to read with you. She lives in Bluebell Wood.", 14, 500, "Fredoka", INK, "margin-top: 2px;")}</div></div>'
        f'<div style="display: flex; gap: 10px; justify-content: center; margin-top: 16px;">{btn("Maybe later", False, "height: 46px; font-size: 16px;")}{btn("Read with Bramble", True, "height: 46px; font-size: 16px;")}</div>',
        358, 190, seed=17, pad=20)
    b = reading_scene(len(pw.WORDS)) + bunny + f'<div style="position: absolute; left: 16px; top: 250px;">{card}</div>'
    return "PhoneMeet", PW_, PH_, b, STATIC_LOGIC, "", "A new friend waits at The end"


def phone_home():
    hare = sticker("./cast/dress/hare-straw.png", tuple(M["dress"]["straw"]), h=200)
    bunny_s, bunny_z = img("bunny")
    bs, bz = item("basket")
    ss, sz = wear("straw")
    bg = (f'<div style="position: absolute; inset: 0; background: {SKY};"></div>'
          f'<img src="./collage/world/soft/cloud-3.png" alt="" style="position: absolute; left: 16px; top: 150px; width: 120px;">'
          f'<div style="position: absolute; left: 0px; top: 176px; width: 390px; height: 330px; background-image: url(./collage/world/mid-day.webp); background-size: 1640px 290px; background-position: -300px 0px; background-repeat: repeat-x;"></div>'
          f'<div style="position: absolute; left: 0px; top: 250px; width: 390px; height: 330px; background-image: url(./collage/world/near-day.webp); background-size: 1480px 347px; background-position: -900px 0px; background-repeat: repeat-x;"></div>')
    top = (f'<div style="position: absolute; left: 16px; top: 56px; width: 358px; display: flex; align-items: center; justify-content: space-between;">{label("Good morning, Sam!", 18)}'
           + sticker_box('<svg width="18" height="18" viewBox="0 0 24 24" aria-hidden="true"><circle cx="12" cy="12" r="3.2" fill="none" stroke="#3B2A20" stroke-width="2.4"></circle>'
                         '<path d="M12 2.5v3M12 18.5v3M2.5 12h3M18.5 12h3M5.2 5.2l2.1 2.1M16.7 16.7l2.1 2.1M5.2 18.8l2.1-2.1M16.7 7.3l2.1-2.1" stroke="#3B2A20" stroke-width="2.4" stroke-linecap="round"></path></svg>', "9px", 999) + "</div>")
    hero = (f'<div style="position: absolute; left: 0px; top: 250px; width: 390px; display: flex; justify-content: center;">{hare}</div>'
            f'<div style="position: absolute; left: 0px; top: 452px; width: 390px; display: flex; justify-content: center;">'
            + sticker_box(f'{rosette(4, 30)}<div><div style="font-family: Fraunces, Georgia, serif; font-weight: 700; font-size: 15px; color: {INK}; line-height: 1.1;">Hare · Level 4</div>'
                          f'<div style="margin-top: 4px;">{ribbon(0.3, 110, 9)}</div></div>', "5px 16px 6px 8px") + "</div>")
    keep = (f'<div style="display: flex; gap: 12px; align-items: center;"><img src="./collage/meadow.jpg" alt="" style="width: 92px; height: 64px; object-fit: cover; border-radius: 10px; box-shadow: 0 0 0 3px #FFFFFF;">'
            f'<div style="flex: 1;">{T("Keep reading", 13, 600, "Fredoka", MUTED)}{T("Storm on the Hill", 19, 700, "Fraunces")}</div>'
            f'<div style="width: 46px; height: 46px; border-radius: 50%; background: {RED}; border: 3px solid #FFFFFF; box-shadow: 0 2px 6px rgba(60,40,20,0.3); display: flex; align-items: center; justify-content: center;">'
            f'<svg width="18" height="18" viewBox="0 0 24 24" aria-hidden="true"><path d="M8 5 L19 12 L8 19 Z" fill="#FFFFFF"></path></svg></div></div>')

    def tile(icon, txt, badge=""):
        return (f'<div style="position: relative; width: 100px; display: flex; flex-direction: column; align-items: center; gap: 6px;">'
                f'<div style="width: 76px; height: 76px; border-radius: 50%; {PAPER_BG} border: 4px solid #FFFFFF; box-shadow: 0 3px 7px rgba(60,40,20,0.25); display: flex; align-items: center; justify-content: center;">{icon}</div>'
                f'{T(txt, 15, 700, "Fraunces")}{badge}</div>')
    new = f'<div style="position: absolute; right: 6px; top: -4px; padding: 1px 7px; border-radius: 999px; background: {WASH}; font-family: Fredoka, sans-serif; font-weight: 600; font-size: 11px; color: {INK};">new!</div>'
    row = (f'<div style="display: flex; justify-content: space-between; margin-top: 18px;">'
           + tile(sticker(bunny_s, bunny_z, 52, 52), "Friends", new) + tile(sticker(ss, sz, 58, 50), "Wardrobe") + tile(sticker(bs, bz, 52, 50), "Book") + "</div>")
    sheet = paper(keep + row, 358, 262, seed=9, pad=20)
    b = bg + top + hero + f'<div style="position: absolute; left: 16px; top: 548px;">{sheet}</div>'
    return "PhoneHome", PW_, PH_, b, STATIC_LOGIC, "", "Home · friend, level and the new places"


BOARDS = [board_plan, board_lineup, board_motion, board_worlds, board_collect, board_wardrobe,
          phone_pickup_before, phone_pickup_after, phone_tally, phone_levelup, phone_wardrobe, phone_friends, phone_book, phone_meet, phone_home]

if __name__ == "__main__":
    import re
    built = []
    css0 = pw.CSS.replace("var(--sheet)", f"{-(pw.HOP[0] * 116 / pw.HOP[1]) * 8:.0f}px")
    for fn in BOARDS:
        name, w, h, body, logic, css, title = fn()
        bgc = CREAM
        open(os.path.join(P, f"{name}.dc.html"), "w").write(dc_doc(f"Hop Tales · {title}", w, h, body, bgc, logic, css0 + css))
        prev = body.replace('src="./', f'src="file://{P}/').replace("url(./", f"url(file://{P}/")
        prev = re.sub(r"<sc-if value=\"\{\{[^}]+\}\}\" hint-placeholder-val=\"\{\{false\}\}\">.*?</sc-if>", "", prev, flags=re.S)
        prev = re.sub(r"\{\{[^}]+\}\}", "", prev)
        os.makedirs(os.path.join(HERE, "out", "cast"), exist_ok=True)
        open(os.path.join(HERE, "out", "cast", f"{name}.html"), "w").write(
            f"<html><head>{FONTS}<style>body{{margin:0;background:{bgc}}}{css0}{css}</style></head><body><div style=\"position: relative; width:{w}px; height:{h}px; overflow:hidden; background:{bgc}\">{prev}</div></body></html>")
        built.append((name, w, h, title, logic != STATIC_LOGIC))
    json.dump(built, open(os.path.join(HERE, "out", "cast", "built.json"), "w"))
    print(built)
