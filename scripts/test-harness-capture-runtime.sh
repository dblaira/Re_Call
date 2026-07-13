#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BIN="$(mktemp -d)/harness-capture-runtime-tests"
trap 'rm -rf "$(dirname "$BIN")"' EXIT

xcrun swiftc -parse-as-library \
  "$ROOT/ios/ReCall/App/Models.swift" \
  "$ROOT/ios/ReCall/App/ICloudReminderCache.swift" \
  "$ROOT/test/harness-capture-runtime.swift" \
  -o "$BIN"

"$BIN"
