# Pro arrangements

## October 21 follow-up — position whole carousels

Arrange now gives every carousel the same up/down controls as the large square.
Each tap moves the entire carousel past an adjacent card area, square, or carousel,
keeping its images in their existing order. Placement uses the existing atomic
arrangement save. The shared top card area remains the destination for new header imports.

The physical-iPhone check passed on October 21 at 08:22 PDT. It moved a populated
carousel below and above the square, moved another carousel past it, and verified
membership, image order, placement after relaunch, and vertical scroll. Result:
`/tmp/Understood-ProPinterest-device/Logs/Test/Test-ReCall-2026.10.21_08-21-20--0700.xcresult`.

The normal collection is restored on the updated phone. Both actual carousel headings
show their new arrows in Arrange. All 15 Application Support files, including the
user's chosen square image and arrangement, match the pre-update copy byte for byte.
Final `./qc.sh --full` completed QC GREEN on October 21 at 08:37 PDT. All 27 UI tests
and 5 unit tests passed, with zero failures or skips, along with the engine, persistence,
deterministic KG output, and native build gates. Result:
`/Users/adamblair/Library/Developer/Xcode/DerivedData/ReCall-QC/Logs/Test/Test-ReCall-2026.10.21_08-22-46--0700.xcresult`.

Evidence: `/Users/adamblair/.codex/visualizations/2026/10/19/01a15550-786d-7151-87b2-d02e194093a5/pro-area-movement-2026-10-21`.
It includes `iphone-carousel-arrange-arrows.png`, both physical-test screenshots in
`physical-proof-all`, `physical-tests-summary.json`, `data-integrity.json`, and the final
`full-qc-summary.json`, `full-qc.log`, and `full-qc-ui.log`.

## October 21, 2026 — Pinterest carousel and large square

Adam's supplied `IMG_3052.png` shows the compact “Your saves” carousel. On the original
1320 px screenshot its card frames measure 270 × 405 px, equivalent to 90 × 135 pt on
the attached 3× iPhone. Pro now matches those identical 2:3 frames, 4 pt gaps, 4 pt
side margins, 16 pt corners, and image-only browsing. Original proportions still govern
the varied main grid. Carousel thumbnails fill their frames without changing source
bytes, and opening an image shows the original in the existing viewer. Holding a
thumbnail retains inline title editing.

The full-width square from `IMG_3053.png` is represented by one 1:1 area with 4 pt side
margins. Arrange can place it after a grid or row and move it earlier/later. Its Add
image menu supports fresh Photo Library or Files imports and choosing one saved image.
Moving or importing another image into an occupied square cannot overwrite its image.
Returning the square to full-size cards preserves the card and its saved metadata.

The worktree was fast-forwarded to `69f17a8` before implementation, retaining October 20
whole-form sharing. The native build is installed on Adam's iPhone. The normal collection
has an empty square after the first carousel, ready for his own image choice. Readback
confirms all 13 non-arrangement files unchanged, including all 10 original
images. Only `arrangement.json` changed to place the empty square and reconcile the
newly saved top card; the original row memberships and order remain intact.

All five selected physical checks now pass on the installed code. The square, native
drag, empty-row pickers, and both onscreen title editors passed in
`Test-ReCall-2026.10.21_07-54-46--0700.xcresult`. The final carousel check passed in
`Test-ReCall-2026.10.21_07-58-12--0700.xcresult`, proving identical 90 × 135 pt frames,
saved membership/order after relaunch, an actual horizontal swipe to offscreen Add
image, return from the viewer, and a held thumbnail accepting an onscreen key and Done.
These results are under `/tmp/Understood-ProPinterest-device/Logs/Test/` and their
summaries and screenshots are preserved in the evidence directory below.

The first physical run exposed clipped image content expanding accessibility bounds;
the card now explicitly uses its rectangular layout bounds for accessibility. The
square assertion uses its stable native tap-host identifier because SwiftUI merges a
single-child container with its parent. The overflow assertion checks that Add image
starts beyond the screen; querying hittability for that offscreen element throws in
this iOS version. Device Hub's simulated hardware keyboard was disabled, and actual
onscreen key taps then passed. Failed attempts remain in the evidence directory.

