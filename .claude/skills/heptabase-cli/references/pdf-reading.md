# [PDF_READING]

## [01]-[COMMON_USAGE_PATTERN]

1. Find PDF card IDs:

```bash template
heptabase card list --card-types pdf --limit 20
heptabase card list -q "<keyword>" --card-types pdf --limit 20
```

2. Read metadata before content:

```bash template
heptabase pdf metadata <pdfCardId>
```

3. Read small page ranges:

```bash template
heptabase pdf read <pdfCardId> --start-page 1 --end-page 5
```

## [02]-[PAGINATION_GUIDANCE]

- Always call `pdf metadata` first.
- Page numbers are 1-indexed and inclusive.
- Empty or image-only pages are returned with `markdown: ""` so the range is continuous.
- Read 5-10 pages by default to bound token cost.
- Ask the user before requesting more than 100 pages.

## [03]-[READ_VS_EXPORT]

- Use `pdf read` for textual analysis. It returns Heptabase's parsed Markdown, ready for the LLM.
- Use `file export` for visual or structural inspection. It returns the raw `.pdf` binary path for native PDF tools. This is rarely needed.

## [04]-[TROUBLESHOOTING]

- `parsedStatus: "processing"`: wait and retry later.
- `parsedStatus: "failed"` or `"notSupported"`: parsed Markdown is not available for this PDF.
- `parsedStatus: null`: this PDF card is not parsed yet. Ask the user to open the PDF in Heptabase and click the Parse button.
