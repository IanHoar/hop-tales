# Hop Tales — design handoff v2: Ink & Ember

Engineering handoff for the v2 visual redesign. `docs/HANDOFF.md` is still the product spec (reading loop, speech rules, parallax maths, milestones). This file replaces only the **visual layer**: tokens, fonts, chrome, world art and characters. `docs/ART-DIRECTION.md` has the style reasoning. This file is what to build.

## Sources

| What | Where |
|---|---|
| Design canvas | Hop Tales design artifact → page **"v2 · Ink & Ember"**. Artboards: `InkHome`, `InkMeadow`, `InkHeard`, `InkCastle`, `InkDragon`, `InkTV`, `InkLibrary`, `InkCast`, `InkKit`. Page "v1 · soft storybook" is the old direction, kept for reference |
| Rendered previews | `Design/ink/preview/*.png` |
| Source art | `Design/ink/sprites/*.svg` (characters, props), `Design/ink/world/*.svg` (12 layers) |
| Generator | `Design/ink/generator/` → `python3 build.py` rebuilds every SVG. Palettes: `props.py → TOD`; character colours at the top of `fox.py`, `knight.py`, `dragon.py` |
| Fonts | `Design/ink/fonts/*.ttf` (all SIL OFL) |

All coordinates below are at the **390 × 844 pt reference phone** unless stated otherwise. Map them onto `ReadingGeometry` / `Metrics` the same way the v1 values were mapped; do not hard-code them.

---

## 0. Ground rules (unchanged, restated because the redesign touches them)

- The word card, ball, mic pill and progress rail never move between stages. Only the world changes.
- Reading text is SwiftUI (Andika). Nothing on the reading surface is rendered in SpriteKit.
- No failure states shown to the child. The redesign adds no red, no X, no shake.
- Swift source carries no comments. Views are `…Screen`; a feature and its view share a file. Snapshot references are recorded on iPhone 18 Pro / iOS 27.

---

## 1. Fonts — do this first

**Bug in the current build:** no font is bundled or registered. `Typography` asks for "Andika" and "Fredoka", iOS silently falls back to SF Pro, and every snapshot shows it (two-storey *a* in "The"). This one change is the biggest visual win available.

| File | Family | PostScript name | Use |
|---|---|---|---|
| `Andika-Regular.ttf` | Andika | `Andika` | — |
| `Andika-Bold.ttf` | Andika | `Andika-Bold` | every word the child reads |
| `Fredoka-Regular.ttf` | Fredoka | `Fredoka-Regular` | — |
| `Fredoka-Medium.ttf` | Fredoka | `Fredoka-Medium` | meta text |
| `Fredoka-SemiBold.ttf` | Fredoka | `Fredoka-SemiBold` | UI labels, mic pill |
| `Fredoka-Bold.ttf` | Fredoka | `Fredoka-Bold` | — |
| `LilitaOne-Regular.ttf` | Lilita One | `LilitaOne` | **new** display face: titles, ribbons, numbers, button labels |

Implementation:

1. Copy the TTFs to `HopTalesPackage/Sources/DesignSystem/Resources/Fonts/`.
2. `Package.swift`: give the `DesignSystem` target `resources: [.process("Resources")]`.
3. Add `DesignSystem/FontRegistry.swift`:

   ```swift
   import CoreText
   import Foundation

   public enum FontRegistry {
     public static func register() {
       guard let urls = Bundle.module.urls(forResourcesWithExtension: "ttf", subdirectory: nil) else { return }
       CTFontManagerRegisterFontURLs(urls as CFArray, .process, true, nil)
     }
   }
   ```

4. Call `FontRegistry.register()` from `HopTalesApp.init()`, and from `SnapshotSupport` before any snapshot renders.
5. `Typography`: add `display(_ size:)` → `.custom("LilitaOne", fixedSize: size)`; make `ui` resolve weights by PostScript name (`Fredoka-SemiBold` etc.) rather than `.weight()` on the family, because the static instances register as separate faces.
6. Every snapshot changes, so re-record them all in this PR. Add one test that asserts `UIFont(name: "Andika-Bold", size: 20) != nil` after registration, so a missing font fails loudly instead of falling back.

