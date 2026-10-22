#!/bin/sh
# Switches which CI runner tests pull requests: GitHub Actions or Xcode Cloud.
#
#   scripts/ci-runner.sh              shows which runner is live
#   scripts/ci-runner.sh github       GitHub Actions tests iOS
#   scripts/ci-runner.sh xcode-cloud  Xcode Cloud tests iOS, and the "CI" gate waits for its result
#
# Either way "CI" and "Parity" are the required checks. Two things change together:
#
#   1. The CI_RUNNER repository variable, which .github/workflows/ci.yml reads to run the iOS job
#      or the Xcode Cloud job that waits for "HopTales | Default". Android always runs on GitHub
#      Actions, and the "CI" gate always reports.
#   2. The required status checks in the "main" ruleset: "CI" and "Parity".
#
# The third, turning Xcode Cloud's pull request workflow off or on, only App Store Connect can do,
# so the script prints where. See docs/ci.md.
set -eu

repo="IanHoar/hop-tales"
ruleset_name="main"

xcode_cloud_check="HopTales | Default"
github_check="CI"
github_actions_app=15368
parity_check="Parity"

current() {
  gh variable get CI_RUNNER --repo "$repo" 2>/dev/null || echo "xcode-cloud"
}

ruleset_id() {
  gh api "repos/$repo/rulesets" --jq ".[] | select(.name == \"$ruleset_name\") | .id"
}

required_checks() {
  gh api "repos/$repo/rulesets/$(ruleset_id)" \
    --jq '.rules[] | select(.type == "required_status_checks")
      | .parameters.required_status_checks[].context'
}

require() {
  id=$(ruleset_id)
  gh api "repos/$repo/rulesets/$id" | python3 -c '
import json, sys
ruleset = json.load(sys.stdin)
pairs = sys.argv[1:]
checks = [
    {"context": pairs[i], "integration_id": int(pairs[i + 1])}
    for i in range(0, len(pairs), 2)
]
for rule in ruleset["rules"]:
    if rule["type"] == "required_status_checks":
        rule["parameters"]["required_status_checks"] = checks
print(json.dumps({
    "name": ruleset["name"],
    "target": ruleset["target"],
    "enforcement": ruleset["enforcement"],
    "conditions": ruleset["conditions"],
    "rules": ruleset["rules"],
    "bypass_actors": ruleset.get("bypass_actors", []),
}))
' "$@" | gh api --method PUT "repos/$repo/rulesets/$id" --input - >/dev/null
}

case "${1:-}" in
  "")
    echo "Live runner: $(current)"
    echo "Required check on main: $(required_checks)"
    ;;
  github)
    gh variable set CI_RUNNER --repo "$repo" --body github
    require "$github_check" "$github_actions_app" "$parity_check" "$github_actions_app"
    echo "GitHub Actions now tests iOS, and \"$github_check\" and \"$parity_check\" are required on main."
    echo "Open pull requests pick it up on their next push."
    echo
    echo "Now disable Xcode Cloud's pull request workflow so it stops spending hours:"
    echo "  App Store Connect → Hop Tales → Xcode Cloud → Manage Workflows → Default → Disable"
    echo "Leave the release workflow on."
    ;;
  xcode-cloud)
    gh variable set CI_RUNNER --repo "$repo" --body xcode-cloud
    require "$github_check" "$github_actions_app" "$parity_check" "$github_actions_app"
    echo "Xcode Cloud now tests iOS. \"$github_check\" waits for \"$xcode_cloud_check\", and"
    echo "\"$github_check\" and \"$parity_check\" are required on main."
    echo "Open pull requests pick it up on their next push."
    echo
    echo "Now enable Xcode Cloud's pull request workflow again:"
    echo "  App Store Connect → Hop Tales → Xcode Cloud → Manage Workflows → Default → Enable"
    echo "and give it a Files and Folders start condition that ignores changes only under android/,"
    echo "so Android-only pull requests don't spend its hours."
    ;;
  *)
    echo "usage: scripts/ci-runner.sh [github | xcode-cloud]" >&2
    exit 2
    ;;
esac
