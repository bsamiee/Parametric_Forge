. + {
  ports: $ports,
  resources: (.resources + {owned: {containers: $containers, volumes: [], networks: []}, runtime: {dockerAvailable: $dockerAvailable, dockerIssue: (if $dockerAvailable then null else $dockerIssue end), lock: $lock}}),
  state: (
    ($services | to_entries | map(.value)) as $serviceList
    | if ($dockerAvailable | not) then "docker-unavailable"
      elif ($containers | length) == 0 then "empty"
      elif any($containers[]; .identityOk == false) then "stale"
      elif any($containers[]; (($services[.service].enabled // false) | not)) then "stale"
      elif any($serviceList[]; . as $svc | $svc.enabled and ([ $containers[] | select(.service == $svc.key and .status == "running") ] | length) != 1) then "partial"
      elif any($containers[]; .status != "running") then "partial"
      else "present"
      end
  )
}
