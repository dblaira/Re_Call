# Re_Call Agent Instructions

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

**Current lane:** TestFlight-valid native iOS; extend graph-promoted product rules into recommendation UI — do not App Store submit without Adam. Do not expand scope without Adam saying so.

## How agents use Adam's Macs (required)

Adam signed up for Tailscale so agents work **on his real computers** — the ones already signed into his accounts — not on a blank rented machine that has to fight every login.

**Default rule:** Do the work on his Macs. Prefer `studio` (Mac Studio). Use `mbp` or `mbp2` when the task belongs there.

When Tailscale is joined (secrets `TAILSCALE_AUTHKEY` + `TAILSCALE_SSH_KEY`):
- `ssh studio` — Mac Studio — primary
- `ssh mbp` — MacBook Pro
- `ssh mbp2` — MacBook Pro 2

**Do not say you cannot access his files, apps, builds, or signed-in sessions** without first trying his Macs. If a website or app needs a login, do it from his Mac (already trusted), not from the cloud box.

If Tailscale is not joined yet, run: `bash .cursor/tailscale-join.sh`

