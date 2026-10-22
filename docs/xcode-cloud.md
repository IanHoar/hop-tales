# Xcode Cloud

Two workflows: one that checks every pull request, one that puts `main` on TestFlight. The free tier
is 25 compute hours a month, which is the reason the PR workflow builds and tests rather than
archives.

When the free hours run out, GitHub Actions can test pull requests instead. [ci.md](ci.md) covers
switching between the two.

The repository side is done — `ios/ci_scripts/` and a shared `HopTales` scheme are committed. What
is left is account setup, and it has to happen in the Xcode or App Store Connect UI.

The app lives in `ios/` since the repository became a monorepo. Xcode Cloud looks for `ci_scripts/`
beside the workspace it builds, so the scripts moved with it, and each workflow has to point at
`ios/HopTales.xcworkspace`. A workflow created before the move still names the old root path and
fails to find the project until it is edited in Xcode (Integrate → Manage Workflows → the workflow
→ General) and saved. Give the release workflow a start condition that skips changes only under
`android/`, so Android merges don't spend the free hours. Leave the pull request workflow running
on every change while its check is required: a build it skips posts no check, and the pull request
can't merge (see [ci.md](ci.md)).

## What the scripts do

Xcode Cloud runs anything it finds in `ios/ci_scripts/` at the matching point in the build. All three
exit immediately when `CI_XCODEBUILD_ACTION` is unset, so running them on your own machine does
nothing.

| Script | When | Why |
|---|---|---|
| `ci_post_clone.sh` | after clone, before package resolution | Runs `scripts/ci-setup.sh`, shared with GitHub Actions, which trusts the package macros, authenticates the private `pointfreeco/TCA26` dependency, and prefers a prebuilt swift-syntax |
| `ci_pre_xcodebuild.sh` | before an archive | Stamps the version and build number the release tag asked for |
| `ci_post_xcodebuild.sh` | after an archive | Writes `ios/TestFlight/WhatToTest.en-US.txt` from the commits since the previous iOS release |

## Setup

### 0. Wait for the paid membership, then set the team

**Nothing below works until this is done.** Xcode Cloud, TestFlight and the App Store all require a
paid Apple Developer Program membership. A *free* personal team — which is what
`hoar.ian@gmail.com` had, `8J5E74LNJY`, and what `ian@metalab.com` has as `PJ3Y8B5FJ3` — can only
install to your own device, and Xcode hides those teams from the Xcode Cloud team picker. If the
picker looks like it is missing your team, that is why.

Once the renewal goes through:

