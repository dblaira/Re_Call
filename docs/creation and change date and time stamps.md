# Creation And Change Date And Time Stamps

## Entry dates are available to agents (Executive Conclusion)

1. 🕒 Original creation dates survive subsequent saves. Entry changes update the change date.

2. 🤖 Whole-form sharing includes `Created` and `Changed` as ISO 8601 UTC instants with seconds. Unsaved form snapshots are identified separately.

## Date meanings stay separate (Consequence)

1. 📅 Creation and change dates are separate from due dates, event start/end dates, completion dates, publication dates, and export times.

2. 📖 Reading, reopening, and sharing do not stamp a new edit. Existing writing and known historical dates are preserved.

## Implementation and delivery (Recommendation)

The existing Reminder, Action and Event types all use the same timestamp behavior. Understood has no Social entry type. Original creation dates are protected at save/upsert. Inline card-title changes, including known dates received through title sync, update the owning entry without rewriting its original text. Existing Harness lifecycle exports retain the entry timestamps in their payload.

Saved Pro images now record a change date on import and metadata/title edits. Older images whose change date was never recorded retain an unknown value until a dated change is available; the upgrade does not invent history. Their original image bytes, dimensions, crop and creation dates are preserved. Card-title records now retain their own creation date for newly created overrides.

## Verification (Supporting Evidence on Request)

Signed iPhone builds passed. An existing Reminder was opened on the physical iPhone, shared with native Copy, and closed with Cancel. The copied text included `Created: 2026-10-22T18:03:42Z` and `Changed: 2026-11-01T06:00:48Z`, matching the saved record. No entry was saved during this inspection.

The initial postinstallation readback matched all 17 Application Support files byte-for-byte, including all 37 reminders and all 13 images. Backups are at `/tmp/entry-timestamps-before/understood` and `/tmp/entry-timestamps-after/understood`.

The isolated runtime regression passed save, completion, reopening, inline rename, reload and UTC export checks for every entry kind. Image runtime checks passed date initialization, metadata edits, legacy decoding without fabricated history, and original-byte preservation. The final full QC result is recorded below. Exact-commit GitHub iOS Build verification follows the scoped commit and push.

The final sharing regression reads actual native Copy output through native Paste in an isolated draft, checks both UTC timestamps and repeated edits, restores the draft, and verifies Cancel does not save it. Clipboard tests run serially across simulators. The calendar test now drags within the visible timeline when returning from evening hours to the all-day row. The empty-row import test reuses the existing picker-cancellation readiness helper and verifies dismissal before opening the next menu. These are test-helper changes; all existing assertions are retained.

Adam paused for laptop closure, then returned and authorized completion. SAVY’s final signed build, including its title-sync corrections, is now installed and its native Copy output verified again on the physical phone. Final SAVY archives preserve all authored content and entry dates; only two CloudKit transport files changed during normal launch/sync. Both apps are installed, and phone verification is finished.

Pre-existing Correlation → Causation changes remain outside this timestamp commit. The full local QA includes those existing working-tree changes; the timestamp commit stages only its own test extension in the mixed EntryShareContentTests.swift file.

Full QA passed on November 12, 2026: all nine `./qc.sh --full` gates were green, exit 0. The run passed 47 tests (14 unit and 33 UI), with zero failures. Final logs: `/tmp/entry-timestamps-understood-qc-verified.log` and `/Users/adamblair/Library/Developer/Xcode/DerivedData/ReCall-QC/qc-ui-tests.log`. Result bundle: `/Users/adamblair/Library/Developer/Xcode/DerivedData/ReCall-QC/Logs/Test/Test-ReCall-2026.11.12_17-49-20--0800.xcresult`. All 14 changed source/test file hashes match the frozen files used for this final run.
