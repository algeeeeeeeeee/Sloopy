
# Sloopy! — Capacitor iOS Project

This repository contains the Sloopy! PWA assets inside `www/` and its Capacitor 8.6.2 iOS wrapper configuration.

## Project Status

- This is a source project, not an already compiled IPA.
- Node.js 22 or newer is required.
- `npm ci` installs dependencies from the committed lockfile.
- `npm run check` validates project configuration and application assets.

## GitHub Actions

Two workflows are configured:

- **Sloopy CI** — runs project checks and a non-blocking dependency audit.
- **Sloopy iOS Unsigned Build** — uses a GitHub-hosted macOS 26 runner and Xcode to build an unsigned IPA.

The iOS build workflow has been configured but its first successful GitHub Actions build has not yet been verified.

## Important iOS Limitations

- An unsigned IPA is not normally installable on a standard iPhone.
- Normal installation requires Apple-accepted signing and provisioning.
- This repository does not contain signing credentials or provisioning profiles.
- No jailbreak-specific signing bypass is included.

See [README-IPA.md](README-IPA.md) for build instructions and limitations.
