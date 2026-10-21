# Keeping iOS and Android at parity

Hop Tales ships on both platforms, and a feature should reach both. Every pull request into `main`
runs the `Parity` check (`.github/workflows/parity.yml`, `scripts/parity-check.sh`), which is a
required check.

## The rule

A pull request that changes the app code of only one platform says what happens on the other, in
a line of its description:

| Line | Meaning |
|---|---|
| `Parity: both` | This pull request changes both apps. Only valid when it does. |
| `Parity: #123` | Issue #123, open and labelled `parity`, tracks the other app. |
| `Parity: n/a — <reason>` | The change has no counterpart: a platform-only API, packaging, a fix to one app's own code. |

App code is `ios/HopTales/`, `ios/HopTalesPackage/Sources/`, `android/app/src/main/` and
`android/core/*/src/main/`. Tests, docs, CI, the website and the shared content, art and fonts in
`ios/HopTalesPackage/Sources/*/Resources/` don't count: the shared resources already reach both
apps. A pull request that changes both apps, or neither, passes without the line.

The check runs again when the description is edited, so fixing the line takes seconds.

## The parity backlog

Issues labelled `parity` are features one app has and the other doesn't yet. Close them when the
second app catches up. `gh issue list --label parity` shows the gap at any time.

## Run it locally

```sh
scripts/parity-check.sh <pull request number>
```
