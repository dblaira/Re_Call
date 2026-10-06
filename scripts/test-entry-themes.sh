#!/usr/bin/env bash
set -euo pipefail
recall_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
recall_checks="$(mktemp -d)"
trap 'rm -rf "$recall_checks"' EXIT
swiftc "$recall_root/ios/ReCall/App/Models.swift" \
  "$recall_root/ios/ReCall/App/PostTheme.swift" \
  "$recall_root/scripts/entry-theme-checks.swift" -o "$recall_checks/checks"
"$recall_checks/checks"
