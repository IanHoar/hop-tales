"""Progression v2: friends are reading levels. Overrides boards from cast_boards and adds new ones."""
import os, sys, json, re
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import cast_boards as cb
from cast_boards import (T, head, paper, label, btn, rosette, ribbon, sticker, img, item, wear, fit, back_chip, reading_scene, basket_chip,
                         FRIENDS, FR, TIERS, M, P, pw, INK, MUTED, PAPER, PAPER_BG, RED, SAGE, WASH, SHADE, CREAM, SKY, STATIC_LOGIC, FONTS, dc_doc, deckle, sticker_box)
from PIL import Image

HERE = cb.HERE
GOLD_INK = "#9A7420"


def steps_meter(frac, w=230, h=18, who="Puddle"):
    return ribbon(frac, w, h)


# ------------------------------------------------------------------ plan
def board_plan():
    W, H = 1680, 1240
    steps = [("Read", "Every word read is a step along the path.", "hare"),
             ("Big words", "Harder words are marked on the path and are worth 5 steps.", "star"),
             ("Path fills", "Steps fill the path to the next friend.", None),
             ("Big story", "The next friend waits with a story one level up.", "next"),
             ("New friend", "Read it well and they join. You're a level up.", "rosette")]
    cx = [120, 420, 720, 1020, 1320]
    loop = [f'<svg width="1560" height="320" viewBox="0 0 1560 320" style="position: absolute; left: 0px; top: 0px;" aria-hidden="true">'
            f'<path d="M 240 110 H 300 M 540 110 H 600 M 840 110 H 900 M 1140 110 H 1200" stroke="{INK}" stroke-width="2.5" stroke-dasharray="2 7" stroke-linecap="round" fill="none"></path>'
            f'<path d="M 1400 190 C 1400 290, 180 300, 150 200" stroke="{INK}" stroke-width="2.5" stroke-dasharray="2 7" stroke-linecap="round" fill="none"></path>'
            + "".join(f'<path d="M {x} 103 l 9 7 -9 7" stroke="{INK}" stroke-width="2.5" fill="none" stroke-linecap="round" stroke-linejoin="round"></path>' for x in (293, 593, 893, 1193))
            + f'<path d="M 143 208 l 7 -9 7 9" stroke="{INK}" stroke-width="2.5" fill="none" stroke-linecap="round" stroke-linejoin="round"></path>'
            f'<text x="780" y="292" text-anchor="middle" font-family="Fredoka, sans-serif" font-size="15" fill="{MUTED}">treats along the way fill baskets · a full basket is a present for the wardrobe</text></svg>']
    for (t, d, ic), x in zip(steps, cx):
        if ic == "hare":
            s, z = img("bunny")
            icon = f'<div style="position: absolute; right: -8px; top: -40px;">{sticker(s, z, h=64)}</div>'
        elif ic == "star":
            s, z = item("star")
            icon = f'<div style="position: absolute; right: -12px; top: -20px; transform: rotate(10deg);">{sticker(s, z, h=52)}</div>'
        elif ic == "next":
            s, z = img("frog")
            icon = f'<div style="position: absolute; right: -14px; top: -26px;">{sticker(s, z, h=56)}</div>'
        elif ic == "rosette":
            icon = f'<div style="position: absolute; right: -10px; top: -30px; transform: rotate(8deg);">{rosette(3, 50)}</div>'
        else:
            icon = f'<div style="position: absolute; right: -12px; top: -14px; padding: 4px 8px; border-radius: 999px; background: {WASH}; font-family: Fredoka, sans-serif; font-weight: 600; font-size: 12px; color: {INK}; transform: rotate(6deg);">412 / 500</div>'
        loop.append(f'<div style="position: absolute; left: {x - 100}px; top: 40px;">'
                    + paper(T(t, 21, 700, "Fraunces") + T(d, 14, 500, "Fredoka", INK, "margin-top: 4px;"), 220, 140, seed=x % 17) + icon + "</div>")
    loop_html = f'<div style="position: absolute; left: 56px; top: 150px; width: 1560px; height: 320px;">{"".join(loop)}</div>'

    def col(title, rows, x, w):
        body = "".join(f'<div style="display: flex; gap: 10px; margin-top: 9px;"><div style="flex: none; width: 7px; height: 7px; margin-top: 8px; border-radius: 50%; background: {RED};"></div>'
                       f'<div style="font-family: Fredoka, sans-serif; font-weight: 500; font-size: 15px; line-height: 1.45; color: {INK};">{r}</div></div>' for r in rows)
        return f'<div style="position: absolute; left: {x}px; top: 510px; width: {w}px;">' + T(title, 22, 700, "Fraunces") + body + "</div>"

    c1 = col("Friends are reading levels", [
        "Seven levels, one friend each: Bramble (1), Hare (2), then Puddle, Button, Marmalade, Nipper and Sprig.",
        "Each level's stories are written to that level: its sounds, word lengths and sentence lengths.",
        "Onboarding shows only the first three friends (levels 1 to 3). Picking one brings the easier friends along too.",
        "Levels 4 to 7 are only reached by reading: fill the path, then pass the big story.",
        "Every friend met stays available. Easier stories are always there to re-read."], 56, 360)
    c2 = col("Steps and big words", [
        "Each word read at your level is 1 step. Words in easier stories count half, which nudges forward without forbidding re-reads.",
        "<b>Big words</b> are harder words (one or two levels up) written into stories. They're marked on the path and worth 5 steps.",
        "Tapping for help still counts, as 1 step. A word is never failed.",
        "The steps needed grow per level: 300, 400, 500 and so on."], 456, 360)
    c3 = col("The big story", [
        "When the path is full, the next friend waits at The end with a story from their level.",
        "Reading it with 85 % of the words read without help (tunable) means they join and the level goes up.",
        "Not yet? “Puddle will wait for you at the pond.” The path stays full, and the story can be tried again from the journey map.",
        "Grown-ups can move the level up or down in settings."], 856, 360)
    c4 = col("Treats and dress-up", [
        "Treats stay the fun layer: picked up on the path, one per friend's taste.",
        "Each friend has their own wardrobe of 8 items (Hare has 12), made for their shape and world.",
        "Meeting a friend gives their first item. Each full basket of that friend's treats (10 + 5n) unlocks the next.",
        "No shop, no purchases. Treats and baskets don't gate levels; reading does."], 1256, 370)
    phases = [("1 · Levels in the content", "Tag every story with a level and mark its big words in stories.json. Write the big stories."),
              ("2 · Steps and the journey", "Step counting, big words on the path, the journey map, the big story and the new-friend moment."),
              ("3 · Treats and baskets", "Treats on the path, the basket chip, the tally, the basket-full present."),
              ("4 · Wardrobe, then friends", "The wardrobe screen and anchors, then one friend and world per release, in level order.")]
    build = (f'<div style="position: absolute; left: 56px; top: 830px; width: 1568px;">' + T("Suggested build order", 22, 700, "Fraunces")
             + '<div style="display: flex; gap: 16px; margin-top: 12px;">'
             + "".join(f'<div style="flex: 1; padding: 14px 16px; border-radius: 16px; background: rgba(251,244,228,0.8);">{T(t, 17, 700, "Fraunces")}{T(d, 14, 500, "Fredoka", INK, "margin-top: 4px;")}</div>' for t, d in phases)
             + "</div></div>")
    notes = (f'<div style="position: absolute; left: 56px; top: 1040px; width: 1568px;">'
             + paper(T("Open questions", 19, 700, "Fraunces")
                     + T("1. In onboarding, does the grown-up pick the friend, or the child with the grown-up?  2. Is 85 % without help the right bar for the big story?  "
                         "3. Should a level ever go down on its own if a child struggles, or only through the grown-up setting?  4. Do the seven level definitions match what his school teaches? Worth checking with a teacher.  "
                         "5. The names are placeholders; does Hare get one?", 15, 500, "Fredoka", INK, "margin-top: 6px;"),
                     1568, 130, seed=11) + "</div>")
    b = (head("How the new features fit together", "each friend is a reading level · reading more, and reading harder words, walks the path to the next friend")
         + loop_html + c1 + c2 + c3 + c4 + build + notes)
    return "CastPlan", W, H, b, STATIC_LOGIC, "", "Plan · friends are reading levels"


