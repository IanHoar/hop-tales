#!/usr/bin/env bash
# Rasterise the world layers and the app icon into the app's asset catalog.
#
# Design/world/*.svg is the source of truth (2340×844 world). Do not hand-edit the PNGs — they are
# generated and git-ignored. Needs rsvg-convert: brew install librsvg
set -euo pipefail

cd "$(dirname "$0")/.."

if ! command -v rsvg-convert >/dev/null; then
  echo "rsvg-convert not found. brew install librsvg" >&2
  exit 1
fi

catalog="HopTales/Assets.xcassets/World"
mkdir -p "$catalog"
cat > "$catalog/Contents.json" <<'JSON'
{ "info" : { "author" : "xcode", "version" : 1 }, "properties" : { "provides-namespace" : true } }
JSON

for svg in Design/world/*.svg; do
  name=$(basename "$svg" .svg)
  set=$catalog/$name.imageset
  mkdir -p "$set"
  rsvg-convert -w 4680 "$svg" -o "$set/$name@2x.png"
  rsvg-convert -w 7020 "$svg" -o "$set/$name@3x.png"
  cat > "$set/Contents.json" <<JSON
{
  "images" : [
    { "idiom" : "universal", "scale" : "1x" },
    { "filename" : "$name@2x.png", "idiom" : "universal", "scale" : "2x" },
    { "filename" : "$name@3x.png", "idiom" : "universal", "scale" : "3x" }
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}
JSON
  echo "rendered $name"
done

# The app icon. Unlike the world layers this PNG is committed: CI never runs this script, and a
# build without an icon is refused by App Store Connect.
icon=HopTales/Assets.xcassets/AppIcon.appiconset
mkdir -p "$icon"
rsvg-convert -w 1024 -h 1024 Design/icon.svg -o "$icon/icon-1024.png"
cat > "$icon/Contents.json" <<'JSON'
{
  "images" : [
    { "filename" : "icon-1024.png", "idiom" : "universal", "platform" : "ios", "size" : "1024x1024" }
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}
JSON
echo "rendered app icon"
