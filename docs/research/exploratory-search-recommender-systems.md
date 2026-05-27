# Exploratory Search and Recommender Systems

Source: [OpenHPI Tutorials, "6.6 Exploratory Search and Recommender Systems"](https://www.youtube.com/watch?v=8WdaPCbZ1KE)

## Useful Ideas For Re_Call

The video separates retrieval from exploration:

- Retrieval: the user knows the target.
- Exploration: the user is still learning the shape of the goal.

Re_Call's reminder recommendations are exploratory. The user is not asking for a known reminder. A positive or negative reaction tells the system where to browse next.

## Linked-Data Recommendation Pattern

The lecture's practical pattern is:

```text
Start with one entity.
Find its graph properties or categories.
Find other entities that share those properties.
Rank candidates by shared property count.
Expose the shared properties as the explanation.
```

For Re_Call:

```text
Start with one reminder.
Find the strength or attention pattern it revealed.
Find reminder templates that deepen that same strength.
Rank candidates by shared graph features and depth.
Expose the graph path as the explanation.
```

## Re_Call Translation

The current proof case maps the idea like this:

| Video pattern | Re_Call pattern |
|---|---|
| Book | Reminder template |
| Category/class | Revealed strength or attention domain |
| Candidate book | Deeper reminder template |
| Shared categories | Shared graph features |
| SPARQL rank | Recommendation score |
| Explanation categories | Graph trace shown to the user/developer |

## Product Boundary

This supports the Re_Call rule:

```text
Do not recommend broader reminders in the same category.
Recommend deeper uses of the strength the reminder revealed.
```

The algorithm should stay inspectable:

```text
Why this recommendation?
Because this reminder revealed TimeAwareness, and this suggestion deepens TimeAwareness.
```
