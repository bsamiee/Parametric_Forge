# [HOSTINGER_HOSTING]

Shared-hosting law: websites, WordPress installations, MySQL databases, Node.js apps, cache, cron, and PHP, all scoped to a hosting account. REST rows on `/api/hosting/v1` map one-to-one onto the `hostinger` MCP `hosting_*` tools; account-scoped paths carry `{username}` (the account, `u123456789`), and every WordPress operation additionally keys on `{software}` — the installation id from `listWordPressInstallationsV1`. Listings paginate on `page` and `per_page` (default 50).

Website creation and every WordPress, plugin, theme, core, and Node.js build mutation is asynchronous: a `2xx` means the job is queued, never done, and no response carries a completion field. Completion is confirmed by re-polling the matching list — `listWebsitesV1`, `listWordPressInstallationsV1`, `listInstalledWordPressPluginsV1`, `listNodeJSBuildsV1` — until the state settles.

## [01]-[WEBSITES]

A website binds to a hosting `order_id`; the first site on a plan also picks a `datacenter_code` (`listAvailableDatacentersV1` returns the plan-filtered set), and every later site inherits it. Website domains never start with `www.`, and `createWebsiteV1` returns empty `200` before provisioning — poll `listWebsitesV1` until the domain lands.

```bash template
curl -X POST "https://developers.hostinger.com/api/hosting/v1/websites" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN" -H "Content-Type: application/json" \
  -d '{ "domain": "example.com", "order_id": 12345, "datacenter_code": "us-east-1" }'
```

Subdomains (`POST .../accounts/{username}/websites/{domain}/subdomains` with `subdomain` and optional `directory`), parked domains, a free `hostingersite.com` subdomain (`generateAFreeSubdomainV1`, no body), and domain-ownership verification (`verifyDomainOwnershipV1`) ride the same website surface. `listWebsitesV1` also returns sites shared into the account by other clients.

## [02]-[WORDPRESS]

WordPress installs onto an existing website. `installWordPressV1` requires `domain`, `site_title`, and a `credentials` block; `overwrite` defaults false, so the async job fails when WordPress already occupies the path. An omitted `version` resolves to the latest core compatible with the vhost's PHP version.

```bash template
curl -X POST "https://developers.hostinger.com/api/hosting/v1/accounts/{username}/wordpress/installations" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN" -H "Content-Type: application/json" \
  -d '{ "domain": "example.com", "site_title": "My site", "language": "en_US", "directory": "public_html",
        "auto_updates": "minor", "credentials": { "email": "owner@example.com", "login": "admin", "password": "..." } }'
```

- [PLUGINS]: `installWordPressPluginsV1` takes `{ "plugins": [...] }` (1-20 slugs from `searchWordPressPluginsV1`); `activate`/`deactivate` take one `plugin`, `uninstall`/`update` take a `plugins` list. `updateHostingerWordPressPluginV1` targets the bundled Hostinger plugins by `slug`.
- [THEMES]: `installWordPressThemeV1` takes `theme`; the Hostinger slugs (`hostinger-blog`, `hostinger-affiliate-theme`, `hostinger-ai-theme`) alone honor `palette`, `layout`, and `font`, and any other slug ignores them.
- [CORE]: `updateWordPressCoreV1` takes optional `minor` and `version`; `showWordPressCoreVersionV1` and `listAvailableWordPressCoreUpdatesV1` read state.
- [ACCESS]: `createLoginLinksV1` mints an auto-login URL; `getInstallationJWTTokenV1` returns a one-hour JWT plus the install's WordPress `mcp_url` for direct in-site automation.
- [DELETE]: `deleteWordPressInstallationV1` with `delete_files`/`delete_database` (both default false) is irreversible and cascades to plugins, themes, and staging sites.

## [03]-[DATABASES]

A database name and user carry the account prefix — `createAccountDatabaseV1` auto-adds `u123456789_` when omitted, so the stored name differs from the sent one, and every later call keys on the full name from `listAccountDatabasesV1`. A password change does not rewrite any `wp-config.php` or app config that references the database; that update is manual.

```bash copy-safe
curl -X POST "https://developers.hostinger.com/api/hosting/v1/accounts/{username}/databases" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN" -H "Content-Type: application/json" \
  -d '{ "name": "u123456789_app", "user": "u123456789_admin", "password": "...", "website_domain": "example.com" }'
```

