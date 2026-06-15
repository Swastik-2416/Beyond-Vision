import Vision
import UIKit
import AVFoundation

struct DetectedObject: Equatable {
    let boundingBox: CGRect
    let confidence: Float
    let topLabel: String?
}

/// Analyzes an image or live camera frame to find objects and answer
/// "what is under the user's finger?" so the haptic layer can respond.
///
/// Pipeline (most to least specific):
///   1. YOLO Core ML detector (80 COCO classes) + Vision's animal recognizer
///      give localized boxes.
///   2. Objectness saliency finds "something is here" regions the detector missed.
///   3. Every candidate box is refined with Vision's fine-grained image
///      classifier (~1300 categories) constrained to that region, turning a
///      generic "dog" into e.g. "golden retriever".
///   4. On still images, text recognition reads signs and labels aloud.
final class VisionManager: ObservableObject, @unchecked Sendable {
    @Published var observations: [DetectedObject] = []

    private let speech = AVSpeechSynthesizer()
    private var lastLabel = ""
    private var compiledModelURL: URL?
    /// Guards against queuing up overlapping analyses on the live camera feed.
    private var isAnalyzing = false

    private enum Mode { case still, live }

    init() {
        prepareModel()
    }

    private func prepareModel() {
        guard let url = Bundle.main.url(forResource: "ObjectDetector", withExtension: "mlmodelc") else {
            print("Warning: ObjectDetector.mlmodelc not found in bundle.")
            return
        }
        compiledModelURL = url
    }

    func analyze(image: UIImage) {
        guard let cgImage = image.cgImage else { return }
        performAnalysis(on: .cgImage(cgImage),
                        size: CGSize(width: cgImage.width, height: cgImage.height),
                        mode: .still)
    }

    func analyze(pixelBuffer: CVPixelBuffer) {
        let size = CGSize(width: CVPixelBufferGetWidth(pixelBuffer),
                          height: CVPixelBufferGetHeight(pixelBuffer))
        performAnalysis(on: .pixelBuffer(pixelBuffer), size: size, mode: .live)
    }

    private enum InputImage {
        case cgImage(CGImage)
        case pixelBuffer(CVPixelBuffer)
    }

    /// User setting (shared with the Settings toggle): read text aloud while exploring.
    static let readTextKey = "vision.readText"
    private var readTextEnabled: Bool {
        UserDefaults.standard.object(forKey: Self.readTextKey) as? Bool ?? true
    }

