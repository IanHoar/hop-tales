"""Nano Banana jobs for the characters & progression canvas.  usage: python3 gen_cast.py job1 job2 ...  (or a prefix like est_)"""
import os, sys, json, concurrent.futures as cf
os.environ.setdefault("NB_MODEL", "gemini-3.1-flash-image")
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import nb
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "nb", "cast")
os.makedirs(OUT, exist_ok=True)
REF = lambda p: Image.open(os.path.join(HERE, p))

STYLE = ("Hand-painted in delicate watercolour washes with fine sepia ink pen lines and a little soft pencil texture, in the gentle, naturalistic "
         "manner of classic Edwardian English children's nature picture books — cozy, warm and quiet.")
STICKER = ("Surrounded by one even, thick white paper border, as if carefully cut out of a printed book with scissors, with a very subtle soft drop shadow.")
GREY = "Plain flat medium-grey background (#8a8a8a). No text, no ground, no other objects, nothing touching the edges."
ORIG = "An original character design; natural, friendly animal anatomy and proportions — not cartoony, no big head, no giant eyes."
SCENE = ("A hand-crafted paper collage: torn watercolour-painted paper with soft white deckled edges between the layers and visible paper grain. "
         "No animals, people or text.")

CAST = {
    "frog": "a small common frog: olive-green skin with soft brown spots, a pale cream throat and belly, long folded hind legs, golden eyes, wearing a tiny mustard-yellow knotted neckerchief",
    "crow": "a young carrion crow: glossy blue-black feathers with soft grey-blue sheen, a bright curious eye, strong dark beak and feet, wearing a tiny hand-knitted cornflower-blue cap",
    "cat": "a slender young ginger tabby cat with soft cream chest and paws, green eyes and a long striped tail, wearing a thin sage-green ribbon collar with a tiny brass bell",
    "crab": "a small shore crab: warm red-orange shell with sandy speckles, two neat claws and eight jointed legs, eyes on little stalks, wearing a tiny blue-and-white striped sailor neckerchief",
    "grasshopper": "a meadow grasshopper: fresh leaf-green body with a straw-yellow stripe, long powerful folded hind legs, fine antennae, delicate wings, wearing a tiny brown leather satchel on a strap",
    "bunny": "a small round young wild rabbit (clearly a rabbit, not a hare): soft grey-brown fur, short rounded ears, a fluffy white cottontail, big gentle dark eye, wearing a little lilac ribbon bow at the base of one ear",
}
HOP = {
    "frog": ("frog leap", "1 crouched sitting ready, 2 hind legs pushing, body rising, 3 launch with hind legs fully straightening, 4 fully stretched in mid-air, body long, front legs reaching forward, "
             "5 descending, front legs reaching down, 6 front hands touch down, hind legs still trailing, 7 landing crouch as hind legs fold in, 8 settled crouched sitting again"),
    "crow": ("crow two-footed hop", "1 standing upright, 2 crouching down, wings slightly lifted, 3 springing up with both feet together, wings half open, 4 in the air, wings open wide for balance, "
             "5 wings sweeping down, feet reaching forward, 6 both feet landing together, wings up, 7 absorbing the landing, wings folding, 8 standing upright with wings tucked, head tilted curiously"),
    "cat": ("cat bound", "1 sitting upright, 2 crouching low, tail up, weight back, 3 hind legs pushing off, front legs lifting, 4 fully stretched leap, front paws reaching forward, tail streaming, "
            "5 front paws reaching down to land, 6 front paws landing, back arched, hind legs swinging forward, 7 hind paws landing close behind, 8 sitting upright again with tail curled around paws"),
    "crab": ("crab sideways scuttle-hop", "1 standing on its legs, claws raised a little, 2 legs bending, body dipping, 3 springing up and sideways, legs pushing, 4 in the air sideways, legs spread, claws open, "
             "5 dropping, legs reaching down, 6 landing on the tips of its legs, 7 body dipping to absorb the landing, claws lowered, 8 standing again with one claw raised in a little wave"),
    "grasshopper": ("grasshopper spring", "1 resting with long hind legs folded, 2 hind legs coiled tight, body tilting up, 3 hind legs snapping straight, launching steeply, 4 high in the air, legs trailing, "
                    "5 wings flicked open while gliding, 6 wings folding, legs reaching forward, 7 touching down on all front legs, 8 resting again with hind legs folded"),
    "bunny": ("rabbit bounce", "1 sitting in a round loaf, 2 hind feet pushing, bottom rising, 3 springing forward, ears back, 4 in the air, body round and compact, legs tucked, cottontail showing, "
              "5 front paws reaching down, 6 front paws landing, hind legs lifting behind, 7 hind feet landing ahead near front paws, 8 sitting in a round loaf again, ears up"),
}
WORLD = {
    "frog": ("Willow Pond", "a quiet green pond: far willow trees and soft hills, reeds and bulrushes along the far bank, calm water with gentle reflections; across the lower third runs a long even line of flat round lily pads "
             "close together like stepping stones, a few white water-lily flowers and a dragonfly-free sky; soft summer light"),
    "crow": ("Harvest Field", "a golden autumn landscape: far rolling hills with hedgerows and a small stone barn, a stubble field with round hay bales, a few bare trees; across the lower third runs the flat top of a long "
             "old dry-stone wall with moss, like a path; warm late-afternoon light, a few leaves drifting"),
    "cat": ("Cottage Garden", "an English cottage garden: far soft rooftops and chimneys, climbing roses and hollyhocks, terracotta flowerpots, a watering can; across the lower third runs a long flat-topped old brick "
            "garden wall like a path, with a little moss; warm morning light"),
    "crab": ("Rock Pools", "a gentle seashore: far pale sea with a small lighthouse on a headland and soft clouds, low rocks with seaweed and small rock pools, a few shells and pebbles; across the lower third runs a long "
             "flat strip of smooth wet golden sand like a path; fresh breezy light"),
    "grasshopper": ("Tall Grass", "a meadow seen from an insect's height: giant grass stems and seed heads towering up, huge clover leaves, a dandelion and a buttercup as tall as trees, soft sky glimpsed above; across the "
                    "lower third runs a long flat pale bare-earth path with tiny pebbles, like a path at insect scale; dappled summer light"),
    "bunny": ("Bluebell Wood", "a spring woodland: far birch and oak trunks in soft mist, a carpet of bluebells and ferns, a mossy bank with a round rabbit burrow entrance; across the lower third runs a long soft "
              "earth woodland path; gentle dappled light"),
}

