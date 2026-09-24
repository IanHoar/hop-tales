import numpy as np, json
from PIL import Image
from sprites_build import cut, best_shift, place, OUT
idle = cut('nb/sprites/idle-sheet.png'); tw = cut('nb/sprites/idle-tween-sheet.png')
print(len(idle), len(tw))
# frame table: name -> source
F = [("rest", idle[1]), ("sniff", idle[2]), ("ear", idle[3]), ("blink", idle[5]), ("tilt", idle[6]),
     ("blink-half", tw[1]), ("ear-1", tw[2]), ("ear-2", tw[3]), ("tilt-1", tw[4]), ("tilt-2", tw[5])]
base = F[0][1]
# match scale to base by alpha area
def rescale(f, ref):
    s = np.sqrt((ref[..., 3] > 128).sum() / max(1, (f[..., 3] > 128).sum()))
    if abs(s - 1) < 0.01: return f
    im = Image.fromarray(f.clip(0, 255).astype(np.uint8), 'RGBA'); im = im.resize((int(im.width * s), int(im.height * s)), Image.LANCZOS)
    return np.asarray(im).astype(np.float32)
frames = [rescale(f, base) if i else f for i, (n, f) in enumerate(F)]
offs = [(30, 0)] + [best_shift(base, f) for f in frames[1:]]
cells, W, H = place(frames, offs)
S = 0.5; w, h = int(W * S), int(H * S)
sheet = Image.new('RGBA', (w * len(cells), h))
for i, c in enumerate(cells):
    sheet.alpha_composite(Image.fromarray(c.clip(0, 255).astype(np.uint8), 'RGBA').resize((w, h), Image.LANCZOS), (i * w, 0))
sheet.save(f'{OUT}/hare-idle-frames.png', optimize=True); sheet.save(f'{OUT}/hare-idle-frames.webp', quality=90, method=6)
names = [n for n, _ in F]
# timeline: (start seconds, [(frame, hold seconds), ...]) ; rest is shown underneath the whole time
T = 18.0
tl = [
    (2.4, [("blink-half", .05), ("blink", .09), ("blink-half", .06)]),
    (5.6, [("ear-1", .09), ("ear-2", .09), ("ear", 1.1), ("ear-2", .1), ("ear-1", .1)]),
    (8.3, [("tilt-1", .14), ("tilt-2", .14), ("tilt", 2.6), ("tilt-2", .16), ("tilt-1", .16)]),
    (10.1, [("blink-half", .05), ("blink", .08), ("blink-half", .05)]),
    (12.9, [("blink-half", .05), ("blink", .09), ("blink-half", .06)]),
    (13.3, [("blink-half", .05), ("blink", .08), ("blink-half", .05)]),
    (15.8, [("sniff", .5)]),
]
json.dump({"frame": [w, h], "names": names, "loop_seconds": T, "timeline": [{"at": a, "frames": [{"frame": names.index(f), "name": f, "hold": d} for f, d in seq]} for a, seq in tl]},
          open(f'{OUT}/idle-timeline.json', 'w'), indent=1)
print(sheet.size, w, h)
b = Image.new('RGBA', sheet.size, (190, 214, 170, 255)); b.alpha_composite(sheet); b.resize((sheet.width // 2, sheet.height // 2)).save('/tmp/idleframes.png')
