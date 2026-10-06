import AppKit
import ImageIO
import UniformTypeIdentifiers

// Export the shared, unmodified transparent brand artwork onto an opaque icon canvas.
let sourceURL = URL(fileURLWithPath: "GifticonCollector/Resources/Assets.xcassets/BrandMark.imageset/BrandMark.png")
guard let source = CGImageSourceCreateWithURL(sourceURL as CFURL, nil),
      let mark = CGImageSourceCreateImageAtIndex(source, 0, nil),
      let context = CGContext(data: nil, width: 1024, height: 1024, bitsPerComponent: 8,
          bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(),
          bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else {
    fatalError("Cannot load brand artwork or create icon canvas")
}
context.setFillColor(CGColor(red: 0.97, green: 0.95, blue: 0.91, alpha: 1))
context.fill(CGRect(x: 0, y: 0, width: 1024, height: 1024))
context.interpolationQuality = .high
context.draw(mark, in: CGRect(x: 48, y: 48, width: 928, height: 928))
let outputURL = URL(fileURLWithPath: "GifticonCollector/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png")
guard let output = context.makeImage(),
      let destination = CGImageDestinationCreateWithURL(outputURL as CFURL, UTType.png.identifier as CFString, 1, nil) else {
    fatalError("Cannot export icon")
}
CGImageDestinationAddImage(destination, output, nil)
guard CGImageDestinationFinalize(destination) else { fatalError("Cannot save icon") }
print("AppIcon: 1024 × 1024, opaque RGB; BrandMark: unchanged transparent source")
