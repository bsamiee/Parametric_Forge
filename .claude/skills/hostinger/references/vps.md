# [HOSTINGER_VPS]

VPS fleet law: VM lifecycle, Docker Manager projects, firewalls, SSH keys, provisioning surfaces, backups and snapshots, recovery, malware scanning, and metrics. REST rows map one-to-one onto the `hostinger` MCP `VPS_*` tools; every mutation returns an async action polled to completion via `GET .../actions/{actionId}`.

## [01]-[LIFECYCLE]

A VM moves `initial` → `running` → `stopped`; a VM in `initial` state needs setup before anything else. Purchase takes an `item_id` from the billing catalog, an OS `template_id` (`GET /api/vps/v1/templates`), and a `data_center_id` (`GET /api/vps/v1/data-centers`).

```bash template
# Purchase, then setup when the VM lands in initial state
curl -X POST "https://developers.hostinger.com/api/vps/v1/virtual-machines" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN" -H "Content-Type: application/json" \
  -d '{ "item_id": "hostingercom-vps-kvm2-usd-1m", "payment_method_id": <payment-method-id>,
        "template_id": 1, "data_center_id": 1, "hostname": "my-server", "password": "..." }'
curl -X POST "https://developers.hostinger.com/api/vps/v1/virtual-machines/12345/setup" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN" -H "Content-Type: application/json" \
  -d '{ "template_id": 1, "data_center_id": 1, "hostname": "my-server", "password": "..." }'

# start / stop / restart are POSTs on the VM path; hostname and root-password are PUTs
curl -X POST "https://developers.hostinger.com/api/vps/v1/virtual-machines/12345/restart" -H "Authorization: Bearer $HOSTINGER_API_TOKEN"
```

`POST .../recreate` reinstalls the OS and destroys all data — snapshot first, confirm with the operator, and meet the password policy: 12+ characters, mixed case, numbers, screened against leaked-password databases.

## [02]-[DOCKER_MANAGER]

Docker Manager deploys Compose projects through the API from inline content, a GitHub repo URL (auto-resolves `docker-compose.yaml` on the master branch), or any URL returning raw compose content. Deploying under an existing project name replaces that project — the zero-config redeploy path. Hostinger marks these endpoints subject to change; a production deployment with an existing compose file takes the SSH lane instead.

```bash copy-safe
curl -X POST "https://developers.hostinger.com/api/vps/v1/virtual-machines/12345/docker" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN" -H "Content-Type: application/json" \
  -d '{ "project_name": "my-app", "url": "https://github.com/user/repo" }'

# containers-with-stats, logs (last 300), lifecycle verbs
curl -X GET  ".../docker/my-app/containers" -H "Authorization: Bearer $HOSTINGER_API_TOKEN"
curl -X GET  ".../docker/my-app/logs"       -H "Authorization: Bearer $HOSTINGER_API_TOKEN"
curl -X POST ".../docker/my-app/update"     -H "Authorization: Bearer $HOSTINGER_API_TOKEN"   # pulls images, recreates, keeps volumes
curl -X DELETE ".../docker/my-app/down"     -H "Authorization: Bearer $HOSTINGER_API_TOKEN"   # irreversible: networks, volumes, images
```

Troubleshooting rows: a restart-looping container reads its `logs` first (missing env, wrong image, port conflict); one service binds a host port at a time; disk pressure shows in `GET .../metrics`; a GitHub URL failure means the compose file is absent from the master-branch root — use the raw file URL for other branches.

## [03]-[FIREWALLS]

Firewalls are account-level resources activated per VM. Default policy drops all inbound traffic; one firewall binds per VM; every rule change requires an explicit sync to take effect — an unsynced firewall is the first suspect when SSH or a service is unreachable.

```bash copy-safe
curl -X POST "https://developers.hostinger.com/api/vps/v1/firewall" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN" -H "Content-Type: application/json" -d '{ "name": "web-server" }'
curl -X POST "https://developers.hostinger.com/api/vps/v1/firewall/1/rules" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN" -H "Content-Type: application/json" \
  -d '{ "protocol": "tcp", "port": "443", "source": "0.0.0.0/0", "action": "accept" }'
curl -X POST "https://developers.hostinger.com/api/vps/v1/firewall/1/activate/12345" -H "Authorization: Bearer $HOSTINGER_API_TOKEN"
curl -X POST "https://developers.hostinger.com/api/vps/v1/firewall/1/sync/12345"     -H "Authorization: Bearer $HOSTINGER_API_TOKEN"
```

Rule-set patterns by role — ports accept `"3000:3999"` range syntax, and `source` narrows to `/32` for restricted access:

