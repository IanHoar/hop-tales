#!/bin/sh
# Switches which CI runner tests pull requests: GitHub Actions or Xcode Cloud.
#
#   scripts/ci-runner.sh              shows which runner is live
#   scripts/ci-runner.sh github       GitHub Actions tests PRs; its "Test" check is required
#   scripts/ci-runner.sh xcode-cloud  Xcode Cloud tests PRs; its "HopTales | Default" is required
#
# Two things change together, so a merge is never blocked on a check nobody will post:
#
#   1. The CI_RUNNER repository variable, which .github/workflows/test.yml reads to run or skip.
#   2. The required status check in the "main" ruleset.
#
# The third, turning Xcode Cloud's pull request workflow off or on, only App Store Connect can do,
# so the script prints where. See docs/ci.md.
set -eu

repo="IanHoar/hop-tales"
ruleset_name="main"

xcode_cloud_check="HopTales | Default"
xcode_cloud_app=117084
github_check="Test"
github_actions_app=15368

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
  context=$1
  app=$2
  id=$(ruleset_id)
  gh api "repos/$repo/rulesets/$id" | python3 -c '
import json, sys
ruleset = json.load(sys.stdin)
context, app = sys.argv[1], int(sys.argv[2])
for rule in ruleset["rules"]:
    if rule["type"] == "required_status_checks":
        rule["parameters"]["required_status_checks"] = [
            {"context": context, "integration_id": app}
        ]
print(json.dumps({
    "name": ruleset["name"],
    "target": ruleset["target"],
    "enforcement": ruleset["enforcement"],
    "conditions": ruleset["conditions"],
    "rules": ruleset["rules"],
    "bypass_actors": ruleset.get("bypass_actors", []),
}))
' "$context" "$app" | gh api --method PUT "repos/$repo/rulesets/$id" --input - >/dev/null
}

case "${1:-}" in
  "")
    echo "Live runner: $(current)"
    echo "Required check on main: $(required_checks)"
    ;;
  github)
    gh variable set CI_RUNNER --repo "$repo" --body github
    require "$github_check" "$github_actions_app"
    echo "GitHub Actions now tests pull requests, and \"$github_check\" is required on main."
    echo "Open pull requests pick it up on their next push, or run: gh pr edit <n> --add-label ci:github-actions"
    echo
    echo "Now disable Xcode Cloud's pull request workflow so it stops spending hours:"
    echo "  App Store Connect → Hop Tales → Xcode Cloud → Manage Workflows → Default → Disable"
    echo "Leave the release workflow on."
    ;;
  xcode-cloud)
    gh variable set CI_RUNNER --repo "$repo" --body xcode-cloud
    require "$xcode_cloud_check" "$xcode_cloud_app"
    echo "Xcode Cloud now tests pull requests, and \"$xcode_cloud_check\" is required on main."
    echo
    echo "Now enable Xcode Cloud's pull request workflow again:"
    echo "  App Store Connect → Hop Tales → Xcode Cloud → Manage Workflows → Default → Enable"
    ;;
  *)
    echo "usage: scripts/ci-runner.sh [github | xcode-cloud]" >&2
    exit 2
    ;;
esac
