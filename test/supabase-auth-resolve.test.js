import { test } from "node:test";
import assert from "node:assert/strict";

import { resolveAuthedUserId, bearerTokenFrom } from "../src/supabase-client.js";

// A fake supabase-js client whose auth.getUser() returns a fixed result.
function fakeClient(getUserResult) {
  return { auth: { getUser: async () => getUserResult } };
}
const reqWithToken = (token) => ({ headers: { authorization: `Bearer ${token}` } });
const reqNoAuth = () => ({ headers: {} });

test("JWT present → identity comes from the validated token, not the body", async () => {
  const client = fakeClient({ data: { user: { id: "auth-uid-123" } }, error: null });
  const userId = await resolveAuthedUserId(reqWithToken("jwt.abc"), client);
  assert.equal(userId, "auth-uid-123");
});

test("invalid/expired token → 401, does not fall through to any body value", async () => {
  const client = fakeClient({ data: { user: null }, error: { message: "bad jwt" } });
  await assert.rejects(
    () => resolveAuthedUserId(reqWithToken("nope"), client),
    (e) => e.status === 401
  );
});

test("no token + SINGLE_USER_ID set → returns the configured single user", async () => {
  const prev = process.env.SINGLE_USER_ID;
  process.env.SINGLE_USER_ID = "single-user-9";
  try {
    const userId = await resolveAuthedUserId(reqNoAuth(), fakeClient({ data: { user: null } }));
    assert.equal(userId, "single-user-9");
  } finally {
    if (prev === undefined) delete process.env.SINGLE_USER_ID;
    else process.env.SINGLE_USER_ID = prev;
  }
});

test("no token + no SINGLE_USER_ID → 401 (closes the IDOR: body userId is never trusted)", async () => {
  const prev = process.env.SINGLE_USER_ID;
  delete process.env.SINGLE_USER_ID;
  try {
    await assert.rejects(
      () => resolveAuthedUserId(reqNoAuth(), fakeClient({ data: { user: null } })),
      (e) => e.status === 401
    );
  } finally {
    if (prev !== undefined) process.env.SINGLE_USER_ID = prev;
  }
});

test("bearerTokenFrom reads node-style and fetch-style headers", () => {
  assert.equal(bearerTokenFrom({ headers: { authorization: "Bearer xyz" } }), "xyz");
  assert.equal(
    bearerTokenFrom({ headers: { get: (k) => (k === "authorization" ? "Bearer fetched" : null) } }),
    "fetched"
  );
  assert.equal(bearerTokenFrom({ headers: {} }), undefined);
});
