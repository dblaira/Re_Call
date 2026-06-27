#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/scripts/load-app-store-connect-env.sh"
load_app_store_connect_env

PROJECT="$ROOT_DIR/ios/ReCall.xcodeproj"
SCHEME="ReCall"
DELIVERY_ID="${APP_STORE_CONNECT_DELIVERY_ID:-}"
APPLE_ID="${APP_STORE_CONNECT_APPLE_ID:-}"
BUILD_VERSION="${APP_STORE_CONNECT_BUILD_VERSION:-}"
PLATFORM="${APP_STORE_CONNECT_PLATFORM:-ios}"

export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"

for var in APP_STORE_CONNECT_API_KEY_ID APP_STORE_CONNECT_API_ISSUER_ID APP_STORE_CONNECT_API_KEY_PATH; do
  if [ -z "${!var:-}" ]; then
    echo "FAIL: $var is required for TestFlight status checks."
    exit 3
  fi
done

if [ -n "$BUILD_VERSION" ] && [ -z "$APPLE_ID" ]; then
  echo "FAIL: APP_STORE_CONNECT_APPLE_ID is required when APP_STORE_CONNECT_BUILD_VERSION is set."
  exit 2
fi

if [ -z "$DELIVERY_ID" ]; then
  if [ -z "$APPLE_ID" ]; then
    echo "FAIL: set APP_STORE_CONNECT_DELIVERY_ID, or set APP_STORE_CONNECT_APPLE_ID plus APP_STORE_CONNECT_BUILD_VERSION."
    exit 2
  fi
  if [ -z "$BUILD_VERSION" ]; then
    BUILD_VERSION="$(
      xcodebuild -project "$PROJECT" -scheme "$SCHEME" -showBuildSettings 2>/dev/null |
        awk -F'= ' '/CURRENT_PROJECT_VERSION/ { gsub(/[[:space:]]/, "", $2); print $2; exit }'
    )"
  fi
  if [ -z "$BUILD_VERSION" ]; then
    echo "FAIL: could not infer CURRENT_PROJECT_VERSION. Set APP_STORE_CONNECT_BUILD_VERSION."
    exit 2
  fi
fi

auth_args=(
  --api-key "$APP_STORE_CONNECT_API_KEY_ID"
  --api-issuer "$APP_STORE_CONNECT_API_ISSUER_ID"
  --p8-file-path "$APP_STORE_CONNECT_API_KEY_PATH"
)

status_args=(--build-status)
if [ -n "$DELIVERY_ID" ]; then
  status_args+=(--delivery-id "$DELIVERY_ID")
else
  status_args+=(--apple-id "$APPLE_ID" --bundle-version "$BUILD_VERSION" --platform "$PLATFORM")
fi

if [ "${APP_STORE_CONNECT_WAIT:-0}" = "1" ]; then
  status_args+=(--wait)
fi

echo "Checking Re_Call TestFlight processing status..."
xcrun altool "${status_args[@]}" "${auth_args[@]}" --output-format json