**Acceptance:** the single-storey *a* and *g* show up in the word card on device and in snapshots. `Typography.width(of:)` measurements change, so re-check `WordRowTests` and the long-word shrink snapshot.

---

## 2. Tokens

Replace `Palette` values in place where a token already exists, and add the new ones. Keep the old names working until every call site is moved.

| Token | Hex | Replaces | Use |
|---|---|---|---|
| `ink` | `#1D1A2C` | `ink #2E2A3B` | every outline, all reading text, UI drop shadows |
| `parchment` | `#FFF6E2` | `cream` | card, chips, buttons |
| `parchmentLip` | `#EBD5A6` | `creamDeep` (partly) | bevel underside |
| `page` | `#F7E9C8` | — | home background below the header |
| `red` / `redShade` / `redLight` | `#DB2A2E` / `#A3141D` / `#FF6A55` | — | ribbon, wordmark |
| `gold` / `goldShade` / `goldLight` | `#F6BB3E` / `#C7861A` / `#FFE39A` | `amber`, `amberDeep`, `pillBg` | coins, progress, primary button, word pills |
| `teal` / `tealShade` / `tealLight` | `#1E8C8C` / `#136066` / `#48B8B0` | `listenBars` | mic, TV button |
| `ball` / `ballShade` / `ballLight` | `#FF9A3C` / `#D8601A` / `#FFE2B8` | `ball`, `ballLo`, `ballHi` | hop ball |
| `pillText` | `#7A4A0C` | `pillText #8A5A12` | text on read-word pills |
| `muted` | `#6E6780` | same | next word, meta |
| `faint` | `#8A8499` | `faint #9A94A6` | word after next. **Darkened** — the old value is 2.7:1 on parchment and fails 3:1 at 21 pt bold |
| `heardBg` / `heardLip` / `heardIcon` | `#E4F6D2` / `#BFDDA4` / `#5FB548` | `heardBg` | mic "heard" state |
| `newBadge` / `newBadgeShade` | `#8A5CD6` / `#6440AE` | `newBadgeBg` | NEW badge (parchment text) |
| `done` / `doneShade` | `#8BD06A` / `#5FA848` | `heardBg` on home | finished-story badge |
| `track` / `trackDusk` | `#8A5A36` / `#3A2E4E` | `trackBg` | progress trail track |
| `stone` | `#D9D2C4` | — | future progress nodes |
| `labelOnWorld` | `#FFF3D6` + 2 pt ink halo | `railLabel` | any text drawn straight on the world |

Contrast, checked: ink on parchment 15.8:1 · muted on parchment 5.0:1 · faint on parchment 3.3:1 · pill text on gold-light 5.9:1 · ink on gold 9.8:1 · parchment on teal 3.8:1 (only used at ≥ 19 pt Lilita, i.e. large text). `ContrastTests` should cover every pair in this list.

Dark mode: v2 is a single-appearance game UI. The world supplies its own day/dusk mood, so the chrome stays parchment in both schemes. Drop the `.dark` snapshot variants, or keep them asserting identical output.

---

## 3. The bevel: one modifier behind every surface

Every surface (card, chip, button, pill, badge) is the same construction. Build it once in `DesignSystem`:

| Layer (bottom → top) | Spec |
|---|---|
| Drop | solid `ink`, same shape, offset `y = drop` |
| Fill | the surface colour |
| Lip | the shade colour, a band `drop + 2` tall along the bottom edge, clipped to the shape |
| Highlight | white at 85 %, 3 pt band along the top edge, inset by `radius × 0.6` horizontally |
| Border | `ink` stroke, inside the shape |

| Use | Border | Drop | Radius |
|---|---|---|---|
| Word card | 4 | 6 (lip 9) | 32 phone · 44 iPad · 56 TV |
| Buttons, chips, mic pill | 3 | 4–5 | capsule |
| Word pill (read) | 2.5 | 3 | 12 |
| Word flash (just heard) | 3 | 4, plus a 6 pt `goldLight @ 60 %` ring | 14 |
| Story row / keep-going card | 3 / 4 | 4 / 6 | 24 / 28 |

