import Foundation

struct GifticonScanResult: Sendable, Equatable {
    let sourceAssetIdentifier: String
    let text: String
    let barcodeValues: [String]
    let confidence: Double
}

struct ParsedGifticon: Sendable, Equatable {
    let brand: String
    let title: String
    let barcodeNumber: String?
    let expiryDate: Date?
    let confidence: Double
}
