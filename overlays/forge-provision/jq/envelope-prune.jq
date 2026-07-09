. + {
  error: (if $ok then null else {code: "docker-unavailable", message: "Docker unavailable or rejected during prune", exitCode: 1} end),
  resources: (.resources + {owned: {containers: $containers, volumes: $volumes, networks: $networks}, runtime: {dockerAvailable: $dockerAvailable, includeVolumes: $includeVolumes}}),
  artifacts: (.artifacts + {generated: $generated})
}
