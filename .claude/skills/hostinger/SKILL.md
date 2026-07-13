---
name: hostinger
description: >-
    Hostinger estate operations across the whole account API: the domain portfolio (registration,
    DNS zone records, nameservers, forwarding, WHOIS, lock and privacy), the VPS fleet (lifecycle,
    Docker Compose projects, firewalls, SSH keys, snapshots, recovery, PTR, metrics), shared hosting
    and WordPress (websites, installs, plugins, themes, databases, Node.js apps, cache, cron, PHP),
    ecommerce stores and products, Reach email marketing, and billing catalog, payment methods, and
    subscriptions. Use when registering or transferring domains, editing DNS, deploying or
    troubleshooting a VPS or its Docker projects, managing a website, WordPress install, or database,
    standing up a store, running email campaigns, or resolving a Hostinger catalog, payment, or
    subscription. Declarative IaC provisioning through the Pulumi Hostinger provider belongs to pulumi.
---

# [HOSTINGER]

The Hostinger estate is one API surface with three entry lanes, and the lane is chosen by the work's shape, never by habit. Maghz — the durable second brain — runs on the Hostinger VPS, so VPS mutations are production operations: snapshot before destructive work, and route lifecycle through the sanctioned lanes below.

| [INDEX] | [LANE]          | [SURFACE]                                                     | [WHEN]                                          |
| :-----: | :-------------- | :------------------------------------------------------------ | :---------------------------------------------- |
|  [01]   | `hostinger` MCP | `domains` `DNS` `VPS` `hosting` `ecommerce` `reach` `billing` | Interactive agent operations — the default lane |
|  [02]   | REST API        | `https://developers.hostinger.com` with `HOSTINGER_API_TOKEN` | Scripts, CI, bulk loops, SDK-driven automation  |
|  [03]   | SSH             | Universal key in `~/.ssh/config`                              | On-box work: deploys, logs, compose, migrations |

The MCP tool names mirror the REST resources one-to-one (`VPS_createSnapshotV1` is `POST /api/vps/v1/virtual-machines/{id}/snapshot`), so every REST row in the references reads as an MCP row and vice versa. REST authenticates with `Authorization: Bearer $HOSTINGER_API_TOKEN`; official SDKs (Python, TypeScript, PHP) and the `hapi` CLI wrap the same endpoints.

## [01]-[ROUTING]

- [01]-[DOMAINS](references/domains.md): portfolio, availability and purchase, nameservers and DNS zone records, forwarding, WHOIS profiles, lock and privacy, verification, outbound transfer, bulk audit. Open for any domain or DNS task.
- [02]-[VPS](references/vps.md): VM lifecycle and actions, Docker Manager projects, firewall law and patterns, SSH keys, templates, post-install scripts, backups and snapshots, recovery mode, Monarx, PTR, metrics, troubleshooting. Open for any server task.
- [03]-[DEPLOYMENT](references/deployment.md): the SSH-first deployment workflow for Dockerized apps: baseline, deploy and update order, verification levels, rollback, and the SSH-versus-API split. Open when deploying or updating an application on a VPS.
- [04]-[HOSTING](references/hosting.md): the shared-hosting account surface — websites, WordPress installs, plugins, themes, databases, Node.js apps, cache, cron, PHP, and the Horizons AI builder. Open for any shared-hosting or WordPress task.
- [05]-[ECOMMERCE](references/ecommerce.md): stores, products, sales channels, and the payment and shipping prerequisites. Open for any storefront task.
- [06]-[REACH](references/reach.md): email marketing — sender profiles and deliverability, contacts, and behavioral segments. Open for any campaign or contact task.
- [07]-[BILLING](references/billing.md): the catalog item-id grammar, payment methods, and subscriptions. Open when resolving a purchase, payment method, or renewal.

## [02]-[STANDING_LAW]

- [SNAPSHOT_FIRST]: A snapshot precedes every destructive operation — recreate, backup restore, migration. One snapshot exists per VM; creating a new one overwrites it.
- [FIREWALL_SYNC]: Firewall rule changes take effect only after an explicit sync to the VM; an unsynced change leaves the box on stale rules. One firewall binds per VM, and the default policy drops all inbound traffic.
- [DESTRUCTIVE_CONFIRMATION]: VM recreate, backup restore, snapshot restore, Docker project `down`, WordPress installation deletion with files or database, and domain deletion are irreversible; explicit operator confirmation of the specific target precedes each.
- [ASYNC_ACTIONS]: VM mutations return an action resource; completion is confirmed by polling the action, never assumed.
- [ASYNC_HOSTING]: Website creation and every WordPress, plugin, theme, core, and Node.js build mutation is fire-and-poll — the queuing `2xx` carries no completion, confirmed only by re-polling the matching list.
- [PURCHASES]: A purchase consumes a catalog price `item_id` and rides the resource endpoint that owns it — domains, VPS — never a generic billing order; a payment method is added in hPanel, never through the API.
- [DNS_OWNERSHIP]: The Hostinger DNS API acts only while the domain uses Hostinger nameservers; after delegation to an external provider, records live there.
- [SECRETS]: The API token enters commands as `$HOSTINGER_API_TOKEN`, never inline; command output with embedded credentials never lands in transcripts.
