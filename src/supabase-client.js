// src/supabase-client.js
//
// Builds a supabase-js client for server-side use in the Vercel/edge entry points.
// This is the ONLY module that imports @supabase/supabase-js, so the rest of the codebase
// (and the whole test suite) stays free of that dependency.
//
// Two modes, decided by whether an end-user access token is supplied:
//
//   accessToken present  -> anon key + Authorization: Bearer <jwt>. The recall.* RLS
//                           policies (user_id = auth.uid()) enforce per-user access. This is
//                           the multi-user / beta path: the iOS client signs in to Supabase
//                           Auth, sends its JWT to the Vercel API, and the API forwards it.
//
//   accessToken absent   -> service-role key. Bypasses RLS for trusted server-side work
//                           (single-user verification today, and goal-weight seeding). The
//                           service-role key is server-only and must never reach a client bundle.
//
// Flipping from the service-role path to the user-JWT path requires no code change here and
// no schema change — only that real JWTs start arriving. That is the "design for RLS, run on
// the service role until login lands" sequencing.

import { createClient } from "@supabase/supabase-js";

export function createSupabaseClient(options = {}) {
  const url = options.url ?? process.env.SUPABASE_URL;
  if (!url) {
    throw new Error("SUPABASE_URL is required to create a Supabase client.");
  }

  const baseConfig = {
    auth: { persistSession: false, autoRefreshToken: false }
  };

  if (options.accessToken) {
    const anonKey = options.anonKey ?? process.env.SUPABASE_ANON_KEY;
    if (!anonKey) {
      throw new Error("SUPABASE_ANON_KEY is required for user-authenticated (RLS-enforced) access.");
    }
    return createClient(url, anonKey, {
      ...baseConfig,
      global: { headers: { Authorization: `Bearer ${options.accessToken}` } }
    });
  }

  const serviceRoleKey = options.serviceRoleKey ?? process.env.SUPABASE_SERVICE_ROLE_KEY;
  if (!serviceRoleKey) {
    throw new Error("SUPABASE_SERVICE_ROLE_KEY is required for server-side (service-role) access.");
  }
  return createClient(url, serviceRoleKey, baseConfig);
}

// Pull a bearer token off an incoming request's Authorization header, if present.
// Returns undefined when there is no usable token, so callers fall back to the service role.
export function bearerTokenFrom(request) {
  const header =
    request?.headers?.authorization ??
    request?.headers?.get?.("authorization") ??
    "";
  const match = /^Bearer\s+(.+)$/i.exec(header.trim());
  return match ? match[1] : undefined;
}

// Resolve the user identity the request is allowed to act as — NEVER from the request body.
//
//   JWT present  -> validate it against Supabase Auth and return its uid. This is the
//                   per-user identity; the body's userId (if any) is ignored.
//   JWT absent   -> single-user mode: return process.env.SINGLE_USER_ID if configured,
//                   otherwise reject. The service-role key bypasses RLS, so without this
//                   gate a caller could read/write ANY user's rows by passing a userId in
//                   the body (IDOR). Binding identity to the token / a server env closes that.
//
// `client` must be the same client used for the work (built with this request's access token,
// if any) so getUser() validates the forwarded JWT.
export async function resolveAuthedUserId(request, client) {
  const token = bearerTokenFrom(request);
  if (token) {
    const { data, error } = await client.auth.getUser();
    if (error || !data?.user?.id) {
      const e = new Error("Invalid or expired access token.");
      e.status = 401;
      throw e;
    }
    return data.user.id;
  }
  if (process.env.SINGLE_USER_ID) {
    return process.env.SINGLE_USER_ID;
  }
  const e = new Error("Authentication required: send a Bearer token, or set SINGLE_USER_ID for single-user mode.");
  e.status = 401;
  throw e;
}
