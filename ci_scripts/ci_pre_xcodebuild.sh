#!/bin/sh
# Before an archive, stamp the version and build number the tag asked for.
#
# Releases are cut by publishing a GitHub release, which creates a tag of the form
#
#     v<marketing version>-<build number>       e.g. v1.0.0-1
#
# The release workflow starts on tag changes, and this turns that one string into the two numbers
# the App Store needs. TestFlight rejects a build number it has already seen, so bump the half
# after the dash for every upload of the same version.
set -eu

if [ "${CI_XCODEBUILD_ACTION:-}" != "archive" ]; then
  exit 0
fi

cd "${CI_PRIMARY_REPOSITORY_PATH:?CI_PRIMARY_REPOSITORY_PATH is not set}"

# CI_TAG is set when a tag started the build. Falling back to the tag pointing at this commit keeps
# the script working if the variable is ever absent or renamed.
tag=${CI_TAG:-$(git describe --exact-match --tags HEAD 2>/dev/null || true)}

if [ -z "$tag" ]; then
  cat >&2 <<'MESSAGE'
error: this archive was not started by a tag, so there is no version to release.

The release workflow's start condition is Tag Changes, and the tag carries the version:

    v<marketing version>-<build number>       e.g. v1.0.0-1

See docs/xcode-cloud.md, step 5.
MESSAGE
  exit 1
fi

if ! echo "$tag" | grep -qE '^v[0-9]+\.[0-9]+\.[0-9]+-[0-9]+$'; then
  cat >&2 <<MESSAGE
error: the tag "$tag" is not a release version.

Release tags are v<major>.<minor>.<patch>-<build>, e.g. v1.0.0-1. Delete the tag and the release,
then publish it again with a name of that shape.
MESSAGE
  exit 1
fi

version=${tag#v}
marketing=${version%-*}
build=${version##*-}

echo "Releasing $marketing ($build), from $tag."
xcrun agvtool new-marketing-version "$marketing"
xcrun agvtool new-version -all "$build"
