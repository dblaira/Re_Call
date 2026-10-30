# Re_Call — Native iOS Reminders: Handoff

Handoff for continuing the native SwiftUI reminders feature. Written 2026-06-15. Read this
top to bottom before touching the iOS build — the **Gotchas** section is what caused repeated
build/crash loops.

## Delegate entry boxes — October 29, 2026

### Delegate entry boxes (Executive Conclusion)

1. ✍️ Delegate questions remain visible in the same black regular styling as Decide and Visual.

2. 🖥️ The installed SAVY Mac Social form was inspected. The Delegate icons and spacing match Visual.

3. 📱 Both installed iPhone apps were inspected. Tapping the first Delegate prompt placed the caret directly below it.

### The question remains while writing grows (Consequence)

1. 🔤 Existing form font sizes are preserved in both apps.

2. ⌨️ Answers begin directly below the question. Existing field identifiers and focus navigation remain connected.

3. 💾 Saved writing and media are unchanged. SAVY’s two changed phone files contain CloudKit synchronization metadata.

### Installed and inspected; Understood full QC is pending (Recommendation)

SAVY’s signed Mac Release was installed through `script/build_and_run.sh --verify` and launched at `/Applications/SAVY.app`. Both signed final phone builds were installed successfully on the physical iPhone. The actual SAVY Social and Understood Action forms were compared with Visual. All three Delegate labels use the same dark body styling. The first-prompt tap was checked directly in each app. The blank forms were canceled without writing or saving.

SAVY’s two final focused UI tests passed with zero failures. They verified answer expansion and complete values, including no ellipsis and Save/reopen behavior. They also checked prompt persistence and focus.

Understood’s full QC is still running. An existing ProArrangement file-picker case failed when an immediate Menu retap used coordinates `{-1, -1}` after Photo Library Cancel. The unchanged case will be retried after the full run. The full gate is not reported as passed. Commit, push and final-revision GitHub verification are pending.

### Actual screens and verification record (Supporting Evidence on Request)

Adam’s request, verbatim:

> One other request.  Match the Delegate entry boxes to the other entry forms.  They should not be muted and disappear when text is entered. They should be the same as Decide, and Visual.

| Check | Current result |
| --- | --- |
| Permanent Delegate questions | Implemented in both shared native forms |
| Question color and weight | Black and regular, using each app’s existing question font |
| Existing font sizes | Preserved |
| Answer placement | Zero question/answer stack gap; top-aligned growing answer |
| Question and icon taps | Focus the matching existing answer field |
| Existing caret editing | Whole-row focus guard uses the active field |
| Data model and writing bindings | Unchanged |
| Understood signed phone build and installation | Succeeded on the physical iPhone |
| Understood full QC | Running; one file-picker case failed; unchanged retry pending |
| SAVY phone and Mac builds | Succeeded |
| SAVY final focused UI tests | 2/2 passed; zero failures |
| SAVY Mac Release installation | Succeeded through the verified install script |
| Installed SAVY Mac Social inspection | Delegate matches Visual; first prompt focuses answer directly below |
| Physical SAVY Social inspection | All three dark questions match Visual; first-prompt caret checked directly |
| Physical Understood Action inspection | All three dark questions match Visual; first-prompt caret checked directly |
| Blank live forms | Canceled without writing or saving |
| Isolated SAVY Mac Debug preview | All three prompts and exact sample answers visible; canceled without saving |
| Final pushed revision’s GitHub build | Pending |

Understood source: [ReminderFormView.swift](/Users/adamblair/Developer/GitHub/Re_Call/ios/ReCall/App/ReminderFormView.swift).

SAVY source: [ReminderFormView.swift](/Users/adamblair/Developer/GitHub/SAVY-iOS/SAVY/ReminderFormView.swift).

| Verification log | Location |
| --- | --- |
| Understood full QC | `/tmp/recall-delegate-full-qc.log` |
| Understood signed phone build | `/tmp/recall-delegate-device-final.log` |
| SAVY final focused UI tests | `/tmp/savy-delegate-ui-final.log` |
| SAVY Mac Release installation | `/tmp/delegate-mac-install.log` |

Fresh Mac preinstallation backup: `/var/folders/ll/k4r0q6fj5k18c1vh9vk5t1c80000gn/T/delegate-mac-preinstall-6zxt2x8u`.

| Mac saved archive check | Result |
| --- | --- |
| Compared archives | All four byte-identical after installation and after blank-form cancellation |
| Reminders | 54 |
| Recovery drafts | 0 |
| Connections | 3 |
| Legacy posts | 1 |

Fresh phone preinstallation backup: `/var/folders/ll/k4r0q6fj5k18c1vh9vk5t1c80000gn/T/delegate-phone-preinstall-kyxv88i2`.

Phone postinstallation copy and comparison: `/var/folders/ll/k4r0q6fj5k18c1vh9vk5t1c80000gn/T/delegate-phone-postinstall-02nl3eel`.

