# [EVENTS]

An Apple Event is a typed cross-process capability request.

## [01]-[EVENT_ENVELOPE]

`AEEventClass` selects the suite and `AEEventID` selects the verb; `keyDirectObject` carries the primary operand and keyed parameters carry secondary operands. Transport attributes ride beside the payload: `keyAddressAttr` names the destination, `keyEventClassAttr`/`keyEventIDAttr` mirror the envelope for inspection, `keyReturnIDAttr` and `keyTransactionIDAttr` correlate replies and grouped sends, `keyTimeoutAttr` bounds the wait, `keyEventSourceAttr` marks provenance, and `keySenderPIDAttr`/`keySenderAuditTokenAttr` carry sender identity for the receiver's TCC evaluation.

Scripting dictionaries map human verbs onto `OSType` values, and security and transport code reasons over the resulting descriptor graph, never the dictionary term. A code logger records each `OSType` as both quoted big-endian text and hex, because a space-padded code such as `'cut '` or `'psn '` loses its trailing space under naive trimming and silently corrupts the four-byte value.

## [02]-[TARGET_AND_DESCRIPTOR_TYPES]

A target descriptor decides routing before terminology resolves. `typeApplicationBundleID` binds stable local application identity and survives a binary move; `typeKernelProcessID` binds one already-running process instance and isolates a specific vetted target; `typeApplicationURL` binds a local or remote application URL.

Descriptor type selection carries its own security and coercion behavior. Text payloads ride `typeUTF8Text` or `typeUTF16ExternalRepresentation`; file references ride `typeFileURL` or `typeBookmarkData`; structured payloads ride `typeAERecord` for keyed records and `typeAEList` for ordered collections; object references ride object-specifier descriptors; numeric payloads ride explicit fixed-width descriptor types rather than a coerced string.

A sender that transmits `document 1` transmits a descriptor tree carrying desired class, container, form, and key data, and the receiver resolves that tree inside its own object model on receipt.

## [03]-[EVENT_CONSTRUCTION]

`AEBuildAppleEvent` binds event class, event ID, address descriptor type, address bytes, return ID, transaction ID, result storage, build-error storage, and a format string in one call, and it stays safe only when the format string is a compile-time literal and every value enters as a typed argument. A dynamic fragment inside that format string turns descriptor construction into an injection surface, because the format parser then compiles attacker-influenced structure rather than attacker-influenced data.

```c conceptual
static OSStatus send_core_event_to_bundle(
    CFStringRef bundleID,
    AEEventClass eventClass,
    AEEventID eventID,
    AESendMode mode,
    AppleEvent *reply
) {
    char target[512];
    CFIndex used = 0;
    if (!CFStringGetBytes(bundleID, CFRangeMake(0, CFStringGetLength(bundleID)),
                           kCFStringEncodingUTF8, 0, false, (UInt8 *)target, sizeof target, &used)) {
        return coreFoundationUnknownErr;
    }

    AppleEvent event = { typeNull, NULL };
    AEBuildError build = { 0 };
    OSStatus status = AEBuildAppleEvent(
        eventClass, eventID,
        typeApplicationBundleID, target, used,
        kAutoGenerateReturnID, kAnyTransactionID,
        &event, &build, ""
    );
    if (status != noErr) return status;

    status = AESendMessage(&event, reply, mode, kAEDefaultTimeout);
    AEDisposeDesc(&event);
    return status;
}
```

```c rejected
char format[256];
snprintf(format, sizeof format, "'----':obj { want:type(%s) }", userSuppliedClassName);
AEBuildAppleEvent(eventClass, eventID, typeApplicationBundleID, target, used,
                   kAutoGenerateReturnID, kAnyTransactionID, &event, &build, format);
```

Cocoa descriptors own the same wire with stronger lifetime behavior. `NSAppleEventDescriptor` takes descriptor ownership through `initWithAEDescNoCopy:`, exposes `aeDesc` for CoreServices interop, builds bundle-ID and application-URL targets, and sends with `sendEventWithOptions:timeout:error:`, keeping descriptor disposal out of ordinary control paths.

