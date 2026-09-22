# Hop Tales — engineering handoff

A read-aloud game for early readers. A large word sits in the middle of the screen with a bouncing ball on top. When the child says the word, the ball hops to the next one, the finished word shrinks into an amber pill and slides left, and the world behind the card scrolls forward. Six sentences per story. The world escalates from a quiet meadow to a castle road to a dragon's hill at dusk — the harder it gets, the cooler it looks.

iPhone first. Same build runs on iPad (any orientation, laid out for landscape; App Store Connect rejects an iPad bundle that leaves one out) and drives an Apple TV over AirPlay as a second screen. No tvOS target in v1.

This document plus `Design/` is everything Claude Code needs to start. Decisions below are made; override them if you disagree, but say so in the commit.

---

## 0. Decisions to confirm before writing code

| Decision | Chosen | Why |
|---|---|---|
| Rendering | **SpriteKit** scene inside a SwiftUI shell | Parallax layers, particles, lights and shaders are native; SwiftUI owns chrome, navigation and text |
| Min OS | iOS 17 / iPadOS 17 | `UIWindowScene` external-display role, modern `Observation` |
| State | Plain `@Observable` store, TCA optional | Domain is small; add TCA if you want reducers for the speech state machine |
| Speech | `SFSpeechRecognizer`, on-device only | Privacy for a child's voice, no network needed, no 1-minute server limit |
| TV | AirPlay external display (`.windowExternalDisplayNonInteractive`) | The phone stays the microphone and the controller; TV is a big passive view |
| Fonts | **Andika** (words) + **Fredoka** (UI), both SIL Open Font License, bundled | Andika is a literacy face: single-storey *a* and *g* match how kids are taught to write |
| Assets | Vector SVG → rasterised PNG at 2×/3× at build time (script in §7) | SpriteKit wants textures; keep SVG as source of truth |

---

## 1. Product rules (don't break these)

1. **The reading surface never moves.** The word card, ball, mic pill and progress rail are in the same place on every stage. Only the world behind changes. A child's eye must never have to re-find the word.
2. **Only one word is big.** Completed words are small amber pills to the left; upcoming words are small and muted to the right. The current word is 3× the size of everything else.
3. **Recognition is forgiving.** A five-year-old's pronunciation is not a dictation test. Match loosely (§5), never punish, never show a red X.
4. **Nothing is timed against the child.** The world only advances when a word is read. Silence is fine. After ~6s of silence, the app *offers help* (word is spoken aloud, gently) — it does not fail.
5. **No ads, no external links, no data leaves the device.** Speech recognition is on-device. Nothing is recorded or stored.
6. **A parent gate** guards settings (hold-for-2s or a simple arithmetic question).

---

## 2. Screens

Interactive artboards are in `Design/artboards/*.dc.html` (each is a self-contained HTML file; open in a browser). Rendered previews in `Design/preview-*.png`.

| Artboard | What it is |
|---|---|
| `Main` | Home / story select. Greeting, "Keep going" card, three story rows, "Play on the TV", parent gear |
| `PhoneEarly` | Stage 1 core loop — meadow. Current word `sat` |
| `PhoneHeard` | The recognised moment — ball at apex, `sat` flashing into a pill, `on` growing into place, green "Heard it" pill, `+1 star` |
| `PhoneCastle` | Stage 3 — castle road, golden hour, knight on horseback |
| `PhoneDragon` | Stage 6 — dragon's hill at dusk, fire, torches, fireflies |
| `Parallax` | 48s animated demo of the whole traverse (layer speeds, sky crossfade, colour grade, lights fading up) |
| `TV` | 1920×1080 Apple TV frame, dragon stage |
| `iPad` | 1194×834 landscape, castle stage |
| `World` | The asset sheet: composite + each layer isolated |

---

## 3. Design tokens

### Colour

