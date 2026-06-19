split("\n")
| map(select(length > 0) | split("\t"))
| map({
    service: .[0],
    extension: .[1],
    category: .[2],
    required: (.[3] == "1"),
    createOnApply: (.[4] == "1"),
    kind: .[5],
    sourcePackage: .[6],
    preloadRequired: (.[7] == "1"),
    selfProvisioned: (.[8] == "1"),
    devGated: (.[9] == "1"),
    expectedService: .[10],
    riskClass: .[11],
    requiresSuperuser: (.[12] == "1"),
    requiresSharedPreload: (.[13] == "1"),
    fileAccess: (.[14] == "1"),
    networkAccess: (.[15] == "1"),
    backgroundWorker: (.[16] == "1"),
    createPolicy: .[17],
    sourceRoute: .[18],
    sourceKind: .[19],
    nixStatus: .[20],
    probeKind: .[21],
    capabilityRank: .[22],
    externalAccess: .[23],
    restartClass: .[24],
    serviceProfile: .[25],
    imageTag: .[26],
    loadPolicy: .[27]
  })
| sort_by(.service, .category, .extension)