```objc conceptual
static NSAppleEventDescriptor *QuitApplication(NSString *bundleID, NSError **error) {
    NSAppleEventDescriptor *target = [NSAppleEventDescriptor descriptorWithBundleIdentifier:bundleID];
    NSAppleEventDescriptor *event = [NSAppleEventDescriptor appleEventWithEventClass:kCoreEventClass
                                                                             eventID:kAEQuitApplication
                                                                    targetDescriptor:target
                                                                            returnID:kAutoGenerateReturnID
                                                                       transactionID:kAnyTransactionID];
    return [event sendEventWithOptions:NSAppleEventSendWaitForReply | NSAppleEventSendCanInteract
                               timeout:30
                                 error:error];
}
```

```swift conceptual
func quitApplication(bundleID: String) throws -> NSAppleEventDescriptor {
    let target = NSAppleEventDescriptor(bundleIdentifier: bundleID)
    let event = NSAppleEventDescriptor.appleEvent(
        withEventClass: kCoreEventClass,
        eventID: kAEQuitApplication,
        targetDescriptor: target,
        returnID: AEReturnID(kAutoGenerateReturnID),
        transactionID: AETransactionID(kAnyTransactionID)
    )
    return try event.sendEvent(
        options: [.waitForReply, .canInteract],
        timeout: 30
    )
}
```

## [04]-[SEND_MODE_BITFIELD]

Reply and interaction axes are mutually exclusive; modifiers compose freely.

| [INDEX] | [AXIS]      | [FLAG]              | [HEX]    | [COCOA]                          | [EFFECT]                               |
| :-----: | :---------- | :------------------ | :------- | :------------------------------- | :------------------------------------- |
|  [01]   | Reply       | `kAENoReply`        | `0x01`   | `NSAppleEventSendNoReply`        | no reply returned                      |
|  [02]   | Reply       | `kAEQueueReply`     | `0x02`   | `NSAppleEventSendQueueReply`     | reply queued to sender asynchronously  |
|  [03]   | Reply       | `kAEWaitReply`      | `0x03`   | `NSAppleEventSendWaitForReply`   | blocks the run loop for the reply      |
|  [04]   | Interaction | `kAENeverInteract`  | `0x10`   | `NSAppleEventSendNeverInteract`  | receiver never fronts UI               |
|  [05]   | Interaction | `kAECanInteract`    | `0x20`   | `NSAppleEventSendCanInteract`    | receiver may front UI                  |
|  [06]   | Interaction | `kAEAlwaysInteract` | `0x30`   | `NSAppleEventSendAlwaysInteract` | receiver always fronts UI              |
|  [07]   | Modifier    | `kAECanSwitchLayer` | `0x40`   | `NSAppleEventSendCanSwitchLayer` | permits a layer switch to the receiver |
|  [08]   | Modifier    | `kAEDontReconnect`  | `0x80`   | none                             | suppresses automatic session reconnect |
|  [09]   | Modifier    | `kAEWantReceipt`    | `0x200`  | none                             | requests a transport return receipt    |
|  [10]   | Modifier    | `kAEDontRecord`     | `0x1000` | `NSAppleEventSendDontRecord`     | excludes the event from recording      |
|  [11]   | Modifier    | `kAEDontExecute`    | `0x2000` | `NSAppleEventSendDontExecute`    | builds the event without executing it  |

`NSAppleEventSendOptions` adds one net-new flag, `NSAppleEventSendDontAnnotate` (`kAEDoNotAutomaticallyAddAnnotationsToEvent`), which suppresses the sandbox annotations the system otherwise stamps onto the event. `NSAppleEventSendDefaultOptions` composes `NSAppleEventSendWaitForReply | NSAppleEventSendCanInteract`, so a sender that names neither axis still blocks its run loop and still permits receiver UI.

