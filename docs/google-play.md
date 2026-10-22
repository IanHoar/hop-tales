# Google Play

Getting the Android app onto Google Play, and where it stands. Signing and releasing from CI are
done on the repository side; what is left happens in Play Console and Google Cloud.

## Status

- [x] Play developer account created, under Superbrands Apps.
- [x] Upload key generated: `~/keys/hoptales-upload.jks`, alias `upload`. It is not in the repo.
- [x] Release builds sign with it (`android/app/build.gradle.kts`, `signingConfigs.release`).
- [x] A signed `app-release.aab` builds locally.
- [x] Play Console account verification.
- [x] Create the app and make the first upload to Internal testing, by hand (version code 1).
- [ ] Release from CI: the workflow is in place; the service account and secrets are not
  ([Releasing from CI](#releasing-from-ci)).
- [ ] Finish the app content forms.
- [ ] Closed testing, then production.

## The upload key

The keystore and its password are the one thing that can't be recreated. Keep a copy of
`hoptales-upload.jks` and its password outside this machine, in a password manager for example. If
the key is lost, Google can reset the upload key through Play support, but releases stop until it
does.

Gradle reads the key from `~/.gradle/gradle.properties`, which is outside the repo:

```properties
HOPTALES_UPLOAD_STORE=/Users/ianhoar/keys/hoptales-upload.jks
HOPTALES_UPLOAD_ALIAS=upload
HOPTALES_UPLOAD_PASSWORD=…
```

Without those properties, debug builds and CI work as before. Only the release packaging tasks need
the key. `*.jks` and `*.keystore` are gitignored.

## Building a release

From `android/`:

```sh
./gradlew :app:installRelease   # optional: try the minified build on a device first
./gradlew :app:bundleRelease    # → app/build/outputs/bundle/release/app-release.aab
```

Build from this repository, not the old `ReadingApp-android` checkout, which predates the signing
setup.

Without a release tag the build is version code 1, `0.1.0`, which Play has already seen. Pass the
tag to build what CI would:

```sh
./gradlew :app:bundleRelease -PreleaseTag=android/v1.0.0-1   # version code 1000001, 1.0.0
```

[Releasing from CI](#releasing-from-ci) explains the numbers. Releases normally go through CI.

## The looks pack

The dressed-friend sheets (`look-*`) are most of the app's size, so a release bundle carries them in
a **fast-follow** asset pack, `looks` (`android/looks`), and Play downloads it straight after the
app installs. Each friend's starting look (`hoptales.baseLooks` in `android/gradle.properties`)
stays in the base, so the intro and every friend's first outfit are there from the first launch.
Until the pack lands, a look it holds shows the friend in their base sheet; it appears without a
restart once Play delivers the pack. The app makes no network call of its own: Play does the
download, through Google's asset-delivery library. Debug builds, `installDebug` and the tests keep
every sheet in the app. Both sets are copied from `ios/…/World/Resources` at build time.

Try the delivery locally with [bundletool](https://github.com/google/bundletool) before a release:

```sh
./gradlew :app:bundleRelease
bundletool build-apks --bundle=app/build/outputs/bundle/release/app-release.aab \
  --output=hoptales.apks --local-testing
bundletool install-apks --apks=hoptales.apks    # the pack arrives as it would from Play
bundletool get-size total --apks=hoptales.apks  # the first download, without the pack
```

`--local-testing` installs the pack from the device's own storage, so the wardrobe can be checked
without Play. `./gradlew :app:installRelease` installs the base alone, with no pack.

## First upload

1. Play Console → **Create app**: Hop Tales, App, Free. The package name comes from the first bundle
   (`com.hoptales.android`) and can never change.
2. **Test and release → Testing → Internal testing → Create new release.**
3. App signing: **Use Google-generated key** (Play App Signing). Google holds the key users' devices
   check; `hoptales-upload.jks` is only the upload key.
4. Upload `app-release.aab` and add release notes.
5. **Testers**: create an email list with your own account, then **Start rollout to Internal
   testing**. Install from the opt-in link on a phone. Internal builds skip full review.

## App content

Play asks for these under **Dashboard → Set up your app** before closed testing or production. The
app is for children, so they need care:

- **Target audience**: children. The app falls under the Families policy: no ads or analytics SDKs,
  and purchases behind a parental gate.
- **Data safety**: nothing is collected or shared. Speech is recognised on the device. The optional
  Google account backup holds the reader's name and progress, is off until a grown-up turns it on,
  and only the family can see it.
- **Foreground service permissions**: Google's asset-delivery library declares a `dataSync`
  foreground service, which unpacks the looks pack. Declare it as downloading app content.
- **Privacy policy URL**, **content rating** (the IARC questionnaire), **ads: none**, **app access:
  no login needed**.
- **Store listing**: a short and full description, a 512×512 icon, a 1024×500 feature graphic, and
  phone, 7-inch and 10-inch tablet screenshots ([store-screenshots.md](store-screenshots.md) covers
  the iOS set).

## Closed testing and production

A personal developer account created since November 2023 must run a closed test with at least 12
testers for 14 days in a row before it can apply for production. An organisation account skips
this. Check which kind the Superbrands Apps account is under **Settings → Developer account**.

Once the app is live, link it from the website (#290).

## Releasing from CI

Publishing a GitHub release with an Android tag builds, signs and uploads the app to **Internal
testing**, as an iOS tag puts the iOS app on TestFlight through Xcode Cloud
([xcode-cloud.md](xcode-cloud.md), step 5). Each app releases from its own tag prefix:

```sh
gh release create android/v1.0.0-1 --generate-notes   # Android, to Play's internal testing
gh release create ios/v1.0.1-1 --generate-notes       # iOS, to TestFlight
```

`--generate-notes` lists the changes since the latest release of either app. Add
`--notes-start-tag android/v…`, naming the previous Android tag, to list only what changed since
then.

`.github/workflows/release-android.yml` runs on every published release and skips quietly unless
the tag starts with `android/v`. It checks the tag's shape, builds `:app:bundleRelease`, keeps the
`.aab` as the run's `app-release-bundle` artifact, and uploads it with `:app:publishReleaseBundle`
from the [Gradle Play Publisher](https://github.com/Triple-T/gradle-play-publisher) plugin, as a
completed release on the internal track. The release's description, cut to Play's 500 characters,
becomes the en-US release notes; the workflow writes it to
`android/app/src/main/play/release-notes/en-US/default.txt`, which is gitignored. Promotion to
closed testing and production stays a manual step in Play Console.

To run a release again, for example after fixing a secret: Actions → Release Android → Run
workflow, with the tag. Play rejects a version code it has already seen, so a release that reached
Play needs a new tag instead.

The plugin is build tooling. It runs on the build machine and never ships in the app, so the
no-third-parties rule is untouched. Without credentials it does nothing: local builds and the pull
request workflow don't need any.

### Version codes

The tag is `android/v<major>.<minor>.<patch>-<build>`. `versionName` is the dotted half, and
`versionCode` packs all four numbers:

```
versionCode = major × 1,000,000 + minor × 10,000 + patch × 100 + build

android/v1.0.0-1   →  1000001, "1.0.0"
android/v1.2.3-4   →  1020304, "1.2.3"
```

Play only accepts a version code higher than any it has seen, so bump the build for every upload
of the same version and reset it when the version moves. Minor, patch and build get two digits
each; a tag with any of them at 100 or more fails the build rather than overlapping the next slot.
The first upload, made by hand, used version code 1, and every tag clears it.

Pass `-PreleaseTag=…` to Gradle to build the same numbers locally. Without it the build stays at
version code 1, `0.1.0`.

### One-time setup

1. **Service account.** In [Google Cloud Console](https://console.cloud.google.com), pick or create
   a project, then **APIs & Services → Library → Google Play Android Developer API → Enable**.
   Under **IAM & Admin → Service accounts → Create service account**, name it (`hoptales-release`,
   say) and skip the optional roles. Open it, **Keys → Add key → Create new key → JSON**, and keep
   the downloaded file out of the repository.
2. **Play permission.** In Play Console → **Users and permissions → Invite new users**, enter the
   service account's email. Under **App permissions**, add Hop Tales with **Release apps to testing
   tracks** and **View app information**. Leave account permissions empty, then **Invite user**.
   It can take a few hours before the API accepts the new account.
3. **Secrets.** From the repository:

   ```sh
   base64 -i ~/keys/hoptales-upload.jks | gh secret set ANDROID_UPLOAD_KEYSTORE
   gh secret set ANDROID_UPLOAD_PASSWORD                  # prompts; the keystore password
   gh secret set ANDROID_UPLOAD_ALIAS --body upload
   gh secret set PLAY_SERVICE_ACCOUNT_JSON < ~/Downloads/hoptales-release-….json
   ```

   Then delete the downloaded JSON key, or move it to the password manager beside the keystore.

If any secret is missing, the workflow stops before building and names it. The secrets reach only
the release job's own steps; GitHub masks them in the log, and the decoded keystore and key file
live in the runner's temporary directory and are deleted when the job ends.

If the upload fails with "Only releases with status draft may be created on draft app", the app
has never had a release rolled out. Roll out the hand-made first release on Internal testing in Play
Console, then run the workflow again.
