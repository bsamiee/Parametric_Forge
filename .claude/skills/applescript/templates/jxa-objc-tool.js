#!/usr/bin/osascript -l JavaScript
// Title    : jxa-objc-tool
// Purpose  : A JXA automation tool that reaches Foundation through the ObjC bridge,
//            runs an NSTask process kernel with separated stdout/stderr/status, keeps
//            application specifiers distinct from realized values, and returns exactly
//            one JSON envelope on stdout.
// Contract : osascript -l JavaScript jxa-objc-tool.js <bundle-id> <payload-json>
//            stdout carries one JSON.stringify(...) object; console.log rides stderr.
// Replace  : <perform> body with the domain operation; the specifier reads it composes.
'use strict';
ObjC.import('Foundation');
ObjC.import('stdlib');

// Deep-unwrap is a boundary operation: Foundation collections become JSON-safe values
// at the edge, never threaded inward as live ObjC objects.
const unwrap = (value) => ObjC.deepUnwrap(value);

// NSTask process kernel: exact argv, separated streams, and a real termination status
// where do shell script collapses to one shell-parsed stream.
function runTask(launchPath, args) {
    const task = $.NSTask.alloc.init;
    const out = $.NSPipe.pipe;
    const err = $.NSPipe.pipe;
    task.launchPath = launchPath;
    task.arguments = args;
    task.standardOutput = out;
    task.standardError = err;
    task.launch;
    task.waitUntilExit;
    const decode = (data) => $.NSString.alloc.initWithDataEncoding(data.readDataToEndOfFile, $.NSUTF8StringEncoding).js;
    return {
        status: task.terminationStatus,
        stdout: decode(out.fileHandleForReading),
        stderr: decode(err.fileHandleForReading),
    };
}

// Atomic UTF-8 write through Foundation; the reference out-parameter carries the fault.
function writeUTF8(text, posixPath) {
    const target = $.NSString.stringWithString(posixPath).stringByExpandingTildeInPath;
    const error = $();
    const ok = $.NSString.stringWithString(text).writeToFileAtomicallyEncodingError(target, true, $.NSUTF8StringEncoding, error);
    if (!ok) {
        throw new Error(error.localizedDescription.js);
    }
    return target.js;
}

// Domain operation. A property read is a method call; a specifier stays uncalled until a container
// operation consumes it. A whose predicate reduces target-side, with JS filtering the fallback when the compound descriptor crosses a brittle object model.
function perform(bundleID, payload) {
    const app = Application(bundleID);
    const currentApp = Application.currentApplication();
    currentApp.includeStandardAdditions = true;

    const documents = app.documents.whose({ modified: false });
    const rows = documents().map((document) => ({
        name: document.name(),
        path: document.path(),
    }));
    return { host: currentApp.name(), count: rows.length, rows, echoed: payload };
}

function run(argv) {
    try {
        const [bundleID, payloadJSON] = argv;
        if (!bundleID) {
            throw new Error('missing bundle identifier');
        }
        const payload = payloadJSON ? JSON.parse(payloadJSON) : {};
        const value = perform(bundleID, payload);
        console.log(`[jxa-objc-tool] host=${value.host} count=${value.count}`);
        return JSON.stringify({ ok: true, value });
    } catch (error) {
        return JSON.stringify({
            ok: false,
            error: {
                name: String(error.name || 'Error'),
                message: String(error.message || error),
                number: error.errorNumber ?? null,
            },
        });
    }
}

// Droplet ingress reuses the same kernel when the tool is saved as a .app droplet.
function openDocuments(dropped) {
    return JSON.stringify({
        ok: true,
        dropped: dropped.map((item) => item.toString()),
    });
}
