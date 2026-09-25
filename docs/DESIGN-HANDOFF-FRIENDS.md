# Hop Tales design handoff: friends as reading levels, big words, treats and wardrobes

This is a plan, not built yet. It builds on the collage storybook (`docs/DESIGN-HANDOFF-V3.md`) and the minimal reading screen (#121).

**The idea in one paragraph:**

- **Friends are reading levels.** There are seven, each a friend with its own world and stories written at that level. A child starts with Bramble the rabbit at level 1, then Hare at level 2, then Puddle, Button, Marmalade, Nipper and Sprig.
- **Steps fill the path.** Every word read is a step along the path to the next friend. **Big words** (harder words from a level or two up, marked on the path) are worth 5 steps.
- **The big story.** When the path is full, the next friend waits at The end with a **big story** from their level. Reading it well unlocks that friend and moves the child up a level.
- **Treats and wardrobes.** Treats picked up along the path fill that friend's basket, and each full basket unlocks the next item in that friend's own wardrobe (8 items each; Hare has 12). Treats never gate levels; reading does.

**Where things are:**

- **Design canvas:** "Hop Tales — friends, collectibles and dress-up". Its source is in `Design/friends/canvas/`. The boards need the canvas runtime (`support.js`), so they won't open in a plain browser.
- **Board renders:** `Design/friends/reference/boards/*.jpg`. Every board and screen named below has a render with that name.
- **Assets:** `Design/friends/`, with sizes and frame data in `Design/friends/assets.json`.

## 0. Product rules for this feature

1. **Reading is the only verb.** Nothing interrupts a sentence.
2. **Nothing is ever lost, and nothing is failed.**
   - A word is never failed: help still counts as a step.
   - A big story is never failed, only "not yet".
   - Levels don't go down on their own; a grown-up can change them in settings.
   - Items and friends are never taken away.
3. **Gentle push forward.** Easier stories are always there to re-read, but they earn fewer steps, and stories at the child's level carry a few big words from the level above.
4. **Levels above 3 are earned.** Onboarding only offers the first three friends. Levels 4 to 7 are reached only by reading.
5. **No shop and no in-app currency for sale.** Everything stays on the device in `ProgressStore`.

## 1. The seven levels

| Level | Friend | Focus | Example words | Sentences | Steps to the next friend |
|---|---|---|---|---|---|
| 1 | Bramble (rabbit) | short vowels, 3-letter words | sat, hop, red, bug | 3–5 words | 300 |
| 2 | Hare | blends and digraphs | frog, ship, hill, chat | 5–7 | 400 |
| 3 | Puddle (frog) | long vowels, magic e | lake, kite, home, tune | 6–8 | 500 |
| 4 | Button (crow) | vowel teams, two beats | rain, boat, garden, paper | 7–9 | 600 |
| 5 | Marmalade (cat) | -ing, -ed, compound words | jumping, sunflower, rested | 8–10 | 700 |
| 6 | Nipper (crab) | longer words, tricky spellings | because, beautiful, island | 9–12 | 800 |
| 7 | Sprig (grasshopper) | big words, longer sentences | adventure, enormous, whispered | 10–14 | — (the top) |

- **These definitions are a first pass on a standard phonics order.** Check them against what his school teaches before writing stories.
- **Keep the numbers in one table in `Content`:** steps per level, sentence lengths and the big-word rate, so they're easy to tune.
- **Starting point: onboarding offers the first three friends only.** This replaces the reading-level step in `DESIGN-HANDOFF-V3.md` §4 (`PhoneOnboard`).
  - **Step 3 of 4:**
    - Title: "Who should your reader start with?"
    - Body: "Pick the friend whose words look about right. You can change this later in settings."
  - **Three cards**, each with the friend's sticker, name, a label and example words in Young Serif:
    - **Bramble** · Just starting · *sat · hop · red*
    - **Hare** · Getting going · *frog · ship · hill*
    - **Puddle** · Reading well · *lake · kite · home*

    The selected card gets a red 3 pt border.
  - **Below the cards:** silhouettes of the other four friends and "4 more friends join as your reader gets stronger".
  - **Picking a friend** starts at their level. The easier friends are already met: picking Puddle means Bramble and Hare come along.
  - **Button, Marmalade, Nipper and Sprig are never offered in onboarding.** They're only reached by filling the path and passing each big story.
  - **Settings:** the grown-up setting can move a child between the levels they've reached. It can't skip them ahead past level 3.

## 2. Steps and big words

**Steps** (kid-facing: the path to the next friend fills):

| Word read | Steps |
|---|---|
| a word in a story **at** your level | 1 |
| a word in an **easier** story | ½ |
| a **big word** | 5 |
| a word read after tapping for help | 1 (big words too: help never costs anything) |

- **Finishing a story** at your level without using help on more than 1 word in 10 adds 20 steps.
- **Big words:**
  - They are tagged in `stories.json`: `"big": true` on the word, usually a word from one or two levels up.
  - Stories at your level use about **1 big word in 20** early in a level, rising to **1 in 8** as the path fills. Author them at both rates, or author the high rate and hide some as plain words.
- **Adaptive nudge:**
  - If the child taps for help on more than 1 word in 5 over the last three stories, big words drop back to the low rate for a while.
  - If they read three stories in a row with no help, the big story arrives at 90 % of the path.
- **Big words on the path** (`PhoneBigWord`):
  - A gold dotted underline in the path's perspective, a small star sticker above the word, and a slightly larger scale.
  - When one is read, the star pops (scale 1.4 → 0, 0.3 s), a small "+5" floats up, and the friend does a higher hop (arc × 1.4).
  - Reduce Motion: no pop; the underline just turns solid gold.

## 3. The path, the big story and meeting a friend

- **Tally** (`PhoneTally`): at The end, the paper sheet shows the story's treats, "3 big words read!" and **The path to Puddle** (the next friend's sticker in grey) with a torn-paper ribbon filling by the steps just earned ("+41 steps · 412 of 500").
- **The big story** (`PhoneBigStory`):
  - When the path is full, the next friend is sitting on the path by The end sign.
  - A card shows a postcard of their world: "Puddle has a bigger story! The path is full. Read Puddle's story to go to the pond together."
  - The story is shown as a chip with its level rosette.
  - Buttons: **Not yet** and **Try the big story**.
  - Each friend's big story is a normal story at the new level, read with the next friend hopping. It can be started again from the journey map at any time.
