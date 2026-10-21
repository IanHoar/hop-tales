#!/bin/sh
# Checks that a pull request keeps the iOS and Android apps at parity.
#
#   scripts/parity-check.sh <pull request number>
#
# A pull request that changes the app code of only one platform must say what happens on the other
# in a "Parity:" line in its description:
#
#   Parity: both                    this pull request changes both apps
#   Parity: #123                    an open issue labelled "parity" tracks the other app
#   Parity: n/a — <reason>          the change has no counterpart, such as a platform-only API
#
# Pull requests that change both apps, or neither, pass without the line. Shared content, art and
# fonts under ios/HopTalesPackage/Sources/*/Resources reach both apps, so they don't count as
# either side. docs/parity.md has the rest.
set -eu

repo="${GITHUB_REPOSITORY:-IanHoar/hop-tales}"
pr="$1"

files=$(gh api --paginate "repos/$repo/pulls/$pr/files" --jq '.[].filename')
body=$(gh api "repos/$repo/pulls/$pr" --jq '.body // ""')

ios=$(printf '%s\n' "$files" | grep -E '^ios/(HopTalesPackage/Sources/|HopTales/)' \
  | grep -vE '^ios/HopTalesPackage/Sources/[^/]+/Resources/' | head -1 || true)
android=$(printf '%s\n' "$files" | grep -E '^android/(app|core/[^/]+)/src/main/' | head -1 || true)

if [ -n "$ios" ] && [ -n "$android" ]; then
  echo "Changes both apps."
  exit 0
fi
if [ -z "$ios" ] && [ -z "$android" ]; then
  echo "Changes neither app's code."
  exit 0
fi

side=iOS other=Android
[ -n "$android" ] && side=Android other=iOS

line=$(printf '%s\n' "$body" | tr -d '\r' | grep -iE '^parity:' | head -1 | sed -E 's/^[Pp]arity:[[:space:]]*//' || true)

fail() {
  echo "::error title=Parity::$1"
  echo "$1"
  echo
  echo "This pull request changes only the $side app. Add a line to its description saying what"
  echo "happens on $other:"
  echo "  Parity: both                 if this pull request should change both apps"
  echo "  Parity: #123                 an open issue labelled 'parity' for the $other side"
  echo "  Parity: n/a — <reason>       if the change has no $other counterpart"
  exit 1
}

[ -n "$line" ] || fail "No Parity line in the description."

case "$line" in
  [Bb]oth*)
    fail "Parity says both, but only the $side app changed." ;;
  \#[0-9]*)
    issue=$(printf '%s' "$line" | sed -E 's/^#([0-9]+).*/\1/')
    info=$(gh api "repos/$repo/issues/$issue" --jq '[.state, ([.labels[].name] | index("parity") != null), (.pull_request != null)] | @tsv' 2>/dev/null) \
      || fail "Issue #$issue doesn't exist."
    state=$(printf '%s' "$info" | cut -f1)
    labelled=$(printf '%s' "$info" | cut -f2)
    is_pr=$(printf '%s' "$info" | cut -f3)
    [ "$is_pr" = false ] || fail "#$issue is a pull request, not an issue."
    [ "$state" = open ] || fail "Issue #$issue is closed. Link an open issue for the $other side."
    [ "$labelled" = true ] || fail "Issue #$issue needs the 'parity' label."
    echo "The $other side is tracked by #$issue." ;;
  [Nn]/[Aa]*)
    reason=$(printf '%s' "$line" | sed -E 's/^[Nn]\/[Aa][[:space:]]*[—–:-]*[[:space:]]*//')
    [ -n "$reason" ] || fail "Parity n/a needs a reason."
    echo "No $other counterpart: $reason" ;;
  *)
    fail "Parity line not understood: '$line'." ;;
esac
