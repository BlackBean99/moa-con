import Foundation
import Vision
import CoreML

struct OCRService: Sendable {
    /// Runs the expensive Korean OCR pass. Call only after barcode pre-filtering.
    func recognizeText(from image: CGImage) async throws -> String {
        let request = VNRecognizeTextRequest()
        request.recognitionLanguages = ["ko-KR"]
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        try configureSimulatorCompute(request)
        try VNImageRequestHandler(cgImage: image).perform([request])
        return request.results?.compactMap { $0.topCandidates(1).first?.string }
            .joined(separator: "\n") ?? ""
    }

    private func configureSimulatorCompute(_ request: VNRequest) throws {
        #if targetEnvironment(simulator)
        for (stage, devices) in try request.supportedComputeStageDevices {
            if let cpu = devices.first(where: { if case .cpu = $0 { return true }; return false }) {
                request.setComputeDevice(cpu, for: stage)
            }
        }
        #endif
    }

    /// Cheap pre-filter used before OCR. It intentionally does not run text recognition.
    func detectBarcodes(from image: CGImage) async throws -> [String] {
        let request = VNDetectBarcodesRequest()
        #if targetEnvironment(simulator)
        // iOS 26.2 Simulator CPU detection returns no Code128 observations with revisions 3/4.
        // Revision 1 is verified by the rendered-coupon regression; devices keep the current revision.
        request.revision = 1
        #endif
        request.symbologies = [.ean13, .ean8, .code128, .qr, .dataMatrix, .pdf417]
        try configureSimulatorCompute(request)
        try VNImageRequestHandler(cgImage: image).perform([request])
        return request.results?.compactMap(\.payloadStringValue) ?? []
    }

    func recognize(from image: CGImage) async throws -> (text: String, barcodeValues: [String]) {
        // Match the full-library pipeline: avoid OCR for images without a usable barcode.
        let barcodes = try await detectBarcodes(from: image)
        guard !barcodes.isEmpty else { return ("", []) }
        let text = try await recognizeText(from: image)
        return (text, barcodes)
    }
}
