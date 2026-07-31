#!/usr/bin/env bash
# [name]=size
declare -A sizes=(
  [android - chrome - 192x192]=192
  [android - chrome - 384x384]=384
  [apple - touch - icon]=180
  [favicon - 16x16]=16
  [favicon - 32x32]=32
  [mstile - 150x150]=150
)

# various .png
for name in "''${!sizes[@]}"; do
  magick convert logo.png -resize "''${sizes[$name]}x''${sizes[$name]}" "./static/''${name}.png"
done

# favicon.ico
magick convert logo.png -resize 16x16 \
  \( logo.png -resize 32x32 \) \
  ./static/favicon.ico
