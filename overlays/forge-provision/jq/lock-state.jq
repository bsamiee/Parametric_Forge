def empty_null: if . == "" then null else . end;
{present: $present, active: $active, state: $state, pidAlive: $pidAlive, heartbeatStale: $heartbeatStale, command: ($command | empty_null)}
+ if $diagnostic then {ownerMetadataRedacted: true} else {} end
