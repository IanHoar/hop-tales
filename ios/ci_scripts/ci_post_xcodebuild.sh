#!/bin/sh
# Xcode Cloud runs this after the build action. On an archive that goes to TestFlight, it writes
# the "What to Test" notes testers see, from the commits since the previous release.
set -eu

if [ "${CI_XCODEBUILD_ACTION:-}" != "archive" ]; then
  exit 0
fi

repo=${CI_PRIMARY_REPOSITORY_PATH:-.}
notes_dir="$repo/ios/TestFlight"
mkdir -p "$notes_dir"

tag=${CI_TAG:-$(git -C "$repo" describe --exact-match --tags HEAD 2>/dev/null || true)}

# The previous iOS release tag, when the clone is deep enough to have it. Only ios/v* tags count,
# so an Android release in between doesn't cut the notes short; before the first ios/v* tag, the
# legacy v* tags are the baseline. Without either the notes fall back to the last twenty commits,
# which is better than nothing and never fails the build.
previous=$(git -C "$repo" describe --abbrev=0 --tags --match 'ios/v*' "$tag^" 2>/dev/null \
  || git -C "$repo" describe --abbrev=0 --tags --match 'v*' "$tag^" 2>/dev/null || true)

{
  echo "Hop Tales ${tag:-${CI_BUILD_NUMBER:-local}}"
  echo
  if [ -n "$previous" ]; then
    git -C "$repo" log --pretty="- %s" "$previous..HEAD"
  else
    git -C "$repo" log --pretty="- %s" -20
  fi
} > "$notes_dir/WhatToTest.en-US.txt"

echo "Wrote $notes_dir/WhatToTest.en-US.txt"
