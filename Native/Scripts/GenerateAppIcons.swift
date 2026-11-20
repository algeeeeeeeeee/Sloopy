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

    try writeContents(
        [
            "images": [image],
            "info": ["author": "xcode", "version": 1]
        ],
        to: directory.appendingPathComponent("Contents.json")
    )
}

private func runSipsResize(from source: URL, to destination: URL) throws {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/sips")
    process.arguments = [
        "-s", "format", "png",
        "-z", "1024", "1024",
        source.path,
        "--out", destination.path
    ]
    try process.run()
    process.waitUntilExit()

    guard process.terminationStatus == 0 else {
        throw NSError(
            domain: "SloopyIconGenerator",
            code: Int(process.terminationStatus),
            userInfo: [
                NSLocalizedDescriptionKey:
                    "sips could not prepare \(source.lastPathComponent) as a 1024x1024 iOS app icon."
            ]
        )
    }
}

let assetCatalog = URL(
    fileURLWithPath: CommandLine.arguments.dropFirst().first
        ?? "Native/Resources/Assets.xcassets",
    isDirectory: true
)
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
            code: 10,
            userInfo: [
                NSLocalizedDescriptionKey:
                    "Missing original user PNG: \(sourceURL.path)"
            ]
        )
    }

    let appIconSet = assetCatalog.appendingPathComponent(
        "\(asset.setName).appiconset",
        isDirectory: true
    )
    try createAssetSet(
        at: appIconSet,
        imageName: "icon.png",
        appIcon: true
    )

    // Keep the uploaded PNG itself as the source. Only the build copy is
    // resampled to the 1024px size expected by a modern iOS app icon catalog.
    try runSipsResize(
        from: sourceURL,
        to: appIconSet.appendingPathComponent("icon.png")
    )

    let previewSet = assetCatalog.appendingPathComponent(
        "\(asset.previewName).imageset",
        isDirectory: true
    )
    try createAssetSet(
        at: previewSet,
        imageName: "icon.png",
        appIcon: false
    )

    // Settings previews use a byte-for-byte copy of the user's original PNG.
    try FileManager.default.copyItem(
        at: sourceURL,
        to: previewSet.appendingPathComponent("icon.png")
    )
}

print("Prepared 5 app icons from the user's original PNG files. Originals are unchanged.")
