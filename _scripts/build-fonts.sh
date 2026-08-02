#!/usr/bin/env bash
#
# Rebuild the subsetted Source Serif 4 variable fonts in assets/fonts/.
#
# The theme depends on features most webfont subsets throw away: real small
# caps (smcp/c2sc), real old-style figures (onum), and the opsz axis that makes
# `font-optical-sizing: auto` mean something. Google's hosted copy of this face
# does not carry them, so we self-host and cut our own subset.
#
# Idempotent: safe to re-run, overwrites its own output.

set -euo pipefail

VERSION="4.005R"
DIST="4.005"
URL="https://github.com/adobe-fonts/source-serif/releases/download/${VERSION}/source-serif-${DIST}_WOFF2.zip"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="$ROOT/assets/fonts"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# Latin-1 plus the typographic punctuation the posts actually use: curly
# quotes, en/em dashes, ellipsis, bullet, dagger, arrows, minus. No Greek, no
# Cyrillic -- they roughly double the file for glyphs nothing here sets.
UNICODES='U+0000-00FF,U+0131,U+0152-0153,U+02BB-02BC,U+02C6,U+02DA,U+02DC,U+2000-206F,U+2074,U+20AC,U+2122,U+2190-2193,U+2212,U+2215,U+2039-203A,U+2010-2015,U+2018-201F,U+2020-2022,U+2026,U+2030,U+FEFF,U+FFFD'

# smcp/c2sc and onum are the whole point -- pyftsubset drops every feature not
# named here, and with them the small-cap and old-style glyphs they reference.
FEATURES='kern,liga,smcp,c2sc,onum,lnum,tnum,pnum,case,frac,sups,subs,ccmp,locl,mark,mkmk,calt'

echo "Fetching Source Serif ${VERSION}..."
curl -sSL --fail --max-time 120 -o "$WORK/src.zip" "$URL"
unzip -q -o "$WORK/src.zip" -d "$WORK"

VAR="$WORK/source-serif-${DIST}_WOFF2/VAR"

mkdir -p "$OUT"
for cut in Roman Italic; do
  echo "Subsetting $cut..."
  uv run --quiet --with fonttools --with brotli -- \
    pyftsubset "$VAR/SourceSerif4Variable-$cut.otf.woff2" \
      --output-file="$OUT/SourceSerif4Var-$cut.subset.woff2" \
      --flavor=woff2 \
      --unicodes="$UNICODES" \
      --layout-features="$FEATURES" \
      --name-IDs='*' --name-legacy \
      --notdef-outline --recommended-glyphs
done

cp "$WORK/source-serif-${DIST}_WOFF2/../"LICENSE* "$OUT/" 2>/dev/null || \
  curl -sSL --fail -o "$OUT/LICENSE.md" \
    https://raw.githubusercontent.com/adobe-fonts/source-serif/release/LICENSE.md

ls -l "$OUT"
