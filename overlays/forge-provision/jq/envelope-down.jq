. + {
  error: (if $dockerAvailable then null else {code: "docker-unavailable", message: "Docker unavailable or rejected during down", exitCode: 1} end),
  resources: (.resources + {owned: {containers: $containers, volumes: [], networks: $networks}, runtime: {dockerAvailable: $dockerAvailable, cleanupPolicy: "preserve-volumes"}}),
  artifacts: (.artifacts + {generated: $generated})
}
