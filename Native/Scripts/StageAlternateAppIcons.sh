#!/usr/bin/env bash
# Stage alternate icon PNGs and register them using EeveeSpotify's plist layout.
# Usage: bash Native/Scripts/StageAlternateAppIcons.sh /path/to/Sloopy.app
set -euo pipefail

APP_PATH="$1"
if [[ -z "$APP_PATH" || ! -d "$APP_PATH" ]]; then
    echo "Usage: $0 /path/to/Sloopy.app" >&2
    exit 1
fi

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
SRC_DIR="$ROOT_DIR/Native/Resources/CustomAppIcons"
PLIST="$APP_PATH/Info.plist"
PB="/usr/libexec/PlistBuddy"

[[ -f "$PLIST" ]] || { echo "[stage-icons] Info.plist missing" >&2; exit 1; }

ICON_NAMES="CCTVIcon CrystalIcon EyeIcon CatIcon CubeIcon"
source_for_icon() {
    case "$1" in
        CCTVIcon) echo "9ebf643bc259023155542695f3587be3.PNG" ;;
        CrystalIcon) echo "IMG_1659.PNG" ;;
        EyeIcon) echo "IMG_1745.PNG" ;;
        CatIcon) echo "IMG_1835.PNG" ;;
        CubeIcon) echo "IMG_1878.PNG" ;;
        *) echo "Unknown icon name: $1" >&2; return 1 ;;
    esac
}

for name in $ICON_NAMES; do
    source="$SRC_DIR/$(source_for_icon "$name")"
    [[ -f "$source" ]] || { echo "[stage-icons] Missing source PNG: $source" >&2; exit 1; }

    # EeveeSpotify-style point sizes: iPhone 120/180 and iPad 152/76.
    sips -s format png -z 120 120 "$source" --out "$APP_PATH/$name@2x.png" >/dev/null
    sips -s format png -z 180 180 "$source" --out "$APP_PATH/$name@3x.png" >/dev/null
    sips -s format png -z 152 152 "$source" --out "$APP_PATH/$name@2x~ipad.png" >/dev/null
    sips -s format png -z 76 76 "$source" --out "$APP_PATH/$name~ipad.png" >/dev/null
done

register_alternates() {
    base="$1"
    "$PB" -c "Delete :$base:CFBundleAlternateIcons" "$PLIST" 2>/dev/null || true
    "$PB" -c "Add :$base:CFBundleAlternateIcons dict" "$PLIST"

    for name in $ICON_NAMES; do
        "$PB" -c "Add :$base:CFBundleAlternateIcons:$name dict" "$PLIST"
        "$PB" -c "Add :$base:CFBundleAlternateIcons:$name:CFBundleIconFiles array" "$PLIST"
        "$PB" -c "Add :$base:CFBundleAlternateIcons:$name:CFBundleIconFiles:0 string $name" "$PLIST"
        "$PB" -c "Add :$base:CFBundleAlternateIcons:$name:UIPrerenderedIcon bool false" "$PLIST"
    done
}

"$PB" -c "Print :CFBundleIcons" "$PLIST" >/dev/null 2>&1 || {
    echo "[stage-icons] CFBundleIcons dictionary missing" >&2
    exit 1
}
register_alternates "CFBundleIcons"

if "$PB" -c "Print :CFBundleIcons~ipad" "$PLIST" >/dev/null 2>&1; then
    register_alternates "CFBundleIcons~ipad"
fi

for name in $ICON_NAMES; do
    for suffix in "@2x.png" "@3x.png" "@2x~ipad.png" "~ipad.png"; do
        [[ -f "$APP_PATH/$name$suffix" ]] || { echo "[stage-icons] Missing $name$suffix" >&2; exit 1; }
    done
    icon_file="$("$PB" -c "Print :CFBundleIcons:CFBundleAlternateIcons:$name:CFBundleIconFiles:0" "$PLIST")"
    [[ "$icon_file" == "$name" ]] || { echo "[stage-icons] Bad CFBundleIconFiles value for $name" >&2; exit 1; }
done

echo "[stage-icons] Registered five alternate icons with loose PNGs and CFBundleIconFiles."