    private func performAnalysis(on input: InputImage, size: CGSize, mode: Mode) {
        guard !isAnalyzing else { return }
        isAnalyzing = true
        let modelURL = compiledModelURL
        let readText = readTextEnabled
        // CGImage / CVPixelBuffer aren't Sendable; we only read them on this
        // background queue, so it's safe to carry them across via a wrapper.
        let work = UncheckedSendable(input)

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            defer {
                // Reset directly on this background queue — isAnalyzing is a
                // private Bool only used inside performAnalysis (never published
                // to the UI), so no main-thread hop is needed and there is no
                // data-race risk. Avoids the Swift 6 "Sending self" warning.
                self?.isAnalyzing = false
            }
            let input = work.value
            func makeHandler() -> VNImageRequestHandler {
                switch input {
                case .cgImage(let img):     return VNImageRequestHandler(cgImage: img)
                case .pixelBuffer(let buf): return VNImageRequestHandler(cvPixelBuffer: buf)
                }
            }

            // 1. Detection pass: YOLO + animals + saliency in one go.
            let animalRequest = VNRecognizeAnimalsRequest()
            let saliencyRequest = VNGenerateObjectnessBasedSaliencyImageRequest()
            var requests: [VNRequest] = [animalRequest, saliencyRequest]

            var detectorRequest: VNCoreMLRequest?
            if let url = modelURL,
               let model = try? MLModel(contentsOf: url),
               let vnModel = try? VNCoreMLModel(for: model) {
                let req = VNCoreMLRequest(model: vnModel)
                req.imageCropAndScaleOption = .scaleFill
                detectorRequest = req
                requests.append(req)
            }
            try? makeHandler().perform(requests)

            var candidates: [DetectedObject] = []

            func addObservations(_ results: [VNRecognizedObjectObservation]?, minConfidence: Float) {
                guard let results else { return }
                for obs in results where obs.confidence > minConfidence {
                    candidates.append(DetectedObject(boundingBox: obs.boundingBox,
                                                     confidence: obs.confidence,
                                                     topLabel: obs.labels.first?.identifier))
                }
            }
            addObservations(detectorRequest?.results as? [VNRecognizedObjectObservation], minConfidence: 0.3)
            addObservations(animalRequest.results, minConfidence: 0.3)

            // Saliency regions the detector didn't already cover.
            if let saliency = saliencyRequest.results?.first as? VNSaliencyImageObservation,
               let salientObjects = saliency.salientObjects {
                let limit = mode == .live ? 4 : 6
                for obj in salientObjects.prefix(limit) {
                    let covered = candidates.contains { $0.boundingBox.intersects(obj.boundingBox) }
                    if !covered {
                        candidates.append(DetectedObject(boundingBox: obj.boundingBox,
                                                         confidence: max(0.3, obj.confidence),
                                                         topLabel: nil))
                    }
                }
            }

            // 2. Refinement pass: fine-grained classification per region.
            let refined = Self.refineLabels(for: candidates, makeHandler: makeHandler)

            // 3. Text recognition. Accurate (with language correction) for still
            //    images; fast for live frames so the feed stays responsive.
            var detections = refined
            if readText {
                let level: VNRequestTextRecognitionLevel = mode == .live ? .fast : .accurate
                detections.append(contentsOf: Self.recognizeText(makeHandler: makeHandler, level: level))
            }

            let unique = Self.deduplicate(detections)
            // Use Task/@MainActor instead of DispatchQueue.main.async — this is
            // the Swift 6-safe way to hop to the main actor without triggering
            // a "Sending self risks causing data races" diagnostic.
            Task { @MainActor [weak self] in
                self?.observations = unique
                self?.lastLabel = ""
            }
        }
    }

    /// Runs Vision's image classifier constrained to each candidate's region and
    /// assigns a label to saliency-only candidates (those with no label yet).
    /// Candidates that already carry a label from the specialist detectors
    /// (VNRecognizeAnimalsRequest → "Cat"/"Dog", YOLO → "car"/"person"/…)
    /// are returned as-is: VNClassifyImageRequest is a general-purpose whole-image
    /// classifier whose broad results ("animal", "mammal") would override the more
    /// accurate specialist labels if we let it run on every candidate.
    private static func refineLabels(for candidates: [DetectedObject],
                                     makeHandler: () -> VNImageRequestHandler) -> [DetectedObject] {
        return candidates.map { candidate in
            // Already labelled by a specialist detector — keep it verbatim.
            if let existing = candidate.topLabel {
                return DetectedObject(boundingBox: candidate.boundingBox,
                                      confidence: candidate.confidence,
                                      topLabel: clean(existing))
            }

            // Saliency-only candidate: no label yet. Run the general classifier
            // on a fresh handler so regionOfInterest applies correctly.
            let req = VNClassifyImageRequest()
            req.regionOfInterest = candidate.boundingBox
            try? makeHandler().perform([req])

            // Results ARE sorted by confidence descending per Apple docs,
            // but max() is used defensively.
            let results = req.results ?? []
            let best = results.max(by: { $0.confidence < $1.confidence })
            let label = best.map { clean($0.identifier) } ?? "object"

            return DetectedObject(boundingBox: candidate.boundingBox,
                                  confidence: candidate.confidence,
                                  topLabel: label)
        }
    }


    private static func recognizeText(makeHandler: () -> VNImageRequestHandler,
                                      level: VNRequestTextRecognitionLevel) -> [DetectedObject] {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = level
        request.usesLanguageCorrection = level == .accurate
        try? makeHandler().perform([request])

        guard let results = request.results else { return [] }
        let limit = level == .fast ? 6 : 12
        return results.prefix(limit).compactMap { obs in
            guard let text = obs.topCandidates(1).first?.string,
                  !text.trimmingCharacters(in: .whitespaces).isEmpty else { return nil }
            return DetectedObject(boundingBox: obs.boundingBox, confidence: obs.confidence, topLabel: text)
        }
    }

    private static func deduplicate(_ detections: [DetectedObject]) -> [DetectedObject] {
        var kept: [DetectedObject] = []
        for obj in detections.sorted(by: { $0.confidence > $1.confidence }) {
            let duplicate = kept.contains { existing in
                let inter = existing.boundingBox.intersection(obj.boundingBox)
                let areaInter = inter.width * inter.height
                let areaA = existing.boundingBox.width * existing.boundingBox.height
                let areaB = obj.boundingBox.width * obj.boundingBox.height
                return areaInter > (min(areaA, areaB) * 0.4)
            }
            if !duplicate { kept.append(obj) }
        }
        return kept
    }

    /// Tidies a raw classifier identifier (e.g. "golden_retriever, retriever")
    /// into something readable and speakable ("golden retriever").
    private static func clean(_ raw: String) -> String {
        let firstTerm = String(raw.split(separator: ",").first ?? Substring(raw))
        return firstTerm.replacingOccurrences(of: "_", with: " ")
            .trimmingCharacters(in: .whitespaces)
    }

    /// Returns how strongly the point sits "on" an object (0...1) and its label.
    /// Stronger means nearer the center of a detected object.
    func hitTest(at point: CGPoint, size: CGSize) -> (intensity: Float, label: String?) {
        guard size.width > 0, size.height > 0 else { return (0, nil) }

        let normPoint = CGPoint(x: point.x / size.width, y: 1.0 - (point.y / size.height))
        let match = observations
            .filter { $0.boundingBox.contains(normPoint) }
            .min { ($0.boundingBox.width * $0.boundingBox.height) < ($1.boundingBox.width * $1.boundingBox.height) }

        guard let match else {
            lastLabel = ""
            return (0.05, nil)
        }

        let dx = normPoint.x - match.boundingBox.midX
        let dy = normPoint.y - match.boundingBox.midY
        let dist = sqrt(dx * dx + dy * dy)
        let radius = (match.boundingBox.width + match.boundingBox.height) / 4.0
        let normalizedDist = max(0, min(1, dist / radius))
        let intensity = Float(1.0 - (normalizedDist * 0.6))

        let label = match.topLabel ?? "object"
        if label != lastLabel {
            speak(label)
            lastLabel = label
        }
        return (intensity, label)
    }

    private func speak(_ text: String) {
        // hitTest() is always called from DragGesture (main thread), so we
        // are already on the main thread here — no dispatch needed.
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = 0.52
        utterance.pitchMultiplier = 1.1
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        speech.stopSpeaking(at: .immediate)
        speech.speak(utterance)
    }
}
