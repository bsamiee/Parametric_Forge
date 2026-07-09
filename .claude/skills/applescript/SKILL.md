---
name: applescript
description: >-
  Builds and hardens AppleScript, JXA, and Open Scripting Architecture automation — osascript/osacompile
  runners, Apple Events and object-specifier dispatch, TCC consent preflight and hardened-runtime
  entitlements, OSAKit/NSAppleScript embedding, ScriptingBridge and Cocoa Scripting, sdef and scriptable-app
  dictionaries, notarized script-app distribution. Use when writing or reviewing AppleScript/JXA code,
  sending Apple Events, wiring ScriptingBridge or OSAKit, authoring or reading an sdef, or packaging a signed
  macOS automation artifact. Routes language core, OSA runtime, Foundation embedding, Apple Events security,
  automation surfaces, and deploy/debug to their reference; carries hardened-runner, ObjC-bridge-tool,
  compiled-library, and notarized-applet templates over real consent-preflight, raw-event-code, thread-safety,
  observation, and dictionary-routing examples. Not plain shell scripting, browser page automation, or
  Shortcuts-only flows.
---

# [APPLESCRIPT]

AppleScript is an object-specifier compiler over the Apple Event ABI, not an English prose runtime; a production artifact treats the language as a descriptor DSL, keeps process invocation and TCC policy outside script bodies, and returns typed receipts. The deliverable is a signed OSA artifact whose identity owns its Gatekeeper and TCC verdicts — a flat `.scpt`, a compiled `.scptd` bundle, a notarized applet, or a host that embeds `OSAScript` — never a text file with incidental launch behavior. Each reference below owns one lane at frontier depth, each template is a production skeleton, and each example is a real code artifact the patterns catalog routes to. The bundle validator in `scripts/validate_bundle.py` compile-checks, round-trips, and lints every OSA artifact.

## [01]-[LANE_ROUTING]

Load the lane that owns the failing decision.

- [01]-[LANGUAGE_CORE]: The script-object algebra, closures, coercion rails, the comparison-attribute stack, delimiter critical sections, filter references, handler-dispatch tables, chevron raw codes, script persistence, and `NSAppleEventDescriptor` surgery — [references/language-core.md](references/language-core.md).
- [02]-[OSA_RUNTIME]: The `osascript` source algebra and output serialization, JXA specifier proxies and `whose` descriptors, the `$` ObjC bridge and `NSTask` kernels, script libraries, applet and droplet handler contracts, compiled storage, and run-only distribution — [references/osa-runtime.md](references/osa-runtime.md).
- [03]-[FOUNDATION_OSAKIT]: `NSAppleScript` against `OSAScript`, OSAKit storage and options, component thread-safety and main-thread confinement, Cocoa Scripting commands and specifiers, `NSUserScriptTask`, ScriptingBridge, and the `OSACopyScriptingDefinitionFromURL` runtime escape — [references/foundation-osakit.md](references/foundation-osakit.md).
- [04]-[APPLE_EVENTS_SECURITY]: The wire envelope and four-character ABI, the `AESendMode` axes, `AEDeterminePermissionToAutomateTarget` preflight, TCC attribution by audit token, hardened-runtime and sandbox entitlements, PPPC, the unified-log rails, and injection defense — [references/apple-events-security.md](references/apple-events-security.md).
- [05]-[AUTOMATION_SURFACES]: The UTType spine, the host dispatch matrix, Automator and Shortcuts routing, Folder Actions, Mail rules, stay-open agents, Script Menu, and App Intents composition through Shortcuts — [references/automation-surfaces.md](references/automation-surfaces.md).
- [06]-[DEPLOY_DEBUG]: Artifact topology, signing and notarization, the shell boundary, Apple Event performance, error architecture, the observation rails, Nix and Homebrew packaging, and the Swift migration boundary — [references/deploy-debug.md](references/deploy-debug.md).

## [02]-[TEMPLATES]

Copy a skeleton and fill its policy rows; each is production-grade and parameterized.

- [01]-[HARDENED_RUNNER]: An agent or CLI drives automation through `osascript` behind a silent consent preflight, argv-only data, a JSON envelope, a timeout budget, and hash-only audit — [assets/templates/hardened-osascript-runner.sh](assets/templates/hardened-osascript-runner.sh).
- [02]-[OBJC_BRIDGE_TOOL]: JXA reaches Foundation and CoreServices through an `NSTask` process kernel, a deep-unwrap boundary, and a JSON envelope over `run(argv)` — [assets/templates/jxa-objc-tool.js](assets/templates/jxa-objc-tool.js).
- [03]-[COMPILED_LIBRARY]: Reusable AppleScript ships as a `.scpt`/`.scptd` script object with policy rows, receipt-shaped errors, and AppleScriptObjC JSON and atomic-write rails — [assets/templates/applescript-library.applescript](assets/templates/applescript-library.applescript).
- [04]-[NOTARIZED_APPLET]: A script-app carries a hardened runtime, the minimal Apple Events entitlement, nested signing, notarization, and a stapled ticket — [assets/templates/notarized-applet.sh](assets/templates/notarized-applet.sh).

## [03]-[EXAMPLES]

Each example is one focused frontier pattern as a real code artifact.

