---
title: Watch Capture Requirements
date: 2026-06-23
topic: watch-capture
type: requirements
---

# Watch Capture Requirements

## Summary

Build a Watch-first capture experience for Notorious Recall that records immediately, saves reliably, and lets Adam replay or append to recent memos from the Watch. The iPhone companion app is where rich metadata, personalized concepts, and notes become explicit during later review.

---

## Problem Frame

The motivating scenario is a run or cooldown walk where an idea, frustration, or market observation hits while Adam is sweaty, distracted, and trying to keep his wrist steady. The phone may be nearby, but the touchscreen can be practically useless in that state.

The memo may be worthless or worth millions. The product should not judge that in the moment. Its job is to preserve the observation with enough context that later review can decide whether the problem is noise, a solvable irritation, or a market inefficiency worth pursuing.

---

## Key Decisions

- **Capture beats interpretation.** The first version must record and save. It must not summarize, classify, file, route, extract tasks, or judge feasibility.
- **Audio is the source of truth.** Transcription is useful, but a transcript failure cannot make capture feel failed if the audio is saved.
- **Watch re-engagement is core.** Playback and append matter because the idea often matures minutes later while Adam is still away from a usable phone.
- **Metadata supports later judgment.** Metadata should preserve factual context and review state; personalized concepts and notes are added deliberately in the iPhone app.
- **Custom wake words are out.** The app can support Siri/App Shortcut phrases and physical Watch launch paths, but it cannot rely on an always-listening private phrase like "Listen Notorious."

---

## Actors

- A1. Adam records, replays, appends, and later reviews memos.
- A2. Apple Watch provides the fastest capture and re-engagement surface.
- A3. iPhone companion app provides richer review, metadata, concepts, and notes.
- A4. Agents may later consume saved memos, but they do not decide meaning during capture.

---

## Requirements

**Watch capture**

- R1. The Watch app must support a physical launch path and a Siri/App Shortcut phrase as first-class entry points.
- R2. Launching the capture path must start recording immediately.
- R3. The recording state must provide clear confirmation that capture has started.
- R4. Stopping a recording must save the raw audio before any transcript or downstream processing is attempted.
- R5. Each saved memo must preserve the original audio even when transcription is unavailable, delayed, or failed.

**Playback and append**

- R6. The Watch app must show a simple list of recent memos.
- R7. A memo in the recent list must be playable from the Watch.
- R8. A memo in the recent list must support appending more audio from the Watch.
- R9. Appended audio must remain connected to the original memo while preserving segment history.
- R10. The Watch app must make re-engagement possible without requiring the iPhone.

**Transcript and artifact shape**

- R11. Each memo should have raw audio and a plain transcript when transcription succeeds.
- R12. The transcript must preserve what was said without summarizing, classifying, or assigning meaning.
- R13. Transcript status must be explicit so Adam can distinguish complete, pending, and failed transcription.

**iPhone companion review**

- R14. The iPhone companion app must expose rich factual metadata for each memo.
- R15. Metadata must include capture time, total duration, segment count, segment timing, source device, launch path when known, transcript status, playback state, append state, and handoff/export state.
- R16. The iPhone companion app must expose Adam's personalized concepts for deliberate review.
- R17. The iPhone companion app must provide a notes section for specialized context that was not known during capture.
- R18. Concept selection and notes belong in the iPhone review flow, not in the Watch capture flow.

**AI boundary**

- R19. The system must not use AI to summarize, classify, file, route, extract tasks, or judge feasibility during capture.
- R20. Agents may later consume the saved memo artifacts only after Adam deliberately points them at the material.

---

## Key Flows

- F1. Fast new capture
  - **Trigger:** Adam launches capture from a Watch surface or Siri/App Shortcut phrase.
  - **Actors:** A1, A2
  - **Steps:** Recording starts immediately; Adam speaks; Adam stops recording; raw audio saves first; transcript generation happens after audio save.
  - **Outcome:** The memo exists even if transcription is delayed or fails.
  - **Covered by:** R1, R2, R3, R4, R5, R11, R13

- F2. Re-engage and append
  - **Trigger:** Adam wants to add detail minutes after the first capture.
  - **Actors:** A1, A2
  - **Steps:** Adam opens the recent memos list; selects the relevant memo; plays it if useful; appends new audio; stops recording; the new segment saves under the same memo.
  - **Outcome:** The idea can grow without starting a disconnected second memo.
  - **Covered by:** R6, R7, R8, R9, R10

- F3. Later iPhone review
  - **Trigger:** Adam is ready to examine captured memos deliberately.
  - **Actors:** A1, A3, A4
  - **Steps:** Adam opens a memo on iPhone; reviews audio, transcript, and factual metadata; adds personalized concepts and notes; decides whether to hand the memo to an agent.
  - **Outcome:** Judgment happens when Adam has the attention and interface to make it useful.
  - **Covered by:** R14, R15, R16, R17, R18, R19, R20

---

## Acceptance Examples

- AE1. **Covers R2, R4, R5.** Given Adam is running and launches capture from the Watch, when he starts speaking and stops the recording, then the raw audio is saved even if the transcript is not ready.
- AE2. **Covers R6, R7, R8, R9.** Given Adam recorded an idea at the start of cooldown, when he opens the recent memos list and chooses that memo, then he can play it back and append more detail without using the phone.
- AE3. **Covers R11, R12, R19.** Given transcription succeeds, when the memo appears in review, then the transcript is plain captured speech and does not include a summary, category, task list, or feasibility judgment.
- AE4. **Covers R14, R15, R16, R17, R18.** Given Adam reviews a memo later on iPhone, when he opens the memo, then he can see factual metadata, choose personalized concepts, and add notes without the app having pre-filed the idea.

---

## Scope Boundaries

### Deferred To Planning

- Final inbox, storage, and export destination.
- Exact persistence model for audio, transcript, segments, metadata, concepts, and notes.
- Detailed Watch and iPhone visual design.
- Permission and privacy handling for optional contextual metadata such as workout or location context.

### Outside This Product's Identity

- A private always-listening custom wake phrase.
- AI deciding what the memo means.
- Automatic filing, routing, summarization, task extraction, or market-feasibility judgment.
- Treating Apple Voice Memos as the primary product path.

---

## Outstanding Questions

### Deferred To Planning

- Where should saved memo artifacts live so they are reliable on-device and later easy for agents to consume?
- Which metadata fields are always captured, which require permission, and which are derived only from user review actions?
- How should appended segments appear in playback and transcript review?
- What is the minimum Watch UI that makes recording, playback, append, and recent-list navigation usable while running?

---

## Sources And Constraints

- `AGENTS.md` sets Adam's reaction and understanding as the acceptance bar for Re_Call product decisions.
- `docs/product/personalization-system-doctrine.md` frames personalization as user correction and explicit signals, not generic AI interpretation.
- `docs/product/ios-feature-roadmap.md` already names Apple Watch companion work as an adjacent product direction.
- Apple App Intents and App Shortcuts documentation supports Siri/Shortcuts invocation, but not a private third-party always-listening wake word.
