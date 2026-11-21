#!/usr/bin/env bash
# Build sized icon variants and register them as CFBundleAlternateIcons.
# This follows EeveeSpotify's alt-icons.sh packaging flow.
# Usage: bash Native/Scripts/StageAlternateAppIcons.sh /path/to/Sloopy.app

set -euo pipefail

APP_PATH="${1:-}"
if [[ -z "$APP_PATH" || ! -d "$APP_PATH" ]]; then
    echo "Usage: $0 /path/to/Sloopy.app" >&2
    exit 1
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SRC_DIR="$ROOT_DIR/Native/Resources/CustomAppIcons"
PLIST="$APP_PATH/Info.plist"
PB=/usr/libexec/PlistBuddy
ICON_DIR="$(mktemp -d -t sloopy-alt-icons.XXXXXX)"
trap 'rm -rf "$ICON_DIR"' EXIT

[[ -f "$PLIST" ]] || { echo "[alt-icons] no Info.plist in $APP_PATH" >&2; exit 1; }

source_for_icon() {
    case "$1" in
        CCTVIcon)   echo "9ebf643bc259023155542695f3587be3.PNG" ;;
        CrystalIcon) echo "IMG_1659.PNG" ;;
        EyeIcon)     echo "IMG_1745.PNG" ;;
        CatIcon)     echo "IMG_1835.PNG" ;;
        CubeIcon)    echo "IMG_1878.PNG" ;;
        *) echo "Unknown icon name: $1" >&2; return 1 ;;
    esac
}

build() {
    local names=(CCTVIcon CrystalIcon EyeIcon CatIcon CubeIcon)
    for name in "${names[@]}"; do
        local src="$SRC_DIR/$(source_for_icon "$name")"
        [[ -f "$src" ]] || { echo "[alt-icons] missing source: $src" >&2; return 1; }

        for spec in "@2x:120" "@3x:180" "@2x~ipad:152" "~ipad:76"; do
            local suffix="${spec%:*}"
            local size="${spec#*:}"
            sips -s format png -z "$size" "$size" "$src" --out "$ICON_DIR/${name}${suffix}.png" >/dev/null
        done
        echo "[alt-icons] built $name"
    done
}

icon_names() {
    shopt -s nullglob
    local pngs=("$ICON_DIR"/*@2x.png)
    shopt -u nullglob
    for f in "${pngs[@]}"; do
        local base
        base="$(basename "$f")"
        [[ "$base" == *"~ipad"* ]] || printf '%s\n' "${base%@2x.png}"
    done
}

patch_app() {
    local names
    names="$(icon_names)"
    [[ -n "$names" ]] || { echo "[alt-icons] nothing to register" >&2; return 1; }

    # EeveeSpotify copies all generated loose PNG variants into the .app bundle.
    cp -f "$ICON_DIR"/*.png "$APP_PATH/"

    register() {
        local base="$1"
        "$PB" -c "Delete :${base}:CFBundleAlternateIcons" "$PLIST" 2>/dev/null || true
        "$PB" -c "Add :${base}:CFBundleAlternateIcons dict" "$PLIST"
        while IFS= read -r name; do
            [[ -n "$name" ]] || continue
            "$PB" -c "Add :${base}:CFBundleAlternateIcons:${name} dict" "$PLIST"
            "$PB" -c "Add :${base}:CFBundleAlternateIcons:${name}:CFBundleIconFiles array" "$PLIST"
            "$PB" -c "Add :${base}:CFBundleAlternateIcons:${name}:CFBundleIconFiles:0 string ${name}" "$PLIST"
            "$PB" -c "Add :${base}:CFBundleAlternateIcons:${name}:UIPrerenderedIcon bool false" "$PLIST"
        done <<< "$names"
    }

    "$PB" -c "Print :CFBundleIcons" "$PLIST" >/dev/null 2>&1 && register "CFBundleIcons"
    "$PB" -c "Print :CFBundleIcons~ipad" "$PLIST" >/dev/null 2>&1 && register "CFBundleIcons~ipad"

    while IFS= read -r name; do
        [[ -n "$name" ]] || continue
        for suffix in "@2x.png" "@3x.png" "@2x~ipad.png" "~ipad.png"; do
            [[ -f "$APP_PATH/${name}${suffix}" ]] || {
                echo "[alt-icons] missing ${name}${suffix} in app bundle" >&2
                return 1
            }
        done
        local registered
        registered="$("$PB" -c "Print :CFBundleIcons:CFBundleAlternateIcons:${name}:CFBundleIconFiles:0" "$PLIST")"
        [[ "$registered" == "$name" ]] || {
            echo "[alt-icons] bad CFBundleIconFiles entry for $name: $registered" >&2
            return 1
        }
    done <<< "$names"

    echo "[alt-icons] applied $(wc -l <<< "$names" | tr -d ' ') icon(s) to $(basename "$APP_PATH")"
}

build
patch_app
