# [PROPERTY_VALUE_FORMATS]

Read property definitions and current values before writing:

```bash template
heptabase tag properties <tagId>
heptabase card properties <cardIdOrDate>
heptabase tag cards <tagId> --include-properties
```

Use `card set-property` to replace one property value on one card:

```bash template
heptabase card set-property <cardIdOrDate> --property-id <propertyId> (--value <value> | --json-value <json>)
```

Pass exactly one of `--value` or `--json-value`.

- Use `--value` when the CLI sends the argument as a literal string, such as text content or a select option name.
- Use `--json-value` when the value's JSON type matters, such as numbers, booleans, arrays, objects, relation values, and `null`.
- Use `--json-value null` to clear a property.

Read commands return property values as:

```json output-only
{
    "id": "property-id",
    "name": "Status",
    "type": "select",
    "value": "Published"
}
```

Relation property reads return an array of populated relation objects, not a plain ID array:

```json output-only
{
    "id": "property-id",
    "name": "Related",
    "type": "relation",
    "value": [{ "id": "related-card-id", "type": "note" }]
}
```

## [01]-[WRITE_FORMATS]

`select` and `multiSelect` option names are case-sensitive, matching the database UI; duplicate resolved options or relation cards are rejected.

- [01]-[TEXT]: `text` — plain string via `--value "Draft notes"`, stored as a plain-text paragraph.
- [02]-[NUMBER]: `number` — `--json-value 42`, or a formatted numeric string via `--value "1,234"`.
- [03]-[SELECT]: `select` — existing option name or raw option ID via `--value "Published"`.
- [04]-[MULTISELECT]: `multiSelect` — JSON array of existing option names or raw option IDs via `--json-value '["Tag1","Tag2"]'`.
- [05]-[DATE]: `date` — JSON object via `--json-value '{"start":"2026-05-05T00:00:00.000Z"}'`.
- [06]-[CHECKBOX]: `checkbox` — boolean via `--json-value true` or `--json-value false`.
- [07]-[URL]: `url` — literal string via `--value "https://example.com"`.
- [08]-[PHONE]: `phone` — literal string via `--value "+1 555 123 4567"`.
- [09]-[EMAIL]: `email` — literal string via `--value "person@example.com"`.
- [10]-[RELATION]: `relation` — JSON array of related card IDs or journal dates via `--json-value '["card-id","2026-05-05"]'`.

- `date`: normalizes `start` to an ISO UTC string with milliseconds and stores `end: null`, because the UI does not display date ranges.
- `relation`: Replaces the full relation value; related cards must belong to the relation property's target tag database, and source-type cards are rejected.

## [02]-[RELATION_PROPERTIES]

Relation writes are not self-contained: first discover the relation property's target tag database, then list cards in that database.

1. Given only a card ID/date, run `heptabase card properties <cardIdOrDate>` to find the source tag containing the relation property.
2. Run `heptabase tag properties <sourceTagId>`.
3. Find the relation property. Its definition includes `relationTargetTagId`.
4. Run `heptabase tag cards <relationTargetTagId>` to list related-card candidates. Do not use source-type cards as relation values; relation writes reject them even when they belong to the target tag database.
5. Set the relation with the selected card IDs or journal dates:

```bash template
heptabase card set-property <cardIdOrDate> --property-id <relationPropertyId> --json-value '["related-card-id"]'
```

Do not guess related card IDs from unrelated searches.

## [03]-[EXAMPLES]

```bash template
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
