# Hop Tales asset style guide (collage storybook)

Use this guide to make new art that matches the existing assets. It covers the look, the prompt recipe, the generation pipeline, and how to cut and ship each kind of asset. The design canvas "Hop Tales — collage storybook" shows everything described here.

## 1. The look in one paragraph

This is a cozy, quiet picture-book world made of **torn watercolour paper collage**. Soft washes of watercolour, fine **sepia ink** linework and a little pencil texture sit on paper with visible grain and soft white deckled (torn) edges. The mood is a gentle, naturalistic English countryside in the manner of early 20th-century nature picture books: warm, calm and never loud. Everything looks as if it were painted, cut out and laid on a table.

**Originality rule.** Every character is our own design. Don't name or imitate existing book characters, costumes or illustrators in prompts; describe the qualities you want instead: watercolour, sepia ink, deckled paper, naturalistic anatomy.

## 2. Rules that keep it consistent

| Rule | Spec |
|---|---|
| Line | Fine sepia or brown ink. Never black and never thick. |
| Paint | Transparent watercolour washes, soft edges, some granulation. No hard cel shading and no gradients. |
| Paper | Visible grain. Torn deckled edges on landscape layers, UI cards and labels. |
| Light | Soft daylight from the upper left, with gentle cool shadows. |
| Characters | Stickers: a thick even **white paper border** plus a very soft shadow. Only characters get the border. |
| Scenery props | **No border.** They blend into the painted world with only a faint contact shadow. |
| Anatomy | Natural animal anatomy and proportions. Friendly but not cartoony: no big heads or giant eyes. |
| Palette | Warm and slightly muted (see §3). Saturated colour only for small accents: the red scarf, poppies, buttercups. |
| Composition | Calm, uncluttered, lots of air. Nothing important cut off at the edges. |

## 3. Tokens

| Token | Hex | Use |
|---|---|---|
| Sepia ink | `#3B2A20` | text, icons, ink |
| Paper | `#FBF4E4` | cards, labels, sheets |
| Paper shade | `#EFE3C8` | paper lip, dividers |
| Page | `#F4EBD8` | app and web background |
| Sage | `#A6BA92` | app icon ground, sage bands |
| Sage deep | `#7E9A6A` | mic button, success |
| Scarf red | `#B8423A` | primary buttons, accent |
| Wash gold | `#F7D774` | "read" word highlight, stars |
| Sky | `#CFE4EE` | day sky top |
| Muted | `#9C8B78` | secondary text |
| Night | `#1E2A4E` | night sky, launch image base |

**Type**

- **Fraunces 700** for titles, labels and buttons.
- **Young Serif** for the words a child reads.
- **Fredoka 500/600** for small UI copy.

All three are Google Fonts under the OFL. Young Serif keeps the single-storey a and g that early readers learn.

## 4. The hare (main character)

- A slender young brown hare with warm tawny-brown fur, a cream chest and belly, and long ears with pale pink insides.
- He has a soft, kind dark eye and a small hand-knitted **red scarf**.
- He's always drawn as a white-bordered sticker.
- Reference images, always attached when making new poses:
  - `Design/collage/raw/hare-a.png` (standing)
  - `Design/collage/raw/hare-sit.png` (sitting)
  - `Design/collage/brand/hare-front-sit.png` (facing us)

### Other hopping characters

Frogs, robins, crows, cats, grasshoppers and so on follow the same recipe:

1. Make one establishing image.
2. Make a sitting pose from it.
3. Make an idle sheet and a hop sheet, each with the establishing image attached as the reference.

Give each character one small signature accent in the same palette, the way the hare has his scarf (a yellow neckerchief, a blue cap, and so on). Keep them the same size family as the hare.

## 5. Prompt recipe

Build every prompt from these blocks, in this order:

1. **Subject**
   - Characters: what it is, its pose, and "side view facing right" unless it faces us.
   - Scenery: what the layer contains.
2. **Style block** (copy verbatim):
   > Hand-painted in delicate watercolour washes with fine sepia ink pen lines and a little soft pencil texture, in the gentle, naturalistic manner of classic Edwardian English children's nature picture books — cozy, warm and quiet.
