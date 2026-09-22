#!/usr/bin/env bash
# Rasterise the world layers and the app icon into the app's asset catalog.
#
# Design/world/*.svg is the source of truth (2340×844 world). Do not hand-edit the PNGs — they are
# generated, and committed so that a build never depends on rsvg-convert being installed.
# Needs rsvg-convert: brew install librsvg
set -euo pipefail

cd "$(dirname "$0")/.."

if ! command -v rsvg-convert >/dev/null; then
  echo "rsvg-convert not found. brew install librsvg" >&2
  exit 1
fi

catalog="HopTales/Assets.xcassets/World"
rm -rf "$catalog"
mkdir -p "$catalog"
cat > "$catalog/Contents.json" <<'JSON'
{ "info" : { "author" : "xcode", "version" : 1 }, "properties" : { "provides-namespace" : true } }
JSON

# The world is 2340pt wide, and rasterising it whole is untenable: at @2x the seven layers came to
# 97MB, most of it the feTurbulence grain and feGaussianBlur haze the art is built from, which PNG
# cannot compress.
#
# The parallax layers therefore ship as PDF. iOS rasterises a vector asset at whatever size it is
# asked for, so there is no resolution to choose and nothing to re-render when a device changes —
# 1.6MB for all three against 13MB of PNG.
#
# The skies do not go that way. Their filters rasterise into the PDF, making sky-day 1.0MB as a PDF
# against 504K as a PNG, so they stay bitmaps at quarter width and are stretched. They are smooth
# gradients, so the difference cannot be seen. Generating them in code removes the last of this
# (#17).
vector() {
  local name=$1
  local set="$catalog/$name.imageset"
  mkdir -p "$set"
  rsvg-convert -f pdf "Design/world/$name.svg" -o "$set/$name.pdf"
  cat > "$set/Contents.json" <<JSON
{
  "images" : [
    { "filename" : "$name.pdf", "idiom" : "universal" }
  ],
  "info" : { "author" : "xcode", "version" : 1 },
  "properties" : { "preserves-vector-representation" : true }
}
JSON
  echo "rendered $name as vector ($(du -h "$set/$name.pdf" | cut -f1))"
}

bitmap() {
  local name=$1 width=$2
  local set="$catalog/$name.imageset"
  mkdir -p "$set"
  rsvg-convert -w "$width" "Design/world/$name.svg" -o "$set/$name.png"
  cat > "$set/Contents.json" <<JSON
{
  "images" : [
    { "filename" : "$name.png", "idiom" : "universal", "scale" : "1x" }
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}
JSON
  echo "rendered $name at ${width}px ($(du -h "$set/$name.png" | cut -f1))"
}

for layer in layer-far layer-mid layer-near sprite-dragon; do
  vector "$layer"
done

for sky in sky-day sky-gold sky-dusk; do
  bitmap "$sky" 1170
done

# The app icon. Its source is a raster rather than an SVG, so it is resized with sips rather than
# rasterised. Unlike the world layers this PNG is committed: CI never runs this script, and a build
# without an icon is refused by App Store Connect.
icon=HopTales/Assets.xcassets/AppIcon.appiconset
mkdir -p "$icon"
sips -s format png -z 1024 1024 Design/icon.png --out "$icon/icon-1024.png" >/dev/null
cat > "$icon/Contents.json" <<'JSON'
{
  "images" : [
    { "filename" : "icon-1024.png", "idiom" : "universal", "platform" : "ios", "size" : "1024x1024" }
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}
JSON
echo "rendered app icon"
