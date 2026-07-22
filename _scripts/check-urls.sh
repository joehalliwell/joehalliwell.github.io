#!/usr/bin/env bash
# Assert that every path in urls.txt exists in the built site.
set -euo pipefail

manifest="${1:-urls.txt}"
output_dir="${2:-build}"

if [ ! -d "$output_dir" ]; then
    echo "No $output_dir/ -- render the site first." >&2
    exit 1
fi

missing=0
checked=0
while read -r path; do
    path="${path%%#*}"
    path="$(echo "$path" | xargs)"
    [ -z "$path" ] && continue
    checked=$((checked + 1))
    if [ ! -e "$output_dir/$path" ]; then
        echo "MISSING $path"
        missing=$((missing + 1))
    fi
done < "$manifest"

if [ "$missing" -gt 0 ]; then
    echo
    echo "$missing of $checked paths missing from $output_dir/" >&2
    exit 1
fi

echo "All $checked paths present in $output_dir/"
