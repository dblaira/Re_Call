# Notorious Recall — iOS App

A real iPhone app that renders the existing Notorious Recall prototype full-screen, edge-to-edge,
inside a `WKWebView` (no Safari chrome). The HTML prototype remains the design source of
truth; this target ships a bundled copy of it so the app runs offline as a native iPhone app.

> Native SwiftUI re-implementation is intentional future work. Today this is a thin,
> production-feel shell around the bundled web prototype.

## Open & Run in Xcode

1. Open the project:

```bash
open ios/ReCall.xcodeproj
```

2. In the toolbar, select an iPhone simulator (e.g. **iPhone 16 Pro**).
3. Press **Run** (⌘R).

- Bundle id: `app.understood.recall`
- Display name: **Notorious Recall**
- Deployment target: iOS 17.0+

## Build from the command line

```bash
xcodebuild -project ios/ReCall.xcodeproj -scheme ReCall \
  -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' build
```

> If `xcodebuild` errors with "requires Xcode … CommandLineTools", prefix the command with
> `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer` (or run
> `sudo xcode-select -s /Applications/Xcode.app`).

## Code signing / running on device

Signing is **Automatic** (Xcode-managed provisioning). The settings live in `project.yml`
and are baked into `ReCall.xcodeproj` on every `xcodegen generate`:

- `CODE_SIGN_STYLE = Automatic`
- `DEVELOPMENT_TEAM = 7FKUS5M5QS` (Adam Blair — **Personal Team**, Apple ID `adamblair1@mac.com`)
- `CODE_SIGN_IDENTITY = "Apple Development"`
- `PRODUCT_BUNDLE_IDENTIFIER = app.understood.recall`

> **Note on the team ID:** an earlier config used `YQT2TQ53UN`, which came from a stale
> certificate whose team is **not** signed into Xcode. The team that is actually signed in is
> the free Personal Team `7FKUS5M5QS`, so that's what the project uses.

### One-time Xcode setup (GUI)

Automatic signing needs the Apple ID present in Xcode (**Settings ▸ Accounts**) so it can
create the provisioning profile. The Apple ID `adamblair1@mac.com` is already signed in, so
`xcodebuild ... -allowProvisioningUpdates` creates the personal-team development cert +
profile non-interactively. If you ever sign in on a fresh machine, add the Apple ID under
**Xcode ▸ Settings ▸ Accounts ▸ +** first.

> **Free / personal team caveat:** `7FKUS5M5QS` is a free (personal) team, not a paid Apple
> Developer Program team. Apps signed with it expire after **7 days** and must be re-installed
> from Xcode. A paid membership removes this limit.

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

## How the web bundle is wired

```
ios/
  project.yml            # XcodeGen spec — regenerates ReCall.xcodeproj
  ReCall/
    App/
      ReCallApp.swift    # @main SwiftUI entry point
      ContentView.swift  # dark canvas + edge-to-edge web view
      WebView.swift      # WKWebView wrapper, loads the bundled prototype offline
    Resources/
      Assets.xcassets/   # AppIcon placeholder + AccentColor
    Web/                 # bundled as a FOLDER REFERENCE (structure preserved)
      index.html         # copy of wireframes/template-gallery-ios.html
      covers/            # copy of wireframes/covers/*.png
```

- `Web/` is added to the target as a **folder reference** (`type: folder` in `project.yml`),
  so the whole tree is copied into the app bundle with its relative layout intact.
- `WebView.swift` loads it with
  `WKWebView.loadFileURL(indexURL, allowingReadAccessTo: webDir)`, granting read access to the
  entire `Web/` directory so the prototype's relative `covers/*.png` references resolve offline.
- Scroll bounce is disabled and the background is set to the prototype's dark canvas
  (`#2B2E38`) so it reads like a native screen rather than a web page.

## Refresh the bundled copy when the prototype changes

The files under `ios/ReCall/Web/` are copies. After editing the prototype in `wireframes/`,
refresh them with one command:

```bash
cp wireframes/template-gallery-ios.html ios/ReCall/Web/index.html && \
  cp wireframes/covers/*.png ios/ReCall/Web/covers/
```

(No Xcode project regeneration is needed — the folder reference picks up the new contents on
the next build. If you add brand-new files/folders to `Web/`, run `cd ios && xcodegen generate`
to refresh the project, though folder references generally pick up new files automatically.)

## Regenerate the Xcode project

The project is generated from `project.yml` using [XcodeGen](https://github.com/yonaskolb/XcodeGen):

```bash
brew install xcodegen   # if not already installed
cd ios && xcodegen generate
```
