-- Title    : applescript-library
-- Purpose  : A reusable AppleScript kernel compiled to a .scpt/.scptd library. One dense
--            script object owns policy rows, receipt-shaped errors, delimiter critical
--            sections, and AppleScriptObjC JSON and atomic-write rails. Consumers call
--            stable exported handlers and pass every variable as an argument.
-- Build    : osacompile -o ~/Library/Script\ Libraries/AutomationKernel.scpt AutomationKernel.applescript
-- Consume  : use AutomationKernel : script "AutomationKernel"  (then AutomationKernel's capture(...))
-- Replace  : <domain handlers> beneath the rails with the operations the library owns.
use AppleScript version "2.8"
use framework "Foundation"
use scripting additions

property parent : AppleScript
property policies : {strictCase:true, delimiter:",", timeoutSeconds:30}

-- Receipt rail: every fallible operation returns a record, never a bare value, preserving
-- the full error structure so a caller distinguishes cancel, denial, missing, and coercion.
on capture(operationName, thunk)
	try
		return {ok:true, operation:operationName, value:(run thunk)}
	on error message number n partial result partial from offender to expected
		return {ok:false, operation:operationName, number:n, message:message, partial:partial, offender:offender, expected:expected}
	end try
end capture

-- Delimiter mutation is global interpreter state, so every split is a try-restored
-- critical section that honors the strict-case policy row.
on split(t)
	set oldDelimiters to AppleScript's text item delimiters
	try
		if strictCase of my policies then
			considering case
				set AppleScript's text item delimiters to delimiter of my policies
				set out to text items of t
			end considering
		else
			set AppleScript's text item delimiters to delimiter of my policies
			set out to text items of t
		end if
		set AppleScript's text item delimiters to oldDelimiters
		return {ok:true, value:out}
	on error message number n partial result partial from offender to expected
		set AppleScript's text item delimiters to oldDelimiters
		return {ok:false, number:n, message:message, partial:partial, offender:offender, expected:expected}
	end try
end split

-- Foundation owns JSON: the |error| bars quote the reserved word and the reference
-- out-parameter carries the parse fault back as a value.
on parseJSON(jsonText)
	set sourceString to current application's NSString's stringWithString:jsonText
	set jsonData to sourceString's dataUsingEncoding:(current application's NSUTF8StringEncoding)
	set {value, parseError} to current application's NSJSONSerialization's JSONObjectWithData:jsonData options:0 |error|:(reference)
	if value is missing value then error (parseError's localizedDescription() as text) number 9200
	return value
end parseJSON

-- Atomic UTF-8 write through Foundation; open for access is a compatibility path, not
-- the primary writer.
on writeUTF8(textValue, posixPath)
	set sourceString to current application's NSString's stringWithString:textValue
	set targetPath to (current application's NSString's stringWithString:posixPath)'s stringByExpandingTildeInPath()
	set {ok, writeError} to sourceString's writeToFile:targetPath atomically:true encoding:(current application's NSUTF8StringEncoding) |error|:(reference)
	if ok is false then error (writeError's localizedDescription() as text) number 9201
	return targetPath as text
end writeUTF8

-- considering numeric strings orders embedded digit runs by magnitude — the version and
-- sequence sort rail with no custom parser.
on compareVersions(a, b)
	considering numeric strings but ignoring case and white space
		if a = b then return 0
		if a < b then return -1
		return 1
	end considering
end compareVersions

-- Bounded remote read: with timeout budgets hostile application latency and the receipt
-- records the target, selector, and budget as fault coordinates.
on boundedName(appName)
	try
		with timeout of (timeoutSeconds of my policies) seconds
			tell application appName to return {ok:true, value:name}
		end timeout
	on error message number n
		return {ok:false, application:appName, budget:(timeoutSeconds of my policies), number:n, message:message}
	end try
end boundedName

on configure given strictCase:strictCaseFlag, delimiter:delimiterText, timeoutSeconds:budget
	set my policies to {strictCase:strictCaseFlag, delimiter:delimiterText, timeoutSeconds:budget}
	return me
end configure