JOBS = {}
for k, d in CAST.items():
    JOBS[f"est_{k}"] = dict(prompt=f"A single character sticker: {d}, sitting calmly, side view facing right. {ORIG} {STYLE} {STICKER} {GREY} "
                                   f"Match the paint, line and paper-border style of image 1 exactly (image 1 is only a style reference; do not draw a hare).",
                            refs=["nb/collage/hare-a.png"], aspect="1:1", size="1K")
    name, frames = HOP[k]
    JOBS[f"hop_{k}"] = dict(prompt=f"An animation sheet for a {name}: 8 frames laid out 4 across and 2 rows down, read left to right then top to bottom, each a separate sticker in its own equal cell, "
                                   f"the same character at the same size and scale in every frame, side view facing right: {frames}. Exactly the same character as image 1: same colours, markings, accessory, line "
                                   f"and paint style, same white paper border. The sheet layout, spacing and sticker treatment match image 2 (image 2 shows a different animal; use it only for layout). "
                                   f"Show a believable, natural {k} movement with small changes between neighbouring frames. {STYLE} {GREY}",
                            refs=[f"nb/cast/est_{k}.png", "nb/sprites/jump-sheet.png"], aspect="16:9", size="2K")
    JOBS[f"hop2_{k}"] = dict(prompt=f"An animation sheet for a {name}: 8 frames laid out in a grid 4 across and 2 rows down, read left to right then top to bottom, each a separate sticker in its own equal cell with generous grey space between, "
                                   f"the same single character at the same size and scale in every frame, side view facing right: {frames}. Every frame shows exactly the same {k} as image 1: same species, same body shape, colours, markings, accessory, line "
                                   f"and paint style, and the same thick white paper sticker border. Only {k}s, no other animals. Believable, natural movement with small changes between neighbouring frames. {STYLE} {GREY}",
                            refs=[f"nb/cast/est_{k}.png"], aspect="16:9", size="2K")
    wn, wd = WORLD[k]
    JOBS[f"world_{k}"] = dict(prompt=f"A wide side-scrolling storybook landscape panorama, '{wn}': {wd}. The path band is plain and uncluttered so words can be printed on it. "
                                     f"{SCENE} {STYLE} Match the painting and collage style of image 1 exactly.",
                              refs=["nb/collage/meadow.png"], aspect="21:9", size="2K")