- [01]-[CONSENT_PREFLIGHT]: `AEDeterminePermissionToAutomateTarget` classified silently through the JXA ObjC bridge, reading the granted, denied, and never-asked verdicts — [assets/examples/aedetermine-preflight.js](assets/examples/aedetermine-preflight.js).
- [02]-[RAW_EVENT_CODES]: Chevron `«event»`/`«class»`/`«constant»` literals and `NSAppleEventDescriptor` list and record surgery over the four-character ABI — [assets/examples/raw-apple-event-codes.applescript](assets/examples/raw-apple-event-codes.applescript).
- [03]-[THREAD_SAFETY]: One serial `OSALanguageInstance` per lane behind a Swift actor, with the main-thread and run-loop-reentrancy confinement — [assets/examples/osakit-thread-safety.swift](assets/examples/osakit-thread-safety.swift).
- [04]-[EVENT_OBSERVATION]: The `com.apple.appleevents` unified-log rail, the `AEDebug` per-process taps, and the `tcc_modify` consent-change stream as a runnable probe — [assets/examples/appleevents-observation.sh](assets/examples/appleevents-observation.sh).
- [05]-[DICTIONARY_ROUTING]: A runtime dictionary probe before script synthesis and a pathological `whose` predicate delegated across the JXA and AppleScript boundary — [assets/examples/dictionary-first-routing.js](assets/examples/dictionary-first-routing.js).

## [04]-[IDENTITY_LAW]

TCC Automation consent binds to the process identity that sends the event, so the artifact that owns durable consent is the signed container, never the development shell. A script run through Terminal, Script Editor, an `osascript` invocation, an applet, Automator, Shortcuts, or an embedding host earns a distinct TCC row keyed on that sender's code requirement. Distribution therefore exercises Apple Events from the final signed applet or command-line tool, and a permission lane rechecks authorization before each privileged send because an OS update resets some grants. A helper embedded in a main app is audited as its own sender unless the system attributes the prompt to the container.

## [05]-[CONSENT_LAW]

A background sender never triggers consent implicitly. It preflights with `AEDeterminePermissionToAutomateTarget(target, class, id, askUserIfNeeded:false)` off the main actor, reads `noErr` as granted, `errAEEventNotPermitted` (`-1743`) as a standing denial, and `errAEEventWouldRequireUserConsent` (`-1744`) as undecided, then routes the undecided verdict to an explicit user-initiated permission lane rather than shipping a doomed command. A batch send OR-s `kAEDoNotPromptForUserConsent` (`0x00020000`) into the `AESendMode` so a consent-requiring event returns `-1744` instead of raising the one visible prompt on a non-user path. The naive `tell application … to get name` probe both prompts and, on a regressed error-retrieval path, stalls for minutes, so every probe carries a `with timeout` budget and runs from the exact binary that later automates.

## [06]-[INJECTION_LAW]

User values are data, never source. A string reaching `do shell script` is parsed once as AppleScript and again by `/bin/sh`, so a caller value enters only as a fully-escaped AppleScript literal and, for a shell argument, only through `quoted form of` joined with `& space &`; long payloads enter a temporary file, never the command string. A generated script is assembled from closed templates with escaped values, never concatenated from raw user text, because `run script` and `do shell script` execute whatever they receive. An automation gateway refuses to dispatch events to credential stores and self-privileging receivers — Keychain Access, password managers, Terminal, System Settings — by target identity, and a static reject pass denies `with administrator privileges`, `sudo`, pipe-to-shell, and keystroke-of-secret patterns before the source compiles.

## [07]-[COST_LAW]

Apple Event round-trips dominate cost, so the script batches specifiers across the process boundary once and loops over native AppleScript lists locally: `set {ids, starts, titles} to {uid, start date, summary} of every event` is one event where a per-object read is many. A `whose` filter pushes reduction into the target when the target implements object filtering, and bulk property assignment over a plural specifier changes the selection set in one send. Every application command carries a `with timeout` that records the target, selector, and budget as fault coordinates, and `ignoring application responses` is reserved for a fire-and-forget send whose result and failure are externally reconciled.

## [08]-[RECEIPT_LAW]

Generated code returns receipts, never bare values. An AppleScript handler preserves every error slot — `message`, `number`, `partial result`, `from`, `to` — and rethrows with the original fields so a caller distinguishes a cancelled dialog, an authorization denial, a missing object, and a coercion fault; recovery keys on the negative Apple Event number, never a message substring. A JXA boundary returns one `JSON.stringify` envelope on stdout with `console.log` diagnostics on stderr, so the pipeline stays parseable under a typed decoder. The durable audit persists a SHA-256 of the source, a bounded non-secret preview, the success bit, and the result length, never the secret-bearing body.

## [09]-[DICTIONARY_LAW]

An application dictionary is the contract, resolved at runtime, never recalled. Terminology resolves through the installed `.sdef`, extracted by `OSACopyScriptingDefinitionFromURL` on a Command Line Tools-only host where the `sdef`/`sdp` executables demand a full Xcode developer directory. A load-bearing verb that must survive dictionary churn across an OS release pins as a chevron `«event»` literal rather than a term the next release retires. Object-model automation through a target's own dictionary command beats UI scripting through System Events, which expands the Accessibility and PPPC scope and weakens receiver semantics; UI scripting stays a bounded last-mile adapter that resolves the smallest stable container and reads attributes in plural form.
