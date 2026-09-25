"""8-item dress-up suites for each new friend, plus two dressed previews each.  usage: python3 gen_suits.py [prefix ...]"""
import os, sys, concurrent.futures as cf
os.environ.setdefault("NB_MODEL", "gemini-3.1-flash-image")
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import nb
from gen_cast import STYLE, STICKER, GREY, REF, OUT

# friend -> (anatomy note, [(id, name, slot, description)], outfit A ids, outfit B ids)
SUITS = {
    "bunny": ("a small round wild rabbit with short rounded ears", [
        ("bluebell-crown", "Bluebell crown", "head", "a crown woven from bluebells and small leaves"),
        ("bonnet", "Straw bonnet", "head", "a little straw bonnet with a lilac ribbon, with gaps for two short ears"),
        ("headscarf", "Polka-dot headscarf", "head", "a red polka-dot headscarf knotted on top"),
        ("heart-glasses", "Heart glasses", "eyes", "a pair of pink heart-shaped glasses"),
        ("daisy-chain", "Daisy chain", "neck", "a daisy-chain necklace"),
        ("berry-kerchief", "Strawberry neckerchief", "neck", "a cream neckerchief printed with tiny strawberries"),
        ("basket-pack", "Wicker backpack", "back", "a tiny woven wicker backpack with leather straps"),
        ("shawl", "Lilac shawl", "body", "a soft knitted lilac shawl"),
    ], ["bluebell-crown", "daisy-chain"], ["heart-glasses", "basket-pack"]),
    "frog": ("a small common frog with no ears and a wide head", [
        ("lilypad-hat", "Lily-pad hat", "head", "a sun hat made from a lily pad with a small white water-lily on top"),
        ("souwester", "Rain hat", "head", "a tiny yellow sou'wester rain hat"),
        ("frog-crown", "Golden crown", "head", "a small golden fairy-tale crown"),
        ("goggles", "Swimming goggles", "eyes", "a pair of round blue swimming goggles"),
        ("check-bowtie", "Check bow tie", "neck", "a green-and-cream check bow tie"),
        ("swim-ring", "Swim ring", "body", "a small red-and-white striped swim ring"),
        ("reed-satchel", "Reed satchel", "back", "a little satchel woven from reeds"),
        ("raincoat", "Raincoat", "body", "a tiny yellow raincoat with toggles"),
    ], ["frog-crown", "check-bowtie"], ["goggles", "swim-ring"]),
    "crow": ("a young crow with a strong beak and folded wings", [
        ("flat-cap", "Tweed flat cap", "head", "a brown tweed flat cap"),
        ("scarecrow-hat", "Scarecrow hat", "head", "a battered straw scarecrow hat with a patch"),
        ("top-hat", "Top hat", "head", "a tiny black top hat with a red band"),
        ("aviator-goggles", "Flying goggles", "eyes", "a pair of brass-rimmed flying goggles on a leather strap"),
        ("autumn-scarf", "Autumn scarf", "neck", "a knitted scarf in orange, mustard and brown stripes"),
        ("pocket-watch", "Pocket watch", "neck", "a small brass pocket watch on a chain, worn as a pendant"),
        ("waistcoat", "Patchwork waistcoat", "body", "a patchwork waistcoat with shiny mismatched buttons"),
        ("post-satchel", "Postbag", "back", "a small red postman's bag on a strap"),
    ], ["top-hat", "autumn-scarf"], ["aviator-goggles", "post-satchel"]),
    "cat": ("a slender young cat with pointed ears", [
        ("garden-hat", "Gardening hat", "head", "a wide straw gardening hat with holes for pointed ears and a pink rose"),
        ("beret", "Beret", "head", "a small raspberry-red beret"),
        ("rose-clip", "Rose clip", "head", "a hair clip with a small pink garden rose"),
        ("cateye-glasses", "Cat-eye glasses", "eyes", "a pair of tortoiseshell cat-eye glasses"),
        ("lace-collar", "Lace collar", "neck", "a round white lace collar"),
        ("red-bell-collar", "Red bell collar", "neck", "a red ribbon collar with a little golden bell"),
        ("apron", "Gardening apron", "body", "a small green gardening apron with a pocket holding a trowel"),
        ("cardigan", "Knitted cardigan", "body", "a tiny cream knitted cardigan with wooden buttons"),
    ], ["garden-hat", "apron"], ["cateye-glasses", "lace-collar"]),
    "crab": ("a small shore crab with eyes on stalks and two claws", [
        ("sailor-cap", "Sailor cap", "head", "a white sailor cap with a blue band"),
        ("bandana", "Pirate bandana", "head", "a red pirate bandana with white spots"),
        ("captain-hat", "Captain's hat", "head", "a navy captain's hat with a gold anchor badge"),
        ("diving-mask", "Diving mask", "eyes", "a small old-fashioned diving mask"),
        ("eyepatch", "Eyepatch", "eyes", "a black pirate eyepatch"),
        ("life-ring", "Life ring", "body", "a small red-and-white life ring"),
        ("claw-mittens", "Claw mittens", "claws", "a pair of striped knitted mittens shaped for crab claws"),
        ("chest-pack", "Treasure backpack", "back", "a tiny wooden treasure-chest backpack with brass corners"),
    ], ["captain-hat", "life-ring"], ["bandana", "eyepatch"]),
    "grasshopper": ("a slender grasshopper with long antennae and long hind legs", [
        ("acorn-cap", "Acorn cap", "head", "an acorn-cup cap"),
        ("leaf-hat", "Leaf hat", "head", "a tiny hat made from a curled green leaf"),
        ("antenna-poms", "Antenna pom-poms", "antennae", "a pair of tiny yellow woolly pom-poms for the tips of antennae"),
        ("explorer-goggles", "Explorer goggles", "eyes", "a pair of round brass explorer goggles"),
        ("clover-bowtie", "Clover bow tie", "neck", "a small bow tie made from two clover leaves"),
        ("fiddle", "Tiny fiddle", "back", "a tiny wooden fiddle with a bow, on a strap"),
        ("ladybird-cape", "Ladybird cape", "back", "a short red cape with black ladybird spots"),
        ("leaf-poncho", "Leaf poncho", "body", "a little poncho made from a big green leaf"),
    ], ["acorn-cap", "fiddle"], ["explorer-goggles", "ladybird-cape"]),
}
JOBS = {}
for k, (anat, items, oa, ob) in SUITS.items():
    listing = "; ".join(f"{i + 1}. {d}" for i, (_, _, _, d) in enumerate(items))
    JOBS[f"suit_{k}"] = dict(prompt=f"A sheet of 8 tiny dress-up clothing item stickers made to fit {anat}, laid out 4 across and 2 rows down, read left to right then top to bottom, "
                                    f"each a separate sticker in its own equal cell, each shown on its own with nobody wearing it, facing right: {listing}. Small and delicate. "
                                    f"Exactly these 8 items and nothing else, in this order. No animals or characters anywhere, no people, no grid lines, no boxes or borders between the cells, one plain grey background. "
                                    f"{STYLE} {STICKER} {GREY} Match the layout spacing, paint, line and white paper-border style of image 1 exactly (image 1 shows different items; use it only for style).",
                             refs=["nb/cast/items_wear.png"], aspect="16:9", size="2K")
    by = {i[0]: i for i in items}
    for tag, ids in (("a", oa), ("b", ob)):
        wear = " and ".join(by[i][3] for i in ids)
        JOBS[f"suitdress_{k}_{tag}"] = dict(prompt=f"Exactly the same character as image 1, in exactly the same pose, size, framing and style, now wearing {wear}, fitted naturally to its body. "
                                                   f"Everything else unchanged: same colours, same own accessory unless covered, same line and paint style, same thick white paper sticker border around the whole figure including the new items. {GREY}",
                                            refs=[f"nb/cast/est_{k}.png"], aspect="1:1", size="1K")


