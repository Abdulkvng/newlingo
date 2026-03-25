import SwiftUI

// MARK: - Onboarding Flow

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @State private var step: OnboardingStep = .welcome
    @State private var email = ""
    @State private var password = ""
    @State private var displayName = ""
    @State private var isLoading = false
    @State private var isLogin = false
    @State private var selectedLanguage: SupportedLanguage = .english
    @State private var selectedLevel: ProficiencyLevel = .beginner

    enum OnboardingStep: Int, CaseIterable {
        case welcome = 0
        case language = 1
        case level = 2
        case account = 3
    }

    var body: some View {
        ZStack {
            Color.lingoBg.ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress indicator (hidden on welcome)
                if step != .welcome && !isLogin {
                    OnboardingProgress(current: step.rawValue, total: 3)
                        .padding(.top, 16)
                        .padding(.horizontal, 24)
                        .transition(.opacity)
                }

                // Content
                TabView(selection: $step) {
                    WelcomeStep(
                        onGetStarted: { withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) { step = .language } },
                        onLogin: { withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) { isLogin = true; step = .account } }
                    )
                    .tag(OnboardingStep.welcome)

                    LanguageStep(selected: $selectedLanguage) {
                        LingoHaptics.impact(.light)
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) { step = .level }
                    }
                    .tag(OnboardingStep.language)

                    LevelStep(selected: $selectedLevel) {
                        LingoHaptics.impact(.light)
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) { step = .account }
                    }
                    .tag(OnboardingStep.level)

                    AccountStep(
                        email: $email,
                        password: $password,
                        displayName: $displayName,
                        isLogin: $isLogin,
                        isLoading: $isLoading,
                        error: appState.error,
                        onSubmit: submit,
                        onBack: {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                                if isLogin { isLogin = false; step = .welcome }
                                else { step = .level }
                            }
                        },
                        onToggleMode: {
                            LingoHaptics.impact(.light)
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                                isLogin.toggle()
                            }
                        }
                    )
                    .tag(OnboardingStep.account)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(response: 0.5, dampingFraction: 0.85), value: step)
            }
        }
    }

    private func submit() {
        LingoHaptics.impact(.medium)
        isLoading = true
        appState.targetLanguage = selectedLanguage
        appState.proficiencyLevel = selectedLevel
        Task {
            if isLogin {
                await appState.login(email: email, password: password)
            } else {
                await appState.register(email: email, password: password, name: displayName)
            }
            isLoading = false
        }
    }
}

// MARK: - Progress Dots

struct OnboardingProgress: View {
    let current: Int
    let total: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(1...total, id: \.self) { i in
                Capsule()
                    .fill(i <= current ? Color.lingoText : Color.lingoText.opacity(0.1))
                    .frame(width: i == current ? 28 : 8, height: 4)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: current)
            }
        }
    }
}

// MARK: - Step 0: Welcome

struct WelcomeStep: View {
    let onGetStarted: () -> Void
    let onLogin: () -> Void
    @State private var appeared = false
    @State private var glowPulse = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 36) {
                // Waveform icon with radial glow
                ZStack {
                    // Radial glow
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.lingoBlue.opacity(0.08), Color.clear],
                                center: .center,
                                startRadius: 20,
                                endRadius: 80
                            )
                        )
                        .frame(width: 160, height: 160)
                        .scaleEffect(glowPulse ? 1.05 : 0.95)
                        .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: glowPulse)

                    Circle()
                        .fill(Color.lingoBlue.opacity(0.05))
                        .frame(width: 88, height: 88)

                    Image(systemName: "waveform")
                        .font(.system(size: 34, weight: .medium))
                        .foregroundColor(.lingoBlueDeep)
                }
                .scaleEffect(appeared ? 1 : 0.6)
                .opacity(appeared ? 1 : 0)
                .animation(.spring(response: 0.7, dampingFraction: 0.6), value: appeared)

                // Brand + tagline
                VStack(spacing: 16) {
                    Text("Lingo")
                        .font(LingoFont.serif(52))
                        .foregroundColor(.lingoText)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 8)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: appeared)

                    Text("Speak confidently.\nIn real-life situations.")
                        .font(LingoFont.serifItalic(22))
                        .foregroundColor(.lingoTextSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 8)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: appeared)
                }
            }

            Spacer()

            // CTAs
            VStack(spacing: 16) {
                Button(action: onGetStarted) {
                    Text("Get Started")
                }
                .buttonStyle(LingoPrimaryButtonStyle())
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 16)
                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.35), value: appeared)

                Button(action: onLogin) {
                    Text("I already have an account")
                        .font(LingoFont.body(15))
                        .fontWeight(.medium)
                        .foregroundColor(.lingoText.opacity(0.45))
                }
                .opacity(appeared ? 1 : 0)
                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.45), value: appeared)
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 52)
        }
        .onAppear {
            appeared = true
            glowPulse = true
        }
    }
}

