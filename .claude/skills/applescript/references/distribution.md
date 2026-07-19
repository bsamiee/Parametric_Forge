# [DISTRIBUTION]

A deployable AppleScript artifact is a typed, signed Open Scripting Architecture object whose bundle identity, entitlement set, and code signature jointly own its Gatekeeper and TCC verdicts.

## [01]-[BUILD_OUTPUT]

`osacompile -o <name>.app` produces a bundled applet or droplet from source or compiled input, `-o <name>.scptd` produces a bundled compiled script, and every other output extension produces a flat compiled script.

```bash copy-safe
/usr/bin/osacompile -l AppleScript -o build/Worker.app src/Worker.applescript
/usr/bin/osacompile -o build/Library.scptd src/Library.applescript
```

Bundle metadata mutates before signing, never after: `CFBundleIdentifier`, `CFBundleName`, version fields, `NSAppleEventsUsageDescription`, and background-presentation keys are trust inputs the code signature seals inside `Info.plist`. An optional key such as the usage description takes an add-then-set fallback since a fresh bundle template never carries it:

```bash template
/usr/libexec/PlistBuddy -c 'Set :CFBundleIdentifier com.example.worker' "$plist"
/usr/libexec/PlistBuddy -c 'Add :NSAppleEventsUsageDescription string "Worker controls approved target apps."' "$plist" 2>/dev/null \
  || /usr/libexec/PlistBuddy -c 'Set :NSAppleEventsUsageDescription "Worker controls approved target apps."' "$plist"
```

## [02]-[SIGNING_AND_NOTARIZATION]

A Developer ID applet ships hardened runtime, the minimal `com.apple.security.automation.apple-events` entitlement set `true` in the signed entitlements plist, a timestamped signature, a notarized archive, a stapled bundle, and an independent Gatekeeper assessment as one pipeline.

```bash template
set -euo pipefail
identity='Developer ID Application: Example Corp (TEAMID1234)'
profile='notarytool-profile'
app='build/Worker.app'
zip='build/Worker.zip'
entitlements='build/worker.entitlements.plist'
/usr/bin/codesign --force --options runtime --timestamp \
  --entitlements "$entitlements" --sign "$identity" "$app"
/usr/bin/codesign --verify --strict --verbose=4 "$app"
/usr/bin/ditto -c -k --keepParent "$app" "$zip"
/usr/bin/xcrun notarytool submit "$zip" --keychain-profile "$profile" --wait
/usr/bin/xcrun stapler staple "$app"
/usr/bin/xcrun stapler validate "$app"
/usr/sbin/spctl --assess --type execute -vv "$app"
```

`notarytool` is the accepted upload path. `xcrun notarytool store-credentials <profile>` custodies the App Store Connect API key or app-specific password inside the login keychain item `com.apple.gke.notary.tool.saved-creds.<PROFILE>`, so the API key file is deletable immediately after that call; `submit --wait` blocks to a terminal verdict, `xcrun notarytool log <submission-id> --keychain-profile <profile>` returns the per-issue JSON a rejection needs, and `--webhook <url>` replaces a poll loop by posting completion time, event type, submission ID, and team ID directly.

`spctl --assess --type execute --verbose` is the developer-side notarization proof, returning `accepted` with `source=Notarized Developer ID`; a `.dmg` assessment adds `--type open --context context:primary-signature` against a spurious `Insufficient Context` rejection, and fleet-wide Gatekeeper exemption rides a Configuration Profile.

Hardened automation fails before any TCC prompt fires when `com.apple.security.automation.apple-events` is absent from the signed entitlements. A sandboxed host binds `com.apple.security.scripting-targets` where the target application exposes access groups, and falls back to a `com.apple.security.temporary-exception.apple-events` array carrying one target bundle identifier per string, such as `com.apple.finder` or `com.apple.systemevents`; a Finder or System Events exception carries operating-system-wide reach and sits outside a Mac App Store distribution plan, and hardened runtime and sandbox entitlement stay independent grants.

A JXA applet runs its hardened runtime with no JIT entitlement present, and JavaScriptCore degrades to its interpreter tier instead of failing outright: `com.apple.security.cs.allow-jit` lands where JIT throughput matters or a JavaScriptCore JIT crash surfaces under hardening. `AppleScriptObjC`, `ObjC.import`, and equivalent dynamic-code paths force the exception, since writable-executable memory needs `com.apple.security.cs.allow-jit` or `com.apple.security.cs.allow-unsigned-executable-memory` scoped to the single Mach-O that loads code dynamically, where a grant blanketed across nested helpers reports `Unnotarized Developer ID` even after a clean notarize-and-staple.

An applet stub is a Mach-O binary, so its architecture slice set is a distribution fact: `lipo -archs App.app/Contents/MacOS/applet` proves the slices, re-exporting the applet from Script Editor or `osacompile` on an Apple Silicon host produces an arm64-capable stub, and `LSArchitecturePriority` in `Info.plist` pins architecture preference for a universal stub with `arm64` listed first.

