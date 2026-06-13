import SwiftUI

/// Top-level view that walks the user through the launch flow and then hands
/// off to the main tabbed interface. Owns the shared HapticManager so the same
/// engine is reused everywhere.
struct RootView: View {
    @StateObject private var router = AppRouter()
    @StateObject private var haptics = HapticManager()

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            switch router.phase {
            case .splash:
                SplashView { router.advanceFromSplash() }
                    .transition(.opacity)
            case .intro:
                LaunchIntroView { router.advanceFromIntro() }
                    .transition(.opacity)
            case .onboarding:
                WelcomeView { router.finishOnboarding() }
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            case .main:
                MainTabView(haptics: haptics)
                    .environmentObject(router)
                    .transition(.opacity)
            }
        }
    }
}
