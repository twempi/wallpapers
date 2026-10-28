#!/usr/bin/env bash
set -euo pipefail

dir="${1:-.}"

# Requires ImageMagick.
if ! command -v magick >/dev/null 2>&1; then
  echo "ImageMagick is required. Install it, then run this script again."
  exit 1
fi

# Find supported image files. Existing numbered files stay first;
# other files are appended afterward in natural filename order.
mapfile -d '' -t files < <(
  find "$dir" -maxdepth 1 -type f \
    \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' \
       -o -iname '*.webp' -o -iname '*.avif' -o -iname '*.heic' \
       -o -iname '*.gif' -o -iname '*.bmp' -o -iname '*.tif' \
       -o -iname '*.tiff' \) \
    -printf '%f\0' |
    sort -z -V
)

if [ "${#files[@]}" -eq 0 ]; then
  echo "No supported image files found in: $dir"
  exit 0
fi

# Convert into a temporary folder first, so nothing is changed if
# a conversion fails.
tmpdir=$(mktemp -d "$dir/.wallpaper-convert.XXXXXX")
trap 'rm -rf "$tmpdir"' EXIT

for i in "${!files[@]}"; do
  file="${files[$i]}"
  output="$tmpdir/$((i + 1)).png"

  if [[ "${file,,}" == *.png ]]; then
    cp -- "$dir/$file" "$output"
  else
    # [0] uses the first frame of animated GIFs, if any.
    magick "$dir/$file[0]" "$output"
  fi
done

# Remove the old source images only after every conversion succeeded.
for file in "${files[@]}"; do
  rm -- "$dir/$file"
done

# Put the converted, sequentially named PNGs in the wallpaper folder.
for i in "${!files[@]}"; do
  mv -- "$tmpdir/$((i + 1)).png" "$dir/$((i + 1)).png"
done

echo "Converted and renamed ${#files[@]} wallpapers to 1.png ... ${#files[@]}.png"
