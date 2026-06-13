import SwiftUI
import AVFoundation

/// First-run walkthrough. A swipeable set of pages that explain the purpose of
/// the app and prime camera access, ending in "Get Started". Fully labelled for
/// VoiceOver since the audience includes blind and low-vision users.
struct WelcomeView: View {
    let onFinished: () -> Void

    @State private var page = 0

    private let pages: [WelcomePage] = [
        WelcomePage(
            icon: "hand.point.up.left.fill",
            title: "Welcome to Beyond Vision",
            message: "An app that lets you feel images and the world around you through touch and vibration."
        ),
        WelcomePage(
            icon: "photo.on.rectangle.angled",
            title: "Explore by touch",
            message: "Open any image, drag your finger across it, and feel objects come alive. Stronger vibration means an object is right under your finger."
        ),
        WelcomePage(
            icon: "speaker.wave.2.fill",
            title: "Hear what you feel",
            message: "As you touch an object, Beyond Vision speaks its name aloud — so you always know what you're feeling."
        ),
        WelcomePage(
            icon: "camera.viewfinder",
            title: "Feel the world live",
            message: "Switch to Live mode and point your camera. Move your finger across the screen to sense objects around you in real time.",
            requestsCamera: true
        )
    ]

    var body: some View {
        ZStack {
            Theme.backgroundGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(pages.indices, id: \.self) { i in
                        WelcomePageView(page: pages[i])
                            .tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: page)

                // Page indicator.
                HStack(spacing: 8) {
                    ForEach(pages.indices, id: \.self) { i in
                        Capsule()
                            .fill(i == page ? Theme.accent : Color.white.opacity(0.25))
                            .frame(width: i == page ? 24 : 8, height: 8)
                            .animation(.spring(response: 0.3), value: page)
                    }
                }
                .padding(.bottom, 28)
                .accessibilityHidden(true)

                VStack(spacing: 14) {
                    PrimaryButton(isLastPage ? "Get Started" : "Continue",
                                  systemImage: isLastPage ? "checkmark" : "arrow.right") {
                        advance()
                    }

                    Button("Skip", action: onFinished)
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                        .opacity(isLastPage ? 0 : 1)
                        .disabled(isLastPage)
                        .accessibilityHidden(isLastPage)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 40)
            }
        }
    }

    private var isLastPage: Bool { page == pages.count - 1 }

    private func advance() {
        if isLastPage {
            if pages[page].requestsCamera {
                // Prime camera permission so Live mode is ready on first use.
                Task {
                    _ = await AVCaptureDevice.requestAccess(for: .video)
                    onFinished()
                }
            } else {
                onFinished()
            }
        } else {
            withAnimation { page += 1 }
        }
    }
}

private struct WelcomePage: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let message: String
    var requestsCamera: Bool = false
}

private struct WelcomePageView: View {
    let page: WelcomePage
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            Image(systemName: page.icon)
                .font(.system(size: 84))
                .foregroundStyle(Theme.brandGradient)
                .frame(width: 160, height: 160)
                .background(Theme.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 36))
                .scaleEffect(appeared ? 1 : 0.7)
                .opacity(appeared ? 1 : 0)
                .accessibilityHidden(true)

            VStack(spacing: 14) {
                Text(page.title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text(page.message)
                    .font(.system(size: 17, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 32)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 16)

            Spacer()
            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) { appeared = true }
        }
    }
}
