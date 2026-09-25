#!/usr/bin/env bash
# Export the friends' sitting stickers from Design/friends/characters into the World module.
#
# Design/friends is the source of truth; the WebP files in World/Resources are generated and
# committed. Each sticker is scaled to 480 px on its long side, which covers the largest on-screen
# use (about 124 pt tall on home) at 3x.
# Needs cwebp: brew install webp
set -euo pipefail

cd "$(dirname "$0")/.."

if ! command -v cwebp >/dev/null; then
  echo "cwebp not found. brew install webp" >&2
  exit 1
fi

world="HopTalesPackage/Sources/World/Resources"
scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT

for source in Design/friends/characters/*-sit.png; do
  key=$(basename "$source" -sit.png)
  sips -Z 480 "$source" --out "$scratch/$key.png" >/dev/null
  cwebp -quiet -q 90 -alpha_q 100 "$scratch/$key.png" -o "$world/friend-$key.webp"
  echo "exported friend-$key ($(du -h "$world/friend-$key.webp" | cut -f1))"
done