`kAEDoNotPromptForUserConsent` (`0x00020000`) turns a send into a consent probe: a sender that OR-s it into `AESendMode` and cannot surface UI receives `errAEEventWouldRequireUserConsent` in place of the consent sheet. This mode drives background-safe permission checks without spending the one visible prompt on a non-user-initiated path.

Reply parsing separates application errors from transport status. `AESendMessage` returns transport and policy status as its own `OSStatus`; the reply event carries application-level failure through `keyErrorNumber`, `keyErrorString`, `keyErrorBriefMessage`, and an offending-object descriptor. A sender folds both rails into one typed error value before the result reaches calling code, because a transport success can still wrap an application failure.

## [05]-[HARDENED_RUNTIME_ENTITLEMENTS]

`com.apple.security.automation.apple-events` gates Automation prompting under the hardened runtime — it is a Boolean right carried by the signed executable that sends the event, and a helper app, login item, XPC service, or applet earns its own signed identity and its own copy of the entitlement whenever it is the process that actually talks to `appleeventsd`.

`NSAppleEventsUsageDescription` binds the visible reason string, and the key lives in the bundle of the process that requests Automation consent. A missing or misplaced value turns first-use prompting into a denial path for an SDK-linked app, because the system withholds the prompt when it cannot present a reason.

## [06]-[TCC_AUTOMATION_RECORD]

TCC Automation rows bind sender identity, receiver identity, and code requirement under the service `kTCCServiceAppleEvents`. Grants live in the `access` table of the per-user store at `~/Library/Application Support/com.apple.TCC/TCC.db`; the system store at `/Library/Application Support/com.apple.TCC/TCC.db` sits behind SIP under the `com.apple.rootless.storage.TCC` entitlement and reads only under Full Disk Access.

Each `access` row keys on `(service, client, client_type, indirect_object_identifier)`. `client` carries the sender identity, `client_type` is `0` for a bundle ID and `1` for an absolute path, and the `csreq` column carries the sender's code-requirement blob. Each row is a relation across both endpoints: the target application rides `indirect_object_identifier`, and the target's own code requirement rides `indirect_object_code_identity`.

| [INDEX] | [AUTH_VALUE] | [MEANING] |
| :-----: | :----------: | :-------- |
|  [01]   |     `0`      | denied    |
|  [02]   |     `1`      | unknown   |
|  [03]   |     `2`      | allowed   |
|  [04]   |     `3`      | limited   |

| [INDEX] | [AUTH_REASON] | [MEANING]      |
| :-----: | :-----------: | :------------- |
|  [01]   |      `2`      | user consent   |
|  [02]   |      `3`      | user set       |
|  [03]   |      `5`      | service policy |
|  [04]   |      `6`      | MDM policy     |
|  [05]   |     `11`      | entitled       |

Columns `pid_version`, `boot_uuid`, `last_modified`, and `last_reminded` bind the grant to one process generation and reminder cadence. `tccutil reset AppleEvents [bundle-id]` is the sanctioned reset path — it clears the client-to-target relationship rows and forces re-consent. Resetting a sender, moving a path-identified binary, or changing receiver identity invalidates an existing approval. `csreq` is a code-requirement predicate, not a fixed hash, so a stable Team-ID-plus-bundle-ID designated requirement carries the grant across rebuilds and re-signs, while an ad-hoc or cdhash-pinned identity mints a fresh code identity on every rebuild, stops satisfying the stored requirement, and silently fails the next send with `errAEEventNotPermitted` (`-1743`); an agent that rebuilds an applet signs it under a stable designated requirement or re-earns consent every build. Enterprise pre-grants flow through PPPC, never through direct `TCC.db` edits.

## [07]-[AUDIT_TOKEN_ATTRIBUTION]

`keySenderPIDAttr` (`'spid'`) and `keySenderAuditTokenAttr` (`'tokn'`) both ride the event, but `tccd` charges the request against the audit token, because a raw PID is kernel-recycled and the window between an `AESend` and TCC resolution is a confused-deputy surface where a recycled PID misattributes a grant. That audit token carries the PID, a `pidversion` generation counter, and the UID set, so it stays collision-free across process death.

