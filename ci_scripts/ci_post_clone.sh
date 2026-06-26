#!/bin/sh
set -eu

echo "Xcode Cloud post-clone: Re_Call"

if [ -d "ios/ReCall.xcodeproj" ]; then
  echo "Found ios/ReCall.xcodeproj."
else
  echo "Missing ios/ReCall.xcodeproj."
  if command -v xcodegen >/dev/null 2>&1; then
    echo "xcodegen found; regenerating project from ios/project.yml."
    (cd ios && xcodegen generate)
  else
    echo "xcodegen not found. Commit ios/ReCall.xcodeproj or install xcodegen in this workflow."
    exit 1
  fi
fi

echo "Post-clone check complete."
