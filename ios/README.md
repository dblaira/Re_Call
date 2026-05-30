# Re_Call — iOS App

A real iPhone app that renders the existing Re_Call prototype full-screen, edge-to-edge,
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
- Display name: **Re_Call**
- Deployment target: iOS 17.0+

## Build from the command line

```bash
xcodebuild -project ios/ReCall.xcodeproj -scheme ReCall \
  -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' build
```

> If `xcodebuild` errors with "requires Xcode … CommandLineTools", prefix the command with
> `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer` (or run
> `sudo xcode-select -s /Applications/Xcode.app`).

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