A separate native Photo Library import in isolated session
`7434FE12-222A-4FE6-A5D2-8BA3D14FBB77` saved the supplied `IMG_3053.png` directly into
an empty square. Reopening showed the same image in the square, with both grid areas
empty. Device readback matches the supplied file byte for byte (SHA-256
`d4fbb845a8f758bd15e4a1018fd58e1a854668699f652ec85465c58ff1c8980d`).
The normal collection is restored and its 14 files match the post-placement copy;
all 13 original non-arrangement files remain unchanged.

Final `./qc.sh --full` completed QC GREEN on October 21 at 08:10 PDT: all 26 UI tests
and 5 unit tests passed, with zero failures or skips. Engine, native persistence,
deterministic KG output, and build gates also passed. The final result is
`/Users/adamblair/Library/Developer/Xcode/DerivedData/ReCall-QC/Logs/Test/Test-ReCall-2026.10.21_07-56-30--0700.xcresult`.
Its summary and logs are preserved as `full-qc-final-summary.json`, `full-qc-final.log`,
and `full-qc-final-ui.log` in the evidence directory. Runtime checks cover one square,
fresh and chosen images, occupied-slot protection, original bytes, relaunch, placement
changes, and returning to the grid. An earlier full run was stopped after the
test-lookup fixes superseded it; it is not counted as a passing gate.

Evidence: `/Users/adamblair/.codex/visualizations/2026/10/19/01a15550-786d-7151-87b2-d02e194093a5/pro-pinterest-square-2026-10-21`.

## October 19, 2026 — black and varied image sizes (historical)

After the tan version was saved as `e4dbe08`, Adam supplied two Pinterest screenshots and requested a black Pro collection with strongly different image widths and lengths. This replaces the earlier tan Pro collection described below. The approved shared navy header and white bottom navigation remain in place.

The native view now uses black behind images and simple white captions. Full-size columns have different widths, and images retain their proportions. Each carousel derives varied sizes from stable image identity and separates neighboring images with similar dimensions. The layout keeps the saved order, row membership, original image files, and existing image viewer. Add image remains available in every row.

The new device build is installed. Direct inspection on the physical iPhone shows the backpack, Running Inspiration, and Presentation Inspiration at different widths and lengths. The lower SAVY and Adam to Understood images also have visibly contrasting sizes. Direct horizontal swiping reaches Add image on black without shifting the grid below it. The normal collection was reopened after the isolated tests. All 13 saved-data files match the pre-installation copy byte for byte.

The physical iPhone passed all four selected tests, with zero failures or skips: chosen row membership, order and sizes after relaunch; horizontal swiping to Add image and returning from image detail; opening Photos and Files from an empty row; native drag and vertical scrolling; and both title editors using actual onscreen keys. Result: `/tmp/Understood-ProArrangement-device/Logs/Test/Test-ReCall-2026.10.19_13-06-00--0700.xcresult`. The first attempt stopped at Apple's XCTest passcode prompt without running app tests. Adam cleared that prompt, and the retry passed.

The new size assertion initially searched for a Button where the card exposes an accessibility container. The lookup was corrected to the existing identifier across element types, retaining the height-difference and relaunch assertions. Its targeted simulator rerun passed. The final `./qc.sh --full` completed QC GREEN on October 19 at 13:15 PDT: all 24 UI tests passed, with zero failures or skips. Engine, native persistence, deterministic KG output, and build gates also passed. Final result: `/Users/adamblair/Library/Developer/Xcode/DerivedData/ReCall-QC/Logs/Test/Test-ReCall-2026.10.19_13-03-56--0700.xcresult`.

Current evidence directory: `/Users/adamblair/.codex/visualizations/2026/10/19/01a15550-786d-7151-87b2-d02e194093a5/pro-black-varied`.

- `iphone-opening.png`, `iphone-lower-carousel.png`, and `iphone-final-swipe.png`: native captures of the actual collection on the phone.
- `physical-tests-summary.json`, `physical-tests.log`, and `physical-test-proof/`: the four passing physical tests and ten captured screens.
- `size-relaunch-simulator-summary.json`: the corrected targeted assertion passing on the simulator.
- `full-qc-summary.json`, `full-qc.log`, and `full-qc-ui.log`: all 24 UI tests and the full quality gate passing for the black Pro version.
- `black-background-readback.json`: the page, image spacing, and caption background are black in the captured pixels.
- `device-before/`, `device-after-final/`, and `data-integrity-after-final.json`: matching files and SHA-256 hashes for all 13 saved-data files.