```swift
enum Palette {
    static let ink        = Color(hex: 0x2E2A3B)   // text, ball shadow
    static let cream      = Color(hex: 0xFFF8EC)   // card, chips, pills
    static let creamDeep  = Color(hex: 0xFFF1D4)   // star chip on home
    static let amber      = Color(hex: 0xFFB23F)   // progress, stars, recognised flash
    static let amberDeep  = Color(hex: 0xE07A22)
    static let ballHi     = Color(hex: 0xFFD9A8)
    static let ball       = Color(hex: 0xFFA552)
    static let ballLo     = Color(hex: 0xD96A1B)
    static let pillBg     = Color(hex: 0xFFE0A8)   // completed word
    static let pillText   = Color(hex: 0x8A5A12)
    static let flashText  = Color(hex: 0x4A2D05)   // text on amber flash
    static let muted      = Color(hex: 0x6E6780)   // next word, labels
    static let faint      = Color(hex: 0x9A94A6)   // word after next
    static let chipText   = Color(hex: 0x5C5670)   // story label
    static let listenBars = Color(hex: 0x7CBA63)
    static let heardBg    = Color(hex: 0xDCF0CE)
    static let heardText  = Color(hex: 0x34601F)
    static let duskRoot   = Color(hex: 0x1B1738)
}
```

All chrome (card, chips, pills, buttons) is cream on every stage. Chrome never changes with time of day — only the world does.

### Type

| Role | Font | Size (phone / iPad / TV) | Weight | Tracking |
|---|---|---|---|---|
| Current word | Andika | 64 / 100 / 144 | 700 | −0.01em (−0.015em on TV) |
| Side words | Andika | 22 / 32 / 48 | 700 | 0 |
| Greeting | Fredoka | 30 | 500 | 0 |
| Story title (home rows) | Fredoka | 18–20 | 600 | 0 |
| Chip / label caps | Fredoka | 11 / 13 / 16–18 | 600 | +0.16em (+0.18em TV) |
| Body / meta | Fredoka | 14–17 | 400–500 | 0 |
| Mic pill text | Fredoka | 15 / 16 / 20 | 500 | 0 |

Long words shrink the current-word size, never the card: `knight` is 52pt on phone, `guarded` 46pt. Rule: fit the current word plus one word either side inside the card; the row may overflow the card edges (clipped) — that's the "scrolling off" cue.

### Shape, depth, spacing

- Card radius 34 (phone) / 44 (iPad) / 56 (TV). Chips and pills are fully round (`.capsule`).
- Shadows are **hard offset + soft**: `0 12 0 rgba(46,42,59,.10)` under the card plus `0 24 40 rgba(scene-dark, .18)`. Chips: `0 4 0 rgba(46,42,59,.12)`. On the dusk stage the hard shadow goes to `rgba(0,0,0,.28)`.
- Touch targets ≥ 48pt (phone), 56pt (iPad). TV has no touch.
- Phone safe layout (390×844 reference; scale proportionally for other iPhones):
  - Top bar: y 48, side padding 20, height 48
  - Word card: x 16, y 452, w 358, h 196
  - Progress: x 28, y 674, w 334 (label, then 12pt gap, then 34pt rail)
  - Mic pill: centred, y 762
- iPad (1194×834): top bar y 32 / padding 32; card x 147 y 470 w 900 h 236; progress y 736; mic pill lives in the top bar.
- TV (1920×1080): 96pt overscan margin on all sides. Top bar y 96; card x 240 y 560 w 1440 h 300; progress y 900 w 1440.

---

## 4. The word track — component spec

The card holds two things: the **ball lane** (top 78pt) and the **word row**.

### Word states

| State | Look |
|---|---|
| `upcoming` | Side size, colour `muted`; the one after that `faint` |
| `current` | Big size, `ink`, ball sits above its horizontal centre |
| `recognised` (transient, ~450ms) | Text `flashText` on `amber` pill, radius 14, padding 4×12, outer ring 5pt `amber @ 28%`; three small amber sparkles pop off it; size animates big → pill |
| `completed` | Side size, `pillText` on `pillBg` pill, radius 10, padding 3×9 |

Row layout: horizontal stack, gap 10 (phone) / 22 (iPad) / 32 (TV), items vertically centred. The **current word's centre is pinned to the card's horizontal centre**; the row translates so that holds. Overflow is clipped by the card's rounded rect.

### Ball

Radial gradient sphere (`ballHi` → `ball` → `ballLo`, highlight at 35%/30%), radius 19 (phone) / 26 / 34. Rests 30pt above the word row baseline. Shadow: ellipse `ink @ 14%` under it that scales with hop height (bigger hop → smaller, lighter shadow).

### Motion (all durations in seconds)

