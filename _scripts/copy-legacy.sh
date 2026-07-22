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

cp -r "$legacy_dir/." "$output_dir/"

echo "post-render: copied $(find "$legacy_dir" -type f | wc -l) legacy files to /"
