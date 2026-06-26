#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_FILE="$ROOT_DIR/ios/ReCall.xcodeproj/project.pbxproj"
SCHEME_FILE="$ROOT_DIR/ios/ReCall.xcodeproj/xcshareddata/xcschemes/ReCall.xcscheme"

TEAM_ID="$(awk -F'= ' '/DEVELOPMENT_TEAM =/ { gsub(/[;[:space:]]/, "", $2); print $2; exit }' "$PROJECT_FILE")"
BUNDLE_ID="$(awk -F'= ' '/PRODUCT_BUNDLE_IDENTIFIER =/ && $0 !~ /uitests/ { gsub(/[;[:space:]]/, "", $2); print $2; exit }' "$PROJECT_FILE")"

echo "TestFlight readiness: Re_Call"
echo "Team: ${TEAM_ID:-missing}"
echo "Bundle id: ${BUNDLE_ID:-missing}"
echo
"$ROOT_DIR/scripts/agent-signing-report.sh" || rc=$?
if [ "${rc:-0}" -ne 0 ]; then
  exit "$rc"
fi

if [ ! -f "$SCHEME_FILE" ]; then
  echo "FAIL: ReCall scheme is not shared."
  exit 1
fi

if [ -z "${TEAM_ID:-}" ] || [ -z "${BUNDLE_ID:-}" ]; then
  echo "FAIL: missing team or bundle id."
  exit 1
fi

if [ "$TEAM_ID" = "7FKUS5M5QS" ]; then
  echo "BLOCKED: project is signed with Adam's Personal Team."
  echo "Local builds can pass, but TestFlight requires an Apple Developer Program/App Store Connect team."
  echo "Move this bundle id to the paid team in Xcode/App Store Connect before expecting TestFlight delivery."
  exit 2
fi

missing_auth=0
for var in APP_STORE_CONNECT_API_KEY_ID APP_STORE_CONNECT_API_ISSUER_ID APP_STORE_CONNECT_API_KEY_PATH; do
  if [ -z "${!var:-}" ]; then
    echo "MISSING: $var"
    missing_auth=1
  fi
done

if [ "$missing_auth" -ne 0 ]; then
  echo "BLOCKED: App Store Connect API credentials are not configured for CLI upload/status checks."
  exit 3
fi

echo "Ready for Apple-side archive/upload checks."
