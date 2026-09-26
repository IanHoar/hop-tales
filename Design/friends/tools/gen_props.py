"""Story event props: the creatures, people and things that turn up in a story's scene.

  gen [sheet ...]    ask Nano Banana for each sheet (raw into nb/props/<sheet>.png); all sheets if none named
  cut [sheet ...]    cut each sheet into stickers and write cast-<name>.webp, or cast-<name>-1/-2.webp for
                     the two walk or wing frames, into HopTalesPackage/Sources/World/Resources
  board              contact sheet of every cut prop into the scratchpad-friendly nb/props/board.png

Walkers and fliers are painted as two poses side by side, facing left, so code moves them across the scene and
swaps the frames. Everything else is one still sticker. props.json in Content lists the cast the stories use.
"""
import concurrent.futures as cf
import json
import math
import os
import sys

import numpy as np
from PIL import Image
from scipy import ndimage as ndi

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
sys.path.insert(0, os.path.join(ROOT, "Design", "collage", "tools"))
os.environ.setdefault("NB_MODEL", "gemini-3.1-flash-image")

RAW = os.path.join(HERE, "nb", "props")
OUT = os.path.join(ROOT, "HopTalesPackage", "Sources", "World", "Resources")
PROPS = json.load(open(os.path.join(ROOT, "HopTalesPackage", "Sources", "Content", "Resources", "props.json")))
os.makedirs(RAW, exist_ok=True)

STYLE = ("Hand-painted in delicate watercolour washes with fine sepia ink pen lines and a little soft pencil texture, in the "
         "gentle, naturalistic manner of classic Edwardian English children's nature picture books — cozy, warm and quiet.")
STICKER = ("Each one is surrounded by one even, thick white paper border, as if carefully cut out of a printed book with "
           "scissors, with a very subtle soft drop shadow.")
GREY = ("Plain flat medium-grey background (#8a8a8a) between them. No text, no labels, no ground, no scenery, "
        "and nothing touching another sticker or the edges.")
NATURAL = "Natural, friendly anatomy and proportions — not cartoony, no big heads, no giant eyes."

