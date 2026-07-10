#!/usr/bin/osascript -l JavaScript
// Pattern : Probe the installed dictionary before synthesizing a script, then delegate a
//           pathological whose predicate across the JXA and AppleScript boundary rather than
//           dropping to a shell escape. The claim binds to the dictionary currently installed.
// Run     : osascript -l JavaScript dictionary-first-routing.js <bundle-id>
'use strict';
ObjC.import('Foundation');

const host = Application.currentApplication();
host.includeStandardAdditions = true;

// Capability gate: confirm the target answers the exact commands before synthesis, recording
// bundle id, version, and dictionary availability as a runtime fixture.
function probe(bundleID) {
    const app = Application(bundleID);
    try {
        return {
            ok: true,
            name: app.name(),
            version: app.version(),
            running: app.running(),
        };
    } catch (error) {
        return { ok: false, bundleID, reason: String(error.message || error) };
    }
}

// A whose predicate compiles to an Apple event test descriptor evaluated target-side; a compound
// descriptor fails coercion on an incomplete object model. The filter delegates to an equivalent
// AppleScript whose via runScript — a tactical OSA language switch, never a shell escape.
function whoseDelegate() {
    const source = `
tell application "Finder"
  return POSIX path of (files of desktop whose name extension is "scpt") as list
end tell`;
    return host.runScript(source);
}

// Split target-side reduction from JavaScript-side refinement so a compound descriptor never
// crosses a brittle object model whole.
function splitReduction() {
    const se = Application('System Events');
    const raw = se.processes.whose({ backgroundOnly: false }).properties();
    return raw.filter((process) => /^S/.test(process.name) && process.bundleIdentifier).map((process) => process.name);
}

function run(argv) {
    const bundleID = argv[0] || 'com.apple.finder';
    const gate = probe(bundleID);
    return JSON.stringify({
        gate,
        scriptPaths: whoseDelegate(),
        sProcesses: splitReduction(),
    });
}
