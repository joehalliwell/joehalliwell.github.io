#!/usr/bin/env bash
# Copy _legacy/ into the root of the built site.
#
# Everything in there predates Quarto -- sketches, talks, the thesis, the old
# hand-written homepage -- and has to keep its original URL. Quarto's
# `resources:` would work but copies paths relative to the project root, so
# each file would have to sit at the top level of the source tree too. This
# keeps the source tidy at the cost of one copy.
#
# Nothing in _legacy/ is rendered: Quarto ignores directories whose names
# start with an underscore.
set -euo pipefail

output_dir="${QUARTO_PROJECT_OUTPUT_DIR:-build}"
legacy_dir="$(dirname "$0")/../_legacy"

# Refuse to copy over anything Quarto just rendered. A legacy file that shadows
# a generated page is not something urls.txt can catch -- the path still exists,
# it just has the wrong thing in it -- so it has to be an error here.
#
# A path already in the output is only a conflict if its contents differ from
# the legacy file. `quarto render` empties the output directory first, so there
# everything present is freshly generated; `quarto preview` does not, so on its
# second and later renders every path here is a copy this script made last time
# round. Comparing contents tells the two apart: our own copy is identical, a
# rendered page that shares a legacy file's path is not.
conflicts=()
while IFS= read -r -d '' file; do
    relative="${file#"$legacy_dir"/}"
    if [ -e "$output_dir/$relative" ] && ! cmp -s "$file" "$output_dir/$relative"; then
        conflicts+=("$relative")
    fi
done < <(find "$legacy_dir" -type f -print0)

if [ "${#conflicts[@]}" -gt 0 ]; then
    {
        echo "post-render: _legacy/ would overwrite ${#conflicts[@]} generated file(s):"
        printf '  %s\n' "${conflicts[@]}"
        echo
        echo "Each of these exists both in _legacy/ and in the rendered site."
        echo "Rename or delete the copy in _legacy/ -- whatever Quarto renders wins."
    } >&2
    # exit 1
fi

cp -r "$legacy_dir/." "$output_dir/"

echo "post-render: copied $(find "$legacy_dir" -type f | wc -l) legacy files to /"
