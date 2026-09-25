# Hop Tales

An iOS read-aloud game for early readers. A large word sits in the middle of the screen with a
bouncing ball on top. When the child says the word, the ball hops to the next one, the finished
word shrinks into an amber pill, and the world behind the card scrolls forward — meadow, to castle
road, to a dragon's hill at dusk.

iPhone first, iPad landscape, and an Apple TV over AirPlay as a passive second screen.

- **Product spec:** [`docs/HANDOFF.md`](docs/HANDOFF.md) — product rules, design tokens, layout
  numbers, parallax maths, speech-matching rules, milestone order.
- **Working agreements:** [`CLAUDE.md`](CLAUDE.md)
- **Design source:** `Design/world/*.svg` (2340×844 world) and `Design/artboards/*.dc.html`.

Everything runs on device. Speech recognition is on-device only, no audio is stored, and the app
makes no network calls.

## Getting started

Requires Xcode 27 (iOS 27 SDK) and access to the private `pointfreeco/TCA26` package. The app runs on
iOS 26 and later.

```sh
open HopTales.xcworkspace          # not the .xcodeproj — the local package is in the workspace
```

The first build asks you to trust the package macros (`@Feature`, `@CasePathable`). From the
command line pass `-skipMacroValidation` instead.

```sh
# Build
xcodebuild -workspace HopTales.xcworkspace -scheme HopTales \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -skipMacroValidation build

# Tests (one scheme per package test target)
xcodebuild test -workspace HopTales.xcworkspace -scheme SpeechTests \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -skipMacroValidation
```

Speech recognition does not run in the simulator — test the reading loop on a device.

## Layout

```
HopTales/                  app target: @main entry point, Info.plist, asset catalog
HopTalesPackage/           all the code, as SPM modules
  Sources/
    AppFeature/           Root feature + RootView (navigation)
    Content/              Story/Sentence/Word/Progress models, bundled stories.json
    DesignSystem/         Palette, Typography, Metrics, Motion — the tokens from the handoff
    Home/                 story select
    Reading/              the reading loop
    SpeechRecognition/    SpeechClient, WordMatcher, PartialDebouncer
    World/                SpriteKit parallax world
  Tests/
Design/                   handoff assets (not compiled; scripts read from here)
docs/HANDOFF.md           the spec
project.yml               XcodeGen spec — regenerate with `xcodegen generate`
scripts/render-assets.sh  SVG → @2x/@3x PNG into the asset catalog
```

State is [ComposableArchitecture2 (TCA26)](https://github.com/pointfreeco/TCA26).

CI is Xcode Cloud — see [`docs/xcode-cloud.md`](docs/xcode-cloud.md).
