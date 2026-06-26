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

That team is documented in this repo as Adam's Personal Team. Personal Team builds are useful for local/device development, but TestFlight requires the app to be under an Apple Developer Program/App Store Connect team.

Once the app is moved to an App Store Connect-capable team, run:

```sh
./scripts/agent-archive-for-testflight.sh
```

The archive script calls `agent-testflight-readiness.sh` first, generates `ios/ExportOptions-TestFlight.plist` from the current project team, then runs `xcodebuild archive` and `xcodebuild -exportArchive`.
