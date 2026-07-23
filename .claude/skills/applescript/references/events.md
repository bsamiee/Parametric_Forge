# [EVENTS]

An Apple Event is a typed cross-process capability request.

## [01]-[EVENT_ENVELOPE]

`AEEventClass` selects the suite and `AEEventID` selects the verb; `keyDirectObject` carries the primary operand and keyed parameters carry secondary operands. Transport attributes ride beside the payload: `keyAddressAttr` names the destination, `keyEventClassAttr`/`keyEventIDAttr` mirror the envelope for inspection, `keyReturnIDAttr` and `keyTransactionIDAttr` correlate replies and grouped sends, `keyTimeoutAttr` bounds the wait, `keyEventSourceAttr` marks provenance, and `keySenderPIDAttr`/`keySenderAuditTokenAttr` carry sender identity.

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
    CFIndex length = CFStringGetLength(bundleID);
    if (CFStringGetBytes(bundleID, CFRangeMake(0, length), kCFStringEncodingUTF8,
                         0, false, (UInt8 *)target, sizeof target, &used) != length) {
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

Reply parsing separates application errors from transport status. `AESendMessage` returns transport status as its own `OSStatus`; the reply event carries application-level failure through `keyErrorNumber`, `keyErrorString`, `keyErrorBriefMessage`, and an offending-object descriptor. A sender folds both rails into one typed error value before the result reaches calling code, because a transport success can still wrap an application failure.

## [05]-[SECURITY_PATTERNS]

An automation gateway refuses to dispatch events to credential stores and self-privileging surfaces — Keychain Access, password managers, Terminal, System Settings — by target identity, because those receivers convert one compromised sender into credential exfiltration or a privilege pivot.

Object-model automation replaces UI-event fallback wherever a receiver dictionary exposes the needed command. `System Events` keyboard and mouse scripting routes the request through Accessibility and Post Event services, weakening receiver semantics, so a receiver dictionary command, a direct CoreServices event, or an app-native API owns the workflow whenever a semantic automation surface exists.

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

## [06]-[FAILURE_SHAPES]

| [INDEX] | [SIGNAL]                             | [MEANING]                          | [NEXT_ACTION]                            |
| :-----: | :----------------------------------- | :--------------------------------- | :--------------------------------------- |
|  [01]   | nil Scripting Bridge app instance    | receiver/dictionary absent         | verify bundle ID + running state first   |
|  [02]   | scripting Finder for plain file work | sender overprivileged for the task | use Foundation/security-scoped bookmarks |
