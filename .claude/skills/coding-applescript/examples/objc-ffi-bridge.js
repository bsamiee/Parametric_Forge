#!/usr/bin/osascript -l JavaScript
// Pattern : The JXA-to-C FFI boundary at composed scale — one declared ABI table, four-char-code
//           marshalling, borrowed AEDesc pointers, a sized out-buffer read, and an opaque
//           out-parameter ref lifted back into an ObjC object.
// Run     : osascript -l JavaScript objc-ffi-bridge.js <bundle-id> [app-bundle-path]
'use strict';
ObjC.import('Foundation');
ObjC.import('CoreServices');
// Carbon carries OpenScripting; a bindFunction name resolves against loaded images alone.
ObjC.import('Carbon');

// One row per admitted C function: result type, then argument types. A new binding is a row here,
// never a cast at a call site. 'pointer' borrows an AEDesc*, 'void *' takes caller-owned bytes,
// and 'void **' takes an out slot the bridge cannot type.
const C_ABI = {
    AEGetDescDataSize: ['long', ['pointer']],
    AEGetDescData: ['short', ['pointer', 'void *', 'long']],
    OSACopyScriptingDefinitionFromURL: ['int', ['id', 'int', 'void **']],
};
Object.keys(C_ABI).forEach((name) => {
    ObjC.bindFunction(name, C_ABI[name]);
});

const CODE_WIDTH = 4;

// A four-char code folds big-endian into the unsigned int the ABI declares, and every byte counts:
// 'psn ' and 'cut ' carry a trailing space, so no trim or pad runs on either edge of the fold.
function fourCharCode(text) {
    if (text.length !== CODE_WIDTH) {
        throw new Error(`four-char code must be exactly 4 bytes: ${JSON.stringify(text)}`);
    }
    return text.split('').reduce((acc, ch) => ((acc << 8) | (ch.charCodeAt(0) & 0xff)) >>> 0, 0) >>> 0;
}

// The inverse keeps a receipt readable as text and hex together, since a logged code alone is ambiguous.
function codeReceipt(value) {
    const text = [24, 16, 8, 0].map((shift) => String.fromCharCode((value >>> shift) & 0xff)).join('');
    return { text, hex: `0x${value.toString(16).padStart(8, '0')}` };
}

// aeDesc hands out a raw AEDesc* the descriptor object owns. `use` receives that pointer and returns
// plain JavaScript values only — a returned pointer outlives its owner and dangles the moment the
// descriptor binding leaves scope.
function borrowAEDesc(descriptor, use) {
    if (!descriptor) {
        throw new Error('pointer borrow requires a live descriptor');
    }
    return use(descriptor.aeDesc);
}

// descriptorWithBundleIdentifier: yields a typeApplicationBundleID descriptor for any string, installed
// or not, so target absence arrives as a status from the call, never as a nil descriptor to guard.
function bundleTarget(bundleID) {
    return $.NSAppleEventDescriptor.descriptorWithBundleIdentifier(bundleID);
}

// Two calls over one borrow: the size call bounds the allocation and the data call fills it. NSMutableData
// owns those bytes for as long as the JavaScript binding lives, so the buffer pointer never escapes the
// borrow that produced it. A 'long' result crosses the bridge as a decimal string, so the size coerces
// to a number before it bounds anything, and a list or record descriptor carries no flat data at all.
function descriptorPayload(descriptor) {
    return borrowAEDesc(descriptor, (aeDesc) => {
        const size = Number($.AEGetDescDataSize(aeDesc));
        if (size <= 0) {
            return { size: 0, text: null };
        }
        const buffer = $.NSMutableData.dataWithLength(size);
        const status = $.AEGetDescData(aeDesc, buffer.mutableBytes, size);
        if (status !== 0) {
            throw new Error(`AEGetDescData returned ${status}`);
        }
        return { size, text: $.NSString.alloc.initWithDataEncoding(buffer, $.NSUTF8StringEncoding).js };
    });
}

// A CFDataRef out-parameter is opaque to the bridge, so the ref carries its own storage type — an untyped
// Ref faults with -2700 before the call runs. Slot zero holds the filled pointer, castRefToObject lifts it
// into an ObjC object, and a nonzero status leaves that slot untouched, so the cast follows the check.
function scriptingDefinition(bundlePath) {
    const sdefOut = Ref('void *', null);
    const url = $.NSURL.fileURLWithPath(bundlePath);
    const status = $.OSACopyScriptingDefinitionFromURL(url, 0, sdefOut);
    if (status !== 0) {
        return { status, bytes: 0 };
    }
    return { status, bytes: Number(ObjC.castRefToObject(sdefOut[0]).length) };
}

function run(argv) {
    const [bundleID, bundlePath] = argv;
    if (!bundleID) {
        return JSON.stringify({ ok: false, error: 'usage: <bundle-id> [app-bundle-path]' });
    }
    const target = bundleTarget(bundleID);
    return JSON.stringify({
        ok: true,
        bundleID,
        descriptorType: codeReceipt(target.descriptorType),
        payload: descriptorPayload(target),
        dictionary: bundlePath ? scriptingDefinition(bundlePath) : null,
    });
}
