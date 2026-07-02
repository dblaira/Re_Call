import Foundation

enum SupabaseConfig {
    static let url = "https://vzaceoipwimphdvdxcpa.supabase.co"
    static let publishableKey: String = {
        guard let key = ProcessInfo.processInfo.environment["SUPABASE_PUBLISHABLE_KEY"], !key.isEmpty else {
            fatalError("SUPABASE_PUBLISHABLE_KEY must be set in the app runtime environment.")
        }
        return key
    }()
    static let schema = "recall"
}

/// Minimal Supabase client over URLSession — NO external packages, so the app ships zero dynamic
/// frameworks and launches reliably on a physical device. Anonymous sign-in gives a stable user
/// id; the refresh token is persisted so the SAME anonymous user (and their rows) survives relaunch.
actor SupabaseService {
    static let shared = SupabaseService()

    private var accessToken: String?
    private var tokenExpiry: Date?
    private let refreshKey = "recall.supabase.refreshToken"
    private let session = URLSession(configuration: .default)

    private init() {}

    /// Guarantee a *valid* session: reuse the in-memory token only while it has headroom left,
    /// else refresh the stored session, else create a fresh anonymous user. The expiry check is
    /// what prevents 401s from a stale access token after ~1h of uptime.
    func ensureSession() async -> Bool {
        if accessToken != nil, let exp = tokenExpiry, exp.timeIntervalSinceNow > 120 {
            return true
        }
        accessToken = nil
        tokenExpiry = nil
        if let rt = UserDefaults.standard.string(forKey: refreshKey), await auth("token?grant_type=refresh_token", ["refresh_token": rt]) {
            return true
        }
        return await auth("signup", [:])
    }

    private func auth(_ path: String, _ payload: [String: String]) async -> Bool {
        guard let u = URL(string: "\(SupabaseConfig.url)/auth/v1/\(path)") else { return false }
        var req = URLRequest(url: u)
        req.httpMethod = "POST"
        req.setValue(SupabaseConfig.publishableKey, forHTTPHeaderField: "apikey")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = (try? JSONSerialization.data(withJSONObject: payload)) ?? Data("{}".utf8)
        do {
            let (data, resp) = try await session.data(for: req)
            guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else { return false }
            let a = try JSONDecoder().decode(AuthResponse.self, from: data)
            guard let token = a.access_token else { return false }
            accessToken = token
            tokenExpiry = Date().addingTimeInterval(TimeInterval(a.expires_in ?? 3600))
            if let rt = a.refresh_token { UserDefaults.standard.set(rt, forKey: refreshKey) }
            return true
        } catch {
            return false
        }
    }

    /// Build an authed PostgREST request against the `recall` schema. Returns nil if not signed in.
    func request(_ method: String, _ path: String, query: String? = nil, body: Data? = nil, prefer: String? = nil) async -> URLRequest? {
        guard await ensureSession(), let token = accessToken else { return nil }
        var str = "\(SupabaseConfig.url)/rest/v1/\(path)"
        if let query { str += "?\(query)" }
        guard let u = URL(string: str) else { return nil }
        var req = URLRequest(url: u)
        req.httpMethod = method
        req.setValue(SupabaseConfig.publishableKey, forHTTPHeaderField: "apikey")
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(SupabaseConfig.schema, forHTTPHeaderField: "Accept-Profile")
        req.setValue(SupabaseConfig.schema, forHTTPHeaderField: "Content-Profile")
        if let prefer { req.setValue(prefer, forHTTPHeaderField: "Prefer") }
        req.httpBody = body
        return req
    }

    /// The signed-in user's id, decoded from the access token's `sub` claim. Used as the Storage
    /// folder so per-user RLS isolates each user's images.
    func userID() async -> String? {
        guard await ensureSession(), let token = accessToken else { return nil }
        let parts = token.split(separator: ".")
        guard parts.count >= 2 else { return nil }
        var b64 = String(parts[1]).replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        while b64.count % 4 != 0 { b64 += "=" }
        guard let data = Data(base64Encoded: b64),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let sub = json["sub"] as? String else { return nil }
        return sub
    }

    private static let imageBucket = "reminder-images"

    /// Upload JPEG bytes to Storage at `path` (e.g. "<uid>/<reminder-id>.jpg"), overwriting.
    func uploadImage(_ data: Data, path: String) async -> Bool {
        guard await ensureSession(), let token = accessToken,
              let u = URL(string: "\(SupabaseConfig.url)/storage/v1/object/\(Self.imageBucket)/\(path)") else { return false }
        var req = URLRequest(url: u)
        req.httpMethod = "POST"
        req.setValue(SupabaseConfig.publishableKey, forHTTPHeaderField: "apikey")
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
        req.setValue("true", forHTTPHeaderField: "x-upsert")
        guard let (_, resp) = try? await session.upload(for: req, from: data),
              let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else { return false }
        return true
    }

    /// Download JPEG bytes for a Storage `path` (private bucket, RLS-enforced).
    func downloadImage(path: String) async -> Data? {
        guard await ensureSession(), let token = accessToken,
              let u = URL(string: "\(SupabaseConfig.url)/storage/v1/object/authenticated/\(Self.imageBucket)/\(path)") else { return nil }
        var req = URLRequest(url: u)
        req.setValue(SupabaseConfig.publishableKey, forHTTPHeaderField: "apikey")
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        guard let (data, resp) = try? await session.data(for: req),
              let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else { return nil }
        return data
    }

    /// Send a request, validating the HTTP status. Returns the response body.
    @discardableResult
    func send(_ req: URLRequest) async throws -> Data {
        let (data, resp) = try await session.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            let code = (resp as? HTTPURLResponse)?.statusCode ?? -1
            if code == 401 { accessToken = nil; tokenExpiry = nil }   // self-heal: re-auth next time
            let msg = String(data: data, encoding: .utf8) ?? "request failed"
            throw NSError(domain: "Supabase", code: code, userInfo: [NSLocalizedDescriptionKey: msg])
        }
        return data
    }

    private struct AuthResponse: Decodable {
        let access_token: String?
        let refresh_token: String?
        let expires_in: Int?
    }
}