# ------------------------------------------------------------------ journey board
def journey_map(w, h, current=1, frac=0.82, small=False):
    """A winding paper path with a stop per friend. current = index of the friend being read with."""
    n = len(FRIENDS)
    pts = []
    for i in range(n):
        t = i / (n - 1)
        x = w * (0.16 + 0.68 * (0.5 + 0.5 * (1 if i % 2 else -1) * (0.6 if i not in (0, n - 1) else 0.3)))
        y = h * (0.92 - 0.84 * t)
        pts.append((x, y))
    d = f"M {pts[0][0]:.0f} {pts[0][1]:.0f} " + " ".join(
        f"C {pts[i - 1][0]:.0f} {(pts[i - 1][1] + pts[i][1]) / 2:.0f}, {pts[i][0]:.0f} {(pts[i - 1][1] + pts[i][1]) / 2:.0f}, {pts[i][0]:.0f} {pts[i][1]:.0f}" for i in range(1, n))
    lw = 30 if small else 46
    svg = (f'<svg width="{w}" height="{h}" viewBox="0 0 {w} {h}" style="position: absolute; left: 0px; top: 0px;" aria-hidden="true">'
           f'<path d="{d}" stroke="#E6D6B4" stroke-width="{lw}" fill="none" stroke-linecap="round"></path>'
           f'<path d="{d}" stroke="#F3E8D0" stroke-width="{lw - 10}" fill="none" stroke-linecap="round"></path>'
           f'<path d="{d}" stroke="rgba(59,42,32,0.35)" stroke-width="2.5" stroke-dasharray="2 9" fill="none" stroke-linecap="round"></path></svg>')
    out = [svg]
    sz = 64 if small else 104
    for i, (f, (x, y)) in enumerate(zip(FRIENDS, pts)):
        s, z = img(f[0])
        ww, hh = fit(z, sz * 1.25, sz)
        met = i <= current
        nxt = i == current + 1
        style = "" if met else ("filter: grayscale(0.4) brightness(1.05); opacity: 0.9;" if nxt else "filter: brightness(0) opacity(0.18);")
        out.append(f'<div style="position: absolute; left: {x - ww / 2:.0f}px; top: {y - hh + 6:.0f}px;">{sticker(s, z, sz * 1.25, sz, style)}</div>')
        side = "left" if x > w / 2 else "right"
        lx = x - ww / 2 - (150 if small else 210) if side == "left" else x + ww / 2 + 10
        name = f[1] if met or nxt else "?"
        sub = (f"Level {i + 1}" + (" · reading now" if i == current else "")) if met else ("Level " + str(i + 1) + " · big story waiting" if nxt else f"Level {i + 1}")
        out.append(f'<div style="position: absolute; left: {lx:.0f}px; top: {y - hh * 0.7:.0f}px; width: {140 if small else 200}px; text-align: {"right" if side == "left" else "left"};">'
                   + T(name, 15 if small else 20, 700, "Fraunces", INK if (met or nxt) else MUTED)
                   + T(sub, 11 if small else 13, 600, "Fredoka", RED if i == current else MUTED) + "</div>")
        if met and i < current:
            out.append(f'<div style="position: absolute; left: {x + ww / 2 - (16 if small else 26):.0f}px; top: {y - hh - 4:.0f}px;">{rosette(i + 1, 26 if small else 40)}</div>')
    # progress from current to next
    if current + 1 < n:
        (x0, y0), (x1, y1) = pts[current], pts[current + 1]
        fx, fy = x0 + (x1 - x0) * frac, y0 + (y1 - y0) * frac
        out.append(f'<div style="position: absolute; left: {fx - 9:.0f}px; top: {fy - 9:.0f}px; width: 18px; height: 18px; border-radius: 50%; background: {WASH}; border: 3px solid #FFFFFF; box-shadow: 0 1px 4px rgba(60,40,20,0.35);"></div>')
    return f'<div style="position: relative; width: {w}px; height: {h}px;">{"".join(out)}</div>'


