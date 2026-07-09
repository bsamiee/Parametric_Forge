{
  schemaVersion: $schemaVersion,
  command: $command,
  ok: false,
  warnings: $warnings,
  error: {code: $code, message: $message, exitCode: $exitCode},
  auth: {},
  portPolicy: {},
  services: {},
  ports: [],
  resources: {counts: {}, owned: {containers: [], volumes: [], networks: []}, images: [], dockerDisk: [], runtime: {}},
  artifacts: {generated: [], plan: null},
  extensions: {catalog: [], results: [], summary: {}},
  tools: {surfaces: {}, summary: {}}
} + if $project == null then {} else {project: $project} end
