# Shop / Ship / Undertow

This is a constraint doc. It reframes Re_Call as a **shopping-and-shipping app**. It pairs with the [Personalization System Doctrine](./personalization-system-doctrine.md) and the [Design Philosophy](../design/design-philosophy.md).

## The Loop

```text
Shop -> Ship -> Undertow -> Resurface
```

The merchandising metaphor is not a new system. It is the existing three-layer × two-channel recommender, re-described to sell.

## Shop

Browsing pleasure. The user scans the Pinterest-style masonry of Lenses and templates, drawn by covers and beauty, picking what appeals.

```text
Desire-led, not efficiency-led.
"Use this lens" == add-to-cart.
```

## Ship

Build and *own*. Rearrange, hide, delete, rename; Save-as-Lens; then ship the personalized practice into real life.

Owning the custom version is the core reaction. The user does not buy the template — they build the thing they would rather have, and that ownership is the point.

## Undertow

The unseen, deterministic engine: Ontology + Knowledge Graph + recommender, reading real-world use (ratings, edits, signals) and quietly pulling deeper.

```text
Calm/ambient tech, not a coaching black box.
The reminder is the cover.
The engine is beneath.
Deeper, not broader.
```

## Resurface

The undertow returns its suggestions as fresh "arrivals." Shopping restarts. The recommender stops being a settings panel and becomes a self-restocking storefront.

## Mapping to the Existing Engine

The three behaviors — *deepen / disappear / flip* — map directly onto the current recommender:

```text
Deepen          = learned affinity
Disappear       = decay / dismissal
Flip-on-a-whim  = declared-goal channel + novelty/rotation
```

Flip-on-a-whim is what swaps the per-lens covers, backgrounds, and arrangements — switching the whole "store section" at once. So the merchandising metaphor *is* the three-layer × two-channel recommender, just told in a language that sells.

## Implications

- Make ownership and delivery *felt* in the UI. Shipping should read as a real act, not a save.
- Frame resurfaced picks as **"new arrivals in the areas you've been deepening."**
- Turn the recommender from a settings surface into a storefront that quietly restocks itself.
