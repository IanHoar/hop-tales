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

**When to switch.** Xcode Cloud has no switch that GitHub can reach. When its hours are spent, it
stops posting checks, and pull requests wait on `HopTales | Default` forever. That is the moment
to run `scripts/ci-runner.sh github`. Switch back when the hours reset, or stay on GitHub Actions
and save Xcode Cloud's hours for releases. While GitHub Actions is live, Xcode Cloud's pull request
workflow keeps running as long as it has hours left. To stop it spending them, disable that
workflow in App Store Connect → Xcode Cloud → Manage Workflows.

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
- Caches resolved packages against `Package.resolved`, and cancels a run when a newer push
  supersedes it.
- On failure, uploads the `.xcresult`, the build log and the failed snapshot images as the
  `test-results` artifact, kept for a week.
