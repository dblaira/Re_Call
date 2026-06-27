# Agent iOS Build Gate

Use this command before committing iOS changes:

```sh
./scripts/agent-ios-check.sh
```

What it proves:

1. `ReCall` builds for the iOS Simulator.
2. `ReCallUITests` run through the shared `ReCall` scheme.
3. The command exits non-zero if build or tests fail.

Default simulator:

```text
platform=iOS Simulator,name=iPhone 17
```

Override when needed:

```sh
IOS_DESTINATION="platform=iOS Simulator,name=iPhone 17 Pro" ./scripts/agent-ios-check.sh
```

Do not change signing, certificates, provisioning, or App Store submission settings from an agent run unless Adam explicitly asks.

## Xcode Cloud

This repo includes `ci_scripts/ci_post_clone.sh` for Xcode Cloud. It verifies that `ios/ReCall.xcodeproj` exists, or regenerates it from `ios/project.yml` when `xcodegen` is available in the workflow.

Apple-side workflow configuration still lives in Xcode/App Store Connect.

## TestFlight Readiness

Run:

```sh
./scripts/agent-testflight-readiness.sh
```

This calls:

```sh
./scripts/agent-signing-report.sh
```

The signing report prints the shared scheme, bundle id, signing team, signing style, App Store Connect API environment status, and the exact Apple-side action needed before TestFlight.

Current known boundary:

```text
DEVELOPMENT_TEAM = 7FKUS5M5QS
```

That team is Adam Blair's App Store Connect team. The remaining TestFlight gate is App Store Connect API credentials for CLI archive/upload/status checks.

Once App Store Connect API credentials are exported, run:

```sh
./scripts/agent-archive-for-testflight.sh
```

The archive script calls `agent-testflight-readiness.sh` first, generates `ios/ExportOptions-TestFlight.plist` from the current project team, then runs `xcodebuild archive` and `xcodebuild -exportArchive`.

To submit the exported IPA to App Store Connect/TestFlight, set:

```sh
export APP_STORE_CONNECT_API_KEY_ID="..."
export APP_STORE_CONNECT_API_ISSUER_ID="..."
export APP_STORE_CONNECT_API_KEY_PATH="/path/to/AuthKey_....p8"
```

Then run:

```sh
./scripts/agent-upload-to-testflight.sh
```

The upload script runs the readiness gate first, creates the IPA if needed, validates it with `xcrun altool`, and uploads it to App Store Connect. Set `APP_STORE_CONNECT_WAIT=1` to wait for Apple processing status before the command returns.

To check Apple processing status after upload, use either the delivery id returned by `altool`:

```sh
export APP_STORE_CONNECT_DELIVERY_ID="..."
./scripts/agent-testflight-status.sh
```

Or use the App Store Connect app Apple ID plus build number:

```sh
export APP_STORE_CONNECT_APPLE_ID="..."
export APP_STORE_CONNECT_BUILD_VERSION="..."
./scripts/agent-testflight-status.sh
```
