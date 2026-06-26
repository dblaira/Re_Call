#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EXPORT_PATH="${EXPORT_PATH:-$ROOT_DIR/build/TestFlightExport}"
IPA_PATH="${IPA_PATH:-}"

export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"

"$ROOT_DIR/scripts/agent-testflight-readiness.sh"

if [ -z "$IPA_PATH" ]; then
  IPA_PATH="$(find "$EXPORT_PATH" -maxdepth 1 -type f -name '*.ipa' -print 2>/dev/null | sort | tail -1)"
fi

if [ -z "$IPA_PATH" ]; then
  echo "No exported IPA found in $EXPORT_PATH. Running archive/export first."
  "$ROOT_DIR/scripts/agent-archive-for-testflight.sh"
  IPA_PATH="$(find "$EXPORT_PATH" -maxdepth 1 -type f -name '*.ipa' -print | sort | tail -1)"
fi

if [ -z "$IPA_PATH" ] || [ ! -f "$IPA_PATH" ]; then
  echo "FAIL: no IPA found. Expected one in $EXPORT_PATH or pass IPA_PATH=/path/to/app.ipa."
  exit 1
fi

if [ -z "${APP_STORE_CONNECT_API_KEY_ID:-}" ] ||
   [ -z "${APP_STORE_CONNECT_API_ISSUER_ID:-}" ] ||
   [ -z "${APP_STORE_CONNECT_API_KEY_PATH:-}" ]; then
  echo "FAIL: App Store Connect API credentials are required."
  echo "Set APP_STORE_CONNECT_API_KEY_ID, APP_STORE_CONNECT_API_ISSUER_ID, and APP_STORE_CONNECT_API_KEY_PATH."
  exit 3
fi

echo "Validating Re_Call IPA for App Store Connect..."
xcrun altool \
  --validate-app "$IPA_PATH" \
  --api-key "$APP_STORE_CONNECT_API_KEY_ID" \
  --api-issuer "$APP_STORE_CONNECT_API_ISSUER_ID" \
  --p8-file-path "$APP_STORE_CONNECT_API_KEY_PATH"

upload_args=(
  --upload-package "$IPA_PATH"
  --api-key "$APP_STORE_CONNECT_API_KEY_ID"
  --api-issuer "$APP_STORE_CONNECT_API_ISSUER_ID"
  --p8-file-path "$APP_STORE_CONNECT_API_KEY_PATH"
  --show-progress
)

if [ "${APP_STORE_CONNECT_WAIT:-0}" = "1" ]; then
  upload_args+=(--wait)
fi

echo "Uploading Re_Call IPA to App Store Connect/TestFlight..."
xcrun altool "${upload_args[@]}"

echo "Upload submitted: $IPA_PATH"