| Event | Timing |
|---|---|
| Idle hop | translateY 0 → −26 over 0.72s, forever. **Ballistic, not eased**: the rise decelerates into the apex, the fall accelerates out of it, and the ball rests a beat on the ground between hops. A squash on contact (scaleY 0.88, anchor bottom) and a slight stretch on the rise. The `cubic-bezier(0.3, 0, 0.2, 1)` this row used to specify is slow at both ends, which reads as floating rather than bouncing |
| Recognised | Ball arcs to next word: quadratic path, apex −46, 0.45s ease-in-out. Current word morphs to pill over the same 0.45s. Row slides left so the new word is centred, 0.45s. Sparkles: 3 stars scale 0→1→0 over 0.5s, offset 0/0.08/0.16 |
| `+1 star` | Chip appears near star counter, rises 24pt and fades over 0.9s |
| Mic pill | While listening: 5 bars animate height between 6–17pt, each on its own 0.35–0.55s loop. On recognised: pill turns `heardBg`, checkmark, text `Heard it — “sat”`, holds 1.2s, returns |
| World | Every recognised word advances world progress by one word-step (§6). Layers ease over 0.6s, `easeOutExpo (0.16, 1, 0.3, 1)` |
| Sentence complete | Ball does a double hop; progress node fills; next sentence's words slide in from the right |

Honour `UIAccessibility.isReduceMotionEnabled`: hop becomes a 2pt bob, no sparkles, layers cut instead of ease.

### Progress rail

Six nodes, evenly spaced. Completed: r7 `amber` filled, rail segment amber 4pt. Current: r11 `cream` fill, 4pt `amber` stroke. Future: r6 white @ 75%. Tiny milestone glyphs above nodes 3 (castle) and 6 (dragon) at 50–60% ink. Label above: `SENTENCE 2 OF 6`, caps style. When a new word is introduced: `SENTENCE 3 OF 6 · NEW WORD “KNIGHT”`.

---

## 5. Speech recognition

```swift
let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-CA"))!  // match the child's accent
guard recognizer.supportsOnDeviceRecognition else { /* show unsupported-device sheet */ }

let request = SFSpeechAudioBufferRecognitionRequest()
request.requiresOnDeviceRecognition = true
request.shouldReportPartialResults = true
request.taskHint = .dictation
request.contextualStrings = sentence.words.map(\.text)   // biases the model toward the story vocabulary
```

- One `AVAudioEngine` tap → recognition task per **sentence**. Tear down and restart between sentences (cheap, and keeps transcripts short).
- Audio session: `.record`, mode `.measurement`, options `[.duckOthers, .allowBluetooth]`. Do not use `.playAndRecord` with speaker output while listening — the ball hop sound will be transcribed.
- **Matching** (run on every partial result):
  1. Normalise transcript: lowercase, strip punctuation, split on whitespace.
  2. Look at the last 3 tokens only.
  3. Target = current word. Also accept the *next* word (kids read ahead) — if next matches, mark current as recognised too.
  4. Accept if: exact match; **or** Levenshtein ≤ 1 when target length ≥ 4; **or** target and token share the same first two letters and the same length (early readers drop/garble final consonants); **or** token is in the target's homophone list (`for/four`, `to/two/too`, `there/their`, `knight/night`, `sea/see`…). `the` also accepts what a child's `the` is usually transcribed as — `a`, `uh`, `duh`, `da`, `de`, `dee`, `thee`, `thuh`, `they`, `then` — because it is unstressed, short, and too short for the Levenshtein rule. That table lives in `WordMatcher.soundsAlike`, not in `stories.json`, so every story gets it.
  5. Debounce: a token must appear in two consecutive partials **or** the result must be `isFinal` before it counts. This kills single-frame misfires.
- **Strictness** is a parent setting (`gentle` = rules above, `standard` = exact or Levenshtein ≤ 1 only). Default `gentle`.
- **Silence helper**: if no partial change for 6s, speak the word with `AVSpeechSynthesizer` (rate 0.42, a warm voice — `com.apple.voice.compact.en-US.Samantha` or the best available `.enhanced`) and briefly pulse the word. Tapping the current word does the same on demand. Speaking pauses recognition for the utterance duration + 300ms so the app doesn't hear itself.
- Mic permission + speech permission requested together on first story start, with a one-screen kid-and-parent-friendly explanation. Never on launch.

---

## 6. The world — parallax system

One continuous world, **2340 × 844 pt**, six phone-widths long. Every screen is a crop of it.

