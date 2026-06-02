# iOS Feature Roadmap

This is a planning doc. It captures the full native-iOS feature surface for Re_Call's own reminder-**template** app and orders it by leverage. It pairs with the [Shop / Ship / Undertow product loop](./shop-ship-undertow.md), the [Design Philosophy](../design/design-philosophy.md), and the [Personalization System Doctrine](./personalization-system-doctrine.md).

Re_Call is **not** Apple Reminders. It is a native iOS app with a rich internal reminder/template object. Apple Reminders is one optional output: the app can write a simplified version of a reminder through EventKit, but the meaning, fields, media, and personalization live in Re_Call.

## Framing — mapped to the loop

The roadmap is the [Shop / Ship / Undertow](./shop-ship-undertow.md) loop expressed as native capability. **Templates are the shop:** prebuilt packs, custom templates, and save-as-template are the browsing-and-owning storefront. **The rich object plus write-through is the ship:** the full reminder/template object — image-first hero, links, fields, EventKit and Calendar delivery — is how an owned practice gets shipped into real life. **Suggestions, HealthKit, and on-device ML are the undertow:** the quiet engine that reads real-world use and resurfaces deeper arrivals. Each phase deepens one part of that loop without broadening away from it.

Phases are ordered by leverage: **deliver felt value fast, then deepen.** Phase 1 is mostly the existing web/SwiftUI prototype plus minimal native. Phase 2 reaches into system surfaces. Phase 3 adds intelligence and ecosystem.

## Phase 1 — MVP: the "shop + ship" core

Goal: a beautiful template storefront and a rich reminder object that ships locally. Mostly the web/SwiftUI prototype plus minimal native.

### Templates and ownership (SwiftUI / SwiftData)

- Prebuilt templates and custom templates.
- Template categories and packs (the storefront "sections").
- Save-as-template from any reminder (the ownership act).
- Core template gallery (masonry, beauty-led) and template detail UI.

### The reminder/template object (SwiftData)

- Core fields: title, notes, category, schedule, priority, tags, cover, links, media slots, state.
- Exercise / movement template fields: movement name, sets, reps, load, tempo, rest, RPE/effort, muscle group, equipment, demo media.

### Image-first hero (PhotosUI)

- `PhotosPicker` for the hero cover and per-card covers.
- Realism-only photography as the figure/ground anchor (per Design Philosophy).

### Entry points (LinkPresentation / SafariServices)

- Link previews via `LinkPresentation` (`LPLinkView`).
- YouTube, app, and map entry points through universal links and URL schemes.
- In-app web via `SFSafariViewController` / `SafariServices`.

### Local notifications (UserNotifications)

- Scheduled local notifications with rich content.
- Notification **actions** (complete, snooze, open template) via `UNNotificationCategory`.

## Phase 2 — Native system surfaces

Goal: reach out of the app into the system surfaces that make a reminder app feel native.

### Write-through delivery (EventKit)

- Write a simplified reminder into Apple Reminders.
- Write events into Apple Calendar.
- Re_Call stays the source of truth; EventKit is an output channel.

### Glanceable surfaces (WidgetKit / ActivityKit)

- Home Screen and Lock Screen widgets (`WidgetKit`).
- Live Activities for in-progress reminders/sessions (`ActivityKit`).

### System intelligence entry points (App Intents)

- App Intents for Siri and Shortcuts.
- Spotlight-exposed actions and donations (`App Intents`).

### Capture and annotation (VisionKit / Vision / PencilKit)

- Camera and video capture for covers and demos.
- Document and text scanning via `VisionKit` (`VNDocumentCameraViewController`, `DataScannerViewController`).
- OCR via `Vision` (`VNRecognizeTextRequest`).
- Drawing/markup via `PencilKit`.

### Files and documents (UIKit / PDFKit)

- File import/attach via `UIDocumentPickerViewController`.
- PDF rendering and markup via `PDFKit`.

### Audio and voice (AVFAudio / Speech)

- Voice memo attachments via `AVFAudio` (`AVAudioRecorder`/`AVAudioPlayer`).
- Speech-to-text capture via `Speech` (`SFSpeechRecognizer`).

### Place-based triggers (Core Location / MapKit)

- Geofenced reminders via `Core Location` region monitoring.
- Map entry points and place pickers via `MapKit`.

## Phase 3 — Intelligence and ecosystem

Goal: turn real-world use into the undertow — context-aware triggers, sync, and on-device suggestions.

### Health and workout context (HealthKit / WorkoutKit)

- Read health/activity context to inform timing and suggestions (`HealthKit`).
- Author and trigger structured workouts (`WorkoutKit`).

### Apple Watch (WatchConnectivity)

- Companion watch app and complications.
- Phone-watch sync via `WatchConnectivity`.

### Sync and persistence (CloudKit / SwiftData)

- Cross-device sync via `CloudKit` (SwiftData + CloudKit store).

### Discoverability (Core Spotlight)

- Index templates and reminders for system search via `Core Spotlight`.

### On-device suggestions (Core ML / Natural Language / Foundation Models)

- On-device classification and ranking via `Core ML`.
- Text understanding via `Natural Language`.
- On-device drafting/suggestions via Foundation Models (Apple Intelligence).
- Graph-first, LLM-second (per Personalization System Doctrine).

### Sharing and automation (BackgroundTasks)

- Share, import, and export of templates and packs.
- Background refresh and scheduled automation via `BackgroundTasks`.

### Privacy and security

- Granular permission flows for each system capability.
- Face ID / Optic ID lock via `LocalAuthentication`.
- Limited Photos library access via PhotosUI.

## Best native stack

The native target stack, by role:

```text
UI / state        SwiftUI, SwiftData
sync              CloudKit
notifications     UserNotifications
calendar/tasks    EventKit
media             PhotosUI, AVFoundation
capture/scan      VisionKit, Vision
links/web         LinkPresentation, SafariServices
glanceable        WidgetKit, ActivityKit
intelligence      App Intents, Core Spotlight
health/fitness    HealthKit, WorkoutKit
place             Core Location, MapKit
watch             WatchConnectivity
background        BackgroundTasks
documents         PDFKit, PencilKit
on-device ML      Core ML, Natural Language, Speech
```

## Through-line

```text
templates are the shop
the rich object + write-through is the ship
suggestions / HealthKit / ML are the undertow
```

Re_Call owns the meaning. The system frameworks are delivery surfaces. Ship felt value in Phase 1, then let the undertow deepen — never broaden.
