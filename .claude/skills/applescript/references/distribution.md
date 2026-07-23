# [DISTRIBUTION]

A deployable AppleScript artifact is a typed Open Scripting Architecture object carrying its own bundle identity.

## [01]-[BUILD_OUTPUT]

`osacompile -o <name>.app` produces a bundled applet or droplet from source or compiled input, `-o <name>.scptd` produces a bundled compiled script, and every other output extension produces a flat compiled script.

```bash copy-safe
/usr/bin/osacompile -l AppleScript -o build/Worker.app src/Worker.applescript
/usr/bin/osacompile -o build/Library.scptd src/Library.applescript
```

Bundle metadata mutates inside `Info.plist`: `CFBundleIdentifier`, `CFBundleName`, version fields, and background-presentation keys.

```bash template
plist='build/Worker.app/Contents/Info.plist'
/usr/libexec/PlistBuddy -c 'Set :CFBundleIdentifier com.example.worker' "$plist"
```

An applet stub is a Mach-O binary, so its architecture slice set is a distribution fact: `lipo -archs App.app/Contents/MacOS/applet` proves the slices, re-exporting the applet from Script Editor or `osacompile` on an Apple Silicon host produces an arm64-capable stub, and `LSArchitecturePriority` in `Info.plist` pins architecture preference for a universal stub with `arm64` listed first.

## [02]-[COMPILED_ARTIFACT_FAULTS]

A faulted Apple Event error-retrieval path stalls and surfaces as `-1712` (`errAETimeout`), occasionally `-600`: Finder's `empty trash` against an already-empty trash guards with `if ((items of trash) as list) is not {}` ahead of the call, and recompiling and re-saving the script cures the stall.

Script Editor refuses an older compiled script whose storage format dropped, failing with `-1758` (`errOSADataFormatObsolete`) and refusing every further script until relaunched. `osascript` executes the same artifact unchanged, so the repair is an `osacompile` re-save from decompiled source, and a release rail recompiles shipped artifacts so the output opens in the editor.

## [03]-[DIAGNOSTICS]

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

## [04]-[PACKAGING]

Nix packages AppleScript as a Darwin-only derivation whose build phase invokes host OSA tools, and a pure Linux builder never owns OSA compilation.

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

Homebrew distributes an applet as a cask when the artifact is an application bundle, a disk image, or a zip; the formula lane owns a command-line launcher that calls `osascript`, never GUI app installation semantics.

```ruby template
cask "worker-applet" do
  version "1.0.0"
  sha256 "<sha256>"
  url "https://example.com/Worker-#{version}.zip"
  app "Worker.app"
end
```

## [05]-[SWIFT_MIGRATION]

A Swift host drives application control through generated ScriptingBridge glue or `OSAScript`; Apple ships no Swift Apple Event framework, and `SwiftAutomation` sits deprecated by its maintainer with `swiftae` riding on as the maintained fork, never taken load-bearing.

Migration keeps object-model automation in Apple Events and moves every other concern into Swift.
