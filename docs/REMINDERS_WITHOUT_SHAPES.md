# Reminders without inspiration tiles

Adam requested removal of the Reminder shapes section because he uses Pro for
inspiration. The Reminders page now shows the existing active feed and Completed
control, without the heading or its five example cards. New reminders still use
the charge button. The list retains clearance above the bottom navigation.

The unused Reminders shape-picker callback and tile definitions were removed.
Shared template components remain for the approved Pro page; Pro implementation
and saved images were not changed.

## Physical iPhone

The updated build was installed on Adam's iPhone 17 Pro Max and the normal
collection was visibly inspected on October 21 at 09:50 PDT. The shapes are gone;
the existing reminder and Completed 28 remain. Device readback confirms all 14
Application Support files match the pre-update copy byte for byte, including
reminders, card titles, Pro images, their crop metadata, and the arrangement.

Three isolated physical checks passed with zero failures or skips:

- Native Reminders opens without the shapes heading or tile controls.
- A long reminder list scrolls to Completed, which opens its saved item.
- Scrolling still reaches Completed after holding a card to edit its title.

Result:
`/tmp/Understood-ProPinterest-device/Logs/Test/Test-ReCall-2026.10.21_09-49-28--0700.xcresult`.

The retired reminder-tile editing test was removed with the feature. Existing
scrolling tests now target Completed and use an isolated long feed that must
actually scroll before reaching it. Professional-template editing coverage remains.

The first full QC run passed 31 of 32 checks. Its one failure was in the updated
Completed scroll test: XCTest reported the collapsed control as hittable while
it was behind the bottom navigation. The captured hierarchy and screen recording
confirm the test tapped the obscured control. The scroll helper now requires the
whole control to sit above the floating button or keyboard before tapping. The
assertion that the saved completed item actually opens remains in place.

Both corrected simulator scroll checks passed at 10:11 PDT. The retained screenshot
shows Completed expanded with its saved item fully visible above the bottom bar.

Final `./qc.sh --full` is green on October 21 at 10:26 PDT: 27 UI tests and
5 unit tests passed, with zero failures or skips. Engine, native persistence,
deterministic KG output, and native build gates also passed. The final simulator
run again passed both corrected scroll checks and reminder reordering.

Final result:
`/Users/adamblair/Library/Developer/Xcode/DerivedData/ReCall-QC/Logs/Test/Test-ReCall-2026.10.21_10-11-41--0700.xcresult`.

Evidence:
`/Users/adamblair/.codex/visualizations/2026/10/19/01a15550-786d-7151-87b2-d02e194093a5/reminder-shapes-removal-2026-10-21`.
The before/after phone screenshots show the normal collection;
`physical-summary.json` and `physical-tests.log` record the isolated tests;
`data-integrity.json` records matching file sets and hashes.
`first-qc-summary.json` and `first-qc-failure-all/` retain the initial failure
and its captured screen for comparison with the corrected run.
`scroll-rerun-summary.json` and `scroll-rerun-attachments/` record both passing
scroll checks and the expanded Completed screenshot.
`full-qc-summary.json`, `full-qc.log`, and `full-qc-ui.log` record the final green run.
