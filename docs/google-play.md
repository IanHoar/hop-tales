# Google Play

Getting the Android app onto Google Play, and where it stands. The repository side of signing is
done; what is left happens in Play Console and Google Cloud.

## Status

- [x] Play developer account created, under Superbrands Apps.
- [x] Upload key generated: `~/keys/hoptales-upload.jks`, alias `upload`. It is not in the repo.
- [x] Release builds sign with it (`android/app/build.gradle.kts`, `signingConfigs.release`).
- [x] A signed `app-release.aab` builds locally.
- [ ] Play Console account verification. **This is where it stopped.**
- [ ] Create the app and make the first upload to Internal testing.
- [ ] Finish the app content forms.
- [ ] Closed testing, then production.
- [ ] Release from CI.

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

Raise `versionCode` in `android/app/build.gradle.kts` for every upload (1, 2, 3 …). Play rejects a
repeated one. `versionName` is what people see.

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

## Releasing from CI (later)

After the first manual upload, a GitHub Actions workflow can build, sign and upload to Internal
testing, as Xcode Cloud does for TestFlight:

1. In Google Cloud, create a service account and download its JSON key. In Play Console → **Users
   and permissions**, invite its email with release permissions for Hop Tales.
2. Add the secrets:

   ```sh
   base64 -i ~/keys/hoptales-upload.jks | gh secret set ANDROID_UPLOAD_KEYSTORE
   gh secret set ANDROID_UPLOAD_PASSWORD
   gh secret set ANDROID_UPLOAD_ALIAS --body upload
   gh secret set PLAY_SERVICE_ACCOUNT_JSON < service-account.json
   ```

3. Add the Gradle Play Publisher plugin and a workflow that runs on a tag or by hand. It decodes the
   keystore, sets `versionCode` from the run number and publishes the bundle to the internal track.
   Promotion to closed testing and production stays a manual step in Play Console.