### Layers and speeds

| Layer | File | Speed | Contents |
|---|---|---|---|
| Sky | `sky-day.svg`, `sky-gold.svg`, `sky-dusk.svg` | 0× (fixed) | Gradient, sun/moon, clouds, god rays, stars. Three variants, crossfaded by progress |
| Far | `layer-far.svg` | 0.3× | Two mountain ranges, snow caps, fog band, far tree line |
| Mid | `layer-mid.svg` | 0.6× | Rolling hills, windmill (x 300), castle (x 836, base y 400), ruined keep (x 1458, base y 392), trees turning to pines |
| Near | `layer-near.svg` | 1× | Ground, path, fence, flowers, big trees, signpost (x 1300), mounted knight (x 1176, base y 436), dragon (centre 2170,212 at 0.62 scale), unlit torches (x 2000, 2240) |
| Actors | code | 1× | The fox companion (always on screen at x≈150, ground y≈436), light sprites |

Layer coordinates: origin top-left, y down, all layers share the same 844pt height so y lines up. The ground crest is at y≈445–460; everything below y 460 is hidden behind the card on phone.

### Scroll maths

`p` = world progress in near-layer points. Each recognised word adds `wordStep = 1950 / totalWordsInStory` so a full story traverses the world exactly once (0 → 1950 leaves one phone-width of near layer showing at the end).

```
far.x  = -0.3 * p
mid.x  = -0.6 * p
near.x = -1.0 * p
```

Stage reference offsets used in the comps: meadow `p=0`, recognised moment `p=60`, castle `p=1000`, dragon `p=1950`.

For the TV (1920×1080): scale the whole world by `1080/844 = 1.2796`, then the visible near-layer window is 1500pt wide. The comp uses `near.x = -840` so castle (left) and dragon (right) are both in frame. Sky is positioned independently on TV (moon at world x≈300). For iPad (1194×834): scale `0.9882`, comp uses `near.x = -227`.

### Time of day

Layers are painted **once, in neutral daylight**. Stages apply a colour grade plus additive light sprites — same as you'd do with `SKLightNode` and normal maps. The comps use CSS filters; equivalents:

| Stage | Sky | Far + mid grade | Near grade |
|---|---|---|---|
| Meadow (p < 650) | `sky-day` | none | none |
| Castle (650 ≤ p < 1400) | `sky-gold` | `sepia .24, saturation 1.18, brightness 1.02, contrast 1.03` | same |
| Dragon (p ≥ 1400) | `sky-dusk` | `brightness .48, saturation .70, sepia .40, hue +205°, contrast 1.08` | `brightness .58, saturation .75, sepia .15, hue +18°, contrast 1.06` |

Crossfade skies and lerp grades over ~200pt of progress around each boundary. **The near layer must not get the +205° hue shift** — it turns the purple dragon green.

Implementation options, cheapest first:
1. **Bake**: a build script renders each layer × 3 grades to PNG. Crossfade two textures. Zero runtime cost. Recommended for v1.
2. `SKEffectNode` with `CIColorControls` + `CISepiaTone` + `CIHueAdjust`, `shouldRasterize = true`. Fine for 3 layers.
3. Custom `SKShader` per layer with a `u_grade` uniform lerping between three colour matrices. Best when you want the transition to be continuous.

### Light sprites (dusk only, fade in from p ≈ 1400)

Positions are in the layer's own coordinates; attach each to its layer's node so it parallaxes correctly.

| Sprite | Layer | Position | Look |
|---|---|---|---|
| Dragon fire | Near | dragon-local (−186, −64), pointing left | Three nested flame shapes `#FF7A2F` → `#FFB23F` → `#FFF1B8`, blurred `#FF6A2A` halo, 5 ember dots drifting left. Flicker: scale 0.94–1.06 at ~9Hz |
| Dragon eye | Near | dragon-local (−150, −93) | `#FFF3B0` ellipse with 11pt `#FFE27A` glow |
| Belly / neck warmth | Near | along belly stroke | `#FFB84A` @ 30%, blurred 3pt |
| Torch flames | Near | torch top (torch x, base y − 64) | Teardrop `#FF6A2A`→`#FFF1B8`, 34pt radial glow `#FFC96B`. Flicker like fire |
| Keep windows | Mid | ruin (1458,392) + (−10..2, −120), (−10, −78), (−6, −38) | `#FFD27A` rounded rects, one blurred copy behind, 40pt glow |
| Castle windows | Mid | castle (836,400) + window rects in `layer-mid.svg` | Same treatment, appear only on TV/iPad where the castle is in frame at dusk |
| Fireflies | Near | random over ground y 300–450 | 1.5pt `#FFF6C0` core + 6pt `#FFE27A` glow, drift ±20pt, blink 2–4s |
| Moon glow / ember band | Sky | fixed | 150pt radial cream glow at moon; 220pt-tall horizontal warm band around y 300–520, screen blend, 24–28% |
| Pollen (meadow) / dust (castle) | Actors | random | 4–6pt soft cream discs, slow upward drift, 8–12 on screen |

