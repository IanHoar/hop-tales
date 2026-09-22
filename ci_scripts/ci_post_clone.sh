#!/bin/sh
# Xcode Cloud runs this after cloning the repo, before resolving packages.
#
# Two things have to happen here or the build cannot even start:
#
#   1. The package graph uses macros (@Feature, @CasePathable, @DebugSnapshot). Macro fingerprint
#      validation expects a one-time human approval that does not exist on a build machine, and
#      Xcode Cloud gives us no way to pass -skipMacroValidation, so we set the same default here.
#
#   2. ComposableArchitecture2 lives in the private pointfreeco/TCA26 repository. Xcode Cloud can
#      only clone repositories its GitHub App is installed on, which we cannot do for someone
#      else's repository — so CI authenticates as us instead, with a token from a secret
#      environment variable on the workflow. Nothing is vendored or redistributed.
#
# See docs/xcode-cloud.md for how the workflows and secrets are set up.
set -eu

# Xcode Cloud always sets this. Locally it is unset, and this script does nothing — it must never
# rewrite a developer's own git or Xcode configuration.
if [ -z "${CI_XCODEBUILD_ACTION:-}" ]; then
  echo "Not running in Xcode Cloud (CI_XCODEBUILD_ACTION unset) — nothing to do."
  exit 0
fi

if [ -z "${TCA26_TOKEN:-}" ]; then
  cat >&2 <<'MESSAGE'
error: TCA26_TOKEN is not set.

Package resolution needs read access to the private pointfreeco/TCA26 repository. Add a GitHub
token with read access to it as a secret environment variable named TCA26_TOKEN on this workflow
(App Store Connect → Xcode Cloud → the workflow → Environment → Secret).
MESSAGE
  exit 1
fi

echo "Trusting package macros for this build."
defaults write com.apple.dt.Xcode IDESkipMacroFingerprintValidation -bool YES

# swift-syntax is the single biggest thing in the graph — TCA26's macros and snapshot-testing both
# pull it — and compiling it from source is most of a build. Swift 6.1.1 and later can download a
# prebuilt binary instead. If there is no prebuilt for the resolved version, this is simply ignored
# and the build compiles it as before.
echo "Preferring prebuilt swift-syntax."
defaults write com.apple.dt.Xcode IDEPackageEnablePrebuilts -bool YES

# Xcode Cloud rewrites GitHub URLs to http:// for its caching proxy, and git applies insteadOf
# exactly once, against the original URL — so a rule keyed on the rewritten http:// form never gets
# a turn. That is how the first builds failed: git ended up asking for a username on
# http://github.com with prompts disabled.
#
# Three rules, all scoped to the one organisation that needs them:
#
#   1. Rewrite pointfreeco URLs to carry the token. The longest matching prefix wins, so this beats
#      the platform's own https -> http rule on the original URL.
#   2. and 3. Credential helpers for both schemes, in case the URL still arrives rewritten.
echo "Authenticating package resolution for private dependencies."
git config --global \
  "url.https://x-access-token:${TCA26_TOKEN}@github.com/pointfreeco/.insteadOf" \
  "https://github.com/pointfreeco/"
for scheme in https http; do
  git config --global "credential.$scheme://github.com.helper" \
    '!f() { test "$1" = get && printf "username=x-access-token\npassword=%s\n" "$TCA26_TOKEN"; }; f'
done

# The build phase lints, and without swiftlint on the machine it can only warn about itself.
# Installed here rather than in the build phase so a failure is a setup failure, not a build one.
echo "Installing swiftlint."
brew install swiftlint
