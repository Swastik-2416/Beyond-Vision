import SwiftUI

/// Animated logo screen shown at launch. Concentric "haptic" rings ripple out
/// from a fingertip mark — the core metaphor of the app — then it auto-advances.
struct SplashView: View {
    let onFinished: () -> Void

    @State private var ringsExpanded = false
    @State private var logoVisible = false
    @State private var textVisible = false

    var body: some View {
        ZStack {
            Theme.backgroundGradient.ignoresSafeArea()

            VStack(spacing: 28) {
                ZStack {
                    // Rippling haptic rings.
                    ForEach(0..<3) { i in
                        Circle()
                            .stroke(Theme.accent.opacity(0.5 - Double(i) * 0.15), lineWidth: 2)
                            .frame(width: 120, height: 120)
                            .scaleEffect(ringsExpanded ? 1.8 + CGFloat(i) * 0.5 : 0.6)
                            .opacity(ringsExpanded ? 0 : 1)
                            .animation(
                                .easeOut(duration: 2.0).repeatForever(autoreverses: false)
                                    .delay(Double(i) * 0.4),
                                value: ringsExpanded
                            )
                    }

                    Circle()
                        .fill(Theme.brandGradient)
                        .frame(width: 110, height: 110)
                        .overlay(
                            Image(systemName: "hand.point.up.left.fill")
                                .font(.system(size: 46))
                                .foregroundStyle(.black)
                        )
                        .shadow(color: Theme.accent.opacity(0.5), radius: 24, y: 8)
                        .scaleEffect(logoVisible ? 1 : 0.4)
                        .opacity(logoVisible ? 1 : 0)
                }
                .accessibilityHidden(true)

                VStack(spacing: 8) {
                    Text("Beyond Vision")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Touch. Feel. Discover.")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                .opacity(textVisible ? 1 : 0)
                .offset(y: textVisible ? 0 : 12)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Beyond Vision. Touch, feel, discover.")
        .onAppear {
            ringsExpanded = true
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) { logoVisible = true }
            withAnimation(.easeOut(duration: 0.6).delay(0.3)) { textVisible = true }
            Task {
                try? await Task.sleep(for: .seconds(2.2))
                onFinished()
            }
        }
    }
}
