import SwiftUI

struct PromptView: View {
    @EnvironmentObject var appState: AppState
    @State private var wordsAppeared = false
    @State private var showRecording = false

    var body: some View {
        ZStack {
            // Main content
            VStack(spacing: 0) {
                LingoHeader(
                    title: "Lingo",
                    showProfileIcon: true,
                    onProfileTap: { appState.navigateTo(.profile) }
                )

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        // Language & Level
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("PRACTICING")
                                    .font(LingoFont.caption(10))
                                    .foregroundColor(.lingoTextSecondary)
                                    .tracking(1.5)

                                Menu {
                                    ForEach(SupportedLanguage.allCases) { lang in
                                        Button(lang.rawValue) {
                                            Task { await appState.updateLanguage(lang) }
                                        }
                                    }
                                } label: {
                                    HStack(spacing: 4) {
                                        Text(appState.targetLanguage.rawValue)
                                            .font(LingoFont.headline())
                                            .foregroundColor(.lingoBlueDeep)
                                        Image(systemName: "chevron.down")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.lingoBlueDeep)
                                    }
                                }
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 4) {
                                Text("LEVEL")
                                    .font(LingoFont.caption(10))
                                    .foregroundColor(.lingoTextSecondary)
                                    .tracking(1.5)
                                Text(appState.proficiencyLevel.rawValue)
                                    .font(LingoFont.headline())
                                    .foregroundColor(.lingoBlueDeep)
                            }
                        }
                        .padding(.horizontal, 28)
                        .padding(.top, 24)

                        // Focus area badge
                        if let focus = appState.focusArea {
                            HStack(spacing: 6) {
                                Image(systemName: "scope")
                                    .font(.system(size: 11, weight: .bold))
                                Text("Focusing on \(focus.capitalized)")
                                    .font(LingoFont.caption(12))
                            }
                            .foregroundColor(.scoreFluency)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(Color.scoreFluency.opacity(0.08))
                            .cornerRadius(20)
                            .padding(.horizontal, 28)
                            .padding(.top, 14)
                        }

