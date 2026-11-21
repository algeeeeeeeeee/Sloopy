import Foundation

private struct IconAsset {
    let id: String
    let sourceFileName: String
    let alternateSetName: String
    let previewName: String
}

private let iconAssets = [
    IconAsset(id: "cctv", sourceFileName: "9ebf643bc259023155542695f3587be3.PNG", alternateSetName: "CCTVIcon", previewName: "SloopyIconPreview-CCTV"),
    IconAsset(id: "crystal", sourceFileName: "IMG_1659.PNG", alternateSetName: "CrystalIcon", previewName: "SloopyIconPreview-Crystal"),
    IconAsset(id: "eye", sourceFileName: "IMG_1745.PNG", alternateSetName: "EyeIcon", previewName: "SloopyIconPreview-Eye"),
    IconAsset(id: "cat", sourceFileName: "IMG_1835.PNG", alternateSetName: "CatIcon", previewName: "SloopyIconPreview-Cat"),
    IconAsset(id: "cube", sourceFileName: "IMG_1878.PNG", alternateSetName: "CubeIcon", previewName: "SloopyIconPreview-Cube")
]

private func writeContents(_ object: [String: Any], to url: URL) throws {
    let data = try JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys])
    try data.write(to: url, options: .atomic)
}

private func createAssetSet(at directory: URL, imageName: String, appIcon: Bool) throws {
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    let image: [String: Any] = appIcon
        ? ["filename": imageName, "idiom": "universal", "platform": "ios", "size": "1024x1024"]
        : ["filename": imageName, "idiom": "universal"]
    try writeContents(["images": [image], "info": ["author": "xcode", "version": 1]],
                      to: directory.appendingPathComponent("Contents.json"))
}

private func runSipsResize(from source: URL, to destination: URL) throws {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/sips")
    process.arguments = ["-s", "format", "png", "-z", "1024", "1024", source.path, "--out", destination.path]
    try process.run()
    process.waitUntilExit()
    guard process.terminationStatus == 0 else {
        throw NSError(domain: "SloopyIconGenerator", code: Int(process.terminationStatus),
                      userInfo: [NSLocalizedDescriptionKey: "sips could not prepare \(source.lastPathComponent) as a 1024x1024 iOS app icon."])
    }
}

let assetCatalog = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? "Native/Resources/Assets.xcassets", isDirectory: true)
let sourceDirectory = URL(fileURLWithPath: "Native/Resources/CustomAppIcons", isDirectory: true)
let selectedPrimaryID = ProcessInfo.processInfo.environment["SLOOPY_PRIMARY_ICON_ID"]?.lowercased() ?? "cctv"

guard let primaryAsset = iconAssets.first(where: { $0.id == selectedPrimaryID }) else {
    throw NSError(domain: "SloopyIconGenerator", code: 11,
                  userInfo: [NSLocalizedDescriptionKey: "Unknown SLOOPY_PRIMARY_ICON_ID '\(selectedPrimaryID)'. Choose: \(iconAssets.map(\.id).joined(separator: ", "))."])
}
try FileManager.default.createDirectory(at: assetCatalog, withIntermediateDirectories: true)

// The selected source becomes AppIcon, so TrollStore installs display it
// without requiring a live LaunchServices alternate-icon update.
let primarySource = sourceDirectory.appendingPathComponent(primaryAsset.sourceFileName)
guard FileManager.default.fileExists(atPath: primarySource.path) else {
    throw NSError(domain: "SloopyIconGenerator", code: 10,
                  userInfo: [NSLocalizedDescriptionKey: "Missing primary icon PNG: \(primarySource.path)"])
}
let primarySet = assetCatalog.appendingPathComponent("AppIcon.appiconset", isDirectory: true)
try createAssetSet(at: primarySet, imageName: "icon.png", appIcon: true)
try runSipsResize(from: primarySource, to: primarySet.appendingPathComponent("icon.png"))

// Keep all five as alternate sets for installation environments that support
// the official UIApplication.setAlternateIconName API.
for asset in iconAssets {
    let sourceURL = sourceDirectory.appendingPathComponent(asset.sourceFileName)
    guard FileManager.default.fileExists(atPath: sourceURL.path) else {
        throw NSError(domain: "SloopyIconGenerator", code: 10,
                      userInfo: [NSLocalizedDescriptionKey: "Missing original user PNG: \(sourceURL.path)"])
    }
    let alternateSet = assetCatalog.appendingPathComponent("\(asset.alternateSetName).appiconset", isDirectory: true)
    try createAssetSet(at: alternateSet, imageName: "icon.png", appIcon: true)
    try runSipsResize(from: sourceURL, to: alternateSet.appendingPathComponent("icon.png"))

    let previewSet = assetCatalog.appendingPathComponent("\(asset.previewName).imageset", isDirectory: true)
    try createAssetSet(at: previewSet, imageName: "icon.png", appIcon: false)
    try FileManager.default.copyItem(at: sourceURL, to: previewSet.appendingPathComponent("icon.png"))
}

let configurationDirectory = URL(fileURLWithPath: "Native/Sources/App", isDirectory: true)
try FileManager.default.createDirectory(at: configurationDirectory, withIntermediateDirectories: true)
let configurationSource = """
import Foundation

enum SloopyBuildConfiguration {
    static let primaryAppIconID = "\(primaryAsset.id)"
}
"""
try configurationSource.write(to: configurationDirectory.appendingPathComponent("SloopyBuildConfiguration.swift"),
                              atomically: true, encoding: .utf8)
print("Prepared primary icon '\(primaryAsset.id)' and all five alternates. Original PNGs remain unchanged.")
