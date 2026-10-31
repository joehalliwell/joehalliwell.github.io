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
project_dir="$(cd "$(dirname "$0")/.." && pwd)"

# The canonical has to be absolute, as add-seo-metadata.sh writes them; the
# origin comes from the same place it does.
site_url="$(sed -n 's|^ *site-url: *||p' "$project_dir/_quarto.yml" | head -1)"
site_url="${site_url%/}"
if [ -z "$site_url" ]; then
    echo "post-render: no site-url in _quarto.yml, cannot build canonical URLs" >&2
    exit 1
fi

cd "$output_dir"

rm -rf blog

find index.html about.html posts -name '*.html' -type f | while read -r page; do
    # Point at the same URL add-seo-metadata.sh canonicalises the target to.
    # Two spellings of one page's canonical URL is worse than either spelling.
    case "$page" in
        index.html) target="/" ;;
        */index.html) target="/${page%index.html}" ;;
        *) target="/$page" ;;
    esac

    mkdir -p "blog/$(dirname "$page")"
    cat > "blog/$page" <<EOF
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <title>Moved</title>
    <link rel="canonical" href="$site_url$target" />
    <meta http-equiv="refresh" content="0; url=$target" />
  </head>
  <body>
    <p>This page has moved to <a href="$target">$target</a>.</p>
  </body>
</html>
EOF
done

echo "post-render: wrote $(find blog -name '*.html' | wc -l) redirect stubs under /blog/"
