#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_FILE="$ROOT_DIR/ios/ReCall.xcodeproj/project.pbxproj"
SCHEME_FILE="$ROOT_DIR/ios/ReCall.xcodeproj/xcshareddata/xcschemes/ReCall.xcscheme"
APP_NAME="Re_Call"

extract_first() {
  local pattern="$1"
  awk -F'= ' "$pattern"' { gsub(/[;[:space:]]/, "", $2); print $2; exit }' "$PROJECT_FILE"
}

TEAM_ID="$(extract_first '/DEVELOPMENT_TEAM =/')"
BUNDLE_ID="$(extract_first '/PRODUCT_BUNDLE_IDENTIFIER =/ && $0 !~ /uitests/')"
CODE_SIGN_STYLE="$(extract_first '/CODE_SIGN_STYLE =/')"
PROVISIONING_PROFILE_SPECIFIER="$(extract_first '/PROVISIONING_PROFILE_SPECIFIER =/')"

echo "# $APP_NAME Signing Report"
echo
echo "Project: $PROJECT_FILE"
echo "Shared scheme: $SCHEME_FILE"
echo "Scheme present: $([ -f "$SCHEME_FILE" ] && echo yes || echo no)"
echo "Bundle id: ${BUNDLE_ID:-missing}"
echo "Development team: ${TEAM_ID:-missing}"
echo "Code sign style: ${CODE_SIGN_STYLE:-missing}"
echo "Provisioning profile specifier: ${PROVISIONING_PROFILE_SPECIFIER:-automatic-or-missing}"
echo
echo "App Store Connect API environment:"
for var in APP_STORE_CONNECT_API_KEY_ID APP_STORE_CONNECT_API_ISSUER_ID APP_STORE_CONNECT_API_KEY_PATH; do
  if [ -n "${!var:-}" ]; then
    echo "- $var: set"
  else
    echo "- $var: missing"
  fi
done
echo

if [ -z "${TEAM_ID:-}" ] || [ -z "${BUNDLE_ID:-}" ]; then
  echo "Status: NOT READY"
  echo "Reason: missing DEVELOPMENT_TEAM or PRODUCT_BUNDLE_IDENTIFIER."
  exit 1
fi

if [ "$TEAM_ID" = "7FKUS5M5QS" ]; then
  echo "Status: WAITING ON APPLE-SIDE SIGNING"
  echo "Reason: this is Adam's Personal Team. TestFlight requires an Apple Developer Program/App Store Connect team."
  echo
  echo "Next Apple-side action:"
  echo "1. Open the project in Xcode."
  echo "2. Select the ReCall app target."
  echo "3. Set Signing & Capabilities > Team to the App Store Connect-capable team."
  echo "4. Confirm the bundle id exists in App Store Connect: ${BUNDLE_ID}."
  echo "5. Re-run ./scripts/agent-testflight-readiness.sh."
  exit 2
fi

missing_auth=0
for var in APP_STORE_CONNECT_API_KEY_ID APP_STORE_CONNECT_API_ISSUER_ID APP_STORE_CONNECT_API_KEY_PATH; do
  if [ -z "${!var:-}" ]; then
    missing_auth=1
  fi
done

if [ "$missing_auth" -ne 0 ]; then
  echo "Status: SIGNING TEAM READY, CLI UPLOAD CREDENTIALS MISSING"
  echo "Next local action: export App Store Connect API credentials, then run ./scripts/agent-archive-for-testflight.sh."
  exit 3
fi

echo "Status: READY FOR ARCHIVE SCRIPT"
echo "Next local action: ./scripts/agent-archive-for-testflight.sh"
