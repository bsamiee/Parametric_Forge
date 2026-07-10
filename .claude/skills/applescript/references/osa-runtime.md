# [OSA_RUNTIME]

The OSA runtime owns script execution, compilation, language selection, descriptor boundaries, script-library composition, applet packaging, and signed distribution across `osascript`, `osacompile`, `osadecompile`, `osalang`, `OSAKit`, `NSAppleScript`, `ScriptingBridge`, and `Automator`. AppleScript and JXA sit as language rows on this one rail; production automation keeps process invocation, output serialization, and packaging policy outside script bodies and treats the descriptor boundary as the real API surface.

| [INDEX] | [SURFACE]         | [CONTRACT]                                                                                                  |
| :-----: | :---------------- | :---------------------------------------------------------------------------------------------------------- |
|  [01]   | `osascript`       | Runs `-e` text, one file, or stdin; `-l` selects language, `-s` selects serialization.                      |
|  [02]   | `osacompile`      | Compiles to `.scpt`/`.scptd`/`.app` by output extension; `-x` strips source, `-s`/`-u` set applet behavior. |
|  [03]   | `osadecompile`    | Recovers source from compiled data; run-only input returns `-1756`.                                         |
|  [04]   | `osalang`         | Lists installed OSA components with `-L` capability flags.                                                  |
|  [05]   | `OSAKit`          | Embeds language-aware `OSAScript` with storage options and structured errors.                               |
|  [06]   | `NSAppleScript`   | Embeds AppleScript-only execution bound to the main thread.                                                 |
|  [07]   | `ScriptingBridge` | Proxies Apple events as typed objects through `SBApplication`.                                              |
|  [08]   | `Automator`       | Hosts `AMAppleScriptAction.script` as a stored `OSAScript`.                                                 |

## [01]-[INVOCATION_AND_ARGV]

`osascript` selects exactly one source shape per invocation: concatenated `-e` lines, one program file, or stdin bound only when `-` names the program explicitly; every shape hands the same argv array to `on run argv` in AppleScript and `function run(argv)` in JXA, and the handler owns decoding, type validation, and envelope framing before any return value crosses back to the caller. `osascript -i` opens a line-at-a-time REPL that loads any `-e` or file program without running it before the prompt opens, a dictionary and coercion probe rather than a production entrypoint. A script error yields a non-zero exit, but the numeric mapping carries no published contract; a wrapper asserts on the serialized error text from `-s o` and never on a specific exit code.

```bash copy-safe
osascript -l JavaScript -s s -e 'function run(argv) { return JSON.stringify(argv) }' a b
printf 'function run(argv) { return argv.join(":") }\n' | osascript -l JavaScript - foo bar
osascript ./worker.scpt alpha beta
osascript -i
```

```applescript copy-safe
on run argv
    return {argv:argv, argc:length of argv}
end run
```

## [02]-[OUTPUT_AND_ENVELOPE]

Output mode is an API boundary, not a formatting preference. `-s h` prints display strings that collapse distinct list and record shapes into identical text; `-s s` prints recompilable source-like values, so pipelines, tests, and wrappers bind to `-s s`. `-s e` keeps script errors on stderr; `-s o` routes them to stdout so a golden test asserts the OSA error text as the primary value. Shell quoting stays inside the wrapper and never enters the script body — untrusted data crosses through argv and returns as one JSON envelope on stdout. The JXA `run` handler's return value is the sole stdout payload; every diagnostic routes to stderr through `console.log`, so a caller parses one `JSON.stringify` envelope without logging interleaved into the parse target.

```bash copy-safe
osascript -s s -e 'return {{"foo", "bar"}, {"foo", {"bar"}}}'
osascript -s h -e 'return {{"foo", "bar"}, {"foo", {"bar"}}}'
actual=$(osascript -s so ./fixture.scpt 2>/tmp/transport.stderr || true)
osascript -l JavaScript -s s ./automation.scpt "$bundle_id" "$payload_json"
```

