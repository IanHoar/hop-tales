# CI runners

Pull requests are tested by one of two runners, and either can take over from the other:

| Runner | Free tier | Required check on `main` |
|---|---|---|
| Xcode Cloud | 25 compute hours a month | `HopTales \| Default` |
| GitHub Actions | Unlimited minutes, because the repository is public | `Test` |

TestFlight releases stay on Xcode Cloud whichever runner is testing pull requests. Only Xcode Cloud
signs and uploads builds. [xcode-cloud.md](xcode-cloud.md) is its runbook.

## Switching

```sh
scripts/ci-runner.sh              # which runner is live, and which check main requires
scripts/ci-runner.sh github       # hand pull requests to GitHub Actions
scripts/ci-runner.sh xcode-cloud  # hand them back to Xcode Cloud
```

The script changes two things together, so a merge is never blocked on a check that no one will
post:

1. The `CI_RUNNER` repository variable. `.github/workflows/test.yml` runs when it is `github` and
   is skipped otherwise.
2. The required status check in the `main` ruleset.

It needs `gh` signed in as a repository admin.

**Xcode Cloud's pull request workflow is switched in App Store Connect.** GitHub can't reach it,
so the script prints the step: App Store Connect → Hop Tales → Xcode Cloud → Manage Workflows →
`Default` → Disable, or Enable to switch back. Leave the release workflow on either way. A disabled
workflow starts no builds and spends no hours. If it's left on while GitHub Actions is live, it
keeps testing pull requests until its hours run out.

**When to switch.** GitHub Actions is the default while the repository is public, since its minutes
are free and uncapped. Switch to Xcode Cloud if GitHub's macOS runners become unavailable or
metered, and switch back when they return. If Xcode Cloud is live and its hours run out, it stops
posting checks and pull requests wait on `HopTales | Default` forever. That is the moment to run
`scripts/ci-runner.sh github`.

Pull requests that are already open pick up the new runner on their next push. To test one
straight away, add the `ci:github-actions` label. It runs the workflow whichever runner is live,
which also makes it the way to try GitHub Actions without switching.

## GitHub Actions setup

Once only:

```sh
gh secret set TCA26_TOKEN
```

Paste the same token that Xcode Cloud uses: read access to the private `pointfreeco/TCA26`.
Secrets are not passed to workflows that run from forks, so a pull request from a fork cannot
resolve packages. Every branch here is pushed to this repository, so that does not arise.

## What the workflow does

- Runs on the `xcode-27` image, with Xcode 27.0 (27A266a) pinned through `DEVELOPER_DIR`, which is
  the same Xcode that Xcode Cloud pins.
- Runs `scripts/ci-setup.sh`, the setup it shares with Xcode Cloud's `ci_post_clone.sh`: macro
  trust, prebuilt swift-syntax, the TCA26 token, and swiftlint.
- Creates an iPhone 18 Pro on the iOS 27.0 runtime **build 24A434**, which is the build the
  snapshots were recorded on. If the image doesn't have that build, it downloads it first. When the
  snapshot runtime moves, change `SNAPSHOT_RUNTIME_BUILD` in the workflow alongside
  `SnapshotSupport.swift` and the Xcode Cloud destination.
- Boots the simulator before testing, so xcodebuild never waits on a cold boot, and stops the
  Test step after 25 minutes if it hangs.
- Caches all of DerivedData, keyed on `Package.resolved`, so packages compile once rather than on
  every run. Setting `IgnoreFileSystemDeviceInodeChanges` in `ci-setup.sh` is what lets Xcode trust
  a restored cache. It also skips the index store, which nothing on CI reads. A newer push cancels
  the run it supersedes.
- On failure, uploads the `.xcresult`, the build log and the failed snapshot images as the
  `test-results` artifact, kept for a week.
