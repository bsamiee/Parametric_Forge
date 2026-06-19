{
  available: true,
  status: {
    arch: ($status.arch // null),
    runtime: ($status.runtime // null),
    driver: ($status.driver // null),
    kubernetes: (if $status | has("kubernetes") then $status.kubernetes else null end),
    cpu: ($status.cpu // null),
    memory: ($status.memory // null),
    disk: ($status.disk // null),
    mountType: ($status.mount_type // null)
  } + if $diagnostic then {dockerSocketRedacted: ($status.docker_socket != null), containerdSocketRedacted: ($status.containerd_socket != null)} else {} end,
  raw: null
}
