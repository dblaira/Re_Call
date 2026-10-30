#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TITLE_TEST_DIR="$(mktemp -d)"
trap 'rm -rf "$TITLE_TEST_DIR"' EXIT
xcrun swiftc -parse-as-library \
  "$ROOT/ios/ReCall/App/Models.swift" \
  "$ROOT/ios/ReCall/App/VisualTemplate.swift" \
  "$ROOT/ios/ReCall/App/ICloudReminderCache.swift" \
  "$ROOT/ios/ReCall/App/CardTitleStore.swift" \
  "$ROOT/test/card-title-runtime.swift" \
  -o "$TITLE_TEST_DIR/card-title-tests"
"$TITLE_TEST_DIR/card-title-tests" RECALL_UI_TEST_ISOLATED
