.[]
| [
    .service,
    .role,
    .profile,
    (if .enabledEnv == "" then "-" else .enabledEnv end),
    .enabledDefault,
    .imageEnv,
    .imageDefault,
    .portEnv,
    .portDefault,
    .dsnEnv,
    .volumeMount,
    .preload,
    .applySqlKey,
    .host,
    (.containerPort | tostring),
    .databaseName,
    .databaseUser
  ]
| @tsv
