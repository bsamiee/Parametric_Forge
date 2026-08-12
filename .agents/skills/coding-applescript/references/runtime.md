# [RUNTIME]

Production automation treats the descriptor boundary as the real API surface, keeping process invocation, output serialization, and packaging policy outside script bodies. AppleScript and JXA sit as language rows on one CLI rail.

| [INDEX] | [SURFACE]      | [CONTRACT]                                                                                                  |
| :-----: | :------------- | :---------------------------------------------------------------------------------------------------------- |
|  [01]   | `osascript`    | Runs `-e` text, one file, or stdin; `-l` selects language, `-s` selects serialization.                      |
|  [02]   | `osacompile`   | Compiles to `.scpt`/`.scptd`/`.app` by output extension; `-x` strips source, `-s`/`-u` set applet behavior. |
|  [03]   | `osadecompile` | Recovers source from compiled data; run-only input returns `-1756`.                                         |
|  [04]   | `osalang`      | Lists installed OSA components with `-L` capability flags.                                                  |

## [01]-[INVOCATION_AND_ARGV]

`osascript` selects exactly one source shape per invocation: concatenated `-e` lines, one program file, or stdin bound only when `-` names the program explicitly; every shape hands the same argv array to `on run argv` in AppleScript and `function run(argv)` in JXA, and the handler owns decoding, type validation, and envelope framing before any return value crosses back to the caller. `osascript -i` opens a line-at-a-time REPL that loads any `-e` or file program without running it before the prompt opens. A script error yields a non-zero exit whose numeric mapping carries no published contract.

```bash copy-safe
osascript -l JavaScript -e 'function run(argv) { return JSON.stringify(argv) }' a b
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

Serialization mode follows the payload's shape. An OSA structure — an AppleScript list, record, or nested value — binds `-s s`, which prints recompilable source-like values; the default `-s h` display form collapses distinct list and record shapes into identical text. A JXA `JSON.stringify` envelope is already text, so its transport rides the default serialization, passing the returned string to stdout verbatim — `-s s` on that path re-quotes the envelope into a source literal and breaks the caller's parse.

`-s e` keeps script errors on stderr; `-s o` routes them to stdout, so a golden test asserts the serialized OSA error text as the primary value, never a specific exit code. Shell quoting stays inside the wrapper and never enters the script body — untrusted data crosses through argv. A JXA `run` handler's return value is the sole stdout payload; every diagnostic routes to stderr through `console.log`, so a caller parses one envelope without interleaved logging.

```bash copy-safe
osascript -s s -e 'return {{"foo", "bar"}, {"foo", {"bar"}}}'
osascript -s h -e 'return {{"foo", "bar"}, {"foo", {"bar"}}}'
actual=$(osascript -s so ./fixture.scpt 2>/tmp/transport.stderr || true)
osascript -l JavaScript ./automation.scpt "$bundle_id" "$payload_json"
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

`osalang -L` returns each installed component's identity and a feature-flag string declaring that component's capability; JXA leaves blank the recording and dialect positions AppleScript alone declares. A generic `scpt` component opens any installed OSA scripting system transparently, but a text source carries no embedded language metadata, so a launcher still passes `-l AppleScript` or `-l JavaScript` explicitly.

```bash copy-safe
osalang -L
```

## [05]-[SPECIFIER_AND_WHOSE]

A JXA property addressing an application object model returns an object specifier until evaluation forces it: parentheses call `get`, assignment sends a `set` Apple event. Specifier chains stay lazy across element traversal — a pipeline sends one event at the terminal property call.

`whose` compiles a specifier into an Apple event test descriptor over the comparison-and-logic keys — `_beginsWith`, `_and`, and peers — evaluated server-side; a target omitting logical-descriptor support rejects a compound test outright rather than degrading to a partial match, so a production filter reduces one field on the target and JavaScript-filters the rest.

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

`Application.currentApplication()` with `includeStandardAdditions` set is the sole JXA binding for Standard Additions, holding them on the executing host; AppleScript mirrors the boundary with `use scripting additions` under explicit `current application` ownership.

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

JXA app dictionaries carry `Path` as the file-reference token that crosses Apple events; a droplet handler receives `Path` values, never plain strings, and a bridge conversion to a Foundation type is explicit. An interactive OSA host surfaces `Progress`, so the value never crosses the `osascript` stdout boundary.

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

