import Foundation
import CoreGraphics
import CoreText
import ImageIO
import UniformTypeIdentifiers
import CoreImage

// Deliberately invalid coupon identifiers. These are review inputs, never store screenshots.
let output = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "docs/release/fixtures")
try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
let renderer = CIContext()
for (name, codes) in [("single-code", ["MOACON-TEST-0001"]), ("multiple-codes", ["MOACON-TEST-0002", "MOACON-TEST-0003"]), ("no-code", [])] {
    let context = CGContext(data: nil, width: 1000, height: 1400, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    context.setFillColor(CGColor(gray: 1, alpha: 1)); context.fill(CGRect(x: 0, y: 0, width: 1000, height: 1400))
    func label(_ text: String, _ y: CGFloat, size: CGFloat = 40) {
        let attributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key(kCTFontAttributeName as String): CTFontCreateWithName("AppleSDGothicNeo-Regular" as CFString, size, nil), NSAttributedString.Key(kCTForegroundColorAttributeName as String): CGColor(gray: 0, alpha: 1)]
        let line = CTLineCreateWithAttributedString(NSAttributedString(string: text, attributes: attributes))
        context.textPosition = CGPoint(x: 80, y: y)
        CTLineDraw(line, context)
    }
    label("테스트 쿠폰 · 사용 불가", 1240, size: 56)
    label("교환처 모아카페", 1120)
    label("아메리카노 교환권", 1020)
    label("상품 가격 5,000원 · 할인 금액 500원", 920)
    label("유효기간 2030.12.31", 820)
    for (index, code) in codes.enumerated() {
        let filter = CIFilter(name: "CICode128BarcodeGenerator")!
        filter.setValue(code.data(using: .ascii), forKey: "inputMessage")
        filter.setValue(10, forKey: "inputQuietSpace")
        let image = filter.outputImage!
        let cg = renderer.createCGImage(image, from: image.extent)!
        context.interpolationQuality = .none
        context.draw(cg, in: CGRect(x: 80, y: 540 - index * 240, width: 840, height: 150))
        label(code, CGFloat(480 - index * 240), size: 30)
    }
    if codes.isEmpty { label("바코드 인식 실패 → 직접 등록 시험용", 580, size: 36) }
    label("매장에서 사용할 수 없는 심사용 합성 이미지입니다.", 100, size: 28)
    let destination = CGImageDestinationCreateWithURL(output.appendingPathComponent(name + ".png") as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(destination, context.makeImage()!, nil)
    guard CGImageDestinationFinalize(destination) else { fatalError("Cannot write fixture") }
}
