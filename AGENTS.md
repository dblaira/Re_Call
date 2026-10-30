# Re_Call Agent Instructions

## Delegate entry boxes — October 29, 2026

Adam: “One other request.  Match the Delegate entry boxes to the other entry forms.  They should not be muted and disappear when text is entered. They should be the same as Decide, and Visual.”

This current direction supersedes the temporary muted-placeholder styling in Delegate. Keep each Delegate question permanently visible in black regular text, matching Decide and Visual. Put the growing answer directly below it with no extra stack gap. Use the existing question font and crimson icon treatment in both apps. Preserve font sizes, field identifiers, writing bindings and data models. Question and icon taps focus the matching answer. The whole-row tap guard uses the active field so returning from a UIKit question editor works without moving the caret inside an already-focused Delegate answer.

The correction is installed and directly inspected in SAVY’s actual Mac Social form and in both physical-iPhone apps. All three Delegate questions match Visual’s dark body styling. Tapping the first prompt placed the caret directly below it. Blank live forms were canceled without writing or saving. SAVY’s final focused UI tests passed 2/2 with zero failures. All four Mac archives are byte-identical after installation and cancellation. Understood’s 14 phone files are byte-identical; SAVY’s writing and media are unchanged, with only two CloudKit metadata files changed among 24 files. Understood full QC is still running after one existing ProArrangement file-picker case failed at an immediate Menu retap with invalid coordinates; an unchanged retry is pending. Commit, push and final-revision GitHub verification are pending. Preserve each app’s active-editor and saved-data requirements before future installations.

Evidence: [Delegate entry boxes](<docs/Delegate entry boxes.md>).

Reference `WORKING_PATTERNS.md` when available. Start by deciding whether the request is Phase 1 ("help me judge this") or Phase 2 ("execute requirements"). If the task touches visible product behavior, wording, visual design, recommendations, ontology, or agent communication, apply the strategy below before making decisions.

## Native iOS Rule

Re_Call is a 100% native Apple-platform app.

The shipped iPhone app must be built in Xcode using Swift, SwiftUI/UIKit, and Apple native frameworks. Do not implement the iOS product as a web app, PWA, WebView shell, React Native app, Capacitor app, Expo app, TypeScript frontend, or browser-hosted experience.

Supabase may remain backend, auth, storage, and sync infrastructure. It is not the iOS runtime.

Device validation should prioritize real iPhone hardware. Avoid simulator-first thinking unless Adam explicitly requests it for a narrow diagnostic.

Acceptance criteria: if it is part of the shipped iPhone app experience, it should feel, behave, and integrate like a real App Store iOS app with direct access to Apple platform capabilities.

## Plan Overview Rule

Adam keeps `docs/recall-migration-map.html` on screen as the living status board. Suite-wide progress: `/Users/adamblair/Developer/GitHub/SAVY-iOS/docs/understood-suite-migration-map.html`.

When sharing multi-step plans or migration status: **overview first** — one sentence, horizontal progress track (all steps on one screen), "HERE" on current step, one-line next move. Details below or collapsed. Update the HTML when milestones change. See `.cursor/rules/plan-overview.mdc`.

## Execute, Don't Delegate

If the agent can run it (git, shell, `xcodebuild`, `gh`, `./qc.sh`, deploys, file edits), **the agent runs it**. Do not return long manual steps or Xcode menu tutorials for work the agent can execute. Ask Adam only for human-only actions (unlock phone, passwords, design judgment) — one sentence, no checklist. See `.cursor/rules/execute-dont-delegate.mdc`.

## Product Rule

This app is being built for Adam first. Adam's taste, language, understanding, and natural reaction are the acceptance criteria. Do not optimize for a hypothetical average user before Adam has reacted.

If Adam does not understand the agent's explanation, naming, or proposed implementation, treat that as a product risk, not a communication footnote.

## Re_Call-Specific Contract

Read `.cursor/rules/recall.mdc` for QC gates, layer boundaries, and iOS gotchas.