```javascript copy-safe
function run(argv) {
    const [bundleID, payloadJSON] = argv;
    console.log(`decoding payload for ${bundleID}`);
    return JSON.stringify({ ok: true, bundleID });
}
```

## [03]-[BUILD_ROW_INJECTION]

`osacompile -e` prepends commands ahead of the file or stdin source, giving a build system an injection point for immutable build rows rather than user data.

```bash copy-safe
osacompile -l JavaScript \
  -e 'const BUILD_CHANNEL = "release"' \
  -e 'const SCRIPT_SCHEMA = 3' \
  -o build/Worker.scpt src/worker.jxa
```

## [04]-[LANGUAGE_CENSUS]

`osalang -L` returns each installed component's identity and a feature-flag string; on macOS 26 AppleScript reports `cgxervdh` and JavaScript reports `cgxe-v-h`. The shared positions decode as compile, get-source, coerce, event-send, convenience-execution, and event-handling — the baseline capability set every OSA host exercises — and the two positions JXA leaves blank are the recording (`r`) and dialect (`d`) bits that AppleScript alone declares. The generic `scpt` component opens any installed OSA scripting system transparently, but a text source carries no embedded language metadata, so a launcher still passes `-l AppleScript` or `-l JavaScript` explicitly.

```bash copy-safe
osalang -L
```

## [05]-[SPECIFIER_AND_WHOSE]

A JXA property that addresses an application object model returns an object specifier until evaluation forces it: parentheses call `get` for a scalar or array value, and assignment sends a `set` Apple event. Specifier chains stay lazy across element traversal, so a pipeline sends one event at the terminal property call. `whose` builds one of these specifiers into an Apple event test descriptor rather than a JavaScript predicate, closed over a comparison-and-logic key vocabulary (`_beginsWith`, `_and`, and their peers) that the target application evaluates server-side. A single-field predicate coerces cleanly against every target because it maps to one comparison descriptor; a compound predicate composes a logical descriptor around it, and a target whose object-model implementation omits logical-descriptor support rejects the whole compound test outright rather than degrading to a partial match — so a production filter reduces on the target for the cheap single field and falls back to JavaScript filtering for the rest.

```javascript copy-safe
const Finder = Application('Finder');
const frontWindow = Finder.windows[0];
const nameValue = frontWindow.name();
frontWindow.bounds = { x: 80, y: 80, width: 1200, height: 900 };

const se = Application('System Events');
const names = se.processes.whose({ _and: [{ name: { _beginsWith: 'S' } }, { visible: true }] }).name();
const raw = se.processes.whose({ visible: true }).properties();
const kept = raw.filter((p) => /^S/.test(p.name) && p.bundleIdentifier);
```

## [06]-[STANDARD_ADDITIONS]

Standard Additions do not bind to an arbitrary target application; JXA admits them only on the executing host through `Application.currentApplication()` with `includeStandardAdditions` set, and AppleScript mirrors the same boundary with `use scripting additions` under explicit `current application` ownership.

```javascript conceptual
const app = Application.currentApplication();
app.includeStandardAdditions = true;
const choice = app.chooseFile({ withPrompt: 'Select input' });
```

```applescript copy-safe
use scripting additions
set hostPath to POSIX path of (path to me)
```

## [07]-[FILE_AND_PROGRESS_TOKENS]

JXA app dictionaries carry `Path` as the file-reference token that crosses Apple events; a droplet handler receives `Path` values, never plain strings, and a bridge conversion to a Foundation type is explicit. `Progress` is a host contract, not a transport: an interactive OSA host surfaces it, while a headless `osascript` caller only ever consumes stdout and stderr.

```javascript copy-safe
ObjC.import('Foundation');
const input = Path('/Users/example/Desktop/input.pdf');
const url = $.NSURL.fileURLWithPath(input.toString());
const name = url.lastPathComponent.js;

function run(argv) {
    Progress.totalUnitCount = argv.length;
    argv.forEach((_, index) => {
        Progress.completedUnitCount = index + 1;
    });
    return argv.length;
}
```

