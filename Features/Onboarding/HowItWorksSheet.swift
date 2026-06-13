import SwiftUI

/// A concise "how to use the app" reference, shown as a sheet from Explore and
/// Settings. Distinct from the first-run WelcomeView walkthrough.
struct HowItWorksSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 12) {
                        Image(systemName: "hand.point.up.left.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(Theme.brandGradient)
                            .frame(width: 88, height: 88)
                            .background(Theme.accent.opacity(0.15), in: RoundedRectangle(cornerRadius: 22))
                            .accessibilityHidden(true)
                        Text("How it works")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .accessibilityAddTraits(.isHeader)
                    }
                    .padding(.top, 12)

                    VStack(alignment: .leading, spacing: 18) {
                        HowItWorksStep(number: "1", icon: "photo.fill",
                                       text: "Choose an image from the gallery or upload your own.")
                        HowItWorksStep(number: "2", icon: "hand.tap.fill",
                                       text: "Touch anywhere on the image to explore it.")
                        HowItWorksStep(number: "3", icon: "waveform",
                                       text: "Feel haptic vibrations that map objects — stronger means right on it.")
                        HowItWorksStep(number: "4", icon: "speaker.wave.2.fill",
                                       text: "Hear each object's name spoken aloud as you touch it.")
                        HowItWorksStep(number: "5", icon: "camera.viewfinder",
                                       text: "In Live mode, feel the objects around you through the camera.")
                    }
                    .padding(.horizontal, 4)
                }
                .padding(24)
            }
            .background(Theme.backgroundGradient.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Theme.accent)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

struct HowItWorksStep: View {
    let number: String
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 14) {
            Text(number)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.accent)
                .frame(width: 30, height: 30)
                .background(Theme.accent.opacity(0.15), in: Circle())
                .accessibilityHidden(true)

            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(Theme.accent.opacity(0.8))
                .frame(width: 24)
                .accessibilityHidden(true)

            Text(text)
                .font(.system(size: 15, design: .rounded))
                .foregroundStyle(.white.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Step \(number): \(text)")
    }
}
