# Hop Tales for Android

Kotlin and Jetpack Compose, built with Gradle. Open this folder (`android/`), not the repository
root, in Android Studio.

## Getting started

Needs JDK 17 or later (Android Studio's bundled JBR works) and the Android SDK with platform 37.

```sh
cd android
./gradlew test                 # JVM tests for the shared logic: content, matching, reading
./gradlew :app:installDebug    # build and install on a running emulator or device
```

`local.properties` (ignored) holds `sdk.dir`; Android Studio writes it for you.

Speech recognition is on-device only — `SpeechRecognizer.createOnDeviceSpeechRecognizer`, never the
network recogniser — so the app needs Android 12 (API 31) or later. Where the device has no on-device
model, the mic pill says so and tapping the word still speaks it. Debug builds show a "Hear …"
button that stands in for a recognised word, like the DEBUG controls on iOS.

## Layout

```
app/            the Compose app: MainActivity, Home, Reading, design tokens, speech, persistence
core/content    Story, Sentence, Word, Friend, Progress, StoryLibrary — pure Kotlin
core/speech     WordMatcher and PartialDebouncer — pure Kotlin, ported from SpeechRecognition
core/reading    the reading state machine (Reading, ReadingState) — pure Kotlin
```

The `core` modules are plain JVM modules so their tests run without an emulator. They are ports of
the Swift modules of the same names, and their tests are ports of the Swift tests: when the Swift
rules change, change both. `WordMatcherTest` mirrors `WordMatcherTests` case for case.

## Shared content

The app does not copy any content or art. Its assets come straight from the iOS package:

| Assets from | What |
|---|---|
| `ios/HopTalesPackage/Sources/Content/Resources` | `stories.json`, `props.json`, `phonics.json`, … |
| `ios/HopTalesPackage/Sources/World/Resources` | the world layers, characters and props (WebP, PNG) |
| `ios/HopTalesPackage/Sources/DesignSystem/Resources` | `Fonts/` — Young Serif, Fraunces, Fredoka |

`app/build.gradle.kts` adds those folders as asset directories, and the JVM tests read `stories.json`
from the same place, so a story added through `scripts/build-stories.py` reaches both apps.

## Privacy

Same rules as iOS: on-device recognition only, nothing recorded or sent, no analytics, no third-party
SDKs. Auto Backup is off and the data extraction rules exclude everything from cloud backup until the
grown-up opt-in exists on Android; a device-to-device transfer still carries progress.
