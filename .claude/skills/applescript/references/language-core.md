# [LANGUAGE_CORE]

AppleScript's language core compiles English-like syntax into an OSA object-specifier and Apple-event-descriptor program running over a mutable script-object runtime; each rule here governs that compiled machine, not the English-like surface.

## [01]-[SCRIPT_OBJECT_ALGEBRA]

A script object carries properties, handlers, nested script objects, and a `parent` property that forms a live dispatch edge. A child handler sharing a name with a parent handler shadows it; `continue` inside the child resumes the first parent-chain handler of that name and returns control to the child afterward. A property read or written through an unshadowed identifier resolves through `parent` at the ancestor's declared slot, so a child mutating an inherited property mutates the ancestor's cell.

```applescript conceptual
script baseScript
    property xs : {}
    on push(x)
        copy x to end of my xs
        return xs
    end push
end script
script childScript
    property parent : baseScript
    on push(x)
        set inheritedResult to continue push(x)
        return {inheritedResult, xs of baseScript}
    end push
end script
tell childScript to push(7)
```

A `script` object declared inside a handler captures the enclosing handler's parameters as its own initialized properties — the native closure and object-constructor surface, since each call mints a distinct script object with a distinct property cell.

```applescript conceptual
on makeAccumulator(seed)
    script accumulator
        property total : seed
        on add(x)
            set my total to my total + x
            return my total
        end add
    end script
    return accumulator
end makeAccumulator
set counterA to makeAccumulator(10)
set counterB to makeAccumulator(10)
tell counterA to add(5)
```

`counterA` and `counterB` own independent `total` cells; mutating one never touches the other's captured seed.

## [02]-[PARAMETER_SURFACES]

Handler spelling is an API boundary, not a style choice. Positional parameters `on name(x, y)` favor internal algebra; labeled `to name given label:value` and `to selector:x selector:y` forms favor script-command readability; interleaved word-plus-label handlers give script objects and `my` calls a selector-like surface.

```applescript conceptual
to clipValues in xs above floor given inclusive:inclusiveFlag
    set out to {}
    repeat with x in xs
        if (inclusiveFlag and x >= floor) or ((not inclusiveFlag) and x > floor) then set end of out to contents of x
    end repeat
    return out
end clipValues
to minOf:x maxOf:y
    if x < y then return x
    return y
end minOf:maxOf:
set clipped to clipValues in {1, 2, 3} above 2 with inclusive
set minimumValue to my minOf:3 maxOf:2
```

User-defined `given` labels commute freely by label; built-in command labels such as `above`, `from`, `thru`, and `into` remain positional in meaning even inside a free-reading sentence.

## [03]-[TELL_AND_DISPATCH]

A bare handler call inside an application `tell` block targets the application's own command set unless `my` or `of me` overrides dispatch to route the call to the enclosing script object instead.

```applescript conceptual
on localName(x)
    return "local:" & x
end localName
tell current application
    set localResult to my localName("finder-context")
    set hostName to name
end tell
```

`my` and `of me` are dispatch overrides, not ornament — the same override protects a Standard Additions command from being shadowed by an imported application's terminology inside the same `tell` block.

## [04]-[REFERENCE_AND_VALUE_SEMANTICS]

`set` binds a name to whatever the right-hand specifier resolves to at that point; for mutable classes — lists, records, dates, script objects — that binding is a shared reference, and mutation through one alias is visible through the other. `copy` forces value duplication, severing the shared cell. `a reference to` wraps an assignable specifier in an explicit reference object, keeping an application object specifier lazily unresolved and giving list-tail mutation a stable target that survives reassignment of the container name; `contents of` forces that reference to its live value.

```applescript conceptual
set xs to {1, 2}
set shared to xs
copy 3 to end of shared
copy xs to detached
copy 4 to end of detached
set xr to a reference to xs
copy 5 to end of xr
return {xs, detached, contents of xr}
```

## [05]-[AEDESC_BOUNDARY]

