"""Frame the rendered app screens as App Store screenshots.

Reads build/store-screenshots/raw (from StoreScreenshotTests) and writes
build/store-screenshots/out/{phone,pad}-<n>-<screen>.png at 1320 x 2868 and 2064 x 2752.

Each PANELS row is (screen, headline, subline, background RGB, stickers), where a sticker is
(World/Resources art name, side of the device, width as a share of the canvas[, flipped]).
"""
from PIL import Image, ImageDraw, ImageFont, ImageFilter
import os, sys
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
RAW = f'{ROOT}/build/store-screenshots/raw'
OUT = f'{ROOT}/build/store-screenshots/out'
FONTS = f'{ROOT}/HopTalesPackage/Sources/DesignSystem/Resources/Fonts'
ART = f'{ROOT}/HopTalesPackage/Sources/World/Resources'
CREAM = (255, 246, 226)

PANELS = [
    ('bob-bug', 'Read a word.\nWatch them hop.', 'Every word read aloud moves the story on', (30, 140, 140), [('hare-front-sit', 'right', 0.30)]),
    ('button-big-story', 'Stories that\ncome alive', 'Sun, rain and moonlight change as you read', (27, 23, 56), [('friend-cat', 'left', 0.34)]),
    ('new-friend', 'Seven friends\nto unlock', 'Finish a big story to meet someone new', (219, 42, 46), [('friend-crow', 'left', 0.32), ('friend-crab', 'right', 0.36)]),
    ('barnacle-shells', 'From first words\nto big stories', '34 stories across seven reading levels', (14, 61, 70), [('friend-grasshopper', 'right', 0.42)]),
    ('home', 'A journey all\ntheir own', 'Level up, dress up and fill the story book', (199, 134, 26), [('friend-frog', 'left', 0.36)]),
    ('rain-on-the-field', 'Private by design', 'Speech stays on the device. No ads, no accounts.', (94, 128, 78), [('friend-bunny', 'right', 0.32, True)]),
]

def font(name, size): return ImageFont.truetype(f'{FONTS}/{name}', size)

def rounded_mask(size, r):
    m = Image.new('L', size, 0); ImageDraw.Draw(m).rounded_rectangle((0, 0, size[0] - 1, size[1] - 1), r, fill=255); return m

def shadow(canvas, box, r, blur, alpha, offset):
    s = Image.new('RGBA', canvas.size, (0, 0, 0, 0))
    x0, y0, x1, y1 = box
    ImageDraw.Draw(s).rounded_rectangle((x0 + offset[0], y0 + offset[1], x1 + offset[0], y1 + offset[1]), r, fill=(0, 0, 0, alpha))
    canvas.alpha_composite(s.filter(ImageFilter.GaussianBlur(blur)))

