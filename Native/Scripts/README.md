# Native app icon generation

`GenerateAppIcons.swift` creates the default Sloopy app icon, four alternate iOS app icons, and matching Settings previews in `Resources/Assets.xcassets`.

The native GitHub Actions workflow runs this script before XcodeGen so the asset catalog exists before the Xcode project is generated.
