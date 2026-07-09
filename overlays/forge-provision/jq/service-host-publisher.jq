.[0].NetworkSettings.Ports[]?[]?
| select(.HostPort == $port and .HostIp == $host)
