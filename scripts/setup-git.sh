#!/bin/sh
# Points git at this repository's commit template and hooks. Run once after cloning.
set -eu

cd "$(dirname "$0")/.."

git config commit.template .gitmessage
git config core.hooksPath .githooks

echo "Commit template and hooks are set up. See CONTRIBUTING.md."
