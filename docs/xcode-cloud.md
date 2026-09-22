# Xcode Cloud

Two workflows: one that checks every pull request, one that puts `main` on TestFlight. The free tier
is 25 compute hours a month, which is the reason the PR workflow builds and tests rather than
archives.

The repository side is done — `ci_scripts/` and a shared `HopTales` scheme are committed. What is
left is account setup, and it has to happen in the Xcode or App Store Connect UI.

## What the scripts do

Xcode Cloud runs anything it finds in `ci_scripts/` at the matching point in the build. All three
exit immediately when `CI_XCODEBUILD_ACTION` is unset, so running them on your own machine does
nothing.

| Script | When | Why |
|---|---|---|
| `ci_post_clone.sh` | after clone, before package resolution | Trusts the package macros, and authenticates the private `pointfreeco/TCA26` dependency |
| `ci_pre_xcodebuild.sh` | before an archive | Stamps `CI_BUILD_NUMBER`, which TestFlight requires to be unique |
| `ci_post_xcodebuild.sh` | after an archive | Writes `TestFlight/WhatToTest.en-US.txt` from the build's commits |

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

   You are looking for an entry under `hoar.ian@gmail.com` with **`isFreeProvisioningTeam = 0`**.
   Enrolling as an individual issues a **new** team ID, so expect something other than
   `8J5E74LNJY`; that old free team stays in the list, which makes it easy to grab the wrong one.
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
- **Test destination: iPhone 18 Pro, iOS 27 — pin it.** The snapshot references in
  `HopTalesPackage/Tests/SnapshotTests/__Snapshots__` were recorded on that simulator. A different
  device or OS renders text fractionally differently and the snapshot tests fail on noise rather
  than on a real change.
- Scheme `HopTales`, which runs all four package test targets.
- **Tick auto-cancel** in the start condition. Without it a second push leaves the first build
  running to completion against a commit nobody is waiting on, and the free tier is 25 hours.

Once a build has reported once, add its check to the branch protection rule on `main` so a red build
blocks the merge.

### 5. The release workflow

- **Start Condition:** Branch Changes on `main`.
- **Actions:** Archive, with TestFlight (Internal Testing Only) as the distribution.
- Add yourself to an internal tester group.

## Known limits

- **Macro trust.** Command-line builds need `-skipMacroValidation`; Xcode Cloud offers no way to
  pass it, so `ci_post_clone.sh` sets `IDESkipMacroFingerprintValidation` instead. If a build fails
  with "Macro … must be enabled before it can be used", that script did not run — check it is
  executable and at the repository root under `ci_scripts/`.
- **The token is a dependency on a private beta.** When TCA26 becomes public, delete the secret and
  the `git config` block in `ci_post_clone.sh`.
- **Snapshot tests are device-specific.** See the pinning note above, and re-record them when the
  real fonts land (#30).
- **Auto-cancel is a workflow setting, not a file.** It lives in the start condition in Xcode or
  App Store Connect, so it cannot be committed here — check it after creating either workflow.
- **`[ci skip]` in a commit message skips the build**, which is worth using for documentation-only
  commits on a branch with an open pull request.
