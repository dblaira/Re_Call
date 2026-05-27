export default function handler(_request, response) {
  response.status(200).json({
    ok: true,
    service: "re-call",
    endpoints: ["/api/recommendations"]
  });
}
