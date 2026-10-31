#!/usr/bin/env bash
# Assert that everything the live site serves is still in the build.
#
# "Live" is the tree of the gh-pages branch: it is exactly what GitHub Pages
# serves, so unlike a hand-kept list it cannot fall behind. A page that has to
# go away for good is listed in retired.txt; a trailing slash retires a whole
# directory.
#
# site_libs/ is exempt. It is Quarto's own, and its filenames change with
# Quarto versions; nothing outside the site links into it.
#
# Usage: check-served.sh [ref] [output-dir] [retired-list]
set -euo pipefail

ref="${1:-origin/gh-pages}"
output_dir="${2:-build}"
retired="${3:-retired.txt}"

if [ ! -d "$output_dir" ]; then
    echo "No $output_dir/ -- render the site first." >&2
    exit 1
fi

# Strip comments and surrounding whitespace, as urls.txt used to.
retired_paths() {
    [ -f "$retired" ] || return 0
    sed -e 's/#.*//' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e '/^$/d' "$retired"
}

mapfile -t retired_list < <(retired_paths)

# An entry retires that exact path or, if it ends in a slash, everything under it.
is_retired() {
    local entry
    for entry in "${retired_list[@]}"; do
        case "$entry" in
            */) [[ "$1" == "$entry"* ]] && return 0 ;;
            *) [[ "$1" == "$entry" ]] && return 0 ;;
        esac
    done
    return 1
}

missing=0
checked=0
while IFS= read -r path; do
    case "$path" in site_libs/*) continue ;; esac
    is_retired "$path" && continue
    checked=$((checked + 1))
    if [ ! -e "$output_dir/$path" ]; then
        echo "MISSING $path"
        missing=$((missing + 1))
    fi
done < <(git ls-tree -r --name-only "$ref")

if [ "$missing" -gt 0 ]; then
    echo
    echo "$missing of $checked files served from $ref are missing from $output_dir/." >&2
    echo "If that is deliberate, list them in $retired." >&2
    exit 1
fi

echo "All $checked files served from $ref present in $output_dir/"
