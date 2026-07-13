#!/usr/bin/env bash
# Title    : notarized-applet
# Purpose  : Build a script-app from AppleScript or JXA source and carry it through the
#            full trust chain — bundle metadata, hardened runtime, the minimal Apple Events
#            entitlement, nested inner-first signing, notarization, staple, and an
#            independent Gatekeeper assessment. The signed applet owns its TCC identity.
# Contract : notarized-applet <source.applescript|source.jxa> <out-name>
# Replace  : <BUNDLE_ID>, <IDENTITY>, <NOTARY_PROFILE>, and the scripting-targets receiver.
set -euo pipefail

readonly OSACOMPILE=/usr/bin/osacompile
readonly CODESIGN=/usr/bin/codesign
readonly PLISTBUDDY=/usr/libexec/PlistBuddy
readonly DITTO=/usr/bin/ditto
readonly XCRUN=/usr/bin/xcrun
readonly SPCTL=/usr/sbin/spctl

readonly BUNDLE_ID="${APPLET_BUNDLE_ID:-com.example.worker}"
readonly IDENTITY="${APPLET_IDENTITY:-Developer ID Application: Example Corp (TEAMID1234)}"
readonly NOTARY_PROFILE="${APPLET_NOTARY_PROFILE:-notarytool-profile}"
readonly SHORT_VERSION="${APPLET_SHORT_VERSION:-1.0.0}"
readonly BUILD_VERSION="${APPLET_BUILD_VERSION:-100}"
readonly USAGE_DESCRIPTION="${APPLET_USAGE_DESCRIPTION:-Worker sends Apple events to approved target applications.}"

main() {
    [[ $# -eq 2 ]] || {
        printf 'usage: notarized-applet <source> <out-name>\n' >&2
        exit 64
    }
    local source=$1 name=$2
    local lang app entitlements zip
    case $source in
        *.jxa | *.js) lang=JavaScript ;;
        *) lang=AppleScript ;;
    esac
    app="build/${name}.app"
    entitlements="build/${name}.entitlements.plist"
    zip="build/${name}.zip"
    mkdir -p build

    # The output extension selects package shape; .app writes the applet stub Mach-O.
    "$OSACOMPILE" -l "$lang" -o "$app" "$source"

    # Bundle metadata is a trust input the signature seals, so every field lands first.
    "$PLISTBUDDY" -c "Set :CFBundleIdentifier ${BUNDLE_ID}" "$app/Contents/Info.plist"
    "$PLISTBUDDY" -c "Set :CFBundleName ${name}" "$app/Contents/Info.plist"
    "$PLISTBUDDY" -c "Set :CFBundleShortVersionString ${SHORT_VERSION}" "$app/Contents/Info.plist"
    "$PLISTBUDDY" -c "Set :CFBundleVersion ${BUILD_VERSION}" "$app/Contents/Info.plist"
    "$PLISTBUDDY" -c "Add :NSAppleEventsUsageDescription string ${USAGE_DESCRIPTION}" "$app/Contents/Info.plist" 2>/dev/null ||
        "$PLISTBUDDY" -c "Set :NSAppleEventsUsageDescription ${USAGE_DESCRIPTION}" "$app/Contents/Info.plist"
    # Prefer an arm64-capable stub on Apple Silicon; re-export on a native host if the slice is Intel-only.
    "$PLISTBUDDY" -c "Add :LSArchitecturePriority array" "$app/Contents/Info.plist" 2>/dev/null || true
    "$PLISTBUDDY" -c "Add :LSArchitecturePriority:0 string arm64" "$app/Contents/Info.plist" 2>/dev/null || true

    # The minimal Apple Events entitlement gates hardened-runtime prompting. A JXA applet
    # that drives the ObjC bridge additionally needs allow-jit for writable-executable memory.
    cat >"$entitlements" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>com.apple.security.automation.apple-events</key>
  <true/>
</dict>
</plist>
PLIST

    # Nested ownership: inner code signs first, the outer app signs last. Any post-signature
    # byte mutation under Contents invalidates the seal.
    while IFS= read -r -d '' path; do
        "$CODESIGN" --force --options runtime --timestamp --sign "$IDENTITY" "$path"
    done < <(/usr/bin/find "$app/Contents" \( -perm -111 -o -name '*.dylib' -o -name '*.framework' \) -print0 | /usr/bin/sort -z -r)

    "$CODESIGN" --force --options runtime --timestamp \
        --entitlements "$entitlements" --sign "$IDENTITY" "$app"
    "$CODESIGN" --verify --strict --verbose=4 "$app"

    # notarytool is the only accepted upload path; the zip is a submission container and the
    # staple bakes the ticket into the .app so first launch verifies offline.
    "$DITTO" -c -k --keepParent "$app" "$zip"
    "$XCRUN" notarytool submit "$zip" --keychain-profile "$NOTARY_PROFILE" --wait
    "$XCRUN" stapler staple "$app"
    "$XCRUN" stapler validate "$app"
    "$SPCTL" --assess --type execute --verbose "$app"

    printf 'signed and notarized: %s\n' "$app"
}

main "$@"
