# Sloopy! iOS wrapper (Capacitor)

This folder wraps the existing Sloopy! static web app in a native iOS shell using Capacitor 8.6.2. It preserves the existing `www/` app and its localStorage-based preferences.

## Requirements

- Node.js 22+
- For iOS compilation: macOS with Xcode 26.0+ (Capacitor 8 requirement)
- iOS deployment target: iOS 15+

## Generate the iOS project

```bash
npm install
npx cap add ios
npx cap sync ios
```

The generated `ios/` folder is intentionally not included in this source archive; Capacitor generates it on a macOS runner.

## Build an unsigned IPA with GitHub Actions

1. Create a **new, separate** GitHub repository for Sloopy (do not put this in the MWLT repository).
2. Upload the contents of this folder to that repository.
3. Open the repository's **Actions** tab.
4. Choose **Build Sloopy iOS (unsigned)** and run **Run workflow**.
5. When the workflow completes, download the `Sloopy-unsigned-IPA` artifact.

The workflow uses a GitHub-hosted macOS runner and Xcode. It builds an unsigned IPA. This is a build artifact, **not a signed, normally installable iOS distribution**.

## Signing and installation

A normal iOS installation requires an app signature and provisioning that Apple accepts. This project deliberately does not contain signing certificates, provisioning profiles, Apple account passwords, or jailbreak-specific signature-bypass steps. For a normal signed install, use Apple's supported signing/development process with an account and provisioning appropriate for the intended installation.

Do not share Apple Account passwords, signing certificates, or provisioning files in chat or in a public repository.

## App details

- Display name: Sloopy!
- Bundle identifier: `com.sloopy.daily`
- Web assets: `www/`
- Capacitor: 8.6.2

## Known limitations carried over from the PWA

- Weather, YouTube live streams, and remote app shortcuts need internet.
- Camera embedding depends on each YouTube channel's embed permission.
- Notes, profile, accent/theme, stamps, selected camera, and routine state are stored locally on this installation. No cross-device sync is configured.
- The app does not read notifications from other iPhone apps or block them.
