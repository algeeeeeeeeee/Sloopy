import Foundation

private func writeContents(_ object: [String: Any], to url: URL) throws {
    let data = try JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys])
    try data.write(to: url, options: .atomic)
}

private func createPrimaryIconSet(at directory: URL) throws {
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    let image: [String: Any] = [
        "filename": "icon.png",
        "idiom": "universal",
        "platform": "ios",
        "size": "1024x1024"
    ]
    try writeContents(
        ["images": [image], "info": ["author": "xcode", "version": 1]],
        to: directory.appendingPathComponent("Contents.json")
    )
}

private func resizeCrystalIcon(from source: URL, to destination: URL) throws {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/sips")
    process.arguments = [
        "-s", "format", "png",
        "-z", "1024", "1024",
        source.path, "--out", destination.path
    ]
    try process.run()
    process.waitUntilExit()

    guard process.terminationStatus == 0 else {
        throw NSError(
            domain: "SloopyIconGenerator",
            code: Int(process.terminationStatus),
            userInfo: [
                NSLocalizedDescriptionKey:
                    "Could not prepare IMG_1659.PNG as the Crystal primary app icon."
            ]
        )
    }
}

let assetCatalog = URL(
    fileURLWithPath: CommandLine.arguments.dropFirst().first ?? "Native/Resources/Assets.xcassets",
    isDirectory: true
)
let crystalSource = URL(
    fileURLWithPath: "Native/Resources/CustomAppIcons/IMG_1659.PNG"
)
let primarySet = assetCatalog.appendingPathComponent("AppIcon.appiconset", isDirectory: true)

guard FileManager.default.fileExists(atPath: crystalSource.path) else {
    throw NSError(
        domain: "SloopyIconGenerator",
        code: 10,
        userInfo: [NSLocalizedDescriptionKey: "Missing original Crystal icon: \(crystalSource.path)"]
    )
}

try FileManager.default.createDirectory(at: assetCatalog, withIntermediateDirectories: true)
try createPrimaryIconSet(at: primarySet)
try resizeCrystalIcon(
    from: crystalSource,
    to: primarySet.appendingPathComponent("icon.png")
)

let configurationDirectory = URL(
    fileURLWithPath: "Native/Sources/App",
    isDirectory: true
)
try FileManager.default.createDirectory(at: configurationDirectory, withIntermediateDirectories: true)

let configurationSource = """
import Foundation

enum SloopyBuildConfiguration {
    static let primaryAppIconID = "crystal"
}
"""
try configurationSource.write(
    to: configurationDirectory.appendingPathComponent("SloopyBuildConfiguration.swift"),
    atomically: true,
    encoding: .utf8
)

print("Prepared Crystal as Sloopy's only primary app icon. Original PNG remains unchanged.")
