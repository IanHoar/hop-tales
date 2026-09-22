#!/bin/sh
# Xcode Cloud runs this after the build action. On an archive that goes to TestFlight, it writes
# the "What to Test" notes testers see, from the commits in this build.
set -eu

if [ "${CI_XCODEBUILD_ACTION:-}" != "archive" ]; then
  exit 0
fi

notes_dir="${CI_PRIMARY_REPOSITORY_PATH:-.}/TestFlight"
mkdir -p "$notes_dir"

{
  echo "Wordhop ${CI_BUILD_NUMBER:-local} — ${CI_BRANCH:-unknown branch}"
  echo
  if [ -n "${CI_PRIMARY_REPOSITORY_PATH:-}" ]; then
    git -C "$CI_PRIMARY_REPOSITORY_PATH" log --pretty="- %s" -20
  fi
} > "$notes_dir/WhatToTest.en-US.txt"

echo "Wrote $notes_dir/WhatToTest.en-US.txt"
