# [EMBEDDING]

Foundation embedding hosts Open Scripting Architecture inside a Cocoa or Objective-C process, binding a Swift or Objective-C host directly to the Apple Event ABI.

## [01]-[DESCRIPTOR_CONSTRUCTION_AND_WALK]

`AEKeyword`, `AEEventClass`, `AEEventID`, `DescType`, and `OSType` are 32-bit integers folded from four ASCII bytes; `NSAppleEventDescriptor(bundleIdentifier:)` binds a target through Launch Services identity, immune to path relocation and PID churn, while `descriptorWithApplicationURL:` binds one specific bundle instance or an `eppc:` remote target instead. A parameter carries command payload keyed by `AEKeyword` under `paramDescriptor(forKeyword:)`; an attribute carries transport metadata under `attributeDescriptor(forKeyword:)`. `isRecordDescriptor` gates a lossless field walk through `numberOfItems`, `keywordForDescriptor(at:)`, and `descriptor(forKeyword:)`; descriptor lists are one-based, so `insert(_:at:)` called with `0` appends and a read walks `1...numberOfItems`.

```swift conceptual
import Carbon
import Foundation
func fourCharCode(_ value: StaticString) -> OSType {
    precondition(value.utf8CodeUnitCount == 4)
    return value.withUTF8Buffer { $0.reduce(0) { ($0 << 8) | OSType($1) } }
}
func targetedEvent(bundleIdentifier: String, eventClass: AEEventClass, eventID: AEEventID) -> NSAppleEventDescriptor {
    NSAppleEventDescriptor(eventClass: eventClass, eventID: eventID, targetDescriptor: .init(bundleIdentifier: bundleIdentifier),
        returnID: AEReturnID(kAutoGenerateReturnID), transactionID: AETransactionID(kAnyTransactionID))
}
func recordFields(_ descriptor: NSAppleEventDescriptor) -> [(AEKeyword, NSAppleEventDescriptor)] {
    guard descriptor.isRecordDescriptor else { return [] }
    return (1...descriptor.numberOfItems).compactMap { index in
        let keyword = descriptor.keywordForDescriptor(at: index)
        return descriptor.descriptor(forKeyword: keyword).map { (keyword, $0) }
    }
}
func descriptorList(_ values: [String]) -> NSAppleEventDescriptor {
    values.reduce(.list()) { list, value in list.insert(.init(string: value), at: 0); return list }
}
```

## [02]-[DESCRIPTOR_LIFECYCLE_AND_COERCION]

`init(aeDescNoCopy:)` transfers disposal of a raw `AEDesc` to Foundation, so a descriptor borrowed from a Carbon callback carries a duplicate through `AEDuplicateDesc` first. A reply descriptor exists on every dispatched event; its `descriptorType` reads `typeNull` exactly when the sender requested none, and only past that check does a handler write `keyErrorNumber` and `keyErrorString`. `coerceToDescriptorType:` is the one-shot Cocoa-side coercion; a standing custom coercion is Carbon Apple Event Manager territory, where `AEInstallCoercionHandler(fromType:toType:handler:refcon:fromTypeIsDesc:isSysHandler:)` registers a thread-safe handler in the calling process's own application coercion table for every event it sends or receives, and `isSysHandler: true` targets a system-wide table that services no handler.

```objc conceptual
static NSAppleEventDescriptor *WrapOwnedAEDesc(AEDesc source) {
    AEDesc copy = { typeNull, NULL };
    return AEDuplicateDesc(&source, &copy) == noErr ? [[NSAppleEventDescriptor alloc] initWithAEDescNoCopy:&copy] : nil;
}
static void Reject(NSAppleEventDescriptor *reply, SInt32 number, NSString *message) {
    if (reply.descriptorType == typeNull) return;
    [reply setParam:[NSAppleEventDescriptor descriptorWithInt32:number] forKeyword:keyErrorNumber];
    [reply setParam:[NSAppleEventDescriptor descriptorWithString:message] forKeyword:keyErrorString];
}
static OSErr CoerceHexToInteger(const AEDesc *from, DescType toType, SRefCon refcon, AEDesc *result) { return AECoercePtr(typeSInt32, NULL, 0, toType, result); }
static void InstallHexCoercion(void) { AEInstallCoercionHandler('hex ', typeSInt32, NewAECoerceDescUPP(CoerceHexToInteger), 0, true, false); }
```

