#!/usr/bin/env bash
# Assert that no rendered page uses a heading deeper than h3.
#
# The sheet styles h2 and h3 and nothing below: h4-h6 fall back to looking
# like h3, which keeps a stray one presentable but makes the outline lie.
# Better to stop it here than to ship it.
set -euo pipefail

root="${1:-.}"

# The same sources _quarto.yml renders: top-level pages and posts/.
mapfile -t sources < <(find "$root" -maxdepth 1 -name '*.qmd'; find "$root/posts" -name '*.qmd')

found=0
for f in "${sources[@]}"; do
    # Skip YAML front matter and fenced code, where `####` is just a comment.
    hits="$(awk '
        NR == 1 && /^---[[:space:]]*$/ { yaml = 1; next }
        yaml { if (/^---[[:space:]]*$/) yaml = 0; next }
        /^[[:space:]]*(```|~~~)/ { fence = !fence; next }
        !fence && /^#####*[[:space:]]/ { print FILENAME ":" FNR ": " $0 }
    ' "$f")"
    if [ -n "$hits" ]; then
        echo "$hits"
        found=$((found + $(printf '%s\n' "$hits" | wc --lines)))
    fi
done

if [ "$found" -gt 0 ]; then
    echo
    echo "$found heading(s) deeper than h3; the sheet only styles h2 and h3." >&2
    exit 1
fi
