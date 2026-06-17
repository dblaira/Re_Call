#!/usr/bin/env bash
# Web behavior tests. On macOS 26, Playwright browsers crash — bundle tests cover the deck instead.
set -euo pipefail
cd "$(dirname "$0")/.."

export PLAYWRIGHT_HOST_PLATFORM_OVERRIDE=mac15-arm64
node scripts/stamp-web.mjs

darwin_major=$(uname -r | cut -d. -f1)
if [ "$darwin_major" -ge 25 ]; then
  echo ""
  echo "macOS 26+: skipping Playwright (browsers crash on Tahoe)."
  echo "Running bundle behavior tests instead..."
  echo ""
  node --test test/web-bundle.test.js
  echo ""
  echo "Web behavior: PASS (bundle tests)"
  exit 0
fi

npx playwright test "$@"
