#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT="$ROOT_DIR/ios/ReCall.xcodeproj"
SCHEME="ReCall"
ARCHIVE_PATH="${ARCHIVE_PATH:-$ROOT_DIR/build/ReCall.xcarchive}"
EXPORT_PATH="${EXPORT_PATH:-$ROOT_DIR/build/TestFlightExport}"
EXPORT_OPTIONS="${EXPORT_OPTIONS:-$ROOT_DIR/ios/ExportOptions-TestFlight.plist}"
PROJECT_FILE="$ROOT_DIR/ios/ReCall.xcodeproj/project.pbxproj"

export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"

"$ROOT_DIR/scripts/agent-testflight-readiness.sh"

mkdir -p "$(dirname "$ARCHIVE_PATH")" "$EXPORT_PATH"

TEAM_ID="$(awk -F'= ' '/DEVELOPMENT_TEAM =/ { gsub(/[;[:space:]]/, "", $2); print $2; exit }' "$PROJECT_FILE")"
sed "s/TEAM_ID_PLACEHOLDER/$TEAM_ID/g" "$ROOT_DIR/ios/ExportOptions-TestFlight.template.plist" > "$EXPORT_OPTIONS"

echo "Archiving Re_Call for TestFlight..."
xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath "$ARCHIVE_PATH" \
  -allowProvisioningUpdates \
  archive

echo "Exporting Re_Call archive for App Store Connect..."
xcodebuild \
  -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$EXPORT_PATH" \
  -exportOptionsPlist "$EXPORT_OPTIONS" \
  -allowProvisioningUpdates

echo "Archive/export complete: $EXPORT_PATH"
