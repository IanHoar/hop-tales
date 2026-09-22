# Wordhop

iOS read-aloud game for early readers. SwiftUI shell + SpriteKit world, on-device `SFSpeechRecognizer`, AirPlay second screen. Read `docs/HANDOFF.md` before touching anything — it has the product rules, tokens, layout numbers, parallax maths, speech-matching rules and milestone order.

## Ground rules

- The word card, ball, mic pill and progress rail never move between stages. Only the SpriteKit world changes.
- Text lives in SwiftUI (Andika for words, Fredoka for UI). Do not render the reading surface in SpriteKit.
- Speech is on-device only (`requiresOnDeviceRecognition = true`). No audio is stored. No network calls anywhere.
- Matching is forgiving by default (`docs/HANDOFF.md §5`). Never show a failure state to the child.
- Design source of truth is `Design/world/*.svg` (2340×844 world) and `Design/artboards/*.dc.html`. Rasterise at build time; don't hand-edit PNGs.
- Milestone 1 (reading loop on a flat background) ships before any world art is wired up.

## Layout

- `Wordhop/` — thin app target: `@main` entry point, `Info.plist`, asset catalog. No feature code.
- `WordhopPackage/` — all the code, as SPM modules: `AppFeature` (root + navigation), `Content`
  (models + bundled `stories.json`), `DesignSystem` (tokens), `Home`, `Reading`,
  `SpeechRecognition` (`SpeechClient`, `WordMatcher`), `World` (SpriteKit).
- `Design/` — handoff assets (not compiled; scripts read from here).
- `docs/HANDOFF.md` — the spec. `project.yml` — XcodeGen spec; run `xcodegen generate` after
  adding files or targets, and commit the regenerated `Wordhop.xcodeproj`.
- `scripts/render-assets.sh` — SVG → @2x/@3x PNG into the asset catalog. Run it manually; it needs
  `rsvg-convert` (`brew install librsvg`).

## Architecture

- State is ComposableArchitecture2 ("TCA26", private `pointfreeco/TCA26`, pinned to `main`).
  Features are `@Feature` types with `Update`/`onMount`; views are logicless and read from `store`.
- TCA26's current API takes a single scope key path — `Scope(\.home)`, `store.scope(\.home)`,
  `.forEach(\.path, dismissStyle: .stack)`. The `action:` label in older Point-Free docs and in
  the `pfw-composable-architecture-2` skill is the deprecated 1.x form.
- Dependencies are declared with the key type, `@Dependency(SpeechClient.self)`, not a
  `DependencyValues` key path — the key path form does not type-check inside `@Feature`.
- A feature used from another module needs `public` on the type, `State`, `Action`, `body`, and an
  explicit `public init()`.
- `@Feature` types are `@MainActor`, so tests use `TestStore` in a `@MainActor` suite, not
  `TestStoreActor`. End a test that mounted a listening feature with `await store.dismount()`, or it
  fails with "an effect for this event is still running".
- `send`'s trailing closure asserts against `State.DebugSnapshot`, whose initializer is internal —
  asserting a child's state from another module's tests needs `@testable import` of that module.
- Feature-scoped mutable state that is not view state goes in `@FeatureState` on the feature (the
  `@FeatureLocal` in older docs does not exist here). Keeping it out of `State` also keeps it out of
  every test assertion.

## Commands

- Open `Wordhop.xcworkspace`, not the `.xcodeproj` — the local package lives in the workspace.
- Build: `xcodebuild -workspace Wordhop.xcworkspace -scheme Wordhop -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -skipMacroValidation build`
- Tests: same command with `test` — the `Wordhop` scheme runs all three package test targets.
  `WordMatcherTests` must stay green; they encode the tolerance rules.
- `-skipMacroValidation` is required from the CLI: the package macros need one-time approval that
  only the Xcode UI can give.
- Speech recognition does not run in the simulator. Test the reading loop on a device.
- Deployment target is iOS 27; the app is iPhone + iPad (`TARGETED_DEVICE_FAMILY = 1,2`).