`codesign --display --verbose=4`, `codesign --display --entitlements :-`, and `codesign --verify --strict --verbose=4` confirm the sealed state. Notarization signs the submission archive while `stapler staple` attaches the ticket to the code-signed executable bundle, disk image, or flat package, so the zip is transport and the stapled bundle is the offline trust carrier that ships. A flat `.scpt` carries no bundle identity for a ticket to attach to, so durable distribution wraps script logic in a signed `.app` or command-line tool, and distribution signing overwrites a prior signature with a stable identifier.

Inner artifacts sign before the outer bundle.

```bash template
while IFS= read -r -d '' path; do
  /usr/bin/codesign --force --options runtime --timestamp --sign "$identity" "$path"
done < <(/usr/bin/find "$app/Contents" \( -perm -111 -o -name '*.dylib' -o -name '*.framework' \) -print0 | /usr/bin/sort -z -r)
/usr/bin/codesign --force --options runtime --timestamp \
  --entitlements "$entitlements" --sign "$identity" "$app"
```

## [03]-[COMPILED_ARTIFACT_FAULTS]

A faulted Apple Event error-retrieval path stalls and surfaces as `-1712` (`errAETimeout`), occasionally `-600`: Finder's `empty trash` against an already-empty trash guards with `if ((items of trash) as list) is not {}` ahead of the call, and recompiling and re-saving the script cures the stall.

Script Editor refuses an older compiled script whose storage format dropped, failing with `-1758` (`errOSADataFormatObsolete`) and refusing every further script until relaunched. `osascript` executes the same artifact unchanged, so the repair is an `osacompile` re-save from decompiled source, and a release rail recompiles shipped artifacts so the output opens in the editor.

## [04]-[DIAGNOSTICS]

AppleScript error number, shell exit status, target application name, offending object, and expected type normalize into one fault record, keeping OSA, shell, and Apple Event failures comparable across a single layer.

```applescript conceptual
on annotateError(domainName, handlerName, thunk)
    try
        return (run thunk)
    on error e number n partial result partialValue from offendingObject to expectedType
        set messageText to domainName & "." & handlerName & " failed: " & e
        error messageText number n partial result partialValue from offendingObject to expectedType
    end try
end annotateError
```

Recovery branches on the negative Apple Event number.

```applescript conceptual
try
    tell application "Calendar" to count calendars
on error e number n
    if n is -1743 then error "Automation consent missing for Calendar." number n
    if n is -1712 then error "Calendar did not answer before timeout." number n
    if n is -1728 then error "Calendar object specifier resolved to no object." number n
    error e number n
end try
```

`osascript -sso tests/case.applescript arg-a arg-b` and `osascript -sse -l JavaScript tests/case.jxa` are the two fixture-matching invocations, and `log {stage:"preflight", target:"Finder", bundle:"com.apple.finder"}` emits a structured trace record a production harness mirrors through shell stdout or Unified Logging at the outer process boundary.

`AEDebugSends=1` and `AEDebugReceives=1` on a launched process's environment trace Apple Event wire traffic for that process alone — a Finder-launched applet needs a wrapper launch or a launchd environment variable, while a terminal `osascript` call inherits both directly — and the Unified Log subsystem `com.apple.appleevents` surfaces the same send and receive descriptors system-wide for a process the harness never spawned itself.

```bash copy-safe
AEDebugSends=1 AEDebugReceives=1 /usr/bin/osascript -sse scripts/probe.applescript 2>build/apple-events.log
/usr/bin/log stream --debug --predicate 'subsystem == "com.apple.appleevents"'
```

`tcc_modify` is the Endpoint Security event carrying a grant or revocation of `kTCCServiceAppleEvents`.

```bash copy-safe
sudo eslogger tcc_modify | grep AppleEvents
/usr/bin/log stream --style compact --predicate 'subsystem == "com.apple.TCC" OR process == "appleeventsd"'
```

## [05]-[PACKAGING]

Nix packages AppleScript as a Darwin-only derivation whose build phase invokes host OSA tools and whose install result already carries the target distribution channel's signature; a pure Linux builder never owns OSA compilation.

```nix template
{ stdenvNoCC, lib }:

stdenvNoCC.mkDerivation {
  pname = "worker-applet";
  version = "1.0.0";
  src = ./.;

  meta.platforms = lib.platforms.darwin;

  buildPhase = ''
    /usr/bin/osacompile -l AppleScript -o Worker.app src/Worker.applescript
    /usr/libexec/PlistBuddy -c 'Set :CFBundleIdentifier com.example.worker' Worker.app/Contents/Info.plist
  '';

  installPhase = ''
    mkdir -p "$out/Applications"
    cp -R Worker.app "$out/Applications/"
  '';
}
```

Homebrew distributes a signed applet as a cask when the artifact is an application bundle, a disk image, or a zip; the formula lane owns a command-line launcher that calls `osascript`, never GUI app installation semantics.

```ruby template
cask "worker-applet" do
  version "1.0.0"
  sha256 "<sha256>"
  url "https://example.com/Worker-#{version}.zip"
  app "Worker.app"
end
```

## [06]-[SWIFT_MIGRATION]

A Swift host drives application control through generated ScriptingBridge glue or `OSAScript`; Apple ships no Swift Apple Event framework, and `SwiftAutomation` sits deprecated by its maintainer with `swiftae` riding on as the maintained fork, never taken load-bearing.

Migration keeps object-model automation in Apple Events and moves every other concern into Swift.
