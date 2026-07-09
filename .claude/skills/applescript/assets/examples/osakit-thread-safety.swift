// Pattern : One serial OSALanguageInstance per lane behind a Swift actor. The component
//           thread-safe bit permits a shared instance, but script state is not reentrant and
//           NSAppleScript is main-thread-only — executeAndReturnError: spins the run loop while
//           blocked, so a nested send re-enters the caller before it returns.
import Foundation
import OSAKit

struct ScriptFailure: Error {
    let info: NSDictionary?
    init(_ info: NSDictionary?) { self.info = info }
}

// The actor confines every compile and execute to one serial context, so the run-loop
// reentrancy a blocked send opens cannot corrupt a second in-flight script. isThreadSafe
// governs shared-versus-dedicated instance selection, never whether execution fans across
// threads: the stock AppleScript and JavaScript components report true and take the shared
// instance, a third-party component that declines the bit takes a dedicated one, and either
// lane stays serial.
actor ScriptExecutor {
    private let language: OSALanguage
    private lazy var instance: OSALanguageInstance =
        language.isThreadSafe ? language.sharedLanguageInstance() : OSALanguageInstance(language: language)

    init(languageName: String = "AppleScript") {
        self.language = OSALanguage(forName: languageName)!
    }

    func run(_ source: String, handler: String, arguments: [NSAppleEventDescriptor]) throws -> NSAppleEventDescriptor {
        let script = OSAScript(source: source, language: language)
        var info: NSDictionary?
        guard script.compileAndReturnError(&info),
              let result = script.executeHandler(withName: handler, arguments: arguments, error: &info)
        else { throw ScriptFailure(info) }
        return result
    }
}

// Off-main execution never runs a background-queue NSAppleScript call. It moves execution out
// of the in-process OSA component entirely — NSUserAppleScriptTask (async completion handler,
// own queue, outside the sandbox) or a spawned /usr/bin/osascript Process — so the host's own
// actor keeps ownership of the descriptor result. The handler is invoked by kASSubroutineEvent.
func runUserHandler(scriptName: String, handler: String, argument: String) async throws -> NSAppleEventDescriptor? {
    let directory = try FileManager.default.url(
        for: .applicationScriptsDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
    let task = try NSUserAppleScriptTask(url: directory.appendingPathComponent(scriptName))

    let event = NSAppleEventDescriptor(
        eventClass: AEEventClass(kASAppleScriptSuite), eventID: AEEventID(kASSubroutineEvent),
        targetDescriptor: nil, returnID: AEReturnID(kAutoGenerateReturnID), transactionID: AETransactionID(kAnyTransactionID))
    event.setParam(.init(string: handler), forKeyword: keyASSubroutineName)
    let list = NSAppleEventDescriptor.list()
    list.insert(.init(string: argument), at: 0)
    event.setParam(list, forKeyword: keyDirectObject)

    return try await withCheckedThrowingContinuation { continuation in
        task.execute(withAppleEvent: event) { result, error in
            error.map { continuation.resume(throwing: $0) } ?? continuation.resume(returning: result)
        }
    }
}
