import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    @State private var showLogoutConfirm = false
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            LingoHeader(
                title: "My Profile",
                onBack: { appState.navigateTo(.prompt) }
            )

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 28) {
                    // User info
                    if let user = appState.user {
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .stroke(Color.lingoBlue.opacity(0.3), lineWidth: 2)
                                    .frame(width: 60, height: 60)

                                Circle()
                                    .fill(Color.lingoBlue.opacity(0.06))
                                    .frame(width: 54, height: 54)

                                Text(String(user.displayName.prefix(1)).uppercased())
                                    .font(LingoFont.serif(24))
                                    .foregroundColor(.lingoBlueDeep)
                            }
                            .scaleEffect(appeared ? 1 : 0.5)
                            .animation(LingoAnimation.bouncy, value: appeared)

                            VStack(alignment: .leading, spacing: 3) {
                                Text(user.displayName)
                                    .font(LingoFont.serif(22))
                                    .foregroundColor(.lingoText)
                                Text(user.email)
                                    .font(LingoFont.caption(13))
                                    .foregroundColor(.lingoTextSecondary)
                            }
                        }
                    }

                    // Level
                    VStack(alignment: .leading, spacing: 10) {
                        Text("MY LEVEL")
                            .font(LingoFont.caption(10))
                            .foregroundColor(.lingoTextSecondary)
                            .tracking(1.5)

                        ProficiencyPicker(selected: Binding(
                            get: { appState.proficiencyLevel },
                            set: { level in Task { await appState.updateProficiency(level) } }
                        ))

                        Text("Setting your level helps Lingo give you better feedback and more relevant challenge words.")
                            .font(LingoFont.body(13))
                            .foregroundColor(.lingoTextSecondary)
                    }

                    // Statistics
                    VStack(alignment: .leading, spacing: 12) {
                        Text("STATISTICS")
                            .font(LingoFont.caption(10))
                            .foregroundColor(.lingoTextSecondary)
                            .tracking(1.5)

                        if let insights = appState.insights {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                StatCard(value: "\(insights.totalSessions)", label: "Sessions", color: .lingoBlue, index: 0, appeared: appeared)
                                StatCard(value: "\(insights.totalXp)", label: "Total XP", color: .accentXp, index: 1, appeared: appeared)
                                StatCard(value: "\(insights.avgScore)%", label: "Avg Score", color: .scorePronunciation, index: 2, appeared: appeared)
                                StatCard(value: "\(insights.streak.current_streak)", label: "Day Streak", color: .scoreFluency, index: 3, appeared: appeared)
                            }

                            // Skill breakdown
                            if !insights.skills.isEmpty {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("SKILL BREAKDOWN")
                                        .font(LingoFont.caption(10))
                                        .foregroundColor(.lingoTextSecondary)
                                        .tracking(1.5)
                                        .padding(.top, 8)

                                    ForEach(Array(insights.skills.enumerated()), id: \.element.skill) { index, skill in
                                        SkillBarRow(skill: skill, index: index, appeared: appeared)
                                    }
                                }
                            }

                            // Vocabulary
                            if insights.vocabulary.totalWords > 0 {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("VOCABULARY")
                                        .font(LingoFont.caption(10))
                                        .foregroundColor(.lingoTextSecondary)
                                        .tracking(1.5)
                                        .padding(.top, 8)

                                    HStack(spacing: 0) {
                                        VocabStat(value: "\(insights.vocabulary.totalWords)", label: "Words Seen", color: .scoreVocabulary)
                                        VocabStat(value: "\(insights.vocabulary.masteredWords)", label: "Mastered", color: .scorePronunciation)
                                        VocabStat(value: "\(insights.vocabulary.avgMastery)%", label: "Avg Mastery", color: .lingoBlue)
                                    }
                                    .lingoCard(padding: 16)
                                }
                            }

                            // Improvement
                            if insights.improvementRate != 0 {
                                let improving = insights.improvementRate > 0
                                HStack(spacing: 10) {
                                    Image(systemName: improving ? "arrow.up.right.circle.fill" : "arrow.down.right.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(improving ? .scorePronunciation : .lingoRed)

                                    Text(improving
                                        ? "Scores improved by \(insights.improvementRate) pts recently!"
                                        : "Scores dipped by \(abs(insights.improvementRate)) pts. Keep practicing!")
                                        .font(LingoFont.body(13))
                                        .foregroundColor(.lingoTextSecondary)
                                }
                                .lingoCard(padding: 16)
                            }
                        } else {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .tint(.lingoBlue)
                                Spacer()
                            }
                            .padding(.vertical, 24)
                        }
                    }

                    // Account
                    VStack(alignment: .leading, spacing: 10) {
                        Text("ACCOUNT")
                            .font(LingoFont.caption(10))
                            .foregroundColor(.lingoTextSecondary)
                            .tracking(1.5)

                        Button(action: { showLogoutConfirm = true }) {
                            Text("Log Out")
                                .font(LingoFont.body())
                                .foregroundColor(.lingoRed)
                        }
                    }
                }
                .padding(24)
            }
        }
        .background(Color.lingoBg.ignoresSafeArea())
        .task { await appState.loadInsights() }
        .onAppear {
            withAnimation { appeared = true }
        }
        .alert("Log Out?", isPresented: $showLogoutConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Log Out", role: .destructive) { appState.logout() }
        } message: {
            Text("Are you sure you want to log out?")
        }
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let value: String
    let label: String
    let color: Color
    var index: Int = 0
    var appeared: Bool = true

    var body: some View {
        VStack(spacing: 6) {
            Text(value)
                .font(LingoFont.serif(28))
                .foregroundColor(color)
            Text(label)
                .font(LingoFont.caption(12))
                .foregroundColor(.lingoTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(Color.white)
        .cornerRadius(18)
        .shadow(color: .black.opacity(0.04), radius: 8, y: 3)
        .scaleEffect(appeared ? 1 : 0.85)
        .opacity(appeared ? 1 : 0)
        .animation(LingoAnimation.stagger(index: index), value: appeared)
    }
}

// MARK: - Skill Bar Row

struct SkillBarRow: View {
    let skill: SkillData
    let index: Int
    let appeared: Bool
    @State private var animateBar = false

    var body: some View {
        HStack {
            Text(skill.skill.capitalized)
                .font(LingoFont.body(14))
                .fontWeight(.medium)
                .foregroundColor(.lingoText)
                .frame(width: 100, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color.borderGray.opacity(0.3))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color.skillColor(for: skill.skill))
                        .frame(width: animateBar ? geo.size.width * CGFloat(skill.rolling_avg) / 100 : 0, height: 8)
                }
            }
            .frame(height: 8)

            Text("\(Int(skill.rolling_avg))%")
                .font(LingoFont.caption(13))
                .fontWeight(.bold)
                .foregroundColor(Color.scoreColor(for: Int(skill.rolling_avg)))
                .frame(width: 40, alignment: .trailing)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.7).delay(Double(index) * 0.1)) {
                animateBar = true
            }
        }
    }
}

// MARK: - Vocab Stat

struct VocabStat: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(LingoFont.serif(20))
                .foregroundColor(color)
            Text(label)
                .font(LingoFont.caption(11))
                .foregroundColor(.lingoTextSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}
