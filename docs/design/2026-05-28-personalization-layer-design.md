# Personalization Layer — Design

Date: 2026-05-28
Status: Approved design, ready for implementation plan

## Problem

The current recommendation engine (`src/reminder-recommendation-engine.js`) is correct
but impersonal. Given a liked reminder it returns deeper uses of the strength that
reminder revealed — but it returns the **same** set for every user. The ontology is a
*universal* meaning layer; by design it cannot personalize.

The goal is a personalization layer that decides *which* deeper moves fit *this* person,
and that can actively guide the user toward a declared aspiration — for the first user,
using more of the 80/20 (leverage) principle in life and lifestyle.

A behavior-only personalizer would fail that goal: it mirrors existing habits and would
under-serve the very thing the user is trying to *become*. So aspiration must be a
first-class, declared input — not something the system waits to learn.

## Model: three layers × two channels

### Three scoring layers

```
finalScore = depthScore        // universal: what is deeper (ontology, unchanged)
           × learnedAffinity    // habit: what this user already gravitates to
           × goalWeight         // aspiration: who this user wants to become
```

- **Universal (existing):** templates → strengths → `depthScore`, plus the
  "deeper, not broader" doctrine. Unchanged.
- **Learned affinity (new):** a per-user, per-strength score inferred from signals.
- **Goal weight (new):** a per-user, per-strength prior the user *declares*. For the
  first user, `Leverage` (`LeverageAwareness` + `ExecutionLeverage`) is the top weight.

### Two channels

Goal weight must not corrupt focused recommendations, or it would break the doctrine
(injecting leverage into a TimeAwareness reminder is *broadening*). So the layer runs in
two channels:

1. **Reactive** — triggered by a specific liked reminder. Recommendations stay **within
   the revealed strength**. Goal weight only breaks ties and boosts candidates that also
   touch a high-goal strength. The doctrine holds; the deeper-not-broader test stays green.

2. **Proactive guidance** — not tied to any one liked reminder. This is where the
   declared goal **leads**. It surfaces in ambient app surfaces (the "Deeper" carousel,
   the home ring, a daily nudge). There is no revealed strength to stay within, so leading
   with leverage is honoring a declared priority, not broadening.

## The strength graph and propagation

The user chose "affinity propagates on the graph," which is what makes the knowledge
graph load-bearing rather than decorative.

- **Adjacency is derived, not hand-authored.** Two strengths are neighbors when templates
  deepen both (co-occurrence in `revealsStrength` / `deepensStrength`). Edge weight =
  normalized co-occurrence count. Optional explicit `recall:relatedStrength` edges may
  augment this later.
- **Affinity is event-sourced.** Every signal is logged; affinity is *computed* from the
  log, never mutated in place. This keeps the engine reproducible and re-tunable.
- **Propagation is one diffusion step:** `affinity = raw + spread · (Adjacency · raw)`.
  A bump to one strength spills a tunable fraction onto its graph neighbors.

## Signals

| Signal | Δ to raw affinity |
|---|---|
| Edit a template into a custom version | **+0.30** (product thesis — strongest) |
| Positive rating | +0.15 |
| Accept a recommendation | +0.10 |
| Dismiss / skip | −0.10 |

Each signal touches the strengths revealed/deepened by the template it acted on. Deltas
are tunable constants, not magic — they live in one config object and are applied **at
compute time, not write time**. An event row stores the durable `signal_type`, never the
numeric delta; re-tuning a weight therefore re-scores all history without migrating rows.

## Cold start

A new user has all `learnedAffinity = 1.0` (neutral) and only their declared goal weights.

- **Reactive** order with neutral affinity == today's universal order (graceful fallback).
- **Proactive** still works immediately, because it is driven by *declared* goal weight,
  not learned history. A leverage-goal user receives leverage guidance from day one,
  before any leverage behavior exists. This is the point of separating aspiration from habit.

## Guardrails

- **Doctrine preservation:** reactive recommendations are filtered to candidates sharing
  the revealed strength *before* personalization re-ranks them. Personalization can only
  reorder within the deeper set; it can never surface a broad pick.
- **Anti-nag:** proactive leverage nudges have a frequency budget and rotate through the
  five leverage-deepening templates, so guidance is persistent without repeating one item.

## Data model (Supabase — app truth)

- `user_strength_events` (source of truth): `user_id`, `strength_id`, `signal_type`,
  `template_id`, `config_version`, `created_at`. The numeric delta is **not** stored — it
  is derived from the signal-delta config at compute time. `config_version` records which
  delta config a row was written under, for auditability.
- `user_goal_weights` (declared aspiration): `user_id`, `strength_id`, `weight`.
- Derived affinity (materialized view or cache): `user_id`, `strength_id`, `raw_score`,
  `propagated_score`, `updated_at`.

The ontology remains the meaning source; Supabase holds per-user state. Clean separation.

## Units (each small, single-purpose, independently testable)

- `src/strength-graph.js` — ontology store → weighted strength adjacency.
- `src/user-affinity.js` — pure `(events, adjacency) → affinity vector` (raw + diffusion).
- `src/goal-weights.js` — load/apply a user's declared goal weights.
- `src/personalized-recommendation-engine.js` — wraps the universal engine: get deeper
  candidates → re-rank by `depthScore × learnedAffinity × goalWeight` → top N (reactive).
- `src/proactive-guidance.js` — goal-driven ambient nudges with frequency budget.
- `src/openai-reminder-copy.js` (existing) — receives affinity + goal context, writes the
  personalized "why." Phrasing only; it does not reorder.

## Testing strategy (the original requirement: test with zero users)

Because ranking is pure math, the personalized algorithm is tested by replaying scripted
signal streams — no real users, no historical dataset.

- **Habit shift:** a synthetic user who repeatedly engages emotional-prep → assert that
  candidate now outranks the default top pick (reactive).
- **Graph propagation:** bump one strength → assert a graph-neighbor strength's affinity
  rose and a non-neighbor's did not.
- **Aspiration beats habit:** a leverage-goal user with zero leverage history → assert
  they still receive proactive leverage guidance.
- **Doctrine under pressure:** a focused TimeAwareness reminder, even for a leverage-goal
  user → assert leverage is never surfaced in the reactive set (existing
  `test/recommendation-stays-deeper.test.js` must stay green).
- **Compounding:** accepting leverage nudges over time → assert learned affinity grows and
  compounds with the declared goal weight.

## Out of scope (for now)

- Multi-hop diffusion beyond one step (personalized PageRank). One step first.
- Learned goal weights (decay/reinforcement of declared priorities). Declared and fixed first.
- Explicit `relatedStrength` ontology edges. Derived adjacency first.
