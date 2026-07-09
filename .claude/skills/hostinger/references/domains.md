# [HOSTINGER_DOMAINS]

Domain portfolio law: availability through purchase, delegation, DNS zone records, forwarding, WHOIS, lock and privacy, verification, outbound transfer, and bulk audit. REST rows below map one-to-one onto the `hostinger` MCP `domains_*` and `DNS_*` tools; curl is the canonical scripted form, and the Python/TypeScript/PHP SDKs wrap the same endpoints with the same field names.

## [01]-[AVAILABILITY_AND_PURCHASE]

Availability precedes every purchase; the endpoint is rate-limited to 10 requests per minute, TLDs arrive without a leading dot, and alternative suggestions require exactly one TLD.

```bash
curl -X POST "https://developers.hostinger.com/api/domains/v1/availability" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN" -H "Content-Type: application/json" \
  -d '{ "domain": "myproject", "tlds": ["com", "net", "io"], "with_alternatives": true }'
```

Purchase requires an `item_id` from the billing catalog (`billing_getCatalogItemListV1`), a payment method (default used when omitted), and WHOIS contacts (TLD defaults used when omitted). A WHOIS profile for the target TLD exists before registration; some TLDs demand `additional_details`.

```bash
curl -X POST "https://developers.hostinger.com/api/domains/v1/portfolio" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN" -H "Content-Type: application/json" \
  -d '{
    "domain": "my-new-domain.com",
    "item_id": "hostingercom-domain-com-usd-1y",
    "payment_method_id": 1327362,
    "domain_contacts": { "owner_id": 741288, "admin_id": 741288, "billing_id": 741288, "tech_id": 741288 }
  }'
```

Post-purchase hardening: enable domain lock and privacy protection immediately (`PUT .../portfolio/{domain}/domain-lock`, `PUT .../portfolio/{domain}/privacy-protection`).

## [02]-[NAMESERVERS_AND_DNS]

```bash
# Delegate — at least two nameservers, verified responsive before switching
curl -X PUT "https://developers.hostinger.com/api/domains/v1/portfolio/example.com/nameservers" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN" -H "Content-Type: application/json" \
  -d '{ "ns1": "ns1.custom-dns.com", "ns2": "ns2.custom-dns.com" }'
```

After delegation to an external provider (Cloudflare, Route53), zone records live there; the Hostinger DNS surface acts only under Hostinger nameservers. Propagation runs up to 48 hours; `dig NS example.com` verifies the switch and the presence of records on the new servers.

Zone records under Hostinger nameservers ride the `DNS_*` MCP family — get, update, and delete records (`DNS_getDNSRecordsV1`, `DNS_updateDNSRecordsV1`, `DNS_deleteDNSRecordsV1`), validate a record set before applying (`DNS_validateDNSRecordsV1`), reset a zone (`DNS_resetDNSRecordsV1`), and restore from the automatic zone snapshots (`DNS_getDNSSnapshotListV1`, `DNS_getDNSSnapshotV1`, `DNS_restoreDNSSnapshotV1`). Validation precedes every zone mutation; a snapshot id anchors every restore.

## [03]-[FORWARDING]

`301` preserves SEO for permanent moves; `302` serves temporary campaigns. Forwarding comes off before the domain points at hosting.

```bash
curl -X POST "https://developers.hostinger.com/api/domains/v1/forwarding" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN" -H "Content-Type: application/json" \
  -d '{ "domain": "old-domain.com", "redirect_type": "301", "redirect_url": "https://new-domain.com" }'
# GET/DELETE /api/domains/v1/forwarding/{domain} read and remove it
```

## [04]-[WHOIS_PROFILES]

Profiles are per-TLD contact bundles reused across domains; `entity_type` is `individual` or `organization`, and requirements differ by TLD. Usage is checked before deletion — a profile in use by active domains refuses to delete.

