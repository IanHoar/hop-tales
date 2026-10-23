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
network recogniser — so the app needs Android 12 (API 31) or later. Listening uses the on-device model for the
chosen accent; where that one isn't installed it borrows another installed English model (American
first, then any English), checked with `checkRecognitionSupport` on Android 13 and later (Android 12
can only ask whether any on-device model exists, and if the check fails or takes over 2 s the accent's
own model is assumed). Where there is no English on-device model at all, or the microphone was turned
off, a panel says so and leads back to the stories, as on iOS. As on iOS, a partial result that holds for 250 ms counts, a recogniser error waits
1 s before listening again, losing audio focus restarts listening, and the focus is held for 3 s between
sentences. The hint voice, unless a grown-up picked one, is the best offline voice for the accent. Debug builds show the DEBUG controls of iOS:
"Read …" stands in for a recognised word, "Rest of sentence" reads to the end of the sentence, and
a tap on the meadow moves on one word.

As on iOS, a grown-up can turn on a speech log in Settings: one line per thing the recogniser hears
(words only, never audio), with the room's noise floor sampled every 0.5 s as iOS's `NoiseMeter` does
it (the quietest tenth of the last 3 s, in 0.1 s blocks — on Android's `rmsdB` scale, so the numbers
are not the iOS dBFS ones), kept in memory until the app closes, capped at 5,000 lines, and exported
through the share sheet as a CSV in plain text. It never leaves the device unless the grown-up shares it.

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

`ScreenshotTest` renders the intro at night, mid-sunrise and with its title, home (first run and
midway), reading, each of the six meadow moods, each friend's world, sound-button marks, the microphone ask, the microphone off, a story prop, a
companion, a thought bubble, a big word, the challenge-word tip, the story-finished panel with its
tally, a full basket, the "Done" card after trying the present on, a new friend, the stop card,
the journey map, friends, the wardrobe, the collection book, home with locked Plus stories and with locked levels, the "You finished Level 1!" card, the locked story
card, the parent gate (and a redrawn question), each onboarding step and the grown-ups settings, light and dark (and the settings in a chosen Dark theme on a light device), with Roborazzi on Robolectric — on the JVM, no emulator. The references
live in
`app/src/test/screenshots`; `verifyRoborazziDebug` fails when a render differs, and leaves the
actual image and a diff in `app/build/outputs/roborazzi`. After a deliberate change, record again
and commit the new PNGs with the change. Motion is frozen (the animator scale is set to 0), so the
hare stands still and the camera snaps.

`LargeScreenshotTest` shoots the same screens on a tablet in portrait and landscape, on a
foldable's outer and inner screens, and half open as a book and on a tabletop, with a fake
`FoldingFeature` published through `WindowLayoutInfoPublisherRule`. Those references live in
`app/src/test/screenshots/large`.

`FontScaleScreenshotTest` shoots home (and a long name that shrinks to fit), the onboarding name step, settings and the story-finished panel
at font scale 2.0, into `app/src/test/screenshots/font-scale`.

## Accessibility

As on iOS, Fredoka UI text (`Typography.ui`) follows the system font size, while the words on the
path, Fraunces titles and caps labels stay at their design size. A one-line title too long for its
space shrinks to fit (`FitText`, iOS's `minimumScaleFactor`) rather than being cut off, and the onboarding
answer pairs stack when they don't fit side by side. "Remove animations" (animator
duration scale 0) is read as Reduce Motion, and followed live while the app runs: the idle friend
stands still, the clouds stop drifting, each word step crossfades over 0.2 s instead of panning, and
props hold their layout. `AccessibilityTest` checks the TalkBack labels, headings and actions
screen by screen, and `ContrastTest` holds the dark palettes to WCAG AA.

## Tablets and foldables

`Metrics.forScreen` picks the reading layout as iOS does: the iPad numbers when the window is at
least 600 × 480 dp, the iPhone Duo's on a squat compact window, the phone's otherwise. `FoldAware`
reads the hinge from Jetpack WindowManager. While a foldable is half open, onboarding keeps its sheet
below a fold that runs across and beside one that runs down, with the hare in the other half, and
Home moves its column after a book fold with the friend before it. Phones stay upright, as the
iPhone does; screens 600 dp and wider rotate freely.

