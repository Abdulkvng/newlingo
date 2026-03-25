import SwiftUI

struct FeedbackView: View {
    @EnvironmentObject var appState: AppState
    @State private var appeared = false
    @State private var scoreProgress: CGFloat = 0

    var body: some View {
        VStack(spacing: 0) {
            LingoHeader(
                title: "Your Feedback",
                onBack: { appState.navigateTo(.prompt) }
            )

            if let feedback = appState.currentFeedback {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        // Overall score hero gauge
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .stroke(Color.borderGray.opacity(0.4), lineWidth: 8)
                                    .frame(width: 100, height: 100)

                                Circle()
                                    .trim(from: 0, to: scoreProgress * CGFloat(feedback.overallScore) / 100)
                                    .stroke(
                                        Color.scoreColor(for: feedback.overallScore),
                                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                                    )
                                    .frame(width: 100, height: 100)
                                    .rotationEffect(.degrees(-90))

                                AnimatedCounter(
                                    target: appeared ? feedback.overallScore : 0,
                                    duration: 1.0,
                                    font: LingoFont.serif(34),
                                    color: Color.scoreColor(for: feedback.overallScore)
                                )
                                .id("overall-\(appeared)")
                            }
                            Text("Overall Score")
                                .font(LingoFont.caption(13))
                                .foregroundColor(.lingoTextSecondary)
                        }
                        .padding(.vertical, 8)
                        .opacity(appeared ? 1 : 0)
                        .scaleEffect(appeared ? 1 : 0.8)
                        .animation(LingoAnimation.bouncy, value: appeared)

                        // Radar Chart
                        VStack(spacing: 8) {
                            Text("Performance Snapshot")
                                .font(LingoFont.serif(20))
                                .foregroundColor(.lingoText)
                            RadarChartView(feedback: feedback)
                                .frame(height: 240)
                        }
                        .lingoCard()
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 16)
                        .animation(LingoAnimation.spring.delay(0.1), value: appeared)

                        // Transcription
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Image(systemName: "quote.opening")
                                    .font(.system(size: 18))
                                    .foregroundColor(.lingoBlue.opacity(0.15))
                                Spacer()
                            }
                            Text("Your response")
                                .font(LingoFont.serif(18))
                                .foregroundColor(.lingoText)
                            Text(appState.currentTranscription)
                                .font(LingoFont.body())
                                .italic()
                                .foregroundColor(.lingoTextSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lingoCard()
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 16)
                        .animation(LingoAnimation.spring.delay(0.2), value: appeared)

                        // Challenge Words
                        ChallengeWordsCard(words: feedback.challengeWordsUsed)

                        // Score Cards (staggered)
                        ScoreCardView(title: "Grammar", score: feedback.grammar.score, feedback: feedback.grammar.feedback, color: .scoreGrammar, delay: 0.3)
                        ScoreCardView(title: "Pronunciation", score: feedback.pronunciation.score, feedback: feedback.pronunciation.feedback, color: .scorePronunciation, delay: 0.4)
                        ScoreCardView(title: "Fluency", score: feedback.fluency.score, feedback: feedback.fluency.feedback, color: .scoreFluency, delay: 0.5)
                        ScoreCardView(title: "Vocabulary", score: feedback.vocabulary.score, feedback: feedback.vocabulary.feedback, color: .scoreVocabulary, delay: 0.6)
                        ScoreCardView(title: "Clarity", score: feedback.clarity.score, feedback: feedback.clarity.feedback, color: .scoreClarity, delay: 0.7)
                    }
                    .padding(20)
                }

                // Continue button
                VStack {
                    Button(action: {
                        LingoHaptics.notification(.success)
                        appState.navigateTo(.completion)
                    }) {
                        Text("Continue")
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
        }
        .background(Color.lingoBg.ignoresSafeArea())
        .onAppear {
            withAnimation { appeared = true }
            withAnimation(.easeOut(duration: 1.0).delay(0.3)) {
                scoreProgress = 1
            }
        }
    }
}