PAIRS = {
    "walk-small": ("1:1", "1K", [
        ("bug", "a small round red ladybird-like beetle with black spots, walking on six little legs"),
        ("worm", "a pink-brown earthworm inching along, its body arched in one pose and stretched in the other"),
        ("snail", "a garden snail with a swirled brown shell, stretching forward then drawing in"),
        ("beetle", "a shiny green-bronze garden beetle walking on six legs"),
    ]),
    "walk-critters": ("1:1", "1K", [
        ("cricket", "a small brown field cricket with long antennae, walking"),
        ("hamster", "a round golden hamster with white cheeks, scurrying on all fours"),
        ("hedgehog", "a small brown hedgehog with soft spines, trundling on little legs"),
        ("frog", "a plain common frog, olive-green with brown spots, no clothing, crawling forward on all fours"),
    ]),
    "walk-animals": ("1:1", "1K", [
        ("hen", "a plump russet-brown farm hen with a red comb, strutting"),
        ("kitten", "a small fluffy grey tabby kitten, padding along"),
        ("cat", "a grown grey tabby mother cat with a white chest, walking calmly"),
        ("seal", "a grey harbour seal with soft spots, humping along on its belly and flippers"),
    ]),
    "walk-people": ("1:1", "2K", [
        ("mum", "a grown-up wild rabbit mother, soft grey-brown fur, wearing a small checked apron, hopping on all fours"),
        ("child", "a young child of about six in a yellow raincoat and red wellington boots, walking happily"),
        ("farmer", "a kindly farmer in a flat cap, brown waistcoat and wellington boots, walking and carrying a tin bucket"),
    ]),
    "walk-grandma": ("3:2", "1K", [
        ("grandma", "a kind grandmother with grey hair in a bun and round glasses, in a long skirt, cardigan and "
                    "walking shoes, strolling outdoors with a wicker knitting basket on her arm and a half-knitted "
                    "green scarf trailing from it"),
    ]),
    "fly-bugs": ("1:1", "1K", [
        ("butterfly", "a small butterfly with orange and brown wings, wings open wide in one pose and raised together in the other"),
        ("moth", "a soft dusty brown-and-cream moth, wings spread in one pose and lifted in the other"),
        ("bee", "a fuzzy round bumblebee, black and golden-yellow, wings up in one pose and down in the other"),
        ("ladybird", "a red ladybird with black spots flying, wing cases open, wings up then down"),
    ]),
    "fly-more": ("1:1", "1K", [
        ("dragonfly", "a slender blue dragonfly with four clear veined wings, wings forward then back"),
        ("firefly", "a small dark firefly with a softly glowing pale yellow-green tail, wings up then down"),
        ("fish", "a small silvery-green minnow swimming, tail flicked one way then the other"),
        ("gull", "a white and grey seagull flying, wings raised high in one pose and swept down in the other"),
    ]),
    "fly-birds": ("3:2", "1K", [
        ("thrush", "a song thrush with a speckled cream breast and brown back, flying with wings up then wings down"),
        ("owl", "a tawny owl with round face and warm brown mottled feathers, flying with wings up then wings down"),
    ]),
}
STILLS = {
    "still-small": ("1:1", "1K", [
        ("log", "a short mossy fallen log lying on its side"),
        ("stone", "a smooth grey river stone"),
        ("lilypad", "a single flat round green lily pad with a notch, no flower"),
        ("nest", "a round bird's nest of woven twigs and straw, empty"),
        ("shell", "a pink spiral sea snail shell"),
        ("starfish", "an orange starfish"),
        ("twig", "a small fallen twig with two leaves"),
        ("puddle", "a small shallow muddy puddle seen from the side, flat and wide"),
    ]),
    "still-things": ("1:1", "1K", [
        ("splash", "a small splash of pond water with droplets flying up"),
        ("kite", "a red diamond kite with a long ribbon tail and bows"),
        ("boat", "a small folded paper boat"),
        ("wool", "a ball of green knitting wool with a loose strand"),
        ("roses", "a small rambling pink rose bush"),
        ("lantern", "a round paper party lantern, pale pink, hanging from a string"),
        ("bubbles", "a cluster of five soap bubbles of different sizes with rainbow sheen"),
        ("bottle", "a green glass bottle with a cork and a rolled paper message inside, lying on its side"),
        ("mushroom", "a large red toadstool with white spots"),
    ]),
    "still-tall": ("16:9", "2K", [
        ("scarecrow", "a friendly old scarecrow in a patched blue jacket and straw hat on a wooden post"),
        ("sunflower", "one very tall sunflower with a big golden head and leaves"),
        ("seaweed", "a tall frond of brown-green kelp seaweed"),
        ("lighthouse", "a small white lighthouse with a red stripe and lamp room on a little rock"),
        ("pine", "a tall slender Scots pine tree"),
        ("rainbow", "a soft watercolour rainbow arc, standing on its two ends"),
    ]),
}
TRUNKS = {
    "oak": ("the base of an enormous ancient oak seen close up from the ground, as a grasshopper would see it: a vast "
            "gnarled trunk with deeply ridged bark, moss and ivy, huge twisted roots spreading across the ground, the "
            "trunk rising straight out of the top edge of the picture so no leaves or crown are visible"),
}
SHEETS = {**PAIRS, **STILLS}


def target(name):
    prop = PROPS[name]
    if not prop.get("sticker", True):
        return math.ceil(prop["height"] * 3)
    return math.ceil(min(prop["height"] * 4, 260) * 3)


def pair_prompt(rows):
    lines = " ".join(f"Row {i + 1}: {desc}." for i, (_, desc) in enumerate(rows))
    return (f"A sheet of {len(rows) * 2} die-cut stickers in {len(rows)} rows of two. Each row is one creature shown twice, "
            "side by side, as the two frames of a simple loop: the same creature at exactly the same size, colours and "
            "height, facing left, seen from the side, with only the legs, wings, tail or body pose changed between the "
            f"two. {lines} {STYLE} {NATURAL} {STICKER} {GREY}")


def still_prompt(rows):
    columns = 3 if len(rows) == 9 else 4
    lines = " ".join(f"{i + 1}: {desc}." for i, (_, desc) in enumerate(rows))
    return (f"A sheet of {len(rows)} separate die-cut stickers in a grid of {columns} columns, read left to right and top "
            f"to bottom: {lines} Each is a whole object seen from the side, standing upright. {STYLE} {STICKER} {GREY}")


def gen_trunk(name):
    import nb
    prompt = (f"One painting of {TRUNKS[name]}. {STYLE} No sticker border. {GREY} The trunk and roots may touch the "
              "top edge, but nothing else touches any edge.")
    image, text, _ = nb.generate(prompt, [], "3:4", "2K")
    image.save(os.path.join(RAW, f"trunk-{name}.png"))
    return f"trunk-{name}: {text}"