- **Passing the big story:**
  - The bar is 85 % of words read without help (tunable).
  - Big words in the big story are ordinary words.
  - **Passed** (`PhoneNewFriend`):
    - paper confetti and the new level rosette: "Reading level 3!" and "Puddle is your new friend";
    - both friends side by side, and the friend's signature item ("Puddle gave you a spotty neckerchief");
    - buttons: **Later** and **Go to the pond**.
  - **Not yet:**
    - "Puddle will wait for you at the pond."
    - The path stays full.
    - Stories at the current level carry more big words until the next try.
    - Nothing says "failed".
- **Journey map** (`PhoneJourney`, board `CastJourney`):
  - One winding paper path, bottom to top, with a stop per friend.
  - Friends met show in colour with their level rosette. The next friend is in grey with "big story waiting". Later friends are silhouettes marked "?".
  - A gold dot shows how far along the path to the next friend the child is.
  - It opens from home and the friends screen.

## 4. Treats and baskets (the fun layer)

- **Placement:** every friend has a treat (strawberries, carrots, water lilies, buttons, wool, shells, clover).
  - About one every three words, placed where the friend will land: ground x = next word x − 128 pt on the #121 layout.
  - Rotated −24°, 44 pt tall.
- **Pickup** on frame 6 of the hop:
  - The treat springs up and flies to the **basket chip** top-right (x 270, y 56 on the 390 reference).
  - The chip counts up and fades out after 1.2 s.
  - It's the only reading UI this adds (`PhonePickup`, `PhonePickupAfter`).
