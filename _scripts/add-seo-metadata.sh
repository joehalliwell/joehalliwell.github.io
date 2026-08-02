#!/usr/bin/env bash
# Tell crawlers which URLs exist and what each page's real address is.
#
# Three jobs, all of which need the finished build rather than the source tree,
# and all of which share one definition of "the canonical URL for this file":
#
#   1. A <link rel="canonical"> in every page that lacks one.
#   2. A sitemap covering the legacy pages as well as the rendered ones.
#      Quarto's own sitemap lists only what it rendered -- ten pages -- while
#      the site serves the whole of _legacy/ too, so the rest was invisible.
#   3. A robots.txt with an actual User-agent group. Quarto writes the file
#      with a bare Sitemap: line, which is technically malformed.
#
# Runs last in post-render: copy-legacy.sh has to have put the legacy pages in
# place, and make-blog-redirects.sh has to have written its stubs, before we
# can tell which files are which.
set -euo pipefail

output_dir="${QUARTO_PROJECT_OUTPUT_DIR:-build}"
project_dir="$(cd "$(dirname "$0")/.." && pwd)"
legacy_dir="$project_dir/_legacy"

# Single source of truth for the origin: whatever _quarto.yml publishes under.
site_url="$(sed -n 's|^ *site-url: *||p' "$project_dir/_quarto.yml" | head -1)"
site_url="${site_url%/}"
if [ -z "$site_url" ]; then
    echo "post-render: no site-url in _quarto.yml, cannot build canonical URLs" >&2
    exit 1
fi

# The URL a given built file should be indexed under. Directory indexes are
# normalised to the bare directory, because that is the form people link to and
# a canonical that disagrees with your inbound links is a canonical that loses.
canonical_url() {
    local path="${1#./}"
    case "$path" in
        index.html) path="" ;;
        */index.html) path="${path%index.html}" ;;
    esac
    printf '%s/%s' "$site_url" "$path"
}

# Pages that exist but should not be advertised. Everything not matched here is
# included, so a legacy page added later is listed by default -- the safer way
# round to be wrong.
listable() {
    case "$1" in
        # Redirect stubs. Each already points a canonical at its target; listing
        # them would invite indexing of the old URL we are retiring.
        blog/*) return 1 ;;
        # Vendored reveal.js machinery inside the talk decks, not pages.
        */plugin/*) return 1 ;;
        # Search Console ownership token.
        google*.html) return 1 ;;
        # Placeholders and test pages, thin by construction.
        empty.html|blank.html|ad-widget.html|bland.html) return 1 ;;
        # Reflects its query string into its own title and body, so it is not a
        # page with content of its own. Also carries a noindex.
        tools/echo.html) return 1 ;;
        # Error page: served on demand, never a destination.
        404.html) return 1 ;;
        # Personal. Reachable by anyone who has the link, but kept out of the
        # index deliberately -- delete this line to list them.
        family/*) return 1 ;;
    esac
    return 0
}

cd "$output_dir"

# --- 1. Canonical links ------------------------------------------------------

canonicalised=0
skipped_headless=()
while IFS= read -r -d '' page; do
    page="${page#./}"
    case "$page" in
        blog/*) continue ;;  # stubs ship their own canonical
    esac
    grep -qi 'rel="canonical"' "$page" && continue
    if ! grep -qi '</head>' "$page"; then
        skipped_headless+=("$page")
        continue
    fi
    awk -v link="<link rel=\"canonical\" href=\"$(canonical_url "$page")\" />" '
        !inserted && /<\/head>/ { print link; inserted = 1 }
        { print }
    ' "$page" > "$page.seotmp"
    mv "$page.seotmp" "$page"
    canonicalised=$((canonicalised + 1))
done < <(find . -name '*.html' -type f -print0)

# --- 2. Sitemap --------------------------------------------------------------
#
# Quarto's entries are kept verbatim apart from the index.html normalisation,
# so their <lastmod> survives. The legacy files get no <lastmod> at all: git
# does not preserve mtimes, so anything we could derive would be the time of
# the last checkout rather than the time the page changed, and a lastmod that
# lies is worse than one that is absent.

quarto_locs="$(mktemp)"
trap 'rm -f "$quarto_locs"' EXIT

{
    echo '<?xml version="1.0" encoding="UTF-8"?>'
    echo '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">'

    sed -e 's|<loc>\(.*\)/index\.html</loc>|<loc>\1/</loc>|' sitemap.xml \
        | sed -n '/<url>/,/<\/url>/p'

    grep -o '<loc>[^<]*</loc>' sitemap.xml \
        | sed -e 's|<loc>||; s|</loc>||' -e 's|/index\.html$|/|' > "$quarto_locs"

    # Anything from _legacy/ that is worth indexing and that Quarto did not
    # already list. PDFs are included: Google indexes them, and the thesis and
    # the CV are both things worth being findable.
    while IFS= read -r -d '' file; do
        relative="${file#"$legacy_dir"/}"
        listable "$relative" || continue
        url="$(canonical_url "$relative")"
        grep -qxF "$url" "$quarto_locs" && continue
        printf '  <url>\n    <loc>%s</loc>\n  </url>\n' "$url"
    done < <(find "$legacy_dir" \( -name '*.html' -o -name '*.pdf' \) -type f -print0 | sort -z)

    echo '</urlset>'
} > sitemap.xml.new
mv sitemap.xml.new sitemap.xml

# --- 3. robots.txt -----------------------------------------------------------
#
# Everything is allowed. To keep a crawler out -- an AI training scraper, say --
# add a group of its own above the wildcard.
cat > robots.txt <<EOF
User-agent: *
Allow: /

Sitemap: $site_url/sitemap.xml
EOF

echo "post-render: added $canonicalised canonical links; sitemap lists $(grep -c '<loc>' sitemap.xml) URLs"
if [ "${#skipped_headless[@]}" -gt 0 ]; then
    echo "post-render: no </head>, so no canonical: ${skipped_headless[*]}" >&2
fi
