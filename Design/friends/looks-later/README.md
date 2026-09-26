# Looks for later

Dressed sitting stickers for the wardrobe items that don't ship yet: everything outside the five per friend in `WardrobeLibrary.wearable` (`HopTalesPackage/Sources/Content/Wardrobe.swift`). They're kept here as a head start, outside the app bundle.

## What these are
- **First-round paintings** from `Design/friends/tools/gen_looks.py` (stage 1 of #147): the friend painted wearing the item, keyed and aligned to the friend's base sticker.
- **Older than the shipped rules.** They were made before the friend was always kept at full size and before stickers were cut from the idle's rest frame. Some may draw the friend slightly smaller, and none has an idle or hop strip. Treat them as reference, not finished art.

## To ship one
1. **Choose it:** add the item id to that friend's list in `WardrobeLibrary.wearable`, replacing an item if it stays at five.
2. **Paint it in full** with `gen_looks.py`, which now does:
   - the redraw at full scale, never shrinking the friend
   - the full crown for head items, with each frame's ears or antennae laid on top
   - a per-frame bare repaint where the item replaces the friend's own accessory
   - the idle, with each base frame kept whole and only the item laid over it
   - the 8 repainted hop frames
   - the sticker cut from the idle's first frame
   - the checks: item present in every frame, item on its anchor, full scale, head board viewed at full size

   Budget about 10 Gemini calls for a neck, body or back item and 12–20 for a head or eye item, plus about 20 once per friend if it replaces their own accessory and they don't already have a bare strip.
3. **List it:** run `python3 scripts/export-looks.py` so `looks.json` lists it. The wardrobe only offers complete looks.
4. **Snapshots:** re-record any that show that friend's wardrobe.

## Files
`look-<friend>-<item>.webp`, one per item, matching `wardrobe.json`:

| Friend | Items |
|---|---|
| Hare | acorn, bobble, cape, neckerchief, paper-crown, pirate, wizard |
| Bramble (bunny) | berry-kerchief, headscarf, shawl |
| Puddle (frog) | frog-crown, souwester, swim-ring |
| Button (crow) | pocket-watch, scarecrow-hat, waistcoat |
| Marmalade (cat) | apron, lace-collar, rose-clip |
| Nipper (crab) | bandana, eyepatch |
| Sprig (grasshopper) | fiddle, leaf-hat, leaf-poncho |

Nipper's life ring is fully painted, with sticker, idle and hop strip. It's in the app's resources, but it isn't in his shipped five because it mostly hides behind his shell.