def board_journey():
    W, H = 1680, 1240
    mp = f'<div style="position: absolute; left: 56px; top: 140px;">{journey_map(640, 1040, current=1, frac=0.82)}</div>'
    rows = ""
    for i, f in enumerate(FRIENDS):
        focus, ex, sent, need = TIERS[f[0]]
        s, z = img(f[0])
        rows += (f'<div style="display: grid; grid-template-columns: 56px 120px 200px 210px 120px 90px; align-items: center; gap: 12px; padding: 10px 14px; border-radius: 14px; '
                 f'background: {"rgba(251,244,228,0.95)" if i % 2 == 0 else "rgba(251,244,228,0.55)"};">'
                 f'<div style="display: flex; justify-content: center;">{sticker(s, z, 60, 48)}</div>'
                 f'<div>{T(f[1], 17, 700, "Fraunces")}{T("Level " + str(i + 1), 12, 600, "Fredoka", MUTED)}</div>'
                 + T(focus, 14, 600) + T(ex, 15, 400, "Young") + T(sent, 13, 500) + T(f"{need} steps" if need else "the top", 13, 600, "Fredoka", MUTED) + "</div>")
    hdr = (f'<div style="display: grid; grid-template-columns: 56px 120px 200px 210px 120px 90px; gap: 12px; padding: 0 14px 6px;">'
           + "".join(T(t, 12, 600, "Fredoka", MUTED) for t in ("", "Friend", "Focus", "Example words", "Sentences", "To next friend")) + "</div>")
    table = f'<div style="position: absolute; left: 740px; top: 150px; width: 890px;">{T("The seven reading levels", 22, 700, "Fraunces")}<div style="margin-top: 12px;">{hdr}<div style="display: flex; flex-direction: column; gap: 6px;">{rows}</div></div></div>'
    entry = (f'<div style="position: absolute; left: 740px; top: 790px; width: 890px;">' + T("Where a child starts: onboarding shows three friends", 22, 700, "Fraunces")
             + '<div style="display: flex; gap: 14px; margin-top: 10px;">'
             + "".join(f'<div style="flex: 1; padding: 12px 14px; border-radius: 14px; background: rgba(251,244,228,0.8);">{T(a, 16, 700, "Fraunces")}{T(b, 13, 500, "Fredoka", INK, "margin-top: 3px;")}</div>'
                       for a, b in (("Bramble · just starting", "Starts at level 1."), ("Hare · getting going", "Starts at level 2. Bramble comes along."),
                                    ("Puddle · reading well", "Starts at level 3. Bramble and Hare come along.")))
             + "</div>"
             + T("Button, Marmalade, Nipper and Sprig are never offered in onboarding. They're only reached by filling the path and passing each big story.",
                 13, 500, "Fredoka", MUTED, "margin-top: 10px;") + "</div>")
    rules = (f'<div style="position: absolute; left: 740px; top: 1000px; width: 890px;">' + T("Nudging forward, gently", 22, 700, "Fraunces")
             + "".join(T("· " + t, 14, 500, "Fredoka", INK, "margin-top: 5px;") for t in [
                 "Stories at your level include a few big words from the next level up, more as the path fills (about 1 in 20 words early on, 1 in 8 near the end).",
                 "If a child taps for help a lot, big words get rarer for a while. If they breeze through, the big story arrives a little sooner.",
                 "The big story is always optional to start, and there's no failing it, only “not yet”."]) + "</div>")
    b = head("The reading journey", "one path, seven friends · the dot shows how far along the path to Puddle a level-2 reader is") + mp + table + entry + rules
    return "CastJourney", W, H, b, STATIC_LOGIC, "", "Reading journey · levels, steps and the big story"


# ------------------------------------------------------------------ collect
def board_collect():
    name, W, H, b, logic, css, title = cb.board_collect()
    b = (b.replace("Hare · Level 3", "Basket 3").replace("12 more carrots to level 4", "12 more carrots for the next present")
         .replace("Level n needs 10 + 5n treats · the ribbon is torn paper filling with gold wash · a rosette per level goes in the book",
                  "basket n needs 10 + 5n treats, one basket per friend · the ribbon is torn paper filling with gold wash · rosettes now mark reading levels")
         .replace("The basket and the level ribbon", "The basket (presents, not levels)")
         .replace("4 · Level up", "4 · Basket full").replace("Rosette, paper confetti and a wrapped present to open.", "Paper confetti and a wrapped present to open.")
         .replace("2 · Golden", "2 · Big word").replace("End of a sentence read without help: a golden treat sparkles on the path.",
                                                         "A marked harder word, read out loud: a star pops and it's worth 5 steps.")
         .replace("6 · New friend", "6 · Big story").replace("After enough stories, a new friend waits on the path at The end sign.",
                                                             "When the path is full, the next friend waits at The end with a story one level up.")
         .replace("levelling-up moments", "celebration moments"))
    # swap the golden-carrot icon in moment 2 for the star
    gs, gz = item("carrot-gold")
    ss, sz = item("star")
    b = b.replace(sticker(gs, gz, h=80), sticker(ss, sz, h=80), 1)
    b = b.replace(rosette(3, 70), "")
    ws_, wz_ = wear("bowtie")
    b = b.replace(rosette(4, 84), sticker(ws_, wz_, h=70))
    bs_, bz_ = img("bunny")
    fs_, fz_ = img("frog")
    b = b.replace(sticker(bs_, bz_, h=86), sticker(fs_, fz_, h=72))
    b = b.replace("the basket counts up and the level ribbon fills.", "the basket counts up and the path to the next friend fills.")
    b = re.sub(r'(<div style="display: flex; gap: 12px; align-items: center;">)<div style="position: relative;[^"]*">.*?</div></div>(<div>)',
               lambda m: m.group(1) + m.group(2), b, count=1, flags=re.S) if False else b
    return name, W, H, b, logic, css, "Collectibles and celebration moments"


