// Title    : osakit-host
// Purpose  : Compiled-host skeleton over OSAKit. One language instance owns every script, a
//            marshal boundary converts host values to descriptors and back, and both OSA error
//            key families normalize into one fault type the calling code branches on.
// Invariant: Callers hand this host a serial execution context; the host itself adds no
//            confinement and stays unsafe to share across concurrent lanes.
// Replace  : SOURCE and HANDLER rows, the Value arms with their two marshal cases each, and the
//            language instance the owning context hands in.
import Foundation
import OSAKit

// MARK: Slots

enum ScriptSource: String, CaseIterable {
    case SOURCE_NAME = "SOURCE_TEXT_OR_RESOURCE_NAME"
}

enum ScriptHandler: String {
    case HANDLER_NAME = "HANDLER_SPELLING"
}

/// Host-side payload vocabulary. Every arm is one descriptor shape the boundary owns in both
/// directions, so a new payload kind lands as one arm plus its two marshal cases.
enum Value {
    case text(String)
    case number(Int)
    case list([Value])
    case record([AEKeyword: Value])
}

// MARK: Fault

/// Both surfaces report a fault as an untyped info dictionary, and their key families never
/// overlap, so a family value selects the spellings and the fault shape stays single.
struct HostFault: Error {
    enum Stage: String { case compile, execute, marshal }

    struct KeyFamily {
        let message: String
        let number: String
        let range: String

        static let appleScript = KeyFamily(
            message: NSAppleScript.errorMessage, number: NSAppleScript.errorNumber, range: NSAppleScript.errorRange,
        )
        static let osa = KeyFamily(
            message: OSAScriptErrorMessageKey, number: OSAScriptErrorNumberKey, range: OSAScriptErrorRangeKey,
        )
    }

    let stage: Stage
    let number: Int
    let message: String
    let range: NSRange?

    init(stage: Stage, info: [AnyHashable: Any]?, keys: KeyFamily) {
        self.stage = stage
        number = info?[keys.number] as? Int ?? Int(errOSASystemError)
        message = info?[keys.message] as? String ?? "UNKNOWN_FAULT_TEXT"
        range = (info?[keys.range] as? NSValue)?.rangeValue
    }
}

// MARK: Marshal

/// Descriptor lists are one-based and index 0 appends, so a built list preserves argument order.
/// Coercion never happens implicitly here: an unmatched descriptor type is a marshal fault, not a
/// silent empty value, which keeps a dictionary drift visible at the boundary instead of downstream.
enum Marshal {
    static func descriptor(_ value: Value) -> NSAppleEventDescriptor {
        switch value {
        case let .text(text): .init(string: text)
        case let .number(number): .init(int32: Int32(number))
        case let .list(values): values.reduce(.list()) { list, item in list.insert(descriptor(item), at: 0); return list }
        case let .record(fields):
            fields.reduce(.record()) { record, field in record.setDescriptor(descriptor(field.value), forKeyword: field.key); return record }
        }
    }

    static func value(_ descriptor: NSAppleEventDescriptor) throws -> Value {
        if descriptor.isRecordDescriptor {
            let fields = try (1 ... max(descriptor.numberOfItems, 0)).reduce(into: [AEKeyword: Value]()) { fields, index in
                let keyword = descriptor.keywordForDescriptor(at: index)
                fields[keyword] = try descriptor.descriptor(forKeyword: keyword).map(value)
            }
            return .record(fields)
        }
        switch descriptor.descriptorType {
        case typeAEList: return try .list((1 ... max(descriptor.numberOfItems, 0)).compactMap(descriptor.atIndex).map(value))
        case typeUTF8Text, typeUnicodeText: return .text(descriptor.stringValue ?? "")
        case typeSInt32, typeSInt64, typeIEEE64BitFloatingPoint: return .number(Int(descriptor.int32Value))
        default: throw HostFault(stage: .marshal, info: nil, keys: .appleScript)
        }
    }
}

// MARK: Host

/// One language instance backs every script the host compiles, and a compiled script is cached by
/// source so a repeated call spends no compile pass. Handler invocation carries the argument list
/// as descriptors, so no host value crosses as generated source text.
final class ScriptHost {
    private let instance: OSALanguageInstance
    private var compiled: [ScriptSource: OSAScript] = [:]

    init(instance: OSALanguageInstance) {
        self.instance = instance
    }

    func call(_ source: ScriptSource, handler: ScriptHandler, arguments: [Value]) throws -> Value {
        var info: NSDictionary?
        let script = try compiled[source] ?? {
            let fresh = OSAScript(source: source.rawValue, from: nil, languageInstance: instance, using: [])
            guard fresh.compileAndReturnError(&info) else {
                throw HostFault(stage: .compile, info: info as? [AnyHashable: Any], keys: .osa)
            }
            compiled[source] = fresh
            return fresh
        }()
        guard let result = script.executeHandler(
            withName: handler.rawValue, arguments: arguments.map(Marshal.descriptor), error: &info,
        ) else {
            throw HostFault(stage: .execute, info: info as? [AnyHashable: Any], keys: .osa)
        }
        return try Marshal.value(result)
    }
}
