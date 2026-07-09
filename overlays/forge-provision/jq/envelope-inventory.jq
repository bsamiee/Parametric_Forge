. + {
  ports: $ports,
  resources: {
    counts: $counts,
    owned: {containers: $containers, volumes: $volumes, networks: $networks},
    images: $images,
    dockerDisk: $dockerDisk,
    runtime: {
      dockerAvailable: $dockerAvailable,
      configuredImages: $configuredImages,
      lock: $lock,
      colima: $colima,
      nonOwnedCleanupPolicy: "diagnostic-only"
    }
  },
  artifacts: (.artifacts + {generated: $generated})
}
