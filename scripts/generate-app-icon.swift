import AppKit

// Reproducible vector artwork: two collected tickets and the Moacon M.
let size = NSSize(width: 1024, height: 1024)
let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 1024, pixelsHigh: 1024, bitsPerSample: 8, samplesPerPixel: 3, hasAlpha: false, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
let cream = NSColor(srgbRed: 0.97, green: 0.95, blue: 0.91, alpha: 1)
let coral = NSColor(srgbRed: 0.96, green: 0.48, blue: 0.37, alpha: 1)
let ink = NSColor(srgbRed: 0.15, green: 0.14, blue: 0.13, alpha: 1)
cream.setFill()
NSBezierPath(rect: NSRect(origin: .zero, size: size)).fill()
NSGraphicsContext.saveGraphicsState()
let rotate = AffineTransform(translationByX: 512, byY: 512)
var transform = rotate
transform.rotate(byDegrees: 12)
transform.translate(x: -512, y: -512)
(transform as NSAffineTransform).concat()
ink.setFill()
NSBezierPath(roundedRect: NSRect(x: 205, y: 295, width: 620, height: 460), xRadius: 70, yRadius: 70).fill()
NSGraphicsContext.restoreGraphicsState()
coral.setFill()
NSBezierPath(roundedRect: NSRect(x: 180, y: 255, width: 664, height: 464), xRadius: 70, yRadius: 70).fill()
cream.setFill()
for x in [135.0, 799.0] {
    NSBezierPath(ovalIn: NSRect(x: x, y: 445, width: 90, height: 90)).fill()
}
let monogram = NSBezierPath()
monogram.move(to: NSPoint(x: 355, y: 370))
monogram.line(to: NSPoint(x: 355, y: 608))
monogram.line(to: NSPoint(x: 512, y: 468))
monogram.line(to: NSPoint(x: 669, y: 608))
monogram.line(to: NSPoint(x: 669, y: 370))
monogram.lineWidth = 48
monogram.lineCapStyle = .round
monogram.lineJoinStyle = .round
cream.setStroke()
monogram.stroke()
NSGraphicsContext.restoreGraphicsState()
let data = bitmap.representation(using: .png, properties: [:])!
try data.write(to: URL(fileURLWithPath: "GifticonCollector/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png"))