def run(name):
    j = JOBS[name]
    im, text, usage = nb.generate(j["prompt"], [REF(r) for r in j["refs"]], j["aspect"], j["size"])
    im.save(os.path.join(OUT, f"{name}.png"))
    return name, im.size


def quad_jobs():
    jobs = {}
    for k, (anat, items, oa, ob) in SUITS.items():
        for half, sl in (("1", items[:4]), ("2", items[4:])):
            listing = "; ".join(f"{i + 1}. {d}" for i, (_, _, _, d) in enumerate(sl))
            jobs[f"suitq_{k}_{half}"] = dict(prompt=f"Four tiny dress-up clothing item stickers made to fit {anat}, laid out in one row, 4 across, evenly spaced, each shown on its own with nobody wearing it, facing right: {listing}. "
                                                  f"Exactly these 4 items, no others. No animals, no people, no grid lines, no boxes. {STYLE} {STICKER} {GREY}",
                                             refs=[], aspect="16:9", size="2K")
    return jobs


JOBS.update(quad_jobs())

if __name__ == "__main__":
    names = [n for a in (sys.argv[1:] or [""]) for n in JOBS if n.startswith(a) or n == a]
    with cf.ThreadPoolExecutor(9) as ex:
        for f in cf.as_completed([ex.submit(run, n) for n in names]):
            try:
                print(*f.result(), flush=True)
            except BaseException as e:
                print("FAIL", e, flush=True)
