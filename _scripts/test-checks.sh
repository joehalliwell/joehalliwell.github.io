#!/usr/bin/env bash
# Exercise the build checks against small fixture sites, so that a check which
# silently stops checking shows up here rather than in production.
#
# Each case plants a defect (or deliberately doesn't) and asserts the check's
# exit status. Run via `just test`.
set -euo pipefail

scripts="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
work="$(mktemp --directory)"
trap 'rm -rf "$work"' EXIT

failures=0
pass() { echo "ok   $1"; }
fail() { echo "FAIL $1"; failures=$((failures + 1)); }

# expect <0|1> <name> <command...>: 0 means the check should pass, 1 fail.
expect() {
    local want="$1" name="$2"
    shift 2
    if "$@" > "$work/out" 2>&1; then got=0; else got=1; fi
    if [ "$got" = "$want" ]; then pass "$name"; else fail "$name"; sed 's/^/     /' "$work/out"; fi
}

# --- check-served.sh ---------------------------------------------------------
#
# A stand-in for the gh-pages branch: a repo whose tree is "what's served".

served="$work/served"
git init --quiet "$served"
mkdir -p "$served/posts/old" "$served/site_libs"
touch "$served/index.html" "$served/posts/old/index.html" "$served/site_libs/bootstrap-abc.css"
git -C "$served" add --all
git -C "$served" -c user.name=t -c user.email=t@t commit --quiet --message served

build="$work/build"
mkdir -p "$build/posts/old"
touch "$build/index.html" "$build/posts/old/index.html"
retired="$work/retired.txt"
: > "$retired"

served_check() { GIT_DIR="$served/.git" bash "$scripts/check-served.sh" HEAD "$build" "$retired"; }

expect 0 "served: everything still built" served_check

rm "$build/posts/old/index.html"
expect 1 "served: a served page has gone missing" served_check
if grep --quiet 'posts/old/index.html' "$work/out"; then pass "served: names the missing page"; else fail "served: names the missing page"; fi

echo "posts/old/index.html  # retired on purpose" > "$retired"
expect 0 "served: a retired page may go missing" served_check

# site_libs/ is Quarto's, and its filenames change with Quarto versions.
expect 0 "served: site_libs churn is ignored" served_check

# A trailing slash retires a whole directory.
mkdir -p "$served/.claude/worktrees/x/assets"
touch "$served/.claude/worktrees/x/assets/font.woff2"
git -C "$served" add --all
git -C "$served" -c user.name=t -c user.email=t@t commit --quiet --message leak
expect 1 "served: a new served directory is checked" served_check
echo ".claude/" >> "$retired"
expect 0 "served: a retired directory may go missing" served_check

# --- check-hidden.sh ---------------------------------------------------------

hidden="$work/hidden"
mkdir -p "$hidden/posts"
touch "$hidden/index.html" "$hidden/.nojekyll"
hidden_check() { bash "$scripts/check-hidden.sh" "$hidden"; }

expect 0 "hidden: dotfiles at the root are fine" hidden_check
mkdir -p "$hidden/.claude/worktrees/x/assets"
touch "$hidden/.claude/worktrees/x/assets/font.woff2"
expect 1 "hidden: a hidden directory in the build" hidden_check

# --- check-headings.sh -------------------------------------------------------

site="$work/site"
legacy="$work/legacy"
mkdir -p "$site/posts" "$site/blog/posts" "$legacy"
echo '<h2>a</h2><h3>b</h3>' > "$site/posts/fine.html"
headings_check() { bash "$scripts/check-headings.sh" "$site" "$legacy"; }

expect 0 "headings: h2 and h3 only" headings_check

# A notebook or .md post renders to HTML like any other; that is the point of
# checking the output rather than the .qmd sources.
echo '<h4 class="anchored">deep</h4>' > "$site/posts/notebook.html"
expect 1 "headings: an h4 in a rendered page" headings_check
rm "$site/posts/notebook.html"

# Legacy pages and redirect stubs are not ours to restyle.
echo '<h5>old</h5>' > "$legacy/old.html"
cp "$legacy/old.html" "$site/old.html"
echo '<h4>stub</h4>' > "$site/blog/posts/fine.html"
expect 0 "headings: legacy pages and blog stubs are exempt" headings_check

# --- make-blog-redirects.sh --------------------------------------------------

out="$work/redirects"
mkdir -p "$out/posts/x"
touch "$out/index.html" "$out/about.html" "$out/posts/x/index.html"
QUARTO_PROJECT_OUTPUT_DIR="$out" bash "$scripts/make-blog-redirects.sh" > /dev/null

site_url="$(sed -n 's|^ *site-url: *||p' "$scripts/../_quarto.yml" | head -1)"
site_url="${site_url%/}"
stub="$out/blog/posts/x/index.html"
if grep --quiet "rel=\"canonical\" href=\"$site_url/posts/x/\"" "$stub"; then
    pass "redirects: canonical is absolute"
else
    fail "redirects: canonical is absolute"; grep canonical "$stub" | sed 's/^/     /'
fi

echo
if [ "$failures" -gt 0 ]; then
    echo "$failures check test(s) failed" >&2
    exit 1
fi
echo "All check tests passed"
