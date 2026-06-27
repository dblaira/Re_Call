# Notorious Recall — Native iOS App

Re_Call is an iOS-only native SwiftUI app. The app surface is the native reminders list and
full-screen native reminder form; Web, CSS, HTML, and WebKit artifacts are legacy/reference
material only and must not be bundled into the app target or restored as the runtime surface.

The app is built for Adam first: his taste, language, and reaction are the bar for success.

## Open & Run in Xcode

1. Open the project:

```bash
open ios/ReCall.xcodeproj
```

2. In the toolbar, select Adam's iPhone or another iOS device.
3. Press **Run** (⌘R).

- Bundle id: `app.understood.recall`
- Display name: **Notorious Recall**
- Deployment target: iOS 17.0+

## Build from the command line

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild \
  -project ios/ReCall.xcodeproj -scheme ReCall \
  -destination 'generic/platform=iOS' -allowProvisioningUpdates build
```

> If `xcodebuild` errors with "requires Xcode … CommandLineTools", prefix the command with
> `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer` (or run
> `sudo xcode-select -s /Applications/Xcode.app`).

## Code signing / running on device

Signing is **Automatic** (Xcode-managed provisioning). The settings live in `project.yml`
and are baked into `ReCall.xcodeproj` on every `xcodegen generate`:

- `CODE_SIGN_STYLE = Automatic`
- `DEVELOPMENT_TEAM = 7FKUS5M5QS` (Adam Blair — App Store Connect team)
- `CODE_SIGN_IDENTITY = "Apple Development"`
- `PRODUCT_BUNDLE_IDENTIFIER = app.understood.recall`

> **Note on the team ID:** App Store Connect lists `7FKUS5M5QS` as Adam Blair's team,
> with Account Holder/Admin roles. Treat this as the TestFlight-capable team for this repo.

### One-time Xcode setup (GUI)

Automatic signing needs the Apple ID present in Xcode (**Settings ▸ Accounts**) so it can
create the provisioning profile. If you ever sign in on a fresh machine, add the Apple ID under
**Xcode ▸ Settings ▸ Accounts ▸ +** first.

### Build for a device from the command line

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild \
  -project ios/ReCall.xcodeproj -scheme ReCall \
  -destination 'generic/platform=iOS' -allowProvisioningUpdates build
```

`-allowProvisioningUpdates` lets `xcodebuild` register the device and create the profile
non-interactively. The build fails with `No Account for Team "<id>"` only if the matching
Apple ID isn't signed into Xcode's Accounts.

> As with the simulator build, prefix with
> `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer` because the system
> `xcode-select` points at CommandLineTools rather than full Xcode.

## Native app layout

```
ios/
  project.yml            # XcodeGen spec — regenerates ReCall.xcodeproj
  ReCall/
    App/
      ReCallApp.swift    # @main SwiftUI entry point
      ContentView.swift  # native reminder list root + store bootstrap
      ReminderListView.swift
      ReminderFormView.swift
      ReminderStore.swift
      ReminderRepository.swift
      Supabase.swift     # URLSession-only Supabase client; no SDK package
    Resources/
      Assets.xcassets/   # AppIcon placeholder + AccentColor
```

- Supabase stays dependency-free on purpose. Do not add `supabase-swift` or any other SPM package
  for the current reminders runtime.
- The old `ios/ReCall/Web/` WebView prototype was **deleted 2026-06-17** (native-only). Do not
  reintroduce a WebView or bundle web artifacts into the app.

## Regenerate the Xcode project

The project is generated from `project.yml` using [XcodeGen](https://github.com/yonaskolb/XcodeGen):

```bash
brew install xcodegen   # if not already installed
cd ios && xcodegen generate
```
