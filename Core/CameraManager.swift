import AVFoundation
import Combine

/// Manages the live camera capture session and streams frames to the vision
/// layer. Uses the modern `videoRotationAngle` API (the old `videoOrientation`
/// is deprecated).
@MainActor
final class CameraManager: ObservableObject {
    @Published var session = AVCaptureSession()
    @Published var status: Status = .initializing

    enum Status: Equatable {
        case initializing
        case requestingAccess
        case active
        case denied
        case noCamera

        var message: String {
            switch self {
            case .initializing:    return "Initializing…"
            case .requestingAccess: return "Requesting Access…"
            case .active:          return "Camera Active"
            case .denied:          return "Camera Access Denied"
            case .noCamera:        return "No Camera Found"
            }
        }

        var isActive: Bool { self == .active }
    }

    /// All session configuration/start/stop happens here, off the main thread.
    private let sessionQueue = DispatchQueue(label: "camera.session")
    private let videoQueue = DispatchQueue(label: "camera.frame.processing", qos: .userInteractive)
    private let receiver = FrameReceiver()

    /// Registers a handler that receives each camera frame (called off the main
    /// thread). The handler is responsible for hopping to the main actor if needed.
    func setFrameHandler(_ handler: ((CVPixelBuffer) -> Void)?) {
        receiver.onFrame = handler
    }

    func start() {
        status = .requestingAccess
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setup()
        case .notDetermined:
            Task {
                let granted = await AVCaptureDevice.requestAccess(for: .video)
                if granted { setup() } else { status = .denied }
            }
        default:
            status = .denied
        }
    }

    func stop() {
        // AVCaptureSession isn't Sendable, but stopRunning() is thread-safe, so
        // we vouch for it across the queue with a wrapper.
        let box = UncheckedSendable(session)
        sessionQueue.async {
            box.value.stopRunning()
        }
    }

    private func setup() {
        status = .initializing
        let receiver = self.receiver
        let videoQueue = self.videoQueue

        sessionQueue.async { [weak self] in
            let session = AVCaptureSession()
            session.beginConfiguration()

            let discovery = AVCaptureDevice.DiscoverySession(
                deviceTypes: [.builtInWideAngleCamera, .builtInDualCamera, .builtInTrueDepthCamera],
                mediaType: .video,
                position: .unspecified
            )
            let device = discovery.devices.first(where: { $0.position == .back })
                ?? discovery.devices.first(where: { $0.position == .front })
                ?? discovery.devices.first

            if let device, let input = try? AVCaptureDeviceInput(device: device),
               session.canAddInput(input) {
                session.addInput(input)
            }

            let output = AVCaptureVideoDataOutput()
            if session.canAddOutput(output) {
                output.setSampleBufferDelegate(receiver, queue: videoQueue)
                output.alwaysDiscardsLateVideoFrames = true
                session.addOutput(output)

                if let connection = output.connection(with: .video) {
                    // Portrait is 90°. Replaces the deprecated videoOrientation API.
                    if connection.isVideoRotationAngleSupported(90) {
                        connection.videoRotationAngle = 90
                    }
                    if device?.position == .front, connection.isVideoMirroringSupported {
                        connection.isVideoMirrored = true
                    }
                }
            }

            session.commitConfiguration()

            if !session.inputs.isEmpty {
                session.startRunning()
                let box = UncheckedSendable(session)
                Task { @MainActor in
                    self?.session = box.value
                    self?.status = .active
                }
            } else {
                Task { @MainActor in self?.status = .noCamera }
            }
        }
    }
}

private final class FrameReceiver: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, @unchecked Sendable {
    private let lock = NSLock()
    private var _onFrame: ((CVPixelBuffer) -> Void)?
    var onFrame: ((CVPixelBuffer) -> Void)? {
        get { lock.withLock { _onFrame } }
        set { lock.withLock { _onFrame = newValue } }
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
            onFrame?(pixelBuffer)
        }
    }
}
