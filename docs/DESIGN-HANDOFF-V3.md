# Hop Tales design handoff v3: collage storybook

This supersedes `DESIGN-HANDOFF-V2.md` (Ink & Ember). The design canvas is **"Hop Tales — collage storybook"**. Source art is in `Design/collage/`. To generate new art, follow `docs/ASSET-STYLE-GUIDE.md`.

## 0. What changed from v2

- **Style.** Heavy ink outlines and cel shading are replaced by torn-paper watercolour collage. Characters are white-bordered stickers; scenery has no border.
- **Character.** Pip the fox is replaced by the **hare**, who takes over from the bouncing ball. He sits by the current word, idles, and hops to the next word when it's heard.
- **Type.** Lilita One and Andika are dropped. The new faces are **Fraunces** (titles and buttons), **Young Serif** (reading words) and **Fredoka** (small UI).
- **World.** The fixed 2340 px world is replaced by an **endless** three-layer parallax with a live sky. Time of day and weather change on top of the layers instead of swapping scenes.
- **Onboarding.** The welcome carousel is removed. The launch image crossfades into a sunrise intro that leads either to onboarding or to home.

## 1. Fonts and tokens

Bundle the TTFs from Google Fonts: Fraunces 700, Young Serif 400, and Fredoka 500 and 600. Register them at launch; the v2 font-registration fix still applies.

```swift
enum Paper {
  static let ink      = Color(hex: 0x3B2A20)   // sepia text and icons
  static let paper    = Color(hex: 0xFBF4E4)   // cards, sheets, labels
  static let shade    = Color(hex: 0xEFE3C8)
  static let page     = Color(hex: 0xF4EBD8)
  static let sage     = Color(hex: 0xA6BA92)
  static let sageDeep = Color(hex: 0x7E9A6A)
  static let red      = Color(hex: 0xB8423A)   // primary button
  static let wash     = Color(hex: 0xF7D774)   // read-word highlight
  static let muted    = Color(hex: 0x9C8B78)
  static let night    = Color(hex: 0x1E2A4E)
}
```

**Surfaces.**

- Paper cards have a slightly irregular deckled edge: a polygon mask with ±1.5 % jitter, or a 9-slice paper texture. Shadow is `0 4 7 rgba(60,40,20,.26)`.
- Buttons and chips use a 4–5 pt white rim, the paper fill and a soft shadow.
- The primary button is red with a white label, a 4 pt white rim and 56 pt height.

## 2. Screens

The boards on the canvas are the spec; open each and measure.

| Screen | Board | Notes |
|---|---|---|
| Reading | Reading screen | Top bar: back chip, deckled title label, star chip. Word card: deckled paper, 362×168 at y 548. Read words are ink with a gold wash, the current word is 54 pt, upcoming words are muted. Progress dots sit under the card; the mic pill is at the bottom. The hare sits on the card's top edge above the current word. |
| Home | Intro (returning) / Home | The top bar holds the icon, "Hop Tales" and a settings chip for grown-ups. Greeting label: "Good morning, <name>!". A paper sheet from y 430 holds the "Keep reading" card and the "More stories" list. |
| Onboarding | Intro (first launch) | Four steps on one paper sheet over the live meadow. No carousel. |
| TV | Apple TV | The same world at 1920×1080 with a large word card. Props scale by depth. |
| App icon | App icon · V | `Design/collage/brand/AppIcon-1024.png` |

**iPad.**

- The world fills the screen, and the land scale is `0.42 × max(1, minSide / 390 × 0.62)`.
- The reading card and onboarding sheet are capped at 560 pt wide and centred.
- The home sheet becomes a 560 pt centred column.

## 3. Launch and intro

**Launch image = frame 0 of the intro.** The shipped images are in `Design/collage/launch/`:

- `Launch-iPhone-1320x2868.png`
- `Launch-iPad-2064x2752.png`
- `Launch-iPad-2752x2064.png`

Use a `LaunchScreen.storyboard` with one image view set to aspect-fill, with separate iPhone and iPad images in the asset catalog. Frame 0 shows the night gradient, stars, and dimmed land shifted down 26 × k pt, with no sun, clouds, hare or title.

Build the intro scene with the same layout maths, so the first rendered frame matches the launch image pixel for pixel. The launch then crossfades (0.25 s) into a live scene that starts identical.

**Layout** (scene size W×H; S as in §2; `k = S / 0.42`):

