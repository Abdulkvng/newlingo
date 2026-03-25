import SwiftUI
import Combine

@MainActor
class AppState: ObservableObject {
    // MARK: - Navigation
    @Published var currentScreen: AppScreen = .onboarding

    // MARK: - Auth
    @Published var isLoggedIn = false
    @Published var user: UserInfo?

    // MARK: - Session State
    @Published var currentPrompt: String = ""
    @Published var focusArea: String?
    @Published var challengeWords: [String] = []
    @Published var isLoadingWords = true
    @Published var isLoadingPrompt = true

    // MARK: - Settings
    @Published var proficiencyLevel: ProficiencyLevel = .beginner
    @Published var targetLanguage: SupportedLanguage = .english

    // MARK: - Feedback
    @Published var currentFeedback: AIFeedback?
    @Published var currentTranscription: String = ""
    @Published var currentXP: XPBreakdown?
    @Published var currentStreak: StreakInfo?

    // MARK: - History
    @Published var sessions: [SessionResult] = []

    // MARK: - Analytics
    @Published var insights: LearningInsights?

    // MARK: - Errors
    @Published var error: String?

    private let api = APIService.shared

    // MARK: - Init

    init() {
        // Check if user is already logged in
        if api.isAuthenticated {
            // Stay on onboarding until restore confirms valid session
            currentScreen = .onboarding
            Task { await restoreSession() }
        } else {
            currentScreen = .onboarding
        }
    }

    // MARK: - Auth Actions

    func register(email: String, password: String, name: String) async {
        error = nil
        do {
            let response = try await api.register(
                email: email,
                password: password,
                displayName: name,
                proficiency: proficiencyLevel,
                language: targetLanguage
            )
            user = response.user
            isLoggedIn = true
            currentScreen = .prompt
            await loadNewSession()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func login(email: String, password: String) async {
        self.error = nil
        do {
            let response = try await api.login(email: email, password: password)
            user = response.user
            if let level = ProficiencyLevel(rawValue: response.user.proficiencyLevel) {
                proficiencyLevel = level
            }
            if let lang = SupportedLanguage(rawValue: response.user.targetLanguage) {
                targetLanguage = lang
            }
            isLoggedIn = true
            currentScreen = .prompt
            await loadNewSession()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func logout() {
        api.logout()
        isLoggedIn = false
        user = nil
        error = nil
        currentScreen = .onboarding
        sessions = []
        insights = nil
        currentFeedback = nil
        currentTranscription = ""
        currentXP = nil
        currentStreak = nil
    }

    private func restoreSession() async {
        do {
            let profile = try await api.getProfile()
            user = profile
            if let level = ProficiencyLevel(rawValue: profile.proficiencyLevel) {
                proficiencyLevel = level
            }
            if let lang = SupportedLanguage(rawValue: profile.targetLanguage) {
                targetLanguage = lang
            }
            isLoggedIn = true
            error = nil
            currentScreen = .prompt
            await loadNewSession()
        } catch {
            // Token expired or invalid — force back to onboarding
            api.logout()
            isLoggedIn = false
            user = nil
            self.error = nil
            currentScreen = .onboarding
        }
    }

    // MARK: - Session Flow

    func loadNewSession() async {
        isLoadingPrompt = true
        isLoadingWords = true
        error = nil

        do {
            let promptResponse = try await api.getAdaptivePrompt()
            currentPrompt = promptResponse.prompt
            focusArea = promptResponse.focusArea
            isLoadingPrompt = false

            let wordsResponse = try await api.getChallengeWords(
                prompt: currentPrompt,
                language: targetLanguage.rawValue,
                proficiency: proficiencyLevel.rawValue
            )
            challengeWords = wordsResponse.words
            isLoadingWords = false
        } catch {
            self.error = "Could not load session. Please try again."
            isLoadingPrompt = false
            isLoadingWords = false
        }
    }

    func submitRecording(audioData: Data) async {
        currentScreen = .loading
        error = nil

        do {
            let base64 = audioData.base64EncodedString()

            let result = try await api.evaluateSpeech(
                audioBase64: base64,
                language: targetLanguage.rawValue,
                proficiency: proficiencyLevel.rawValue,
                prompt: currentPrompt,
                challengeWords: challengeWords
            )

            currentFeedback = result.feedback
            currentTranscription = result.transcription
            currentXP = result.xp
            currentStreak = result.streak

            currentScreen = .feedback
        } catch {
            self.error = "Failed to evaluate audio: \(error.localizedDescription)"
            currentScreen = .prompt
        }
    }

    // MARK: - Navigation

    func navigateTo(_ screen: AppScreen) {
        error = nil
        if screen == .prompt {
            currentFeedback = nil
            currentTranscription = ""
            currentXP = nil
        }
        currentScreen = screen
    }

    func startNewSession() async {
        currentFeedback = nil
        currentTranscription = ""
        currentXP = nil
        currentScreen = .prompt
        await loadNewSession()
    }

    // MARK: - Data Loading

    func loadHistory() async {
        do {
            let response = try await api.getSessionHistory()
            sessions = response.sessions
        } catch {
            self.error = "Failed to load history."
        }
    }

    func loadInsights() async {
        do {
            insights = try await api.getLearningInsights()
        } catch {
            self.error = "Failed to load analytics."
        }
    }

    func updateProficiency(_ level: ProficiencyLevel) async {
        proficiencyLevel = level
        do {
            try await api.updateProfile(proficiency: level)
            await loadNewSession()
        } catch {
            self.error = "Failed to update proficiency."
        }
    }

    func updateLanguage(_ language: SupportedLanguage) async {
        targetLanguage = language
        do {
            try await api.updateProfile(language: language)
            await loadNewSession()
        } catch {
            self.error = "Failed to update language."
        }
    }
}