## [03]-[HANDLER_INVOCATION_AND_ERRORS]

`NSAppleScript.executeAppleEvent(_:error:)` invokes a compiled script's named handler with event class `kASAppleScriptSuite`, event ID `kASSubroutineEvent`, the handler name under `keyASSubroutineName`, and arguments under `keyDirectObject` as a descriptor list. A failure surfaces as an `NSDictionary`, never `NSError`, carrying the same keys across compile and execute faults. `OSAScript` raises its own constant family instead — `OSAScriptErrorMessageKey` and `OSAScriptErrorRangeKey` in the error's user info — so a host bridging both surfaces reads each under its own keys.

| [INDEX] | [KEY]                            | [CARRIES]                           |
| :-----: | :------------------------------- | :---------------------------------- |
|  [01]   | `NSAppleScriptErrorMessage`      | full diagnostic text                |
|  [02]   | `NSAppleScriptErrorBriefMessage` | condensed diagnostic text           |
|  [03]   | `NSAppleScriptErrorNumber`       | negative Apple Event Manager status |
|  [04]   | `NSAppleScriptErrorAppName`      | offending application name          |
|  [05]   | `NSAppleScriptErrorRange`        | source range of the fault           |

```swift conceptual
func callHandler(_ script: NSAppleScript, name: String, arguments: [NSAppleEventDescriptor]) throws -> NSAppleEventDescriptor {
    let event = NSAppleEventDescriptor(eventClass: AEEventClass(kASAppleScriptSuite), eventID: AEEventID(kASSubroutineEvent),
        targetDescriptor: nil, returnID: AEReturnID(kAutoGenerateReturnID), transactionID: AETransactionID(kAnyTransactionID))
    event.setParam(.init(string: name), forKeyword: keyASSubroutineName)
    event.setParam(arguments.reduce(.list()) { $0.insert($1, at: 0); return $0 }, forKeyword: keyDirectObject)
    var runError: NSDictionary?
    guard let result = script.executeAppleEvent(event, error: &runError) else { throw AppleScriptFailure(runError) }
    return result
}
```

## [04]-[OSASCRIPT_STORAGE_AND_AUTOMATOR]

`OSAScript` owns the language instance, storage options, source, handler execution, and compiled persistence that `NSAppleScript` keeps private. `OSALanguage(forScriptDataDescriptor:)` recovers a stored script's own language from its data descriptor, so `OSAScript(scriptDataDescriptor:from:languageInstance:using:)` reconstructs a compiled artifact under its authoring component rather than AppleScript by assumption. `executeHandler(withName:arguments:error:)` returns an `NSAppleEventDescriptor` and `executeAndReturnDisplayValue(_:)` returns the human-readable form. `compiledData(forType:usingStorageOptions:)` and `writeToURL:ofType:usingStorageOptions:` serialize the compiled artifact into a storage container, and the storage options are the programmatic form of the compiler switches: `OSAPreventGetSource` seals an execute-only artifact, `OSAStayOpenApplet` writes a stay-open applet, `OSACompileIntoContext` compiles into an existing script context, and `OSADontSetScriptLocation` suppresses the script's file-origin binding, which breaks `path to me` inside the compiled script. `AMAppleScriptAction.script` is an `OSAScript` slot, so an Automator AppleScript action shares this compile, execution, and storage model, and `OSAScriptController` binds an `OSAScriptView`, result text, the selected `OSALanguage`, and `compileScript:`/`runScript:` controller actions for a host shipping an OSA editor, recorder, or runner pane.