Every AppleScript value crosses a process boundary as an Apple event descriptor: a four-character type code plus payload, or for containers, a nested descriptor list or keyed descriptor record. `NSAppleEventDescriptor` addresses this ABI directly, and inspecting it at a bridge boundary distinguishes a language coercion fault from a transport fault from an application dictionary defect. A list descriptor is built with `listDescriptor()` and grown with `insertDescriptor:atIndex:0`, which appends under the one-based `NSAppleEventDescriptor` insertion contract; a record descriptor is walked with `keywordForDescriptorAtIndex:` paired against `descriptorAtIndex:` so its four-character keys survive, since positional indexing alone drops them.

```applescript conceptual
use framework "Foundation"
set NSAED to current application's NSAppleEventDescriptor
set d to NSAED's listDescriptor()
repeat with x in {"a", "b", "c"}
    (d's insertDescriptor:(NSAED's descriptorWithString:x) atIndex:0)
end repeat
```

A Cocoa method returning through an `NSError **` out-parameter binds in AppleScript to the literal keyword `reference`, and the call destructures a `{result, errorOut}` pair; `result` is `missing value` with the error populated on the failure path. The parameter label `error` requires vertical bars because `error` is a reserved word — the rail that carries every Foundation JSON, regex, date-formatter, and atomic-file failure back into AppleScript as a value instead of a raw exception.

```applescript conceptual
use framework "Foundation"
set d to (current application's NSString's stringWithString:"{}")'s dataUsingEncoding:(current application's NSUTF8StringEncoding)
set {obj, err} to current application's NSJSONSerialization's JSONObjectWithData:d options:0 |error|:(reference)
if obj is missing value then error (err's localizedDescription() as text) number 9200
```

## [06]-[COERCION_RAILS]

`as` invokes AppleScript's and the Apple Event Manager's coercion handlers. A coercion rail names the source and target class explicitly at every ingress and egress where the caller's class can vary, and a failed coercion raises `-1700` (`errAECoercionFail`).

```applescript conceptual
if class of x is alias then return POSIX path of x
if class of x is file then return POSIX path of x
if class of x is text then return POSIX path of (POSIX file x)
error "unsupported path input" number -1700 from x to "alias | file | POSIX text"
```

Coercion is asymmetric and lossy in one direction: `record as list` discards labels and yields values in declaration order, while `list as record` has no defined handler. `text` subsumes `string` and `Unicode text`, so `class of "x"` returns `text` and a dictionary naming `string` coerces to `text`. Numeric coercion honors the active `considering numeric strings` attribute for text-to-number conversion, and a malformed numeral faults `-1700` rather than silently yielding zero. A coercion chain is single-step: `x as list as text` performs two independent coercions through an intermediate value, and each step faults independently — a rail names the intermediate class whenever the source-to-target pair has no direct handler.

## [07]-[FILTER_REFERENCES]

`whose`, `where`, and `that` compile to filter reference forms over an application's own object containers. They never filter AppleScript lists, records, or text values. Parentheses bind a filtered object specifier before a later container phrase applies.

```applescript conceptual
tell application id "com.apple.finder"
    set homeFolder to path to home folder
    set hits to every file of homeFolder whose name extension is "scpt" or name extension is "applescript"
    set scriptNames to name of (files whose name extension is "scpt") in homeFolder
end tell
```

The implicit `it` inside a predicate names the candidate object under test; `it` outside the predicate remains the current `tell` target. An application that implements the filter evaluates the predicate itself; one that does not forces the script to materialize and test every candidate.

## [08]-[CONSIDERING_IGNORING]

The comparison attribute stack is a lexically scoped policy of seven independent attributes — `case`, `diacriticals`, `hyphens`, `punctuation`, `white space`, `expansion`, and `numeric strings` — read by text equality, ordering, `contains`, and `text item delimiters` alike. The default active set ignores `case` and `numeric strings` while considering the rest, so `"a" = "A"` is true unwrapped but magnitude ordering is opt-in. `expansion` (ligature folding) is inert. `considering numeric strings` orders embedded digit runs by magnitude, giving `"1.10" > "1.9"` and `"item2" < "item10"` without a custom parser, and `considering X but ignoring Y` composes the full stack in one clause.

```applescript conceptual
considering numeric strings but ignoring case and white space
    "1.10" > "1.9"
end considering
```