## Earlier decisions and verification

Reorder Pro cards between areas, add smaller horizontal rows farther down the page, and let Adam choose the cards in each row. The header background is solid navy, extending to the top edge of the iPhone. Header titles are white and lowered; controls and other header text stay sand. The body and space behind each smaller row use the same tan. Browsing has no “Carousel” heading; shape, size, and horizontal scrolling distinguish the row.

The native mockup was shown on the physical iPhone before implementation. Adam’s corrections were applied and shown in a revised mockup. The temporary preview entry point has now been removed; these controls live in the normal Pro page.

Adam then extended the appearance change to all four tabs. `BrandPageHeader` gives Home, Actions, Calendar, and Pro one compact 128-point content height plus the native status-bar safe area. The header remains visible while the body scrolls. All four tabs have a white bottom navigation bar and tan body background, including Reminder Shapes and completed rows. The title stands alone: UP NEXT, PRIORITY, descriptive subtitles, LIGHT OFFERING, and PRO LIBRARY were removed. Pro appears above Templates, Arrange, and Add image. Calendar opens at the month grid; its explicit Today button can still jump to the current time. A larger header was shown and then reduced at Adam’s request.

## Delivered behavior

- Arrange enables native drag/drop, Move earlier/later, and moves between areas.
- “Start a row here” puts the chosen card into a smaller row at that point in the page. Full-size cards remain before and after it.
- “Add row here” creates an empty destination. Move-menu choices let Adam fill it himself.
- Each row also has its own Add image card, offering Photo Library and Choose File. A fresh import goes directly into that row, without first becoming a full-size card. Empty rows remain visible and can be filled entirely with fresh images, even in a new collection.
- Carousel image padding, title areas, and the Add image card match the tan page exactly. Adam supplied a screenshot showing white letterboxing and pale card panels; those surfaces now blend into the page. Original image pixels are unchanged.
- The import draft retains the chosen row through the system picker and Save. Fresh cards append to that row, and its horizontal view reveals the new card. The page header's Add image continues to add full-size cards at the top.
- The grid icon in Arrange returns a row to full-size cards, preserving its cards and order.
- Browsing keeps the existing image viewer, source and notes, inline title editor, Photos/Files import, and Templates.
- Existing collections keep their saved order and receive no automatic rows. New imports appear in the top full-size area.

`ProLibraryArrangement` is presentation data. `ProImageArchive` serializes its writes to a separate atomic `pro-library/arrangement.json` document. Reordering never rewrites the image index or original bytes. Stale references are removed when reading, new images are reconciled at the top unless a row was explicitly chosen, and a damaged arrangement is not silently overwritten. Direct imports validate the row before writing, save original bytes and placement before the index commit, and return the saved cards and layout together. An import to a removed row fails without silently redirecting the card.

## Physical iPhone evidence

Device: Adam’s iPhone 17 Pro Max, iOS 27.2, UDID `00008150-000D793E0208401C`.

The native build succeeded and passed strict code-signature verification. Both arrangement UI tests passed on the physical phone in isolated stores:

- `testNativeDragReordersCardsAndKeepsVerticalScroll`: holds and drags the second card before the first; checks changed positions; scrolls to a lower card while Arrange is on; relaunches and checks the saved order. Result: `/tmp/Understood-ProArrangement-device/Logs/Test/Test-ReCall-2026.10.19_11-43-10--0700.xcresult` — 1 passed, 0 failed, 0 skipped.
- `testChosenRowMembershipAndOrderSurviveRelaunch`: starts a row at a selected card, moves another card into it, checks only those selected cards and their order, verifies no browsing heading, relaunches, opens an image, and returns to the same row. Result: `/tmp/Understood-ProArrangement-device/Logs/Test/Test-ReCall-2026.10.19_11-45-16--0700.xcresult` — 1 passed, 0 failed, 0 skipped.