1. Check it is actually active at
   [developer.apple.com/account](https://developer.apple.com/account) → Membership details. Status
   must read *Active*, not *Processing*.
2. **Xcode → Settings → Accounts**, select `hoar.ian@gmail.com`, **sign out and sign back in**.
   "Download Manual Profiles" is not enough — it refreshes profiles, not team membership.
3. Read the team ID back:

   ```sh
   defaults read com.apple.dt.Xcode IDEProvisioningTeams | grep -E "teamID|teamName|isFree"
   ```

   Enrolling as an individual **kept** the personal team's ID: App Store Connect shows the account
   as `8J5E74LNJY`, which is what `project.yml` carries. Xcode's cached copy of that entry can
   still read `isFreeProvisioningTeam = 1` long after the membership is active — the cache is what
   signing out and back in refreshes, so trust App Store Connect over this list.
4. Put that ID into `project.yml` as `DEVELOPMENT_TEAM` (it is deliberately empty right now), then:

   ```sh
   xcodegen generate
   ```

   and commit both files.
5. Confirm the team now appears in Xcode's picker before going further.

### 1. Create the app record

Bundle ID `com.hoptales.ios`, on the team from step 0. Creating the first Xcode Cloud workflow
offers to create this record for you, which also closes issue #28.

### 2. Connect the repository

Xcode → Product → Xcode Cloud → Create Workflow, and grant the Xcode Cloud GitHub App access to
`IanHoar/hop-tales`. **Installing that app is also what posts build status back to pull
requests** — there is no separate step for it, and no webhook to configure.

### 3. Add the token for the private dependency

`ComposableArchitecture2` comes from the private `pointfreeco/TCA26`. Xcode Cloud can only clone
repositories its GitHub App is installed on, and we cannot install it on someone else's repository,
so CI authenticates as you instead.

1. Create a GitHub token with **read access to `pointfreeco/TCA26`**. A fine-grained token is
   preferable; if Point-Free's organization does not allow them, a classic token with `repo` scope
   inherits your access — note that this is a broad scope, so set an expiry and rotate it.
2. On **both** workflows: Environment → Environment Variables → add `TCA26_TOKEN`, value the token,
   and **tick Secret**. A non-secret variable would be printed in build logs.

`ci_post_clone.sh` fails with an explicit message if the variable is missing, rather than letting
package resolution fail with something cryptic.

### 4. The pull request workflow

- **Start Condition:** Pull Request Changes, target branch `main`.
- **Actions:** Build, then Test.
- **Environment: Xcode 27.1 (27A9275), not "Latest Release".** Pin the exact version on both
  workflows, so a new Xcode or simulator runtime on Xcode Cloud never changes the renderer behind
  our backs.
- **Test destination: iPhone 18 Pro, iOS 27.0 (build 24A434) — pin it, never "Latest".** The snapshot references in
  `ios/HopTalesPackage/Tests/SnapshotTests/__Snapshots__` were recorded on that exact simulator. A
  different device or runtime (27.1 included) resamples images and renders text fractionally
  differently, and the snapshot tests fail on noise rather than on a real change. `SnapshotSupport`
  checks the runtime and fails with a message naming both versions if they differ, and
  `ci_post_clone.sh` prints the machine's Xcode and runtimes into the log.
- **Moving to a new runtime** is a deliberate change: update `snapshotRuntime` and
  `snapshotRuntimeBuild` in `SnapshotSupport.swift`, re-record every reference on the new simulator, and change the pinned
  destination here and in both workflows in the same pull request.
- Scheme `HopTales`, Test Plan `HopTales` — the scheme's default plan, `HopTales.xctestplan`, which
  runs all six package test targets.
- **Leave test retries and repetitions off.** A failing snapshot fails the same way every time, so
  "Retry on failure" or "Run until failure" in the test action only reruns it. The test plan already
  sets repetition to none; nothing in the workflow should override it.
- **One test destination.** Every extra device or runtime is another full simulator run, and on
  anything but the pinned one the snapshot tests fail the runtime check anyway.
- **Tick auto-cancel** in the start condition. Without it a second push leaves the first build
  running to completion against a commit nobody is waiting on, and the free tier is 25 hours.

Once a build has reported once, add its check to the branch protection rule on `main` so a red build
blocks the merge.

### 5. The release workflow

A release is cut by publishing a GitHub release. Each app releases from its own tag prefix, and
the iOS tag carries both numbers:

```
ios/v<marketing version>-<build number>       e.g. ios/v1.0.0-1
```

An `android/v…` tag ships the Android app to Google Play through GitHub Actions instead
([google-play.md](google-play.md)), so the two apps release independently.

- **Start Condition:** Tag Changes, pattern `ios/v*`. Tick auto-cancel here too. Tags were plain
  `v*` (`v1.0.0-1` … `v1.0.0-62`) until each app got its own prefix: change the pattern in App Store
  Connect → Hop Tales → Xcode Cloud → Manage Workflows → the release workflow → Start Conditions
  when that change merges, or the first `ios/v…` release starts no build.
- **Actions:** Archive, with **TestFlight and App Store** as the deployment preparation — not
  Internal Testing Only, whose builds are processed without what an App Store submission needs and
  so can never be promoted. It only makes a build *eligible*; nothing is submitted for review.
- Add yourself to an internal tester group.

`ci_pre_xcodebuild.sh` reads the tag and stamps `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION`
with `agvtool`; `Info.plist` picks both up through `$(...)` substitution. A tag of any other shape
fails the build with an explicit message rather than shipping the wrong version, and an archive
started by anything but a tag fails the same way. A legacy `v…` tag fails too, so it can't ship
by accident.

TestFlight rejects a build number it has already seen, so the half after the dash increments for
every upload of the same version — `ios/v1.0.0-1`, `ios/v1.0.0-2` — and resets when the version
changes.

`ci_post_xcodebuild.sh` writes the What to Test notes from the commits since the previous `ios/v…`
tag, so an Android release in between doesn't cut them short. Until the first `ios/v…` tag exists it
falls back to the latest legacy `v…` tag.

`agvtool` alone is not enough. Xcode Cloud passes its own build number on the `xcodebuild` command
line, and a command-line setting beats the project, so `$(CURRENT_PROJECT_VERSION)` in `Info.plist`
resolves to Xcode Cloud's counter rather than the tag — `v1.0.0-2` shipped as **1.0.0 (41)**. The
script therefore writes both numbers into `Info.plist` as literals, leaving nothing to substitute,
and prints what it stamped so a build log settles any argument.

One consequence of that first mistake: build 41 is now spent against version 1.0.0. App Store
Connect wants a build number it has not seen for a given version, so another 1.0.0 release has to
clear every build already uploaded (the legacy tags reach `v1.0.0-62`), or move the version instead,
`ios/v1.0.1-1`. The latter is cleaner.

To cut one:

```sh
gh release create ios/v1.0.1-1 --generate-notes       # iOS, to TestFlight
gh release create android/v1.0.0-1 --generate-notes   # Android, to Play's internal testing
```

Ship both apps by publishing one release for each tag; they can point at the same commit, and
each app numbers its own versions.

Tagging is the only trigger: pushing to `main` no longer archives, so `main` can move without
spending compute or burning a build number.

## Build time

The test action is compiling almost throughout and testing for about two seconds — 35 tests, the
slowest suite 1.2 seconds. Anything that helps is therefore about the build, not the tests. A cold
test action took 10m24s and a warm one 4m33s, so most of the caching win is already there:

- **Prefer a prebuilt swift-syntax.** `ci_post_clone.sh` sets `IDEPackageEnablePrebuilts`. TCA26's
  macros and snapshot-testing both pull swift-syntax, and compiling it is most of a cold build.
- **Drop the Build action from the pull request workflow.** The test action compiles the same
  thing, so building first is roughly two minutes of the free tier spent twice.
- **Auto-cancel.** Covered in step 4 — a superseded build otherwise runs to completion.

## Failing fast

A failing test does not keep the test action going. The snapshot failure that turned `main` red
failed in under a minute, and those runs finished no later than the passing runs beside them. A
Test check on GitHub reads as 17 to 30 minutes because its clock starts when the action is created:
it includes the wait for a machine while several pull requests build at once, then the build for
testing, and only then the seconds of testing.

What the test plan guards against is a test that never finishes — a `TestStore` waiting on an effect,
a `receive` that never arrives. `HopTales.xctestplan` turns test timeouts on at 60 seconds, and
Xcode hands that limit to Swift Testing, so a hung test fails after a minute instead of running
until Xcode Cloud's own action timeout. The `TestStore` suites also carry `.timeLimit(.minutes(1))`,
which holds when they run from the package's own scheme without the plan.

Test settings live in `HopTales.xctestplan`, not the scheme. XcodeGen writes the scheme and drops
anything edited into it by hand, and it cannot express test timeouts; it only points the scheme at
the plan.

## Known limits

- **Macro trust.** Command-line builds need `-skipMacroValidation`; Xcode Cloud offers no way to
  pass it, so `ci_post_clone.sh` sets `IDESkipMacroFingerprintValidation` instead. If a build fails
  with "Macro … must be enabled before it can be used", that script did not run — check it is
  executable and in `ios/ci_scripts/`, beside the workspace.
- **The token is a dependency on a private beta.** When TCA26 becomes public, delete the secret and
  the `git config` block in `ci_post_clone.sh`.
- **Snapshot tests are device-specific.** See the pinning note above, and re-record them when the
  real fonts land (#30).
- **Auto-cancel is a workflow setting, not a file.** It lives in the start condition in Xcode or
  App Store Connect, so it cannot be committed here — check it after creating either workflow.
- **`[ci skip]` in a commit message skips the build**, which is worth using for documentation-only
  commits on a branch with an open pull request.
