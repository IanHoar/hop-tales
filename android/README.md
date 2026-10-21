# Hop Tales for Android

Kotlin and Jetpack Compose, built with Gradle. Open this folder (`android/`), not the repository
root, in Android Studio.

## Getting started

Needs JDK 17 or later (Android Studio's bundled JBR works) and the Android SDK with platform 37.

```sh
cd android
./gradlew test                         # JVM tests: content, matching, reading, and the screenshots
./gradlew ktlintCheck                  # lint every Kotlin file; ktlintFormat fixes most of it
./gradlew :app:verifyRoborazziDebug    # compare the screenshots with the committed references
./gradlew :app:recordRoborazziDebug    # re-record the references after a deliberate UI change
./gradlew :app:installDebug            # build and install on a running emulator or device
```

`local.properties` (ignored) holds `sdk.dir`; Android Studio writes it for you.

Speech recognition is on-device only — `SpeechRecognizer.createOnDeviceSpeechRecognizer`, never the
network recogniser — so the app needs Android 12 (API 31) or later. Where the device has no on-device
model, or the microphone was turned off, a panel says so and leads back to the stories, as on iOS. Debug builds show a "Hear …"
button that stands in for a recognised word, like the DEBUG controls on iOS.

## Style

ktlint is the house style, configured in `android/.editorconfig` (IntelliJ IDEA style, trailing
commas allowed, lines up to 140). The `pre-commit` hook lints staged `android/**/*.kt` and `.kts`
files the way it runs SwiftLint on Swift, so install the CLI once:

```sh
brew install ktlint
./gradlew ktlintFormat && git add -u    # fixes most of what the hook reports
```

Without the CLI the hook warns and lets the commit through; CI runs `./gradlew ktlintCheck` either
way. Change `.editorconfig` rather than suppressing a rule in the code.

## Screenshot tests

`ScreenshotTest` renders home, reading, the microphone ask, the microphone off, a story prop, a companion, a thought
bubble, the story-finished chips, the stop card, each onboarding step and the grown-ups settings,
light and dark, with Roborazzi on Robolectric — on the JVM, no emulator. The references live in
`app/src/test/screenshots`; `verifyRoborazziDebug` fails when a render differs, and leaves the
actual image and a diff in `app/build/outputs/roborazzi`. After a deliberate change, record again
and commit the new PNGs with the change. Motion is frozen (the animator scale is set to 0), so the
hare stands still and the camera snaps.

## Layout

```
app/            the Compose app: MainActivity, Onboarding, Home, Reading, Settings, design tokens, speech, persistence
core/content    Story, Sentence, Word, Friend, Progress, StoryLibrary — pure Kotlin
core/speech     WordMatcher and PartialDebouncer — pure Kotlin, ported from SpeechRecognition
core/reading    the reading state machine (Reading, ReadingState) — pure Kotlin
core/onboarding the onboarding step flow (Onboarding, OnboardingState) — pure Kotlin
```

The `core` modules are plain JVM modules so their tests run without an emulator. They are ports of
the Swift modules of the same names, and their tests are ports of the Swift tests: when the Swift
rules change, change both. `WordMatcherTest` mirrors `WordMatcherTests` case for case.

## Profile and settings

The first launch walks the grown-up through onboarding: the child's name, the microphone (explained
before Android's prompt, which is asked for there and never on a story start again), the starting
friend and sound buttons. There is no iCloud step. Answers are kept in `profile-draft.json` as they
are given, so a closed app resumes where it left off, and the finished `Profile` is `profile.json`
in `filesDir`, beside `progress.json`. The accent picks the recogniser and help-voice locale; the
help voice is one of the engine's offline English voices, never a network one. Matching strictness,
sound effects and whether the microphone was asked live in the `settings` shared preferences.

The gear on Home opens Settings directly: there is nothing in it that costs money or leaves the app,
so no parent gate yet (`docs/HANDOFF.md` §1.6).

## Shared content

The app does not copy any content or art. Its assets come straight from the iOS package:

| Assets from | What |
|---|---|
| `ios/HopTalesPackage/Sources/Content/Resources` | `stories.json`, `props.json`, `phonics.json`, … |
| `ios/HopTalesPackage/Sources/World/Resources` | the world layers, characters and props (WebP, PNG) |
| `ios/HopTalesPackage/Sources/DesignSystem/Resources` | `Fonts/` — Young Serif, Fraunces, Fredoka |

The launcher icon is the one exception: `scripts/render-android-icon.py` renders the adaptive icon's
foreground, background and monochrome layers from `ios/HopTales/AppIcon.icon` into `res/mipmap-*`,
and they are committed. Re-run it when the iOS icon changes.

`app/build.gradle.kts` adds those folders as asset directories, and the JVM tests read `stories.json`
from the same place, so a story added through `scripts/build-stories.py` reaches both apps.

Art that Android does not draw yet is left out of the package by `ignoreAssetsPatterns` in
`app/build.gradle.kts` — the wardrobe (`look-*`, `wear-*`), postcards and the land's `prop-*`
scenery other than the signpost. The story props, companions and thought bubbles draw from `cast-*`,
so that ships. When a
feature starts drawing one of those families, take its pattern off the list, or `Art.image` quietly
returns null. WebP and PNG are stored as they are, since deflating them saves well under 2%; JSON,
fonts and text are compressed.

## Release

Play gets an App Bundle, not an APK:

```sh
./gradlew :app:bundleRelease    # app/build/outputs/bundle/release/app-release.aab, R8-minified
```

It is unsigned; sign it with the upload key when it goes to Play.

## Privacy

Same rules as iOS: on-device recognition only, nothing recorded or sent, no analytics, no third-party
SDKs. Auto Backup is off and the data extraction rules exclude everything from cloud backup until the
grown-up opt-in exists on Android; a device-to-device transfer still carries progress.
