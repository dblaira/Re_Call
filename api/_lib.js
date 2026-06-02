// Shared helpers for the api/* handlers. The leading underscore keeps Vercel from
// treating this as a routable endpoint.

// Bearer-token APIs (no cookies) can safely use a wildcard origin. If a browser client
// on a fixed origin is added later, swap "*" for that origin and add Allow-Credentials.
export function applyCors(response) {
  response.setHeader("Access-Control-Allow-Origin", "*");
  response.setHeader("Access-Control-Allow-Methods", "POST, OPTIONS");
  response.setHeader("Access-Control-Allow-Headers", "Content-Type, Authorization");
}

// Map a thrown error to a response without leaking server internals.
//   - error.status set  -> use it (e.g. 401 auth)         [message is safe to show]
//   - known validation  -> 400                            [message is safe to show]
//   - anything else      -> 500 generic; real error logged server-side only
export function sendError(response, error, fallback = "Internal error.") {
  const message = error instanceof Error ? error.message : String(error);

  if (error && typeof error.status === "number") {
    response.status(error.status).json({ error: message });
    return;
  }
  if (/^Unknown signal type/.test(message)) {
    response.status(400).json({ error: message });
    return;
  }
  console.error("[api] unhandled error:", error);
  response.status(500).json({ error: fallback });
}