## Layout

```
app/            the Compose app: MainActivity, Intro, Onboarding, Home, Reading, Settings, design tokens, speech, persistence
core/content    Story, Sentence, Word, Friend, Progress, StoryLibrary — pure Kotlin
core/speech     WordMatcher, PartialDebouncer, SettledPartial, VoiceChoice — pure Kotlin, ported from SpeechRecognition
core/reading    the reading state machine (Reading, ReadingState) — pure Kotlin
core/onboarding the onboarding step flow (Onboarding, OnboardingState) — pure Kotlin
```

The `core` modules are plain JVM modules so their tests run without an emulator. They are ports of
the Swift modules of the same names, and their tests are ports of the Swift tests: when the Swift
rules change, change both. `WordMatcherTest` mirrors `WordMatcherTests` case for case.

## Profile and settings

The first launch walks the grown-up through onboarding: Google backup (the Android counterpart of
the iCloud step), the child's name, the microphone (explained before Android's prompt, which is
asked for there and never on a story start again), what's ahead (the first three friends, with Bob
as where every reader starts; nothing to pick) and sound buttons. Answers
are kept in `profile-draft.json` as they are given, so a closed app resumes where it left off.

Progress and the finished `Profile` live in SQLite, `databases/hoptales.db`, through the platform's
`SQLiteOpenHelper` (no extra library; its version number carries the migrations). The tables and
columns are the iOS ones from `Content/Database.swift` — `profiles`, `progress`, `storyProgress` —
and `HopTalesDatabaseTest` builds the iOS statements next to ours and compares them column for
column, so a change on one side fails until the other follows. Never drop or rename a table or
column. The JSON columns are written the way Swift's `JSONEncoder` writes them (a dictionary keyed
by an enum is a flat `[key, value, …]` array). Only `STRICT` is left off, since Android 12's SQLite
predates it. `profiles.theme` holds the Theme setting (Match device, Light or Dark) with the iOS raw values `device`, `light` and `dark`, and the whole app follows it. The first launch after
the update imports `progress.json` and `profile.json` and deletes them once the import has
committed; a file that cannot be read stays where it is. The accent picks the recogniser and help-voice locale; the
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
`app/build.gradle.kts` — the `postcard-*` art. The
story props, companions and thought bubbles draw from `cast-*`, and the wardrobe from `look-*`
(dressed stickers and sprite sheets), `wear-*` (the items), `looks.json` and `wardrobe.json`, so
those ship. When a
feature starts drawing one of those families, take its pattern off the list, or `Art.image` quietly
returns null. WebP and PNG are stored as they are, since deflating them saves well under 2%; JSON,
fonts and text are compressed.

## Release

Play gets an App Bundle, not an APK:

```sh
./gradlew :app:bundleRelease    # app/build/outputs/bundle/release/app-release.aab, R8-minified
```

It is unsigned; sign it with the upload key when it goes to Play.

The dressed-friend sheets go in the `looks` fast-follow asset pack rather than the base;
[docs/google-play.md](../docs/google-play.md#the-looks-pack) covers it and how to test it locally.

## Privacy

Same rules as iOS: on-device recognition only, nothing recorded or sent, no analytics, no third-party
SDKs. The only copy that can leave the device is Android's own backup into the family's Google
account, and only after a grown-up opts in, in onboarding or in Settings.

`HopTalesBackupAgent` decides each backup pass (`BackupPlan`):

- Opted in: the database and the `backup` preferences file, per `data_extraction_rules.xml`.
- Never opted in: nothing. Android declines an empty backup, so no copy is made.
- Opted in, then out: only the `backup` preferences file, which says "off". That replaces the
  earlier copy, so the name and progress drop out of the Google account at the next pass.
- Device-to-device transfer (setting up a new phone from the old one, cable or Wi-Fi): the database
  and the choice, whatever the choice is, as before.

On a new device, Android restores the backup when the app is installed, before it first opens, so
the reader lands on Home with their name and progress; the microphone is asked for on the first
story. What Android does not let us promise: when backups run (about once a day, idle, charging
and on Wi-Fi), that the grown-up has backup turned on in Android's own settings, or when an old copy
is removed if the device never backs up again. `adb shell bmgr backupnow com.hoptales.android`
forces a pass for testing.