The card also gets a soft ambient shadow under the hard drop: `0 22 34 rgba(12,10,30,.32)`.

**Pressed state** (`ButtonStyle`): drop goes to 1 and the content offsets down by `drop − 1`, over 80 ms. Release springs back (response 0.25, damping 0.6). No scale and no colour change.

API sketch:

```swift
public struct Bevel: ViewModifier { fill: Color, lip: Color, shape: some InsettableShape, border: CGFloat, drop: CGFloat }
public struct InkButtonStyle: ButtonStyle { enum Kind { case primary, secondary, tertiary } }
```

`primary` = gold / ink label · `secondary` = teal / parchment label · `tertiary` = parchment / ink label. All three are 58 pt tall, Lilita One 19, tracking +0.03 em.

---

## 4. Reading screen

Artboards: `InkMeadow` (idle), `InkHeard` (word recognised), `InkCastle`, `InkDragon`.

### Layout (390 × 844 reference)

| Element | Frame | Notes |
|---|---|---|
| World | full bleed | `WorldView`, behind everything |
| Top bar | y 50, side padding 16, space-between | back button · ribbon · star chip |
| Back button | 52 × 52 capsule bevel, parchment | chevron 22 pt, ink, stroke 3.4 |
| Story ribbon | 206 × 52 | §4.1 |
| Star chip | 52 tall, padding 6 / 16 | coin 38 pt + Lilita One 22 number |
| Word card | x 14, y 468, 362 × 190 | top edge sits ~20 pt below the ground crest, so the fox's feet stay visible |
| Ball lane | card-local y 0–100 | ball 42 pt, resting centre at card-local (181, 59) |
| Word row | card-local y 102, height 80 | current word's centre pinned to card centre x (unchanged rule) |
| Progress trail | x 28, y 684, 334 wide | label, then a 58 pt trail |
| Mic pill | centred, y 766, 56 tall | |

### 4.1 Story ribbon

A notched banner drawn as a `Shape`: centre panel 16…w−16 × 4…h−2, `red`, 3 pt ink. Two tails 18 pt wide, `redShade`, with a V notch 9 pt deep, drawn *behind* the panel and offset down 6 pt. Plus a 3 pt `redLight` highlight line 4 pt under the top edge. Text: Lilita One 17, `#FFF3D6`, 4 pt ink stroke behind the fill (in SwiftUI, stack an ink copy with `.shadow` offsets, or render the text as a `Text` path). The title comes from the story; the ribbon width hugs the text (min 160, max 230).

### 4.2 Word states (replaces the v1 table)

| State | Look |
|---|---|
| upcoming | Andika Bold, side size, `muted`; the word after that `faint` |
| current | Andika Bold 64 (52 for 6 letters, 46 for 7+ — existing shrink rule), `ink`, tracking −0.01 em |
| recognised (≈450 ms) | 36 pt on a `gold` pill, 3 pt ink border, 4 pt ink drop, 6 pt `goldLight @ 60 %` ring. Three ink-outlined gold stars pop off it (scale 0 → 1 → 0, 0.5 s, staggered 0 / 80 / 160 ms) |
| completed | side size, `pillText` on `goldLight`, 2.5 pt ink border, 3 pt ink drop, radius 12, padding 2 / 9 / 3 |

Side sizes: 21 phone · 32 iPad · 48 TV (was 22/32/48). Row gap: 10 · 22 · 32.

### 4.3 Hop ball

Circle r 17 on a 40-unit box, `ball` fill, bottom crescent `ballShade` (hard edge, no gradient), 3 pt ink ring, specular ellipse 10 × 7 rotated −30° at (14, 12) plus a dot r 1.8 at (25, 10), both `ballLight`. Ground shadow: ink @ 18 %, 32 × 8, scaling with hop height as today. Squash on landing: `scaleY 0.72 / scaleX 1.39`, 60 ms. Stretch at take-off: `scaleY 1.25`. `BallPhysics` timing is unchanged.

Dotted arc from the previous word to the ball: ink @ 22 %, stroke 3.4, dash `0.5 10`, round caps.

