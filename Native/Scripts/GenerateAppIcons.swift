import AppKit
import Foundation

private struct IconSpec {
    let setName: String
    let previewName: String
    let startHex: UInt32
    let endHex: UInt32
    let markHex: UInt32
    let motif: String
}

private let iconSpecs = [
    IconSpec(setName: "AppIcon", previewName: "SloopyIconPreview-Original",
             startHex: 0xF1F3E9, endHex: 0xC9DDD2, markHex: 0x31594F, motif: "leaf"),
    IconSpec(setName: "AppIcon-Ocean", previewName: "SloopyIconPreview-Ocean",
             startHex: 0x153B59, endHex: 0x4D91A7, markHex: 0xF3FAF8, motif: "waves"),
    IconSpec(setName: "AppIcon-Sage", previewName: "SloopyIconPreview-Sage",
             startHex: 0x58765D, endHex: 0xB5C7A8, markHex: 0xF7F3E7, motif: "leaf"),
    IconSpec(setName: "AppIcon-Lavender", previewName: "SloopyIconPreview-Lavender",
             startHex: 0x554C80, endHex: 0xB4A5D3, markHex: 0xFBF8FF, motif: "sparkle"),
    IconSpec(setName: "AppIcon-Peach", previewName: "SloopyIconPreview-Peach",
             startHex: 0xB85E4E, endHex: 0xF1BD91, markHex: 0xFFF2DC, motif: "sun")
]

private func color(_ hex: UInt32, alpha: CGFloat = 1) -> NSColor {
    NSColor(
        calibratedRed: CGFloat((hex >> 16) & 0xFF) / 255,
        green: CGFloat((hex >> 8) & 0xFF) / 255,
        blue: CGFloat(hex & 0xFF) / 255,
        alpha: alpha
    )
}

private func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
    CGPoint(x: x, y: y)
}

private func drawLeaf(from start: CGPoint, to end: CGPoint, width: CGFloat, fill: NSColor) {
    let dx = end.x - start.x
    let dy = end.y - start.y
    let length = max(1, hypot(dx, dy))
    let ux = dx / length
    let uy = dy / length
    let nx = -uy * width
    let ny = ux * width

    let c1 = point(start.x + dx * 0.30 + nx, start.y + dy * 0.30 + ny)
    let c2 = point(start.x + dx * 0.72 + nx, start.y + dy * 0.72 + ny)
    let c3 = point(start.x + dx * 0.72 - nx, start.y + dy * 0.72 - ny)
    let c4 = point(start.x + dx * 0.30 - nx, start.y + dy * 0.30 - ny)

    let path = NSBezierPath()
    path.move(to: start)
    path.curve(to: end, controlPoint1: c1, controlPoint2: c2)
    path.curve(to: start, controlPoint1: c3, controlPoint2: c4)
    path.close()
    fill.setFill()
    path.fill()
}

private func drawSprout(mark: NSColor) {
    drawLeaf(from: point(510, 430), to: point(310, 635), width: 78, fill: mark)
    drawLeaf(from: point(518, 535), to: point(724, 735), width: 82, fill: mark)
    drawLeaf(from: point(510, 625), to: point(500, 850), width: 74, fill: mark)

    let stem = NSBezierPath()
    stem.move(to: point(512, 235))
    stem.curve(to: point(510, 690),
               controlPoint1: point(490, 365),
               controlPoint2: point(535, 555))
    stem.lineWidth = 25
    stem.lineCapStyle = .round
    mark.setStroke()
    stem.stroke()
}

private func drawWaves(mark: NSColor) {
    for y in [390.0, 515.0, 640.0] {
        let wave = NSBezierPath()
        wave.move(to: point(220, y))
        wave.curve(to: point(804, y),
                   controlPoint1: point(370, y + 145),
                   controlPoint2: point(650, y - 145))
        wave.lineWidth = 34
        wave.lineCapStyle = .round
        mark.setStroke()
        wave.stroke()
    }
}

private func starPath(center: CGPoint, outer: CGFloat, inner: CGFloat, points: Int = 4) -> NSBezierPath {
    let path = NSBezierPath()
    for index in 0..<(points * 2) {
        let radius = index.isMultiple(of: 2) ? outer : inner
        let angle = CGFloat(index) * .pi / CGFloat(points) - .pi / 2
        let position = point(center.x + cos(angle) * radius, center.y + sin(angle) * radius)
        if index == 0 {
            path.move(to: position)
        } else {
            path.line(to: position)
        }
    }
    path.close()
    return path
}

