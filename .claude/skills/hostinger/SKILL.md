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

Hostinger's estate is one API surface with three entry lanes, and the work's shape chooses the lane, never habit. Maghz — the durable second brain — runs on the Hostinger VPS, so VPS mutations are production operations: snapshot before destructive work, and route lifecycle through the sanctioned lanes below.

| [INDEX] | [LANE]          | [SURFACE]                                                     | [WHEN]                                          |
| :-----: | :-------------- | :------------------------------------------------------------ | :---------------------------------------------- |
|  [01]   | `hostinger` MCP | `domains` `DNS` `VPS` `hosting` `ecommerce` `reach` `billing` | Interactive agent operations — the default lane |
|  [02]   | REST API        | `https://developers.hostinger.com` with `HOSTINGER_API_TOKEN` | Scripts, CI, bulk loops, SDK-driven automation  |
|  [03]   | SSH             | Universal key in `~/.ssh/config`                              | On-box work: deploys, logs, compose, migrations |

MCP tool names mirror the REST resources one-to-one (`VPS_createSnapshotV1` is `POST /api/vps/v1/virtual-machines/{id}/snapshot`), so every REST row in the references reads as an MCP row and vice versa. REST authenticates with `Authorization: Bearer $HOSTINGER_API_TOKEN`; official SDKs (Python, TypeScript, PHP) and the `hapi` CLI wrap the same endpoints.

## [01]-[ROUTING]

- [01]-[DOMAINS](references/domains.md): registration, nameservers, DNS zone records, forwarding, WHOIS profiles, lock, privacy, transfer, bulk audit
- [02]-[VPS](references/vps.md): VM lifecycle, Docker Manager, firewalls, SSH keys, post-install, backups, snapshots, recovery, Monarx, PTR, metrics
- [03]-[DEPLOYMENT](references/deployment.md): SSH-first Docker deploys — baseline, update order, verification levels, rollback, SSH-versus-API split
- [04]-[HOSTING](references/hosting.md): websites, WordPress installs, plugins, themes, databases, Node.js apps, cache, cron, PHP, Horizons AI builder
- [05]-[ECOMMERCE](references/ecommerce.md): stores, products, sales channels, payment and shipping prerequisites
- [06]-[REACH](references/reach.md): email marketing — sender profiles, deliverability, contacts, behavioral segments
- [07]-[BILLING](references/billing.md): catalog item-id grammar, payment methods, subscriptions, renewals

## [02]-[STANDING_LAW]

- [SNAPSHOT_FIRST]: A snapshot precedes every destructive operation — recreate, backup restore, migration. One per VM, overwritten by the next.
- [FIREWALL_SYNC]: Firewall rule changes take effect only after an explicit sync to the VM; unsynced, the box runs stale rules.
- [FIREWALL_BINDING]: One firewall binds per VM, and the default policy drops all inbound traffic.
- [DESTRUCTIVE_CONFIRMATION]: Explicit operator confirmation of the specific target precedes every irreversible act.
- [IRREVERSIBLE]: VM recreate, backup and snapshot restore, Docker project `down`, WordPress install deletion with files or database, domain deletion.
- [ASYNC_ACTIONS]: VM mutations return an action resource; completion is confirmed by polling the action, never assumed.
- [ASYNC_HOSTING]: Website creation and every WordPress, plugin, theme, core, and Node.js mutation is fire-and-poll; a list re-poll proves completion.
- [PURCHASES]: A purchase consumes a catalog price `item_id` and rides the resource endpoint owning it — domains, VPS — never a generic billing order.
- [PAYMENT_METHODS]: A payment method is added in hPanel, never through the API.
- [DNS_OWNERSHIP]: Hostinger's DNS API acts only while the domain uses Hostinger nameservers; once delegated externally, records live there.
- [SECRETS]: Every API token enters commands as `$HOSTINGER_API_TOKEN`, never inline; output carrying credentials never lands in transcripts.
