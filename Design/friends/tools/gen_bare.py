"""Accessory-free base stickers, so wardrobe items can replace or sit where the built-in accessory was."""
import os, sys, concurrent.futures as cf
os.environ.setdefault("NB_MODEL", "gemini-3.1-flash-image")
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import nb
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = {"bunny": ("nb/cast/est_bunny.png", "the lilac ribbon bow on its ear", "the ear"),
       "frog": ("nb/cast/est_frog.png", "the yellow neckerchief", "the throat and shoulders"),
       "crow": ("nb/cast/est_crow.png", "the blue knitted cap", "the glossy black feathered head"),
       "cat": ("nb/cast/est_cat.png", "the green ribbon collar and bell", "the neck fur"),
       "crab": ("nb/cast/est_crab.png", "the striped neckerchief", "the front of the shell"),
       "grasshopper": ("nb/cast/est_grasshopper.png", "the little leather satchel and its strap", "the body"),
       "hare": ("nb/collage/hare-sit.png", "the red knitted scarf", "the neck and chest fur")}


def run(k):
    src, acc, part = SRC[k]
    im = Image.open(os.path.join(HERE, src))
    out, _, _ = nb.generate(f"Edit this image: remove {acc} and paint {part} naturally where it was. Keep everything else exactly the same: the same character, the same pose, "
                            f"position, size and framing, the same colours, line and paint style, the same thick white paper sticker border and soft shadow, the same plain grey background.",
                            [im], "1:1", "1K")
    out.save(os.path.join(HERE, "nb", "cast", f"bare_{k}.png"))
    return k


if __name__ == "__main__":
    with cf.ThreadPoolExecutor(7) as ex:
        for f in cf.as_completed([ex.submit(run, k) for k in SRC]):
            print(f.result(), flush=True)
