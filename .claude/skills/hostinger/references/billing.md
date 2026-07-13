# [HOSTINGER_BILLING]

Billing is the cross-cutting foundation: every domain and VPS purchase consumes a catalog price `item_id` and an optional `payment_method_id`, so a purchase resolves the catalog first. REST rows on `/api/billing/v1` map one-to-one onto the `hostinger` MCP `billing_*` tools; all amounts are integer minor units (cents), so `1799` is `$17.99`.

## [01]-[CATALOG]

The catalog is two levels: a catalog item carries a `category`, a string `id`, and a `prices[]` array, and each price carries its own string `id`. A purchase consumes the PRICE `id`, never the catalog-item `id`.

- Catalog-item id: `hostingercom-<category>-<sku>` — `hostingercom-vps-kvm2`, `hostingercom-domain-com`.
- Price id: `<catalog-item-id>-<currency>-<periodN><unit>` — `hostingercom-vps-kvm2-usd-1m`, `hostingercom-domain-com-usd-1y`.

```bash template
# Filter by category or name; read a prices[].id for the intended term
curl -X GET "https://developers.hostinger.com/api/billing/v1/catalog?category=vps" -H "Authorization: Bearer $HOSTINGER_API_TOKEN"
```

Each price carries `currency`, `price`, `first_period_price` (the promotional first-term price), `period`, and `period_unit` (`month`, `year`, `day`, `week`, `none`); the catalog-item `metadata` shape varies by category. The order lands through the resource endpoint that owns the product — `POST /api/domains/v1/portfolio` for a domain, `POST /api/vps/v1/virtual-machines` for a VM — each taking the price `item_id` and an optional `payment_method_id`; the generic billing orders endpoint was retired, so no order rides `/api/billing/v1` directly.

## [02]-[PAYMENT_METHODS]

A payment method is created only in hPanel (`hpanel.hostinger.com/billing/payment-methods`); the API lists, sets the default, and deletes, never creates. An omitted `payment_method_id` on a purchase falls to the account default.

```bash copy-safe
curl -X GET  "https://developers.hostinger.com/api/billing/v1/payment-methods" -H "Authorization: Bearer $HOSTINGER_API_TOKEN"
curl -X POST "https://developers.hostinger.com/api/billing/v1/payment-methods/517244" -H "Authorization: Bearer $HOSTINGER_API_TOKEN"   # set default
```

A `credit_card` method can demand extra verification that leaves an order unprocessed; a non-card default clears that path. `paymentMethodId` is an integer.

## [03]-[SUBSCRIPTIONS]

A subscription carries `status`, `total_price`, `renewal_price`, `is_auto_renewed`, `expires_at`, and `next_billing_at`. An API-created order auto-renews by default; the toggle is asymmetric — enable is `PATCH`, disable is `DELETE` — and there is no stable API cancel, so a cancellation runs through hPanel.

```bash copy-safe
curl -X GET    "https://developers.hostinger.com/api/billing/v1/subscriptions" -H "Authorization: Bearer $HOSTINGER_API_TOKEN"
curl -X PATCH  "https://developers.hostinger.com/api/billing/v1/subscriptions/{id}/auto-renewal/enable"  -H "Authorization: Bearer $HOSTINGER_API_TOKEN"
curl -X DELETE "https://developers.hostinger.com/api/billing/v1/subscriptions/{id}/auto-renewal/disable" -H "Authorization: Bearer $HOSTINGER_API_TOKEN"
```

## [04]-[API_REFERENCE]

| [INDEX] | [METHOD]       | [ENDPOINT]                                          | [DESCRIPTION]                                        |
| :-----: | :------------- | :-------------------------------------------------- | :--------------------------------------------------- |
|  [01]   | `GET`          | `/api/billing/v1/catalog`                           | Catalog items and prices; `category`, `name` filters |
|  [02]   | `GET`          | `/api/billing/v1/payment-methods`                   | List payment methods                                 |
|  [03]   | `POST/DELETE`  | `/api/billing/v1/payment-methods/{id}`              | Set default; delete                                  |
|  [04]   | `GET`          | `/api/billing/v1/subscriptions`                     | List subscriptions                                   |
|  [05]   | `PATCH/DELETE` | `/api/billing/v1/subscriptions/{id}/auto-renewal/*` | Toggle auto-renewal (enable, disable)                |