JXA shells out through `NSTask` when a caller needs exact argv, separated stdout and stderr, and a termination contract; `do shell script` remains a Standard Addition with shell-string semantics, not an argv contract. File-backed standard handles carry no pipe backpressure, so a single-threaded host reads both streams after `waitUntilExit` and stays deadlock-free by construction — an `NSPipe` read ordered after the wait wedges the host once a chatty child fills the pipe buffer.

`terminationStatus` conflates a normal nonzero exit with death by an uncaught signal, so a caller reads `terminationReason` (`.exit` vs `.uncaughtSignal`) beside the status.

```javascript copy-safe
ObjC.import('Foundation');
function capture(path) {
    $.NSFileManager.defaultManager.createFileAtPathContentsAttributes(path, $.NSData.data, $());
    return $.NSFileHandle.fileHandleForWritingAtPath(path);
}
function drain(handle, path) {
    handle.closeFile;
    const text = $.NSString.stringWithContentsOfFileEncodingError(path, $.NSUTF8StringEncoding, $());
    $.NSFileManager.defaultManager.removeItemAtPathError(path, $());
    return text.js;
}
function runTask(launchPath, args) {
    const base = `${$.NSTemporaryDirectory().js}${$.NSProcessInfo.processInfo.globallyUniqueString.js}`;
    const task = $.NSTask.alloc.init;
    const out = capture(`${base}.out`), err = capture(`${base}.err`);
    task.launchPath = launchPath;
    task.arguments = args;
    task.standardOutput = out;
    task.standardError = err;
    task.launch;
    task.waitUntilExit;
    return {
        status: task.terminationStatus,
        reason: task.terminationReason,
        stdout: drain(out, `${base}.out`),
        stderr: drain(err, `${base}.err`),
    };
}
```

## [10]-[SHELL_BOUNDARY]

`do shell script` starts a fresh, non-login `/bin/sh` per call, receives a noninteractive environment, returns stdout, turns a nonzero exit into an AppleScript error, and interprets command and output text as UTF-8 — shell state never survives past the call that created it. Every command builder carries an absolute executable path and never accepts a pre-joined fragment from a caller.

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

Elevated shell execution runs outside application `tell` blocks or inside `tell me`, since the target application never becomes the parent process for a privileged scripting addition; multi-command elevation sends one quoted script to `/bin/sh -c`, preserving one authentication prompt, one root shell, and one injection boundary. Long data enters a temporary file the rail deletes on every exit, never the command string, and a background command detaches with explicit redirection and a captured PID so AppleScript receives a process handle, never a live pipe.

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
set caught to missing value
try
    set fd to open for access POSIX file tempPath with write permission
    write largeText to fd as «class utf8»
    close access fd
    do shell script "/usr/bin/plutil -lint " & quoted form of tempPath
on error e number n
    try
        close access POSIX file tempPath
    end try
    set caught to {message:e, code:n}
end try
do shell script "/bin/rm -f " & quoted form of tempPath
if caught is not missing value then error (message of caught) number (code of caught)
```

```applescript conceptual
set logPath to POSIX path of (path to temporary items) & "worker.log"
set commandText to "/usr/local/bin/worker > " & quoted form of logPath & " 2>&1 & echo $!"
set workerPID to do shell script commandText
```

## [11]-[LIBRARY_COMPOSITION]

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

## [12]-[PACKAGING_AND_HANDLERS]

`osacompile -o` selects compiled storage by output extension, and LaunchServices and drag-filter code binds the matching `UTType` row. An applet becomes a droplet by implementing a drop handler, `open` in AppleScript or `openDocuments` in JXA, on top of the same idle and lifecycle handler set. `osacompile -s` writes a stay-open applet that keeps its handlers resident; `osacompile -u` activates the startup screen for an applet that carries a user-facing description.

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

## [13]-[RUN_ONLY_AND_DRIFT_RECEIPTS]

`osacompile -x` prevents source recovery while execution stays intact, so a build system retains canonical source and treats the run-only artifact as a disposable output; the expected decompile failure is `errOSASourceNotAvailable` (`-1756`). Decompiling a non-run-only output back to source signals formatter, language, or storage drift on a mismatch.

```bash copy-safe
osacompile -x -o dist/Worker.scpt src/worker.applescript
osadecompile dist/Worker.scpt

tmp=$(mktemp -d)
osacompile -l JavaScript -o "$tmp/worker.scpt" src/worker.jxa
osascript "$tmp/worker.scpt" --self-test
osadecompile "$tmp/worker.scpt" > "$tmp/worker.decompiled.jxa"
```

## [14]-[CROSS_LANGUAGE_DELEGATION]

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
