-- Pattern : Reach the four-character Apple Event ABI beneath terminology — chevron literals
--           from source and NSAppleEventDescriptor list/record surgery from Foundation.
-- Run     : osascript raw-apple-event-codes.applescript
use framework "Foundation"
use scripting additions

-- Chevron literals («class XXXX», «event XXXXYYYY», «constant ****XXXX») compile with no dictionary
-- resolution, so a load-bearing verb survives an .sdef the release retired. osadecompile emits them for
-- any term the dictionary dropped — a version-drift receipt, not corruption.
on chevronRead()
	tell application id "com.apple.finder"
		return name of document 1
	end tell
end chevronRead

-- Descriptor lists are one-based; insertDescriptor:atIndex:0 appends. Building descriptors
-- directly is the surgery layer under whose filters and cross-process replies that must
-- survive coercion the language otherwise performs silently.
on aeDescList(xs)
	set NSAED to current application's NSAppleEventDescriptor
	set d to NSAED's listDescriptor()
	repeat with x in xs
		(d's insertDescriptor:(NSAED's descriptorWithString:(contents of x as text)) atIndex:0)
	end repeat
	return d
end aeDescList

-- A record walk pairs keywordForDescriptorAtIndex: with descriptorAtIndex: so four-character
-- keys survive; numeric indexing alone drops them.
on recordFields(recordDescriptor)
	set out to {}
	repeat with i from 1 to (recordDescriptor's numberOfItems() as integer)
		set keyword to (recordDescriptor's keywordForDescriptorAtIndex:i)
		set valueDescriptor to (recordDescriptor's descriptorAtIndex:i)
		set end of out to {keyword:(keyword as integer), value:(valueDescriptor's stringValue() as text)}
	end repeat
	return out
end recordFields

-- The reference out-parameter carries a Foundation error back as a value; the |error| bars
-- quote the reserved word. A missing value result with a populated error is the sentinel.
on parseJSON(t)
	set d to (current application's NSString's stringWithString:t)'s dataUsingEncoding:(current application's NSUTF8StringEncoding)
	set {obj, err} to current application's NSJSONSerialization's JSONObjectWithData:d options:0 |error|:(reference)
	if obj is missing value then error (err's localizedDescription() as text) number 9200
	return obj
end parseJSON

on run
	set built to aeDescList({"alpha", "beta", "gamma"})
	return {itemCount:(built's numberOfItems() as integer), secondValue:((built's descriptorAtIndex:2)'s stringValue() as text)}
end run
