# App Store screenshots

Six framed panels for each device: a headline and subline, a real app screen in a device frame, and a
friend or two stepping in front of it. There are three steps: render the screens, frame them, and
upload them. Nothing is committed from `build/store-screenshots/`, and the pipeline rebuilds it
in about a minute.

| Device | App Store slot | Screen rendered at | Panel size |
|---|---|---|---|
| iPhone | 6.9″ (`APP_IPHONE_67`) | 440 × 956 pt @3x | 1320 × 2868 |
| iPad | 13″ (`APP_IPAD_PRO_3GEN_129`) | 1032 × 1376 pt | 2064 × 2752 |

Apple scales the 6.9″ and 13″ sets down for smaller devices, so no other sizes are needed.

## 1. Render the screens

`StoreScreenshotTests` (in `SnapshotTests`) renders each screen through its preview. It only runs
when `STORE_SCREENSHOTS=1`, so it stays out of CI and the normal test run:

```sh
TEST_RUNNER_STORE_SCREENSHOTS=1 xcodebuild -workspace ios/HopTales.xcworkspace -scheme HopTales \
  -destination 'platform=iOS Simulator,name=iPhone 18 Pro' -skipMacroValidation \
  -only-testing:SnapshotTests/StoreScreenshotTests test
```

The PNGs land in `build/store-screenshots/raw/`. Two things are set for every render:
- `freezesMotion`, so the world renders as a still image.
- `hidesDebugControls`, so the DEBUG-only "Read word" buttons stay out of the shot.

To show a different moment, edit `stories`: each entry is `story id|sentence|word`. Check the
result before using it. The seaside far hills have a visible join at most camera positions, but
`barnacle-shells|0|1`, the opening signpost, is clean.

## 2. Frame them

```sh
python3 -m pip install -r scripts/store-screenshots/requirements.txt
python3 scripts/store-screenshots/compose.py
```

This writes `build/store-screenshots/out/{phone,pad}-<n>-<screen>.png`. The `PANELS` table at the
top of `compose.py` holds the order, headlines, background colours and stickers. Every device sits
at the same height, set by the tallest headline.

## 3. Upload

This needs an App Store Connect API key with the App Manager role. Put the `.p8` file in
`~/.appstoreconnect/private_keys/`, then:

```sh
export ASC_KEY_ID=… ASC_ISSUER_ID=…
python3 scripts/store-screenshots/upload.py        # the version in Prepare for Submission
python3 scripts/store-screenshots/upload.py 1.1    # or a named version
```

The script deletes the existing 6.9″ and 13″ screenshots for the primary locale, then uploads the
new ones in file-name order.

## Google Play

The play set frames the Android app's screens at 1080 × 1920 (9:16), with the same headlines and
friends. `StoreScreenshotTest` renders the six screens with Robolectric at 412 × 915 dp, xxhdpi, and
the DEBUG-only reading controls turned off. It only runs with `-PstoreScreenshots`, so CI and
`verifyRoborazziDebug` skip it:

```sh
cd android && ./gradlew :app:testDebugUnitTest --tests '*StoreScreenshotTest' -PstoreScreenshots --rerun
cd .. && python3 scripts/store-screenshots/compose.py play
```

The screens land in `build/store-screenshots/raw/android-<screen>.png` and the panels in
`build/store-screenshots/out/play-<n>-<screen>.png`. The reading moments sit where the current word
and its neighbours are whole on screen; check the result after changing one. `PLAY_SHOTS` maps each
panel to its Android screen, and `PLAY_STICKERS` moves friends that would cover a word or a
button. Upload the set in Play Console under the store listing's phone screenshots.
