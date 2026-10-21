# Re_Call — Native iOS Reminders: Handoff

Handoff for continuing the native SwiftUI reminders feature. Written 2026-06-15. Read this
top to bottom before touching the iOS build — the **Gotchas** section is what caused repeated
build/crash loops.

## October 21 update — Pinterest carousel sizing and one large square

Final adjustment: Adam requested less gap between the Pro header and carousel.
Browsing now has a 2 pt top inset instead of 22 pt; Arrange keeps its control spacing.
The updated build is installed and visibly verified on the physical iPhone at
09:27 PDT. All 14 saved-data files are byte-identical. Final `./qc.sh --full` is
green at 09:43 PDT: 28 UI tests and 5 unit tests passed, zero failures or skips.
See the newest section of `docs/PRO_ARRANGEMENT_PREVIEW.md`.

Latest appearance: Adam requested almost no gaps. Pro browsing now has 2 pt spacing
between areas and grid cards, tighter captions, and no extra carousel padding. At his
explicit request, the selected large diagram has a saved thumbnail crop removing its
black bands. The crop is optional per-image metadata; the original image and viewer
remain intact. Final appearance, scrolling, original-image viewing, and crop persistence
were inspected on the physical iPhone at 09:08 PDT. Only the selected image's crop field
changed in the current 14-file collection; original bytes and layout are unchanged.
Adam inspected this exact version and said, “That is perfect.” Preserve it.
Final `./qc.sh --full` is green on October 21 at 09:23 PDT: all 28 UI tests and
5 unit tests pass, with zero failures or skips. Engine, native persistence,
deterministic KG output, and build gates also passed.

Latest follow-up: **Remove image** is available in every image's ellipsis menu in
Arrange, including full-size cards, carousel images, and the large square. It uses the
existing confirmation and local archive removal, keeps Arrange active, and leaves
empty carousel/square containers ready for another image. Physical iPhone checks passed
for cancellation, all three layouts, neighboring images, and relaunch persistence.
The actual menu was inspected on the updated phone. At the earlier removal-only
checkpoint, all 15 normal collection files were unchanged. The final combined change
passed full QC as recorded above. See the latest section of `docs/PRO_ARRANGEMENT_PREVIEW.md`.

Every carousel also has up/down arrows in Arrange, matching the large square. Moving a
carousel preserves its membership and image order. The preceding physical check passed
moves across the square and another carousel, relaunch persistence, and vertical scrolling.

Adam supplied three Pinterest screenshots and requested identical compact carousel sizing
plus one large square image container. Carousel thumbnails now use 90 × 135 pt frames,
4 pt gaps and side margins, and 16 pt corners. Captions are hidden while browsing the
carousel; holding an image still opens its title editor. The main grid remains varied
on black, and the shared headers and white navigation retain their approved appearance.

Arrange can add one large square after any grid or row, move it earlier/later, or return
it to the grid. The square accepts a fresh Photo Library/Files import or one chosen
saved image. Its image fills a 1:1 frame with 4 pt side margins; the original file and
full-image viewer remain intact. An occupied square cannot silently replace an image.

This build includes main's October 20 whole-form sharing work. It is installed on the
physical iPhone, with an empty square placed after Adam's first carousel. All five
selected physical checks and a fresh square import/relaunch pass. Final `./qc.sh --full`
is green: all 26 UI tests and 5 unit tests pass, with zero failures or skips, October 21
at 08:10 PDT. All 13 original non-arrangement data files remain unchanged. See the latest section of
`docs/PRO_ARRANGEMENT_PREVIEW.md` for current evidence. The October 19 varied-carousel
direction below is historical and superseded by these uniform thumbnails.

## October 19 update — Pro arrangements and approved page appearance

October 19 Pro direction: black behind the saved-image collection, simple white captions,
and strongly varied image widths and lengths in both the main grid and carousels.
This replaces the tan Pro body described in the earlier verification below. Original
image proportions, saved order, row membership, and source bytes are preserved. The
shared navy headers and white navigation retain their approved appearance. This build
is installed and visually verified on the physical iPhone; all four selected physical
tests passed. All 13 saved-data files are unchanged. Final full QC is green: 24/24 UI
tests, zero failures or skips, October 19 at 13:15 PDT. See the latest section of
`docs/PRO_ARRANGEMENT_PREVIEW.md` for evidence. The tan-page results below are historical.

The physical iPhone build includes Pro card ordering and user-selected smaller horizontal rows.
Arrange opens the controls; a card's menu offers **Start a row here**. Cards can be dragged,
moved earlier/later, or moved between areas. Rows have no heading during normal browsing.
Each row's Add image card accepts a fresh photo or file directly into that row. Empty rows
remain available, so they do not require any existing Pro cards. The header's Add image
still imports to the full-size area at the top.
Carousel image padding, title areas, and the Add image card use the same tan as the
page, following Adam's screenshot correction. The original images are not altered.
Layout is stored separately in `pro-library/arrangement.json`; images and metadata retain
their identity and original bytes. Adam said he will choose row membership in Arrange.

