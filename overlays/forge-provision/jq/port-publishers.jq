.[]
| select([
    .NetworkSettings.Ports[]?[]?
    | select(.HostPort == $port and (.HostIp | IN("127.0.0.1", "::1", "0.0.0.0", "::", "")))
  ] | length > 0)
| .Id
