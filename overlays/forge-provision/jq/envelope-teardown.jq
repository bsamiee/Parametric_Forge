. + {
  error: (
    if $ok then null
    elif $dockerAvailable then {code: "cleanup-failed", message: ("owned resource cleanup failed during " + $mode), exitCode: 1}
    else {code: "docker-unavailable", message: ("Docker unavailable or rejected during " + $mode), exitCode: 1}
    end
  ),
  resources: (.resources + {
    owned: {containers: $containers, volumes: $volumes, networks: $networks},
    runtime: (
      {dockerAvailable: $dockerAvailable}
      + (if $mode == "down" then {cleanupPolicy: "preserve-volumes"} else {includeVolumes: $includeVolumes} end)
    )
  }),
  artifacts: (.artifacts + {generated: $generated})
}