| [INDEX] | [CONSTANT]                        | [CONTAINER]                    |
| :-----: | :-------------------------------- | :----------------------------- |
|  [01]   | `OSAStorageScriptType`            | flat compiled `.scpt`          |
|  [02]   | `OSAStorageScriptBundleType`      | `.scptd` bundle with resources |
|  [03]   | `OSAStorageApplicationType`       | flat script applet             |
|  [04]   | `OSAStorageApplicationBundleType` | applet bundle with resources   |
|  [05]   | `OSAStorageTextType`              | plain source text              |

```objc conceptual
static OSAScript *Compile(NSString *source, NSURL *origin, OSALanguageInstance *instance, NSDictionary **info) {
    OSAScript *script = [[OSAScript alloc] initWithSource:source fromURL:origin languageInstance:instance usingStorageOptions:OSANull];
    return [script compileAndReturnError:info] ? script : nil;
}
static BOOL WriteCompiledBundle(OSAScript *script, NSURL *url, NSDictionary **info) {
    return [script writeToURL:url ofType:OSAStorageScriptBundleType usingStorageOptions:OSAPreventGetSource error:info];
}
@interface TransformAction : AMAppleScriptAction
@end
@implementation TransformAction
- (id)runWithInput:(id)input fromAction:(AMAction *)action error:(NSDictionary **)errorInfo {
    return [self.script executeHandlerWithName:@"transform" arguments:@[ input ?: [NSNull null] ] error:errorInfo] ?: input;
}
@end
```

## [05]-[THREAD_CONFINEMENT]

`NSAppleScript` executes only on the main thread, and `@synchronized` around a call does not lift the restriction: `executeAndReturnError:` spins the run loop while blocked, so a script that itself sends Apple events re-enters the calling code before the outer call returns. `OSALanguage.isThreadSafe` reports the component's declared thread-safety bit, which authorizes sharing `sharedLanguageInstance()` across callers and never makes one script object safe to run concurrently — compilation state and property mutation stay non-reentrant, so one serial queue owns each `OSALanguageInstance` for its lifetime.

```swift conceptual
actor ScriptExecutor {
    private let language = OSALanguage(forName: "AppleScript")!
    private lazy var instance = language.isThreadSafe
        ? language.sharedLanguageInstance() : OSALanguageInstance(language: language)
    func run(_ source: String, handler: String, args: [NSAppleEventDescriptor]) throws -> NSAppleEventDescriptor {
        let script = OSAScript(source: source, language: language)
        var info: NSDictionary?
        guard script.compileAndReturnError(&info), let result = script.executeHandler(withName: handler, arguments: args, error: &info)
        else { throw AppleScriptFailure(info) }
        return result
    }
}
```

## [06]-[EVENT_MANAGER_DISPATCH_AND_SUSPENSION]

`NSAppleEventManager.setEventHandler(_:andSelector:forEventClass:andEventID:)` dispatches an incoming event to a selector shaped `(event:reply:)`. `suspendCurrentAppleEvent()` detaches the active event for async completion, `setCurrentAppleEventAndReplyEvent(withSuspensionID:)` rebinds thread-local command context on the completing thread, and `resume(withSuspensionID:)` invalidates the token and releases the reply. `dispatchRawAppleEvent(_:withRawReply:handlerRefCon:)` routes an already-received raw `AppleEvent` through the registered handler table and never sends to another process.

```swift conceptual
final class EventRouter: NSObject {
    @objc func handle(event: NSAppleEventDescriptor, reply: NSAppleEventDescriptor) {
        let manager = NSAppleEventManager.shared()
        guard let suspension = manager.suspendCurrentAppleEvent() else { return }
        Task.detached {
            manager.setCurrentAppleEventAndReplyEvent(withSuspensionID: suspension)
            let suspendedReply = manager.replyAppleEvent(forSuspensionID: suspension)
            suspendedReply.setParam(.init(string: "ready"), forKeyword: keyDirectObject)
            manager.resume(withSuspensionID: suspension)
        }
    }
}
```

## [07]-[SCRIPTABLE_APP_SDEF_AND_COMMANDS]