- **Golden treat:**
  - A sentence finished without help ends with a golden treat that counts as 3.
  - It has its own slots in the collection book.
  - Only the golden carrot is painted so far.
- **Baskets:**
  - Each friend has their own basket, filled by that friend's treats. Their basket n needs `10 + 5n` treats.
  - Each full basket is a present (`PhoneLevelUp`, now "A full basket!"): paper confetti, a wrapped present to tap, the item pops out, and **Try it on** puts it on the current friend.
  - Baskets never affect reading levels.

## 5. Wardrobes

**Every friend has their own wardrobe: 8 items for each new friend and 12 for Hare.** Items are made for that friend's shape and world, and are never shared, so nothing has to fit seven different bodies.

- **How items unlock:**
  - A friend's **first item comes with meeting them** (it's shown on the new-friend screen, e.g. "Puddle gave you a lily-pad hat").
  - Each full basket of that friend's treats unlocks the next item, in the order below.
- **Stickers:** `Design/friends/wardrobe-suites/<friend>/<id>.png`, with ids, names and slots in `wardrobe-suites/suits.json`.
- **Painted looks:** `_dressed-a.png` and `_dressed-b.png` are two looks per friend showing the target fit. Don't ship them; build outfits from the item stickers.
- **Board:** `CastSuits` shows all six wardrobes.

| Order | Bramble | Puddle | Button | Marmalade | Nipper | Sprig |
|---|---|---|---|---|---|---|
| on meeting | bluebell crown (head) | lily-pad hat (head) | tweed flat cap (head) | gardening hat (head) | sailor cap (head) | acorn cap (head) |
| basket 1 | straw bonnet (head) | rain hat (head) | scarecrow hat (head) | beret (head) | pirate bandana (head) | leaf hat (head) |
| basket 2 | polka-dot headscarf (head) | golden crown (head) | top hat (head) | rose clip (head) | captain's hat (head) | antenna pom-poms (antennae) |
| basket 3 | heart glasses (eyes) | swimming goggles (eyes) | flying goggles (eyes) | cat-eye glasses (eyes) | diving mask (eyes) | explorer goggles (eyes) |
| basket 4 | daisy chain (neck) | check bow tie (neck) | autumn scarf (neck) | lace collar (neck) | eyepatch (eyes) | clover bow tie (neck) |
| basket 5 | strawberry neckerchief (neck) | swim ring (body) | pocket watch (neck) | red bell collar (neck) | life ring (body) | tiny fiddle (back) |
| basket 6 | wicker backpack (back) | reed satchel (back) | patchwork waistcoat (body) | gardening apron (body) | claw mittens (claws) | ladybird cape (back) |
| basket 7 | lilac shawl (body) | raincoat (body) | postbag (back) | knitted cardigan (body) | treasure backpack (back) | leaf poncho (body) |

**Hare's 12** (`wardrobe/`), in unlock order:

1. straw hat (on meeting)
2. bow tie
3. spotty neckerchief
4. flower crown
5. satchel
6. bobble hat
7. round glasses
8. pirate hat
9. wizard hat
10. acorn cap
11. cape
12. paper crown

**Slots and fitting:**

- **Slots:** `head`, `eyes`, `neck`, `body` and `back`, plus `claws` for Nipper and `antennae` for Sprig. One item per slot.
- **Anchors:** each friend defines an anchor for every slot it uses (x, y, rotation, scale). They're defined for the sit pose and every hop frame, in `wardrobe-anchors.json` per friend. An item's pivot is the bottom middle of a hat, the bridge of glasses, the knot of a neck item, or the top of a strap.
- **Following the motion:** an item follows its anchor frame by frame.
- **Masks:** a front mask covers ears and antennae where they should sit over a hat.
- **Neck items:** these replace the friend's own accessory while worn.

**The screen** (`PhoneWardrobe`):

