import SwiftUI

/// Central place for the app's colors, gradients and reusable visual styles.
/// Keeping this in one file makes it easy to keep every screen on-brand.
enum Theme {
    // Brand colors
    static let accent = Color.orange
    static let accentSecondary = Color.yellow
    static let background = Color.black

    /// Signature warm gradient used for logos, highlights and primary buttons.
    static let brandGradient = LinearGradient(
        colors: [accent, accentSecondary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Subtle dark backdrop with a hint of warmth, used behind full-screen flows.
    static let backgroundGradient = LinearGradient(
        colors: [Color.black, Color(red: 0.10, green: 0.06, blue: 0.0)],
        startPoint: .top,
        endPoint: .bottom
    )
}

/// A large, accessible primary button used across the launch flow.
struct PrimaryButton: View {
    let title: String
    let systemImage: String?
    let action: () -> Void

    init(_ title: String, systemImage: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .accessibilityHidden(true)
                }
                Text(title)
            }
            .font(.system(size: 17, weight: .semibold, design: .rounded))
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Theme.brandGradient)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Theme.accent.opacity(0.35), radius: 16, y: 8)
        }
    }
}