A scriptable app declares `NSAppleScriptEnabled` true, names its `OSAScriptingDefinition`, and ships the `.sdef` inside the bundle resources — the one dictionary AppleScript, JXA, Cocoa Scripting, and ScriptingBridge all consume; `<cocoa key="...">` binds terminology to key-value coding, where an `element` maps an array-backed class-extension, a `property` maps a scalar or to-one value, and a command's `<cocoa key>` parameter matches the key `NSScriptCommand.arguments` exposes. A custom verb subclasses `NSScriptCommand` and overrides `performDefaultImplementation()`; a validation failure sets `scriptErrorNumber` and `scriptErrorString` and returns `nil`.

```xml template
<?xml version="1.0" encoding="UTF-8"?><!DOCTYPE dictionary SYSTEM "file://localhost/System/Library/DTDs/sdef.dtd">
<dictionary title="Shape Terminology"><suite name="Shape Suite" code="Shap" description="Shape automation.">
    <class-extension extends="application"><element type="shape" access="rw"><cocoa key="scriptableShapes"/></element></class-extension>
    <command name="export" code="ShapExpr" description="Export a shape.">
      <cocoa class="ShapeExportCommand"/>
      <access-group identifier="shape.export"/>
      <direct-parameter type="specifier" requires-access="r" description="The shape to export."/>
      <parameter name="to" code="kfil" type="file" description="Destination file."><cocoa key="DestinationURL"/></parameter>
    </command>
</suite></dictionary>
```

```swift conceptual
final class ShapeExportCommand: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        guard let destination = evaluatedArguments?["DestinationURL"] as? URL, let shape = evaluatedReceivers as? Shape else {
            scriptErrorNumber = NSArgumentsWrongScriptError; return nil
        }
        suspendExecution()
        Task.detached { [weak self] in self?.resumeExecution(withResult: try? ShapeExporter.write(shape, to: destination)) }
        return nil
    }
}
@objcMembers final class Shape: NSObject {
    dynamic var title = ""
    override var scriptingProperties: [String: Any]? {
        get { ["title": title] }
        set { title = newValue?["title"] as? String ?? title }
    }
}
```

## [08]-[OBJECT_SPECIFIER_TAXONOMY_AND_FAST_PATH]

A scriptable object publishes its own address through `objectSpecifier`, choosing whichever concrete `NSScriptObjectSpecifier` subclass keeps it addressable after the container reorders — a stable unique ID over a volatile index. `NSPositionalSpecifier` subclasses `NSObject`, naming an insertion position paired with a container specifier for a `make ... at` command. A container overrides `indicesOfObjects(byEvaluating:)` to serve lookups from an existing index; an empty array means no match, and `nil` delegates to the default evaluator.

| [INDEX] | [SPECIFIER]           | [SELECTS_BY]               |
| :-----: | :-------------------- | :------------------------- |
|  [01]   | `NSIndexSpecifier`    | absolute or relative index |
|  [02]   | `NSNameSpecifier`     | name                       |
|  [03]   | `NSUniqueIDSpecifier` | stable identifier          |
|  [04]   | `NSRangeSpecifier`    | `items X thru Y`           |
|  [05]   | `NSWhoseSpecifier`    | qualified `whose` test     |
|  [06]   | `NSMiddleSpecifier`   | middle element             |
|  [07]   | `NSRandomSpecifier`   | random element             |
|  [08]   | `NSPropertySpecifier` | to-one property            |

```swift conceptual
override var objectSpecifier: NSScriptObjectSpecifier? {
    guard let document, let container = document.objectSpecifier,
          let classDescription = NSScriptClassDescription(for: ShapeDocument.self) else { return nil }
    return NSUniqueIDSpecifier(containerClassDescription: classDescription, containerSpecifier: container,
        key: "scriptableShapes", uniqueID: persistentID)
}
override func indicesOfObjects(byEvaluating specifier: NSScriptObjectSpecifier) -> [NSNumber]? {
    guard specifier.key == "scriptableShapes", let unique = specifier as? NSUniqueIDSpecifier,
          let id = unique.uniqueID as? String else { return nil }
    return indexByID[id].map { [NSNumber(value: $0)] } ?? []
}
```