- Far layer top: `H − 986·S`
- Mid layer top: `H − 848·S`
- Near layer top: `H − 705·S`
- Sun width: `295·S`
- Sun top: `H − 1224·S`
- Path line (hare's feet): `nearTop + 430·S`

**Timeline**, in seconds:

| t | Event |
|---|---|
| 0.0 | Launch image on screen; live scene underneath, identical |
| 0.6–4.6 | Sunrise. The sky crossfades night → dawn (`#8FA6CF → #F6D6A6`) → day. The sun rises 210·k pt with a warm glow, the stars fade by 55 %, two clouds drift in, and the land lifts 26·k pt while its brightness goes 0.42 → 1 (staggered 0.12 s far → near). |
| 3.9 | The front-facing hare pops up on the path: squash 0.9/1.08, overshoot, settle. |
| 4.2 | Title label "Hop Tales" and "a read-aloud adventure" fade in near the top. |
| 5.6 | The hare **turns**: the front sprite squashes to 0.7 wide and swaps to the side-on sit sprite with a small anticipation squash. |
| 6.0–7.15 | He **runs off right**: the hop sheet loops twice at 14 fps while the node eases right off-screen. |
| 6.2–6.7 | The title lifts 24 pt and fades out. |
| 6.7 | The interface rises in (80 pt, 0.7 s, ease-out); the top bar follows 0.15 s later. |

**Routing at 6.7 s:**

- Has a `Profile` → **Home**.
- No profile → **Onboarding**.

Reduced Motion collapses the sequence to a 0.3 s crossfade from the launch image straight to the destination.

## 4. Onboarding (no carousel)

One paper sheet from y 330 over the meadow. It has progress pills (the active one 22 pt wide, the rest 8 pt), "Step n of 4", a Fraunces 28 heading, Fredoka 16 body text and a primary button. Steps slide in 18 pt with a fade.

1. **What should we call you?**
   - Body: "A first name, a nickname or anything familiar is perfect. We use it to say hello, and it never leaves this device."
   - A "Name or nickname" field, then Continue.
2. **Can Hop Tales use the microphone?**
   - Body: "The microphone lets Hop Tales hear your child read, so the hare can hop to the next word. Everything is heard on this device. Nothing is recorded, and nothing is sent anywhere."
   - Button: Allow microphone. Denied and unsupported use the existing copy.
3. **What's your reader's reading level?**
   - Three choice cards: Just starting, Getting going, Reading well, each with its example-word line.
   - The selected card gets a red 3 pt border.
4. **What's your reader's accent?**
   - Canadian, American, British or Australian, in a 2×2 grid.
   - Button: **Start reading**. It saves the Profile and moves to Home, greeting the child by name. "Start here" points at the story the reading level picked.

Remove the `welcome` step and `WelcomeCarousel.swift`; the intro replaces them.

## 5. The world (endless)

| Layer | File (@2x) | Loop width | Speed |
|---|---|---|---|
| Sky | code: gradient per time of day | — | 0 |
| Far hills | `world/far-day.webp` | 5615 | 0.3× |
| Mid fields | `world/mid-day.webp` | 4692 | 0.6× |
| Near meadow + path | `world/near-day.webp` | 3555 | 1× |

- Tile each layer horizontally forever as two SKSpriteNodes leapfrogging.
- The loop widths are deliberately different, so the layers never line up the same way twice.
- Scatter props (borderless, `Design/collage/soft/`) from a seeded RNG along the near layer, and scale them by depth.
- The sky pieces are in `world/soft/`: clouds 1–4, storm 1–3, sun, moon, stars 1–3.

**Time of day.** Crossfade the sky gradient, and tint the land layers with a multiply colour:

| Time | Sky gradient (top → bottom) | Land tint far / mid / near |
|---|---|---|
| Day | `#BCDCEE → #DCEBEF → #EEF2E6` | white |
| Golden hour | `#F0C9A4 → #F7DDB8 → #FBEBCB` | `#FCD6AA / #FFDEB4 / #FFE8C4` |
| Dusk | `#7F74A6 → #C98FA2 → #F0B48E` | `#C4A0C8 / #D6ACBE / #E8BEBE` |
| Night | `#18223F → #2C3A63 → #46557E` | `#5C6CA0 / #6070A0 / #6876A0` |

The moon and stars fade in at night.

**Weather.**

- **Clouds:** fair clouds at full opacity, with a few storm clouds coming in.
- **Storm:** storm clouds and a grey sky overlay, land tint times 0.74, occasional lightning flashes.
- **Rain:** two diagonal streak emitters at different speeds.

Story progress drives these with 3 s crossfades.

## 6. The hare

| Animation | Asset | Timing |
|---|---|---|
| Idle | `sprites/hare-idle-frames` (10 drawings, 260×373) + `idle-timeline.json` | Hold `rest` and breathe (scale y 1.014 / x 1.006, 3.8 s, anchored at the feet). Events over an 18 s cycle: blinks, an ear flick, a head tilt, a sniff, each eased through its in-betweens. Shuffle the order and vary the gaps by ±30 % each cycle. |
| Hop to next word | `sprites/hare-hop` (8 frames, 363×346) | 14 fps, once. Move one word forward during frames 2–7, then go back to idle. |
| Turn (intro) | `brand/hare-front-sit.png` → `hare-sit.png` | See §3 |

Build SpriteKit atlases `hare-idle.atlas` and `hare-hop.atlas` from the strips.

## 7. Marketing site

The site boards are desktop 1440 and mobile 390. Full-page renders are in `Website/reference/collage-*.jpg`.

Structure and copy are the same as `Website/HANDOFF.md` except:

- The new tokens and fonts from §1.
- Paper cards replace bevels.
- The hero is the meadow with the leaping hare.
- A sage "A world that keeps going" band shows four moods.
- The call to action is a night scene.
- Swap in Apple's official App Store badge.

## 8. Build order

1. Fonts and `Paper` tokens.
2. Launch storyboard, then the intro scene with routing (§3).
3. Onboarding sheet steps; delete the carousel.
4. Endless world layers and the time/weather controller.
5. Hare atlases, idle controller, and hop on word heard.
6. Reading screen and home restyle.
7. App icon, then TV and iPad layout passes.