| Physical-phone saved files | Result |
| --- | --- |
| Understood | 14/14 files byte-identical |
| SAVY | 22/24 files byte-identical; same relative file paths |
| SAVY writing and media | Unchanged |
| Changed SAVY files | `SAVY/CloudKit/state.json` and `SAVY/CloudKit/status.json` |

The changed SAVY files contain synchronization metadata. The changed keys were `generation`, `engineState`, `lastForegroundFetch` and `lastFetch`.

The previous Visual addition reports remain historical evidence of that earlier installation. The live evidence below verifies this Delegate correction separately.

**Installed SAVY Mac Release.** The actual blank Social form shows Delegate matching Visual. The first prompt was tapped and the caret appears directly underneath. The form was canceled without saving.

![Mac app](</Users/adamblair/Developer/GitHub/SAVY-iOS/docs/design/Delegate entry boxes/Mac app.jpg>)

**Installed SAVY on the physical iPhone.** The blank Social form shows all three dark Delegate questions with the matching crimson icons beneath Visual.

![phone app](</Users/adamblair/Developer/GitHub/SAVY-iOS/docs/design/Delegate entry boxes/phone app.jpg>)

**SAVY after the first Delegate prompt tap.** The actual Social form is focused for writing beneath the question. Direct inspection confirmed the caret position. The blank form was canceled without saving.

![entry boxes](</Users/adamblair/Developer/GitHub/SAVY-iOS/docs/design/Delegate entry boxes/entry boxes.jpg>)

**Installed Understood on the physical iPhone.** The actual Action form shows the caret immediately beneath “What do I want?” All three Delegate questions remain dark and visible. The blank form was canceled without saving.

![Understood](</Users/adamblair/Developer/GitHub/Re_Call/docs/Delegate entry boxes/Understood.jpg>)

**Isolated Mac Debug preview.** This earlier screenshot records all three questions with exact sample writing. It was canceled without saving. It remains distinct from the live captures above.

![SAVY](</Users/adamblair/Developer/GitHub/SAVY-iOS/docs/design/Delegate entry boxes/SAVY.jpg>)

All five original JPEG files are copied without changing their bytes.

## entry forms — October 29, 2026

### entry forms (Executive Conclusion)

1. 📱 SAVY’s Visual addition is installed in Understood. The physical Action form was compared with SAVY while Theme and Visual were closed and while their menus were open.

2. 🎨 The opened Visual menu shows all twelve choices with red icons on the rounded cream panel. Both closed selectors use compact crimson controls.

3. 💾 All 14 production files are byte-identical after installation and blank-form checks. All 37 saved reminders remain intact.

### The supported entry kinds share one form (Consequence)

1. 🔗 Reminder uses the same native entry form as Action and Event. Re_Call has no Social entry kind or configured Mac Catalyst target.

2. ✍️ Selecting Summarize updated its four prompts on the phone. Tapping the first question placed the cursor directly below it. All four questions and Delegate remained visible.

3. 🔤 The implementation uses SAVY’s 17-point regular iPhone form typography. All five Visual UI cases passed in full QC. They cover all three entry kinds and long-writing interaction.

4. 🖼️ The approved Pro implementation is unchanged. Its original image bytes and metadata match the preinstallation backup exactly.

### Installed; local QA is green (Recommendation)

The signed Debug app is installed as `sh.notorious.app`. Normal physical launch succeeded. The blank Action form was canceled to Home without entering writing or saving an entry.

