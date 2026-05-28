# Supabase GitHub Connection

Supabase currently shows no connected GitHub repository for `Re_Call`.

That is okay right now.

## Current Truth

- Vercel deploys the app from the repo.
- Supabase project `Re_Call` is active and healthy.
- Supabase project ref is `vzaceoipwimphdvdxcpa`.
- The production database already has the `recall` schema, RDF tables, and Neo4j projection views.
- The Supabase Edge Function `recommendations` is active with JWT required.
- Vercel Production has the Supabase environment variables.

## What The Missing Connection Means

The missing GitHub connection only means Supabase is not automatically syncing migrations or Edge Functions from GitHub.

It does not mean the database is disconnected from the app, broken, or missing data.

## Risk

Future manual Supabase changes can drift from the repo if migrations, SQL notes, or Edge Function updates are not copied back into version control.

## When To Connect It

Connect Supabase to GitHub when any of these become true:

- Supabase schema changes start happening often.
- Edge Functions become part of the real app flow.
- A second person needs to review or deploy database changes.
- Re_Call needs repeatable staging/production database workflows.

## Future Checklist

1. Open Supabase project `Re_Call`.
2. Go to the GitHub integration or project settings area.
3. Connect the GitHub repository for `/Users/adamblair/Documents/Re_Call`.
4. Confirm which branch should be treated as the source of truth.
5. Make sure migrations and Edge Functions in `supabase/` match production before enabling automatic deploy behavior.
6. Re-check Vercel env vars after any Supabase key rotation.

Until then, treat this note as the reminder: no GitHub repository connected in Supabase is expected and okay.
