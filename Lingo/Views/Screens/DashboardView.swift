import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedSession: SessionResult?
    @State private var appeared = false

    var body: some View {
        if let session = selectedSession {
            SessionDetailView(session: session, onBack: { selectedSession = nil })
        } else {
            mainDashboard
        }
    }

    private var mainDashboard: some View {
        VStack(spacing: 0) {
            LingoHeader(
                title: "My Progress",
                onBack: { appState.navigateTo(.prompt) }
            )

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Score Trend
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Score Trend")
                            .font(LingoFont.serif(20))
                            .foregroundColor(.lingoText)

                        if appState.sessions.count > 1 {
                            ScoreTrendChart(sessions: appState.sessions)
                                .frame(height: 200)
                        } else {
                            VStack(spacing: 12) {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .font(.system(size: 32))
                                    .foregroundColor(.lingoBlue.opacity(0.2))
                                Text("Complete more sessions to see your progress chart.")
                                    .font(LingoFont.serifItalic(15))
                                    .foregroundColor(.lingoTextSecondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity, minHeight: 160)
                        }
                    }
                    .lingoCard()

                    // Practice History
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Practice History")
                            .font(LingoFont.serif(20))
                            .foregroundColor(.lingoText)

                        if appState.sessions.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "mic.badge.plus")
                                    .font(.system(size: 32))
                                    .foregroundColor(.lingoBlue.opacity(0.2))
                                Text("No recordings yet.\nComplete a prompt to see it here!")
                                    .font(LingoFont.serifItalic(15))
                                    .foregroundColor(.lingoTextSecondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 28)
                        } else {
                            ForEach(Array(appState.sessions.enumerated()), id: \.element.id) { index, session in
                                Button(action: { selectedSession = session }) {
                                    HStack(spacing: 0) {
                                        // Color accent bar
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(Color.scoreColor(for: session.feedback.overallScore))
                                            .frame(width: 3)
                                            .padding(.vertical, 10)

                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(session.prompt)
                                                .font(LingoFont.body(15))
                                                .fontWeight(.medium)
                                                .foregroundColor(.lingoText)
                                                .lineLimit(1)

                                            Text(session.formattedDate)
                                                .font(LingoFont.caption(12))
                                                .foregroundColor(.lingoTextSecondary)
                                        }
                                        .padding(.leading, 14)

                                        Spacer()

                                        Text("\(session.feedback.overallScore)%")
                                            .font(LingoFont.serif(16))
                                            .foregroundColor(.lingoBlueDeep)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 5)
                                            .background(Color.lingoBlueDeep.opacity(0.06))
                                            .cornerRadius(12)
                                    }
                                    .padding(14)
                                    .background(Color.lingoCardBg)
                                    .cornerRadius(16)
                                    .shadow(color: .black.opacity(0.03), radius: 6, y: 2)
                                }
                                .buttonStyle(.plain)
                                .opacity(appeared ? 1 : 0)
                                .offset(y: appeared ? 0 : 12)
                                .animation(LingoAnimation.stagger(index: index, base: 0.05), value: appeared)
                            }
                        }
                    }
                }
                .padding(20)
            }
            .refreshable {
                await appState.loadHistory()
            }
        }
        .background(Color.lingoBg.ignoresSafeArea())
        .task { await appState.loadHistory() }
        .onAppear {
            withAnimation { appeared = true }
        }
    }
}

// MARK: - Session Detail

struct SessionDetailView: View {
    let session: SessionResult
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            LingoHeader(title: "Session Details", onBack: onBack)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    RadarChartView(feedback: session.feedback)
                        .frame(height: 240)
                        .lingoCard()

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your response")
                            .font(LingoFont.serif(18))
                            .foregroundColor(.lingoText)
                        Text("\"\(session.transcription)\"")
                            .font(LingoFont.body())
                            .italic()
                            .foregroundColor(.lingoTextSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lingoCard()

                    ChallengeWordsCard(words: session.feedback.challengeWordsUsed)

                    ScoreCardView(title: "Grammar", score: session.feedback.grammar.score, feedback: session.feedback.grammar.feedback, color: .scoreGrammar, delay: 0.1)
                    ScoreCardView(title: "Pronunciation", score: session.feedback.pronunciation.score, feedback: session.feedback.pronunciation.feedback, color: .scorePronunciation, delay: 0.15)
                    ScoreCardView(title: "Fluency", score: session.feedback.fluency.score, feedback: session.feedback.fluency.feedback, color: .scoreFluency, delay: 0.2)
                    ScoreCardView(title: "Vocabulary", score: session.feedback.vocabulary.score, feedback: session.feedback.vocabulary.feedback, color: .scoreVocabulary, delay: 0.25)
                    ScoreCardView(title: "Clarity", score: session.feedback.clarity.score, feedback: session.feedback.clarity.feedback, color: .scoreClarity, delay: 0.3)
                }
                .padding(20)
            }

            VStack {
                Button(action: onBack) {
                    Text("Back to Dashboard")
                }
                .buttonStyle(LingoPrimaryButtonStyle())
            }
            .padding(20)
            .background(Color.lingoBg)
            .overlay(
                Rectangle().fill(Color.borderGray.opacity(0.3)).frame(height: 0.5),
                alignment: .top
            )
        }
        .background(Color.lingoBg.ignoresSafeArea())
    }
}