## [09]-[REGISTRY_AND_USER_TASKS]

`NSScriptSuiteRegistry` loads `.scriptSuite` declaration dictionaries, registers class and command descriptions, and emits AETE data; runtime registry loading serves plugin-style scriptability, while ordinary bundle resources register automatically. `NSUserScriptTask` and its `NSUserAppleScriptTask`, `NSUserAutomatorTask`, and `NSUserUnixTask` subclasses execute a user-supplied script out of process from `applicationScriptsDirectory`, which a sandboxed app only reads; each task instance executes exactly once, and `NSUserAppleScriptTask.execute(withAppleEvent:)` takes `nil` for a plain `run` or a fully formed handler-invocation event. A script run through `NSUserAppleScriptTask` executes outside the app process and carries its own TCC identity.

```swift conceptual
func runUserHandler(scriptURL: URL, handler: String, argument: String) async throws -> NSAppleEventDescriptor? {
    let task = try NSUserAppleScriptTask(url: scriptURL)
    let event = NSAppleEventDescriptor(eventClass: AEEventClass(kASAppleScriptSuite), eventID: AEEventID(kASSubroutineEvent),
        targetDescriptor: nil, returnID: AEReturnID(kAutoGenerateReturnID), transactionID: AETransactionID(kAnyTransactionID))
    event.setParam(.init(string: handler), forKeyword: keyASSubroutineName)
    event.setParam(descriptorList([argument]), forKeyword: keyDirectObject)
    return try await withCheckedThrowingContinuation { continuation in
        task.execute(withAppleEvent: event) { result, error in
            error.map { continuation.resume(throwing: $0) } ?? continuation.resume(returning: result) }
    }
}
```

## [10]-[SCRIPTINGBRIDGE_AND_DICTIONARY_TOOLING]

`sdef` extracts a target's dictionary and `sdp -fh --basename Name` emits Objective-C glue that a Swift caller imports through a bridging header; both executables demand a full Xcode developer directory and refuse a Command Line Tools-only selection. A caller configures `delegate`, `sendMode`, `timeout`, and `launchFlags` on the resulting `SBApplication` instance. `SBObject` and `SBElementArray` carry an object specifier lazily until `get()` forces evaluation, so chained property access composes references and only the terminal call produces a concrete Foundation value, while `propertyWithCode:` and `sendEvent(_:id:parameters:)` are the four-character-code escape hatch for a property or event shape the generated header loses. `OSACopyScriptingDefinitionFromURL(CFURLRef, SInt32 modeFlags, CFDataRef *sdef)` is the runtime dictionary rail a Command Line Tools-only host reaches without those executables: `modeFlags` is reserved as `kOSAModeNull`, the returned `CFData` is `.sdef` XML read from a local bundle or an `eppc:` remote target, and the call auto-synthesizes a dictionary from a legacy `'aete'` resource or a `scriptSuite`/`scriptTerminology` plist pair where no native `.sdef` exists, feeding the same `sdp -fh` header generation.

```objc conceptual
@interface BridgeErrors : NSObject <SBApplicationDelegate>
@end
@implementation BridgeErrors
- (id)eventDidFail:(const AppleEvent *)event withError:(NSError *)error { return nil; }
@end
static TargetAppApplication *TargetApp(void) {
    TargetAppApplication *target = [SBApplication applicationWithBundleIdentifier:@"com.example.TargetApp"];
    target.delegate = [BridgeErrors new]; target.sendMode = kAEWaitReply;
    return target;
}
static id SendRawVerb(SBApplication *app, AEEventClass cls, AEEventID eid, AEKeyword key, id v) { return [app sendEvent:cls id:eid parameters:key, v, 0]; }
static NSData *CopySDEF(NSURL *url, OSAError *status) {
    CFDataRef data = NULL;
    *status = OSACopyScriptingDefinitionFromURL((__bridge CFURLRef)url, 0, &data);
    return *status == noErr ? CFBridgingRelease(data) : nil;
}
```
