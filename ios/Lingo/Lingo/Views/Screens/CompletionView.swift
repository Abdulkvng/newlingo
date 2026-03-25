import SwiftUI

struct CompletionView: View {
    @EnvironmentObject var appState: AppState
    @State private var showCircle = false
    @State private var showCheckmark = false
    @State private var showContent = false
    @State private var showConfetti = false

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                LingoHeader(title: "Lingo")

                VStack(spacing: 0) {
                    Spacer()

                    // Checkmark animation
                    ZStack {
                        // Outer glow
                        Circle()
                            .fill(Color.scorePronunciation.opacity(0.06))
                            .frame(width: 130, height: 130)
                            .scaleEffect(showCircle ? 1 : 0.2)
                            .animation(LingoAnimation.bouncy.delay(0.1), value: showCircle)

                        // Main circle — flat green
                        Circle()
                            .fill(Color.scorePronunciation)
                            .frame(width: 96, height: 96)
                            .scaleEffect(showCircle ? 1 : 0)
                            .shadow(color: .scorePronunciation.opacity(0.2), radius: 16, y: 6)
                            .animation(LingoAnimation.bouncy, value: showCircle)

                        // Checkmark
                        Image(systemName: "checkmark")
                            .font(.system(size: 44, weight: .bold))
                            .foregroundColor(.white)
                            .scaleEffect(showCheckmark ? 1 : 0)
                            .animation(LingoAnimation.bouncy.delay(0.3), value: showCheckmark)
                    }
                    .padding(.bottom, 28)

                    Text("Session Complete!")
                        .font(LingoFont.serif(30))
                        .foregroundColor(.lingoText)
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 12)
                        .animation(LingoAnimation.spring.delay(0.4), value: showContent)

                    Text("Great work today.")
                        .font(LingoFont.serifItalic(18))
                        .foregroundColor(.lingoTextSecondary)
                        .padding(.top, 4)
                        .opacity(showContent ? 1 : 0)
                        .animation(LingoAnimation.spring.delay(0.5), value: showContent)

                    // XP Breakdown
                    if let xp = appState.currentXP {
                        VStack(spacing: 0) {
                            HStack {
                                Text("BASE XP")
                                    .font(LingoFont.caption())
                                    .foregroundColor(.lingoTextSecondary)
                                Spacer()
                                Text("\(xp.base)")
                                    .font(LingoFont.serif(22))
                                    .foregroundColor(.lingoText)
                            }

                            HStack {
                                Text("CHALLENGE BONUS")
                                    .font(LingoFont.caption())
                                    .foregroundColor(.accentChallenge)
                                Spacer()
                                Text("+\(xp.bonus)")
                                    .font(LingoFont.serif(22))
                                    .foregroundColor(.accentChallenge)
                            }
                            .padding(.top, 10)

                            Rectangle()
                                .fill(Color.borderGray.opacity(0.5))
                                .frame(height: 1)
                                .padding(.vertical, 14)

                            HStack {
                                Text("TOTAL XP")
                                    .font(LingoFont.caption())
                                    .foregroundColor(.lingoTextSecondary)
                                Spacer()
                                HStack(spacing: 6) {
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 22))
                                        .foregroundStyle(LinearGradient.xpGold)
                                    AnimatedCounter(
                                        target: xp.total,
                                        duration: 1.5,
                                        font: LingoFont.serif(34),
                                        color: Color(hex: "FFAA00")
                                    )
                                }
                            }
                        }
                        .lingoCard()
                        .frame(maxWidth: 300)
                        .padding(.top, 40)
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 20)
                        .animation(LingoAnimation.spring.delay(0.6), value: showContent)
                    }

                    // Streak
                    if let streak = appState.currentStreak, streak.current_streak > 0 {
                        HStack(spacing: 8) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.lingoBlue)
                            Text("\(streak.current_streak) day streak!")
                                .font(LingoFont.headline(16))
                                .foregroundColor(.lingoText)
                        }
                        .padding(.top, 20)
                        .opacity(showContent ? 1 : 0)
                        .animation(LingoAnimation.spring.delay(0.8), value: showContent)
                    }

                    Spacer()
                }

                // Done button
                VStack {
                    Button(action: {
                        LingoHaptics.impact(.medium)
                        Task { await appState.startNewSession() }
                    }) {
                        Text("Done")
                    }
                    .buttonStyle(LingoPrimaryButtonStyle())
                }
                .padding(24)
                .background(Color.lingoBg)
                .overlay(
                    Rectangle().fill(Color.borderGray.opacity(0.3)).frame(height: 0.5),
                    alignment: .top
                )
            }

            // Confetti overlay
            if showConfetti {
                ConfettiView()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
        }
        .background(Color.lingoBg.ignoresSafeArea())
        .onAppear {
            LingoHaptics.notification(.success)
            showCircle = true
            showCheckmark = true
            showContent = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showConfetti = true
            }
        }
    }
}