def cut_trunk(name):
    a = np.asarray(Image.open(os.path.join(RAW, f"trunk-{name}.png")).convert("RGB")).astype(np.float32)
    bg = np.median(np.concatenate([a[-6:].reshape(-1, 3), a[:, :6].reshape(-1, 3)]), 0)
    d = np.sqrt(((a - bg) ** 2).sum(2))
    fg = ndi.binary_fill_holes(ndi.binary_opening(d > 26, iterations=2))
    lab, _ = ndi.label(fg)
    sizes = ndi.sum(fg, lab, index=np.arange(1, lab.max() + 1))
    keep = lab == (np.argmax(sizes) + 1)
    alpha = np.where(keep, np.clip((d - 14) * 18, 0, 255), 0)
    alpha = ndi.gaussian_filter(alpha, 0.7)
    image = Image.fromarray(np.dstack([a, alpha]).clip(0, 255).astype(np.uint8))
    fit(image, target(name)).save(os.path.join(OUT, f"cast-{name}.webp"), quality=88)
    return f"trunk-{name}: cut"


def gen(sheet):
    import nb
    aspect, size, rows = SHEETS[sheet]
    prompt = pair_prompt(rows) if sheet in PAIRS else still_prompt(rows)
    image, text, _ = nb.generate(prompt, [], aspect, size)
    image.save(os.path.join(RAW, f"{sheet}.png"))
    return f"{sheet}: {text}"


def components(path):
    a = np.asarray(Image.open(path).convert("RGB")).astype(np.float32)
    bg = np.median(np.concatenate([a[:6].reshape(-1, 3), a[-6:].reshape(-1, 3)]), 0)
    d = np.sqrt(((a - bg) ** 2).sum(2))
    fg = ndi.binary_fill_holes(ndi.binary_opening(d > 26, iterations=2))
    lab, n = ndi.label(fg)
    boxes = []
    for index, box in enumerate(ndi.find_objects(lab), start=1):
        area = (lab[box] == index).sum()
        if area > fg.size * 0.004:
            boxes.append((box, index, area))
    alpha = np.clip((d - 14) * 18, 0, 255).astype(np.uint8)
    rgba = np.dstack([a.astype(np.uint8), alpha])
    pieces = []
    for box, index, _ in boxes:
        mask = ndi.binary_dilation(lab[box] == index, iterations=2)
        piece = rgba[box].copy()
        piece[..., 3] = np.where(mask, piece[..., 3], 0)
        ys, xs = box
        pieces.append(((ys.start + ys.stop) / 2, (xs.start + xs.stop) / 2, Image.fromarray(piece)))
    return pieces


PICKS = {
    "bug": [(0, True), (1, False)], "worm": [(0, False), (1, False)], "snail": [(0, True), (1, True)],
    "beetle": [(0, True), (1, True)], "cricket": [(0, True), (1, True)], "hamster": [(0, True), (1, True)],
    "hedgehog": [(0, True), (1, True)], "frog": [(0, True), (3, True)], "hen": [(0, True), (1, True)],
    "kitten": [(0, True), (1, True)], "cat": [(0, True), (1, True)], "seal": [(0, True), (1, True)],
    "mum": [(0, True), (1, True)], "child": [(0, True), (1, True)], "farmer": [(0, True), (1, True)],
    "butterfly": [(0, False), (1, False)], "moth": [(0, False), (1, False)], "bee": [(1, False), (3, False)],
    "ladybird": [(0, True), (1, False)], "dragonfly": [(0, False), (1, False)],
    "firefly": [(0, False), (1, False)], "fish": [(0, False), (1, False)], "gull": [(0, True), (1, True)],
    "thrush": [(0, True), (1, False)], "owl": [(0, True), (1, False)],
    "grandma": [(0, True), (1, True)],
}
SKIPS = {"still-tall": [4, 6, 7], "still-things": [7], "still-small": [4]}


