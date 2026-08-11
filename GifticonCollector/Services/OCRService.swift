import Foundation
import Vision

struct OCRService: Sendable {
    func recognize(from image: CGImage) async throws -> (text: String, barcodeValues: [String]) {
        try await withThrowingTaskGroup(of: OCRPart.self) { group in
            group.addTask { try await recognizeText(from: image) }
            group.addTask { try await detectBarcodes(from: image) }

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

    private func recognizeText(from image: CGImage) async throws -> OCRPart {
        let request = VNRecognizeTextRequest()
        request.recognitionLanguages = ["ko-KR"]
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        try VNImageRequestHandler(cgImage: image).perform([request])
        let lines = request.results?.compactMap { $0.topCandidates(1).first?.string } ?? []
        return .text(lines.joined(separator: "\n"))
    }

    private func detectBarcodes(from image: CGImage) async throws -> OCRPart {
        let request = VNDetectBarcodesRequest()
        request.symbologies = [.ean13, .ean8, .code128, .qr, .dataMatrix, .pdf417]
        try VNImageRequestHandler(cgImage: image).perform([request])
        let values = request.results?.compactMap(\ .payloadStringValue) ?? []
        return .barcodes(values)
    }
}

private enum OCRPart: Sendable {
    case text(String)
    case barcodes([String])
}