// MARK: - Step 1: Language

struct LanguageStep: View {
    @Binding var selected: SupportedLanguage
    let onNext: () -> Void
    @State private var appeared = false

    private let languages: [(SupportedLanguage, String, String)] = [
        (.english, "🇺🇸", "EN"),
        (.spanish, "🇪🇸", "ES"),
        (.french, "🇫🇷", "FR"),
        (.german, "🇩🇪", "DE"),
        (.italian, "🇮🇹", "IT"),
        (.japanese, "🇯🇵", "JA"),
        (.yoruba, "🇳🇬", "YO"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 48)

            LingoSectionHeader(line1: "What language are", line2: "you practicing?")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 28)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 12)
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: appeared)

            Spacer().frame(height: 32)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 10) {
                    ForEach(Array(languages.enumerated()), id: \.element.0) { index, item in
                        Button(action: {
                            LingoHaptics.selection()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                selected = item.0
                            }
                        }) {
                            HStack(spacing: 14) {
                                Text(item.1)
                                    .font(.system(size: 28))

                                Text(item.0.rawValue)
                                    .font(LingoFont.body(17))
                                    .fontWeight(.medium)
                                    .foregroundColor(.lingoText)

                                Spacer()

                                Text(item.2)
                                    .font(LingoFont.caption(11))
                                    .foregroundColor(.lingoTextSecondary.opacity(0.6))

                                if selected == item.0 {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.lingoBlueDeep)
                                        .transition(.scale.combined(with: .opacity))
                                }
                            }
                            .padding(.horizontal, 18)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white)
                                    .shadow(color: selected == item.0 ? Color.lingoBlue.opacity(0.1) : .black.opacity(0.03), radius: selected == item.0 ? 8 : 4, y: 2)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(selected == item.0 ? Color.lingoBlue.opacity(0.25) : .clear, lineWidth: 1.5)
                            )
                        }
                        .buttonStyle(.plain)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 12)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(Double(index) * 0.04), value: appeared)
                    }
                }
                .padding(.horizontal, 28)
            }

            Button(action: onNext) {
                Text("Continue")
            }
            .buttonStyle(LingoPrimaryButtonStyle())
            .padding(.horizontal, 28)
            .padding(.bottom, 48)
            .padding(.top, 16)
            .opacity(appeared ? 1 : 0)
            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.35), value: appeared)
        }
        .onAppear { appeared = true }
    }
}

// MARK: - Step 2: Level

struct LevelStep: View {
    @Binding var selected: ProficiencyLevel
    let onNext: () -> Void
    @State private var appeared = false

    private let levels: [(ProficiencyLevel, String, String, String)] = [
        (.beginner, "Beginner", "Just starting out or know the basics", "seedling"),
        (.intermediate, "Intermediate", "Can hold conversations on familiar topics", "leaf"),
        (.expert, "Expert", "Fluent, looking to polish and perfect", "tree"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 48)

            LingoSectionHeader(line1: "What's your", line2: "current level?")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 28)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 12)
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: appeared)

            Spacer().frame(height: 36)

            VStack(spacing: 12) {
                ForEach(Array(levels.enumerated()), id: \.element.0) { index, item in
                    Button(action: {
                        LingoHaptics.selection()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            selected = item.0
                        }
                    }) {
                        HStack(spacing: 16) {
                            Image(systemName: item.3)
                                .font(.system(size: 20))
                                .foregroundColor(selected == item.0 ? .lingoBlueDeep : .lingoTextSecondary.opacity(0.5))
                                .frame(width: 28)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.1)
                                    .font(LingoFont.headline(17))
                                    .foregroundColor(.lingoText)
                                Text(item.2)
                                    .font(LingoFont.body(14))
                                    .foregroundColor(.lingoTextSecondary)
                            }

                            Spacer()

                            if selected == item.0 {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 22))
                                    .foregroundColor(.lingoBlueDeep)
                                    .transition(.scale.combined(with: .opacity))
                            } else {
                                Circle()
                                    .stroke(Color.lingoText.opacity(0.12), lineWidth: 1.5)
                                    .frame(width: 22, height: 22)
                            }
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(Color.white)
                                .shadow(color: selected == item.0 ? Color.lingoBlue.opacity(0.1) : .black.opacity(0.03), radius: selected == item.0 ? 8 : 4, y: 2)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(selected == item.0 ? Color.lingoBlue.opacity(0.25) : .clear, lineWidth: 1.5)
                        )
                    }
                    .buttonStyle(.plain)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 12)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(Double(index) * 0.06), value: appeared)
                }
            }
            .padding(.horizontal, 28)

            Spacer()

            Button(action: onNext) {
                Text("Continue")
            }
            .buttonStyle(LingoPrimaryButtonStyle())
            .padding(.horizontal, 28)
            .padding(.bottom, 48)
            .opacity(appeared ? 1 : 0)
            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.25), value: appeared)
        }
        .onAppear { appeared = true }
    }
}

