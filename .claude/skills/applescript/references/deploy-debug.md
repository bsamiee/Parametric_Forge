# [DEPLOY_DEBUG]

A deployable AppleScript artifact is a typed, signed Open Scripting Architecture object whose bundle identity, entitlement set, and code signature jointly own its Gatekeeper and TCC verdicts, never its file extension, source text, or declared intent. Every discrimination, packaging, signing, consent, and observability decision downstream traces back to that identity.

## [01]-[ARTIFACT_TOPOLOGY]

`UTType.appleScript` binds plain `.applescript` source text, `UTType.osaScript` binds a flat compiled `.scpt`, and `UTType.osaScriptBundle` binds the `.scptd` package form through `com.apple.applescript.script-bundle`. A file-accepting surface discriminates on these conformances before any extension check; extension sniffing is a fallback for a type identity that resolution fails to produce.

```swift conceptual
import UniformTypeIdentifiers

enum ScriptArtifact {
    case source(URL)
    case compiled(URL)
    case bundle(URL)
    case unsupported(URL, UTType)

    init(url: URL, contentType: UTType) {
        if contentType.conforms(to: .appleScript) {
            self = .source(url)
        } else if contentType.conforms(to: .osaScript) {
            self = .compiled(url)
        } else if contentType.conforms(to: .osaScriptBundle) {
            self = .bundle(url)
        } else {
            self = .unsupported(url, contentType)
        }
    }
}
```

`osacompile -o <name>.app` produces a bundled applet or droplet from source or compiled input, `-o <name>.scptd` produces a bundled compiled script, and every other output extension produces a flat compiled script; the output extension is the sole package-format switch.

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

`notarytool` is the only accepted upload path — the notary service stopped taking `altool` submissions since 2023-11-01, and an `altool` submission ID never resolves against `notarytool log`. `xcrun notarytool store-credentials <profile>` custodies the App Store Connect API key or app-specific password inside the login keychain item `com.apple.gke.notary.tool.saved-creds.<PROFILE>`, so the API key file is deletable immediately after that call; `submit --wait` blocks to a terminal verdict, a rejection is diagnosed with `xcrun notarytool log <submission-id> --keychain-profile <profile>` for the per-issue JSON the zip submission omits, and `--webhook <url>` replaces a poll loop by posting completion time, event type, submission ID, and team ID directly. Gatekeeper management leaves the CLI entirely on Tahoe: `spctl --master-disable`, `spctl --global-disable`, and `spctl --global-enable` each redirect to System Settings instead of executing, while `spctl --assess --type execute --verbose` remains the developer-side notarization proof, returning `accepted` with `source=Notarized Developer ID` — a `.dmg` assessment adds `--type open --context context:primary-signature` to avoid a spurious `Insufficient Context` rejection, and fleet-wide exemption rides a Configuration Profile, never a CLI toggle. Hardened automation fails before any TCC prompt fires when `com.apple.security.automation.apple-events` is absent from the signed entitlements, and sandboxed automation additionally binds a `com.apple.security.temporary-exception.apple-events` array carrying each target's bundle identifier, one string per application such as `com.apple.finder` or `com.apple.systemevents` — hardened runtime and sandbox entitlement stay independent grants.

A JXA applet runs its hardened runtime with no JIT entitlement present, and JavaScriptCore degrades to its interpreter tier instead of failing outright: `com.apple.security.cs.allow-jit` lands only when JIT throughput matters or a JavaScriptCore JIT crash surfaces under hardening, and the ObjC bridge — `AppleScriptObjC`, `ObjC.import`, and equivalent dynamic-code paths — forces the exception, since writable-executable memory needs `com.apple.security.cs.allow-jit` or `com.apple.security.cs.allow-unsigned-executable-memory` scoped to the single Mach-O that loads code dynamically, never blanketed across nested helpers, where an over-broad grant reports `Unnotarized Developer ID` even after a clean notarize-and-staple. The applet stub is a Mach-O binary, not a text script, so its architecture set is a distribution fact: a legacy Intel-only stub triggers a Rosetta prompt on Apple Silicon, while re-exporting the applet from Script Editor or `osacompile` on an Apple Silicon host produces an arm64-capable stub — `lipo -archs App.app/Contents/MacOS/applet` proves the slice set, and `LSArchitecturePriority` in `Info.plist`, arm64 listed first, pins architecture preference for a universal stub. Every post-signature byte mutation under `Contents` invalidates the signature: icon injection, `Info.plist` edits, embedded-helper replacement, `Scripts/main.scpt` replacement, and localization edits land before `codesign`, never after — `codesign --display --verbose=4`, `codesign --display --entitlements :-`, and `codesign --verify --strict --verbose=4` confirm the sealed state, and notarization signs the submission archive while `stapler staple` attaches the ticket to the code-signed executable bundle, disk image, or flat package — the zip is transport only, and the app bundle is the offline trust carrier that ships.

