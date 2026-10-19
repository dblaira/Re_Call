#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PRO_TEST_DIR="$(mktemp -d)"
trap 'rm -rf "$PRO_TEST_DIR"' EXIT
xcrun swiftc -parse-as-library \
  "$ROOT/ios/ReCall/App/ProImageArchive.swift" \
  "$ROOT/ios/ReCall/App/ProLibraryArrangement.swift" \
  "$ROOT/test/pro-image-runtime.swift" \
  -o "$PRO_TEST_DIR/pro-image-tests"
"$PRO_TEST_DIR/pro-image-tests"
