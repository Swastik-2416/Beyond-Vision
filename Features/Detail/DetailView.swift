import SwiftUI
import AVFoundation

/// Full-screen haptic exploration of a single image. Drag a finger across the
/// image to feel objects; tap the info button to hear a description.
struct DetailView: View {
    let image: UIImage
    let explainerText: String
    @ObservedObject var haptics: HapticManager
    @ObservedObject var vision: VisionManager

    @State private var synthesizer = AVSpeechSynthesizer()
    @State private var showTouchHint = true
    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    .accessibilityLabel("Haptic exploration image")
                    .accessibilityHint("Move your finger across the screen to feel objects. Stronger vibration means an object is under your finger. Lift your finger to stop.")
                    .accessibilityAddTraits(.allowsDirectInteraction)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { val in
                                if showTouchHint {
                                    withAnimation(.easeOut(duration: 0.3)) { showTouchHint = false }
                                }
                                haptics.start()
                                let result = vision.hitTest(at: val.location, size: geo.size)
                                haptics.update(intensity: result.intensity)
                            }
                            .onEnded { _ in haptics.stop() }
                    )

                bottomGradient

                if showTouchHint { touchHint }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            vision.analyze(image: image)
            pulseScale = 1.15
        }
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    let utterance = AVSpeechUtterance(string: explainerText)
                    utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
                    synthesizer.speak(utterance)
                } label: {
                    Image(systemName: "info.circle")
                        .font(.title3)
                        .foregroundStyle(.white)
                }
                .accessibilityLabel("Read description")
                .accessibilityHint("Reads aloud a description of what is in this image")
            }
        }
    }

    private var bottomGradient: some View {
        VStack {
            Spacer()
            LinearGradient(colors: [.clear, .black.opacity(0.4)], startPoint: .top, endPoint: .bottom)
                .frame(height: 120)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var touchHint: some View {
        VStack(spacing: 12) {
            Image(systemName: "hand.point.up.fill")
                .font(.system(size: 40))
                .foregroundStyle(.white.opacity(0.8))
                .scaleEffect(pulseScale)
                .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: pulseScale)
            Text("Touch to Feel")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.7))
        }
        .transition(.opacity)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
