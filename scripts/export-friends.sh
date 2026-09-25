#!/usr/bin/env bash
# Export the friends' art from Design/friends into the World module: sitting stickers, collectibles
# and world postcards.
#
# Design/friends is the source of truth; the WebP files in World/Resources are generated and
# committed. Stickers are scaled to 480 px on their long side, which covers the largest on-screen
# use (about 124 pt tall on home) at 3x. Collectibles are 44 pt at most, so 240 px covers them, and
# postcards are shown about 360 pt wide, so 1200 px.
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

for source in Design/friends/collectibles/*.png; do
  name=$(basename "$source" .png)
  sips -Z 240 "$source" --out "$scratch/$name.png" >/dev/null
  cwebp -quiet -q 90 -alpha_q 100 "$scratch/$name.png" -o "$world/collect-$name.webp"
  echo "exported collect-$name ($(du -h "$world/collect-$name.webp" | cut -f1))"
done

for source in Design/friends/worlds/*-postcard.jpg; do
  key=$(basename "$source" -postcard.jpg)
  sips -Z 1200 "$source" --out "$scratch/$key.jpg" >/dev/null
  cwebp -quiet -q 82 "$scratch/$key.jpg" -o "$world/postcard-$key.webp"
  echo "exported postcard-$key ($(du -h "$world/postcard-$key.webp" | cut -f1))"
done