## [08]-[OBJC_NAMESPACE_AND_FFI]

`ObjC.import()` admits a framework into the `$` namespace; every value it returns stays an Objective-C object until `.js`, `ObjC.unwrap()`, or `ObjC.deepUnwrap()` converts it at the boundary, and deep unwrapping belongs at the edge where a Foundation collection becomes a JSON-safe JavaScript value, never mid-pipeline. `ObjC.bindFunction()` admits a C function by declared result and argument types; a pointer-heavy signature routes through `ObjC.Ref` and `ObjC.castRefToObject()` behind an owner-scoped wrapper so a pointer lifetime never leaks into application code.

```javascript copy-safe
ObjC.import('Foundation');
const fm = $.NSFileManager.defaultManager;
const urls = fm.URLsForDirectoryInDomains($.NSDocumentDirectory, $.NSUserDomainMask);
const first = urls.objectAtIndex(0).path.js;
const dict = $.NSDictionary.dictionaryWithObjectsForKeys(['value', 42], ['key', 'count']);
const value = ObjC.deepUnwrap(dict);

ObjC.bindFunction('getpid', ['int', []]);
function run() {
    return $.getpid();
}
```

## [09]-[PROCESS_KERNEL]

JXA shells out through `NSTask`/`NSPipe` when a caller needs exact argv, separated stdout and stderr streams, and a termination contract; `do shell script` remains an AppleScript Standard Addition with shell-string semantics rather than an argv contract. `terminationStatus` alone conflates two distinct outcomes — a normal exit carrying a nonzero code, or death by an uncaught signal — so a caller reads `terminationReason` (`.exit` vs `.uncaughtSignal`) beside the status to know which meaning the numeric value carries.

```javascript copy-safe
ObjC.import('Foundation');
function runTask(launchPath, args) {
    const task = $.NSTask.alloc.init;
    const out = $.NSPipe.pipe;
    task.launchPath = launchPath;
    task.arguments = args;
    task.standardOutput = out;
    task.launch;
    task.waitUntilExit;
    const data = out.fileHandleForReading.readDataToEndOfFile;
    return {
        status: task.terminationStatus,
        reason: task.terminationReason,
        stdout: $.NSString.alloc.initWithDataEncoding(data, $.NSUTF8StringEncoding).js,
    };
}
```

## [10]-[LIBRARY_COMPOSITION]

`Library("name")` loads a compiled script library from the script-library search locations and exposes its handlers as callable functions; a value that is not a handler stays private implementation state. AppleScript composes libraries at compile time through `use script`, and `use scripting additions` stays explicit whenever library resolution changes the inheritance chain.

```javascript copy-safe
const toolbox = Library('toolbox');
toolbox.normalizeName('  A   B  ');
```

```applescript copy-safe
use script "TextKernel"
use scripting additions

on run argv
    return normalizeText(item 1 of argv) of script "TextKernel"
end run
```

## [11]-[PACKAGING_AND_HANDLERS]

`osacompile -o` selects compiled storage by output extension — a flat `worker.scpt`, a `worker.scptd` script bundle carrying `Contents/Resources/Scripts/main.scpt`, or a `Worker.app` applet bundle carrying an executable alongside the same compiled script resource — and LaunchServices and drag-filter code binds to the matching `UTType.appleScript`, `UTType.osaScript`, and `UTType.osaScriptBundle` rows instead of the extension itself. An applet becomes a droplet by implementing a drop handler, `open` in AppleScript or `openDocuments` in JXA, on top of the same idle and lifecycle handler set. `osacompile -s` writes a stay-open applet that keeps its handlers resident; `osacompile -u` activates the startup screen for an applet that carries a user-facing description.

