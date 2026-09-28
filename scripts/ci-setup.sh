#!/bin/sh
# Prepares a CI machine to build and test Hop Tales. Both CI runners call it:
#
#   Xcode Cloud     ci_scripts/ci_post_clone.sh, after clone
#   GitHub Actions  .github/workflows/test.yml, after checkout
#
# It rewrites global git and Xcode defaults, so it refuses to run anywhere CI is unset — both
# runners set it, and a developer's machine does not.
#
# See docs/ci.md for switching between the runners, and docs/xcode-cloud.md for Xcode Cloud.
set -eu

if [ -z "${CI:-}" ]; then
  echo "error: scripts/ci-setup.sh only runs on CI (CI is unset). It rewrites global git and" >&2
  echo "Xcode settings, which is not something to do to your own machine." >&2
  exit 1
fi

if [ -z "${TCA26_TOKEN:-}" ]; then
  cat >&2 <<'MESSAGE'
error: TCA26_TOKEN is not set.

Package resolution needs read access to the private pointfreeco/TCA26 repository. Add a GitHub
token with read access to it as a secret named TCA26_TOKEN:

  Xcode Cloud     App Store Connect → Xcode Cloud → the workflow → Environment → Secret
  GitHub Actions  gh secret set TCA26_TOKEN
MESSAGE
  exit 1
fi

# Snapshot references are pinned to one simulator runtime, so print what this machine has. When a
# snapshot test fails on the runtime check, this is where to see what CI actually ran.
echo "Xcode and simulator runtimes on this machine:"
xcodebuild -version || true
xcrun simctl list runtimes | grep -i ios || true

echo "Trusting package macros for this build."
defaults write com.apple.dt.Xcode IDESkipMacroFingerprintValidation -bool YES

# swift-syntax is the single biggest thing in the graph — TCA26's macros and snapshot-testing both
# pull it — and compiling it from source is most of a build. Swift 6.1.1 and later can download a
# prebuilt binary instead. If there is no prebuilt for the resolved version, this is simply ignored
# and the build compiles it as before.
# A restored build cache arrives with new inodes, and Xcode reads that as every file having
# changed. This makes it compare modification times alone, so the cache is actually used.
echo "Letting a restored build cache count as up to date."
defaults write com.apple.dt.XCBuild IgnoreFileSystemDeviceInodeChanges -bool YES

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
# brew updates itself before every install, which is minutes of a build spent refreshing formulae we
# do not need. The formula on the image is recent enough for swiftlint.
echo "Installing swiftlint."
HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_INSTALL_CLEANUP=1 brew install swiftlint
