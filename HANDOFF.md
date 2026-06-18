# Re_Call — Native iOS Reminders: Handoff

Handoff for continuing the native SwiftUI reminders feature. Written 2026-06-15. Read this
top to bottom before touching the iOS build — the **Gotchas** section is what caused repeated
build/crash loops.

---

## 1. What was built

A **native SwiftUI** reminders app (replacing the old WebView-only shell), backed by
**Supabase**, implementing all 16 "parts" from the Figma board.

**Native-only rule:** Re_Call is an iOS-only native app. The web prototype was **deleted
2026-06-17** — `WebView.swift`, `ios/ReCall/Web/*` (index.html, recommendations.js, covers), the
Playwright specs (`tests/web/`), and the web tooling (`stamp-web.mjs`, `serve-web.sh`,
`web-bundle-md5.mjs`, `web-bundle.test.js`, `playwright.config.js`) are gone. Do not reintroduce a
WebView or bundle web artifacts. The KG→cards compiler (`scripts/build-recommendations.mjs`) stays
as an engine artifact; it now writes to `build/recommendations.js` (was the Web folder).

- **List screen** (`ReminderListView`): black page, "Notorious" Bodoni title, crimson FAB,
  active + completed (retained) sections, tap-a-row-to-edit.
- **Entry form** (`ReminderFormView`): **black background, white entry-row cells only**, grouped
  Core / Date & Time / Organization / Places & People. All 16 parts: Title, Notes, URL, Image
  (PhotosPicker), Date, Time, Urgent, Repeat, Early Reminder, List, Tags, Subtasks, Flag,
  Priority, Location (CoreLocation), When-Messaging.
- **Persistence**: local-first cache (`reminders.json` in Application Support) is the on-device
  source of truth; syncs to Supabase behind a `ReminderRepository` protocol. Completed reminders
  keep `status='completed'` (never deleted).
- **Native capabilities**: local notifications (Date/Time/Early/Urgent), PhotosPicker image,
  CoreLocation "use current location".

**Verified working:** clean device build + valid signature, installed + launched on Adam's
iPhone 17 Pro Max, two real reminders created on-device and confirmed in Supabase
(`recall.reminders`) with all parts (priority, date/time, tags, notes, list).

---

## 2. Files (all currently UNCOMMITTED in the working tree)

New native Swift (`ios/ReCall/App/`):
- `Theme.swift` — Notorious palette (crimson/black/white) + Bodoni helper
- `Models.swift` — `Reminder`, `Subtask`, `Priority`/`RepeatRule`/`EarlyReminder`/`ReminderStatus` enums, JSON coders
- `Supabase.swift` — `SupabaseService` actor: anonymous auth + REST over **URLSession** (NO SDK)
- `ReminderRepository.swift` — `ReminderRepository` protocol + `SupabaseReminderRepository` (URLSession/PostgREST) + DB row DTOs
- `ReminderStore.swift` — `@MainActor` ObservableObject: local-first cache + sync + offline retry
- `NotificationScheduler.swift` — UNUserNotificationCenter scheduling
- `LocationProvider.swift` — one-shot CoreLocation place lookup
- `LocalImageStore.swift` — saves picked photos to Application Support (cloud upload = 1.0.1)
- `ReminderListView.swift` — list + row + FAB
- `ReminderFormView.swift` — the full-page 16-part form

Modified:
- `ios/ReCall/App/ContentView.swift` — root is now `ReminderListView` + store bootstrap
- `ios/project.yml` — native app target, Info.plist usage strings (location, photos). **No Swift package** (intentional — see Gotchas).
- `ios/ReCallUITests/SmokeTests.swift` — native smoke tests (launch, charge-FAB opens form, create→list); rewritten 2026-06-17 for the charge-FAB UI
- (deleted 2026-06-17) the web prototype — `ios/ReCall/Web/*`, `WebView.swift`, `tests/web/*` — was removed; the app is native-only
- `supabase/migrations/README.md` — documents the two new migrations

New Supabase migrations (applied to the live project):
- `supabase/migrations/20260615120000_add_reminders_tables.sql`
- `supabase/migrations/20260615120001_harden_set_updated_at_search_path.sql`

`ios/ReCall.xcodeproj/project.pbxproj` is **generated** from `project.yml` — don't hand-edit; regenerate with xcodegen.

---

## 3. Supabase state (already live)

- Project: **`vzaceoipwimphdvdxcpa`** ("Re_Call"), schema **`recall`**.
- Tables: `recall.reminders` (16 scalar parts as columns), `recall.reminder_tags`,
  `recall.reminder_subtasks` (child tables → clean RDF/Neo4j edge projection later).
  `seeded_from_template_id` FK links a reminder into the existing `recall.reminder_templates` graph.
- RLS: own-rows only `to authenticated` via `(select auth.uid())`; grants to `authenticated` + `service_role`.
- Auth: **anonymous sign-ins are ENABLED** (Adam turned the toggle on). The Swift client signs in
  anonymously and persists the refresh token so the same anon user (and rows) survive relaunch.
- Anon key + URL are in `Supabase.swift` (safe to ship; RLS protects rows).

---

## 4. Build / deploy / verify (commands that work)