                        // Today's Topic Card
                        VStack(alignment: .leading, spacing: 10) {
                            Text("TODAY'S TOPIC")
                                .font(LingoFont.caption(10))
                                .foregroundColor(.lingoTextSecondary)
                                .tracking(1.5)

                            if appState.isLoadingPrompt {
                                VStack(spacing: 10) {
                                    ShimmerPlaceholder(height: 24)
                                    ShimmerPlaceholder(height: 24)
                                        .frame(width: 200)
                                }
                            } else {
                                HStack(spacing: 0) {
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(Color.lingoBlueDeep)
                                        .frame(width: 3)

                                    Text(appState.currentPrompt)
                                        .font(LingoFont.prompt(22))
                                        .foregroundColor(.lingoText)
                                        .padding(.leading, 16)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lingoCard()
                        .padding(.horizontal, 20)
                        .padding(.top, 20)

                        // Challenge Words
                        VStack(alignment: .leading, spacing: 10) {
                            Text("CHALLENGE WORDS")
                                .font(LingoFont.caption(10))
                                .foregroundColor(.accentChallenge)
                                .tracking(1.5)

                            if appState.isLoadingWords {
                                HStack(spacing: 10) {
                                    ForEach(0..<3, id: \.self) { _ in
                                        ShimmerPlaceholder(height: 32, cornerRadius: 16)
                                            .frame(width: 80)
                                    }
                                }
                            } else if appState.challengeWords.isEmpty {
                                Text("Could not load words. You can still practice.")
                                    .font(LingoFont.body(14))
                                    .foregroundColor(.lingoTextSecondary)
                            } else {
                                FlowLayout(spacing: 10) {
                                    ForEach(Array(appState.challengeWords.enumerated()), id: \.element) { index, word in
                                        Text(word)
                                            .font(LingoFont.body(14))
                                            .fontWeight(.semibold)
                                            .foregroundColor(.accentChallenge)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(Color.accentChallenge.opacity(0.08))
                                            .cornerRadius(20)
                                            .scaleEffect(wordsAppeared ? 1 : 0.5)
                                            .opacity(wordsAppeared ? 1 : 0)
                                            .animation(LingoAnimation.stagger(index: index), value: wordsAppeared)
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lingoCard()
                        .padding(.horizontal, 20)
                        .padding(.top, 12)

                        // Tips Section
                        TipsSection(insights: appState.insights, focusArea: appState.focusArea)
                            .padding(.horizontal, 20)
                            .padding(.top, 12)

                        // Streak
                        if let streak = appState.currentStreak, streak.current_streak > 0 {
                            HStack(spacing: 10) {
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.lingoBlue)

                                VStack(alignment: .leading, spacing: 1) {
                                    Text("\(streak.current_streak) day streak")
                                        .font(LingoFont.headline(16))
                                        .foregroundColor(.lingoText)
                                    Text("Keep it going!")
                                        .font(LingoFont.caption(12))
                                        .foregroundColor(.lingoTextSecondary)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .lingoCard()
                            .padding(.horizontal, 20)
                            .padding(.top, 12)
                        }

                        // Error
                        if let error = appState.error {
                            HStack(spacing: 10) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.lingoRed)
                                Text(error)
                                    .font(LingoFont.body(14))
                                    .foregroundColor(.lingoRed)
                            }
                            .padding(16)
                            .background(Color.lingoRed.opacity(0.06))
                            .cornerRadius(16)
                            .padding(.horizontal, 20)
                            .padding(.top, 12)
                        }

                        Spacer().frame(height: 20)
                    }
                }

                // Bottom Buttons
                VStack(spacing: 12) {
                    Button(action: {
                        LingoHaptics.impact(.medium)
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            showRecording = true
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "mic.fill")
                            Text("Start Recording")
                        }
                    }
                    .buttonStyle(LingoPrimaryButtonStyle(disabled: appState.isLoadingWords))
                    .disabled(appState.isLoadingWords)

                    Button(action: {
                        appState.navigateTo(.dashboard)
                        Task { await appState.loadHistory() }
                    }) {
                        Text("View Progress")
                    }
                    .buttonStyle(LingoSecondaryButtonStyle())
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
                .background(Color.lingoBg)
                .overlay(
                    Rectangle().fill(Color.borderGray.opacity(0.3)).frame(height: 0.5),
                    alignment: .top
                )
            }
            .opacity(showRecording ? 0.3 : 1)
            .allowsHitTesting(!showRecording)

            // Recording overlay
            if showRecording {
                RecordingOverlay(
                    appState: appState,
                    onDismiss: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            showRecording = false
                        }
                    }
                )
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .background(Color.lingoBg.ignoresSafeArea())
        .onChange(of: appState.isLoadingWords) { _, newValue in
            if !newValue { wordsAppeared = true }
        }
        .onChange(of: appState.currentScreen) { _, newValue in
            // If we navigated away (e.g. to loading), dismiss the overlay
            if newValue != .prompt && newValue != .recording {
                showRecording = false
            }
        }
        .task {
            // Load insights for tips (lightweight)
            if appState.insights == nil {
                await appState.loadInsights()
            }
        }
    }
}

// MARK: - Tips Section

struct TipsSection: View {
    let insights: LearningInsights?
    let focusArea: String?

    private var tips: [(String, String, String)] {
        var result: [(String, String, String)] = [] // (icon, title, body)

        if let insights = insights {
            // Tip based on weak skill
            if let weakest = insights.skills.min(by: { $0.rolling_avg < $1.rolling_avg }) {
                let skill = weakest.skill.capitalized
                let avg = Int(weakest.rolling_avg)
                if avg < 70 {
                    result.append((
                        "lightbulb.fill",
                        "Work on \(skill)",
                        "Your \(skill.lowercased()) averages \(avg)%. Try focusing on this in your next session."
                    ))
                }
            }

            // Tip based on vocabulary
            if insights.vocabulary.totalWords > 0 && insights.vocabulary.avgMastery < 60 {
                result.append((
                    "text.book.closed.fill",
                    "Review vocabulary",
                    "You've seen \(insights.vocabulary.totalWords) words but mastered \(insights.vocabulary.masteredWords). Keep practicing!"
                ))
            }

            // Tip based on improvement
            if insights.improvementRate < 0 {
                result.append((
                    "arrow.triangle.2.circlepath",
                    "Stay consistent",
                    "Your scores dipped recently. Short daily sessions work better than long weekly ones."
                ))
            } else if insights.improvementRate > 5 {
                result.append((
                    "star.fill",
                    "You're improving!",
                    "Your scores are up by \(insights.improvementRate) points. Keep the momentum going."
                ))
            }

            // Tip about streak
            if insights.streak.current_streak == 0 {
                result.append((
                    "flame",
                    "Start a streak",
                    "Practice daily to build a streak. Even one session a day makes a big difference."
                ))
            }
        }

        // Default tips when no data
        if result.isEmpty {
            result.append((
                "mic.fill",
                "Speak naturally",
                "Don't overthink it — respond as you would in a real conversation for the best feedback."
            ))
            result.append((
                "textformat.abc",
                "Use challenge words",
                "Try working all the challenge words into your response to earn bonus XP."
            ))
        }

        return Array(result.prefix(2))
    }