`application responses` shares this grammar but governs Apple event transport, not text comparison: `ignoring application responses` sends a targeted command fire-and-forget, and any reply read inside that block requires an inner `considering application responses`. `text item delimiters` is a related but distinct piece of global interpreter state, owned by the `AppleScript` object; every mutation of it is a try-restored critical section, because an unhandled error inside the block leaves the delimiter set for every later script that reads it. Splitting treats every delimiter string in the list as a separator, while joining via `xs as text` uses only the first — one property with asymmetric split and join semantics, and both honor whatever `considering`/`ignoring` attributes are active, so a case-sensitive split needs `considering case` pinned around the delimiter mutation, not merely around the read.

```applescript conceptual
set oldDelimiters to AppleScript's text item delimiters
try
    considering case
        set AppleScript's text item delimiters to "x"
        set pieces to text items of "aXbxb"
    end considering
    set AppleScript's text item delimiters to oldDelimiters
on error message number n from source to target partial result partial
    set AppleScript's text item delimiters to oldDelimiters
    error message number n from source to target partial result partial
end try
```

## [09]-[COLLECTION_MECHANICS]

List construction appends efficiently through `a reference to` the destination cell; repeated `set xs to xs & {x}` rebuilds the entire list on every append and collapses under large inputs. A `repeat with x in xs` loop variable is a reference to the list item, not its value; `contents of x` forces a value snapshot where the loop body must store the value rather than a live reference.

```applescript conceptual
set out to {}
set outRef to a reference to out
repeat with i from 1 to 5
    copy (i * i) to end of outRef
end repeat
```

Record labels are compile-time identifiers resolved against the active terminology, not runtime string keys — a record is a dense static product type, never a dictionary.

```applescript conceptual
set receipt to {ok:true, value:42, diagnostics:{}}
set valueCell to a reference to value of receipt
set contents of valueCell to 43
```

Dynamic keyed data belongs in a Cocoa dictionary reached through AppleScriptObjC, in an application record with known terminology, or in parallel lists carrying an explicit index algebra; a runtime string never addresses a native record field.

## [10]-[ERROR_RECEIPTS]

An AppleScript error carries a message, a number, an optional source object (`from`), an optional target class or value (`to`), and an optional partial result. A production handler preserves every field when translating a domain fault rather than collapsing it to a message string.

```applescript conceptual
on guardedDivide(x, y)
    try
        if y = 0 then error "zero divisor" number 9001 from x to y partial result {x}
        return {ok:true, value:x / y}
    on error message number n from source to target partial result partial
        return {ok:false, number:n, source:source, target:target, partial:partial, message:message}
    end try
end guardedDivide
```

A selective handler binds directly to the number clause instead — `on error number -49` skips the message/from/to/partial capture entirely when only the fault identity matters. A rethrow restates every original field; `error message` alone discards the machine-readable provenance the caller relies on.

## [11]-[CODE_AND_STATE_BOUNDARIES]

`run script` compiles and executes text, a file, an alias, a script value, or a compiled OSA payload against an explicit parameter vector — a dynamic code boundary where every caller-supplied string becomes executable code, so a generator assembles payloads from closed templates plus escaped values, never from raw untrusted strings.

```applescript conceptual
set loader to "on run argv" & linefeed & "return item 1 of argv & \"/\" & item 2 of argv" & linefeed & "end run"
run script loader with parameters {"a", "b"}
```

The OSA file-kind rail distinguishes source, compiled script, and script bundle before any tool invokes `osacompile`, `osascript`, `NSAppleScript`, or `OSAScript` against a path; the extensions are conventional.

| [INDEX] | [UTTYPE]                 | [IDENTIFIER]                          | [ROLE]                             | [EXTENSION]    |
| :-----: | :----------------------- | :------------------------------------ | :--------------------------------- | :------------- |
|  [01]   | `UTType.appleScript`     | `com.apple.applescript.text`          | Text source                        | `.applescript` |
|  [02]   | `UTType.osaScript`       | `com.apple.applescript.script`        | Compiled OSA script data           | `.scpt`        |
|  [03]   | `UTType.osaScriptBundle` | `com.apple.applescript.script-bundle` | Compiled bundle carrying resources | `.scptd`       |