The four tabs use `BrandPageHeader`: compact 128-point content height, solid navy through
the top safe area, white titles, sand controls, tan body, and white bottom navigation.
Calendar opens at its month grid. Today explicitly jumps to the current time. Descriptive
page subtitles and UP NEXT/PRIORITY headings were removed. Adam approved this version
and asked to move on; do not continue adjusting header size or title placement.

Current app bundle is `sh.notorious.app`; Adam's current iPhone identifier is
`00008150-000D793E0208401C`. The older identifiers and appearance descriptions below are
historical. Physical drag, row persistence, uniform headers, Calendar opening, and Calendar
title editing passed. After the seamless-carousel color correction, all 13 then-current
Application Support files matched before/after installation byte for byte. See
`docs/PRO_ARRANGEMENT_PREVIEW.md` for the final regression gate and evidence.

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

**Updated 2026-10-18:** long-press now puts the cursor at the end of the card title. The inline
up/down arrows still move an Up Next card one slot. Tap outside the card to save the title and
dismiss the keyboard. Keep the UIKit gesture surface: the title field receives touches only
while editing, and vertical pans still reach the page. `.scrollDisabled` is not used.
Device testing is the proof for this interaction.

## 5c. Inline card titles

`CardTitle.swift` supplies the shared inline editor and outside-tap handling. It covers
Reminders, Actions, completed rows, all-day and timed Calendar cards, and every Reminder shape
and PRO template. Use the card's existing font, foreground and background; do not add a modal
rename form. The page brings the active editor above the keyboard, and template tiles grow to
keep the pills inside their background. A renamed template seeds the new entry with its displayed title.

`CardTitleStore.swift` saves display titles in a separate local/iCloud `card-titles.json` document,
keyed by reminder UUID or stable template ID. Original titles, Theme answers and other entry
contents remain untouched. Empty drafts preserve the existing title; the reset icon restores
the original display. The entry form continues to show the original writing.

`CardTitleTests` uses isolated fixtures and real holds, typing, keyboard taps, outside taps and
relaunches. Set `RECALL_QC_SIMULATOR_ID` to the simulator owned by the current task when running
`./qc.sh --full`; this full run also executes `scripts/agent-ios-check.sh`. Tests must never write
to the live reminder cache, iCloud or Harness. See `scripts/test-card-title-runtime.sh` for local
persistence and per-card merge checks.

## 5d. Pro saved images (2026-10-18)

Pro opens `ProLibraryView`: a saved-image collection with native Photos and Files import.
The Templates button retains the existing professional templates and their inline title editing.
`ProImageArchive` stores the imported bytes without recompression and an atomic `cards.json`
index in Application Support/pro-library. These are local image records, not reminders;
they do not schedule notifications or export Harness events. Image sync is not implemented.

`ProPosterViewer` uses UIKit `UIScrollView` for pinch, pan, double-tap and zoom controls.
The full-screen presentation keeps the collection mounted so closing returns to the same place.
Full images decode only in the viewer; cards use downsampled previews. Source URLs and notes
belong to the image and can be edited from its details. Keep original bytes intact.

`ProImageTests` runs only in a per-session isolated store; test posters are never seeded into
the normal collection. `scripts/test-pro-image-runtime.sh` checks byte preservation, persistence,
metadata edits, invalid imports, removal, and refusal to overwrite a damaged index. Full QC
includes this runtime check and the saved-card/viewer UI tests. Verification: `docs/PRO_IMAGES_VERIFICATION.md`.

Resumed on 2026-10-19 to test every Pro control. Fixed the conflict between the inline title
override and the image details title; both editors now use the same displayed title and saving
details clears an older override. Each saved card has a pencil button. Copy source shows a
checkmark. Direct physical-iPhone checks cover title entry, metadata, source opening/copying,
sharing, removal, both native imports, cancellation, and persistence. The user's two real cards
and image bytes are unchanged; the normal Pro collection is open on the installed build.
Full QC is green on October 19: all 19 UI tests passed, including the five expanded Pro tests,
and all engine, persistence, and native build gates passed. The final build is installed on the
physical iPhone. Evidence and exact result paths are in `docs/PRO_IMAGES_VERIFICATION.md`.

October 19 keyboard follow-up: the earlier physical typing used Mac input, which did not prove
the onscreen keyboard appeared. Device Hub's Simulate Hardware Keyboard setting hid it even
with Capture Keyboard off. Disabling simulation restored it on the user's actual second card.
Actual phone key taps also exposed Done inserting a newline. That code fix and its new regression
pass are complete. The updated build is installed; actual onscreen typing, Done, details Save,
and relaunch persistence were verified on the phone. Both original card pencils and the actual
opened image title display the keyboard. The normal collection is open and its original files
are unchanged. Full QC for the final code completed with exit 0 at 10:30 PDT: all 20 UI tests
passed, including six Pro tests, plus all engine, persistence, and build gates. The current result
is `Test-ReCall-2026.10.19_10-20-09--0700.xcresult` under ReCall-QC/Logs/Test.

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
