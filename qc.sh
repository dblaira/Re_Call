#!/usr/bin/env bash
# Notorious Recall — quality control for the NATIVE iOS app.
#
#   ./qc.sh           Layers 1+2 (engine logic + native build)     ~1 min
#   ./qc.sh --full    Layers 1+2+3 (adds native device smoke)      ~3 min
#
# Layer 1  Engine        recommendation/ontology engine unit tests + KG -> recommendations.js compile
# Layer 2  Build         the native SwiftUI app compiles for the simulator
# Layer 3  Device smoke  app boots on a simulator and the native entry flow works (XCUITest)
#
# ---------------------------------------------------------------------------
# RETIRED 2026-06-17 — the old web/WebView QC layers were removed:
#   * "Behavior (Playwright vs bundled HTML, WebKit)"        — the app no longer renders a WebView
#   * "Bundle integrity (data-src-md5 stamp in index.html)"  — nothing bundles ios/ReCall/Web/*
#
# Re_Call is native SwiftUI only (see HANDOFF.md "Native-only rule"). WebView.swift and
# ios/ReCall/Web/* remain in the repo as legacy/reference and are intentionally NOT verified here.
# They were giving permanent false-red ("bundle is STALE", "renders web UI") that had nothing to
# do with the native app. Do NOT re-add web QC unless a WebView becomes a runtime surface again.
# ---------------------------------------------------------------------------
#
# Trust contract: "it works" == this script prints all-green for the layers you ran.
set -uo pipefail
cd "$(dirname "$0")"

# xcode-select often points at CommandLineTools; full Xcode is required to build the app.
if [ -d "/Applications/Xcode.app/Contents/Developer" ]; then
  export DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"
fi

DD="$HOME/Library/Developer/Xcode/DerivedData/ReCall-QC"
PASS=()
FAIL=()

step() { printf "\n\033[1m== %s ==\033[0m\n" "$1"; }
ok()   { PASS+=("$1"); printf "\033[32mPASS\033[0m %s\n" "$1"; }
bad()  { FAIL+=("$1"); printf "\033[31mFAIL\033[0m %s\n" "$1"; }

# ---------- Layer 1: engine (node) ----------
step "Layer 1/3 — recommendation/ontology engine (node)"
if npm test --silent >/dev/null 2>&1; then ok "engine unit tests"; else bad "engine unit tests"; fi

# recommendations.js must be the deterministic compile of the current KG.
REC=build/recommendations.js
BEFORE=$(md5 -q "$REC" 2>/dev/null || echo none)
node scripts/build-recommendations.mjs >/dev/null 2>&1
AFTER=$(md5 -q "$REC" 2>/dev/null || echo none)
if [ "$BEFORE" = "$AFTER" ]; then
  ok "recommendations.js current with KG"
else
  ok "recommendations.js regenerated from KG (was stale — now current)"
fi

# ---------- Layer 2: native build ----------
step "Layer 2/3 — native build"
xattr -cr ios/ReCall >/dev/null 2>&1
BUILD_LOG=$(xcodebuild -project ios/ReCall.xcodeproj -scheme ReCall \
     -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' \
     -derivedDataPath "$DD" build 2>&1)
if [ $? -eq 0 ]; then
  ok "build"
else
  echo "$BUILD_LOG" | grep -E "error:|FAILED|No available simulator" | head -5
  bad "build"
fi

# ---------- Layer 3: native device smoke (--full) ----------
if [ "${1:-}" = "--full" ]; then
  step "Layer 3/3 — native device smoke (XCUITest, simulator)"
  SIM_LINE=$(xcrun simctl list devices available | grep "iPhone" | tail -1)
  SIM_ID=$(echo "$SIM_LINE" | grep -oE "[0-9A-F-]{36}" | head -1)
  echo "using simulator: $SIM_LINE"
  TEST_LOG=$(xcodebuild -project ios/ReCall.xcodeproj -scheme ReCall \
       -sdk iphonesimulator \
       -destination "platform=iOS Simulator,id=$SIM_ID" \
       -derivedDataPath "$DD" test 2>&1)
  TEST_RC=$?
  echo "$TEST_LOG" | grep -E "Test Suite|Test Case.*(passed|failed)|TEST" | tail -8
  if [ $TEST_RC -eq 0 ]; then ok "device smoke"; else bad "device smoke"; fi
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
  printf "\n\033[32mQC GREEN\033[0m — sha: %s\n" "$(git rev-parse --short HEAD)$( [ -n "$(git status --porcelain)" ] && echo '*' )"
fi
