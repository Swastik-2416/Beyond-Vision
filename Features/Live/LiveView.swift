import SwiftUI
import AVFoundation

/// Real-time camera exploration. Frames stream through the vision layer and the
/// user drags a finger over the preview to feel objects around them.
struct LiveView: View {
    @StateObject private var camera = CameraManager()
    @StateObject private var vision = VisionManager()
    @ObservedObject var haptics: HapticManager

    @State private var showStatusPill = true

    var body: some View {
        GeometryReader { geo in
            ZStack {
                CameraPreview(session: camera.session)
                    .ignoresSafeArea()
                    .accessibilityLabel("Live camera feed")
                    .accessibilityHint("Move your finger across the screen to feel objects in real time. Stronger vibration means an object is closer. Lift your finger to stop.")
                    .accessibilityAddTraits(.allowsDirectInteraction)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { val in
                                haptics.start()
                                let result = vision.hitTest(at: val.location, size: geo.size)
                                haptics.update(intensity: result.intensity)
                            }
                            .onEnded { _ in haptics.stop() }
                    )

                if showStatusPill {
                    VStack {
                        StatusPill(status: camera.status)
                            .padding(.top, 60)
                        Spacer()
                    }
                    .allowsHitTesting(false)
                    .transition(.opacity)
                }
            }
        }
        .onAppear {
            camera.start()
            camera.setFrameHandler { buffer in
                // Analyze directly on the background video queue — VisionManager
                // guards against overlapping calls with isAnalyzing, so frames
                // that arrive while analysis is in flight are simply dropped.
                // Avoid dispatching to main first: the pixel buffer may be
                // reclaimed by the camera pipeline before the block runs, causing
                // a crash or corrupted frame.
                vision.analyze(pixelBuffer: buffer)
            }
        }
        .onChange(of: camera.status) { _, newStatus in
            if newStatus == .active {
                Task {
                    try? await Task.sleep(for: .seconds(2))
                    withAnimation(.easeOut(duration: 0.5)) { showStatusPill = false }
                }
            }
        }
        .onDisappear {
            camera.stop()
            camera.setFrameHandler(nil)
            showStatusPill = true
        }
    }
}

struct StatusPill: View {
    let status: CameraManager.Status

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(status.isActive ? Color.green : Theme.accent)
                .frame(width: 8, height: 8)
                .accessibilityHidden(true)

            Image(systemName: status.isActive ? "camera.fill" : "exclamationmark.triangle.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(status.isActive ? .green : Theme.accent)
                .accessibilityHidden(true)

            Text(status.message)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: Capsule())
        .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(status.isActive ? "Camera is active and ready" : "Camera status: \(status.message)")
    }
}

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewUIView {
        let view = PreviewUIView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewUIView, context: Context) {
        uiView.previewLayer.session = session
    }
}

/// A UIView whose backing layer is the camera preview, so it always tracks bounds.
final class PreviewUIView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
}
