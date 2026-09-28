#!/bin/sh
# Xcode Cloud runs this after cloning the repo, before resolving packages.
#
# The setup itself is shared with GitHub Actions and lives in scripts/ci-setup.sh:
#
#   1. The package graph uses macros (@Feature, @CasePathable, @DebugSnapshot). Macro fingerprint
#      validation expects a one-time human approval that does not exist on a build machine, and
#      Xcode Cloud gives us no way to pass -skipMacroValidation, so the script sets the same default.
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

"$(dirname "$0")/../scripts/ci-setup.sh"
