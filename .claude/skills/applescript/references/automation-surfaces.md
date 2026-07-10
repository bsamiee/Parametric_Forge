# [AUTOMATION_SURFACES]

AppleScript, JXA, compiled OSA scripts, script bundles, Automator actions, Shortcuts, Folder Actions, Mail rule scripts, Script Menu entries, applets, droplets, and stay-open agents form one dispatch surface: file identity, launch host, handler signature, entitlement domain, Apple-event target, and result transport are explicit policy rows a caller resolves before authoring a script, never assumptions folded into prose.

## [01]-[UTTYPE_SPINE]

| [INDEX] | [ROLE]          | [UTI]                                 | [EXTENSION]    | [CONFORMANCE]        |
| :-----: | :-------------- | :------------------------------------ | :------------- | :------------------- |
|  [01]   | Source text     | `com.apple.applescript.text`          | `.applescript` | `public.script`      |
|  [02]   | Compiled script | `com.apple.applescript.script`        | `.scpt`        | `public.data`        |
|  [03]   | Script bundle   | `com.apple.applescript.script-bundle` | `.scptd`       | `com.apple.bundle`   |
|  [04]   | Coarse import   | `public.script`                       | none           | self                 |
|  [05]   | JXA source      | `com.netscape.javascript-source`      | `.js`          | `public.source-code` |
|  [06]   | Saved applet    | `com.apple.application-bundle`        | `.app`         | `com.apple.bundle`   |

`UTType.osaScript` carries the legacy `osas` OSType alongside `com.apple.applescript.script` and conforms to both `public.data` and `public.script`; `UTType.osaScriptBundle` conforms to `com.apple.bundle`, `com.apple.package`, and `public.script` together, because a `.scptd` is a package before it is a script. A saved applet or droplet carries no dedicated script UTI — `com.apple.application-bundle` is the ordinary application identity, and applet-ness is carried by the OSAKit storage type baked into the bundle at compile time plus the applet stub Mach-O at `Contents/MacOS`. JXA source text takes `com.netscape.javascript-source`, but JXA compiled bytecode reuses `com.apple.applescript.script` — the OSA component, not the type identifier, carries the `JavaScript` language dimension, so discrimination between a compiled AppleScript and a compiled JXA script is an `osalang` or component-identifier probe, never a UTI comparison.

```swift conceptual
import UniformTypeIdentifiers

enum ScriptArtifact: String, CaseIterable {
    case source = "com.apple.applescript.text"
    case compiled = "com.apple.applescript.script"
    case bundle = "com.apple.applescript.script-bundle"

    var type: UTType { UTType(rawValue)! }
    var extensionHint: String {
        switch self {
        case .source: "applescript"
        case .compiled: "scpt"
        case .bundle: "scptd"
        }
    }
}
```

## [02]-[EXPORT_AND_PACKAGE_SHAPE]

`UTExportedTypeDeclarations` binds only a tool that mints a new script-adjacent document type; a runner, editor, or workflow action that merely consumes the existing spine declares `CFBundleDocumentTypes` and `LSItemContentTypes` against the system-owned identifiers instead of exporting a parallel UTI. `.scptd` is the polymorphic artifact for embedded resources, script libraries, localized dictionaries, and bundle metadata — a flat `.scpt` earns deploy-target status only when the script owns no resource lookup, no embedded library, and no localized asset. `osacompile -o` selects package shape from the output extension: `.app` produces an applet or droplet, `.scptd` produces a bundled compiled script, and any other extension produces a flat compiled script. `osadecompile` is the review rail for a compiled artifact — a release pipeline stores `.applescript` as the source-control form and decompiles the shipped output during verification to prove the installed artifact still maps to reviewed text; execute-only output from `osacompile -x` removes readable source from the compiled artifact and is a distribution boundary the source-control rail never adopts as its own storage form.

```bash copy-safe
osacompile -l AppleScript -o build/Task.scpt source/Task.applescript
osacompile -l AppleScript -o build/Task.scptd source/Task.applescript
osacompile -l JavaScript -o build/Task.app source/Task.jxa
osadecompile build/Task.scpt
```

## [03]-[STORAGE_TYPES_AND_OPTIONS]

Every `osacompile` surface flag is an OSAKit storage-option row, so a programmatic builder calls `OSAScript.compiledDataForType:usingStorageOptions:error:` directly instead of shelling to `osacompile`. The format axis is five storage types:

- `OSAStorageScriptType` binds `.scpt`
- `OSAStorageScriptBundleType` binds `.scptd`
- `OSAStorageApplicationType` binds a flat applet
- `OSAStorageApplicationBundleType` binds a bundled applet
- `OSAStorageTextType` binds decompiled source

