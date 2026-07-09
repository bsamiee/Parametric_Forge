.[0].NetworkSettings.Ports[]?[]?
| select(.HostPort == $port and (.HostIp == "127.0.0.1" or .HostIp == "::1"))