Nested signing runs inner-to-outer: every embedded helper, framework, plug-in, and command-line tool inside the bundle signs first, and the outer app bundle signs last, sealing every inner signature inside its own.

```bash template
while IFS= read -r -d '' path; do
  /usr/bin/codesign --force --options runtime --timestamp --sign "$identity" "$path"
done < <(/usr/bin/find "$app/Contents" \( -perm -111 -o -name '*.dylib' -o -name '*.framework' \) -print0 | /usr/bin/sort -z -r)
/usr/bin/codesign --force --options runtime --timestamp \
  --entitlements "$entitlements" --sign "$identity" "$app"
```

## [03]-[AUTOMATION_CONSENT_PREFLIGHT]

`AEDeterminePermissionToAutomateTarget` classifies Automation consent before any real Apple Event ships: `noErr` means already-permitted, `errAEEventNotPermitted` (`-1743`) means denied, and `errAEEventWouldRequireUserConsent` (`-1744`) means the status is undetermined and a prompt resolves it — returned only when the trailing `askUserIfNeeded` argument is `false`. Passing `typeWildCard` for both event class and event ID asks whether any event reaches the target at all. A preflight call with `askUserIfNeeded` `false` branches silently on the verdict; a follow-up call with `askUserIfNeeded` `true` triggers the consent dialog on demand, so a host never discovers denial by shipping a doomed command first.

```swift conceptual
import Carbon.AppleScript

func automationVerdict(bundleID: String) -> OSStatus {
    var target = AEAddressDesc()
    _ = bundleID.withCString { ptr in
        AECreateDesc(typeApplicationBundleID, ptr, strlen(ptr), &target)
    }
    defer { AEDisposeDesc(&target) }
    return AEDeterminePermissionToAutomateTarget(&target, AEEventClass(typeWildCard), AEEventID(typeWildCard), false)
}
```

`kAEDoNotPromptForUserConsent` (`0x00020000`) is the send-time analog of the preflight call: OR-ing it into an `AESend` send mode turns a consent-requiring event into an immediate `-1744` instead of a dialog, and a batch sender that stays non-interactive sets this flag and reconciles `-1744` and `-1743` as ordinary domain data, keeping the human-facing dialog on its own explicit preflight call. Tahoe carries an error-retrieval regression, `FB20174869`: AppleScript error paths that returned immediately on Sequoia now stall roughly two minutes and surface as `-1712` (`errAETimeout`), occasionally `-600` — the retrieval of the error stalls, not the permission-determination call itself, and Mail reads against nonexistent properties, junk-mailbox faults, and Finder's `empty trash` against an already-empty trash are the observed victims, the Finder case guarded with `if ((items of trash) as list) is not {}` ahead of the call; recompiling and re-saving every script on a Tahoe host cures the stall, so every automation boundary carries an explicit `with timeout` on the Apple Event side and a process-level deadline on the host side. Script Editor build `234` on macOS `26.4` refuses to open some older compiled scripts, failing with `-1758` (`errOSADataFormatObsolete`): legacy storage formats, resource-fork-stored `.scpt` chief among them, drop silently, and Script Editor refuses further scripts until relaunched once it hits one — `osascript`, BBEdit, and Keyboard Maestro still execute the same artifacts, since the fault is an editor-format regression, not an execution break, and the repair is an `osacompile` re-save from decompiled source into a current-format `.scpt`, with a release rail shipping compiled artifacts recompiling on a `26.4`-or-later host so the shipped output opens in the current editor.

