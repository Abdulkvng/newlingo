import Foundation

class APIService {
    static let shared = APIService()

    // Change this to your backend URL
    private let baseURL = "http://localhost:3001/api"
    private var authToken: String? {
        get { UserDefaults.standard.string(forKey: "lingo-auth-token") }
        set { UserDefaults.standard.set(newValue, forKey: "lingo-auth-token") }
    }

    var isAuthenticated: Bool { authToken != nil }

    private init() {}

    // MARK: - Core Request

    private func request<T: Decodable>(
        _ method: String,
        path: String,
        body: [String: Any]? = nil,
        authenticated: Bool = true
    ) async throws -> T {
        guard let url = URL(string: "\(baseURL)\(path)") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if authenticated, let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body = body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        if httpResponse.statusCode == 401 {
            authToken = nil
            throw APIError.unauthorized
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorBody = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw APIError.serverError(errorBody.error)
            }
            throw APIError.serverError("Request failed with status \(httpResponse.statusCode)")
        }

        return try JSONDecoder().decode(T.self, from: data)
    }

    // MARK: - Auth

    func register(email: String, password: String, displayName: String, proficiency: ProficiencyLevel, language: SupportedLanguage) async throws -> AuthResponse {
        let body: [String: Any] = [
            "email": email,
            "password": password,
            "displayName": displayName,
            "proficiencyLevel": proficiency.rawValue,
            "targetLanguage": language.rawValue
        ]
        let response: AuthResponse = try await request("POST", path: "/auth/register", body: body, authenticated: false)
        authToken = response.token
        return response
    }

    func login(email: String, password: String) async throws -> AuthResponse {
        let body: [String: Any] = ["email": email, "password": password]
        let response: AuthResponse = try await request("POST", path: "/auth/login", body: body, authenticated: false)
        authToken = response.token
        return response
    }

    func logout() {
        authToken = nil
        UserDefaults.standard.removeObject(forKey: "lingo-user")
    }

    func getProfile() async throws -> UserInfo {
        try await request("GET", path: "/auth/me")
    }

    func updateProfile(proficiency: ProficiencyLevel? = nil, language: SupportedLanguage? = nil, displayName: String? = nil) async throws {
        var body: [String: Any] = [:]
        if let p = proficiency { body["proficiencyLevel"] = p.rawValue }
        if let l = language { body["targetLanguage"] = l.rawValue }
        if let n = displayName { body["displayName"] = n }

        let _: [String: Bool] = try await request("PUT", path: "/auth/me", body: body)
    }

    // MARK: - Sessions

    func getAdaptivePrompt() async throws -> PromptResponse {
        try await request("GET", path: "/sessions/prompt")
    }

    func getChallengeWords(prompt: String, language: String, proficiency: String) async throws -> ChallengeWordsResponse {
        let body: [String: Any] = [
            "prompt": prompt,
            "targetLanguage": language,
            "proficiencyLevel": proficiency
        ]
        return try await request("POST", path: "/sessions/challenge-words", body: body)
    }

    func evaluateSpeech(audioBase64: String, language: String, proficiency: String, prompt: String, challengeWords: [String]) async throws -> EvaluationResponse {
        let body: [String: Any] = [
            "audioBase64": audioBase64,
            "targetLanguage": language,
            "proficiencyLevel": proficiency,
            "prompt": prompt,
            "challengeWords": challengeWords
        ]
        return try await request("POST", path: "/sessions/evaluate", body: body)
    }

    func getSessionHistory(limit: Int = 50, offset: Int = 0) async throws -> SessionHistoryResponse {
        try await request("GET", path: "/sessions/history?limit=\(limit)&offset=\(offset)")
    }

    // MARK: - Analytics

    func getLearningInsights() async throws -> LearningInsights {
        try await request("GET", path: "/analytics/insights")
    }
}

// MARK: - Error Types

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case unauthorized
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .invalidResponse: return "Invalid response from server"
        case .unauthorized: return "Please log in again"
        case .serverError(let msg): return msg
        }
    }
}

struct ErrorResponse: Codable {
    let error: String
}
