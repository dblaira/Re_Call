# Pro saved images and poster viewer

Requested outcome: “Start with the saved image cards and zoomable poster viewer on the Pro page in Understood.”

## Delivered behavior

- Pro opens a saved-image collection. Native Photos and Files pickers lead to an image preview with optional title, source URL, and notes, then Save.
- Two independent lazy columns preserve portrait, landscape, and square image proportions. Each card has a pencil button for its inline title editor; holding the title also opens it.
- Tapping opens the saved image, without creating a reminder. The native viewer supports pinch, pan, double tap, zoom in/out, and fit. Closing returns to the same card position.
- Image details expose the source link, copying the source, and editable notes. Copy shows a checkmark after writing the URL to the clipboard. Image options provide sharing and confirmed removal.
- The existing Pro templates remain under Templates. Reminder shapes and the icon-only sand/navy/red swipe controls remain in place.

## Persistence

`ProImageArchive` serializes imports and edits. Imported image bytes are stored without app recompression alongside an atomic JSON index in Application Support/pro-library. Saving does not create reminders, notifications, or Harness exports. This first collection is local to the device. Thumbnails and the viewer decode off the main thread; originals are retained at their imported resolution. The viewer decodes up to 6,000 pixels on its long side to bound memory use.

The test store uses RECALL_UI_TEST_ISOLATED and a unique session directory. Test posters never populate the normal collection.

## Initial implementation verification — October 18

- Physical iPhone 17 Pro Max, iOS 27.2: both ProImageTests passed in `/tmp/Understood-ProImages-device-tests-3.xcresult`. The tests exercise pinch, double tap, panning, zoom controls, edited-note persistence through relaunch, and return position within two screen points.
- Physical-device screenshots were inspected for the saved-card layout, enlarged poster, and saved source/notes. The production launch was separately opened in Device Hub and its empty Pro collection was visibly confirmed.
- Adam then supplied a physical-iPhone screenshot showing his own two saved cards, including “Adam to Understood,” in the normal Pro collection.
- Photos import and Files import were exercised through their real system pickers on the task-owned iOS 27 simulator. Two resulting cards were read back from disk; each retained the exact fixture PNG bytes. Title, source, and keyboard-entered notes were checked in the viewer and on disk. Both imported cards were visibly retained after installing the final build and reopening Pro in the same isolated session.
- `scripts/test-pro-image-runtime.sh` passed: original bytes, dimensions, source, notes, relaunch, edit identity, invalid imports, removal, and corrupt-index preservation.
- The installed device app passed strict code-signature verification. The live reminder cache contained 35 records and was byte-for-byte unchanged across the device tests.
- Full QC was incomplete at the bedtime pause. Run 2 finished with 15/16 tests passing; the template-title test received SIGTERM when an older overlapping Xcode process was terminated. A clean third run was stopped at Adam’s explicit request to pause for the night. Engine, persistence, and build gates passed before that pause. Those runs are not evidence of a passing full gate; current results belong to the October 19 repair below.

## Controls repair — October 19

Adam reported that the second card's title control did not work, then asked: “don't worry about which one, just test them all. Don't give me stuff to do”.

The defect was reproduced on the physical iPhone and by the failing regression in `/tmp/Understood-ProControls-title-before-sim.xcresult`: inline edits lived in `CardTitleStore`, while the details editor loaded the original archive title. Saving details left the older inline override visible. The editor now loads the current display title and a successful details save resets the obsolete override. A visible pencil opens the existing inline editor on every saved-image card.

Physical iPhone 17 Pro Max, iOS 27.2, direct Device Hub interaction:

