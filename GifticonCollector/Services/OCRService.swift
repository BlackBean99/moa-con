import Foundation
import Vision

struct OCRService: Sendable {
    /// Runs the expensive Korean OCR pass. Call only after barcode pre-filtering.
    func recognizeText(from image: CGImage) async throws -> String {
        let request = VNRecognizeTextRequest()
        request.recognitionLanguages = ["ko-KR"]
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        try VNImageRequestHandler(cgImage: image).perform([request])
        return request.results?.compactMap { $0.topCandidates(1).first?.string }
            .joined(separator: "\n") ?? ""
    }

    /// Cheap pre-filter used before OCR. It intentionally does not run text recognition.
    func detectBarcodes(from image: CGImage) async throws -> [String] {
        let request = VNDetectBarcodesRequest()
        request.symbologies = [.ean13, .ean8, .code128, .qr, .dataMatrix, .pdf417]
        try VNImageRequestHandler(cgImage: image).perform([request])
        return request.results?.compactMap(\.payloadStringValue) ?? []
    }

    func recognize(from image: CGImage) async throws -> (text: String, barcodeValues: [String]) {
        try await withThrowingTaskGroup(of: OCRPart.self) { group in
            group.addTask { .text(try await recognizeText(from: image)) }
            group.addTask { .barcodes(try await detectBarcodes(from: image)) }

            var text = ""
            var barcodes: [String] = []
            for try await part in group {
                switch part {
                case let .text(value): text = value
                case let .barcodes(values): barcodes = values
                }
            }
            return (text, barcodes)
        }
    }

}

private enum OCRPart: Sendable {
    case text(String)
    case barcodes([String])
}
