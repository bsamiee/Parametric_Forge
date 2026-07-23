#!/usr/bin/osascript -l JavaScript
// Pattern : Route a required verb set against the target's own installed dictionary before any send —
//           a declared command routes terminology, an undeclared name whose event class the dictionary
//           still declares routes a raw descriptor, an absent class refuses. JXA proxies every property
//           name, so `typeof app.anythingAtAll` is always "function" and only the sdef gates capability.
// Run     : osascript -l JavaScript sdef-routing.js <app-bundle-path> [verb[=operand] ...]
'use strict';
ObjC.import('Foundation');
ObjC.import('OSAKit');
// OSACopyScriptingDefinitionFromURL(CFURLRef, SInt32 modeFlags, CFDataRef *sdef) — modeFlags reserved as
// kOSAModeNull. This is the whole dictionary rail on a Command Line Tools-only host: sdef and sdp both
// refuse a developer directory that is not full Xcode. It synthesizes from an 'aete' resource or a
// scriptSuite pair where no native .sdef ships, so a legacy target still answers.
ObjC.bindFunction('OSACopyScriptingDefinitionFromURL', ['int', ['id', 'int', 'pointer']]);

// Growth axis: one row per verb the caller's rail requires. `code` is the sdef's own eight-character
// class+id pair, so the raw fallback reads its wire identity from the same row that names the term.
const REQUIRED = [
    { verb: 'count', code: 'corecnte', parameters: ['each'] },
    { verb: 'open', code: 'aevtodoc', parameters: [] },
    { verb: 'quit', code: 'aevtquit', parameters: ['saving'] },
];

const fourCharCode = (text) => Array.from(text).reduce((acc, ch) => (acc << 8) | ch.charCodeAt(0), 0) >>> 0;
const camelVerb = (verb) =>
    verb
        .split(/\s+/)
        .map((word, i) => (i === 0 ? word : word[0].toUpperCase() + word.slice(1)))
        .join('');
const attribute = (node, name) => {
    const found = node.attributeForName(name);
    return found.isNil() ? null : found.stringValue.js;
};

// Ref('pointer') is the only out-parameter shape the CFDataRef* slot accepts; an untyped $() returns
// paramErr (-50) before the call reaches OSAKit.
function copyDictionary(appPath) {
    const out = Ref('pointer');
    const status = $.OSACopyScriptingDefinitionFromURL($.NSURL.fileURLWithPath(appPath), 0, out);
    if (status !== 0) return { ok: false, stage: 'copy', status };
    const error = $();
    const document = $.NSXMLDocument.alloc.initWithDataOptionsError(ObjC.castRefToObject(out[0]), 0, error);
    if (document.isNil()) return { ok: false, stage: 'parse', status: error.code };
    return { ok: true, document };
}

function nodes(context, expression) {
    const error = $();
    const found = context.nodesForXPathError(expression, error);
    if (found.isNil()) return [];
    return Array.from({ length: found.count }, (_, index) => found.objectAtIndex(index));
}

// The catalog is the admission surface: declared names, their declared parameter labels, their
// access-group identifiers, and the set of event classes any declared command still answers.
function catalogOf(document) {
    const commands = new Map();
    const classes = new Set();
    nodes(document, '//command').forEach((node) => {
        const name = attribute(node, 'name');
        const code = attribute(node, 'code');
        if (name === null || code === null) return;
        commands.set(name, {
            code,
            parameters: nodes(node, 'parameter/@name').map((parameter) => parameter.stringValue.js),
            groups: nodes(node, 'access-group/@identifier').map((group) => group.stringValue.js),
        });
        classes.add(code.slice(0, 4));
    });
    return { commands, classes };
}

// A declared command missing a required parameter label is refused, never sent with the label dropped —
// the receiver resolves a different operation under the same verb. `*` is the universal access group.
function routeOf(row, catalog) {
    const declared = catalog.commands.get(row.verb);
    if (declared !== undefined) {
        const missing = row.parameters.filter((label) => !declared.parameters.includes(label));
        const scriptingTargets = declared.groups.filter((identifier) => identifier !== '*');
        if (missing.length > 0) return { verb: row.verb, route: 'refused', reason: 'parameter-absent', missing };
        return { verb: row.verb, route: 'terminology', code: declared.code, scriptingTargets };
    }
    if (catalog.classes.has(row.code.slice(0, 4))) {
        return { verb: row.verb, route: 'raw-event', code: row.code, scriptingTargets: [] };
    }
    return { verb: row.verb, route: 'refused', reason: 'event-class-absent', code: row.code };
}

// Terminology dispatch camel-cases the dictionary's own spelling; the raw lane addresses the same target
// by application URL, binding one bundle instance rather than a Launch Services identity. returnID -1 is
// kAutoGenerateReturnID and transactionID 0 is kAnyTransactionID.
function dispatch(appPath, verdict, operand) {
    if (verdict.route === 'terminology') {
        return { sent: 'terminology', value: Application(appPath)[camelVerb(verdict.verb)](operand) };
    }
    const target = $.NSAppleEventDescriptor.descriptorWithApplicationURL($.NSURL.fileURLWithPath(appPath));
    const event = $.NSAppleEventDescriptor.appleEventWithEventClassEventIDTargetDescriptorReturnIDTransactionID(
        fourCharCode(verdict.code.slice(0, 4)),
        fourCharCode(verdict.code.slice(4)),
        target,
        -1,
        0,
    );
    if (operand !== undefined) {
        event.setParamDescriptorForKeyword($.NSAppleEventDescriptor.descriptorWithString(operand), fourCharCode('----'));
    }
    const error = $();
    const reply = event.sendEventWithOptionsTimeoutError($.NSAppleEventSendWaitForReply | $.NSAppleEventSendNeverInteract, 10, error);
    if (reply.isNil()) return { sent: 'raw-event', status: error.code };
    return { sent: 'raw-event', status: 0, descriptorType: reply.descriptorType };
}

function run(argv) {
    const [appPath, ...selected] = argv;
    if (!appPath) return JSON.stringify({ ok: false, error: 'usage: <app-bundle-path> [verb[=operand] ...]' });
    const dictionary = copyDictionary(appPath);
    if (!dictionary.ok) return JSON.stringify(dictionary);
    const catalog = catalogOf(dictionary.document);
    // A selection carries its operand inline as verb=value; a bare verb sends with no direct parameter.
    const operands = new Map(
        selected.map((entry) => {
            const split = entry.indexOf('=');
            return split < 0 ? [entry, undefined] : [entry.slice(0, split), entry.slice(split + 1)];
        }),
    );
    const verdicts = REQUIRED.map((row) => routeOf(row, catalog));
    const sends = verdicts
        .filter((verdict) => operands.has(verdict.verb) && verdict.route !== 'refused')
        .map((verdict) => ({ verb: verdict.verb, ...dispatch(appPath, verdict, operands.get(verdict.verb)) }));
    return JSON.stringify({ ok: true, target: appPath, commands: catalog.commands.size, verdicts, sends });
}