Final full QC is green. Source feature commit `fd771e397c0295abf8138411b02ca3e7d00a6a6c` has a successful [GitHub iOS Build](https://github.com/dblaira/Re_Call/actions/runs/41006449225).

Repo and Mac evidence copies match. Cowork copies are staged; cloud upload remains unconfirmed.

### Actual phone screens and verification record (Supporting Evidence on Request)

Adam’s request, verbatim:

> OK, now we're going to switch to the recall understood app because I want the same edition to that app as well. This is another level of consistency that I want in the entry forms. I want them all to be the same, whether it's the understood app or whether it's the SAVY app, because they represent different levels of the Adam pattern for me.

| Check | Current evidence |
| --- | --- |
| Product identity | Installed Understood is `sh.notorious.app` |
| Source reference | SAVY’s existing native Visual catalog and entry form |
| Runtime persistence and sharing checks | Passed in final full QC |
| Simulator app compilation | Passed in final full QC |
| Visual UI tests | All five passed in the final full run |
| Unit tests | 11/11 passed; zero failures or skips |
| UI tests | 32/32 passed; zero failures or skips |
| Full simulator test suite | 43/43 passed together |
| Full QC gates | 8/8 passed |
| Signed device build and installation | Succeeded |
| Physical blank Action form | Both selectors inspected while closed and open |
| Opened Visual menu | All twelve choices visible; compared with SAVY |
| Summarize selection | Four prompts updated |
| First Visual question tap | Writing cursor directly below the question |
| Blank form cancellation | Returned to Home without saving |
| Production file comparison | Same 14 relative paths; all SHA256 hashes match |
| Source feature commit’s GitHub iOS Build | Passed for `fd771e397c0295abf8138411b02ca3e7d00a6a6c` |

The initial physical XCTest attempt failed during runner initialization with Apple authentication error 12. It executed no tests. Initial Mirroring clicks returned `noWindowsAvailable`; Raise and Connect enabled the later direct inspection recorded above.

Earlier full-QC runs exposed legacy field-visibility assumptions in `CardTitleTests/testThemeCardOutsideTapSavesAcrossPagesAndRelaunch` and `UpNextScrollTests/testReorderMovesCardWithinUpNext`. Their helpers now reveal the actual editable field without weakening the assertions. Focused reruns passed. Final full QC passed all 43 tests together.

The optional Visual field keeps older saved entries decodable. Each format retains its own writing. Entire-form sharing includes populated Visual answers. Unknown saved format IDs remain recoverable. The live store remains local-first with iCloud Documents.

| Saved data | Before | After | Result |
| --- | ---: | ---: | --- |
| Production files | 14 | 14 | All hashes identical |
| Reminder records | 37 | 37 | Original JSON bytes identical |
| Pro card records | 10 | 10 | Original metadata identical |
| Total file bytes | 17,513,005 | 17,513,005 | Identical |

Private preinstallation backup: `/var/folders/ll/k4r0q6fj5k18c1vh9vk5t1c80000gn/T/tmpzaztdh88`.

Private final-reinstallation backup: `/var/folders/ll/k4r0q6fj5k18c1vh9vk5t1c80000gn/T/tmp1pf411eb`. All hashes match the first baseline again.

The final source cleanup removed an unused branch for an unconfigured Catalyst target. Its iOS runtime UI code is unchanged from the captured version. The final native device build and reinstallation succeeded; normal physical launch succeeded again.

Final device-build log: `/tmp/ReCall-entry-forms-device-final-build.log`.

Final installation log: `/tmp/ReCall-entry-forms-final-install.log`.

Final full-QC log: `/tmp/ReCall-entry-forms-qc-complete.log`.

Final test result: `/Users/adamblair/Library/Developer/Xcode/DerivedData/ReCall-QC/Logs/Test/Test-ReCall-2026.10.29_21-44-28--0700.xcresult`.

All 17 source/build/test files match `/tmp/ReCall-entry-forms-tested-source.json` after the passing run. The committed source feature snapshot also matches those tested hashes. Their hashes are included in the verification record.

[Verification record](</Users/adamblair/Developer/GitHub/Re_Call/docs/entry forms.json>)

![Visual](</Users/adamblair/Developer/GitHub/Re_Call/docs/entry forms/Visual.jpg>)

![Theme](</Users/adamblair/Developer/GitHub/Re_Call/docs/entry forms/Theme.jpg>)

![entry forms](</Users/adamblair/Developer/GitHub/Re_Call/docs/entry forms/entry forms.jpg>)

![right below the question](</Users/adamblair/Developer/GitHub/Re_Call/docs/entry forms/right below the question.jpg>)

## October 21 update — GitHub build notifications

The GitHub iOS Build failures were caused by the macOS 15 runner selecting its
default Xcode 16.4. The first failing Pro/header commit on October 19 reported
`scrollEdgeEffectHidden` missing; the October 21 Reminders checkpoint reported
`glassEffect` missing. Both are iOS 26 SwiftUI APIs. These remote compile failures
are separate from the passing local QC and physical-iPhone checks below.

The workflow now explicitly selects the runner's installed Xcode 26.3 and prints
its version before compiling. No app source, appearance, stored data, signing,
or deployment setting changes are needed. Always verify the GitHub run for the
exact pushed commit before reporting all checks green; see `ios/AGENT_BUILD.md`.

## October 21 update — remove Reminder shapes

Adam now uses Pro for inspiration and requested removal of the Reminder shapes
heading and its five tiles. Reminders shows the existing active feed and Completed
control. The unused shape-picker callback is removed; bottom clearance remains.
The approved Pro page is finished and its implementation is unchanged.

Installed and visibly verified on the physical iPhone at 09:50 PDT. Three isolated
phone checks pass: shapes absent, a long list reaches and opens Completed, and
scrolling still works after holding a title. All 14 saved-data files are unchanged.
The obsolete reminder-tile editing test was retired; scroll tests now use Completed
and a long fixture feed. Their helper brings Completed fully above the bottom bar
before tapping; XCTest had incorrectly reported the obscured control as hittable.
Final `./qc.sh --full` is green at 10:26 PDT: 27 UI tests and 5 unit tests passed,
zero failures or skips. See `docs/REMINDERS_WITHOUT_SHAPES.md`.

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
