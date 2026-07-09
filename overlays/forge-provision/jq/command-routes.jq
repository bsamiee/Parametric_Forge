.[]
| [
    .verb,
    .handler,
    (if .json then "1" else "0" end),
    .argspec,
    (if .mutates then "1" else "0" end),
    .lockMode,
    (if .diagnosticJson then "1" else "0" end),
    .description
  ]
| @tsv
