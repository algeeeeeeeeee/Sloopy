# Sloopy! — Capacitor iOS preparation

This project contains the Sloopy! PWA assets inside `www/` plus a Capacitor iOS wrapper configuration.

## Important

- This is a **source project**, not an already compiled IPA.
- iOS compilation requires a macOS/Xcode runner. Capacitor 8 requires Xcode 26.0+ and supports iOS 15+.
- A GitHub Actions workflow is included to build an **unsigned** IPA on a hosted macOS runner.
- An unsigned IPA is not normally installable on a standard iPhone. A normal install needs Apple-accepted signing/provisioning.
- No signing credentials or jailbreak-specific bypass instructions are included.

See `README-IPA.md` for the build workflow and limitations.
