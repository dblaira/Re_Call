#!/usr/bin/env bash
# Install Playwright browsers for this Mac. macOS 26 needs arm64 fallbacks + Firefox.
set -euo pipefail
cd "$(dirname "$0")/.."

export PLAYWRIGHT_HOST_PLATFORM_OVERRIDE=mac15-arm64

darwin_major=$(uname -r | cut -d. -f1)
if [ "$darwin_major" -ge 25 ]; then
  echo "macOS 26+ detected — installing Firefox (headed; WebKit/Chromium crash on Tahoe)."
  npx playwright install firefox
else
  echo "Installing WebKit + Chromium for behavior tests."
  npx playwright install webkit chromium
fi
