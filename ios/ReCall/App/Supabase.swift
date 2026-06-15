import Foundation

enum SupabaseConfig {
    static let url = "https://vzaceoipwimphdvdxcpa.supabase.co"
    // Public anon key — safe to ship in a client bundle; per-row access is enforced by RLS.
    static let anonKey =
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZ6YWNlb2lwd2ltcGhkdmR4Y3BhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk5MTUzNTksImV4cCI6MjA5NTQ5MTM1OX0.PpbSvOTzBbJGz4Qp4Qarj1RPs9vofFxJYI9NfFqFLh8"
    static let schema = "recall"
}

/// Minimal Supabase client over URLSession — NO external packages, so the app ships zero dynamic
/// frameworks and launches reliably on a physical device. Anonymous sign-in gives a stable user
/// id; the refresh token is persisted so the SAME anonymous user (and their rows) survives relaunch.
actor SupabaseService {
    static let shared = SupabaseService()

    private var accessToken: String?
    private let refreshKey = "recall.supabase.refreshToken"
    private let session = URLSession(configuration: .default)

    private init() {}

    /// Guarantee a valid session: reuse the in-memory token, else refresh the stored session,
    /// else create a fresh anonymous user.
    func ensureSession() async -> Bool {
        if accessToken != nil { return true }
        if let rt = UserDefaults.standard.string(forKey: refreshKey), await auth("token?grant_type=refresh_token", ["refresh_token": rt]) {
            return true
        }
        return await auth("signup", [:])
    }

    private func auth(_ path: String, _ payload: [String: String]) async -> Bool {
        guard let u = URL(string: "\(SupabaseConfig.url)/auth/v1/\(path)") else { return false }
        var req = URLRequest(url: u)
        req.httpMethod = "POST"
        req.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = (try? JSONSerialization.data(withJSONObject: payload)) ?? Data("{}".utf8)
        do {
            let (data, resp) = try await session.data(for: req)
            guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else { return false }
            let a = try JSONDecoder().decode(AuthResponse.self, from: data)
            guard let token = a.access_token else { return false }
            accessToken = token
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
        req.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(SupabaseConfig.schema, forHTTPHeaderField: "Accept-Profile")
        req.setValue(SupabaseConfig.schema, forHTTPHeaderField: "Content-Profile")
        if let prefer { req.setValue(prefer, forHTTPHeaderField: "Prefer") }
        req.httpBody = body
        return req
    }

    /// Send a request, validating the HTTP status. Returns the response body.
    @discardableResult
    func send(_ req: URLRequest) async throws -> Data {
        let (data, resp) = try await session.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            let code = (resp as? HTTPURLResponse)?.statusCode ?? -1
            let msg = String(data: data, encoding: .utf8) ?? "request failed"
            throw NSError(domain: "Supabase", code: code, userInfo: [NSLocalizedDescriptionKey: msg])
        }
        return data
    }

    private struct AuthResponse: Decodable {
        let access_token: String?
        let refresh_token: String?
    }
}
