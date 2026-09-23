# App Store privacy and age rating

What to enter in App Store Connect for Hop Tales, and why each answer is true. If the app starts
collecting anything, update `HopTales/PrivacyInfo.xcprivacy` and this page in the same change.

## App Privacy ("nutrition label")

**Data collection: "No, we do not collect data from this app."**

- Speech recognition runs on the device (`requiresOnDeviceRecognition = true`). Audio never leaves the
  phone and is never stored.
- The child's name, accent, help voice, settings and reading progress are saved only on the
  device, in Application Support and `UserDefaults`.
- There are no network calls, analytics, crash reporters, advertising or third-party SDKs that phone
  home.
- Apple's definition of "collect" is data sent off the device, so nothing here counts.

**Tracking: none.** `NSPrivacyTracking` is `false`, with no tracking domains.

## Privacy manifest (`HopTales/PrivacyInfo.xcprivacy`)

| Required-reason API | Where | Reason |
|---|---|---|
| `UserDefaults` | `StrictnessPreference`, `SoundPreference` | `CA92.1`: the app's own settings |
| System boot time | `ContinuousClock`, for the silence timer and the recogniser's settle timer | `35F9.1`: elapsed time between events in the app |

No file-timestamp or disk-space APIs are used. The dependencies ship their own manifests where they
need one (`swift-sharing`).

## Age rating and category

- **Category:** Education, with the Kids Category. The age band is **Ages 6–8**, the early-reader
  range the stories are written for. Ages 5 and under also fits if the stories are aimed younger.
- **Age rating questionnaire:** every content question is "None". There is no unrestricted web access
  and no user-generated content, so the rating is **4+**.
- **Kids Category rules (guideline 1.3):**
  - no third-party analytics or advertising
  - no links out of the app, purchases or other distractions except behind a parental gate
  - a privacy policy is required
  - Today there are no links or purchases, so there is no gate (`docs/HANDOFF.md` rule 6).

## Still needed before submission

- **Privacy policy URL.** Required for every app, and for the Kids Category in particular. It goes
  on hoptales.com, tracked in #44. Who writes it is still open; the answers above are the substance.
- **Microphone and speech-recognition purpose strings** are already in `Info.plist`. Check the
  wording again against the final onboarding copy.