Direct Device Hub interactions independently checked row creation, moving two more images into a row, vertical scrolling with Arrange active, horizontal swiping during browsing, and editing a smaller card using actual onscreen keys followed by keyboard Done. Device readback confirmed the three chosen cards in the row and the edited title. All of these agent-selected arrangements were in an isolated test collection.

The first physical automation attempt timed out at Apple’s passcode prompt. After Adam entered his passcode, the retry passed. That timeout is not counted as a behavioral test failure or a pass.

The compact shared-header build also passed both arrangement tests and `testCalendarOpensAtTheTopWithUniformTabHeaders` on the physical phone: `/tmp/Understood-ProArrangement-device/Logs/Test/Test-ReCall-2026.10.19_12-05-12--0700.xcresult` — 3 passed, 0 failed, 0 skipped. That run checks equal header frames on all four tabs, the whole month visible on Calendar opening, an explicit Today jump, and the month visible again after returning to Calendar.

The normal app was then reopened on the physical phone. Home, Actions, Calendar, and Pro were inspected directly: navy reaches the top edge, the body is tan, and the bottom navigation is white. Adam approved the compact height, then requested white titles placed lower while retaining sand controls. He approved that result and asked to move on. The final captures supersede the earlier larger-header and navy-body previews.

The final build also passed Calendar timed and all-day title editing on the physical phone: `/tmp/Understood-ProArrangement-device/Logs/Test/Test-ReCall-2026.10.19_12-08-51--0700.xcresult` — 1 passed, 0 failed, 0 skipped. With Calendar now opening at its month grid, the test uses the visible Today button to reach its current-time fixture before running the existing title assertions.

Device readback after the header work confirmed all 10 original Application Support files still match byte for byte: seven images, their index, display titles, and reminders. When Adam asked where the carousel was, the live Arrange → card menu → “Start a row here” control was opened for him. He then requested the ability to add fresh cards directly to a carousel.

The final fresh-import build passed all three `ProArrangementTests` on the physical phone: `/tmp/Understood-ProArrangement-device/Logs/Test/Test-ReCall-2026.10.19_12-21-02--0700.xcresult` — 3 passed, 0 failed, 0 skipped. The new test starts with no saved cards, creates an empty row, opens both real system pickers from that row, cancels, and verifies the row remains available after relaunch. A further physical run adds an actual horizontal swipe assertion: `/tmp/Understood-ProArrangement-device/Logs/Test/Test-ReCall-2026.10.19_12-26-00--0700.xcresult` — 1 passed, 0 failed. The swipe fully reveals the row's Add image card and can return to the saved images.

Direct Device Hub interaction then created an empty row in isolated session `06AC1D8F-75C6-4BFF-97C4-2885F6709CEF`. A diagram was selected from Photo Library and saved directly into it. A second image, `car-original`, was selected through Files and appended to the same row. Both appeared in the smaller carousel after relaunch. Device readback confirmed the row contains exactly those two fresh IDs, with the full-size areas empty.

On returning to the normal collection, two arrangements were already present: the backpack in one row and two other images in a lower row. Those choices were preserved. The new Add image card was visibly available beside the backpack. Final real-collection readback still matches all 10 original files byte for byte; the only added file is `pro-library/arrangement.json`, containing all seven existing card IDs exactly once. The agent's fresh import checks remain isolated from that collection.

Adam then confirmed fresh additions were working and showed Running Inspiration and Presentation Inspiration in his carousel. He requested a seamless tan background. The three surface colors were changed, built, signed, installed, and inspected on the physical phone. Direct horizontal swiping revealed the existing images and Add image on the same tan surface. Pixel samples from the phone capture match exactly across the page, image padding, title area, and Add image card. All 13 current Application Support files matched before and after this installation byte for byte, including Adam's new images and arrangement.

## Runtime and regression checks

The native persistence tests cover existing order without automatic rows, first-use empty row creation, earlier/later order, starting rows mid-collection, moves across areas, multiple rows, relaunch, intact metadata and source bytes, invalid destinations, new imports, removal, and damaged-layout preservation. Fresh-import checks also cover an entirely empty collection, appending two fresh images directly to its row, exact source bytes and metadata, relaunch, independent header imports, and rejection of missing or removed destinations. These checks pass.

