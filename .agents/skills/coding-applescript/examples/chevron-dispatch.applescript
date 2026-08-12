-- Pattern : A dispatch rail whose load-bearing verbs are chevron literals. Each row carries both a
--           raw-code send against a runtime-chosen target and the term send the dictionary compiled,
--           a probe elects one per verb, and an osadecompile census receipts terminology drift.
-- Run     : osascript chevron-dispatch.applescript [bundle-id]
use AppleScript version "2.8"
use scripting additions

-- A retired term still sends its compiled code and the target answers -1708 (event not handled) before any
-- work happens; object and coercion faults are domain failures owned by the rail that raised them.
property absentTerminology : {-1708}
property defaultBundleID : "com.apple.finder"

-- Every row owns the same send twice. The code half compiles with no dictionary resolution and holds a
-- runtime-chosen target, which resolves no terminology at all; the term half compiles only because a
-- literal target let the dictionary in at compile time, so it is the half an .sdef revision can retire.
on verbRows(bundleID)
	script WindowCount
		property verb : "windowCount"
		on viaCode()
			tell application id bundleID to return count window
		end viaCode
		on viaTerm()
			tell application "Finder" to return count windows
		end viaTerm
	end script
	
	script FirstDiskName
		property verb : "firstDiskName"
		on viaCode()
			tell application id bundleID to return «event coregetd» name of «class cdis» 1
		end viaCode
		on viaTerm()
			tell application "Finder" to return name of disk 1
		end viaTerm
	end script
	
	-- A rectangle crosses as four big-endian SInt16 fields, and the compiler coerces no list into that
	-- shape under a runtime-chosen target, so the payload rides as raw typeQDRectangle bytes.
	script FrameFrontWindow
		property verb : "frameFrontWindow"
		on viaCode()
			tell application id bundleID
				«event coresetd» bounds of window 1 given «class data»:«data qdrt0000000000C8012C»
			end tell
			return "framed"
		end viaCode
		on viaTerm()
			tell application "Finder" to set bounds of window 1 to {0, 0, 300, 200}
			return "framed"
		end viaTerm
	end script
	
	return {WindowCount, FirstDiskName, FrameFrontWindow}
end verbRows

-- Terminology presence is a runtime property of the installed target, so the probe asks the term rail first
-- and elects the code rail on an absence fault alone. Any other fault is the domain's and stays attributed
-- to the rail that raised it, which keeps one verb's failure off the other rows.
on dispatch(row)
	try
		return {verb:row's verb, rail:"term", value:(row's viaTerm())}
	on error message number n
		if absentTerminology does not contain n then ¬
			return {verb:row's verb, rail:"term", faultNumber:n, message:message}
	end try
	try
		return {verb:row's verb, rail:"chevron", value:(row's viaCode())}
	on error message number n
		return {verb:row's verb, rail:"chevron", faultNumber:n, message:message}
	end try
end dispatch

-- A chevron the compiler resolves decompiles back to its term, so the codes surviving a compile-decompile
-- round trip are exactly the ones no installed terminology defines. That census is the version-drift
-- receipt: it rises the release a dictionary retires a term this rail sends, and the rail keeps working.
on driftReceipt()
	set sourcePath to POSIX path of (path to me)
	set workDir to do shell script "/usr/bin/mktemp -d /tmp/chevron.XXXXXX"
	set compiledPath to workDir & "/rail.scpt"
	do shell script "/usr/bin/osacompile -o " & quoted form of compiledPath & " " & quoted form of sourcePath
	set unresolved to (do shell script ¬
		"/usr/bin/osadecompile " & quoted form of compiledPath & " | /usr/bin/grep -c '«' || true") as integer
	do shell script "/bin/rm -rf " & quoted form of workDir
	return {source:sourcePath, unresolvedCodeLines:unresolved}
end driftReceipt

on run argv
	set bundleID to defaultBundleID
	if (count of argv) > 0 then set bundleID to item 1 of argv
	set results to {}
	repeat with row in verbRows(bundleID)
		set end of results to dispatch(contents of row)
	end repeat
	return {target:bundleID, dispatched:results, drift:driftReceipt()}
end run