3. **Paper block**
   - Characters: "surrounded by one even, thick white paper border, as if carefully cut out of a printed book with scissors, with a very subtle soft drop shadow."
   - Scenery: "a hand-crafted paper collage: torn watercolour-painted paper with soft white deckled edges and visible paper grain."
4. **Consistency block** (poses): "Exactly the same character as image 1: same fur colours, same markings, same scarf, same line and paint style, same border."
5. **Background block** (anything that gets cut out): "Plain flat medium-grey background (#8a8a8a). No text, no ground, no other objects, nothing touching the edges."
6. **Layer block** (parallax layers): "One layer of a side-scrolling parallax background: a long horizontal panorama with no focal point, nothing important at the left or right edges. Everything above the paper layer is flat plain medium grey (#8a8a8a). No animals, people, buildings or text."

**Sheets.** For animation frames, ask for "N frames laid out C across and R rows down, each a separate sticker in its own equal cell, same size and scale in every frame". List what changes in each frame, and ask for small in-between changes.

## 6. Generating (Nano Banana via the Gemini API)

- **Model:**
  - `gemini-3.1-flash-image` (Nano Banana 2) for everything. It's cheap and good.
  - `gemini-3-pro-image` only for hero art that needs extra fidelity.
- **Client:** `Design/collage/tools/nb.py`, via `generate(prompt, [reference PIL images], aspect="16:9", size="1K"|"2K")`.
- **Key:** set `GEMINI_API_KEY`, or put the key in `.gemini-key` at the repo root. `.gemini-key` is git-ignored; never commit a key.
- **Spend:** about 2 cents an image at 1K. Explore at 1K and go to 2K only for keepers. Start with one or two images per idea before generating a full set.
- **Sizes and aspect ratios:**
  - Characters and props: 1:1 or 4:3, 1K.
  - Sheets: 16:9, 2K.
  - Landscape layers: 21:9, 2K.

## 7. Pipeline scripts

All scripts are in `Design/collage/tools/`.

| Step | Script | What it does |
|---|---|---|
| Cut stickers | `sprites_build.py` → `cut()` | Keys out the flat grey, keeps the white border, soft 1 px alpha edge, one image per sticker |
| Remove border (scenery) | `unborder_edge` recipe (see the handoff) | Strips the white paper rim and shadow connected to the outside edge only |
| Align animation frames | `sprites_build.py` → `best_shift()` / `idle_frames.py` | Matches each frame's scale to the rest pose and aligns on overlap; feet stay put |
| Make a layer loop | `chain.py` | Chains 2–3 generated sections with min-cost seam cuts into one long seamless loop |
| Heal a seam | Nano Banana edit | Shift the seam to the centre and ask to "repaint only the middle third". Feather it back in. Check the result. |
| Preview boards | `collage_world.py`, `sprite_board.py`, `intro.py`, `collage_site.py` | Rebuild the canvas boards |

## 8. Asset specs

| Asset | Size | Format | Notes |
|---|---|---|---|
| Parallax layer | loop ≥ 3,500 px wide @2x, ~830 px tall | WebP q86 (PNG master) | Seamless at x = 0 / w. Transparent above the paper edge. Far / mid / near loops should have different lengths so they drift out of step. |
| Sky piece (cloud, sun, moon, star) | ~400–850 px | PNG with alpha | No border |
| Scenery prop | ~300–350 px | PNG with alpha | No border, faint contact shadow in the engine |
| Character frame | cell size fixed per sheet (hare: idle 260×373, hop 363×346 @1x of sheet) | PNG/WebP strip | Bordered sticker, feet on a common baseline |
| App icon | 1024×1024 | PNG, no alpha, square corners | iOS applies the mask |
| Launch image | iPhone 1320×2868, iPad 2064×2752 / 2752×2064 | PNG | Frame 0 of the sunrise |

## 9. Checklist before shipping new art

- It sits well next to `hare-a.png` and `meadow.jpg` at the same scale.
- Characters have the white border; scenery doesn't.
- There's no text and no signature in the image, and no stray grey around the edges after cutting.
- Loops tile: view two copies side by side and look for a seam.
- The design is original, with no recognisable existing characters or branding.