The trust and lifecycle axis is three storage options composed as a bitmask:

- `OSAPreventGetSource` binds the `-x` execute-only flag
- `OSAStayOpenApplet` binds a persistent-agent applet
- `OSAShowStartupScreen` binds the startup-screen prompt

The `-t`/`-c` type and creator flags and the `-d`/`-r` resource-fork flags are storage-type selection expressed through the CLI rather than a separate axis.

```objc conceptual
NSData *data = [script compiledDataForType:OSAStorageScriptBundleType
                         usingStorageOptions:(OSAPreventGetSource | OSAStayOpenApplet)
                                       error:&failure];
```

## [04]-[OSA_HOST_DISPATCH]

`osalang -L` is the installed-language census; the string passed to `osascript -l` and `osacompile -l` comes from that census, so `JavaScript` and `AppleScript` literals are policy values selected from discovery, never hardcoded assumptions. `osascript -s s` is the machine-output rail because it emits recompilable source form for AppleScript values; `osascript -s h` is an operator rail because lists and records collapse into ambiguous display text. `osascript -s o` routes script errors to stdout for golden-file testing, while the default `-s e` preserves stdout as result-only IPC — a harness declares the error channel per test mode, never per call site. A stdin script that needs arguments runs as `osascript - scriptArg...`; filename-free stdin consumes the script body and leaves no positional path slot for the argument vector.

Four ingress shapes reach automation code, and a reusable core normalizes all four before domain logic runs: AppleScript `run argv` receives a string list from `osascript`; Automator and Shortcuts `run` receive `{input, parameters}`; a droplet receives `open` with a list of Finder aliases; a JXA droplet receives `openDocuments` with a list of `Path` values.

```applescript conceptual
on normalize(payload)
	if class of payload is list then return payload
	return {payload}
end normalize

on run argv
	return handleWork(normalize(argv), {host:"osascript"})
end run

on open droppedItems
	return handleWork(normalize(droppedItems), {host:"droplet"})
end open
```

## [05]-[EVENT_TIMEOUT_AND_JXA_BOUNDARY]

`ignoring application responses` is a fire-and-forget Apple-event boundary; it never wraps a command whose result, error, or object specifier feeds later logic, and any such command nests back under `considering application responses`. `with timeout of n seconds` binds a command sent to an application object, not a command handled by the current script — a long application command carries an explicit timeout row, while local shell and Foundation work carries its own process or API timeout. A JXA script that needs Standard Additions sets `includeStandardAdditions` at the host boundary; application automation through object specifiers and Foundation bridge calls stay separate owner rows because JXA specifiers, Objective-C objects, and JavaScript values obey different coercion rules.

```javascript conceptual
ObjC.import('Foundation');

const app = Application.currentApplication();
app.includeStandardAdditions = true;

function run(input, parameters) {
    const values = Array.isArray(input) ? input : [input];
    return values.map(String).join('\n');
}
```

## [06]-[BUNDLE_AND_LIBRARY_OWNERSHIP]

A script bundle places executable OSA code at `Contents/Resources/Scripts/main.scpt`; resource lookup uses bundle-relative locations, and path construction inside the bundle never assumes a Finder-visible package layout. A script library loads from `~/Library/Script Libraries/`, `/Library/Script Libraries/`, or the `Resources` folder inside the calling script or app bundle — an applet depending on a private library vendors it inside its own bundle and resolves it by name from the resource domain. AppleScript reaches a library through `tell script "Library Name"`; JXA reaches the same library through `Library("Library Name")`; a cross-language library exposes stable handler names and restricts payloads to OSA-coercible values. Script Editor's bundle contents pane is the authoring surface for identifier, version, copyright, description, and resources, while a build rail mutates those same values through `Info.plist` and bundle files directly and reopens Script Editor only for event-log and dictionary inspection. The event log is the Apple-event trace rail: `log` inside an application `tell` block targets the application unless redirected with `tell me to log`, and JXA traces through `console.log()`.

## [07]-[AUTOMATOR_SURFACES]

Automator's `Run AppleScript` action receives and returns `com.apple.applescript.object` list payloads through `on run {input, parameters}`; the action body is a workflow transform, so it returns the downstream payload explicitly rather than falling through. `Run JavaScript` uses `function run(input, parameters)`, and JXA action code returns ordinary JavaScript values only when the next action in the chain can coerce them through the OSA object bridge. `AMAppleScriptAction` hosts an `OSAScript` instance compiled from the action source, so a custom Automator action owns action UI, parameter storage, accepted and provided types, and script execution as one bundle contract.