### Parallax demo

`Design/artboards/Parallax.dc.html` animates the whole 48s traverse in CSS. Watch it once before implementing the scene — it is the acceptance test for motion feel.

---

## 7. Assets

```
Design/
  world/
    sky-day.svg  sky-gold.svg  sky-dusk.svg      2340×844, fixed layer
    layer-far.svg  layer-mid.svg  layer-near.svg  2340×844, transparent
    sprite-dragon.svg                              standalone dragon, local coords (see §6)
  artboards/*.dc.html                              the design comps (open in a browser)
  preview-*.png                                    rendered comps for reference
```

Rasterise with a script at build time (keep SVG as source):

```bash
# e.g. scripts/render-assets.sh — needs rsvg-convert or Chromium
for f in Design/world/*.svg; do
  n=$(basename "$f" .svg)
  rsvg-convert -w 4680 "$f" -o "HopTales/Assets.xcassets/World/$n.imageset/$n@2x.png"
  rsvg-convert -w 7020 "$f" -o "HopTales/Assets.xcassets/World/$n.imageset/$n@3x.png"
done
```

4680×1688 @2× textures are within SpriteKit limits but big; if memory bites on older iPhones, split each layer into three 780pt tiles and only load the two that are visible.

The dragon in `layer-near.svg` is the unlit base. Ideally extract it to its own node (`sprite-dragon.svg`) so it can bob (translateY ±6, 2.4s) and flap (wing scaleY 0.92–1.0, 1.1s) independently, and so it can be removed from the near layer. The fox has no standalone file — rebuild from `PhoneEarly.dc.html` (`<g transform="translate(150,436)">…`) or redraw; it needs an idle (breathe), trot (4 frames) and celebrate (jump) state.

Characters that need frames for v1: fox (idle/trot/celebrate), ball (none — procedural), dragon (bob/flap/fire — procedural transforms on grouped nodes is enough). The knight and windmill are static in v1 (windmill blades may rotate).

---

## 8. Architecture

```
HopTalesApp (SwiftUI)
 ├─ AppStore (@Observable)          progress, stars, settings, current story/sentence/word
 ├─ SpeechEngine                    AVAudioEngine + SFSpeechRecognizer, publishes .heard(word) / .silence(seconds)
 ├─ WordMatcher                     pure function: (transcriptTokens, target, next, strictness) -> Match?
 ├─ Views
 │   ├─ HomeView                    Main artboard
 │   ├─ ReadingView                 chrome: top bar, WordCard, ProgressRail, MicPill — over a SpriteView
 │   └─ ParentSettingsView          behind ParentGate
 ├─ WorldScene: SKScene             layers, actors, lights, grade; exposes setProgress(_:animated:) and setStage(_:)
 └─ ExternalDisplayScene            a second UIWindowScene (role .windowExternalDisplayNonInteractive) hosting TVReadingView + its own WorldScene, observing the same AppStore
```

- `WordCard` is SwiftUI (`Text` with `matchedGeometryEffect` for the shrink-to-pill morph). The ball is a SwiftUI shape animated with `Animation.timingCurve(0.3, 0, 0.2, 1, duration: 0.72).repeatForever(autoreverses: true)`. Keep text in SwiftUI — SpriteKit text rendering is not good enough for the reading surface.
- `WorldScene.setProgress(p)` runs `SKAction.moveTo(x:duration: 0.6)` with `timingFunction = easeOutExpo` on the three layer nodes. `setStage` crossfades sky textures and grades.
- `SpriteView(scene:, options: [.allowsTransparency])` sits behind the chrome. `preferredFramesPerSecond = 60`; drop to 30 when the app is backgrounded to the external display only.
- External display: implement `UIApplicationDelegate.application(_:configurationForConnecting:options:)`; when `connectingSceneSession.role == .windowExternalDisplayNonInteractive`, return a configuration whose delegate builds `TVReadingView`. The phone keeps showing its own `ReadingView` (it is the mic). Progress, word state and stage come from the shared store; the TV scene sizes its own crop (§6).
- iPad: `ReadingView` uses a `horizontalSizeClass == .regular` layout branch matching the `iPad` artboard (mic pill in the top bar, 900pt card).

