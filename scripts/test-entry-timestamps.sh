#!/usr/bin/env bash
set -euo pipefail
entry_root="$(cd "$(dirname "$0")/.." && pwd)"
entry_checks="$(mktemp -d)"
trap 'rm -rf "$entry_checks"' EXIT
xcrun swiftc -parse-as-library \
  "$entry_root/ios/ReCall/App/Models.swift" \
  "$entry_root/ios/ReCall/App/VisualTemplate.swift" \
  "$entry_root/ios/ReCall/App/PostTheme.swift" \
  "$entry_root/ios/ReCall/App/ICloudReminderCache.swift" \
  "$entry_root/ios/ReCall/App/CardTitleStore.swift" \
  "$entry_root/ios/ReCall/App/ReminderStore.swift" \
  "$entry_root/ios/ReCall/App/EntryShareContent.swift" \
  "$entry_root/test/entry-timestamps-runtime.swift" \
  -o "$entry_checks/checks"
"$entry_checks/checks" RECALL_UI_TEST_ISOLATED
