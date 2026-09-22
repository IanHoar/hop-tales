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

# Keep the token out of the log: no xtrace, and git stores it in a config file rather than in a
# command line that shows up in process listings.
echo "Authenticating package resolution for private dependencies."
git config --global \
  "url.https://x-access-token:${TCA26_TOKEN}@github.com/.insteadOf" \
  "https://github.com/"
