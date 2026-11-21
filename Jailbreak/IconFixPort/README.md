# Sloopy IconFix Port — write-side component

This rootless Dopamine/ElleKit package follows the write-side design of [IconFix](https://github.com/estrogencat/dbiconfix).

## Why this package is write-side only

On the target iPhone XR, Sloopy's alternate icons display correctly when installed through ordinary sideloading. The failing path on the TrollStore Lite install is the LaunchServices request in `_LSDIconClient`. This port therefore focuses on the LaunchServices write path and does not replace SpringBoard's icon artwork renderer.

## Behaviour

- Hooks `_LSDIconClient.setAlternateIconName:forIdentifier:iconsDictionary:reply:` inside `lsd`.
- Identifies the XPC caller PID, resolves its running executable with `proc_pidpath`, and reads that caller's own `.app/Info.plist`.
- The alternate-icon request is forwarded only when the caller bundle's own `CFBundleIdentifier` exactly matches the requested identifier.
- Uses the `CFBundleIcons` dictionary read from that caller's disk bundle when available.
- If ownership cannot be established, a private class/selector is unavailable, the runtime signature differs from expectation, or an exception occurs, the hook falls back to Apple's original implementation.

A small SpringBoard-side loader companion checks the loaded dylib marker on respring and requests a launchd respawn of `lsd` if the write-side tweak has not been loaded. It does not hook or replace icon rendering.

## Compatibility

Target device: iPhone XR, iOS 18.2.1, Dopamine 3.0.13.

The user's error log confirms the `_LSDIconClient.setAlternateIconName:forIdentifier:iconsDictionary:reply:` selector is reached. However, the private `LSAltIconManager` implementation for iOS 18.2.1 has not been inspected on this exact build. The package includes a runtime Objective-C method-signature guard; that guard falls back to the original system method if the observed signature differs.

CI validates compilation, rootless package layout, and arm64e output only. It does not prove runtime compatibility on a physical iPhone.

## Build

The workflow `.github/workflows/build-iconfix-port.yml` builds this Debian package with Theos and a pinned LLVM 19 toolchain.