```applescript conceptual
on run {input, parameters}
	set rows to {}
	repeat with itemRef in input
		set end of rows to itemRef as text
	end repeat
	return rows
end run
```

## [08]-[SHORTCUTS_SURFACES]

The global `Allow Running Scripts` switch under Shortcuts Advanced settings gates five privileged bridge actions — Run AppleScript, Run Shell Script, Run JavaScript for Mac Automation, Run JavaScript on Web Page, and Run Script Over SSH — which execute with full user privileges outside normal action guardrails. TCC for Automation, Files, and Accessibility still attaches to the responsible process, so the same shortcut earns different privacy prompts and different persistence across an app launch, a CLI invocation, and a background-automation launch context; a headless run that meets an unanswered consent prompt blocks rather than fails. External Shortcuts automation enters through the `shortcuts` CLI or the `Shortcuts Events` scripting dictionary. The CLI exposes four verbs — `run`, `list`, `view`, `sign` — and `shortcuts run` owns shell IPC with repeatable `--input-path` (accepting `-` for stdin and shell globs), `--output-path` (accepting `-`), and `--output-type` (a UTI, inferred from the output filename when omitted). `tell application "Shortcuts Events" to run shortcut ... with input ...` dispatches in the background without fronting the Shortcuts UI, while `tell application "Shortcuts"` launches the app. `shortcuts sign --mode anyone|people-who-know-me -i in.shortcut -o out.shortcut` is the distribution gate: `anyone` notarizes through iCloud for open sharing, `people-who-know-me` signs locally for contact-gated import, and an unsigned `.shortcut` file does not import on a hardened install.

```applescript conceptual
tell application "Shortcuts Events"
	run shortcut "Normalize Intake" with input {"alpha", "beta"}
end tell
```

```bash copy-safe
shortcuts run "Normalize Intake" --input-path - --output-path - --output-type public.plain-text
shortcuts sign --mode people-who-know-me -i Intake.shortcut -o Intake-signed.shortcut
```

## [09]-[APP_INTENTS_SUCCESSOR]

App Intents is the sanctioned automation successor, reached only through an enclosing Shortcut — no CLI verb invokes an App Intent directly, and no AppleScript-to-intent bridge exists. Any app shipping App Intents contributes Shortcuts actions that also run from Siri, Spotlight, and directly from Spotlight as first-class results; the Apple Intelligence `Use Model` action reasons over app-exposed entities inside the same Shortcut. A shortcut composes a `Run AppleScript` action alongside App-Intent-derived actions in one flow, so an AppleScript rail reaches App Intents by invoking that enclosing shortcut through `Shortcuts Events` or `shortcuts run`, never by calling an intent as a standalone target. Personal automations add folder-change, external-drive, Wi-Fi, display, and app-launch triggers on the Mac, replacing Folder Actions and stay-open pollers wherever the trigger is a first-class Shortcuts event; the OSA hosts remain the owning surface for triggers Shortcuts does not model and for latency-sensitive in-process work.

## [10]-[FOLDER_ACTIONS_STAYOPEN_DROPLETS]

A Folder Action is a handler contract, not a callable API: every handler parameter is required, no handler returns a value, and the attached folder rides as the direct parameter.

```applescript conceptual
on adding folder items to thisFolder after receiving addedItems
	repeat with addedItem in addedItems
		my processAddedItem(thisFolder, addedItem)
	end repeat
end adding folder items to
```

A hot folder drains itself or moves accepted work into a terminal subfolder; leaving processed files in the watched root repeats work and degrades Folder Actions throughput. `moving folder window for` is an opt-in contract only, unreliable across installed hosts — window-position automation belongs in a stay-open app or an explicit Finder script until host testing proves the event fires. A stay-open app owns periodic work through `idle`, which returns the next polling interval in seconds, and releases resources in `quit`.

```applescript conceptual
property pending : {}

on idle
	set pending to my drainQueue(pending)
	return 15
end idle

on quit
	set pending to {}
	continue quit
end quit
```

A droplet routes Finder drops through AppleScript `open` or JXA `openDocuments`, and its root `run` path stays a diagnostic entrypoint that calls the same processing kernel against a manually selected file. Script Menu runs compiled scripts, applets, shell scripts, and Automator workflows from `~/Library/Scripts/` and optionally `/Library/Scripts/`; application-specific entries live under `Scripts/Applications/<ApplicationName>` and surface only while that application is frontmost.

## [11]-[MAIL_RULE_SCRIPTS]

