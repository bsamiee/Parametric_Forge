. + {ports: $ports, resources: (.resources + {runtime: {dockerAvailable: $dockerAvailable, dockerIssue: (if $dockerAvailable then null else $dockerIssue end)}})}
