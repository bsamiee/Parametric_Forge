# [HOSTINGER_ECOMMERCE]

Store law: create a store, satisfy its payment and shipping prerequisites, then add products and sales channels. REST rows on `/api/ecommerce/v1` map one-to-one onto the `hostinger` MCP `ecommerce_*` tools; every price is an integer in minor units (cents), and store, product, and sales-channel ids are ULID-suffixed prefixes (`store_01J8Z...`, `scha_01J8...`).

## [01]-[STORE]

Creating a store auto-provisions its primary sales channel, so the `sales_channel` field is optional and set only for a headless external storefront. Store deletion is a soft delete — the record marks deleted and the underlying data survives — so it returns `200`, not `204`.

```bash template
curl -X POST "https://developers.hostinger.com/api/ecommerce/v1/stores" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN" -H "Content-Type: application/json" \
  -d '{ "name": "My Store", "country_code": "us", "company_email": "owner@example.com",
        "company_name": "My Company", "language": "en" }'
```

`getStoreMetadataV1` (`GET /stores/{id}/metadata`) is the readiness gate: it reports whether payment methods and shipping are configured and the store `default_currency`, and a storefront build reads it before going live.

## [02]-[PREREQUISITES]

A store takes orders only once a payment method and a shipping rate exist. The manual payment method is a checkout-time instruction (bank transfer, cash on delivery); shipping is a single flat rate that creates the shipping zone when absent, with `0` meaning free shipping.

```bash copy-safe
curl -X POST "https://developers.hostinger.com/api/ecommerce/v1/stores/{id}/payment-methods/manual" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN" -H "Content-Type: application/json" -d '{ "title": "Bank transfer" }'
curl -X POST "https://developers.hostinger.com/api/ecommerce/v1/stores/{id}/shipping" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN" -H "Content-Type: application/json" -d '{ "price": 599 }'
```

## [03]-[PRODUCTS]

A product is created published with a single variant — these endpoints carry no draft or multi-variant path. A physical product takes `name` and `price` (cents, positive) with optional `description` and `currency`; a digital product adds `download_url`, the external link delivered after purchase. Currency defaults to the store currency.

```bash copy-safe
curl -X POST "https://developers.hostinger.com/api/ecommerce/v1/stores/{id}/products/physical" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN" -H "Content-Type: application/json" \
  -d '{ "name": "T-Shirt", "price": 2499, "description": "Cotton tee" }'
```

## [04]-[SALES_CHANNELS]

The primary channel arrives with the store; a custom channel drives a headless storefront on external infrastructure. Update a channel's `name` and `url` (returned as its `domain`) with a `PATCH`, passing `null` to clear a field, and read the Markdown wiring guide from `getCustomStorefrontSetupInstructionsV1`.

```bash copy-safe
curl -X POST  "https://developers.hostinger.com/api/ecommerce/v1/stores/{id}/sales-channels" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN" -H "Content-Type: application/json" -d '{ "name": "Headless" }'
curl -X GET   "https://developers.hostinger.com/api/ecommerce/v1/miscellaneous/custom-storefront-instructions" -H "Authorization: Bearer $HOSTINGER_API_TOKEN"
```

## [05]-[API_REFERENCE]

| [INDEX] | [METHOD]         | [ENDPOINT]                                                        | [DESCRIPTION]                      |
| :-----: | :--------------- | :---------------------------------------------------------------- | :--------------------------------- |
|  [01]   | `GET/POST`       | `/api/ecommerce/v1/stores`                                        | List; create a store               |
|  [02]   | `GET/DELETE`     | `/api/ecommerce/v1/stores/{id}[/metadata]`                        | Metadata gate; soft-delete         |
|  [03]   | `POST`           | `/api/ecommerce/v1/stores/{id}/products/{physical,digital}`       | Create a product                   |
|  [04]   | `GET/POST/PATCH` | `/api/ecommerce/v1/stores/{id}/sales-channels[/{id}]`             | List, create, update a channel     |
|  [05]   | `POST`           | `/api/ecommerce/v1/stores/{id}/{payment-methods/manual,shipping}` | Payment and shipping prerequisites |
|  [06]   | `GET`            | `/api/ecommerce/v1/miscellaneous/custom-storefront-instructions`  | Headless wiring guide              |
