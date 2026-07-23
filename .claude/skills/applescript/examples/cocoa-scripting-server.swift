// Pattern : Server-side specifier resolution — the receiving half of an object-specifier program. A
//           client query resolves against the receiver's own index — a named or unique-ID form answers in
//           one lookup and a `whose` filter tests projected records in place, never faulting in payloads.
//           An index hit returns concrete indices, an empty array asserts no match, nil alone delegates.
import Foundation

/// Growth axis: one row per sdef `<cocoa key>` the receiver filters on. A new scriptable filter key is a
/// row plus its projector, never a second evaluation path.
struct IndexedKey {
    let cocoaKey: String
    let project: (ShapeRecord) -> String
}

let INDEXED_KEYS: [IndexedKey] = [
    IndexedKey(cocoaKey: "name", project: { $0.name }),
    IndexedKey(cocoaKey: "layer", project: { $0.layer }),
]

/// The record is the cheap half of an element: identity plus every projected filter value. Payload loading
/// stays behind the closure, so a comparison never faults in geometry the query is about to discard.
struct ShapeRecord {
    let uniqueID: String
    let name: String
    let layer: String
    let loadPayload: () -> Data
}

final class ShapeIndex {
    private(set) var records: [ShapeRecord] = []
    private var positionByID: [String: Int] = [:]
    private var positionsByValue: [String: [String: [Int]]] = [:]

    func replaceAll(with incoming: [ShapeRecord]) {
        records = incoming
        // Keep-last on a duplicate uniqueID: this is the admission boundary for foreign records, so identity re-points, never traps the host.
        positionByID = Dictionary(incoming.enumerated().map { ($0.element.uniqueID, $0.offset) }, uniquingKeysWith: { _, last in last })
        positionsByValue = Dictionary(uniqueKeysWithValues: INDEXED_KEYS.map { indexed in
            var buckets: [String: [Int]] = [:]
            for (position, record) in incoming.enumerated() {
                buckets[indexed.project(record), default: []].append(position)
            }
            return (indexed.cocoaKey, buckets)
        })
    }

    func position(ofID uniqueID: String) -> Int? {
        positionByID[uniqueID]
    }

    /// A known key with no bucket is a real empty result; an unknown key is nil so the caller delegates.
    func positions(key: String, equalTo value: String) -> [Int]? {
        guard let buckets = positionsByValue[key] else { return nil }
        return buckets[value] ?? []
    }
}

/// The whose test runs candidate by candidate through NSScriptingComparisonMethods, so each element answers
/// its own comparison from the projected record and the payload closure never runs for a rejected
/// candidate. Without these overrides the evaluator falls back to isEqualTo: over materialized values.
@objcMembers final class Shape: NSObject {
    let record: ShapeRecord
    weak var container: ShapeContainer?

    init(record: ShapeRecord, container: ShapeContainer) {
        self.record = record
        self.container = container
    }

    dynamic var name: String {
        record.name
    }

    dynamic var layer: String {
        record.layer
    }

    override func scriptingIsEqual(to object: Any) -> Bool {
        compare(object) { $0 == $1 }
    }

    override func scriptingBegins(with object: Any) -> Bool {
        compare(object) { $0.hasPrefix($1) }
    }

    override func scriptingContains(_ object: Any) -> Bool {
        compare(object) { $0.contains($1) }
    }

    private func compare(_ object: Any, _ test: (String, String) -> Bool) -> Bool {
        guard let operand = object as? String else { return false }
        return INDEXED_KEYS.contains { test($0.project(record), operand) }
    }

    /// A unique-ID specifier keeps this element addressable after the container reorders; an index
    /// specifier names a different shape the moment a sibling lands ahead of it.
    override var objectSpecifier: NSScriptObjectSpecifier? {
        guard let container, let containerSpecifier = container.objectSpecifier,
              let description = NSScriptClassDescription(for: ShapeContainer.self) else { return nil }
        return NSUniqueIDSpecifier(containerClassDescription: description, containerSpecifier: containerSpecifier,
                                   key: "scriptableShapes", uniqueID: record.uniqueID)
    }
}

@objcMembers final class ShapeContainer: NSObject {
    private let index = ShapeIndex()
    private var facades: [Shape] = []

    /// Facades are minted once per load, so a specifier evaluated twice addresses the same element and the
    /// whose evaluator walks a stable array instead of rebuilding one per access.
    func load(_ records: [ShapeRecord]) {
        index.replaceAll(with: records)
        facades = records.map { Shape(record: $0, container: self) }
    }

    dynamic var scriptableShapes: [Shape] {
        facades
    }

    /// Each form the index owns resolves without walking the element array. NSWhoseSpecifier publishes its
    /// test as an opaque NSScriptWhoseTest, so a compound filter returns nil here and lands on the element
    /// comparison overrides — still receiver-side evaluation, one projected record at a time.
    override func indicesOfObjects(byEvaluatingObjectSpecifier specifier: NSScriptObjectSpecifier) -> [NSNumber]? {
        guard specifier.key == "scriptableShapes" else { return nil }
        switch specifier {
        case let unique as NSUniqueIDSpecifier:
            guard let uniqueID = unique.uniqueID as? String else { return nil }
            return index.position(ofID: uniqueID).map { [NSNumber(value: $0)] } ?? []
        case let named as NSNameSpecifier:
            return index.positions(key: "name", equalTo: named.name)?.map(NSNumber.init(value:))
        case let indexed as NSIndexSpecifier:
            let position = indexed.index < 0 ? index.records.count + indexed.index : indexed.index
            return index.records.indices.contains(position) ? [NSNumber(value: position)] : []
        default:
            return nil
        }
    }
}

/// A long export suspends the command rather than blocking the receiver's event dispatch; the suspension
/// token is what lets the reply event outlive performDefaultImplementation's return.
final class ShapeExportCommand: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        guard let destination = evaluatedArguments?["DestinationURL"] as? URL,
              let shapes = evaluatedReceivers as? [Shape]
        else {
            scriptErrorNumber = NSArgumentsWrongScriptError
            scriptErrorString = "export expects shape receivers and a destination directory"
            return nil
        }
        suspendExecution()
        // The detached task captures the command strongly: a suspended command deallocated before resume
        // strands the sender on a reply that never arrives, so the capture is the resume guarantee.
        Task.detached {
            let written = shapes.reduce(0) { total, shape -> Int in
                let payload = shape.record.loadPayload()
                do {
                    try payload.write(to: destination.appendingPathComponent(shape.record.uniqueID))
                    return total + payload.count
                } catch {
                    return total
                }
            }
            self.resumeExecution(withResult: written)
        }
        return nil
    }
}
