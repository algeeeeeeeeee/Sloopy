import AppKit
import Foundation

private struct IconAsset {
    let sourceFileName: String
    let setName: String
    let previewName: String
}

private let iconAssets = [
    IconAsset(
        sourceFileName: "9ebf643bc259023155542695f3587be3.PNG",
        setName: "AppIcon",
        previewName: "SloopyIconPreview-CCTV"
    ),
    IconAsset(
        sourceFileName: "IMG_1659.PNG",
        setName: "AppIcon-Crystal",
        previewName: "SloopyIconPreview-Crystal"
    ),
    IconAsset(
        sourceFileName: "IMG_1745.PNG",
        setName: "AppIcon-Eye",
        previewName: "SloopyIconPreview-Eye"
    ),
    IconAsset(
        sourceFileName: "IMG_1835.PNG",
        setName: "AppIcon-Cat",
        previewName: "SloopyIconPreview-Cat"
    ),
    IconAsset(
        sourceFileName: "IMG_1878.PNG",
        setName: "AppIcon-Cube",
        previewName: "SloopyIconPreview-Cube"
    )
]

private func makeOpaque1024PNG(from sourceURL: URL) throws -> Data {
    guard let source = NSImage(contentsOf: sourceURL) else {
        throw NSError(
            domain: "SloopyIconGenerator",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Cannot open source icon at \(sourceURL.path)"]
        )
    }

    let side = 1024
    let bytesPerRow = side * 3
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: side,
        pixelsHigh: side,
        bitsPerSample: 8,
        samplesPerPixel: 3,
        hasAlpha: false,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: bytesPerRow,
        bitsPerPixel: 24
    ) else {
        throw NSError(
            domain: "SloopyIconGenerator",
            code: 2,
            userInfo: [NSLocalizedDescriptionKey: "Cannot create 1024x1024 icon canvas"]
        )
    }

    NSGraphicsContext.saveGraphicsState()
    guard let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
        NSGraphicsContext.restoreGraphicsState()
        throw NSError(
            domain: "SloopyIconGenerator",
            code: 3,
            userInfo: [NSLocalizedDescriptionKey: "Cannot create graphics context"]
        )
    }

    NSGraphicsContext.current = context
    context.imageInterpolation = .high

    let rect = NSRect(x: 0, y: 0, width: side, height: side)
    NSColor.white.setFill()
    rect.fill()

    source.draw(
        in: rect,
        from: NSRect(origin: .zero, size: source.size),
        operation: .sourceOver,
        fraction: 1
    )
    context.flushGraphics()
    NSGraphicsContext.restoreGraphicsState()

    guard let png = bitmap.representation(using: .png, properties: [:]) else {
        throw NSError(
            domain: "SloopyIconGenerator",
            code: 4,
            userInfo: [NSLocalizedDescriptionKey: "Cannot encode icon as PNG"]
        )
    }
    return png
}

private func writeContents(_ object: [String: Any], to url: URL) throws {
    let data = try JSONSerialization.data(
        withJSONObject: object,
        options: [.prettyPrinted, .sortedKeys]
    )
    try data.write(to: url, options: .atomic)
}

private func createAssetSet(
    at directory: URL,
    imageName: String,
    appIcon: Bool
) throws {
    try FileManager.default.createDirectory(
        at: directory,
        withIntermediateDirectories: true
    )

    let image: [String: Any] = appIcon
        ? [
            "filename": imageName,
            "idiom": "universal",
            "platform": "ios",
            "size": "1024x1024"
          ]
        : [
            "filename": imageName,
            "idiom": "universal"
          ]

    let contents: [String: Any] = [
        "images": [image],
        "info": ["author": "xcode", "version": 1]
    ]
    try writeContents(contents, to: directory.appendingPathComponent("Contents.json"))
}

let assetCatalogPath = CommandLine.arguments.dropFirst().first
    ?? "Native/Resources/Assets.xcassets"
let assetCatalog = URL(fileURLWithPath: assetCatalogPath, isDirectory: true)
let sourceDirectory = URL(
    fileURLWithPath: "Native/Resources/CustomAppIcons",
    isDirectory: true
)

try FileManager.default.createDirectory(
    at: assetCatalog,
    withIntermediateDirectories: true
)

for asset in iconAssets {
    let sourceURL = sourceDirectory.appendingPathComponent(asset.sourceFileName)
    guard FileManager.default.fileExists(atPath: sourceURL.path) else {
        throw NSError(
            domain: "SloopyIconGenerator",
            code: 5,
            userInfo: [NSLocalizedDescriptionKey: "Missing user icon: \(sourceURL.path)"]
        )
    }

    let png = try makeOpaque1024PNG(from: sourceURL)

    let appIconSet = assetCatalog.appendingPathComponent(
        "\(asset.setName).appiconset",
        isDirectory: true
    )
    try createAssetSet(at: appIconSet, imageName: "icon.png", appIcon: true)
    try png.write(
        to: appIconSet.appendingPathComponent("icon.png"),
        options: .atomic
    )

    let previewSet = assetCatalog.appendingPathComponent(
        "\(asset.previewName).imageset",
        isDirectory: true
    )
    try createAssetSet(at: previewSet, imageName: "icon.png", appIcon: false)
    try png.write(
        to: previewSet.appendingPathComponent("icon.png"),
        options: .atomic
    )
}

print("Generated five 1024x1024 app icons from Native/Resources/CustomAppIcons.")
