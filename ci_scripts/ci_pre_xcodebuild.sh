#!/bin/sh
# Before an archive, stamp the build number Xcode Cloud allocated. TestFlight rejects a build
# number it has already seen, so this cannot be left at the 1 in project.yml.
set -eu

if [ "${CI_XCODEBUILD_ACTION:-}" != "archive" ]; then
  exit 0
fi

cd "${CI_PRIMARY_REPOSITORY_PATH:?CI_PRIMARY_REPOSITORY_PATH is not set}"
echo "Setting the build number to ${CI_BUILD_NUMBER:?CI_BUILD_NUMBER is not set}."
xcrun agvtool new-version -all "$CI_BUILD_NUMBER"
