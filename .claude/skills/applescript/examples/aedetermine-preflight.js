#!/usr/bin/osascript -l JavaScript
// Pattern  : Silent TCC Automation consent preflight from the exact binary that automates.
// Run      : osascript -l JavaScript aedetermine-preflight.js <bundle-id> [class-hex] [id-hex]
// Verdict  : noErr(0) granted · errAEEventNotPermitted(-1743) denied · errAEEventWouldRequireUserConsent(-1744)
//            undecided · procNotFound(-600) not running. -1744 routes to the explicit permission lane, never "denied".
'use strict';
ObjC.import('Foundation');
ObjC.import('CoreServices');
// AEDeterminePermissionToAutomateTarget(const AEAddressDesc*, AEEventClass, AEEventID, Boolean askUserIfNeeded)
ObjC.bindFunction('AEDeterminePermissionToAutomateTarget', ['int', ['pointer', 'unsigned int', 'unsigned int', 'bool']]);

const WILDCARD = 0x2a2a2a2a; // typeWildCard '****' — tests broad automation of the target
const VERDICT = {
    0: 'granted',
    '-1743': 'denied',
    '-1744': 'undecided',
    '-600': 'target-not-running',
};

// askUserIfNeeded stays false so a background checker branches without raising the sheet;
// a specific class/id scopes the question to one command the receiver's access group governs.
function consentFor(bundleID, eventClass = WILDCARD, eventID = WILDCARD) {
    // descriptorWithBundleIdentifier always builds a descriptor; a non-running target surfaces
    // as procNotFound (-600) from the C call, not as a nil descriptor.
    const target = $.NSAppleEventDescriptor.descriptorWithBundleIdentifier(bundleID);
    const status = $.AEDeterminePermissionToAutomateTarget(target.aeDesc, eventClass, eventID, false);
    return { bundleID, verdict: VERDICT[String(status)] || 'failed', status };
}

function run(argv) {
    const [bundleID, klass, ident] = argv;
    if (!bundleID) {
        return JSON.stringify({
            ok: false,
            error: 'usage: <bundle-id> [class-hex] [id-hex]',
        });
    }
    const scope = {
        eventClass: klass ? parseInt(klass, 16) : WILDCARD,
        eventID: ident ? parseInt(ident, 16) : WILDCARD,
    };
    return JSON.stringify({
        ok: true,
        ...consentFor(bundleID, scope.eventClass, scope.eventID),
    });
}
