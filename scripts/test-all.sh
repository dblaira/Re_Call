#!/usr/bin/env bash
# Run all Re_Call tests from the correct directory with the right browser setup.
set -euo pipefail
cd "$(dirname "$0")/.."

export PLAYWRIGHT_HOST_PLATFORM_OVERRIDE=mac15-arm64

echo "== Re_Call tests (from $(pwd)) =="
echo ""

echo "→ Unit + recommendation engine tests"
npm test

echo ""
echo "→ Playwright browser install (if needed)"
bash scripts/install-playwright-browsers.sh

echo ""
echo "→ Web UI behavior tests"
bash scripts/test-web.sh
