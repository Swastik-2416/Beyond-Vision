import Foundation

/// Wraps a non-Sendable value so it can safely cross a concurrency boundary when
/// we know the usage is safe — e.g. AVFoundation objects (`AVCaptureSession`,
/// `CVPixelBuffer`) that are thread-safe for the operations we perform on them.
struct UncheckedSendable<T>: @unchecked Sendable {
    let value: T
    init(_ value: T) { self.value = value }
}
