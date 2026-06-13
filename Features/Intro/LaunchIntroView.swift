import SwiftUI
import AVKit

/// The launch "video" screen. If an `intro.mp4` is bundled in Resources it
/// plays that; otherwise it shows a self-contained animated motion intro so the
/// app always has a polished opening. Either way the user can Skip.
struct LaunchIntroView: View {
    let onFinished: () -> Void

    private var bundledVideoURL: URL? {
        Bundle.main.url(forResource: "intro", withExtension: "mp4")
            ?? Bundle.main.url(forResource: "launch", withExtension: "mp4")
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            if let url = bundledVideoURL {
                IntroVideoPlayer(url: url, onFinished: onFinished)
                    .ignoresSafeArea()
            } else {
                MotionIntro(onFinished: onFinished)
            }

            Button("Skip", action: onFinished)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial, in: Capsule())
                .padding(.top, 16)
                .padding(.trailing, 20)
                .accessibilityHint("Skips the intro and continues")
        }
    }
}

// MARK: - Bundled video

private struct IntroVideoPlayer: View {
    let url: URL
    let onFinished: () -> Void
    @State private var player = AVPlayer()

    var body: some View {
        VideoPlayer(player: player)
            .onAppear {
                player.replaceCurrentItem(with: AVPlayerItem(url: url))
                player.play()
            }
            .onDisappear { player.pause() }
            .onReceive(NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime)) { note in
                if let item = note.object as? AVPlayerItem, item === player.currentItem {
                    onFinished()
                }
            }
            .accessibilityLabel("Introduction video")
    }
}

// MARK: - Animated fallback intro

private struct IntroScene: Identifiable {
    let id = Int.random(in: 0...Int.max)
    let icon: String
    let title: String
    let subtitle: String
}

private struct MotionIntro: View {
    let onFinished: () -> Void

    private let scenes: [IntroScene] = [
        IntroScene(icon: "hand.point.up.left.fill", title: "See with your fingertips",
                   subtitle: "Beyond Vision turns images into touch."),
        IntroScene(icon: "waveform", title: "Feel what's there",
                   subtitle: "Objects answer back with haptic vibration."),
        IntroScene(icon: "camera.viewfinder", title: "Explore the world live",
                   subtitle: "Point your camera and feel your surroundings.")
    ]

    @State private var index = 0
    @State private var ripple = false
    @State private var finished = false

    private let timer = Timer.publish(every: 2.2, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Theme.backgroundGradient.ignoresSafeArea()

            // Soft pulsing rings in the background for ambient motion.
            ForEach(0..<3) { i in
                Circle()
                    .stroke(Theme.accent.opacity(0.25), lineWidth: 1.5)
                    .frame(width: 200, height: 200)
                    .scaleEffect(ripple ? 2.2 + CGFloat(i) * 0.4 : 0.5)
                    .opacity(ripple ? 0 : 0.6)
                    .animation(.easeOut(duration: 2.6).repeatForever(autoreverses: false).delay(Double(i) * 0.5), value: ripple)
            }
            .accessibilityHidden(true)

            VStack(spacing: 22) {
                Image(systemName: scenes[index].icon)
                    .font(.system(size: 70))
                    .foregroundStyle(Theme.brandGradient)
                    .id("icon\(index)")
                    .transition(.scale.combined(with: .opacity))

                VStack(spacing: 10) {
                    Text(scenes[index].title)
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                    Text(scenes[index].subtitle)
                        .font(.system(size: 16, design: .rounded))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .id("text\(index)")
                .transition(.opacity)
                .padding(.horizontal, 40)

                // Progress dots.
                HStack(spacing: 8) {
                    ForEach(scenes.indices, id: \.self) { i in
                        Capsule()
                            .fill(i == index ? Theme.accent : Color.white.opacity(0.25))
                            .frame(width: i == index ? 22 : 8, height: 8)
                            .animation(.spring(response: 0.3), value: index)
                    }
                }
                .padding(.top, 8)
                .accessibilityHidden(true)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(scenes[index].title). \(scenes[index].subtitle)")
        }
        .onAppear { ripple = true }
        .onReceive(timer) { _ in
            guard !finished else { return }
            if index < scenes.count - 1 {
                withAnimation(.easeInOut(duration: 0.5)) { index += 1 }
            } else {
                finished = true
                onFinished()
            }
        }
    }
}