### 4.4 Mic pill

56 tall capsule bevel, parchment. Inside: a 36 pt teal disc with a 3 pt ink ring and a white mic glyph; five level bars (5 wide, radius 3, `teal`, 1.5 pt ink border, animated 6–19 pt as today); label Fredoka SemiBold 17 "Say the word".
Heard state: fill `heardBg`, lip `heardLip`, disc `heardIcon` with a white check, no bars, label `Heard it — "sat"!`. Hold 1.2 s (unchanged).

### 4.5 Progress trail

| Part | Spec |
|---|---|
| Label | Lilita One 14, tracking +0.12 em, `labelOnWorld` with a 2 pt ink halo (8-direction text shadow). Copy is unchanged (`SENTENCE 2 OF 6`, `NEW WORD · KNIGHT`, `LAST SENTENCE!`) |
| Track | 12 tall capsule, `track` (`trackDusk` on the dragon stage), 3 pt ink |
| Fill | `gold`, inset 2, up to the current node |
| Done node | r 10 `gold`, 3 pt ink, `goldLight` star r 5.5 |
| Current node | r 17 `goldLight @ 50 %` halo, r 13 parchment, 3.4 pt ink, r 6 `ball` core with 2 pt ink |
| Future node | r 8 `stone`, 3 pt ink |
| Milestones | a 22 × 20 castle glyph above node 4 and a dragon-head glyph above node 6, both ink-outlined (`InkLibrary` artboard) |

### 4.6 Heard moment (`InkHeard`)

Everything from v1's recognised animation still applies. Added:
- The fox swaps to the happy head and jumps (existing `celebrate()`), with its ground shadow shrinking.
- A `+1` gold chip (bevel, coin 26 + Lilita One 18) appears under the star chip, rises 24 pt and fades out over 0.9 s.

### 4.7 Stage differences

Only the world and the characters change: the meadow has the fox, the castle road adds Sir Pennant at near-layer x 1262, and dragon's hill adds Ember at x 2212. The chrome is identical on every stage except the dusk trail track colour.

---

## 5. Home screen (`InkHome`)