    var body: some View {
        if !tips.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("TIPS FOR YOU")
                    .font(LingoFont.caption(10))
                    .foregroundColor(.lingoTextSecondary)
                    .tracking(1.5)

                ForEach(Array(tips.enumerated()), id: \.offset) { _, tip in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: tip.0)
                            .font(.system(size: 14))
                            .foregroundColor(.lingoBlueDeep)
                            .frame(width: 28, height: 28)
                            .background(Color.lingoBlueDeep.opacity(0.06))
                            .cornerRadius(8)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(tip.1)
                                .font(LingoFont.headline(15))
                                .foregroundColor(.lingoText)
                            Text(tip.2)
                                .font(LingoFont.body(13))
                                .foregroundColor(.lingoTextSecondary)
                        }
                    }
                }
            }
            .lingoCard()
        }
    }
}

// MARK: - Recording Overlay (Dynamic Island style)

struct RecordingOverlay: View {
    @ObservedObject var appState: AppState
    @StateObject private var recorder = AudioRecorder()
    @State private var elapsed: TimeInterval = 0
    @State private var timer: Timer?
    @State private var breathe = false
    let onDismiss: () -> Void

    var body: some View {
        VStack {
            Spacer()

            // Dynamic Island-style recording pill
            VStack(spacing: 0) {
                // Expanded island
                VStack(spacing: 16) {
                    // Waveform + timer
                    HStack(spacing: 16) {
                        // Live waveform indicator
                        HStack(spacing: 3) {
                            ForEach(0..<5, id: \.self) { i in
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.white.opacity(0.8))
                                    .frame(width: 3, height: waveHeight(for: i))
                                    .animation(.easeInOut(duration: 0.3).delay(Double(i) * 0.05), value: recorder.volume)
                            }
                        }
                        .frame(height: 24)

                        // Timer
                        Text(formatTime(elapsed))
                            .font(LingoFont.serif(22))
                            .foregroundColor(.white)
                            .monospacedDigit()

                        Spacer()

                        // Recording indicator dot
                        Circle()
                            .fill(Color.lingoRed)
                            .frame(width: 10, height: 10)
                            .opacity(breathe ? 1 : 0.3)
                    }

                    // Prompt reminder
                    Text(appState.currentPrompt)
                        .font(LingoFont.body(14))
                        .foregroundColor(.white.opacity(0.6))
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    // Stop button
                    Button(action: stopRecording) {
                        HStack(spacing: 8) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.lingoRed)
                                .frame(width: 16, height: 16)
                            Text("Stop Recording")
                                .font(LingoFont.headline(15))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.white.opacity(0.12))
                        .cornerRadius(14)
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 28)
                        .fill(Color(hex: "1A1A1A"))
                        .shadow(color: .black.opacity(0.3), radius: 20, y: 8)
                )
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)

            // Cancel button
            Button(action: cancelRecording) {
                Text("Cancel")
                    .font(LingoFont.body(15))
                    .foregroundColor(.lingoTextSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.white)
                    .cornerRadius(14)
                    .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
        .onAppear {
            LingoHaptics.impact(.heavy)
            recorder.startRecording()
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                elapsed += 0.1
            }
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                breathe = true
            }
        }
        .onDisappear {
            timer?.invalidate()
            if recorder.isRecording { recorder.cancelRecording() }
        }
    }

    private func waveHeight(for index: Int) -> CGFloat {
        let base: CGFloat = 6
        let volumeBoost = recorder.volume * 18
        let offsets: [CGFloat] = [0.6, 1.0, 0.8, 0.9, 0.5]
        return base + volumeBoost * offsets[index]
    }

    private func stopRecording() {
        LingoHaptics.notification(.success)
        timer?.invalidate()
        guard recorder.isRecording else { return }
        if elapsed < 3 {
            appState.error = "Please record for at least 3 seconds."
            onDismiss()
            return
        }
        if let audioData = recorder.stopRecording() {
            onDismiss()
            Task { await appState.submitRecording(audioData: audioData) }
        }
    }

    private func cancelRecording() {
        LingoHaptics.impact(.light)
        timer?.invalidate()
        recorder.cancelRecording()
        onDismiss()
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}