`keyActualSenderAuditToken` (`'acat'`) names the responsible token when a helper acts on behalf of a parent, and EndpointSecurity surfaces the same concept as `responsible_audit_token` on `es_process_t`.

## [08]-[PREFLIGHT_AND_ERROR_TRIAD]

`AEDeterminePermissionToAutomateTarget` owns explicit preflight and takes four positional arguments in order — target address descriptor, event class, event ID, ask-user flag. Its target `AEAddressDesc` must identify a running application; `theAEEventClass` and `theAEEventID` bind a specific command, while `typeWildCard` tests broad target automation. Its ask-user flag selects a visible-prompt path or a silent-status path, and the call is thread-safe and UI-blocking. Preflight runs from an explicit permission lane. `descriptorWithBundleIdentifier:` yields a `typeApplicationBundleID` descriptor for any string, installed or not, so an absent or stopped receiver surfaces as `procNotFound` (`-600`) from the call itself, never as a nil descriptor.

```objc conceptual
typedef NS_ENUM(NSInteger, AutomationConsent) {
    AutomationConsentGranted,
    AutomationConsentDenied,
    AutomationConsentWouldPrompt,
    AutomationConsentTargetNotRunning,
    AutomationConsentFailed
};

static AutomationConsent CheckAutomationConsent(
    NSString *bundleID, AEEventClass eventClass, AEEventID eventID,
    Boolean prompt, OSStatus *rawStatus
) {
    NSAppleEventDescriptor *target = [NSAppleEventDescriptor descriptorWithBundleIdentifier:bundleID];
    OSStatus status = AEDeterminePermissionToAutomateTarget(target.aeDesc, eventClass, eventID, prompt);
    if (rawStatus != NULL) *rawStatus = status;

    switch (status) {
        case noErr: return AutomationConsentGranted;
        case errAEEventNotPermitted: return AutomationConsentDenied;
        case errAEEventWouldRequireUserConsent: return AutomationConsentWouldPrompt;
        case procNotFound: return AutomationConsentTargetNotRunning;
        default: return AutomationConsentFailed;
    }
}
```

```swift conceptual
func checkAutomationConsent(
    bundleID: String, eventClass: AEEventClass, eventID: AEEventID, askUserIfNeeded: Boolean
) -> (status: OSStatus, verdict: String) {
    let target = NSAppleEventDescriptor(bundleIdentifier: bundleID)
    guard let descriptor = target.aeDesc else { return (paramErr, "descriptorUnavailable") }

    let status = AEDeterminePermissionToAutomateTarget(descriptor, eventClass, eventID, askUserIfNeeded)
    switch status {
    case noErr: return (status, "granted")
    case errAEEventNotPermitted: return (status, "denied")
    case errAEEventWouldRequireUserConsent: return (status, "wouldPrompt")
    default: return (status, "failed")
    }
}
```

| [INDEX] | [CODE]  | [SYMBOL]                            | [MEANING]                                                       |
| :-----: | :-----: | :---------------------------------- | :-------------------------------------------------------------- |
|  [01]   | `-1742` | `errAETargetAddressNotPermitted`    | sender-to-target reachability policy blocks the address         |
|  [02]   | `-1743` | `errAEEventNotPermitted`            | a standing user denial exists for this Automation pair          |
|  [03]   | `-1744` | `errAEEventWouldRequireUserConsent` | the target is undecided and reached through a suppressed prompt |

`-1744` is undecided, never a denial: a silent path returns it for an undecided target while a standing denial surfaces only as `-1743`, a true ask-user preflight yields the authoritative `noErr`/`-1743` verdict at the cost of a visible prompt, and a background checker routes `-1744` to the explicit permission lane.

## [09]-[SANDBOX_AND_ENTERPRISE_POLICY]