cb.WEAR_TABLE = [("straw", "Hat", "Meet Hare"), ("bobble", "Hat", "Basket 5"), ("crown", "Hat", "Basket 3"), ("acorn", "Hat", "Basket 9"),
                 ("paper-crown", "Hat", "Basket 11"), ("wizard", "Hat", "Basket 8"), ("pirate", "Hat", "Basket 7"), ("specs", "Glasses", "Basket 6"),
                 ("bowtie", "Neck", "Basket 1"), ("neckerchief", "Neck", "Basket 2"), ("satchel", "Back", "Basket 4"), ("cape", "Back", "Basket 10")]
cb.WARD = [("none", None, None), ("straw", "straw", None), ("bobble", "bobble", None), ("crown", "crown", None), ("pirate", "pirate", None),
           ("wizard", "wizard", None), ("specs", "specs", None), ("acorn", None, "Basket 9"), ("paper-crown", None, "Basket 11")]


def board_wardrobe():
    name, W, H, b, logic, css, title = cb.board_wardrobe()
    b = (b.replace("Dress-up items", "Hare&#39;s wardrobe").replace("12 unlockables to start, in four slots · every one is earned by levelling up a friend",
                   "12 items for Hare · the first when you meet him, then one per full basket of carrots · every other friend has 8 (see the next board)")
         .replace("Items are separate stickers drawn once", "Each friend&#39;s items are separate stickers made for that friend")
         .replace("One wardrobe shared by every friend", "Each friend has their own wardrobe"))
    return name, W, H, b, logic, css, "Hare&#39;s wardrobe and how items fit"


SU = json.load(open(os.path.join(P, "cast", "suits", "suits.json")))
SUIT_ORDER = ["bunny", "frog", "crow", "cat", "crab", "grasshopper"]


def board_suits():
    W = 1680
    rowh = 250
    H = 150 + rowh * 6 + 40
    rows = []
    for r, k in enumerate(SUIT_ORDER):
        y = 140 + r * rowh
        f = FR[k]
        s, z = img(k)
        lvl = [x[0] for x in FRIENDS].index(k) + 1
        left = (f'<div style="position: absolute; left: 56px; top: {y}px; width: 150px;">'
                f'<div style="height: 120px; display: flex; align-items: flex-end;">{sticker(s, z, 140, 110)}</div>'
                + T(f[1], 22, 700, "Fraunces", INK, "margin-top: 6px;") + T(f"Level {lvl} · {f[6]}", 12.5, 600, "Fredoka", MUTED) + "</div>")
        dressed = "".join(f'<div style="position: absolute; left: {220 + j * 150}px; top: {y}px; width: 140px; height: 200px; display: flex; align-items: flex-end; justify-content: center;">'
                          + sticker("./cast/suits/" + k + "/dressed-" + t + ".png", tuple(SU[k]["dressed"][t]), 140, 190) + "</div>" for j, t in enumerate("ab"))
        tiles = []
        for i, it in enumerate(SU[k]["items"]):
            x = 530 + i * 136
            unlock = "Meet " + f[1] if i == 0 else f"Basket {i}"
            isrc = "./cast/suits/" + k + "/" + it["id"] + ".png"
            iname, islot = it["name"], it["slot"]
            tiles.append(f'<div style="position: absolute; left: {x}px; top: {y + 6}px; width: 126px; height: 206px; border-radius: 16px; background: rgba(251,244,228,0.78);">'
                         f'<div style="position: absolute; left: 0px; top: 10px; width: 126px; height: 104px; display: flex; align-items: center; justify-content: center;">{sticker(isrc, tuple(it["size"]), 104, 92)}</div>'
                         f'<div style="position: absolute; left: 10px; right: 8px; top: 122px;">{T(iname, 14, 700, "Fraunces", INK, "line-height: 1.15;")}'
                         f'{T(islot + " · " + unlock, 11.5, 600, "Fredoka", RED if i == 0 else MUTED, "margin-top: 3px;")}</div></div>')
        line = f'<div style="position: absolute; left: 56px; top: {y + rowh - 22}px; width: 1568px; height: 2px; background: repeating-linear-gradient(90deg, rgba(59,42,32,0.18) 0 6px, transparent 6px 12px);"></div>' if r < 5 else ""
        rows.append(left + dressed + "".join(tiles) + line)
    b = (head("A wardrobe for every friend", "8 items each, made for that friend&#39;s shape and world · the first comes with meeting them, then one per full basket of their treats · two looks painted per friend to set the target",
              w=1568) + "".join(rows))
    return "CastSuits", W, H, b, STATIC_LOGIC, "", "Wardrobes · 8 items for each new friend"
    return name, W, H, b, logic, css, title


def board_lineup():
    name, W, H, b, logic, css, title = cb.board_lineup()
    b = b.replace("<b>Joins:</b>", "<b>Level:</b>").replace("Reading level ", "").replace(
        "six more hoppers join the hare · each has a treat, a world and a way of moving",
        "in reading-level order, easiest first · each has a treat, a world and a way of moving")
    return name, W, H, b, logic, css, title


# ------------------------------------------------------------------ phones
def big_word_scene():
    words0, xs0 = pw.WORDS, pw.XS
    pw.WORDS = ["The", "hare", "hid", "in", "the", "garden"]
    from PIL import ImageFont
    f = ImageFont.truetype(os.path.expanduser("~/.fonts/YoungSerif.ttf"), pw.FS)
    wl = [f.getlength(t) for t in pw.WORDS]
    xs = [0.0]
    for i in range(1, len(wl)):
        xs.append(round(xs[-1] + wl[i - 1] * 0.5 + 64 + wl[i] * 0.5, 1))
    pw.XS = xs
    pos = 5
    html = reading_scene(pos)
    c = pw.cam(pos)
    ss, sz = item("star")
    gx = xs[pos] - c
    deco = (f'<div style="position: absolute; left: {gx - 78:.0f}px; top: {pw.PATH_Y + 20}px; width: 156px; height: 4px; '
            f'background: repeating-linear-gradient(90deg, #E0B94E 0 6px, transparent 6px 11px); border-radius: 2px; transform: perspective(260px) rotateX(24deg);"></div>'
            f'<div style="position: absolute; left: {gx + 52:.0f}px; top: {pw.PATH_Y - 70}px; transform: rotate(14deg); filter: drop-shadow(0 2px 3px rgba(60,40,20,0.3));">{sticker(ss, sz, h=40)}</div>'
            f'<div style="position: absolute; left: {gx - 70:.0f}px; top: {pw.PATH_Y - 100}px; padding: 3px 10px; border-radius: 999px; background: {WASH}; '
            f'font-family: Fredoka, sans-serif; font-weight: 600; font-size: 12px; color: {INK}; transform: rotate(-4deg); box-shadow: 0 2px 4px rgba(60,40,20,0.2);">big word · 5 steps</div>')
    pw.WORDS, pw.XS = words0, xs0
    return html + deco


