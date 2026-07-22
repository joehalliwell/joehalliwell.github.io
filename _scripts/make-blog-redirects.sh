#!/usr/bin/env bash
# Mirror every page the blog used to serve under /blog/ into a redirect stub.
#
# The blog was published at joehalliwell.com/blog until it moved to the top
# level, so each old URL differs from its new one by exactly that prefix. That
# makes the mapping mechanical: no list of posts to keep in step, and posts
# added from now on get a stub they do not need rather than a missing one.
#
# Quarto's own `aliases:` would do this a post at a time, but it emits a
# JavaScript-only redirect. These stubs use a meta refresh with a canonical
# link, which search engines and text browsers both understand.
set -euo pipefail

output_dir="${QUARTO_PROJECT_OUTPUT_DIR:-build}"
cd "$output_dir"

rm -rf blog

find index.html about.html posts -name '*.html' -type f | while read -r page; do
    mkdir -p "blog/$(dirname "$page")"
    cat > "blog/$page" <<EOF
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <title>Moved</title>
    <link rel="canonical" href="/$page" />
    <meta http-equiv="refresh" content="0; url=/$page" />
  </head>
  <body>
    <p>This page has moved to <a href="/$page">/$page</a>.</p>
  </body>
</html>
EOF
done

echo "post-render: wrote $(find blog -name '*.html' | wc -l) redirect stubs under /blog/"