| [INDEX] | [ROLE]          | [ACCEPT_RULES]                                                          |
| :-----: | :-------------- | :---------------------------------------------------------------------- |
|  [01]   | Web server      | 22, 80, 443 from `0.0.0.0/0`                                            |
|  [02]   | Database server | 22 from the admin IP `/32`; 5432 or 3306 from the app server `/32` only |
|  [03]   | Docker host     | 22, 80, 443, plus the app port range (e.g. `3000:3999`)                 |
|  [04]   | Mail server     | 22, 25, 465, 587, 143, 993                                              |

Hardening rows: SSH narrows to known IPs where feasible; database ports never open to `0.0.0.0/0`; unused rules and firewalls are removed (deleting a firewall auto-deactivates it everywhere); switching firewalls is deactivate-then-activate.

## [04]-[SSH_KEYS]

Keys register at account level and attach per VM; a key in the account but unattached does not authenticate. Attachment is the first check when SSH refuses a key, firewall sync the second.

```bash copy-safe
curl -X POST "https://developers.hostinger.com/api/vps/v1/public-keys" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN" -H "Content-Type: application/json" \
  -d '{ "name": "deploy-key", "key": "ssh-ed25519 AAAA... user@host" }'
curl -X POST "https://developers.hostinger.com/api/vps/v1/public-keys/attach/12345" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN" -H "Content-Type: application/json" -d '{ "ids": [1, 2] }'
```

## [05]-[DATA_SAFETY]

- [BACKUPS]: Hostinger-managed periodic captures — `GET .../backups`, `POST .../backups/{id}/restore`. A restore overwrites all VM data.
- [SNAPSHOTS]: Operator-initiated point-in-time captures — `POST/GET/DELETE .../snapshot`, `POST .../snapshot/restore`. One per VM; a new snapshot overwrites the old. Snapshot precedes every destructive operation.
- [RECOVERY]: `POST .../recovery` boots a rescue image with the original disk mounted at `/mnt` for filesystem repair; `DELETE .../recovery` exits. A VM stuck refusing to start is checked for active recovery mode.
- [POST_INSTALL]: Scripts run after VM installation as `/post_install` with output at `/post_install.log`, capped at 48KB — `GET/POST/PUT/DELETE /api/vps/v1/post-install-scripts`.
- [MONARX]: `GET/POST/DELETE .../monarx` manages the malware scanner; production servers run it.
- [PTR]: `POST/DELETE .../ptr/{ipId}` manages reverse-DNS records — required for mail deliverability.
- [METRICS]: `GET .../metrics?date_from=...&date_to=...` returns CPU, memory, disk, network, and uptime for plan right-sizing and disk-pressure checks.

## [06]-[API_REFERENCE]

| [INDEX] | [METHOD]              | [ENDPOINT]                                                | [DESCRIPTION]                            |
| :-----: | :-------------------- | :-------------------------------------------------------- | :--------------------------------------- |
|  [01]   | `GET/POST`            | `/api/vps/v1/virtual-machines`                            | List; purchase                           |
|  [02]   | `GET`                 | `/api/vps/v1/virtual-machines/{id}`                       | VM details                               |
|  [03]   | `POST`                | `.../{id}/setup`, `start`, `stop`, `restart`, `recreate`  | Lifecycle verbs (recreate destroys data) |
|  [04]   | `PUT/DELETE`          | `.../{id}/hostname`                                       | Set / reset hostname                     |
|  [05]   | `PUT`                 | `.../{id}/root-password`, `panel-password`, `nameservers` | Credentials and resolvers                |
|  [06]   | `GET`                 | `.../{id}/metrics`, `public-keys`, `actions`              | Telemetry, attached keys, action history |
|  [07]   | `GET/POST/DELETE`     | `.../{id}/docker[/{name}/...]`                            | Docker Manager projects                  |
|  [08]   | `GET/POST/DELETE`     | `/api/vps/v1/firewall[/{id}/...]`                         | Firewalls, rules, activate, sync         |
|  [09]   | `GET/POST/DELETE`     | `/api/vps/v1/public-keys[...]`                            | SSH keys; attach                         |
|  [10]   | `GET`                 | `/api/vps/v1/templates`, `data-centers`                   | OS templates, data centers               |
|  [11]   | `GET/POST/PUT/DELETE` | `/api/vps/v1/post-install-scripts`                        | Provisioning scripts                     |
|  [12]   | `GET/POST/DELETE`     | `.../backups`, `snapshot`, `recovery`, `ptr`, `monarx`    | Data safety and security surfaces        |