def phone_bigword():
    b = big_word_scene() + T("big words get a gold dotted underline and a star; the friend does a bigger hop onto them", 12, 600, "Fredoka", INK,
                             "position: absolute; left: 150px; top: 108px; width: 220px; text-align: right; opacity: 0.7;")
    return "PhoneBigWord", 390, 844, b, STATIC_LOGIC, "", "Reading · a big word on the path"


def phone_tally():
    bs, bz = item("basket")
    cs, cz = item("carrot")
    ss, sz = item("star")
    fs, fz = img("frog")
    pile = "".join(f'<div style="position: absolute; left: {x}px; top: {y}px; transform: rotate({r}deg);">{sticker(cs, cz, h=40)}</div>'
                   for x, y, r in ((14, -8, -30), (34, -14, -8), (54, -8, 18), (72, -2, 38)))
    basket = f'<div style="position: relative; width: 120px; height: 112px;">{pile}<div style="position: absolute; left: 0px; top: 8px;">{sticker(bs, bz, h=104)}</div></div>'
    sheet = paper(
        f'<div style="text-align: center;">{T("The end!", 30, 700, "Fraunces")}</div>'
        f'<div style="display: flex; gap: 16px; align-items: center; margin-top: 8px;">{basket}<div>'
        f'<div style="display: flex; align-items: baseline; gap: 8px;"><span style="font-family: Fraunces, Georgia, serif; font-weight: 700; font-size: 38px; color: {INK};">12</span>{T("carrots", 16, 600)}</div>'
        f'<div style="display: flex; gap: 6px; align-items: center; margin-top: 4px;">{sticker(ss, sz, h=24)}{T("3 big words read!", 14, 600, "Fredoka", GOLD_INK)}</div></div></div>'
        f'<div style="margin-top: 14px; padding: 12px 14px; border-radius: 14px; background: rgba(239,227,200,0.7);">'
        f'<div style="display: flex; gap: 10px; align-items: center;">{sticker(fs, fz, 54, 46, "filter: grayscale(0.4);")}<div style="flex: 1;">{T("The path to Puddle", 16, 700, "Fraunces")}'
        f'<div style="margin-top: 6px;">{ribbon(0.82, 220, 16)}</div>{T("+41 steps · 412 of 500", 12.5, 600, "Fredoka", MUTED, "margin-top: 4px;")}</div></div></div>'
        f'<div style="display: flex; gap: 10px; justify-content: center; margin-top: 16px;">{btn("Read again", False, "height: 46px; font-size: 16px;")}{btn("Keep going", True, "height: 46px; font-size: 16px;")}</div>',
        358, 430, seed=13, pad=22)
    b = reading_scene(len(pw.WORDS)) + f'<div style="position: absolute; left: 16px; top: 392px;">{sheet}</div>'
    return "PhoneTally", 390, 844, b, STATIC_LOGIC, "", "End of story · treats, big words, the path to the next friend"


def phone_levelup():
    name, W, H, b, logic, css, title = cb.phone_levelup()
    bs, bz = item("basket")
    b = b.replace(rosette(4, 118), f'<div style="transform: rotate(-4deg);">{sticker(bs, bz, h=120)}</div>')
    b = b.replace("Level 4!", "A full basket!").replace("Hare has found 60 carrots", "That&#39;s 60 carrots. Here&#39;s a present.")
    return "PhoneLevelUp", W, H, b, logic, css, "Basket full · tap the present, then Try it on"


def phone_bigstory():
    s, z = img("frog")
    ww, hh = fit(z, h=80)
    frog = f'<div style="position: absolute; left: {262 - ww / 2:.0f}px; top: {pw.PATH_Y + 30 - hh:.0f}px; filter: drop-shadow(0 3px 4px rgba(60,40,20,0.28));">{sticker(s, z, h=80)}</div>'
    card = paper(
        f'<div style="display: flex; gap: 14px; align-items: center;"><img src="./cast/worlds/frog.jpg" alt="" style="width: 118px; height: 80px; object-fit: cover; border-radius: 10px; box-shadow: 0 0 0 3px #FFFFFF;">'
        f'<div>{T("Puddle has a bigger story!", 22, 700, "Fraunces")}{T("The path is full. Read Puddle&#39;s story to go to the pond together.", 14, 500, "Fredoka", INK, "margin-top: 2px;")}</div></div>'
        f'<div style="display: flex; align-items: center; gap: 8px; margin-top: 12px; padding: 8px 12px; border-radius: 12px; background: rgba(239,227,200,0.7);">{rosette(3, 30)}'
        f'{T("<b>The Lily Pad Race</b> · reading level 3", 14, 500)}</div>'
        f'<div style="display: flex; gap: 10px; justify-content: center; margin-top: 14px;">{btn("Not yet", False, "height: 46px; font-size: 16px;")}{btn("Try the big story", True, "height: 46px; font-size: 16px;")}</div>',
        358, 256, seed=17, pad=20)
    note = paper(T("Finished with 85 % read without help: Puddle joins and it&#39;s level 3.", 14, 600) +
                 T("Not quite: “Puddle will wait for you at the pond.” The path stays full; try again any time from the journey map.", 13, 500, "Fredoka", MUTED, "margin-top: 4px;"),
                 300, 124, seed=29, pad=16)
    b = (reading_scene(len(pw.WORDS)) + frog + f'<div style="position: absolute; left: 16px; top: 180px;">{card}</div>'
         + f'<div style="position: absolute; left: 45px; top: 700px; opacity: 0.95;">{note}</div>')
    return "PhoneBigStory", 390, 844, b, STATIC_LOGIC, "", "The big story · the next friend invites you up a level"