| Control | Observed result |
| --- | --- |
| Pencil / inline title | Entered and saved a title on the second fixture and on a new untitled Photos import. The actual second user card's pencil also opened its editor; Cancel preserved its title. |
| Edit details / Save | Loaded the visible title; saved a replacement title and notes; viewer and details agreed. |
| Source link | Opened the exact source in Safari; the Understood return link returned to the viewer. |
| Copy source | Showed its checkmark; native Paste into the source field yielded the full expected URL. |
| Share image | Opened the native share sheet with the original PNG, thumbnail, and file size. No recipient was selected. |
| Remove image | Outside-tap dismissal kept the image. Confirming removed only the selected fixture; the nine remaining original fixture images were byte-identical. |
| Photos / Files import | Both real native pickers saved an image in the isolated collection. An untitled Photos import accepted a later inline title. Both cards and their titles survived relaunch and were read back from the device. |
| Cancel import / picker | Preview Cancel and closing either picker returned without adding a card. |
| Add your first image | Opened Photos from a separate empty isolated collection. |
| Templates / Saved images | Switched between both surfaces and returned to the saved collection. |

The final signed Debug build is installed as `sh.notorious.app`. The phone is back in the normal Pro collection. Its two-card index and both original image files match the pre-test backup byte for byte. The isolated imports, title edits, and removal never populated that collection. The current physical XCTest runner required a passcode, so current automated coverage runs on the task-owned iOS 27 simulator; physical interaction was checked directly instead.

All five focused Pro regression tests passed on the task-owned iOS 27 simulator in `/tmp/Understood-ProControls-tests-2.xcresult` (completed xcodebuild exit 0). Coverage includes second-card pencil and long-press editing, Cancel, outside-tap Save, keyboard geometry, details-title consistency, relaunch, Restore original, source validation, copy feedback reset, zoom controls/gestures, note persistence, removal cancellation/confirmation, and return position. The title-above-keyboard and persisted-title screenshots were inspected.

**Full QC GREEN:** `RECALL_QC_SIMULATOR_ID=06E039C5-2271-45B0-B877-26FC07042661 ./qc.sh --full` completed with exit 0 on October 19 at 08:50 PDT. All 19 UI tests passed with zero failures, including all five Pro tests plus the existing template, reminder, form, scrolling, and reorder tests. Engine, Harness capture, card-title persistence, Pro-image persistence, recommendation compilation, and native build gates passed. This is a single completed run, with no overlapping test runner. Log: `/tmp/understood-pro-controls-qc-full.log`. Final bundle: `/Users/adamblair/Library/Developer/Xcode/DerivedData/ReCall-QC/Logs/Test/Test-ReCall-2026.10.19_08-40-06--0700.xcresult`.

The October 19 checkpoint includes the five swipe-control edits in ActionsHomeView, CalendarView, ItemListView, RemindersHomeView, and UpNextCardRow alongside the Pro collection, title repairs, tests, and verification notes.

## Keyboard correction — October 19

Adam reported: “When opening the saved image to change the title, the keyboard on the iphone does not open.” The earlier physical check typed through the Mac and did not verify the phone's onscreen keyboard. Its title-saving evidence was valid, but it did not prove keyboard presentation.

Reproduced on the actual second saved image: the editor and caret appeared with no keyboard. Toggling Device Hub → Device → Keyboard → Simulate Hardware Keyboard off and reopening the editor made the keyboard appear. Capture Keyboard was already off; that separate setting was insufficient. Actual onscreen key taps changed an isolated fixture's title.

The phone's onscreen Done key then inserted a newline instead of finishing. `/tmp/Understood-ProKeyboard-before.xcresult` reproduced that failure (completed exit 65). The inline field now recognizes a single inserted newline as submission and preserves the current title. `/tmp/Understood-ProKeyboard-after.xcresult` passes the new onscreen-key regression (completed exit 0), including details editing and saved-title persistence after relaunch.

The updated signed Debug build from `/tmp/Understood-ProKeyboard-device/Build/Products/Debug-iphoneos/ReCall.app` passed strict code-signature verification and is installed on the physical iPhone. With hardware-keyboard simulation off:

- Actual onscreen taps edited the second fixture title. Tapping the blue Done key saved it and dismissed the editor and keyboard; the card and viewer showed the saved value.
- Opening Edit details and tapping its title displayed the onscreen keyboard. Actual phone keys replaced text; Save updated the viewer. The resulting title survived terminating and relaunching the app and was read back from the device's isolated archive.
- Both of Adam's original card pencils displayed the keyboard. Opening the actual “Adam to Understood” image, choosing Edit details, and tapping its title also displayed the keyboard. Cancel preserved both original titles.
- The phone is back in the normal Pro collection. Its index and both original image files remain byte-for-byte identical to the pre-test backup. Verification: `keyboard-user-image-integrity.json`. Device readback: `/tmp/Understood-ProKeyboard-device-readback`; isolated test readback: `/tmp/Understood-ProKeyboard-fixture-readback`.