`NSAppleScript` owns text-or-URL script loading, compilation, execution, and structured error dictionaries at the Foundation boundary; OSAKit's `OSAScript` owns richer editor and compiled-script workflows over the same runtime, and Automator's `AMAppleScriptAction` compiles to an `OSAScript` instance underneath.

```applescript conceptual
use framework "Foundation"
set scriptObject to current application's NSAppleScript's alloc()'s initWithSource:"return 40 + 2"
set errorInfo to missing value
set resultDescriptor to scriptObject's executeAndReturnError:errorInfo
return resultDescriptor's stringValue() as text
```

`store script` serializes a live script object — properties, handlers, and its `parent` link — into a compiled `.scpt` container; `load script` rehydrates it into an executable value, giving AppleScript a durable object-graph and memoization surface with no database.

```applescript conceptual
use scripting additions
on loadOrSeed(pathText, seed)
    set f to POSIX file pathText
    try
        return (load script f)
    on error number -1700
        script fresh
            property state : seed
            on bump()
                set my state to my state + 1
                return my state
            end bump
        end script
        store script fresh in f replacing yes
        return fresh
    end try
end loadOrSeed
```

Loading a missing POSIX file raises `-1700` (a coercion fault), not a file-not-found number, so the seed path binds to `-1700` rather than `-43`. `replacing yes` overwrites without a Finder prompt; an existing target with `replacing` omitted raises `-48`. A loaded script object is a detached in-memory copy whose mutations persist only when the caller re-`store`s after mutating it. `store script` and `load script` compile only when `use scripting additions` accompanies a `use framework` import, and `store script` cannot coerce a script object once Foundation is imported into the same top level — the ASObjC bridge reclassifies the object and the store faults `-1700`. Script persistence therefore stays isolated on a pure-AppleScript surface, apart from ASObjC-bearing code, and loading a foreign compiled script carries the same trust profile as `run script`.

Within a single running script, `property` values persist with the compiled script object until recompilation while `global` values persist across handler calls within one run but reset with each fresh compilation; a handler cannot declare a `property`, and a local declaration shadows a same-named property or global for the remainder of that handler.

```applescript conceptual
property cachedCount : 0
global sessionCount
on bump()
    try
        set sessionCount to sessionCount + 1
    on error
        set sessionCount to 1
    end try
    set cachedCount to cachedCount + 1
    return {cachedCount, sessionCount}
end bump
```

Top-level executable statements form an implicit `run` handler, and a script object cannot carry both an implicit and an explicit `run` handler at once; an explicit `on run argv` handler is the entry point `osascript` and compiled applets invoke with command-line parameters, while a library exposes handlers and script objects with no top-level effects at all.

## [12]-[TERMINOLOGY_AND_TEXT_ALGEBRA]

An application's `.sdef` dictionary decides which terms compile; AppleScript syntax is the presentation layer over the underlying Apple event code map. `using terms from application "Mail"` imports a dictionary's terminology for a handler such as `perform mail action with messages` without changing the command target; `use application` imports terminology at compile time and admits multi-application term composition that one `tell` target cannot express. When a term is absent, misspelled, or deliberately bypassed, a chevron literal addresses the Apple event ABI directly with no dictionary resolution — the source-level peer of `NSAppleEventDescriptor` construction: `«event XXXXYYYY»` names an event by four-character class and id, `«class XXXX»` names a type or property code, `«constant ****XXXX»` names an enumerator, and `«data XX...»` carries raw descriptor bytes.

```applescript conceptual
tell application id "com.apple.finder"
    set nameValue to «class pnam» of «class docu» 1
end tell
```

`osadecompile` emits chevron literals for any compiled script referencing terminology the current dictionary no longer defines; a compile/decompile round-trip against a target whose `.sdef` changed surfaces every unresolved term as a raw code, a version-drift receipt rather than corruption. A rail that must survive dictionary churn pins its load-bearing verbs as chevron literals rather than terms a future OS release may retire. Text is likewise a sequenced container with a fixed element vocabulary — `characters`, `words`, `paragraphs`, and `text items` — and every element form takes `every`, `item N`, `items X thru Y`, negative indices, `first`, `last`, `middle`, and `some`; word and paragraph segmentation is Unicode-aware and locale-influenced, while `text items` alone is delimiter-driven and therefore deterministic against the active `text item delimiters`. Character identity is the Unicode code point — `id of t` returns one integer for a single character and a list of code points for longer text, and `character id N` plus `string id {…}` invert it, the codepoint-exact rail that the Mac Roman `ASCII character`/`ASCII number` pair cannot express — as in `id of "café"` against `string id {72, 105}`.

