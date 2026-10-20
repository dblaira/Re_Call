# Entry form sharing

The shared entry form has the same black `square.and.arrow.up` icon as SAVY at the bottom center. Its 30-point symbol sits in a 64-point circle, matching the existing FAB's size and position. The native glass treatment mirrors the circular Close and Save controls at the top. It remains available while scrolling and above the keyboard. There is no visible Share label; VoiceOver receives “Share.”

The circle rises 22 points above a solid, full-width, 1-point divider at the footer's top edge, matching the existing FAB's overlap. A white circular backing keeps the divider behind the button. The footer extends through the bottom safe area.

On iOS 26 and later, the circle uses Apple's [native Liquid Glass effect](https://developer.apple.com/documentation/SwiftUI/Applying-Liquid-Glass-to-custom-views), with a material-circle fallback on earlier supported versions. Bottom spacing aligns the circle with Understood's existing FAB.

Share opens the native destination picker directly with the entire form: current Decide questions and answers, the three Delegate fields, steps and metadata. There is no scope menu. The iPhone's share sheet still lets Adam choose where to send the text.

Original writing, line breaks and edited questions are preserved. Images and image paths are excluded. Sharing reads the current draft, including pending tags and date controls, without saving an entry or clearing the editor. Sharing again after an edit includes the latest writing.

Metadata includes the selected theme, Pattern, Lift, priority, energy, effort, tags, flags, status, notes, link, location, waiting-on text, dates and repeat information. The shared formatter and icon control match SAVY's implementation.

## Simulator verification

Functional testing ran exclusively in the simulator as Adam requested.

- iPhone 17 Pro Max simulator, iOS 27.
- Five export unit tests passed for exact writing, every Delegate field, steps, metadata, legacy questions, pending tags and image exclusion.
- The sharing UI test passed. It compares Share's center, width and height with the existing FAB, checks visibility above the keyboard, and opens native Copy directly without a scope choice.
- The test copies the entire draft, returns to the form, adds writing, and copies the entire form again. Both exports retain the exact text and metadata. Cancelling afterward creates no entry.

Direct-sharing result: `/tmp/understood-form-sharing-20261020/entire-only-focused.xcresult`; log: `/tmp/understood-form-sharing-20261020/entire-only-focused.log`. The screenshots below come from this successful run.

The final `./qc.sh --full` gate passed: engine/runtime checks, native build, five unit tests and all 25 UI tests, with no failures or skips. Its log is `/tmp/understood-form-sharing-20261020/entire-only-final-full-qc.log`; the result bundle is `/Users/adamblair/Library/Developer/Xcode/DerivedData/ReCall-QC/Logs/Test/Test-ReCall-2026.10.20_11-27-51--0700.xcresult`.

## Phone installation for Adam's inspection

The direct whole-form version's signed Debug build installed and launched on Adam's connected iPhone 17 Pro Max. Its receipts are `/tmp/understood-form-sharing-20261020/entire-only-phone-install.json` and `/tmp/understood-form-sharing-20261020/entire-only-phone-launch.json`.

Before installation, the app showed its main page with no open editor. Its saved reminders file, containing 35 entries, was byte-for-byte unchanged after installation. The installed app's main page was observed. Sharing interactions were tested in isolated simulator storage.

## Captured app screens

- [Share crossing the divider](share-icon.png)
- [Share stays available above the keyboard](share-keyboard.png)
- [Entire form opens directly in the native share sheet](entire-form-share-sheet.png)
- [Entire form shared again after an edit](updated-form-share-sheet.png)
- [Editor after sharing](editor-after-sharing.png)