Remote access opens per database (`POST .../databases/{name}/remote-connections` with an `ip`, or `%` for any host) and revokes by the same `ip` query; `getPhpMyAdminLinkV1` and `repairDatabaseV1` round out the surface. Remote-connection listing is account-wide; create and delete are per-database.

## [04]-[NODE_JS]

A Node.js build takes a source archive — `createNodeJSBuildFromArchiveV1` with a `.zip`/`.tar.gz`/`.tgz` under 50 MB containing SOURCE ONLY (no `node_modules`, no build output; the build runs server-side). `node_version` (`18`/`20`/`22`/`24`), `app_type` (`vite`, `express`, `nest`, and peers), and `package_manager` auto-detect from `package.json` when omitted. Each build carries a `state` of `pending` → `running` → `completed`/`failed`, polled via `listNodeJSBuildsV1`; `restartNode_jsApplicationV1` cycles the running app.

## [05]-[CACHE_CRON_PHP]

- [CACHE]: `clearWebsiteCacheV1` and `toggleWebsiteCacheV1` are website-scoped (`{domain}`) and also purge the CDN when enabled; LiteSpeed and Memcached (`purgeLiteSpeedCacheV1`, `toggleMemcachedObjectCacheV1`, with `{ "enabled": ... }`) are WordPress-scoped (`{software}`) — different path keys.
- [CRON]: `createAccountCronJobV1` takes a five-field `time` and a `command`; `getCronJobOutputV1` returns the last run's captured output by the job `uid`.
- [PHP]: `getPHPDetailsV1`/`getPHPInfoV1` read; `updatePHPVersionV1`, `updatePHPOptionsV1`, and `updatePHPExtensionsV1` mutate, with `resetPHPExtensionsV1` reverting to defaults. PHP version gates WordPress core-version resolution.
- [MAINTENANCE]: `toggleMaintenanceModeV1` (`{ "enabled": ... }`) is WordPress-scoped.

## [06]-[HORIZONS]

Horizons AI builder generates a site from a prompt: `horizons_createWebsiteV1` takes `message` as an array of `{ "type": "text", "text": ... }` items, the text carrying the full project spec up to 20000 characters. `horizons_getWebsiteV1` returns an edit link into the Horizons UI — a Horizons site is editable only there, never through the API.

## [07]-[COMPOSITE_DEPLOY]

Seven tools — `deployStaticWebsite`, `deployJsApplication`, `deployWordpressPlugin`, `deployWordpressTheme`, `importWordpressWebsite`, `listJsDeployments`, `showJsDeploymentLogs` — are MCP-side compositions over an upload pipeline absent from the published spec (`POST /api/hosting/v1/files/upload-urls` → upload → a per-type deploy or build endpoint). They cannot be reproduced from the OpenAPI paths alone. `deployStaticWebsite` uploads PRE-BUILT static files with no build step; `deployJsApplication` uploads SOURCE ONLY and builds server-side (the MCP routes by the presence of `package.json`); `importWordpressWebsite` takes a site archive plus a `.sql` dump, naming a directory input `<dir>_YYYYMMDD_HHMMSS.zip`.

## [08]-[API_REFERENCE]

| [INDEX] | [METHOD]                | [ENDPOINT]                                                              | [DESCRIPTION]                       |
| :-----: | :---------------------- | :---------------------------------------------------------------------- | :---------------------------------- |
|  [01]   | `GET/POST`              | `/api/hosting/v1/websites`                                              | List; create a website (async)      |
|  [02]   | `GET/POST/DELETE`       | `.../accounts/{username}/websites/{domain}/{subdomains,parked-domains}` | Subdomains, parked domains          |
|  [03]   | `GET/POST/DELETE`       | `.../accounts/{username}/wordpress[/installations,/{software}]`         | WordPress installs (async)          |
|  [04]   | `POST`                  | `.../wordpress/{software}/{plugins,themes,update}/*`                    | Plugins, themes, core (async)       |
|  [05]   | `GET/POST/PATCH/DELETE` | `.../accounts/{username}/databases[/{name}/*]`                          | Databases, passwords, remote access |
|  [06]   | `GET/POST`              | `.../accounts/{username}/websites/{domain}/nodejs/builds`               | Node.js builds (async state)        |
|  [07]   | `PATCH/POST/DELETE`     | `.../accounts/{username}/{websites/{domain}/cache,cron-jobs,.../php}`   | Cache, cron, PHP                    |
|  [08]   | `GET/POST`              | `/api/horizons/v1/websites[/{id}]`                                      | AI website builder                  |
