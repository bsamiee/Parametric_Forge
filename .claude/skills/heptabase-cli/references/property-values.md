# Property Value Formats

Read property definitions and current values before writing:

```bash
heptabase tag properties <tagId>
heptabase card properties <cardIdOrDate>
heptabase tag cards <tagId> --include-properties
```

Use `card set-property` to replace one property value on one card:

```bash
heptabase card set-property <cardIdOrDate> --property-id <propertyId> (--value <value> | --json-value <json>)
```

Pass exactly one of `--value` or `--json-value`.

- Use `--value` when the CLI should send the argument as a literal string, such as text content or a select option name.
- Use `--json-value` when the value's JSON type matters, such as numbers, booleans, arrays, objects, relation values, and `null`.
- Use `--json-value null` to clear a property.

Read commands return property values as:

```json
{
  "id": "property-id",
  "name": "Status",
  "type": "select",
  "value": "Published"
}
```

Relation property reads return an array of populated relation objects, not a plain ID array:

```json
{
  "id": "property-id",
  "name": "Related",
  "type": "relation",
  "value": [{ "id": "related-card-id", "type": "note" }]
}
```

## Write Formats

<!-- prettier-ignore -->
| Property type | Format |
| --- | --- |
| `text` | Plain string via `--value "Draft notes"`. Stores a plain-text paragraph. |
| `number` | Number via `--json-value 42`, or a formatted numeric string via `--value "1,234"`. |
| `select` | Existing option name or raw option ID via `--value "Published"`. Option names are case-sensitive, matching the database UI. |
| `multiSelect` | JSON array of existing option names or raw option IDs via `--json-value '["Tag1","Tag2"]'`. Option names are case-sensitive, matching the database UI. Duplicate resolved options are rejected. |
| `date` | JSON object via `--json-value '{"start":"2026-05-05T00:00:00.000Z"}'`. The CLI normalizes `start` to an ISO UTC string with milliseconds and stores `end: null` because the UI does not display date ranges. |
| `checkbox` | Boolean via `--json-value true` or `--json-value false`. |
| `url` | Literal string via `--value "https://example.com"`. |
| `phone` | Literal string via `--value "+1 555 123 4567"`. |
| `email` | Literal string via `--value "person@example.com"`. |
| `relation` | JSON array of related card IDs or journal dates via `--json-value '["card-id","2026-05-05"]'`. Replaces the full relation value. Related cards must belong to the relation property's target tag database, source-type cards are rejected, and duplicate resolved cards are rejected. |

## Relation Properties

Relation writes are not self-contained. You must first discover the relation property's target tag database, then list cards in that database.

1. If you only have a card ID/date, run `heptabase card properties <cardIdOrDate>` to find the source tag containing the relation property.
2. Run `heptabase tag properties <sourceTagId>`.
3. Find the relation property. Its definition includes `relationTargetTagId`.
4. Run `heptabase tag cards <relationTargetTagId>` to list related-card candidates. Do not use source-type cards as relation values; relation writes reject them even when they belong to the target tag database.
5. Set the relation with the selected card IDs or journal dates:

```bash
heptabase card set-property <cardIdOrDate> --property-id <relationPropertyId> --json-value '["related-card-id"]'
```

Do not guess related card IDs from unrelated searches. If a card is not under `relationTargetTagId`, or it is a source-type card, the write is rejected.

## Examples

```bash
# Set select by option name
heptabase card set-property <cardIdOrDate> --property-id <propertyId> --value "Published"

# Set multi-select by option names
heptabase card set-property <cardIdOrDate> --property-id <propertyId> --json-value '["Research","Draft"]'

# Set a date
heptabase card set-property <cardIdOrDate> --property-id <propertyId> --json-value '{"start":"2026-05-05T00:00:00.000Z"}'

# Set a checkbox
heptabase card set-property <cardIdOrDate> --property-id <propertyId> --json-value true

# Replace relation values with a card and a journal
heptabase card set-property <cardIdOrDate> --property-id <propertyId> --json-value '["related-card-id","2026-05-05"]'

# Clear a property
heptabase card set-property <cardIdOrDate> --property-id <propertyId> --json-value null
```
