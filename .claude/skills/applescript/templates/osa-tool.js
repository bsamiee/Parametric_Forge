#!/usr/bin/osascript -l JavaScript
// Title    : osa-tool
// Purpose  : Agent-tool skeleton across the OSA host set — argv in, one typed JSON envelope out,
//            with every host entry point declared beside the shared policy row.
// Contract : osascript -l JavaScript osa-tool.js <bundle-id> <payload-json>
//            stdout carries one JSON.stringify object; console.log rides stderr.
// Replace  : <TOOL_NAME>, <IDLE_SECONDS>, and the <DOMAIN_LOGIC> region inside run.
'use strict';

const POLICY = { tool: '<TOOL_NAME>', idleSeconds: 300 };

const envelope = (value) => JSON.stringify({ ok: true, tool: POLICY.tool, value });

// errorNumber carries the OSA fault identity and stays null for a JavaScript-native throw.
const fault = (stage, error) =>
    JSON.stringify({
        ok: false,
        tool: POLICY.tool,
        stage,
        error: {
            name: String(error.name || 'Error'),
            message: String(error.message || error),
            number: error.errorNumber ?? null,
        },
    });

// osascript and a double-clicked applet both enter here; the applet arrives with an empty argv.
function run(argv) {
    try {
        const [bundleID, payloadJSON] = argv;
        if (!bundleID) {
            throw new Error('missing bundle identifier');
        }
        const payload = payloadJSON ? JSON.parse(payloadJSON) : {};
        // <DOMAIN_LOGIC> — build the envelope value here; Foundation values unwrap at this edge.
        const value = { bundleID, payload };
        return envelope(value);
    } catch (error) {
        return fault('run', error);
    }
}

// Droplet ingress: a Finder drop hands Path tokens, never strings, so each item converts explicitly.
function openDocuments(dropped) {
    try {
        return envelope(dropped.map((item) => item.toString()));
    } catch (error) {
        return fault('openDocuments', error);
    }
}

// Stay-open applet only (osacompile -s); the return value is the seconds until the next call.
function idle() {
    return POLICY.idleSeconds;
}

// Stay-open teardown: release retained state here before the host exits.
function quit() {
    return true;
}
