import SwiftUI

/// The phases of the app's launch flow, in order.
enum AppPhase {
    case splash      // animated logo
    case intro       // launch video / motion intro
    case onboarding  // first-run welcome walkthrough
    case main        // the tabbed app
}

/// Drives which screen is shown at launch. Onboarding only appears the first
/// time the app is opened; after that, splash + intro lead straight to `main`.
@MainActor
final class AppRouter: ObservableObject {
    @Published var phase: AppPhase = .splash

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    func advanceFromSplash() {
        withAnimation(.easeInOut(duration: 0.5)) { phase = .intro }
    }

    func advanceFromIntro() {
        withAnimation(.easeInOut(duration: 0.5)) {
            phase = hasCompletedOnboarding ? .main : .onboarding
        }
    }

    func finishOnboarding() {
        hasCompletedOnboarding = true
        withAnimation(.easeInOut(duration: 0.5)) { phase = .main }
    }

    /// Lets the user replay the welcome walkthrough from Settings.
    func replayOnboarding() {
        withAnimation(.easeInOut(duration: 0.4)) { phase = .onboarding }
    }
}