A Mail rule script implements `perform mail action with messages`, whose direct parameter is a message list; `in mailboxes` appears for a menu-invoked script and `for rule` appears for a rule-invoked script. The handler wraps in `using terms from application "Mail"` so compilation succeeds outside Mail while preserving Mail's own command terminology and parameter labels.

```applescript conceptual
using terms from application "Mail"
	on perform mail action with messages theseMessages for rule theRule
		tell application "Mail"
			repeat with eachMessage in theseMessages
				set read status of eachMessage to true
			end repeat
		end tell
	end perform mail action with messages
end using terms from
```

## [12]-[EMBEDDING_BOUNDARIES]

Foundation scripting support exposes app scriptability through `NSScriptCommand`, `NSScriptObjectSpecifier`, `NSScriptClassDescription`, `NSScriptExecutionContext`, and a `.sdef` dictionary — a Cocoa app's scriptability is a model contract, never a string-command adapter. `NSAppleScript` and OSAKit's `OSAScript` are host-side execution boundaries: both compile and execute OSA code, return `NSAppleEventDescriptor`, and report structured error dictionaries, without turning AppleScript into a typed Swift API. Scripting Bridge belongs to a native client that wants Objective-C messaging over a scriptable application's dictionary; generated headers and `.sdef` remain the contract source rather than the bridge itself. `OSACopyScriptingDefinitionFromURL(CFURLRef, SInt32 modeFlags, CFDataRef *sdef)`, part of OpenScripting under `Carbon/Carbon.h`, is the runtime dictionary rail that a Command Line Tools-only host reaches without the full-Xcode requirement of the `sdef`/`sdp` executables. `modeFlags` is reserved as `kOSAModeNull`, the returned `CFData` is `.sdef` XML, and the call auto-synthesizes a dictionary from legacy `'aete'` resources and `scriptSuite`/`scriptTerminology` plist pairs. TCC attaches automation consent to the sending process, so running identical script text through Script Editor, `osascript`, Automator, Shortcuts, a signed applet, or an embedding host earns a distinct privacy prompt and a distinct persistence record for each sender.

```swift conceptual
var sdef: Unmanaged<CFData>?
let status = OSACopyScriptingDefinitionFromURL(appURL as CFURL, 0, &sdef)
guard status == noErr, let xml = sdef?.takeRetainedValue() as Data? else {
    throw DictionaryError(status)
}
```

## [13]-[HOST_DISPATCH_MATRIX]

| [INDEX] | [HOST]             | [ENTRY]                     | [PAYLOAD]         | [EXIT]           |
| :-----: | :----------------- | :-------------------------- | :---------------- | :--------------- |
|  [01]   | `osascript`        | `run argv`                  | string list       | stdout status    |
|  [02]   | Automator          | `run {input, parameters}`   | OSA object list   | OSA object list  |
|  [03]   | Shortcuts action   | `run(input, parameters)`    | shortcut input    | action output    |
|  [04]   | Shortcuts external | `shortcuts run`             | typed output      | CLI result       |
|  [05]   | Droplet            | `open` handler              | Finder aliases    | none             |
|  [06]   | Folder Action      | folder handlers             | folder parameters | none             |
|  [07]   | Mail rule          | `perform mail action`       | message list      | none             |
|  [08]   | Stay-open agent    | `idle` `quit`               | script properties | next interval    |
|  [09]   | Script Menu        | file launch                 | script app shell  | host-defined     |
|  [10]   | Native host        | `NSAppleScript` `OSAScript` | source data event | descriptor error |

## [14]-[PLATFORM_POSTURE]

The Open Scripting Architecture is stable but frozen: AppleScript, JXA, `osascript`, `osacompile`, and Automator all ship and function, none carry a deprecation notice, and none receive language investment. App Intents is the sanctioned successor surface, reaching users through Shortcuts, Siri, and Spotlight, with no CLI verb and no AppleScript command invoking an intent directly — the only scriptable rail into an intent is an enclosing Shortcut through `Shortcuts Events` or `shortcuts run`. Existing scriptable-app control stays on OSA because most apps expose richer dictionaries than their App Intents surface, while new first-party automation targets App Intents and composes OSA only through Shortcuts. The freeze erodes at legacy edges rather than at the core language or the type spine: `tell application "iTunes"` no longer resolves to a running target, Script Editor fails to open some resource-fork-stored scripts and raises `errOSADataFormatObsolete`, and error retrieval on a faulted event stalls a fault path for minutes before returning. Each of these is a packaging and toolchain fact a release rail absorbs by recompiling and re-testing on a current host, never a change to handler contracts, the UTType spine, or the host dispatch matrix.
