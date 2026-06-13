import CoreHaptics
import SwiftUI

/// Drives continuous haptic feedback while the user explores an image or the
/// live camera. The intensity passed in by the vision layer is scaled by the
/// user's saved preferences so the Haptic Tuner has a real, end-to-end effect.
@MainActor
final class HapticManager: ObservableObject {

    /// Keys shared with the Settings sliders so changes apply everywhere.
    enum PrefKey {
        static let intensity = "haptic.intensity"
        static let sharpness = "haptic.sharpness"
    }

    /// User-tunable feedback strength (0...1), read fresh from saved preferences.
    var userIntensity: Float {
        Float(UserDefaults.standard.object(forKey: PrefKey.intensity) as? Double ?? 0.8)
    }
    /// User-tunable feedback crispness (0...1), read fresh from saved preferences.
    var userSharpness: Float {
        Float(UserDefaults.standard.object(forKey: PrefKey.sharpness) as? Double ?? 0.5)
    }

    /// Whether the device actually supports Core Haptics.
    let supportsHaptics = CHHapticEngine.capabilitiesForHardware().supportsHaptics

    private var engine: CHHapticEngine?
    private var player: CHHapticAdvancedPatternPlayer?
    private var isPlaying = false

    init() {
        guard supportsHaptics else { return }
        do {
            let engine = try CHHapticEngine()
            engine.playsHapticsOnly = true
            // Restart automatically if the engine is reset by the system.
            engine.resetHandler = { [weak engine] in try? engine?.start() }
            try engine.start()
            self.engine = engine
        } catch {
            print("Haptic engine init error: \(error)")
            self.engine = nil
        }
    }

    /// Begins a continuous haptic that we then modulate via `update`.
    func start() {
        guard !isPlaying, let engine else { return }
        isPlaying = true

        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5)
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: Float(userSharpness))
        let event = CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [intensity, sharpness],
            relativeTime: 0,
            duration: 100
        )
        do {
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine.makeAdvancedPlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
            self.player = player
        } catch {
            print("Haptic start error: \(error)")
            isPlaying = false
        }
    }

    /// Updates the live haptic. `intensity` (0...1) comes from the vision layer;
    /// it is scaled by the user's preferred strength.
    func update(intensity: Float) {
        guard let player else { return }
        let scaled = max(0, min(1, intensity * Float(userIntensity)))
        let iParam = CHHapticDynamicParameter(parameterID: .hapticIntensityControl, value: scaled, relativeTime: 0)
        let sParam = CHHapticDynamicParameter(parameterID: .hapticSharpnessControl, value: Float(userSharpness), relativeTime: 0)
        do {
            try player.sendParameters([iParam, sParam], atTime: 0)
        } catch {
            print("Haptic update error: \(error)")
        }
    }

    /// Plays a short preview burst, used by the Tuner so changes can be felt.
    func preview() {
        start()
        update(intensity: 1.0)
        Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(350))
            self?.stop()
        }
    }

    func stop() {
        isPlaying = false
        try? player?.stop(atTime: CHHapticTimeImmediate)
        player = nil
    }
}
