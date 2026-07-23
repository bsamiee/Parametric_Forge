// Pattern : The reentrancy path joined end to end — a host handler that suspends its incoming event,
//           runs a script that sends the same verb back into this process, rebinds the command context
//           on the completing thread, and resumes the detached reply exactly once.
// Consumes : a serial script lane whose instance confinement is already established.
import Carbon
import Foundation

// 'Shap'/'Rndr' — the private suite this host answers. Reentrancy is only observable on a verb the host
// both receives and re-sends, so the script the handler runs targets this same class and id.
private let hostSuite = AEEventClass(0x5368_6170)
private let renderVerb = AEEventID(0x526E_6472)
/// 'Rent' — a host-owned reply keyword, since the reentrancy fact belongs to this suite and no
/// registry keyword carries it.
private let reentrantKey = AEKeyword(0x5265_6E74)

/// Host-domain fault numbers stay out of the Apple Event Manager's negative range, so a receipt never
/// reads a host refusal as a transport status.
private enum HostFault {
    static let depthExceeded: Int32 = 9300
    static let suspensionUnavailable: Int32 = 9301
    static let executionFailed: Int32 = 9302
}

/// Suspension is what makes the nested send legal. Executing the script inline instead would spin the run
/// loop while blocked, dispatch the reentrant inbound event into this same selector on this same thread,
/// and let the inner reply write into the outer event's reply descriptor. Detaching the reply first gives
/// each generation its own reply slot and its own current-event binding.
final class ReentrantRenderHost: NSObject {
    private let execute: (String) throws -> NSAppleEventDescriptor
    private let lane: DispatchQueue
    private let maxDepth: Int
    private var depth = 0

    init(lane: DispatchQueue, maxDepth: Int = 3, execute: @escaping (String) throws -> NSAppleEventDescriptor) {
        self.lane = lane
        self.maxDepth = maxDepth
        self.execute = execute
    }

    func install() {
        NSAppleEventManager.shared().setEventHandler(
            self, andSelector: #selector(handle(event:reply:)),
            forEventClass: hostSuite, andEventID: renderVerb,
        )
    }

    @objc private func handle(event: NSAppleEventDescriptor, reply: NSAppleEventDescriptor) {
        let manager = NSAppleEventManager.shared()
        // A send this process addressed to itself is the reentrant generation; the sender PID attribute is
        // the only evidence available at dispatch, since the event body carries nothing about its origin.
        let reentrant = event.attributeDescriptor(forKeyword: keySenderPIDAttr)?.int32Value == getpid()
        guard depth < maxDepth else {
            return write(fault: HostFault.depthExceeded, message: "render depth \(depth) exceeded", into: reply)
        }
        // Suspension is taken on the dispatch thread and before any work that can spin the run loop; past
        // that point the passed-in reply descriptor is stale and only the suspended reply is writable.
        guard let suspension = manager.suspendCurrentAppleEvent() else {
            return write(fault: HostFault.suspensionUnavailable, message: "event not suspendable", into: reply)
        }
        let source = event.paramDescriptor(forKeyword: keyDirectObject)?.stringValue ?? ""
        depth += 1

        lane.async { [self] in
            // The command context is thread-local, so the completing thread rebinds it before running the
            // script; without this the nested send attributes to whatever event this thread last handled.
            manager.setCurrentAppleEventAndReplyEventWithSuspensionID(suspension)
            let suspendedReply = manager.replyAppleEvent(forSuspensionID: suspension)
            do {
                let result = try execute(source)
                suspendedReply.setParam(result, forKeyword: keyDirectObject)
                suspendedReply.setParam(.init(boolean: reentrant), forKeyword: reentrantKey)
            } catch {
                write(fault: HostFault.executionFailed, message: "\(error)", into: suspendedReply)
            }
            // Resume invalidates the token and releases the reply to the sender. A second resume against the
            // same token, or a write after it, reaches a descriptor the manager already handed back.
            manager.resume(withSuspensionID: suspension)
            DispatchQueue.main.async { self.depth -= 1 }
        }
    }

    /// A reply the sender requested none of reads typeNull, and writing into it corrupts an unowned slot.
    private func write(fault: Int32, message: String, into reply: NSAppleEventDescriptor) {
        guard reply.descriptorType != typeNull else { return }
        reply.setParam(.init(int32: fault), forKeyword: keyErrorNumber)
        reply.setParam(.init(string: message), forKeyword: keyErrorString)
    }
}

/// The script the handler runs re-enters this host on the same verb, so a completed round trip proves the
/// suspension held: the outer reply carries the inner result, and the inner generation saw its own sender PID.
func reentrantProbeSource(bundleID: String, depth: Int) -> String {
    """
    tell application id "\(bundleID)"
        «event ShapRndr» "depth-\(depth)"
    end tell
    """
}