private func drawSparkles(mark: NSColor) {
    mark.setFill()
    starPath(center: point(512, 520), outer: 230, inner: 78).fill()
    starPath(center: point(770, 760), outer: 72, inner: 25).fill()
    starPath(center: point(280, 300), outer: 54, inner: 19).fill()

    let dot = NSBezierPath(ovalIn: NSRect(x: 730, y: 300, width: 38, height: 38))
    dot.fill()
}

private func drawSun(mark: NSColor) {
    let center = point(512, 535)
    let radius: CGFloat = 150

    for index in 0..<8 {
        let angle = CGFloat(index) * .pi / 4
        let inner = radius + 58
        let outer = radius + 112
        let ray = NSBezierPath()
        ray.move(to: point(center.x + cos(angle) * inner, center.y + sin(angle) * inner))
        ray.line(to: point(center.x + cos(angle) * outer, center.y + sin(angle) * outer))
        ray.lineWidth = 28
        ray.lineCapStyle = .round
        mark.setStroke()
        ray.stroke()
    }

    mark.setFill()
    NSBezierPath(ovalIn: NSRect(x: center.x - radius, y: center.y - radius,
                                width: radius * 2, height: radius * 2)).fill()
}

private func drawIcon(_ spec: IconSpec) -> Data {
    let side = 1024
    let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: side,
        pixelsHigh: side,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: false,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!

    NSGraphicsContext.saveGraphicsState()
    let graphics = NSGraphicsContext(bitmapImageRep: bitmap)!
    NSGraphicsContext.current = graphics
    graphics.imageInterpolation = .high
    graphics.shouldAntialias = true

    let rect = NSRect(x: 0, y: 0, width: side, height: side)
    let start = color(spec.startHex)
    let end = color(spec.endHex)
    let mark = color(spec.markHex)

    if let gradient = NSGradient(starting: start, ending: end) {
        gradient.draw(in: rect, angle: 45)
    } else {
        start.setFill()
        rect.fill()
    }

    color(spec.markHex, alpha: 0.08).setFill()
    NSBezierPath(ovalIn: NSRect(x: 700, y: 700, width: 460, height: 460)).fill()
    NSBezierPath(ovalIn: NSRect(x: -190, y: -160, width: 470, height: 470)).fill()

    switch spec.motif {
    case "waves":
        drawWaves(mark: mark)
    case "sparkle":
        drawSparkles(mark: mark)
    case "sun":
        drawSun(mark: mark)
    default:
        drawSprout(mark: mark)
    }

    NSGraphicsContext.restoreGraphicsState()
    return bitmap.representation(using: .png, properties: [:])!
}

private func writeJSON(_ object: [String: Any], to url: URL) throws {
    let data = try JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys])
    try data.write(to: url, options: .atomic)
}

private func makeAssetSet(at url: URL, imageName: String, appIcon: Bool) throws {
    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    let contents: [String: Any]
    if appIcon {
        contents = [
            "images": [[
                "filename": imageName,
                "idiom": "universal",
                "platform": "ios",
                "size": "1024x1024"
            ]],
            "info": ["author": "xcode", "version": 1]
        ]
    } else {
        contents = [
            "images": [[
                "filename": imageName,
                "idiom": "universal"
            ]],
            "info": ["author": "xcode", "version": 1]
        ]
    }
    try writeJSON(contents, to: url.appendingPathComponent("Contents.json"))
}

let outputPath = CommandLine.arguments.dropFirst().first ?? "Native/Resources/Assets.xcassets"
let catalogURL = URL(fileURLWithPath: outputPath, isDirectory: true)
try FileManager.default.createDirectory(at: catalogURL, withIntermediateDirectories: true)

for spec in iconSpecs {
    let png = drawIcon(spec)
    let iconSetURL = catalogURL.appendingPathComponent("\(spec.setName).appiconset", isDirectory: true)
    try makeAssetSet(at: iconSetURL, imageName: "icon.png", appIcon: true)
    try png.write(to: iconSetURL.appendingPathComponent("icon.png"), options: .atomic)

    let previewSetURL = catalogURL.appendingPathComponent("\(spec.previewName).imageset", isDirectory: true)
    try makeAssetSet(at: previewSetURL, imageName: "icon.png", appIcon: false)
    try png.write(to: previewSetURL.appendingPathComponent("icon.png"), options: .atomic)
}

print("Generated \(iconSpecs.count) Sloopy app icons and previews in \(catalogURL.path)")