| Element | Spec |
|---|---|
| Header | the world (day, p = 0) rendered at 0.62 scale, 280 tall, cropped 60 pt from the top. Reuse `WorldView` with a fixed progress, or a pre-rendered image |
| Page | below y 236: `page` colour with a 4 pt ink top edge |
| Wordmark | "Hop Tales", Lilita One 44, `red` fill, 9 pt ink stroke behind, 1.6 pt `redLight` inner highlight offset (−1, −2). x 10, y 44. Replace with the poster lettering as an image asset if preferred |
| Star chip | 46 tall, top-right, y 48 |
| Greeting | "Hi, {name}!" Lilita One 28, parchment, 3 pt ink halo, x 18, y 108 |
| Keep-going card | x 16, y 190, 358 wide. Scene thumbnail on top (the story's stage world, 124 tall, 4 pt ink divider) with that story's character in frame. Below: eyebrow `KEEP GOING` (Fredoka SemiBold 12, +0.14 em, `muted`), title Lilita One 24, a mini progress trail (190 × 26), and a 62 pt gold play button |
| Fox | the `fox-sit` pose, 0.42 scale, standing on the card's top edge at x 314 |
| Section label | `ALL STORIES`, Lilita One 15, +0.12 em, ink, y 436 |
| Story rows | 358 wide, gap 10. Bevel `#FFFBF1` / lip, radius 24. 62 pt framed scene thumbnail (radius 14, 3 pt ink), title Lilita One 21, meta Fredoka Medium 14 `muted`, trailing badge. The in-progress story gets a 4 pt `gold` outline, offset 2 |
| Badges | finished: 38 pt `done` bevel circle with an ink check · in progress: a 34 pt coin · new: `NEW` Lilita One 14 parchment on a `newBadge` capsule bevel |
| Bottom bar | y 766: "Play on the TV" `InkButtonStyle.secondary` (flex) + 58 pt parchment settings button |

Story thumbnails are crops of the real world at that story's stage and progress, not flat gradients (v1 used gradients). Render them once at launch from `WorldArt` and cache them.

---

## 6. Apple TV (`InkTV`) and iPad

**TV, 1920 × 1080.** World scale `1080/844 = 1.2796`, near offset `p = 840` so the castle, knight, keep and dragon are all in frame at dusk. 96 pt overscan margin. Top-left: ribbon at 1.7×. Top-right: mic pill + star chip at 1.5×. Word card x 240, y 600, 1440 × 310, border 6, drop 10, radius 56. Words 48 / 140 (current), gap 30, row at card-local y 128. Ball 76 pt. Progress trail at 1.8×, centred, 20 pt below the card (2.5× at y 930 runs off the bottom of the screen).

**iPad.** Not redrawn for v2. Use the v1 iPad layout (`iPad.dc.html` on the v1 page) with the v2 components: 900 pt card, radius 44, words 32 / 100, mic pill in the top bar. The top bar is the phone chrome at 1.08×: back button and ribbon on the left, mic pill and star total on the right. Portrait uses the same layout scaled to the width.

**Screens not redrawn** (story finished, onboarding, listening unavailable, parent gate): apply the library as-is. Parchment bevel surfaces, Lilita One titles, `InkButtonStyle`, no new colours. Onboarding's welcome carousel should use the same world header as home.

---

## 7. World

Parallax maths, metrics, stage thresholds and scroll timing are all unchanged (`HANDOFF.md §6`, `WorldScene`, `LayerOffsets`, `WorldStage`).

### 7.1 Layers

Twelve files replace six. Each layer ships in three palettes:

| Layer | Files | Speed | Outline | Contents |
|---|---|---|---|---|
| Sky | `sky-{day,gold,dusk}.svg` | 0× | clouds self-tinted | gradient, sun or moon, clouds, stars |
| Far | `far-{…}.svg` | 0.3× | none | two mountain ranges with snow caps, haze band, far hills |
| Mid | `mid-{…}.svg` | 0.6× | 3 pt tinted ink | hills, windmill x 300, castle x 820, old keep x 1460, tree clusters |
| Near | `near-{…}.svg` | 1× | 4 pt ink | ground with a scalloped grass lip, path, fence, oaks, pines, flowers, rocks, signpost x 1300, torches x 2000 / 2250 |

The ground line is unchanged: `y = 448 − 10·sin(x/190) − 6·sin(x/63 + 1)`. Characters are **not** in the near layer any more.

### 7.2 Time of day = texture crossfade

- `WorldArt` gains a palette dimension: `WorldArt.layer(.near, .dusk)` etc. `sky(_:)` stays.
- On `setStage`, each of the four layer nodes crossfades to the new palette's texture over `WorldScene.crossfade` (0.6 s), exactly as the sky already does. Add an incoming sprite at alpha 0, fade it in, swap the texture, remove it.
- **No runtime colour filters on the world.** v1's hue-rotate is what turned the dragon green.
- Characters get a light dusk grade only: `SKSpriteNode.color = #CCC7E0`, `colorBlendFactor 0.2`, or a shared `SKShader` that multiplies by 0.8 brightness and 0.92 saturation.

### 7.3 Dusk lights (additive sprites, fade in with the dusk crossfade)

| Light | Layer | Position | Spec |
|---|---|---|---|
| Torch flames ×2 | near | torch top (x, ground − 64) | teardrop flame `#FF8A2A` / `#E0501A` / `#FFE08A` with 2.6 pt ink, plus a 34 pt radial glow `#FFC96B` 85 % → 0. Flicker: scale 0.94–1.06 at ~9 Hz, randomised phase |
| Castle and keep windows | mid | baked lit in `mid-dusk` | none needed, but a slow 0.9–1.0 alpha pulse on an overlay reads nicely on TV |
| Warm pool | screen | around the fox and torches | radial `rgba(255,170,80,.28)` → 0, 140 pt, `.add` blend |
| Fireflies | near | random, ground − 150…0 | 1.5 pt `#FFF6C0` core with a 6 pt glow; drift ±20 pt; blink 2–4 s |

### 7.4 Asset pipeline

`scripts/render-assets.sh` should read `Design/ink/world/*.svg` and write PDFs (layers) plus PNGs (skies) to `World/Resources`, as today, now with 12 inputs. At 2340 wide × 3 palettes × 4 layers, rasterise on demand and cache only the current and incoming palette. Don't hold all 12 textures in memory; on older iPhones, tile to 780 pt as `HANDOFF.md §7` suggests.

---

## 8. Characters

Every character is a **rigged cut-out**: separate part textures, each with a pivot, animated by transforms. `FoxNode` already works this way. Only its drawing source changes, from CoreGraphics (`FoxArt.swift`) to atlas textures.

Coordinate system for every sprite below: local origin at the feet, ground at y = 0, y up is negative (SVG space; flip for SpriteKit). 1 unit = 1 pt at scale 1.

### 8.1 Pip the fox

In-scene scale **0.62** (the source is 240 × 170 units; ≈ 149 × 105 pt on screen). Screen x 118, feet on the ground line.

| Part | z | Pivot (local) | Notes |
|---|---|---|---|
| tail | 0 | (−24, −54) | rotates ±4° in the trot, −10° in the jump |
| far legs ×2 | 1 | hips (−20, −28), (18, −28) | darker fur `#CF5A20` |
| body | 2 | (0, −40) | carries the bob |
| near legs ×2 | 3 | hips (−12, −26), (26, −26) | |
| scarf tail | 4 | (10, −60) | flap 0–8 units |
| head | 5 | (18, −66) | two variants: idle eyes, happy (closed-arc eyes and open smile) |
| scarf wrap | 6 | (26, −58) | gold clasp |

The pivots are the red dots on the `InkCast` rig tile. `sheets.py → rig_svg()` holds the exact offsets.

Poses, as leg rotations (far-rear, far-front, near-rear, near-front) + tail° + bob + scarf flap:

| Pose | Legs ° | Tail ° | Bob | Flap |
|---|---|---|---|---|
| trot 1 | 18, −14, −18, 14 | 4 | −1 | 2 |
| trot 2 | 6, −4, −6, 4 | −2 | −3 | 4 |
| trot 3 | −14, 18, 14, −18 | −4 | −1 | 6 |
| trot 4 | −4, 6, 4, −6 | 2 | −3 | 3 |
| jump | −24, 20, −28, 24 | −10 | −22 | 8 · happy head |
| cheer | 0, 0, 0, 0 | 8 | 0 | 0 · happy head |

`FoxNode`'s existing gait code (`strideAngle`, `trotBounce`, `jumpHeight`, `breathPeriod`, `swishPeriod`) already produces this motion procedurally. Keep it, retune `strideAngle` to ~0.31 rad (18°), and swap the textures. `FoxNode.canvas` grows to (−120, −160, 240, 170) × 0.62. Idle: a 1.8 s breath on the body (scaleY 1.0–1.02) and a 1.4 s tail swish (±3°), as today.

### 8.2 Sir Pennant (castle stage)

Scale **0.6**, near-layer x **1262**, faces the reader (front view). Parts: body+legs, shield arm, banner pole and flag, helmet+plume. Idle: the flag waves (skewX ±4°, 1.2 s); plume bobs 1 pt. When the fox passes (near x within 120 pt), he waves the banner arm up 20° and back, once.

### 8.3 Ember the dragon (dragon stage)

Scale **0.72**, near-layer x **2212** (2180 on TV), sitting on the hoard, facing left toward the fox. Parts: far wing, tail, body+haunch, hoard, neck+head, front arm, near wing. Pivots: near wing (8, −122); far wing at the same point under a (−34, −18) offset and −12° rotation; head at the neck base (−30, −110).
- Idle: near wing flaps −16° ↔ +8° over 2.4 s, far wing follows at 60 % and 80 ms later; the body breathes (scaleY 1.0–1.015); the tail spade sways ±5°.
- Last word of the story: the head swaps to the roar variant, and a fire sprite (the three nested flame shapes from `InkDragon`, pointing left from the mouth at local (−186, −64)) scales 0 → 1 over 0.2 s, flickers for 1.2 s, then fades out, with 5 embers drifting up-left.
- Coins in the hoard twinkle: two small parchment stars scale 0 → 1 → 0 at random, every 1.5–3 s.

### 8.4 Atlases

One atlas per character (`fox.atlas`, `knight.atlas`, `dragon.atlas`), with parts exported as PNG @2x and @3x from the SVGs. Naming: `fox-tail`, `fox-leg-far-rear`, …, `fox-head-idle`, `fox-head-happy`. Each part's anchor point comes from its pivot divided by its trimmed bounds. Write it into a sidecar `pivots.json` per atlas, so art can change without code changes.

---

## 9. Final art: vector now, raster later

The SVG characters are **placeholders of the right shape**: correct palette, proportions, parts, pivots and poses. They still look built from primitives. The plan is to replace them with painted raster sprites made to this spec (the icon and poster style), without touching code:

- Same atlas names, same part split, same pivots (`pivots.json`), same local coordinate system.
- Deliverables: transparent PNG per part at @3x, trimmed; one full composite per pose for reference; the palette from §2 (±5 % allowed).
- Sources, in order of preference: an illustrator working from the `InkCast` sheet; a style-trained game-asset generator (Scenario, Layer.ai, Leonardo); or GPT-image / Gemini with the poster as a style reference. For AI output, check commercial terms, and note that unedited AI images generally can't be copyrighted in the US.
- Style block for any brief or prompt: *"2D mobile-game character art, bold uniform black outline, flat cel shading with three tones and one hard shadow shape, light from upper-left, saturated teal / red / gold palette, clean shapes, no texture noise, no gradients, transparent background, side view facing right, full body, feet on a flat baseline."*
- Start with Pip, then Ember, then Sir Pennant. World layers can stay generated. They already hold up, and a matching raster pass is optional.

---

## 10. PR plan

Each PR is small and demoable, in the order below. Conventional-commit titles.

| # | Title | Scope | Acceptance |
|---|---|---|---|
| 1 | `feat(design): bundle and register Andika, Fredoka and Lilita One` | §1 | Andika's single-storey *a* on device; font-presence test; all snapshots re-recorded |
| 2 | `feat(design): ink tokens, bevel modifier and ink button style` | §2, §3 | tokens in `Palette`; `Bevel`, `InkButtonStyle` with previews; `ContrastTests` extended; no screen changes yet |
| 3 | `feat(reading): restyle the reading chrome` | §4 | `WordCard`, `WordRow` states, `Ball`, `MicPill`, `ProgressRail`, `StarChip`, top bar ribbon; snapshots match `InkMeadow` / `InkHeard` |
| 4 | `feat(world): v2 layers with a palette crossfade on stage change` | §7.1–7.2, 7.4 | 12 layers; the crossfade covers all four layers; no world filters; `WorldArtTests` updated |
| 5 | `feat(world): dusk lights and fireflies` | §7.3 | torches flicker, warm pool, fireflies; off with Reduce Motion |
| 6 | `feat(world): Pip from atlas textures` | §8.1, 8.4 | `FoxNode` draws from `fox.atlas`; gait unchanged; `FoxArt.swift` deleted |
| 7 | `feat(world): Sir Pennant and Ember as actors` | §8.2–8.3 | on `actorLayer`, placed by near-x, idle loops, dragon fire on the story's last word |
| 8 | `feat(home): v2 home screen` | §5 | world header, story thumbnails from the world, badges, TV button; snapshot matches `InkHome` |
| 9 | `feat(reading): v2 TV and iPad layouts` | §6 | TV crop and scale; iPad with v2 components |

Reduce Motion (all PRs): no flicker, no fireflies, no sparkle bursts. Wings and tail hold still, and the fire shows as a static frame.

---

## 11. Open questions

1. Wordmark: redraw the poster lettering as a vector asset, or ship the poster's raster lettering?
2. Should the ball become a character, e.g. a small spark creature? The rig system would support it; the current spec keeps a plain ball.
3. Dark-mode snapshots: drop them, or keep them asserting that the output is identical?
4. Raster art: who produces it, and is Pip first?
