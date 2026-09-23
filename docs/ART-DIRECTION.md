# Hop Tales — art direction v2: Ink & Ember

The app icon and launch poster already set the brand: bold black outlines, chunky cel shading, a teal / red / gold palette. The v1 world (soft gradient vectors) and the SwiftUI chrome did not match it, which is most of why the game read as "hand drawn". v2 brings everything onto the poster's style.

Design canvas: the "v2 · Ink & Ember" page of the Hop Tales design artifact. Source art: `Design/ink/`.

## 1. Rules

| Rule | Spec |
|---|---|
| Ink | `#1D1A2C` for every outline and all reading text |
| Outline weight = depth | UI and near layer 4 px · characters 3.6 px · mid layer 3 px in a *tinted* ink (the layer's darkest tone) · far layer and sky: no outline |
| Light | One key light, upper-left. Shadows are hard-edged shapes lower-right — never a blur on a form |
| Shading | Three tones per material: base, shade, highlight. A fourth "deep" tone only for crevices |
| Ground contact | Soft ink ellipse at 25–30 % under every character and prop |
| Time of day | A **palette swap**, not a filter. Every layer ships in day / gold / dusk and crossfades like the sky already does. Runtime hue-rotation turned the purple dragon green in v1 |
| Chrome | Parchment surfaces with an ink border, a solid ink drop, a darker inner lip and a white top highlight — the "bevel" |

## 2. Tokens

```swift
enum Ink {
  static let ink          = Color(hex: 0x1D1A2C)
  static let parchment    = Color(hex: 0xFFF6E2)
  static let parchmentLip = Color(hex: 0xEBD5A6)
  static let page         = Color(hex: 0xF7E9C8)
  static let red          = Color(hex: 0xDB2A2E)   // shade A3141D, light FF6A55
  static let gold         = Color(hex: 0xF6BB3E)   // shade C7861A, light FFE39A
  static let teal         = Color(hex: 0x1E8C8C)   // shade 136066, light 48B8B0
  static let ball         = Color(hex: 0xFF9A3C)   // shade D8601A, light FFE2B8
  static let dragon       = Color(hex: 0x7C52C4)   // shade 553A9E, light A884EE
  static let muted        = Color(hex: 0x6E6780)
  static let faint        = Color(hex: 0x9A94A6)
}
```

The bevel, as one modifier:

```swift
struct Bevel: ViewModifier {
  var fill: Color, lip: Color, radius: CGFloat, drop: CGFloat = 4
  func body(content: Content) -> some View {
    content
      .background(
        RoundedRectangle(cornerRadius: radius).fill(fill)
          .overlay(alignment: .bottom) {
            RoundedRectangle(cornerRadius: radius).fill(lip).frame(height: drop + 2).mask(RoundedRectangle(cornerRadius: radius))
          }
          .overlay(alignment: .top) { Capsule().fill(.white.opacity(0.85)).frame(height: 3).padding(.horizontal, radius * 0.6) }
      )
      .overlay(RoundedRectangle(cornerRadius: radius).strokeBorder(Ink.ink, lineWidth: 3))
      .background(RoundedRectangle(cornerRadius: radius).fill(Ink.ink).offset(y: drop))
  }
}
```

Pressed state: drop collapses to 1 and the view offsets down 3.

## 3. Type

| Face | Role | Notes |
|---|---|---|
| Lilita One | Display: titles, ribbons, numbers, button labels | New. OFL. Ribbons/wordmark get a 4–9 px ink stroke (`paint-order: stroke`) |
| Fredoka 600 | UI: meta, labels, mic pill | Already specified |
| Andika 700 | The words a child reads — nothing else | Already specified |

**Bug in the current build:** none of these fonts are bundled or registered — the app falls back to SF Pro everywhere (visible in every snapshot: double-storey *a* in "The"). Fix: add the TTFs to `DesignSystem/Resources/Fonts`, give the target `resources: [.process("Resources")]`, and call `CTFontManagerRegisterFontURLs` once at launch (and in `SnapshotSupport` before re-recording). TTFs are in `Design/ink/fonts/`.

## 4. Components (see the Design library artboard)

- **Buttons** — gold primary (ink label), teal secondary (parchment label), parchment tertiary. 58 pt tall, capsule.
- **Back button, star chip** — 52 pt parchment bevel; the star chip leads with a gold coin.
- **Story ribbon** — notched red banner, Lilita One 17, parchment fill, ink stroke.
- **Word card** — parchment, 4 px ink, 6 px drop, 9 px lip, radius 32 (44 iPad, 56 TV).
- **Word states** — read: gold-light pill, ink 2.5 px border, 3 px drop · just heard: gold pill with 6 px glow ring · current: Andika 64 ink · next: muted · after: faint.
- **Mic pill** — teal disc with mic glyph, ink-outlined level bars; heard state turns green with a check.
- **Progress trail** — dirt-brown track, gold coin nodes (done), parchment ring with orange core (current), grey stones (future); castle and dragon glyphs above nodes 4 and 6.
- **Hop ball** — orange, ink outline, hard cel shade, two specular dots. Squash 0.72 on landing, stretch 1.25 at take-off.

## 5. Sprites

All characters are **rigged cut-out sprites**: each part is its own texture with a pivot, animated in SpriteKit. `FoxNode` already works this way — only its CoreGraphics drawing changes.

| Character | Parts | Frames / motion |
|---|---|---|
| Pip the fox | tail, far legs ×2, body, near legs ×2, scarf tail, head, scarf wrap | trot (4 poses from leg rotation ±18°, tail ±4°, bob 1–3 px, scarf flap), jump, cheer. Idle/happy eyes swap on the head |
| Sir Pennant (knight) | body, shield arm, banner, plume | wave, banner flutter |
| Ember (dragon) | body, near wing, far wing, head, tail | wing flap ±16–22°, roar mouth, fire sprite on the last word |
| Hop ball | one texture | squash/stretch transform |

Export: SVG → PNG @2x/@3x into a SpriteKit texture atlas per character (`fox.atlas`, …). Pivots in the generator (`Design/ink/generator/fox.py`) — red dots on the Cast artboard.

## 6. World

One 2340 × 844 world, unchanged metrics and parallax maths. New layers:

| Layer | Speed | Contents |
|---|---|---|
| `sky-{day,gold,dusk}` | 0× | gradient, sun/moon, self-tinted clouds, stars |
| `far-{…}` | 0.3× | two mountain ranges with snow caps, haze band, far hills |
| `mid-{…}` | 0.6× | hills, windmill (x 300), castle (x 820), old keep (x 1460), tree clusters — tinted ink |
| `near-{…}` | 1× | ground with scalloped grass lip, path, fence, oaks, pines, flowers, signpost (x 1300), torches (x 2000, 2250) — black ink |

Characters are **not** baked into the near layer any more (v1 baked the knight and dragon in). Knight stands at near x ≈ 1262, dragon at ≈ 2212, both at the ground line `y = 448 − 10·sin(x/190) − 6·sin(x/63 + 1)`.

At dusk, characters get a light grade (`brightness 0.8, saturation 0.92`) plus an additive warm glow sprite near the torches.

## 7. Regenerating

```
cd Design/ink/generator
python3 build.py        # writes ../sprites/*.svg and ../world/*.svg
```

Then `scripts/render-assets.sh` as today. Palettes live in `props.py → TOD`; character colours at the top of each character file.

## 8. Next, in order

1. Bundle and register the fonts (one small PR — fixes every screen at once).
2. `DesignSystem`: add `Ink` tokens + `Bevel` modifier; restyle WordCard, MicPill, ProgressRail, StarChip, buttons.
3. `World`: swap the six v1 layers for the twelve v2 layers; crossfade layers on stage change like the sky.
4. `FoxNode`: replace CoreGraphics part drawing with atlas textures; keep the gait code.
5. Knight and dragon as actor nodes on `actorLayer`, with their idle loops.
6. Home screen: scene header, framed story tiles, teal TV button.