- the current friend's wardrobe only: a stage with the dressed friend, tabs by slot, and a grid of 82 pt paper tiles starting with "Just me";
- the selected tile gets a red ring;
- locked tiles are greyed with a drawn padlock and "Basket 9";
- a change saves at once.

## 6. Friends, collection book, home

- **Friends** (`PhoneFriends`):
  - a 2-column grid in level order;
  - friends met show their level rosette and treat count;
  - the friend being read with has a red ring and a "reading" tag;
  - the next friend is in grey with a "next" tag and "fill the path, then read the big story";
  - later friends are silhouettes with "Reading level N".
  - Tapping a friend met makes them the one who reads next. They read stories from their own level and world.
- **Collection book** (`PhoneBook`): a page per friend with their treats, golden-treat slots, the seven reading-level rosettes (earned or dashed) and stamps for the stories read.
- **Home** (`PhoneHome`):
  - the current friend in their outfit on their world;
  - a chip reading "Level 2 · 412 of 500 to Puddle" with a mini ribbon;
  - the paper sheet with "Keep reading" and three sticker buttons: **Friends** (the journey map opens from here too), **Wardrobe** and **Book**.

## 7. The cast and motion

| Key | Name (placeholder) | Level | Accessory | Treat | World | Hop fps | Lift per frame (src px) |
|---|---|---|---|---|---|---|---|
| `bunny` | Bramble | 1 | lilac ear bow | wild strawberries | Bluebell Wood | 14 | 0 0 −30 −60 −30 0 0 0 |
| `hare` | Hare | 2 | red knitted scarf | carrots | The Meadow | 14 | (existing) |
| `frog` | Puddle | 3 | yellow neckerchief | water lilies | Willow Pond | 12 | 0 0 −40 −90 −60 −10 0 0 |
| `crow` | Button | 4 | blue knitted cap | shiny buttons | Harvest Field | 12 | 0 0 −20 −70 −50 0 0 0 |
| `cat` | Marmalade | 5 | sage ribbon collar | balls of wool | Cottage Garden | 14 | 0 0 −10 −60 −40 0 0 0 |
| `crab` | Nipper | 6 | striped sailor neckerchief | seashells | Rock Pools | 16 | 0 0 −30 −60 −30 0 0 0 |
| `grasshopper` | Sprig | 7 | brown leather satchel | clover leaves | Tall Grass | 14 | 0 0 −60 −130 −110 −50 0 0 |

- **Stickers:** `characters/<key>-sit.png` are the sitting stickers.
- **Hop strips:** `sprites/<key>-hop.png` are 8-frame strips, 440 px tall, with the feet on one baseline and the lift baked in.
  - Play a strip once per word, in place, while the ground pans.
  - Fire the treat pickup on frame 6.
  - Nipper's frame 8 repeats frame 1.
- **Every friend sits at about the hare's on-screen height** (≈124 pt).
- **Idles still needed:** each friend needs a calm idle like the hare's (V3 §6).

**The worlds:** `worlds/<key>-postcard.jpg` sets the look for each world. Each still needs building as a 3-layer endless world with the meadow pipeline (`docs/ASSET-STYLE-GUIDE.md` §7). Where the words go:

- **Willow Pond:** on the lily pads.
- **Harvest Field:** chalked on a dry-stone wall. The words are chalk white, the one light-on-dark world.
- **Cottage Garden:** painted on a brick wall face.
- **Rock Pools:** in wet sand. The tide smooths each word after it's read.
- **Tall Grass:** pressed into an insect-height path.
- **Bluebell Wood:** on a woodland path.

On the walls (Harvest Field, Cottage Garden) the friend walks above the word line, so `WorldLayout` needs a separate `feetY` and `wordY`.

## 8. Data (sketch)

