---
name: applescript
description: >-
    Builds and hardens AppleScript, JXA, and Open Scripting Architecture automation — osascript/osacompile
    runners, Apple Events and object-specifier dispatch, TCC consent preflight and hardened-runtime
    entitlements, OSAKit/NSAppleScript embedding, ScriptingBridge and Cocoa Scripting, sdef and scriptable-app
    dictionaries, notarized script-app distribution. Use when writing or reviewing AppleScript/JXA code,
    sending Apple Events, wiring ScriptingBridge or OSAKit, authoring or reading an sdef, or packaging a signed
    macOS automation artifact. Not plain shell scripting, browser page automation, or Shortcuts-only flows.
---

# [APPLESCRIPT]

AppleScript is an object-specifier compiler over the Apple Event ABI: a production artifact treats the language as a descriptor DSL, keeps process invocation and TCC policy outside script bodies, and returns typed receipts. Every deliverable is a signed OSA artifact whose code identity owns its Gatekeeper and TCC verdicts. `scripts/validate_bundle.py` compile-checks, round-trips, and lints every OSA artifact.

## [01]-[ROUTING]

[REFERENCES]:
- [01]-[LANGUAGE](references/language.md): AppleScript source composition, from script-object algebra to `NSAppleEventDescriptor` surgery.
- [02]-[RUNTIME](references/runtime.md): `osascript` execution, compilation, and packaging, with AppleScript and JXA as language rows.
- [03]-[EMBEDDING](references/embedding.md): `OSAKit` embedded in a Cocoa host, bound directly to the Apple Event ABI.
- [04]-[EVENTS](references/events.md): Apple Event wire ABI and the entitlement axes gating every send.
- [05]-[HOSTS](references/hosts.md): host dispatch matrix binding each surface to its handler contract and entitlements.
- [06]-[DISTRIBUTION](references/distribution.md): packaging, notarization, and the observation rails that carry an artifact into production.

[TEMPLATES]:
- [01]-[HARDENED_RUNNER](templates/hardened-osascript-runner.sh): `osascript` dispatch shell gated on a silent consent preflight.
- [02]-[OBJC_BRIDGE_TOOL](templates/jxa-objc-tool.js): JXA tool skeleton over the ObjC bridge, returning one JSON envelope from `run(argv)`.
- [03]-[COMPILED_LIBRARY](templates/applescript-library.applescript): reusable script object compiled to a `.scpt`/`.scptd` handler library.
- [04]-[NOTARIZED_APPLET](templates/notarized-applet.sh): script-app build driving `osacompile` output to a stapled notarized bundle.

[EXAMPLES]:
- [01]-[CONSENT_PREFLIGHT](examples/aedetermine-preflight.js): `AEDeterminePermissionToAutomateTarget` classified silently through the ObjC bridge.
- [02]-[RAW_EVENT_CODES](examples/raw-apple-event-codes.applescript): chevron literals and `NSAppleEventDescriptor` surgery beneath terminology.
- [03]-[THREAD_SAFETY](examples/osakit-thread-safety.swift): `OSALanguageInstance` serialized per lane behind an actor against run-loop reentrancy.
- [04]-[EVENT_OBSERVATION](examples/appleevents-observation.sh): one runnable probe over the Apple Event observation rails.
- [05]-[DICTIONARY_ROUTING](examples/dictionary-first-routing.js): capability gate before synthesis, `whose` reduction delegated across the OSA seam.

## [02]-[AUTOMATION_LAW]

- Automation consent binds one signed sender to one receiver, so every probe and every send runs from the binary that ships.
- A production sender preflights consent and routes an undetermined verdict to a user-initiated lane.
- User values reach a script as escaped literals inside closed templates, never as concatenated source.
- Terminology resolves against the installed target dictionary at run time, never from recall.
