#!/usr/bin/env bash
#
# Report how deep the ragged right edge actually runs, in px and in characters.
#
# The rag is the number that decides whether ranged-left survives at this
# measure. Justification used to hide it; nothing hides it now, and it fails the
# same silent way the measure does -- the page still looks entirely plausible
# while the right-hand gutter reads three times the left. The note in styles.scss
# records a 102px median at 80ch as the state that drove the sheet to justify, so
# that is the number to beat.
#
# Last lines of paragraphs are excluded: a last line is short because the
# paragraph ended, which is not rag, and including them buries the signal.
#
# Usage: _scripts/measure-rag.sh [page-path] [viewport-width]

set -euo pipefail

PAGE="${1:-posts/rust-tools/index.html}"
WIDTH="${2:-1440}"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD="$ROOT/build"
[ -f "$BUILD/$PAGE" ] || { echo "no $BUILD/$PAGE -- run 'just render' first" >&2; exit 1; }

PORT="$(python3 -c 'import socket;s=socket.socket();s.bind(("127.0.0.1",0));print(s.getsockname()[1]);s.close()')"

PROBE_ABS="$BUILD/$(dirname "$PAGE")/_rag.html"
PROBE_URL="$(dirname "$PAGE")/_rag.html"

SERVER=""
cleanup() {
  [ -n "$SERVER" ] && kill "$SERVER" 2>/dev/null || true
  rm -f "$PROBE_ABS"
}
trap cleanup EXIT

python3 - "$BUILD/$PAGE" "$PROBE_ABS" <<'PY'
import sys
src, dst = sys.argv[1], sys.argv[2]
probe = """
<script>
window.addEventListener('load', function(){
  var out = document.createElement('div');
  out.id = 'PROBE';
  // Line boxes come from Range rects, not from anything in the CSS: walk the
  // text nodes of each paragraph and let the browser report where the lines
  // actually broke.
  var shortfalls = [], lines = 0, paras = 0;
  var ch = null;
  document.querySelectorAll('main.content > p, main.content section > p').forEach(function(p){
    if (p.closest('.column-margin') || p.querySelector('img')) return;
    var right = p.getBoundingClientRect().left + parseFloat(getComputedStyle(p).maxInlineSize || p.getBoundingClientRect().width);
    if (ch === null) {
      var probe = document.createElement('div');
      probe.style.cssText = 'width:100ch;position:absolute;visibility:hidden';
      p.appendChild(probe);
      ch = probe.getBoundingClientRect().width / 100;
      probe.remove();
    }
    var r = document.createRange();
    r.selectNodeContents(p);
    var rects = Array.from(r.getClientRects()).filter(function(x){ return x.width > 1; });
    if (rects.length < 2) return;
    paras++;
    // Group rects into line boxes by vertical centre, bucketed to the line
    // height. Keying on `top` instead looks right and is not: a <sup> or an
    // inline <code> at a different font-size has a different rect top on the
    // very same visual line, so each one splits that line into extra fragments
    // whose right edge is wherever the fragment happened to end. That reads as
    // a huge rag and is entirely an artefact -- it is what put p90 at 665px on
    // a page whose median was 59.
    var lh = parseFloat(getComputedStyle(p).lineHeight);
    var byLine = {};
    rects.forEach(function(x){
      var k = Math.round((x.top + x.height / 2) / lh);
      byLine[k] = Math.max(byLine[k] === undefined ? -Infinity : byLine[k], x.right);
    });
    var tops = Object.keys(byLine).sort(function(a,b){ return a-b; });
    var byTop = byLine;
    // Drop the last line of the paragraph.
    tops.slice(0, -1).forEach(function(k){
      lines++;
      shortfalls.push(right - byTop[k]);
    });
  });
  if (!shortfalls.length) { out.textContent = 'ERROR no lines measured'; document.body.appendChild(out); return; }
  shortfalls.sort(function(a,b){ return a-b; });
  function pct(q){ return shortfalls[Math.min(shortfalls.length-1, Math.floor(shortfalls.length*q))]; }
  var mean = shortfalls.reduce(function(a,b){ return a+b; }, 0) / shortfalls.length;
  var rows = [
    ['paragraphs', paras],
    ['lines',      lines],
    ['ch',         ch.toFixed(2) + 'px'],
    ['median',     pct(0.5).toFixed(0) + 'px (' + (pct(0.5)/ch).toFixed(1) + 'ch)'],
    ['mean',       mean.toFixed(0) + 'px'],
    ['p90',        pct(0.9).toFixed(0) + 'px (' + (pct(0.9)/ch).toFixed(1) + 'ch)'],
    ['worst',      shortfalls[shortfalls.length-1].toFixed(0) + 'px'],
    ['over 60px',  (100*shortfalls.filter(function(x){ return x > 60; }).length/shortfalls.length).toFixed(0) + '%']
  ];
  out.textContent = rows.map(function(r){ return r[0] + '=' + r[1]; }).join(' | ');
  document.body.appendChild(out);
});
</script>
"""
open(dst, 'w').write(open(src).read().replace('</head>', probe + '</head>'))
PY

python3 -m http.server "$PORT" --bind 127.0.0.1 --directory "$BUILD" >/dev/null 2>&1 &
SERVER=$!

for _ in $(seq 1 40); do
  curl -sf -o /dev/null "http://127.0.0.1:$PORT/$PROBE_URL" && break
  sleep 0.25
done

DOM="$(flatpak run com.google.Chrome --headless=new --disable-gpu --no-sandbox \
  --window-size="$WIDTH",2000 --virtual-time-budget=6000 \
  --dump-dom "http://127.0.0.1:$PORT/$PROBE_URL" 2>/dev/null || true)"

RESULT="$(printf '%s' "$DOM" | grep -o 'id="PROBE">[^<]*' | sed 's/id="PROBE">//' || true)"

if [ -z "$RESULT" ]; then
  echo "probe produced nothing (page ${#DOM} bytes) -- is Chrome available?" >&2
  exit 1
fi

echo "$PAGE @ ${WIDTH}px"
printf '%s\n' "$RESULT" | tr '|' '\n' | sed 's/^ */  /'