**Full QC GREEN for the final code:** `RECALL_QC_SIMULATOR_ID=06E039C5-2271-45B0-B877-26FC07042661 ./qc.sh --full` completed with exit 0 on October 19 at 10:30 PDT. All 20 UI tests passed with zero failures, including the six Pro tests, five shared card-title tests, six smoke tests, and three scrolling/reorder tests. Engine, Harness capture, card-title persistence, Pro-image persistence, recommendation compilation, and native build gates passed. Finalized result bundle: `/Users/adamblair/Library/Developer/Xcode/DerivedData/ReCall-QC/Logs/Test/Test-ReCall-2026.10.19_10-20-09--0700.xcresult`. Logs: `/tmp/understood-pro-keyboard-qc-full.log` and the evidence copies below. This completed run supersedes the earlier 19/19 result for the Done-key change.

Keyboard evidence in the same `pro-controls-repair` folder:

- `iphone-original-card-keyboard.png` and `iphone-original-details-keyboard.png`: the keyboard on Adam's actual second card and opened image title.
- `iphone-title-done-saved.png`: fixture title saved by tapping the phone's Done key.
- `iphone-details-onscreen-typing.png` and `iphone-keyboard-title-relaunch.png`: onscreen entry in details and the persisted title after relaunch.
- `keyboard-regression-before.log`, `keyboard-regression-after.log`, `keyboard-device-build.log`, `keyboard-full-qc.log`, and `keyboard-full-ui-tests.log`: reproduced failure, passing targeted regression, signed device build, and completed full quality gate.
- `keyboard-fixture-persistence.json`: exact saved title read back from the isolated device archive; all nine neighboring fixture titles unchanged.

## Saved evidence

Evidence folder: `/Users/adamblair/.codex/visualizations/2026/10/19/01a15277-65c7-7871-8b3a-99fb7c2110c2/pro-images-implementation`.

- `iphone-pro-installed.png`: normal collection on Adam’s iPhone, with no seeded cards.
- `iphone-user-saved-images.png`: Adam’s supplied screenshot of his two saved images in the normal collection.
- `iphone-cards-test-fixtures.png`, `iphone-poster-zoom.png`, `iphone-poster-saved-details.png`, `iphone-return-position.png`: real device tests using isolated poster fixtures.
- `simulator-photos-and-files-import.jpg`, `imported-test-cards.json`: actual picker imports and saved metadata.
- `device-tests.log`: final physical-device test run.

Current repair evidence: sibling folder `pro-controls-repair`:

- `iphone-title-source-notes.png`: saved title and notes with copied-source feedback on the physical iPhone.
- `iphone-photos-files-import.png`: both native imports saved in the isolated collection.
- `iphone-second-card-editing.png`: actual second user card's title editor open.
- `iphone-pro-final.png`: normal collection with its original two cards and visible pencil buttons.
- `pro-regression-tests.log`, `simulator-title-above-keyboard.png`, `simulator-title-persisted.png`: completed 5/5 focused regression run and rendered title checks.
- `user-image-integrity.json`: matching before/after SHA-256 values for the user's image index and both original images.
- `full-qc.log`, `full-ui-tests.log`: completed full quality gate, 19/19 UI tests passed.

Fresh local device backup: `/tmp/Understood-ProControls-backup-before`; post-check data: `/tmp/Understood-ProControls-user-data-after`. Isolated physical test readback: `/tmp/Understood-ProControls-fixtures-final`.

The first viewer test attempted to append notes by tapping the empty center of a multiline field; iOS inserted text at the beginning. The test now taps after the first line and asserts the exact edited value before saving. The original persistence assertion remains. Visual inspection also found that changing viewer height could retain an old image offset; the viewer now recenters the fit image when its bounds change.
