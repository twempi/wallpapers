#!/usr/bin/env bash
set -euo pipefail

dir="${1:-.}"

shopt -s nullglob

# Get PNG files in natural numeric order: 1.png, 2.png, 10.png, etc.
mapfile -t files < <(
  find "$dir" -maxdepth 1 -type f -name '*.png' -printf '%f\n' | sort -V
)

if [ ${#files[@]} -eq 0 ]; then
  echo "No .png files found in: $dir"
  exit 0
fi

# Pass 1: rename to temporary names
i=1
for file in "${files[@]}"; do
  tmp=$(printf ".renaming_tmp_%04d.png" "$i")
  mv -- "$dir/$file" "$dir/$tmp"
  ((i++))
done

# Pass 2: rename temp files to final sequential names
i=1
for tmp in "$dir"/.renaming_tmp_*.png; do
  mv -- "$tmp" "$dir/$i.png"
  ((i++))
done

echo "Renamed ${#files[@]} files in '$dir' to 1.png ... ${#files[@]}.png"
