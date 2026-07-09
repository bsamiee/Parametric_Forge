.[]
| select([
    .NetworkSettings.Ports[]?[]?
    | select(.HostPort == $port and (.HostIp == "127.0.0.1" or .HostIp == "::1" or .HostIp == "0.0.0.0" or .HostIp == "::" or .HostIp == ""))
  ] | length > 0)
| .Id