- Before shipping: `./qc.sh` green (`./qc.sh --full` when iOS behavior changed).
- Before touching iOS: read `HANDOFF.md` and `ios/AGENT_BUILD.md`.
- Ontology edits: `ontology/validate.sh` must pass.
- **Native only** — no WebView restoration. See `HANDOFF.md` for retired web layer.

## Technical Boundaries

- Swift and Apple frameworks are the app runtime (`ios/ReCall/`).
- Xcode project: `ios/ReCall.xcodeproj`, scheme `ReCall`.
- Node engine / ontology: `src/`, `ontology/` — do not cross layers in one pass unless the task requires it.
- Supabase: `supabase/migrations/`, `src/supabase-*.js`.
- No WebKit/WebView in the app target unless Adam explicitly reverses this rule.
- No JavaScript application runtime in the iOS app.

## Current Lane

Update this line when the active milestone changes:

**Current lane:** October 29 Delegate entry boxes: permanent black regular questions and answers directly below are installed and inspected in SAVY on Mac and in both physical-iPhone apps. Font sizes and data models are preserved. SAVY’s two focused UI tests passed. Saved writing and media are unchanged. Understood full QC remains pending after an existing file-picker test failure; the unchanged case will be retried. Commit, push and final-revision GitHub verification remain pending. See [Delegate entry boxes](<docs/Delegate entry boxes.md>).

Historical previous lane:

**Previous lane:** October 29 entry forms: SAVY’s Visual addition and consistent styling are implemented in Re_Call/Understood (`sh.notorious.app`). Reminder/Action/Event share one native form. The signed Debug app is installed. The physical blank Action form was inspected with both selectors closed and open; all twelve Visual choices showed red icons. Summarize updated four prompts; tapping the first prompt placed the cursor directly below it. No writing was entered; Cancel returned Home. All 14 saved files and 37 reminders are byte-identical to the preinstallation backup. Earlier legacy field-visibility assumptions were corrected without weakening assertions. Final full QC is green: all 11 unit tests and 32 UI tests passed together with zero failures or skips. All five Visual cases passed. All 17 source/build/test hashes still match the tested files. Source feature commit `fd771e397c0295abf8138411b02ca3e7d00a6a6c` passed its [GitHub iOS Build](https://github.com/dblaira/Re_Call/actions/runs/41006449225). The committed source snapshot matches all 17 tested hashes. The final source cleanup removed unused Catalyst code; iOS runtime UI code is unchanged. Final native device build/reinstallation and normal launch passed again, and all 14 files still match the first baseline. See [entry forms](<docs/entry forms.md>). Adam approved Pro as finished: preserve its exact appearance and features unless he explicitly requests a Pro change. No App Store submission.

## How agents use Adam's Macs (required)

Adam signed up for Tailscale so agents work **on his real computers** — the ones already signed into his accounts — not on a blank rented machine that has to fight every login.

**Default rule:** Do the work on his Macs. Prefer `studio` (Mac Studio). Use `mbp` or `mbp2` when the task belongs there.

When Tailscale is joined (secrets `TAILSCALE_AUTHKEY` + `TAILSCALE_SSH_KEY`):
- `ssh studio` — Mac Studio — primary
- `ssh mbp` — MacBook Pro
- `ssh mbp2` — MacBook Pro 2

**Do not say you cannot access his files, apps, builds, or signed-in sessions** without first trying his Macs. If a website or app needs a login, do it from his Mac (already trusted), not from the cloud box.

If Tailscale is not joined yet, run: `bash .cursor/tailscale-join.sh`


## Skills to load (do not skip)

Always: requirement-is-the-test, adams-words, no-time-estimates, cognitive-fit, articulate-leadership-communication.

Stack (when editing matching files): see `.cursor/rules/stack-*.mdc` — nextjs / react-best-practices / figma-swiftui / aws-lambda / context7 / systematic-debugging.

If the same mistake happens twice: create a rule. Prefer system over apology.