// MARK: - Step 3: Account

struct AccountStep: View {
    @Binding var email: String
    @Binding var password: String
    @Binding var displayName: String
    @Binding var isLogin: Bool
    @Binding var isLoading: Bool
    let error: String?
    let onSubmit: () -> Void
    let onBack: () -> Void
    let onToggleMode: () -> Void
    @State private var appeared = false
    @FocusState private var focusedField: Field?

    enum Field { case name, email, password }

    private var isFormValid: Bool {
        if isLogin {
            return !email.isEmpty && !password.isEmpty
        }
        return !email.isEmpty && !password.isEmpty && !displayName.isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            // Back button
            HStack {
                Button(action: onBack) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Back")
                            .font(LingoFont.body(15))
                    }
                    .foregroundColor(.lingoTextSecondary)
                }
                Spacer()
            }
            .padding(.horizontal, 28)
            .padding(.top, 16)

            Spacer().frame(height: 24)

            Text(isLogin ? "Welcome back" : "Create your account")
                .font(LingoFont.serif(28))
                .foregroundColor(.lingoText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 28)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 12)
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: appeared)

            Spacer().frame(height: 36)

            VStack(spacing: 14) {
                if !isLogin {
                    OnboardingTextField(
                        placeholder: "Your name",
                        text: $displayName,
                        icon: "person"
                    )
                    .focused($focusedField, equals: .name)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .email }
                    .transition(.opacity.combined(with: .offset(y: -8)))
                }

                OnboardingTextField(
                    placeholder: "Email address",
                    text: $email,
                    icon: "envelope"
                )
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($focusedField, equals: .email)
                .submitLabel(.next)
                .onSubmit { focusedField = .password }

                OnboardingSecureField(
                    placeholder: "Password",
                    text: $password
                )
                .focused($focusedField, equals: .password)
                .submitLabel(.go)
                .onSubmit { if isFormValid { onSubmit() } }

                if let error = error {
                    Text(error)
                        .font(LingoFont.body(13))
                        .foregroundColor(.lingoRed)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 2)
                }
            }
            .padding(.horizontal, 28)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 12)
            .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1), value: appeared)

            Spacer()

            VStack(spacing: 14) {
                Button(action: onSubmit) {
                    if isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text(isLogin ? "Log In" : "Create Account")
                    }
                }
                .buttonStyle(LingoPrimaryButtonStyle(disabled: !isFormValid))
                .disabled(!isFormValid || isLoading)

                Button(action: onToggleMode) {
                    Group {
                        if isLogin {
                            Text("Don't have an account? ") + Text("Sign up").fontWeight(.semibold)
                        } else {
                            Text("Already have an account? ") + Text("Log in").fontWeight(.semibold)
                        }
                    }
                    .font(LingoFont.body(14))
                    .foregroundColor(.lingoTextSecondary)
                }
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 48)
            .opacity(appeared ? 1 : 0)
            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.25), value: appeared)
        }
        .onAppear { appeared = true }
    }
}

// MARK: - Text Field Components

struct OnboardingTextField: View {
    let placeholder: String
    @Binding var text: String
    let icon: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.lingoTextSecondary.opacity(0.6))
                .frame(width: 20)

            TextField(placeholder, text: $text)
                .font(LingoFont.body(16))
                .foregroundColor(.lingoText)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }
}

struct OnboardingSecureField: View {
    let placeholder: String
    @Binding var text: String
    @State private var showPassword = false

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "lock")
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.lingoTextSecondary.opacity(0.6))
                .frame(width: 20)

            if showPassword {
                TextField(placeholder, text: $text)
                    .font(LingoFont.body(16))
                    .foregroundColor(.lingoText)
            } else {
                SecureField(placeholder, text: $text)
                    .font(LingoFont.body(16))
                    .foregroundColor(.lingoText)
            }

            Button(action: { showPassword.toggle() }) {
                Image(systemName: showPassword ? "eye.slash" : "eye")
                    .font(.system(size: 15))
                    .foregroundColor(.lingoTextSecondary.opacity(0.4))
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }
}
