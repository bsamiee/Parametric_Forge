#!/usr/bin/env bash
# Title    : applet
# Purpose  : Build a script-app from AppleScript or JXA source, driving osacompile output to a
#            distributable bundle with its metadata and architecture preference.
# Contract : applet <source.applescript|source.jxa> <out-name>
# Replace  : <BUNDLE_ID>.
set -euo pipefail

readonly OSACOMPILE=/usr/bin/osacompile
readonly PLISTBUDDY=/usr/libexec/PlistBuddy

readonly BUNDLE_ID="${APPLET_BUNDLE_ID:-com.example.worker}"
readonly SHORT_VERSION="${APPLET_SHORT_VERSION:-1.0.0}"
readonly BUILD_VERSION="${APPLET_BUILD_VERSION:-100}"

main() {
    [[ $# -eq 2 ]] || {
        printf 'usage: applet <source> <out-name>\n' >&2
        exit 64
    }
    local source=$1 name=$2
    local lang app
    case $source in
        *.jxa | *.js) lang=JavaScript ;;
        *) lang=AppleScript ;;
    esac
    app="build/${name}.app"
    mkdir -p build

    # The output extension selects package shape; .app writes the applet stub Mach-O.
    "$OSACOMPILE" -l "$lang" -o "$app" "$source"

    "$PLISTBUDDY" -c "Set :CFBundleIdentifier ${BUNDLE_ID}" "$app/Contents/Info.plist"
    "$PLISTBUDDY" -c "Set :CFBundleName ${name}" "$app/Contents/Info.plist"
    "$PLISTBUDDY" -c "Set :CFBundleShortVersionString ${SHORT_VERSION}" "$app/Contents/Info.plist"
    "$PLISTBUDDY" -c "Set :CFBundleVersion ${BUILD_VERSION}" "$app/Contents/Info.plist"
    # Prefer an arm64-capable stub on Apple Silicon; re-export on a native host if the slice is Intel-only.
    "$PLISTBUDDY" -c "Add :LSArchitecturePriority array" "$app/Contents/Info.plist" 2>/dev/null || true
    "$PLISTBUDDY" -c "Add :LSArchitecturePriority:0 string arm64" "$app/Contents/Info.plist" 2>/dev/null || true

    printf 'built: %s\n' "$app"
}

main "$@"
