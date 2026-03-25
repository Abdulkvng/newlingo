import SwiftUI

struct RootView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ZStack {
            switch appState.currentScreen {
            case .onboarding:
                OnboardingView()
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
            case .prompt, .recording:
                // Recording is now an overlay inside PromptView
                PromptView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            case .loading:
                LoadingView()
                    .transition(.opacity)
            case .feedback:
                FeedbackView()
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            case .completion:
                CompletionView()
                    .transition(.scale(scale: 0.92).combined(with: .opacity))
            case .dashboard:
                DashboardView()
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            case .profile:
                ProfileView()
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: appState.currentScreen)
    }
}
