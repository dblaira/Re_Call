#!/usr/bin/env bash
# Notorious Recall — quality control, three independent layers.
#
#   ./qc.sh           Layers 1+2 (behavior + bundle integrity)   ~1 min
#   ./qc.sh --full    Layers 1+2+3 (adds device smoke test)      ~4 min
#
# Layer 1  Behavior      Playwright vs the bundled HTML, WebKit engine
# Layer 2  Integrity     built .app contains EXACTLY the current source
# Layer 3  Device smoke  app boots + renders web UI on a simulator
#
# Trust contract: "it works" == this script prints all-green AND the SHA
# shown in the app's corner matches `git rev-parse --short HEAD`.
set -uo pipefail
cd "$(dirname "$0")"

DD="$HOME/Library/Developer/Xcode/DerivedData/ReCall-QC"
APP="$DD/Build/Products/Debug-iphonesimulator/ReCall.app"
PASS=()
FAIL=()

step() { printf "\n\033[1m== %s ==\033[0m\n" "$1"; }
ok()   { PASS+=("$1"); printf "\033[32mPASS\033[0m %s\n" "$1"; }
bad()  { FAIL+=("$1"); printf "\033[31mFAIL\033[0m %s\n" "$1"; }

# ---------- Layer 1: engine + behavior ----------
step "Layer 1/3 — recommendation engine (node) + behavior (Playwright, WebKit)"
if npm test --silent >/dev/null 2>&1; then ok "engine unit tests"; else bad "engine unit tests"; fi

# recommendations.js must be the deterministic compile of the current KG
REC=ios/ReCall/Web/recommendations.js
BEFORE=$(md5 -q "$REC" 2>/dev/null || echo none)
node scripts/build-recommendations.mjs >/dev/null
AFTER=$(md5 -q "$REC")
if [ "$BEFORE" = "$AFTER" ]; then
  ok "recommendations.js current with KG"
else
  ok "recommendations.js regenerated from KG (was stale — now current)"
fi

if npx playwright test; then ok "behavior"; else bad "behavior"; fi

# ---------- Layer 2: build + bundle integrity ----------
step "Layer 2/3 — build + bundle integrity"
xattr -cr ios/ReCall >/dev/null 2>&1
BUILD_LOG=$(xcodebuild -project ios/ReCall.xcodeproj -scheme ReCall \
     -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' \
     -derivedDataPath "$DD" build 2>&1)
BUILD_RC=$?
if [ $BUILD_RC -ne 0 ]; then
  echo "$BUILD_LOG" | grep -E "error:|FAILED" | head -10
  bad "build (xcodebuild exit $BUILD_RC)"
else
  ok "build"
  SRC_MD5=$(cd ios/ReCall/Web && find . -type f ! -name ".*" | sort | xargs cat | md5 -q)
  EMBEDDED=$(grep -o 'data-src-md5="[a-f0-9]*"' "$APP/Web/index.html" 2>/dev/null | cut -d'"' -f2)
  BUILD_SHA=$(grep -o 'id="build-info"[^>]*>[^<]*' "$APP/Web/index.html" 2>/dev/null | sed 's/.*>//')
  if [ -n "$EMBEDDED" ] && [ "$EMBEDDED" = "$SRC_MD5" ]; then
    ok "bundle integrity (md5 $SRC_MD5, app shows: $BUILD_SHA)"
  else
    bad "bundle integrity — bundle is STALE (embedded=$EMBEDDED source=$SRC_MD5)"
  fi
fi

# ---------- Layer 3: device smoke (--full) ----------
if [ "${1:-}" = "--full" ]; then
  step "Layer 3/3 — device smoke (XCUITest, simulator)"
  SIM_LINE=$(xcrun simctl list devices available | grep "iPhone" | tail -1)
  SIM_ID=$(echo "$SIM_LINE" | grep -oE "[0-9A-F-]{36}" | head -1)
  echo "using simulator: $SIM_LINE"
  TEST_LOG=$(xcodebuild -project ios/ReCall.xcodeproj -scheme ReCall \
       -sdk iphonesimulator \
       -destination "platform=iOS Simulator,id=$SIM_ID" \
       -derivedDataPath "$DD" test 2>&1)
  TEST_RC=$?
  echo "$TEST_LOG" | grep -E "Test Suite|Test Case.*(passed|failed)|TEST" | tail -6
  if [ $TEST_RC -eq 0 ]; then
    ok "device smoke"
  else
    bad "device smoke"
  fi
else
  printf "\n(skipping Layer 3 device smoke — run ./qc.sh --full to include it)\n"
fi

# ---------- summary ----------
step "QC summary"
for p in "${PASS[@]:-}"; do [ -n "$p" ] && printf "  \033[32m✓\033[0m %s\n" "$p"; done
for f in "${FAIL[@]:-}"; do [ -n "$f" ] && printf "  \033[31m✗\033[0m %s\n" "$f"; done
if [ ${#FAIL[@]} -gt 0 ]; then
  printf "\n\033[31mQC FAILED\033[0m — do not ship.\n"; exit 1
else
  printf "\n\033[32mQC GREEN\033[0m — sha to verify on device: %s\n" "$(git rev-parse --short HEAD)$( [ -n "$(git status --porcelain)" ] && echo '*' )"
fi
