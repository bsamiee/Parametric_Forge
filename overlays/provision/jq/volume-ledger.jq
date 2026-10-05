{
  schemaVersion: $schemaVersion,
  project: $project,
  generation: $generation,
  createdAt: $createdAt,
  auth: {mode: $authMode, risk: $authRisk},
  rollback: {persistentVolumesIntact: true, eligibility: "compose-generation-only", imageStability: "best-effort-image-tag"},
  volumes: (
    $services
    | to_entries
    | map({service: .key, volume: ($volumePrefix + "-" + .key + "-data"), enabled: .value.enabled})
    | sort_by(.service)
  )
}