def rows_of(pieces):
    pieces = sorted(pieces, key=lambda p: p[0])
    heights = sorted(p[2].height for p in pieces)
    gap = heights[len(heights) // 2] * 0.5
    rows = [[pieces[0]]]
    for piece in pieces[1:]:
        if piece[0] - rows[-1][-1][0] > gap:
            rows.append([])
        rows[-1].append(piece)
    return [[p[2] for p in sorted(row, key=lambda p: p[1])] for row in rows]


def unsticker(image, gaps=False):
    rgba = np.asarray(image.convert("RGBA")).astype(np.float32)
    rgb, alpha = rgba[..., :3], rgba[..., 3]
    paper = (rgb.min(2) > 200) & (rgb.max(2) - rgb.min(2) < 30) & (alpha > 128)
    lab, count = ndi.label(paper)
    if count == 0:
        return image
    sizes = ndi.sum(paper, lab, index=np.arange(1, count + 1))
    ring = lab == (np.argmax(sizes) + 1)
    inside = ndi.binary_fill_holes(ring) & ~ndi.binary_dilation(ring, iterations=2)
    if gaps:
        pure = (rgb.min(2) > 236) & (rgb.max(2) - rgb.min(2) < 16)
        holes, _ = ndi.label(pure & inside)
        big = [index for index, size in enumerate(ndi.sum(pure, holes, index=np.arange(1, holes.max() + 1)), 1) if size > 40]
        inside &= ~np.isin(holes, big)
    alpha = np.where(inside, alpha, 0)
    alpha = ndi.gaussian_filter(alpha, 0.7)
    return Image.fromarray(np.dstack([rgb, alpha]).clip(0, 255).astype(np.uint8))


def fit(image, height):
    image = image.crop(image.getbbox())
    scale = min(1, height / image.height)
    return image.resize((max(1, round(image.width * scale)), max(1, round(image.height * scale))), Image.LANCZOS)


def cut(sheet):
    _, _, cast = SHEETS[sheet]
    rows = rows_of(components(os.path.join(RAW, f"{sheet}.png")))
    written = 0
    if sheet in PAIRS:
        if len(rows) < len(cast):
            raise SystemExit(f"{sheet}: found {len(rows)} rows, expected {len(cast)}")
        rows = rows[:len(cast)]
        for (name, _), row in zip(cast, rows):
            frames = []
            for index, flip in PICKS[name]:
                frame = row[index].crop(row[index].getbbox())
                frames.append(frame.transpose(Image.FLIP_LEFT_RIGHT) if flip else frame)
            height = target(name)
            scale = min(1, height / max(frame.height for frame in frames))
            for number, frame in enumerate(frames, start=1):
                size = (max(1, round(frame.width * scale)), max(1, round(frame.height * scale)))
                frame.resize(size, Image.LANCZOS).save(os.path.join(OUT, f"cast-{name}-{number}.webp"), quality=88)
                written += 1
    else:
        pieces = [piece for row in rows for piece in row]
        pieces = [piece for index, piece in enumerate(pieces) if index not in SKIPS.get(sheet, [])]
        if len(pieces) != len(cast):
            raise SystemExit(f"{sheet}: found {len(pieces)} stickers, expected {len(cast)}")
        for (name, _), piece in zip(cast, pieces):
            if not PROPS[name].get("sticker", True):
                piece = unsticker(piece, gaps=name in ("oak", "pine"))
            fit(piece, target(name)).save(os.path.join(OUT, f"cast-{name}.webp"), quality=88)
            written += 1
    return f"{sheet}: {written} stickers"


def board():
    names = sorted(f for f in os.listdir(OUT) if f.startswith("cast-"))
    tiles = [Image.open(os.path.join(OUT, n)).convert("RGBA") for n in names]
    cell = 180
    columns = 10
    sheet = Image.new("RGBA", (cell * columns, cell * math.ceil(len(tiles) / columns)), (138, 138, 138, 255))
    for i, tile in enumerate(tiles):
        tile.thumbnail((cell - 10, cell - 10))
        x, y = (i % columns) * cell, (i // columns) * cell
        sheet.alpha_composite(tile, (x + (cell - tile.width) // 2, y + (cell - tile.height) // 2))
    sheet.save(os.path.join(RAW, "board.png"))
    return os.path.join(RAW, "board.png")


if __name__ == "__main__":
    command, *names = sys.argv[1:] or ["help"]
    names = names or list(SHEETS)
    if command == "gen":
        with cf.ThreadPoolExecutor(4) as pool:
            for line in pool.map(gen, names):
                print(line)
    elif command == "cut":
        for name in names:
            print(cut(name))
    elif command == "trunk":
        for name in (sys.argv[2:] or list(TRUNKS)):
            print(gen_trunk(name))
    elif command == "cut-trunk":
        for name in (sys.argv[2:] or list(TRUNKS)):
            print(cut_trunk(name))
    elif command == "board":
        print(board())
    else:
        print(__doc__)
