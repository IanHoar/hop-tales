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

Pull requests that are already open pick up the new runner on their next push. To try GitHub
Actions without switching, run the workflow by hand from the Actions tab (`gh workflow run
test.yml --ref <branch>`), which runs whichever runner is live.

The workflow runs only when a pull request is opened, reopened or pushed to, and never when it is
labelled. Labelling a new pull request fires one event per label at the same moment. Each started
a run and cancelled the one before, and GitHub reads the required check from the newest run, so a
cancelled one blocked the merge even after an older run had passed.

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
- Tests on an iPhone 18 Pro on the iOS 27.0 runtime **build 24A434**, the build the snapshots were
  recorded on. It uses the image's own device, which boots faster than a new one, and creates one
  only when the image has none. If the image doesn't have that build, it downloads it first. When the
  snapshot runtime moves, change `SNAPSHOT_RUNTIME_BUILD` in the workflow alongside
  `SnapshotSupport.swift` and the Xcode Cloud destination.
- Boots the simulator before testing, so xcodebuild never waits on a cold boot, and stops the
  Test step after 25 minutes if it hangs.
- Caches the whole of DerivedData except its logs, keyed on `Package.resolved`, so packages compile
  once rather than on every run. It is 1.6 GB, and a cache without the app's own products was tried
  and was slower: the Test step took 11 minutes against under 6, so the rest of the build depends
  on them. The cache is saved only when that key is new, because saving 1.6 GB takes minutes.
  It also runs on pushes to `main`, because a cache saved there is the only one every pull request
  can read. One saved on a pull request's branch stays with that branch. Setting `IgnoreFileSystemDeviceInodeChanges` in `ci-setup.sh` is what lets Xcode trust
  a restored cache. It also skips the index store, which nothing on CI reads. A newer push cancels
  the run it supersedes.
- On failure, uploads the `.xcresult`, the build log and the failed snapshot images as the
  `test-results` artifact, kept for a week.