### Data

```swift
struct Story: Identifiable, Codable {
    let id: String            // "meadow-morning"
    let title: String         // "Meadow morning"
    let sentences: [Sentence] // exactly 6 in v1
    let stage: StageTheme     // .meadow, .castle, .dragon — which chunk of the world this story owns
}
struct Sentence: Codable { let words: [Word]; let newWord: String? }
struct Word: Codable { let text: String; let homophones: [String] }

struct Progress: Codable {   // persisted in Application Support as JSON, one file
    var stars: Int
    var completedSentences: [String: Int]   // storyID -> count
    var wordsRead: [String: Int]            // word -> times read correctly
}
```

Bundled starter content (JSON), sentence case, one new "hard" word per story:

- **Meadow morning** — `The cat sat on the mat.` / `The fox ran to the tree.` / `A bird sang in the sun.` / `The dog dug in the mud.` / `We can hop and skip.` / `The sun is up and it is fun.`
- **The castle road** — `The road went up the hill.` / `We saw a big red flag.` / `The young knight rode past.` (new: *knight*) / `His horse was brown and fast.` / `The gate was made of wood.` / `The king waved from the wall.`
- **Dragon's hill** — `The sky got dark and red.` / `We saw a light on the hill.` / `A dragon flew over the trees.` (new: *dragon*) / `Its wings were big and purple.` / `The dragon guarded the gold.` / `It was a friend, not a foe.`

Stars: 1 per word, +5 for a sentence with no help, +20 for a finished story. Stars unlock nothing in v1 — they are the counter in the top-right chip.

---

## 9. Kid & accessibility details

- Word taps speak the word. Nothing else on the reading screen is tappable except Back (which asks "Stop reading?" with two big buttons).
- Haptics: `.soft` on hop, `.success` on sentence complete. Off on iPad/TV.
- Sound: a short marimba `hop` on each recognised word (pitch rises across the sentence), a chord on sentence complete, ambient loop per stage (birds / wind + distant flag / crackling fire + crickets) at −18dB under speech. All sounds route to `.ambient` category **between** recognition sessions; while listening, output is muted except the hop (see §5).
- Dynamic Type is not applied to the word track (sizes are the design); it is applied to home-screen text.
- VoiceOver: word card announces "Current word: sat. Say it out loud." Progress rail announces sentence index.
- Colour contrast: all text on cream ≥ 4.5:1 (`muted #6E6780` on `#FFF8EC` = 5.3:1). Labels over the dark ground use `#F0E3D0`.

---

## 10. Milestones

1. **Reading loop, no world.** WordCard + ball + MicPill + WordMatcher + SpeechEngine on a flat green background. Ship to the phone and test with the actual reader. Tune matcher rules here — nothing else matters until this feels right.
2. **World.** `WorldScene` with the three layers + sky-day, `setProgress`, fox actor, pollen. Meadow story end-to-end.
3. **Stages.** Sky crossfade, grades, light sprites, dragon bob/flap/fire, castle and dragon stories.
4. **Second screen.** External display scene, TV crop, iPad layout.
5. **Home & progress.** HomeView, persistence, parent gate + settings (strictness, voice, sound).

Each milestone is a demo to the kid. If step 1 doesn't hold his attention for 6 sentences, stop and fix that before drawing a single mountain.

---

## 11. Open questions

- Locale: `en-CA` assumed. On-device recognition quality varies by locale; test `en-US` too.
- Should the fox be swappable for a character he picks? (Cheap if actors are separate nodes.)
- Word list source — hand-written above; consider Dolch sight words ordered by grade for stories 4–10.
- tvOS native app later? The phone would still need to be the mic (Siri Remote can't stream continuous audio to a third-party app). Multipeer/Bonjour from phone to TV would replace AirPlay — better latency and no mirroring UI, more work.
