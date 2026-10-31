#!/usr/bin/env bash
# Assert that no rendered page uses a heading deeper than h3.
#
# The sheet styles h2 and h3 and nothing below: h4-h6 fall back to looking
# like h3, which keeps a stray one presentable but makes the outline lie.
# Better to stop it here than to ship it.
#
# This reads the built HTML rather than the sources, so .qmd, .md and .ipynb
# posts are all covered and code fences need no special handling. Pages copied
# from _legacy/ and the /blog/ redirect stubs are not styled by the sheet, so
# they are skipped.
#
# Usage: check-headings.sh [output-dir] [legacy-dir]
set -euo pipefail

output_dir="${1:-build}"
legacy_dir="${2:-_legacy}"

if [ ! -d "$output_dir" ]; then
    echo "No $output_dir/ -- render the site first." >&2
    exit 1
fi

found=0
while IFS= read -r -d '' page; do
    relative="${page#"$output_dir"/}"
    case "$relative" in blog/*) continue ;; esac
    [ -e "$legacy_dir/$relative" ] && continue
    while IFS= read -r hit; do
        echo "$relative: $hit"
        found=$((found + 1))
    done < <(grep --only-matching '<h[4-6][ >][^<]*' "$page" || true)
done < <(find "$output_dir" -name '*.html' -type f -print0)

if [ "$found" -gt 0 ]; then
    echo
    echo "$found heading(s) deeper than h3; the sheet only styles h2 and h3." >&2
    exit 1
fi