JOBS["items_collect"] = dict(prompt="A sheet of 12 small collectible item stickers, laid out 4 across and 3 rows down, each a separate sticker in its own equal cell, all at a similar size: "
                             "row 1: a fresh orange carrot with leafy green top; a shining golden carrot with a soft glow; a white water-lily flower on a small lily pad; a round shiny brass button. "
                             "row 2: a small ball of red knitting wool; a pale pink scallop seashell; a green three-leaf clover; a rare four-leaf clover with a tiny sparkle. "
                             f"row 3: a wild strawberry with a leaf; a small woven wicker basket; a ribbon rosette award in red and cream; a small golden star. {STYLE} {STICKER} {GREY} "
                             "Match the paint, line and paper-border style of image 1 exactly (image 1 is only a style reference).",
                             refs=["nb/collage/hare-a.png"], aspect="4:3", size="2K")
JOBS["items_wear"] = dict(prompt="A sheet of 12 tiny dress-up clothing item stickers for a small animal character, laid out 4 across and 3 rows down, each a separate sticker in its own equal cell, "
                          "each shown on its own with nobody wearing it, facing right: row 1: a woven straw sun hat with a daisy; a hand-knitted blue bobble hat; a crown of daisies and buttercups; an acorn-cup cap. "
                          "row 2: a folded gold paper crown; a starry midnight-blue wizard hat; a little black pirate hat; a pair of round wire spectacles. "
                          f"row 3: a red polka-dot bow tie; a blue spotted neckerchief; a small brown leather satchel; a short red cape. {STYLE} {STICKER} {GREY} "
                          "Match the paint, line and paper-border style of image 1 exactly (image 1 is only a style reference).",
                          refs=["nb/collage/hare-a.png"], aspect="4:3", size="2K")
WEAR = {"straw": "a woven straw sun hat with a daisy, sitting between his ears", "bobble": "a hand-knitted blue bobble hat with holes for his ears",
        "crown": "a crown of daisies and buttercups around the base of his ears", "wizard": "a starry midnight-blue wizard hat, tilted, and a short red cape",
        "pirate": "a little black pirate hat", "specs": "round wire spectacles and a blue spotted neckerchief instead of the scarf"}
for k, d in WEAR.items():
    JOBS[f"dress_{k}"] = dict(prompt=f"Exactly the same hare as image 1, in exactly the same sitting pose, size, framing and style, now wearing {d}. Everything else unchanged: same fur, same red scarf "
                                     f"(unless replaced), same line and paint style, same thick white paper sticker border around the whole figure including the new item. {GREY}",
                              refs=["nb/collage/hare-sit.png"], aspect="3:4", size="1K")


def run(name):
    j = JOBS[name]
    path = os.path.join(OUT, f"{name}.png")
    im, text, usage = nb.generate(j["prompt"], [REF(r) for r in j["refs"]], j["aspect"], j["size"])
    im.save(path)
    return name, im.size, usage.get("totalTokenCount")


if __name__ == "__main__":
    names = [n for a in sys.argv[1:] for n in JOBS if n == a or n.startswith(a)]
    with cf.ThreadPoolExecutor(8) as ex:
        for f in cf.as_completed([ex.submit(run, n) for n in names]):
            try:
                print(*f.result(), flush=True)
            except BaseException as e:
                print("FAIL", e, flush=True)