```bash
curl -X GET "https://developers.hostinger.com/api/domains/v1/whois?tld=com" -H "Authorization: Bearer $HOSTINGER_API_TOKEN"

curl -X POST "https://developers.hostinger.com/api/domains/v1/whois" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN" -H "Content-Type: application/json" \
  -d '{
    "tld": "com", "entity_type": "individual", "country": "US",
    "whois_details": { "first_name": "John", "last_name": "Doe", "email": "john@example.com",
      "phone": "+1.5551234567", "address": "123 Main St", "city": "New York", "state": "NY", "zip": "10001" }
  }'

curl -X GET "https://developers.hostinger.com/api/domains/v1/whois/741288/usage" -H "Authorization: Bearer $HOSTINGER_API_TOKEN"
```

## [05]-[LOCK_PRIVACY_VERIFICATION]

Domain lock blocks unauthorized transfers and stays on for every production domain; privacy protection hides owner data from public WHOIS. Lock comes off only immediately before an intended transfer. Registrar-imposed lock periods can follow registration — `.com` typically holds 60 days.

```bash
# PUT enables, DELETE disables — same paths
curl -X PUT "https://developers.hostinger.com/api/domains/v1/portfolio/example.com/domain-lock" -H "Authorization: Bearer $HOSTINGER_API_TOKEN"
curl -X PUT "https://developers.hostinger.com/api/domains/v1/portfolio/example.com/privacy-protection" -H "Authorization: Bearer $HOSTINGER_API_TOKEN"
```

Domain access verification lives on a different base path and returns pending and completed verifications for a set of domains:

```bash
curl -X GET "https://developers.hostinger.com/api/v2/direct/verifications/active" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN" -H "Content-Type: application/json" \
  -d '{ "domains": ["example.com", "example.net"] }'
```

## [06]-[TRANSFER_OUT]

1. Disable domain lock (`DELETE .../portfolio/{domain}/domain-lock`).
2. Read domain details for the auth/EPP code context (`GET .../portfolio/{domain}`).
3. Initiate the transfer at the receiving registrar with the EPP code — outside the Hostinger API.
4. Approve the transfer when notified, via email or hPanel.

## [07]-[BULK_AUDIT]

Portfolio-wide security posture reads as one list call plus a per-domain detail loop: `GET /api/domains/v1/portfolio`, then check `domain_lock` and `privacy_protection` on each, enabling both wherever absent. The same loop shape serves any portfolio-wide mutation.

## [08]-[API_REFERENCE]

| [INDEX] | [METHOD]     | [ENDPOINT]                                              | [DESCRIPTION]                       |
| :-----: | :----------- | :------------------------------------------------------ | :---------------------------------- |
|  [01]   | `POST`       | `/api/domains/v1/availability`                          | Check availability (10/min)         |
|  [02]   | `GET/POST`   | `/api/domains/v1/portfolio`                             | List domains; purchase a domain     |
|  [03]   | `GET`        | `/api/domains/v1/portfolio/{domain}`                    | Domain details                      |
|  [04]   | `PUT`        | `/api/domains/v1/portfolio/{domain}/nameservers`        | Update nameservers                  |
|  [05]   | `PUT/DELETE` | `/api/domains/v1/portfolio/{domain}/domain-lock`        | Enable / disable lock               |
|  [06]   | `PUT/DELETE` | `/api/domains/v1/portfolio/{domain}/privacy-protection` | Enable / disable privacy            |
|  [07]   | `POST`       | `/api/domains/v1/forwarding`                            | Create forwarding                   |
|  [08]   | `GET/DELETE` | `/api/domains/v1/forwarding/{domain}`                   | Read / delete forwarding            |
|  [09]   | `GET/POST`   | `/api/domains/v1/whois`                                 | List / create WHOIS profiles        |
|  [10]   | `GET/DELETE` | `/api/domains/v1/whois/{whoisId}`                       | Read / delete a profile             |
|  [11]   | `GET`        | `/api/domains/v1/whois/{whoisId}/usage`                 | Profile usage                       |
|  [12]   | `GET`        | `/api/v2/direct/verifications/active`                   | Pending and completed verifications |

Full API docs, changelog, SDKs, and the `hapi` CLI live under https://developers.hostinger.com and https://github.com/hostinger.
