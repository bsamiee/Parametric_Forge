.[]
| [
    "port",
    "service=\(.service)",
    "env=\(.env)",
    "value=\(.value)",
    "state=\(.state)",
    "occupied=\(.occupied)",
    "owner=\(.owner)",
    "container_id=\(.containerId // "-")",
    "name=\(.name // "-")",
    "image=\(.image // "-")",
    "compose_project=\(.composeProject // "-")",
    "compose_service=\(.composeService // "-")",
    "provision_project=\(.provisionProject // "-")",
    "host_listener_pid=\(.hostListenerPid // "-")",
    "host_listener_command=redacted"
  ]
| join("\t")