```bash copy-safe
osacompile -l JavaScript -o build/Worker.scpt src/worker.jxa
osacompile -l JavaScript -o build/Worker.scptd src/worker.jxa
osacompile -l JavaScript -o build/Worker.app src/worker.jxa
```

```javascript copy-safe
function run(argv) {
    return 'double-click';
}
function openDocuments(docs) {
    return docs.map((d) => d.toString()).join('\n');
}
function idle() {
    return 300;
}
function quit() {
    return true;
}
```

## [12]-[RUN_ONLY_AND_DRIFT_RECEIPTS]

`osacompile -x` prevents source recovery while execution stays intact — a distribution format, not source control — and the expected decompile failure is `errOSASourceNotAvailable` (`-1756`); a build system retains canonical source and treats the run-only artifact as a disposable output. A build otherwise compiles every source-language row, executes a minimal self-test handler, and decompiles the non-run-only output so a mismatch against the source signals formatter, language, or storage drift before release.

```bash copy-safe
osacompile -x -o dist/Worker.scpt src/worker.applescript
osadecompile dist/Worker.scpt

tmp=$(mktemp -d)
osacompile -l JavaScript -o "$tmp/worker.scpt" src/worker.jxa
osascript "$tmp/worker.scpt" --self-test
osadecompile "$tmp/worker.scpt" > "$tmp/worker.decompiled.jxa"
```

## [13]-[SIGNING_AND_NOTARIZATION]

Flat `.scpt` files and script applets take a normal code signature; distribution signing overwrites a prior signature with a stable identifier. `notarytool` is the only accepted upload path — the notary service rejects `altool` submissions — and the staple bakes into the `.app` bundle itself so a first launch verifies offline; a bare `.zip` is a submission container, not a stapled artifact. A flat `.scpt` carries no bundle identity for the notary ticket to attach to, so durable distribution wraps script logic in a signed, notarized `.app` or command-line tool whose identity owns the Gatekeeper and TCC verdicts.

```bash copy-safe
codesign -s "Developer ID Application: Example Corp" --force --options runtime --entitlements Automation.entitlements dist/Worker.app
ditto -c -k --keepParent dist/Worker.app dist/Worker.zip
xcrun notarytool submit dist/Worker.zip --keychain-profile "AC_NOTARY" --wait
xcrun stapler staple dist/Worker.app
spctl -a -vvv -t install dist/Worker.app
```

## [14]-[AUTOMATION_ENTITLEMENTS]

Hardened-runtime automation prompts require one automation entitlement; an app-sandboxed target additionally scopes cross-app Apple events to a named-target or exception entitlement per receiver. `NSAppleEventsUsageDescription` in `Info.plist` carries the consent-prompt string for a GUI app that sends Apple events.

```xml copy-safe
<dict>
  <key>com.apple.security.automation.apple-events</key>
  <true/>
  <key>com.apple.security.scripting-targets</key>
  <dict>
    <key>com.apple.mail</key>
    <array>
      <string>com.apple.mail.compose</string>
    </array>
  </dict>
</dict>
```

## [15]-[FOUNDATION_EMBEDDING]

`NSAppleScript` is the narrow Foundation bridge: it loads AppleScript source or compiled AppleScript, compiles lazily, executes scripts and supplied Apple events, and surfaces failures through a fixed error-dictionary contract instead of a localized string — but it never selects JXA. `OSAScript` is the language-aware embedding surface instead, and `OSALanguage(forScriptDataDescriptor:)` recovers a script's stored language from its descriptor before construction.

```swift copy-safe
var error: NSDictionary?
let script = NSAppleScript(source: "on run argv\n    return item 1 of argv\nend run")!
let result = script.compileAndReturnError(&error) ? script.executeAndReturnError(&error) : nil

let descriptor = OSAScript.scriptDataDescriptor(withContentsOf: url)!
let language = OSALanguage(forScriptDataDescriptor: descriptor)!
let embedded = try? OSAScript(scriptDataDescriptor: descriptor, from: url, languageInstance: language.sharedLanguageInstance(), using: [])
```