def phone_newfriend():
    s, z = img("frog")
    bs, bz = img("hare")
    ns, nz = f"./cast/suits/frog/lilypad-hat.png", tuple(SU["frog"]["items"][0]["size"])
    b = (reading_scene(len(pw.WORDS)) + '<div style="position: absolute; inset: 0; background: rgba(247,240,222,0.86);"></div>' + cb.confetti()
         + f'<div style="position: absolute; left: 0px; top: 96px; width: 390px; display: flex; flex-direction: column; align-items: center;">{rosette(3, 104)}'
         + T("Reading level 3!", 34, 700, "Fraunces", INK, "margin-top: 4px;") + T("Puddle is your new friend", 17, 600, "Fredoka", MUTED) + "</div>"
         + f'<div style="position: absolute; left: 0px; top: 360px; width: 390px; display: flex; justify-content: center; align-items: flex-end; gap: 10px;">'
         + sticker(bs, bz, h=170) + sticker(s, z, h=110) + "</div>"
         + f'<div style="position: absolute; left: 0px; top: 560px; width: 390px; display: flex; justify-content: center; align-items: center; gap: 10px;">'
         + sticker_box(f'{sticker(ns, nz, h=34)}<span style="font-family: Fredoka, sans-serif; font-weight: 600; font-size: 14px; color: {INK};">Puddle gave you a lily-pad hat</span>', "6px 14px 6px 8px") + "</div>"
         + f'<div style="position: absolute; left: 0px; top: 650px; width: 390px; display: flex; justify-content: center; gap: 10px;">{btn("Later", False)}{btn("Go to the pond", True)}</div>')
    return "PhoneNewFriend", 390, 844, b, STATIC_LOGIC, "", "Passed · a new friend and a new level"


def phone_onboard():
    bg = (f'<div style="position: absolute; inset: 0; background: {SKY};"></div>'
          f'<img src="./collage/world/soft/cloud-2.png" alt="" style="position: absolute; left: 230px; top: 70px; width: 130px;">'
          f'<div style="position: absolute; left: 0px; top: 60px; width: 390px; height: 290px; background-image: url(./collage/world/mid-day.webp); background-size: 1640px 290px; background-position: -700px 0px; background-repeat: repeat-x;"></div>'
          f'<div style="position: absolute; left: 0px; top: 110px; width: 390px; height: 347px; background-image: url(./collage/world/near-day.webp); background-size: 1480px 347px; background-position: -300px 0px; background-repeat: repeat-x;"></div>')
    pills = "".join(f'<span style="display: block; height: 8px; width: {22 if i == 2 else 8}px; border-radius: 999px; background: {RED if i == 2 else "rgba(59,42,32,0.2)"};"></span>' for i in range(4))
    opts = [("bunny", "Just starting", "sat · hop · red"), ("hare", "Getting going", "frog · ship · hill"), ("frog", "Reading well", "lake · kite · home")]
    cards = ""
    for i, (k, lab, ex) in enumerate(opts):
        s_, z_ = img(k)
        cards += (f'<button type="button" onClick="{{{{pick{i}}}}}" style="display: flex; align-items: center; gap: 12px; width: 100%; height: 84px; padding: 0 14px; border-radius: 18px; cursor: pointer; text-align: left; '
                  f'background: rgba(255,255,255,0.72); border: 3px solid transparent; {{{{ring{i}}}}}">'
                  f'<span style="width: 70px; display: flex; justify-content: center; flex: none;">{sticker(s_, z_, 70, 64)}</span>'
                  f'<span style="display: flex; flex-direction: column; gap: 1px;">'
                  f'<span style="font-family: Fraunces, Georgia, serif; font-weight: 700; font-size: 19px; color: {INK};">{FR[k][1]} <span style="font-family: Fredoka, sans-serif; font-weight: 600; font-size: 13px; color: {MUTED};">· {lab}</span></span>'
                  f'<span style="font-family: &#39;Young Serif&#39;, Georgia, serif; font-size: 17px; color: #4A3F36;">{ex}</span></span></button>')
    later = "".join(sticker(*img(k), 36, 30, "filter: brightness(0) opacity(0.2);") for k in ("crow", "cat", "crab", "grasshopper"))
    sheet = (f'<div style="position: absolute; left: 0px; top: 214px; width: 390px; bottom: 0px; filter: drop-shadow(0 -4px 10px rgba(60,40,20,0.22));">'
             f'<div style="position: absolute; inset: 0; {PAPER_BG} clip-path: {deckle(40, 1.4, 21)};"></div>'
             f'<div style="position: relative; padding: 24px 22px 30px; box-sizing: border-box; height: 100%; display: flex; flex-direction: column; gap: 12px;">'
             f'<div style="display: flex; gap: 7px; justify-content: center;">{pills}</div>'
             f'<div style="font-family: Fredoka, sans-serif; font-weight: 600; font-size: 13px; color: {MUTED}; letter-spacing: 0.08em; text-transform: uppercase;">Step 3 of 4</div>'
             f'<h2 style="margin: 0; font-family: Fraunces, Georgia, serif; font-weight: 700; font-size: 27px; line-height: 1.12; color: {INK};">Who should your reader start with?</h2>'
             f'<p style="margin: 0; font-family: Fredoka, sans-serif; font-size: 15px; line-height: 1.4; color: #4A3F36;">Pick the friend whose words look about right. You can change this later in settings.</p>'
             f'{cards}'
             f'<div style="display: flex; align-items: center; gap: 6px; margin-top: 2px;">{later}<span style="font-family: Fredoka, sans-serif; font-weight: 600; font-size: 12.5px; color: {MUTED}; margin-left: 4px;">4 more friends join as your reader gets stronger</span></div>'
             f'<div style="flex-grow: 1;"></div>'
             f'<button type="button" style="height: 56px; border-radius: 999px; border: 4px solid #FFFFFF; background: {RED}; color: #FFFFFF; font-family: Fredoka, sans-serif; font-weight: 600; font-size: 18px; box-shadow: 0 4px 10px rgba(60,40,20,0.3); cursor: pointer;">Continue</button>'
             f'</div></div>')
    logic = """
class Component extends DCLogic {
  constructor(props) { super(props); this.state = { sel: 1 }; }
  renderVals() {
    const v = {};
    for (let i = 0; i < 3; i++) {
      v["pick" + i] = () => this.setState({ sel: i });
      v["ring" + i] = this.state.sel === i ? "border-color: %s; background: #FFFFFF;" : "";
    }
    return v;
  }
}
""" % RED
    return "PhoneOnboard", 390, 844, bg + sheet, logic, "", "Onboarding · pick one of the first three friends"