## [04]-[SHELL_BOUNDARY]

`do shell script` starts a fresh, non-login `/bin/sh` per call, receives a noninteractive environment, returns stdout, turns a nonzero exit into an AppleScript error, and interprets command and output text as UTF-8 — shell state never survives past the call that created it. Shell arguments stay data until one join point converts them with `quoted form of`; every command builder carries an absolute executable path and never accepts a pre-joined fragment from a caller.

```applescript conceptual
script Shell
    on argv(wordList)
        set quotedWords to {}
        repeat with wordValue in wordList
            set end of quotedWords to quoted form of (wordValue as text)
        end repeat
        set AppleScript's text item delimiters to space
        set joined to quotedWords as text
        set AppleScript's text item delimiters to ""
        return joined
    end argv
end script

do shell script "/usr/bin/stat " & Shell's argv({"-f", "%N:%z", POSIX path of (choose file)})
```

Elevated shell execution runs outside application `tell` blocks or inside `tell me`, since the target application never becomes the parent process for a privileged scripting addition; multi-command elevation sends one quoted script to `/bin/sh -c`, preserving one authentication prompt, one root shell, and one injection boundary. Long data enters a temporary file, never the command string, so `kern.argmax`, AppleScript quoting, shell parsing, and logging surfaces all stop carrying payload bytes, and a background command detaches with explicit redirection and a captured PID so AppleScript receives a process handle, never a live pipe.

```applescript conceptual
tell application "Finder" to set selectedPaths to (POSIX path of (selection as alias list))
tell me
    do shell script "/usr/sbin/chown -R root:wheel " & Shell's argv(selectedPaths) with administrator privileges
end tell
```

```applescript conceptual
set payload to "set -e" & linefeed & ¬
    "install -d -m 0755 /Library/Application\\ Support/Example" & linefeed & ¬
    "cp " & quoted form of POSIX path of sourceFile & " /Library/Application\\ Support/Example/config.json"

do shell script "/bin/sh -c " & quoted form of payload with administrator privileges
```

```applescript conceptual
set tempPath to do shell script "/usr/bin/mktemp /tmp/example.XXXXXX"
try
    set fd to open for access POSIX file tempPath with write permission
    write largeText to fd as «class utf8»
    close access fd
    do shell script "/usr/bin/plutil -lint " & quoted form of tempPath
on error e number n
    try
        close access POSIX file tempPath
    end try
    error e number n
end try
```

```applescript conceptual
set logPath to POSIX path of (path to temporary items) & "worker.log"
set commandText to "/usr/local/bin/worker > " & quoted form of logPath & " 2>&1 & echo $!"
set workerPID to do shell script commandText
```

## [05]-[APPLE_EVENT_PERFORMANCE]

Round-trips across the Apple Event boundary, object-specifier resolution, and the target application's own implementation quality dominate automation cost. A script batches specifiers across the process boundary once, then loops over native AppleScript lists locally.

```applescript conceptual
tell application "Calendar"
    tell calendar "Work"
        set {eventIds, eventStarts, eventSummaries} to {uid, start date, summary} of every event
    end tell
end tell

set rows to {}
repeat with i from 1 to count eventIds
    set end of rows to {id:item i of eventIds, starts:item i of eventStarts, title:item i of eventSummaries}
end repeat
```

`whose` filtering pushes selection into the target application when that application implements object filtering correctly, with looping over every remote object staying the fallback path, never the first design — UI scripting rides the same discipline one layer lower, resolving the smallest stable accessibility container first and collecting attributes in plural form rather than walking rows one at a time. Bulk property assignment through a plural object specifier beats a per-object command loop, since one Apple Event mutates the whole selection set.

```applescript conceptual
tell application "Finder"
    set staleAliases to every alias file of folder sourceFolder whose modification date < cutoffDate
    set label index of staleAliases to 2
    set label index of every file of folder targetFolder whose name extension is "pdf" to 6
end tell
```

