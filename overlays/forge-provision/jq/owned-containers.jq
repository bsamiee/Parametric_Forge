map(
  (.Config.Labels[$service_label] // "") as $service
  | ($identities[$service] // null) as $expected
  | (($expected != null)
      and (.Config.Image == $expected.image)
      and ((.NetworkSettings.Networks // {})[$net] != null)
      and any(.Mounts[]?; .Name == $expected.volume and .Destination == $expected.mount)) as $identityOk
  | {
      id: .Id,
      name: (.Name | ltrimstr("/")),
      image: .Config.Image,
      service: $service,
      owner: (.Config.Labels[$owner_label] // ""),
      root: (.Config.Labels[$root_label] // ""),
      project: (.Config.Labels[$project_label] // ""),
      status: .State.Status,
      health: (if .State.Health then .State.Health.Status else "none" end),
      ports: (.NetworkSettings.Ports // {}),
      identityOk: $identityOk,
      identityIssue: (
        if $identityOk then null
        elif $expected == null then "unknown-service"
        elif .Config.Image != $expected.image then "image-mismatch"
        elif ((.NetworkSettings.Networks // {})[$net] == null) then "network-mismatch"
        else "volume-mount-mismatch"
        end
      )
    }
) | sort_by(.service, .name, .id)
