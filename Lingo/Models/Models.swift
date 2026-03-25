import Foundation

// MARK: - Proficiency Level

enum ProficiencyLevel: String, Codable, CaseIterable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case expert = "Expert"
}

// MARK: - Supported Languages

enum SupportedLanguage: String, CaseIterable, Identifiable {
    case english = "English"
    case spanish = "Spanish"
    case french = "French"
    case german = "German"
    case italian = "Italian"
    case japanese = "Japanese"
    case yoruba = "Yoruba"

    var id: String { rawValue }
}

// MARK: - Feedback Models

struct FeedbackItem: Codable {
    let score: Int
    let feedback: String
}

struct ChallengeWordFeedback: Codable, Identifiable {
    let word: String
    let used: Bool
    let feedback: String

    var id: String { word }
}

struct AIFeedback: Codable {
    let grammar: FeedbackItem
    let pronunciation: FeedbackItem
    let fluency: FeedbackItem
    let vocabulary: FeedbackItem
    let clarity: FeedbackItem
    let overallScore: Int
    let challengeWordsUsed: [ChallengeWordFeedback]
}

// MARK: - Session / Recording

struct SessionResult: Codable, Identifiable {
    let id: String
    let prompt: String
    let transcription: String
    let feedback: AIFeedback
    let targetLanguage: String
    let proficiencyLevel: String
    let xpEarned: Int
    let date: String

    var formattedDate: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        var parsed: Date?
        parsed = formatter.date(from: date)
        if parsed == nil {
            formatter.formatOptions = [.withInternetDateTime]
            parsed = formatter.date(from: date)
        }
        if let d = parsed {
            let display = DateFormatter()
            display.dateFormat = "d MMM, HH:mm"
            return display.string(from: d)
        }
        return date
    }
}

// MARK: - API Responses

struct AuthResponse: Codable {
    let token: String
    let user: UserInfo
}

struct UserInfo: Codable {
    let id: String
    let email: String
    let displayName: String
    let proficiencyLevel: String
    let targetLanguage: String
    var dailyGoal: Int?
}

struct PromptResponse: Codable {
    let prompt: String
    let weakSkills: [WeakSkill]?
    let focusArea: String?
}

struct WeakSkill: Codable {
    let skill: String
    let rolling_avg: Double
}

struct ChallengeWordsResponse: Codable {
    let words: [String]
}

struct EvaluationResponse: Codable {
    let sessionId: String
    let transcription: String
    let feedback: AIFeedback
    let xp: XPBreakdown
    let streak: StreakInfo
}

struct XPBreakdown: Codable {
    let base: Int
    let bonus: Int
    let total: Int
}

struct StreakInfo: Codable {
    let current_streak: Int
    let longest_streak: Int
}

struct SessionHistoryResponse: Codable {
    let sessions: [SessionResult]
}

struct SkillData: Codable {
    let skill: String
    let rolling_avg: Double
    let total_assessments: Int
}

struct VocabularyStats: Codable {
    let totalWords: Int
    let masteredWords: Int
    let avgMastery: Int
}

struct PracticePattern: Codable {
    let day: String
    let count: Int
}

struct LearningInsights: Codable {
    let totalSessions: Int
    let avgScore: Int
    let totalXp: Int
    let bestScore: Int
    let skills: [SkillData]
    let streak: StreakInfo
    let recentScores: [RecentScore]
    let improvementRate: Int
    let vocabulary: VocabularyStats
    let practicePatterns: [PracticePattern]
}

struct RecentScore: Codable {
    let overall_score: Int
    let created_at: String
}

// MARK: - App Screen State

enum AppScreen: Equatable {
    case onboarding
    case prompt
    case recording
    case loading
    case feedback
    case completion
    case dashboard
    case profile
}