```swift
enum FriendID: String, Codable, CaseIterable { case bunny, hare, frog, crow, cat, crab, grasshopper }  // level order
enum Slot: String, Codable { case head, eyes, neck, body, back, claws, antennae }

struct Journey: Codable {
  var level = 1
  var steps = 0.0
  var bigStoryAttempts = 0
  var met: Set<FriendID> = [.bunny]
  var activeFriend: FriendID = .bunny
}

struct FriendTreats: Codable {
  var total = 0
  var golden = 0
  var basketsFilled = 0
  var inBasket = 0
}

struct Wardrobe: Codable {
  var unlocked: [FriendID: Set<WardrobeItemID>] = [:]   // items belong to one friend
  var outfits: [FriendID: [Slot: WardrobeItemID]] = [:]
}
```

- **Where it lives:** in `ProgressStore`, next to story progress. Existing stars stay as they are and are out of scope here.
- **What changes in the content:**
  - `Story` gains `level: Int` and `isBigStory: Bool`.
  - `Word` gains `big: Bool`.
- **Who does what:**
  - `Reading` emits `wordRead(big:helped:)`, `treatCollected` and `storyFinished(helpRate:)`.
  - A `Journey` feature applies steps, decides when the big story is offered and whether it was passed, and produces the moments (tally, big story, new friend, basket full) for the reading panels.

## 9. Build order (one issue each)

1. **Onboarding:** replace the reading-level step with the three-friend picker.
2. **Levels in the content:** tag every story's level, mark big words, write the big stories (one per level up), and add the level table to `Content`.
3. **Journey:** step counting, big words on the path, the tally path meter, the big-story card, passing and "not yet", the new-friend moment, and the journey map.
4. **Treats and baskets:** treats on the path, the basket chip, golden treats, each friend's basket and the basket-full present.
5. **Wardrobes:** the anchor format, Bramble's and Hare's anchors and wardrobes, the wardrobe screen, and outfits shown while reading and on home. Each later friend's anchors ship with that friend.
6. **Bramble fully:** idle, anchors, Bluebell Wood as 3 layers, and level-1 stories.
7. **Then one friend per release in level order:** Puddle, Button, Marmalade, Nipper, Sprig. Each needs a world, idle, anchors, golden treat and level stories.

## 10. Decisions for Ian

1. **Who picks in onboarding:** the grown-up alone, or the child with the grown-up?
2. **The big-story bar:** is 85 % of words without help right?
3. **Level ups:** is the big story the only way up, or should a level also rise on its own after many stories read well at the current level?
4. **Level definitions:** check the seven levels with a teacher or against his school's phonics order.
5. **Names:** Bramble, Puddle, Button, Marmalade, Nipper and Sprig are placeholders. Does Hare get a name?

## 11. Assets and making more

| Folder | What |
|---|---|
| `characters/` | 6 sitting stickers |
| `sprites/` | 6 hop strips |
| `worlds/` | 6 postcards, 3168×1344 |
| `collectibles/` | treats, golden carrot, four-leaf clover, basket, rosette, star (the big-word marker) |
| `wardrobe/` | Hare's 12 items |
| `wardrobe-suites/` | 8 items per new friend, plus two painted looks each, and `suits.json` |
| `reference/dressed/` | target looks |
| `reference/boards/` | renders |
| `raw/` | the original generated sheets |
| `tools/` | the scripts that made all of it |

**About the tools:**

- **Scripts:** `gen_cast.py` and `gen_suits.py` (prompts), `cut_cast.py`, `cut_suits.py`, `export_friends.py`, `cast_boards.py` and `cast_journey.py` (the canvas boards).
- **Item sheets:** the best results came from **four items per image with no reference image**. With a reference attached, the model tends to draw the animal wearing each item or copy the reference items.
- **Paths:** they're copies from the design workspace, so update the paths before running them here.
- **Generating new art:**
  - Use `Design/collage/tools/nb.py`, with the key in the git-ignored `.gemini-key`.
  - Follow `docs/ASSET-STYLE-GUIDE.md`.
- **Git:** consider git-ignoring `Design/friends/raw/`.
