#!/usr/bin/env bash
#
# Report what the text column *actually* renders at, in characters.
#
# The measure is the one number the whole sheet is built on, and it fails
# silently: if the grid track is narrower than --measure, the column is clipped
# and the page still looks entirely plausible. That is how it spent a while
# serving 57ch while claiming 62. Numbers, not eyes.
#
# Usage: _scripts/measure-column.sh [page-path] [viewport-width]
#   e.g. _scripts/measure-column.sh posts/rust-tools/index.html 1280

set -euo pipefail

PAGE="${1:-posts/rust-tools/index.html}"
WIDTH="${2:-1280}"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD="$ROOT/build"
[ -f "$BUILD/$PAGE" ] || { echo "no $BUILD/$PAGE -- run 'just render' first" >&2; exit 1; }

# The page has to be served over HTTP, not file://: the @font-face rules use
# absolute paths, and the measurement is meaningless in a fallback face.
# An ephemeral port, because a previous run's server lingering on a fixed one
# is otherwise indistinguishable from the probe failing.
PORT="$(python3 -c 'import socket;s=socket.socket();s.bind(("127.0.0.1",0));print(s.getsockname()[1]);s.close()')"

# The probe has to live beside its page so the relative asset paths resolve.
PROBE_ABS="$BUILD/$(dirname "$PAGE")/_probe.html"
PROBE_URL="$(dirname "$PAGE")/_probe.html"

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
  // Two samples, deliberately. The lead-in paragraphs are direct children of
  // main.content; everything after the first heading is nested in a <section>.
  // A selector that reaches one and not the other is the exact bug this script
  // failed to catch when it only sampled the first, so measure both and
  // compare -- they must agree.
  var lead = document.querySelector('main.content > p');
  var nested = document.querySelector('main.content section p');
  var p = lead || nested;
  if (!p) { out.textContent = 'ERROR no paragraph found'; document.body.appendChild(out); return; }
  var cs = getComputedStyle(p);
  var w  = p.getBoundingClientRect().width;
  var nestedW = nested ? nested.getBoundingClientRect().width : null;
  // Resolve the real ch unit by asking the browser, not by assuming 0.5em.
  var probe = document.createElement('div');
  probe.style.cssText = 'width:100ch;position:absolute;visibility:hidden';
  p.appendChild(probe);
  var ch = probe.getBoundingClientRect().width / 100;
  probe.remove();
  var asked = parseFloat(cs.maxInlineSize);
  var sn = document.querySelector('.column-margin');
  var rows = [
    ['root',       getComputedStyle(document.documentElement).fontSize],
    ['body',       cs.fontSize],
    ['lineHeight', cs.lineHeight],
    ['ch',         ch.toFixed(3) + 'px'],
    ['askedFor',   cs.maxInlineSize],
    ['leadCh',     (w/ch).toFixed(1)],
    ['nestedCh',   nestedW === null ? 'n/a' : (nestedW/ch).toFixed(1)],
    ['agree',      (nestedW === null || Math.abs(nestedW - w) < 2) ? 'yes' : 'NO -- selector misses nested sections'],
    ['rendered',   Math.round(w) + 'px'],
    ['clipped',    (isFinite(asked) && Math.round(w) < Math.round(asked) - 1) ? 'YES' : 'no'],
    ['sidenote',   sn ? Math.round(sn.getBoundingClientRect().width) + 'px' : 'none']
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