`with timeout` budgets a hostile application's latency at the Apple Event boundary, and the enclosing handler records target, selector, and timeout value as fault coordinates on the way out; `with transaction` benefits only an application that implements transaction semantics, so the transaction block sits behind an application capability row and an unsupported target keeps the ordinary batched Apple Event path.

```applescript conceptual
on fetchWindowNames()
    try
        with timeout of 5 seconds
            tell application "System Events" to return name of every window of every process whose visible is true
        end timeout
    on error e number n partial result partialValue from offendingObject to expectedType
        error ("System Events window census failed: " & e) number n partial result partialValue from offendingObject to expectedType
    end try
end fetchWindowNames
```

```applescript conceptual
on applyRemoteMutation(targetBundleID, mutationScript, supportsTransactions)
    if supportsTransactions then
        tell application id targetBundleID
            with transaction
                run script mutationScript
            end transaction
        end tell
    else
        tell application id targetBundleID
            run script mutationScript
        end tell
    end if
end applyRemoteMutation
```

## [06]-[DIAGNOSTICS]

Production handlers rethrow the full AppleScript error structure after attaching domain context; dropping `partial result`, `from`, or `to` destroys the only structured diagnostics some applications return. The rethrown fields — AppleScript error number, shell exit status, target application name, offending object, expected type — normalize into one fault record, keeping OSA, shell, and Apple Event failures comparable across a single layer.

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

Recovery branches on exact negative Apple Event numbers, never message substrings: `-1743` routes an Automation-consent denial, `-1712` routes a timeout, and `-1728` routes an object-not-found fault.

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

`osascript -sso tests/case.applescript arg-a arg-b` recompiles result output and routes script errors to stdout for fixture matching; `osascript -sse -l JavaScript tests/case.jxa` keeps stderr separate for a shell pipeline, and `log` is Script Editor's structured trace primitive, invoked as `log {stage:"preflight", target:"Finder", bundle:"com.apple.finder"}`, that a production harness mirrors through shell stdout or Unified Logging at the outer process boundary.

`AEDebugSends=1` and `AEDebugReceives=1` on a launched process's environment trace Apple Event wire traffic for that process alone — a Finder-launched applet needs a wrapper launch or a launchd environment variable, while a terminal `osascript` call inherits both directly — and system-wide tracing routes through the Unified Log subsystem `com.apple.appleevents`, surfacing the same send and receive descriptors for a process the harness never spawned itself.

```bash copy-safe
AEDebugSends=1 AEDebugReceives=1 /usr/bin/osascript -sse scripts/probe.applescript 2>build/apple-events.log
/usr/bin/log stream --debug --predicate 'subsystem == "com.apple.appleevents"'
```

Endpoint Security carries no `apple_event` event type, so Apple Event traffic itself stays outside its reach; what Endpoint Security observes for consent work is `tcc_modify`, the write to the TCC database that records a grant or revocation of `kTCCServiceAppleEvents`, watched directly with `sudo eslogger tcc_modify | grep AppleEvents` riding the Apple-signed binary's existing ES client entitlement, while the `com.apple.appleevents` log owns the event traffic itself. Script Debugger direct debugging handles an ordinary script, a stay-open applet, a droplet, and idle handlers; indirect debugging attaches where another host invokes the script, so the reproduction preserves the parent process, environment, TCC identity, and working directory — TCC debugging records the controlling binary, not the script text alone, so `osascript`, Terminal, Script Editor, a signed applet, and a Swift host each earn a separate Automation consent row, surfaced by `log stream --style compact --predicate 'subsystem == "com.apple.TCC" OR process == "appleeventsd"'`.

## [07]-[PACKAGING]

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

## [08]-[SWIFT_MIGRATION]

`NSAppleScript` binds to the main thread and rejects reentrancy: `compileAndReturnError:`, `executeAndReturnError:`, and `executeAppleEvent:error:` all misbehave off-thread or under recursive invocation. OSAKit's `OSAScript` rides the identical OSA component substrate and grants no concurrency escape. Off-main execution runs through `NSUserAppleScriptTask`, whose completion handler fires on its own queue outside the sandbox, or through a spawned `/usr/bin/osascript` `Process`, never through a background-queue `NSAppleScript` call.