## [16]-[DESCRIPTOR_RICH_ERRORS]

An `OSAScript` error's user info carries a closed set of descriptor-rich keys instead of one flattened string; an error handler preserves them so a caller distinguishes a cancelled dialog from an authorization denial or a coercion fault.

```swift copy-safe
func osaReceipt(_ error: NSError) -> [String: Any] {
    [
        "code": error.code,
        "message": error.userInfo[OSAScriptErrorMessageKey] ?? error.localizedDescription,
        "range": error.userInfo[OSAScriptErrorRangeKey] ?? NSNull()
    ]
}
```

## [17]-[THREAD_CONFINEMENT]

`OSALanguage.isThreadSafe` reports the component's declared thread-safety bit; the AppleScript component reports version 2.8 and returns `true`, as does JavaScript. The bit grants access to `sharedLanguageInstance()`, not concurrent execution of one script object — compilation state and property mutation stay non-reentrant, so a serial lane still owns one `OSALanguageInstance` per language. `NSAppleScript` sits one layer below that bit entirely: it is main-thread-only regardless of the component's thread-safety, because `executeAndReturnError:` spins the run loop while blocked and a nested script send can re-enter the caller.

```swift copy-safe
func makeExecutor(for language: OSALanguage) -> (queue: DispatchQueue, instance: OSALanguageInstance) {
    let instance = language.isThreadSafe
        ? language.sharedLanguageInstance()
        : OSALanguageInstance(language: language)
    return (DispatchQueue(label: "osa.\(language.name ?? "lang")"), instance)
}
```

## [18]-[SCRIPTINGBRIDGE_AND_DICTIONARY_TOOLING]

`SBObject` represents a specifier; `get()` forces the target to return concrete data, and an element array or property stays a reference until a scalar value is requested. Generated glue from `sdp` gives typed subclasses for normal access; `propertyWithCode:` and `sendEvent:id:parameters:` exist as a four-character-code escape hatch for generic dictionary tooling that deliberately operates below generated selectors. `sdef` extracts a target's scripting dictionary from its bundle ahead of `sdp` glue generation, and both executables reject execution on a Command Line Tools-only developer directory until the full Xcode developer directory is selected. `AMAppleScriptAction` exposes `script` as an `OSAScript` property, so Automator action code inspects or replaces the compiled OSA object while `AMAction` owns the surrounding lifecycle.

```swift copy-safe
let app = SBApplication(bundleIdentifier: "com.apple.finder")!
app.timeout = 120
app.activate()
```

```objc copy-safe
id currentTrack = [music propertyWithCode:'pTrk'];
id concrete = [currentTrack get];

@interface AMAppleScriptAction : AMBundleAction
@property (copy, nonatomic, nullable) OSAScript *script;
@end
```

```bash copy-safe
sdef /Applications/Music.app > build/Music.sdef
sdp -fh --basename Music build/Music.sdef
```

## [19]-[CROSS_LANGUAGE_DELEGATION]

`run script ... in "JavaScript"` evaluates a JXA source string through the OSA runtime from inside AppleScript, a targeted bridge for an ObjC-heavy kernel inside an AppleScript library; the boundary carries OSA coercions, not Node semantics, so return values stay descriptor-coercible. JXA delegates the opposite direction through Standard Additions `runScript`, handing a target dictionary that rejects a JXA compound `whose` descriptor to an equivalent AppleScript query instead of forcing a shell escape.

```applescript copy-safe
set js to "ObjC.import('Foundation'); $.NSProcessInfo.processInfo.processName.js"
set hostName to run script js in "JavaScript"
```

```javascript copy-safe
const host = Application.currentApplication();
host.includeStandardAdditions = true;
const source = 'tell application "Finder" to return POSIX path of (files of desktop whose name extension is "scpt") as list';
const paths = host.runScript(source);
```