def device(canvas, shot, left, top, width, kind):
    W, H = canvas.size
    bezel = int(width * (0.034 if kind == 'phone' else 0.026))
    sw = width - 2 * bezel
    sh = int(shot.height * sw / shot.width)
    fh = sh + 2 * bezel
    r_out = int(width * (0.15 if kind == 'phone' else 0.055))
    r_in = r_out - bezel
    box = (left, top, left + width, top + fh)
    shadow(canvas, box, r_out, 40, 110, (0, 30))
    frame = Image.new('RGBA', (width, fh), (0, 0, 0, 0))
    d = ImageDraw.Draw(frame)
    d.rounded_rectangle((0, 0, width - 1, fh - 1), r_out, fill=(28, 26, 34))
    d.rounded_rectangle((3, 3, width - 4, fh - 4), r_out - 3, outline=(88, 84, 98), width=4)
    screen = shot.resize((sw, sh), Image.LANCZOS)
    frame.paste(screen, (bezel, bezel), rounded_mask((sw, sh), r_in))
    if kind == 'phone':
        iw, ih = int(sw * 0.29), int(sw * 0.085)
        d.rounded_rectangle(((width - iw) // 2, bezel + int(sw * 0.028), (width + iw) // 2, bezel + int(sw * 0.028) + ih), ih // 2, fill=(8, 8, 10))
    canvas.alpha_composite(frame, (left, top))
    return box

def sticker(canvas, name, side, scale, box, kind, flip=False):
    im = Image.open(f'{ART}/{name}.webp').convert('RGBA')
    if flip: im = im.transpose(Image.FLIP_LEFT_RIGHT)
    W, H = canvas.size
    w = int(W * scale)
    im = im.resize((w, int(im.height * w / im.width)), Image.LANCZOS)
    x0, y0, x1, y1 = box
    y = H - im.height - int(H * 0.012)
    x = x0 - int(w * 0.42) if side == 'left' else x1 - int(w * 0.58)
    x = max(-int(w * 0.10), min(W - int(w * 0.90), x))
    sh = Image.new('RGBA', canvas.size, (0, 0, 0, 0))
    alpha = im.split()[3].point(lambda a: int(a * 0.45))
    blk = Image.new('RGBA', im.size, (0, 0, 0, 255)); blk.putalpha(alpha)
    sh.alpha_composite(blk, (x + 10, y + 26))
    canvas.alpha_composite(sh.filter(ImageFilter.GaussianBlur(18)))
    canvas.alpha_composite(im, (x, y))

def background(size, colour):
    W, H = size
    bg = Image.new('RGBA', size, colour + (255,))
    glow = Image.new('L', size, 0)
    ImageDraw.Draw(glow).ellipse((-W * 0.4, -H * 0.25, W * 1.4, H * 0.45), fill=70)
    glow = glow.filter(ImageFilter.GaussianBlur(W * 0.12))
    light = Image.new('RGBA', size, tuple(min(255, c + 60) for c in colour) + (255,))
    bg = Image.composite(light, bg, glow)
    dots = Image.new('RGBA', size, (0, 0, 0, 0)); d = ImageDraw.Draw(dots)
    import random; rnd = random.Random(7)
    for _ in range(90):
        x, y, r = rnd.randint(0, W), rnd.randint(0, H), rnd.randint(2, 6)
        d.ellipse((x - r, y - r, x + r, y + r), fill=CREAM + (rnd.randint(18, 45),))
    bg.alpha_composite(dots)
    return bg

def headline(canvas, title, sub, kind):
    W, H = canvas.size
    d = ImageDraw.Draw(canvas)
    size = int(W * (0.105 if kind == 'phone' else 0.072))
    f = font('Fraunces-Bold.ttf', size)
    top = int(H * (0.055 if kind == 'phone' else 0.045))
    d.multiline_text((W // 2, top), title, font=f, fill=CREAM, anchor='ma', align='center', spacing=int(size * 0.12))
    bb = d.multiline_textbbox((W // 2, top), title, font=f, anchor='ma', align='center', spacing=int(size * 0.12))
    fs = font('Fredoka-SemiBold.ttf', int(size * 0.40))
    d.text((W // 2, bb[3] + int(size * 0.38)), sub, font=fs, fill=CREAM + (225,), anchor='ma')
    return bb[3] + int(size * 0.38) + int(size * 0.5)

def titles(kind, W):
    out = []
    for shot, title, sub, colour, stickers in PANELS:
        if kind == 'pad':
            one = title.replace('\n', ' ')
            f = font('Fraunces-Bold.ttf', int(W * 0.072))
            title = one if ImageDraw.Draw(Image.new('RGB', (1, 1))).textlength(one, font=f) < W * 0.86 else title
        out.append(title)
    return out

def build(kind):
    W, H = (1320, 2868) if kind == 'phone' else (2064, 2752)
    heads = titles(kind, W)
    lowest = max(headline(Image.new('RGBA', (W, H)), t, p[2], kind) for t, p in zip(heads, PANELS))
    for n, (shot, title, sub, colour, stickers) in enumerate(PANELS, 1):
        title = heads[n - 1]
        canvas = background((W, H), colour)
        headline(canvas, title, sub, kind)
        bottom = lowest
        img = Image.open(f'{RAW}/shot.{kind}-{shot}.png').convert('RGB')
        width = int(W * (0.76 if kind == 'phone' else 0.80))
        top = bottom + int(H * 0.035)
        box = device(canvas, img, (W - width) // 2, top, width, kind)
        for name, side, scale, *flip in stickers:
            sticker(canvas, name, side, scale if kind == 'phone' else scale * 0.62, box, kind, bool(flip and flip[0]))
        canvas.convert('RGB').save(f'{OUT}/{kind}-{n}-{shot}.png')

if __name__ == '__main__':
    os.makedirs(OUT, exist_ok=True)
    for kind in sys.argv[1:] or ['phone', 'pad']:
        build(kind)