def phone_journey():
    mp = journey_map(358, 700, current=1, frac=0.82, small=True)
    b = (f'<div style="position: absolute; inset: 0; background: {CREAM};"></div>' + back_chip()
         + f'<div style="position: absolute; left: 70px; top: 56px;">{label("Your reading path", 19)}</div>'
         + f'<div style="position: absolute; left: 16px; top: 116px;">{mp}</div>')
    return "PhoneJourney", 390, 844, b, STATIC_LOGIC, "", "Journey map · friends met and the next one"


def phone_friends():
    cards = []
    state = {"bunny": ("met", "Level 1", 18), "hare": ("reading", "Level 2", 64), "frog": ("next", "Level 3", 0)}
    for i, f in enumerate(FRIENDS + [("more", "")]):
        x = 16 + (i % 2) * 184
        y = 128 + (i // 2) * 204
        if f[0] == "more":
            cards.append(f'<div style="position: absolute; left: {x}px; top: {y}px; width: 174px; height: 190px; border-radius: 18px; border: 3px dashed rgba(59,42,32,0.25); '
                         f'display: flex; align-items: center; justify-content: center; text-align: center;">{T("More friends<br>on the way", 15, 600, "Fredoka", MUTED)}</div>')
            continue
        st, lv, cnt = state.get(f[0], ("locked", f"Level {i + 1}", 0))
        s, z = img(f[0])
        dim = {"locked": "filter: brightness(0) opacity(0.2);", "next": "filter: grayscale(0.5); opacity: 0.85;"}.get(st, "")
        pic = sticker(s, z, 130, 92, dim)
        if st in ("met", "reading"):
            cs, cz = item(f[4])
            foot = (T(f[1], 18, 700, "Fraunces") + f'<div style="display: flex; align-items: center; gap: 6px; margin-top: 2px;">{rosette(i + 1, 24)}{T(lv, 13, 600)}'
                    f'<div style="margin-left: auto; display: flex; align-items: center; gap: 3px;">{sticker(cs, cz, h=20)}{T(str(cnt), 13, 700)}</div></div>')
        elif st == "next":
            foot = T(f[1], 18, 700, "Fraunces") + T("Level 3 · fill the path, then read the big story", 12, 600, "Fredoka", MUTED)
        else:
            foot = T("?", 18, 700, "Fraunces", MUTED) + T(f"Reading level {i + 1}", 12.5, 600, "Fredoka", MUTED)
        ring = f"box-shadow: 0 0 0 3px {RED}, 0 3px 8px rgba(60,40,20,0.25);" if st == "reading" else "box-shadow: 0 3px 8px rgba(60,40,20,0.2);"
        tag = ""
        if st == "reading":
            tag = f'<div style="position: absolute; right: 10px; top: 10px; padding: 2px 8px; border-radius: 999px; background: {RED}; color: #FFFFFF; font-family: Fredoka, sans-serif; font-weight: 600; font-size: 11px;">reading</div>'
        elif st == "next":
            tag = f'<div style="position: absolute; right: 10px; top: 10px; padding: 2px 8px; border-radius: 999px; background: {WASH}; color: {INK}; font-family: Fredoka, sans-serif; font-weight: 600; font-size: 11px;">next</div>'
        bg = PAPER_BG if st != "locked" else "background: rgba(251,244,228,0.5);"
        cards.append(f'<div style="position: absolute; left: {x}px; top: {y}px; width: 174px; height: 190px; border-radius: 18px; {bg} {ring}">'
                     f'<div style="position: absolute; left: 0px; top: 12px; width: 174px; height: 96px; display: flex; align-items: flex-end; justify-content: center;">{pic}</div>{tag}'
                     f'<div style="position: absolute; left: 14px; right: 14px; top: 116px;">{foot}</div></div>')
    b = (f'<div style="position: absolute; inset: 0; background: {CREAM};"></div>' + back_chip()
         + f'<div style="position: absolute; left: 70px; top: 56px;">{label("Friends", 19)}</div>' + "".join(cards))
    return "PhoneFriends", 390, 844, b, STATIC_LOGIC, "", "Friends · one per reading level"


def phone_home():
    name, W, H, b, logic, css, title = cb.phone_home()
    b = b.replace("Hare · Level 4", "Level 2 · 412 of 500 to Puddle").replace(rosette(4, 30), rosette(2, 30)).replace(ribbon(0.3, 110, 9), ribbon(0.82, 150, 9))
    return name, W, H, b, logic, css, "Home · friend, level and the path to the next friend"


def phone_wardrobe():
    name, W, H, b, logic, css, title = cb.phone_wardrobe()
    b = b.replace(f'{rosette(4, 30)}<span style="font-family: Fraunces, Georgia, serif; font-weight: 700; font-size: 17px; color: {INK};">Hare · Level 4</span>',
                  f'{rosette(2, 30)}<span style="font-family: Fraunces, Georgia, serif; font-weight: 700; font-size: 17px; color: {INK};">Hare</span>')
    return name, W, H, b, logic, css, title


def phone_book():
    cb.BOOK[:] = [2, 7]
    name, W, H, b, logic, css, title = cb.phone_book()
    b = b.replace(">Rosettes<", ">Reading levels<")
    return name, W, H, b, logic, css, title


BOARDS = [board_plan, board_journey, board_lineup, cb.board_motion, cb.board_worlds, board_collect, board_wardrobe, board_suits,
          phone_onboard, phone_bigword, cb.phone_pickup_before, cb.phone_pickup_after, phone_tally, phone_levelup, phone_bigstory, phone_newfriend,
          phone_journey, phone_friends, phone_wardrobe, phone_book, phone_home]

# ------------------------------------------------------------------ fit check (items composed from anchors, no new art)
import fit as FIT


def fit_tile(k, iid, slot, src, box=150):
    from PIL import Image as _I
    base_src = FIT.SIT[k]
    bw, bh = _I.open(os.path.join(P, base_src)).size
    s = min(box / bw, box / bh) * 0.78
    W, H = bw * s, bh * s
    ox, oy = (box - W) / 2, (box - H) / 2 + 8
    parts = [f'<img src="./{base_src}" alt="" style="position: absolute; left: {ox:.1f}px; top: {oy:.1f}px; width: {W:.1f}px; height: {H:.1f}px;">']
    img = _I.open(os.path.join(P, src))
    pieces = [(slot, None)] if slot not in FIT.PAIRS else [(slot, "l"), (slot + "2", "r")]
    for sl, half in pieces:
        t = FIT.transform(k, iid, sl)
        iw = t["w"] * W
        if half:
            hw = img.width / 2
            ih = img.height * iw / hw
            full = iw * 2
            clip = f'clip-path: inset(0 {50 if half == "l" else 0}% 0 {0 if half == "l" else 50}%);'
            left = ox + t["x"] * W - (iw * t["pivot"][0]) - (0 if half == "l" else iw)
            parts.append(f'<img src="./{src}" alt="" style="position: absolute; left: {left:.1f}px; top: {oy + t["y"] * H - ih * t["pivot"][1]:.1f}px; width: {full:.1f}px; height: {ih:.1f}px; {clip} '
                         f'transform: rotate({t["rot"]}deg); transform-origin: {(25 if half == "l" else 75)}% {t["pivot"][1] * 100:.0f}%;">')
        else:
            ih = img.height * iw / img.width
            parts.append(f'<img src="./{src}" alt="" style="position: absolute; left: {ox + t["x"] * W - iw * t["pivot"][0]:.1f}px; top: {oy + t["y"] * H - ih * t["pivot"][1]:.1f}px; '
                         f'width: {iw:.1f}px; height: {ih:.1f}px; transform: rotate({t["rot"]}deg); transform-origin: {t["pivot"][0] * 100:.0f}% {t["pivot"][1] * 100:.0f}%;">')
    return f'<div style="position: relative; width: {box}px; height: {box}px; overflow: visible;">{"".join(parts)}</div>'


def board_fit():
    order = ["bunny", "hare", "frog", "crow", "cat", "crab", "grasshopper"]
    box, gap = 150, 12
    W = 56 + 160 + 12 * (box + gap) + 40
    rowh = box + 50
    H = 150 + rowh * len(order) + 60
    rows = []
    for r, k in enumerate(order):
        y = 140 + r * rowh
        name = FR[k][1]
        rows.append(f'<div style="position: absolute; left: 56px; top: {y + 60}px; width: 150px;">{T(name, 20, 700, "Fraunces")}'
                    f'{T(str(len(FIT.items_for(k))) + " items", 12.5, 600, "Fredoka", MUTED)}</div>')
        for c, (iid, slot, src) in enumerate(FIT.items_for(k)):
            x = 216 + c * (box + gap)
            rows.append(f'<div style="position: absolute; left: {x}px; top: {y}px; width: {box}px; height: {box + 36}px; border-radius: 14px; background: rgba(251,244,228,0.6);">'
                        f'{fit_tile(k, iid, slot, src, box)}<div style="position: absolute; left: 8px; right: 6px; top: {box + 4}px; font-family: Fredoka, sans-serif; font-weight: 600; font-size: 11px; color: {MUTED};">{iid} · {slot}</div></div>')
    note = T("Every item placed from the anchors in Design/friends/wardrobe-anchors.json, on the sit pose. The built-in accessories (Bramble&#39;s bow, Puddle&#39;s and Nipper&#39;s neckerchiefs, Button&#39;s cap, Marmalade&#39;s collar, Sprig&#39;s satchel, Hare&#39;s scarf) still show underneath: each friend needs an accessory-free base sticker before this ships. Pairs (claw mittens, antenna pom-poms) are split in half, one per claw or antenna.",
             14, 500, "Fredoka", INK, f"position: absolute; left: 56px; top: {H - 70}px; width: {W - 112}px;")
    b = head("Fit check · every item on its friend", "composed live from anchors (no painting), so the numbers are the spec · sit pose; hop frames need their own anchors", w=W - 112) + "".join(rows) + note
    return "CastFit", W, H, b, STATIC_LOGIC, "", "Fit check · every item on its friend"


BOARDS.insert(BOARDS.index(board_suits) + 1, board_fit)


if __name__ == "__main__":
    built = []
    css0 = pw.CSS.replace("var(--sheet)", f"{-(pw.HOP[0] * 116 / pw.HOP[1]) * 8:.0f}px")
    only = set(sys.argv[1:])
    for fn in BOARDS:
        name, w, h, body, logic, css, title = fn()
        built.append((name, w, h, title, logic != STATIC_LOGIC))
        if only and name not in only:
            continue
        open(os.path.join(P, f"{name}.dc.html"), "w").write(dc_doc(f"Hop Tales · {title}", w, h, body, CREAM, logic, css0 + css))
        prev = body.replace('src="./', f'src="file://{P}/').replace("url(./", f"url(file://{P}/")
        prev = re.sub(r"<sc-if value=\"\{\{[^}]+\}\}\" hint-placeholder-val=\"\{\{false\}\}\">.*?</sc-if>", "", prev, flags=re.S)
        prev = prev.replace("{{ring1}}", "border-color: #B8423A; background: #FFFFFF;")
        prev = re.sub(r"\{\{[^}]+\}\}", "", prev)
        open(os.path.join(HERE, "out", "cast", f"{name}.html"), "w").write(
            f"<html><head>{FONTS}<style>body{{margin:0;background:{CREAM}}}{css0}{css}</style></head><body><div style=\"position: relative; width:{w}px; height:{h}px; overflow:hidden; background:{CREAM}\">{prev}</div></body></html>")
    json.dump(built, open(os.path.join(HERE, "out", "cast", "built.json"), "w"))
    print([b[0] for b in built])
