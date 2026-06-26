#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT="$ROOT_DIR/ios/ReCall.xcodeproj"
SCHEME="ReCall"
DESTINATION="${IOS_DESTINATION:-platform=iOS Simulator,name=iPhone 17}"

export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"

echo "Agent iOS check: Re_Call"
echo "Project: $PROJECT"
echo "Scheme: $SCHEME"
echo "Destination: $DESTINATION"

xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration Debug \
  -sdk iphonesimulator \
  -destination "$DESTINATION" \
  test

echo "Agent iOS check passed: Re_Call build and UI tests succeeded."