App Sandbox carries a separate automation policy layer beneath TCC. A sandboxed receiver always accepts and responds to events sent to itself; a sandboxed sender needs scripting-targets or temporary Apple-events exceptions to cross the app-sandbox boundary at all, and the request still crosses TCC Automation afterward where that policy applies.

`com.apple.security.scripting-targets` binds receiver-declared access groups: the receiver's `sdef` annotates a terminology subset, the sender entitlement names the receiver bundle ID and its group strings, and the system admits only that declared slice. This is the fine-grained path for Mac App Store automation against a cooperative receiver.

```xml template
<key>com.apple.security.scripting-targets</key>
<dict>
  <key>com.apple.mail</key>
  <array>
    <string>com.apple.mail.compose</string>
  </array>
</dict>
```

`com.apple.security.temporary-exception.apple-events` is a broad sender-to-target exception reserved for receivers without access groups, reviewed as a bounded compatibility declaration. Finder and System Events targets carry high rejection and abuse pressure, because either entitlement turns into broad operating-system control.

MDM PPPC pre-grants encode the same sender/receiver graph declaratively. Profile payload `com.apple.TCC.configuration-profile-policy` carries `Services` entries, and each `AppleEvents` entry names sender `Identifier`, `IdentifierType`, and `CodeRequirement` alongside receiver identity fields. A designated `CodeRequirement` is the stable trust anchor — a bundle ID alone never constitutes an enterprise grant.

```xml template
<key>Services</key>
<dict>
  <key>AppleEvents</key>
  <array>
    <dict>
      <key>Identifier</key>
      <string>com.example.AutomationHost</string>
      <key>IdentifierType</key>
      <string>bundleID</string>
      <key>CodeRequirement</key>
      <string>identifier "com.example.AutomationHost" and anchor apple generic</string>
      <key>AEReceiverIdentifier</key>
      <string>com.apple.Terminal</string>
      <key>AEReceiverIdentifierType</key>
      <string>bundleID</string>
      <key>AEReceiverCodeRequirement</key>
      <string>identifier "com.apple.Terminal" and anchor apple</string>
      <key>Authorization</key>
      <string>Allow</string>
    </dict>
  </array>
</dict>
```

PPPC merging is restrictive: multiple payloads can land on one Mac, and conflicting policy collapses to the more restrictive outcome. Fleet automation treats a generated profile as a receipt from an observed sender-target pair, then hand-curates receiver identity and code requirements before deployment.

## [10]-[DIAGNOSTIC_RAILS]

TCC diagnostics start at attribution. `log stream --debug --predicate 'subsystem == "com.apple.TCC" AND eventMessage BEGINSWITH "AttributionChain"'` names the binary actually charged for a request, and that binary is the one that owns the entitlement, the usage string, the PPPC sender identity, and the user-facing remediation copy. That unified-log format is private.

`ES_EVENT_TYPE_NOTIFY_TCC_MODIFY` is the EndpointSecurity primitive an automation observer binds, firing on any TCC grant or revoke including `kTCCServiceAppleEvents`. Its `es_event_tcc_modify_t` exposes `service`, `identity`, `identity_type` (`es_tcc_identity_type_t`: bundle ID, executable path, file-provider domain, policy ID), `update_type` (`es_tcc_event_type_t`), `instigator_token` (an `audit_token_t` by value), `instigator` (`es_process_t *`), a nullable `responsible_token`/`responsible` pair, and one `right`/`reason` field. That struct carries no prior-versus-current value pair — it observes a decision change, not per-event access, and a CLI-initiated grant attributes to the parent process. Continuous automation monitoring composes `ES_EVENT_TYPE_NOTIFY_TCC_MODIFY` for policy transitions, the `com.apple.TCC` unified-log rail for attribution chains, and EndpointSecurity process events carrying `audit_token`/`responsible_audit_token` for the acting identity.

## [11]-[HOST_SURFACE_AND_PLATFORM_POSTURE]

