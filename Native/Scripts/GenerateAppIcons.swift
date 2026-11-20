import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

private struct IconAsset {
    let sourceFileName: String
    let setName: String
    let previewName: String
}

private let iconAssets = [
    IconAsset(sourceFileName: "9ebf643bc259023155542695f3587be3.PNG", setName: "AppIcon", previewName: "SloopyIconPreview-CCTV"),
    IconAsset(sourceFileName: "IMG_1659.PNG", setName: "AppIcon-Crystal", previewName: "SloopyIconPreview-Crystal"),
    IconAsset(sourceFileName: "IMG_1745.PNG", setName: "AppIcon-Eye", previewName: "SloopyIconPreview-Eye"),
    IconAsset(sourceFileName: "IMG_1835.PNG", setName: "AppIcon-Cat", previewName: "SloopyIconPreview-Cat"),
    IconAsset(sourceFileName: "IMG_1878.PNG", setName: "AppIcon-Cube", previewName: "SloopyIconPreview-Cube")
]

private func makeOpaque1024PNG(from sourceURL: URL) throws -> Data {
    guard
        let source = CGImageSourceCreateWithURL(sourceURL as CFURL, nil),
        let sourceImage = CGImageSourceCreateImageAtIndex(source, 0, nil),
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
        let context = CGContext(
            data: nil,
            width: 1024,
            height: 1024,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        )
    else {
        throw NSError(
            domain: "SloopyIconGenerator",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Cannot decode source PNG or create 1024px canvas: \(sourceURL.lastPathComponent)"]
        )
    }

    let canvas = CGRect(x: 0, y: 0, width: 1024, height: 1024)
    context.setFillColor(CGColor(gray: 1, alpha: 1))
    context.fill(canvas)
    context.interpolationQuality = .high
    context.draw(sourceImage, in: canvas)

    guard let outputImage = context.makeImage() else {
        throw NSError(
            domain: "SloopyIconGenerator",
            code: 2,
            userInfo: [NSLocalizedDescriptionKey: "Cannot render icon: \(sourceURL.lastPathComponent)"]
        )
    }

    let output = NSMutableData()
    guard let destination = CGImageDestinationCreateWithData(
        output,
        UTType.png.identifier as CFString,
        1,
        nil
    ) else {
        throw NSError(
            domain: "SloopyIconGenerator",
            code: 3,
            userInfo: [NSLocalizedDescriptionKey: "Cannot create PNG output: \(sourceURL.lastPathComponent)"]
        )
    }

    CGImageDestinationAddImage(destination, outputImage, nil)
    guard CGImageDestinationFinalize(destination) else {
        throw NSError(
            domain: "SloopyIconGenerator",
            code: 4,
            userInfo: [NSLocalizedDescriptionKey: "Cannot encode PNG output: \(sourceURL.lastPathComponent)"]
        )
    }
    return output as Data
}

private func writeContents(_ object: [String: Any], to url: URL) throws {
    let data = try JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys])
    try data.write(to: url, options: .atomic)
}

private func createAssetSet(at directory: URL, imageName: String, appIcon: Bool) throws {
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

    let image: [String: Any] = appIcon
        ? ["filename": imageName, "idiom": "universal", "platform": "ios", "size": "1024x1024"]
        : ["filename": imageName, "idiom": "universal"]

    try writeContents(
        ["images": [image], "info": ["author": "xcode", "version": 1]],
        to: directory.appendingPathComponent("Contents.json")
    )
}

let assetCatalog = URL(
    fileURLWithPath: CommandLine.arguments.dropFirst().first ?? "Native/Resources/Assets.xcassets",
    isDirectory: true
)
let sourceDirectory = URL(fileURLWithPath: "Native/Resources/CustomAppIcons", isDirectory: true)

try FileManager.default.createDirectory(at: assetCatalog, withIntermediateDirectories: true)

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

    let appIconSet = assetCatalog.appendingPathComponent("\(asset.setName).appiconset", isDirectory: true)
    try createAssetSet(at: appIconSet, imageName: "icon.png", appIcon: true)
    try png.write(to: appIconSet.appendingPathComponent("icon.png"), options: .atomic)

    let previewSet = assetCatalog.appendingPathComponent("\(asset.previewName).imageset", isDirectory: true)
    try createAssetSet(at: previewSet, imageName: "icon.png", appIcon: false)
    try png.write(to: previewSet.appendingPathComponent("icon.png"), options: .atomic)
}

print("Generated five opaque 1024x1024 app icons and previews from the uploaded PNG files.")
