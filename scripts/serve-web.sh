#!/usr/bin/env bash
# Serve the bundled web UI for manual testing.
set -euo pipefail
cd "$(dirname "$0")/.."

node scripts/stamp-web.mjs
PORT="${PORT:-5179}"

echo "Open http://127.0.0.1:${PORT}/index.html"
python3 -m http.server "$PORT" --directory ios/ReCall/Web --bind 127.0.0.1
