#!/usr/bin/env bash
set -euo pipefail
recall_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
recall_checks="$(mktemp -d)"
trap 'rm -rf "$recall_checks"' EXIT
xcrun swiftc -parse-as-library \
  "$recall_root/ios/ReCall/App/Models.swift" \
  "$recall_root/ios/ReCall/App/VisualTemplate.swift" \
  "$recall_root/ios/ReCall/App/PostTheme.swift" \
  "$recall_root/ios/ReCall/App/ICloudReminderCache.swift" \
  "$recall_root/ios/ReCall/App/EntryShareContent.swift" \
  "$recall_root/test/visual-template-runtime.swift" \
  -o "$recall_checks/checks"
"$recall_checks/checks" RECALL_UI_TEST_ISOLATED
