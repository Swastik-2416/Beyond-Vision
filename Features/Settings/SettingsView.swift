import SwiftUI

/// Settings + Haptic Tuner. The sliders write the same UserDefaults keys the
/// HapticManager reads, so adjustments take effect everywhere immediately.
struct SettingsView: View {
    @ObservedObject var haptics: HapticManager
    @EnvironmentObject private var router: AppRouter

    @AppStorage("haptic.intensity") private var intensity = 0.8
    @AppStorage("haptic.sharpness") private var sharpness = 0.5
    @AppStorage(VisionManager.readTextKey) private var readTextAloud = true

    @State private var showHowItWorks = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    tunerHeader

                    if !haptics.supportsHaptics {
                        unsupportedNote
                    }

                    ParameterCard(icon: "bolt.fill", title: "Intensity",
                                  value: intensity, color: Theme.accent) {
                        Slider(value: $intensity, in: 0...1) { editing in
                            if !editing { haptics.preview() }
                        }
                        .tint(Theme.accent)
                        .accessibilityLabel("Intensity")
                        .accessibilityValue("\(Int(intensity * 100)) percent")
                        .accessibilityHint("Adjusts how strong the vibration feels")
                    }

                    ParameterCard(icon: "waveform.path", title: "Sharpness",
                                  value: sharpness, color: Theme.accentSecondary) {
                        Slider(value: $sharpness, in: 0...1) { editing in
                            if !editing { haptics.preview() }
                        }
                        .tint(Theme.accentSecondary)
                        .accessibilityLabel("Sharpness")
                        .accessibilityValue("\(Int(sharpness * 100)) percent")
                        .accessibilityHint("Adjusts how crisp the vibration feels")
                    }

                    Button { haptics.preview() } label: {
                        Label("Test Haptic", systemImage: "hand.tap.fill")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .glassEffect(in: .rect(cornerRadius: 16))
                    }
                    .accessibilityHint("Plays a short vibration so you can feel the current settings")

                    readingSection
                    helpSection
                    aboutSection
                }
                .padding(20)
            }
            .background(Theme.backgroundGradient.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showHowItWorks) { HowItWorksSheet() }
    }

    private var tunerHeader: some View {
        VStack(spacing: 8) {
            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 50))
                .foregroundStyle(Theme.brandGradient)
                .accessibilityHidden(true)
            Text("Haptic Tuner")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .accessibilityAddTraits(.isHeader)
            Text("Fine-tune vibration feedback to your preference")
                .font(.system(size: 14, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 12)
    }

    private var unsupportedNote: some View {
        Label("This device doesn't support haptics, but spoken labels still work.",
              systemImage: "exclamationmark.triangle.fill")
            .font(.system(size: 13, design: .rounded))
            .foregroundStyle(.secondary)
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassEffect(in: .rect(cornerRadius: 14))
    }

    private var readingSection: some View {
        HStack(spacing: 14) {
            Image(systemName: "text.viewfinder")
                .font(.system(size: 18))
                .foregroundStyle(Theme.accent)
                .frame(width: 40, height: 40)
                .background(Theme.accent.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text("Read text aloud")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                Text("Speak signs and labels in photos and live camera")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            Toggle("", isOn: $readTextAloud)
                .labelsHidden()
                .tint(Theme.accent)
        }
        .padding(14)
        .glassEffect(in: .rect(cornerRadius: 16))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Read text aloud")
        .accessibilityValue(readTextAloud ? "On" : "Off")
        .accessibilityHint("When on, signs and labels are read aloud as you explore")
    }

    private var helpSection: some View {
        VStack(spacing: 12) {
            Button { showHowItWorks = true } label: {
                SettingsRowLabel(icon: "questionmark.circle.fill", title: "How it works",
                                 subtitle: "Quick guide to using the app")
            }
            .buttonStyle(.plain)
            .accessibilityHint("Quick guide to using the app")

            NavigationLink {
                FeedbackView()
            } label: {
                SettingsRowLabel(icon: "text.bubble.fill", title: "Send feedback",
                                 subtitle: "Tell us what to add or fix")
            }
            .accessibilityHint("Tell us what to add or fix")

            Button { router.replayOnboarding() } label: {
                SettingsRowLabel(icon: "sparkles", title: "Replay welcome",
                                 subtitle: "See the introduction again")
            }
            .buttonStyle(.plain)
            .accessibilityHint("See the introduction again")
        }
    }

    private var aboutSection: some View {
        VStack(spacing: 6) {
            Text("Beyond Vision")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
            Text("Feel images and the world through touch.\nVersion 1.0")
                .font(.system(size: 12, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
        .accessibilityElement(children: .combine)
    }
}

private struct SettingsRowLabel: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(Theme.accent)
                .frame(width: 40, height: 40)
                .background(Theme.accent.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .glassEffect(in: .rect(cornerRadius: 16))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
    }
}

struct ParameterCard<SliderContent: View>: View {
    let icon: String
    let title: String
    let value: Double
    let color: Color
    @ViewBuilder let sliderContent: () -> SliderContent

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(color)
                    .frame(width: 36, height: 36)
                    .background(color.opacity(0.15), in: RoundedRectangle(cornerRadius: 10))
                    .accessibilityHidden(true)

                Text(title)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)

                Spacer()

                Text("\(Int(value * 100))%")
                    .font(.system(size: 15, weight: .bold, design: .monospaced))
                    .foregroundStyle(color)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(color.opacity(0.12), in: Capsule())
                    .accessibilityHidden(true)
            }

            sliderContent()
        }
        .padding(20)
        .glassEffect(in: .rect(cornerRadius: 20))
        .accessibilityElement(children: .contain)
    }
}
