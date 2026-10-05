# One identity predicate serves every container projection; $ARGS.named.mode selects the shape:
# identity -> boolean for jq -e, report-row -> one US-joined row, owned -> sorted JSON array.
def identity_issue($c; $expected; $net):
  if $c == null or $expected == null then "unknown-service"
  elif ($expected.image != null and (($c.Config.Image // "") != $expected.image)) then "image-mismatch"
  elif (($c.NetworkSettings.Networks // {})[$net]) == null then "network-mismatch"
  elif (any($c.Mounts[]?; .Name == $expected.volume and .Destination == $expected.mount) | not) then "volume-mount-mismatch"
  else null end;

$ARGS.named.mode as $mode
| if $mode == "identity" then
    (.[0] // null) as $c
    | identity_issue($c; {image: null, volume: $ARGS.named.volume, mount: $ARGS.named.mount}; $ARGS.named.net) == null
  elif $mode == "report-row" then
    (.[0] // null) as $c
    | (($c.Config.Labels // {})[$ARGS.named.service_label] // "") as $service
    | ($ARGS.named.identities[$service] // null) as $expected
    | (identity_issue($c; $expected; $ARGS.named.net)) as $issue
    | (if $c == null then ["-", "-", "-", "-"]
       else [
           (($c.Name // "-") | ltrimstr("/")),
           ($c.Config.Image // "-"),
           ($c.State.Status // "-"),
           (if $c.State.Health then $c.State.Health.Status else "none" end)
         ]
       end) as $fields
    | [$service] + $fields + [(($issue == null) | tostring), ($issue // "-")]
    | join("\u001f")
  else
    map(
      (.Config.Labels[$ARGS.named.service_label] // "") as $service
      | ($ARGS.named.identities[$service] // null) as $expected
      | (identity_issue(.; $expected; $ARGS.named.net)) as $issue
      | {
          id: .Id,
          name: (.Name | ltrimstr("/")),
          image: .Config.Image,
          service: $service,
          owner: (.Config.Labels[$ARGS.named.owner_label] // ""),
          root: (.Config.Labels[$ARGS.named.root_label] // ""),
          project: (.Config.Labels[$ARGS.named.project_label] // ""),
          status: .State.Status,
          health: (if .State.Health then .State.Health.Status else "none" end),
          ports: (.NetworkSettings.Ports // {}),
          identityOk: ($issue == null),
          identityIssue: $issue
        }
    ) | sort_by(.service, .name, .id)
  end