## [13]-[HANDLER_DISPATCH]

AppleScript has no first-class function type, but a single-handler script object is a first-class behavior value: a record of such objects is a dispatch table, and a list of them is a pipeline. This collapses an `if class` ladder or a family of parallel handlers into one polymorphic surface. Dispatch keys by value, never by record label, since record labels are compile-time identifiers a runtime string cannot index; the table is a list of `{key, obj}` rows searched by the key's value.

```applescript conceptual
on strategyTable()
    script upper
        on apply(t)
            return do shell script "printf %s " & quoted form of t & " | tr a-z A-Z"
        end apply
    end script
    script tagged
        on apply(t)
            return "[" & t & "]"
        end apply
    end script
    return {{key:"upper", obj:upper}, {key:"tagged", obj:tagged}}
end strategyTable
on runStrategy(name, t)
    repeat with row in strategyTable()
        if key of row = name then return (obj of row)'s apply(t)
    end repeat
    error "unknown strategy " & name number 9101
end runStrategy
```

A script object closes over its constructor's parameters, so a handler that returns one is a parameterized strategy factory; the call site holds the resolved `obj` as a value and invokes it without a second branch on the strategy name.

## [14]-[VOCABULARY_AND_VERSION_GATE]

The `AppleScript` top-level object exposes read-only vocabulary constants — `pi`, `space`, `tab`, `return`, `linefeed`, `quote`, `version`, and time-span constants in integer seconds — that a rail treats as vocabulary rather than as literals. Date components (`hours`, `minutes`, `day`, `time`) are settable in place against a `date` value with no string reparse.

```applescript conceptual
set d to (current date) + (1 * days)
set hours of d to 9
set minutes of d to 0
set seconds of d to 0
```

`AppleScript's version` returns a version object ordered by component rather than by string, so a comparison against `"2.8"` is a true numeric comparison; `use AppleScript version "2.8"` declares a compile-time capability floor, and the macOS 26 component is 2.8. A script declaring that floor fails to compile on an older component instead of misbehaving at runtime — the language's own capability gate.

Vertical-bar identifiers admit reserved words and arbitrary characters as record labels, handler names, and variables, addressing a field whose spelling collides with terminology the compiler otherwise claims.

```applescript conceptual
set row to {|id|:7, |class|:"widget", |name|:"gadget"}
{|id| of row, |class| of row}
```

## [15]-[COMPOSITION_PATTERN]

A dense language-core module owns one script object carrying policy rows, constructor handlers, and receipt-shaped errors in a single surface — state, policy, text-comparison semantics, delimiter cleanup, and fault translation live in one owner, and every call site consumes the rail instead of re-deriving delimiter discipline and error shape per script.

```applescript conceptual
script TextRail
    property parent : AppleScript
    property policies : {strictCase:true, delimiter:","}
    on configure given strictCase:strictCaseFlag, delimiter:delimiterText
        set my policies to {strictCase:strictCaseFlag, delimiter:delimiterText}
    end configure
    on split(t)
        set oldDelimiters to AppleScript's text item delimiters
        try
            set AppleScript's text item delimiters to delimiter of my policies
            if strictCase of my policies then
                considering case
                    set resultValue to text items of t
                end considering
            else
                set resultValue to text items of t
            end if
            set AppleScript's text item delimiters to oldDelimiters
            return {ok:true, value:resultValue}
        on error message number n from source to target partial result partial
            set AppleScript's text item delimiters to oldDelimiters
            return {ok:false, number:n, source:source, target:target, partial:partial, message:message}
        end try
    end split
end script
tell TextRail to configure with strictCase given delimiter:"x"
tell TextRail to split("aXbxb")
```