`osascript` inherits the invoking terminal's TCC identity. A script launched from Terminal, a CI runner, an editor, or an agent shell is attributed to that host process, never to the script file, so durable Automation consent belongs to a signed app, helper, or command-line tool whose identity owns the prompt.

Compiled scripts change identity only when packaged as executables. A flat compiled script still runs under the invoking host, while an applet runs as a signed bundle carrying its own `Info.plist` and entitlements, so only a launched, signed bundle shifts TCC attribution away from the invoking host. Language choice changes syntax, never the security envelope.

An ASObjC script calling a protected framework such as CoreLocation fires no automatic consent prompt, so that grant comes from a manual toggle in System Settings. An OS update resets standing automation approvals, so a production consent lane rechecks authorization on every launch rather than trusting a stored grant.

## [12]-[SECURITY_PATTERNS]

A least-privilege sender splits automation by process identity: broad System Events control, browser-tab automation, mail composition, and app-specific data extraction run through separate signed helpers whenever their privilege, prompt copy, PPPC receiver graph, or enterprise deployment cadence differs, turning TCC's sender identity into the isolation boundary.

An automation gateway refuses to dispatch events to credential stores and self-privileging surfaces — Keychain Access, password managers, Terminal, System Settings — by target identity, because those receivers convert one compromised sender into credential exfiltration or a privilege pivot; the allowlist of reachable receivers stays narrower than the set TCC otherwise permits.

Object-model automation replaces UI-event fallback wherever a receiver dictionary exposes the needed command. `System Events` keyboard and mouse scripting routes the request through Accessibility and Post Event services, expanding PPPC scope and weakening receiver semantics, so a receiver dictionary command, a direct CoreServices event, or an app-native API owns the workflow whenever a semantic automation surface exists.

Resigning or relocating a helper changes the Automation contract and triggers PPPC regeneration and fresh consent testing.

A string that reaches `do shell script` parses once as AppleScript source and again through `/bin/sh`, so a single-layer escape leaks straight through. User values enter only as fully escaped AppleScript string literals and, for shell arguments, only through `quoted form of`, joined with `& space &`. A static pass rejects the escalation classes before the source compiles: `with administrator privileges`, `sudo`, a pipe into a shell, and a keystroke carrying a secret.

```applescript rejected
set shellCmd to "rm -rf " & userSuppliedPath
do shell script shellCmd
```

```applescript accepted
set safePath to quoted form of userSuppliedPath
do shell script "rm -rf " & safePath
```

Audit receipts hash the payload and never store it: a script body carries secrets, so the durable receipt persists a source digest and non-secret outcome fields, never a secret-bearing body that outlives the send.

## [13]-[FAILURE_SHAPES]

| [INDEX] | [SIGNAL]                                   | [MEANING]                                 | [NEXT_ACTION]                               |
| :-----: | :----------------------------------------- | :---------------------------------------- | :------------------------------------------ |
|  [01]   | `errAEEventNotPermitted`, no prompt        | missing entitlement, usage, or TCC denial | fix entitlement, usage, or helper identity  |
|  [02]   | `errAEEventWouldRequireUserConsent`        | caller chose a silent preflight/send path | explicit permission lane, no silent retry   |
|  [03]   | `procNotFound` from preflight              | no running receiver for the descriptor    | launch the receiver, preflight again        |
|  [04]   | an installed PPPC profile fails at runtime | sender/receiver requirement or type clash | regenerate profile from sender-target pair  |
|  [05]   | Automation failure only under a CI runner  | headless runner: no prompt, no TCC state  | ship signed fixture + pre-installed PPPC    |
|  [06]   | nil Scripting Bridge app instance          | receiver/dictionary absent, not TCC       | verify bundle ID + running state first      |
|  [07]   | scripting Finder for plain file work       | sender overprivileged for the task        | use Foundation/security-scoped bookmarks    |
|  [08]   | broad classes, no access groups            | forces broad TCC grants on callers        | annotate `sdef` families, publish group IDs |