```swift conceptual
func runAppleScript(source: String) throws -> NSAppleEventDescriptor? {
    var compileError: NSDictionary?
    let script = NSAppleScript(source: source)
    guard script?.compileAndReturnError(&compileError) == true else {
        throw ScriptFailure(info: compileError)
    }
    var runError: NSDictionary?
    let result = script?.executeAndReturnError(&runError)
    if let runError { throw ScriptFailure(info: runError) }
    return result
}
```

OSAKit owns a richer OSA lifecycle than `NSAppleScript`: `OSALanguage.availableLanguages`, `OSAScript.compileAndReturnError:`, `OSAScript.executeHandler(withName:arguments:error:)` returns an `NSAppleEventDescriptor`, never display text, `OSAScript.executeAndReturnDisplayValue(_:)` gives the human-readable form, and `compiledData(forType:usingStorageOptions:)`/`write(to:ofType:usingStorageOptions:)` serialize the compiled artifact — together the migration surface for an editor, a runner, or an artifact builder. Its storage option flags are the programmatic form of every `osacompile` output flag — `OSAPreventGetSource` seals an execute-only build, `OSAStayOpenApplet` and `OSACompileIntoContext` mirror the remaining compiler switches — so an in-process build rail skips shelling out to `osacompile` entirely.

```swift conceptual
func runHandler(source: String) -> (NSAppleEventDescriptor?, NSDictionary?) {
    guard let language = OSALanguage(forName: "AppleScript") else { return (nil, nil) }
    let script = OSAScript(source: source, language: language)
    var compileError: NSDictionary?
    guard script.compileAndReturnError(&compileError) else { return (nil, compileError) }
    var runError: NSDictionary?
    let descriptor = script.executeHandler(withName: "run", arguments: [], error: &runError)
    return (descriptor, runError)
}
```

ScriptingBridge migrates application control, never AppleScript semantics: `SBApplication` targets by bundle identifier, drives a generated or dynamic app-specific interface, carries `sendMode`, `timeout`, and a delegate for Apple Event failures, and still consumes TCC Automation consent under the host application's identity. ScriptingBridge and OSAKit stand as the only Apple-shipped Apple Event bridges — no first-party Swift Apple Event framework exists — and the third-party `SwiftAutomation` and its `appleeventbridge` predecessor sit deprecated by their maintainer's own hand, with `swiftae` riding on as its actively maintained fork; a Swift host drives application control through generated ScriptingBridge glue or through `OSAScript`/`NSAppleScript`, never through an absent first-party Swift bridge or an unmaintained third-party dependency taken load-bearing.

`sdef` and `sdp` produce a typed bridge from a target application's scripting dictionary, run as `sdef /Applications/Safari.app > build/Safari.sdef` then `sdp -fh --basename Safari build/Safari.sdef`; full Xcode owns both tools even where Command Line Tools expose stubs, so a build probes tool usability before committing to the lane, and on a Command Line Tools-only host `OSACopyScriptingDefinitionFromURL` returns the same `.sdef` XML at runtime — auto-synthesized from a legacy `'aete'` or `scriptSuite`/`scriptTerminology` resource when no native `.sdef` exists — without the `sdef` executable present, feeding the same `sdp -fh` header generation. The migration boundary keeps object-model automation in Apple Events and moves computation, persistence, concurrency, signing, update, and observability into Swift; a Swift rewrite that shells to `osascript` for every operation only preserves the slowest and least typed boundary. The `NSUserScriptTask` family — `NSUserAppleScriptTask` (`execute(withAppleEvent:completionHandler:)`), `NSUserAutomatorTask` (`execute(withInput:)`), and `NSUserUnixTask` (`execute(withArguments:)`) — runs a user-supplied script from `~/Library/Application Scripts/<bundle-id>/` outside the host application's sandbox, completing on an asynchronous handler; a sandboxed host reads that directory and discriminates each task class by artifact kind, never treating a bundled script as a user script task.

App Sandbox automation binds `com.apple.security.scripting-targets` when the target application exposes access groups, and falls back to `com.apple.security.temporary-exception.apple-events` only when the target lacks groups; Finder and System Events exceptions carry operating-system-wide reach and sit outside a Mac App Store distribution plan.