```bash
# Regenerate the Xcode project (see Gotcha #2 — do this with Xcode QUIT):
cd ios && xcodegen generate

# Clean DEVICE build (this is what reproduces a Run-on-device):
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild clean build \
  -project ios/ReCall.xcodeproj -scheme ReCall \
  -destination 'generic/platform=iOS' -allowProvisioningUpdates \
  -derivedDataPath /tmp/ReCall-build
# Expect: BUILD SUCCEEDED, 0 errors, .app/Frameworks EMPTY, valid Apple Development signature.

# Simulator build/run:
xcodebuild ... -sdk iphonesimulator -destination 'platform=iOS Simulator,id=<sim-udid>' build
xcrun simctl install <sim> <app> ; xcrun simctl launch <sim> app.understood.recall

# Device: prefer Xcode ⌘R (devicectl over the network is slow/hangs — see Gotcha #4).
# Bundle id: app.understood.recall ; device: Adam's iPhone 17 Pro Max (B03CFB03-AA65-5941-BD82-8CBC60092BD9)

# QC (native-only): Layer 1 engine tests + Layer 2 native build (+ Layer 3 native device smoke with --full)
./qc.sh          # ~1 min
./qc.sh --full   # ~3 min, adds the simulator XCUITest smoke
```

> **QC is native-only (retired the web layer 2026-06-17).** The old `./qc.sh` had a
> "Behavior (Playwright vs bundled HTML, WebKit)" check and a "Bundle integrity" check that
> stamped/verified `ios/ReCall/Web/index.html`. The native app renders no WebView, so both gave
> permanent false-red and confused agents into "fixing" a dead web bundle. They were removed; QC
> now verifies only what ships: the engine unit tests, the native build, and a native device-smoke
> XCUITest. `WebView.swift` and `ios/ReCall/Web/*` stay as legacy/reference — do **not** re-add web
> QC unless a WebView becomes a real runtime surface again.

---

## 5. GOTCHAS — these caused the loops, do not relearn them the hard way

1. **DO NOT add the `supabase-swift` SPM package.** Its dynamic frameworks (Supabase/Auth/Crypto/
   HTTPTypes/…) do **not** embed in the app bundle for **device** builds → the app builds and runs
   on the **Simulator** but `abort_with_payload` (dyld "can't load frameworks") crashes at launch on
   a **physical iPhone**. The whole Supabase layer is intentionally plain **URLSession** in
   `Supabase.swift` for exactly this reason. Keep it dependency-free.
2. **xcodegen vs. open Xcode:** if Xcode is OPEN it reverts `project.pbxproj` to its stale in-memory
   copy. Always `xcodegen generate` with Xcode **quit**, then reopen. If builds go stale/crash again:
   quit Xcode → `rm -rf ~/Library/Developer/Xcode/DerivedData/ReCall-*` → delete any junk
   `ios/ReCall N.xcodeproj` duplicates → `cd ios && xcodegen generate` → reopen.
3. **The crash signature** to recognize: `Thread 1: abort with payload or reason` /
   `__abort_with_payload` in disassembly on launch = missing dynamic frameworks = something re-added
   an SPM package. Check `.app/Frameworks` is empty and `grep supabase-swift project.pbxproj` is 0.
4. **`devicectl` over the network connection is slow / hangs** (the device is paired over
   `*.coredevice.local`). For install/launch, use **Xcode ⌘R** rather than CLI devicectl.
5. **Signing:** automatic, `Apple Development: Adam Blair`, bundle `app.understood.recall`. First
   device launch may need the dev cert trusted on the phone (Settings → General → VPN & Device
   Management). It's already trusted on Adam's device.

---

## 5b. Up Next reorder + scroll (device-critical)

Home scroll froze on launch when Up Next cards used SwiftUI `DragGesture` / `LongPressGesture` on
every row — on device that intercepts the ScrollView's vertical pan. Simulator often still scrolls.

**Rule:** Home Up Next uses `UpNextCardRow` (`UpNextCardRow.swift`) — a UIKit pan/long-press layer
that only claims horizontal swipes and reorder holds; vertical pans pass through to the ScrollView.
Do **not** put SwiftUI drag/long-press reorder on feed cards inside `RemindersHomeView`.

Reorder: **long-press a card** (~0.35s, crimson ring + up/down chevrons), then either **tap a chevron**
to move one slot (stays armed for more taps) or **drag up/down while holding** to move and disarm.
Scrolling disarms any armed card when **content offset actually changes** (iOS 18+
`onScrollGeometryChange` with a delta threshold — arming a card must not disarm itself via
layout churn from scale/shadow). `.scrollDisabled` is NOT used anywhere. Device testing is the
only proof — run on Adam's iPhone via Xcode ⌘R.

## 6. Status + what's pending

**Working:** native list + 16-part form, builds clean, signs, runs on device, data syncs to
Supabase (verified with two real reminders).

**Pending / next:**
- **Git:** nothing committed yet; repo is on `main` which is **4 commits BEHIND `origin/main`**.
  `origin/main` has Adam's own native work — `NativeCaptureSheet.swift` (voice-memo capture bridged
  from the web prototype, commit `b3d410f`), a post-run body-scan KG field (`f184268`), a user-zero
  strategy memory (`3367aaa`), and `AGENTS.md` (`ef460db`). Recommended: commit this native work to a
  branch and open a PR against `main` so it reconciles with `NativeCaptureSheet` (overlaps on
  `ContentView.swift`, `index.html`, `project.yml`, tests) instead of clobbering it.
- **Reconcile** the two native approaches: this build removes the WebView runtime; `NativeCaptureSheet`
  should be re-wired natively rather than kept behind the web layer.
- **Figma mirror** of the form (deferred; design artifact only).
- **Image → Supabase Storage** (v1 keeps photos local; `image_path` stays null server-side).
- **Import** old localStorage reminders (from the web prototype) into Supabase, if wanted.

**Product doctrine (from `3367aaa` on origin/main):** the app is built for Adam (user zero) first;
his taste/judgment is the only success bar; anything he doesn't understand in agent communication is
treated as potentially harmful. Optimize for *his* resonance, not generic best practice.