The new worktree initially lacked Node dependencies. `npm ci --ignore-scripts` installed the lockfile versions, after which engine tests passed. The full arrangement gate then passed with 22 UI tests. The next run passed 22 of 23 tests: the old Calendar title test assumed the page opened at the current time. Its navigation was updated to use Today; the title assertions are unchanged, and the corrected test passed on the physical phone. After that earlier run finished its tests, Xcode stalled collecting simulator diagnostics and was stopped; its QC result remains failed.

The fresh-import build then completed `./qc.sh --full` with exit 0 and QC GREEN at 12:34 PDT: all 24 UI tests passed, along with the engine, native persistence, and build gates. Result: `Test-ReCall-2026.10.19_12-22-17--0700.xcresult` under ReCall-QC/Logs/Test; summary saved as `full-qc-fresh-carousel-summary.json`.

The final seamless-tan build also completed `./qc.sh --full` with exit 0 and QC GREEN. Its 24 UI tests passed with zero failures and zero skips, including the additional horizontal-swipe assertion. Engine, Harness persistence, card-title persistence, Pro-image persistence, deterministic KG output, and the native build all passed. Result: `Test-ReCall-2026.10.19_12-34-58--0700.xcresult` under ReCall-QC/Logs/Test, completed October 19 at 12:46 PDT. The physical iPhone is running this final code.

## Evidence directory

`/Users/adamblair/.codex/visualizations/2026/10/19/01a15550-786d-7151-87b2-d02e194093a5/pro-arrangement-preview`

- `iphone-navy-opening.png` and `iphone-navy-row.png`: revised native design preview.
- `iphone-live-pro.png`: earlier navy-body Pro page, superseded by the compact-header captures.
- `iphone-sand-*.png`: intermediate navy-header/tan-body screens before header unification.
- `iphone-uniform-*.png`: intermediate larger shared header, subsequently reduced at Adam’s request.
- `iphone-final-home.png` and `iphone-final-pro.png`: final white titles, sand controls, compact navy header, tan body, and white navigation.
- `physical-drag-proof/` and `physical-row-proof/`: native screenshots exported from successful physical XCTest results.
- `physical-compact-header-proof/`: seven screenshots from the successful three-test physical run.
- `physical-fresh-carousel-proof/` and `physical-horizontal-swipe-proof/`: successful picker, relaunch, drag, and native horizontal swipe evidence from the final build.
- `iphone-fresh-carousel-photo.png` and `iphone-fresh-carousel-relaunched.png`: real Photos and Files imports in the isolated empty row, including both images after relaunch.
- `fresh-carousel-import-complete/` and `fresh-carousel-import-proof.json`: the two fresh image files, index, destination row, order, and hashes read back from the phone.
- `iphone-live-carousel-add-image.png`: the normal collection's backpack carousel with Add image beside it.
- `physical-arrangement-check/`: readback of the isolated manual interaction session.
- `device-before-live/` and `device-after-live/`: real collection before and after installation and checks.
- `live-data-integrity.json`: all 10 original files unchanged; no automatic row membership.
- `device-after-final/` and `final-data-integrity.json`: final readback, matching file set and SHA-256 hashes for all 10 original files.
- `device-after-fresh-import-feature/` and `final-real-collection-readback.json`: all 10 original files unchanged; the current arrangement is the only additional file.
- `iphone-seamless-carousel.png`: physical iPhone capture of the final tan carousel padding, title area, and Add image surface.
- `seamless-color-readback.json`: matching color samples and coordinates from that unmodified phone capture.
- `device-before-seamless/`, `device-after-seamless/`, and `seamless-data-integrity.json`: all 13 current files unchanged across the color correction.
- `physical-final-calendar-log-proof.json`: preserved passing Calendar title-test log evidence; Xcode subsequently rotated its original result bundle.
- `full-qc-seamless-summary.json`, `full-qc-seamless-ui.log`, and `full-qc-seamless.log`: final 24/24 test result and green quality gate.

The earlier tan-page mockup and its initial data-integrity report remain in the same directory as historical design evidence. They do not describe the final palette or production persistence.
