# File Reading

Use `heptabase file list` to resolve a PDF/media card ID into exportable file IDs. Use `heptabase file export` to copy a local raw file into a scratch directory so native file-reading tools can inspect it.

## [01]-[COMMAND_SUMMARY]

```bash template
heptabase file list --card-id <pdf-or-media-card-id>
heptabase file export <fileId> --output-dir <existing-directory>
```

- `file list --card-id` returns exportable files for PDF/media cards. Unsupported card types return an empty `files` array.
- `file export` copies a local raw file into `--output-dir` and returns the file path to read.
- Read only the returned `path`; never inspect Heptabase internal file paths.

## [02]-[LIST_FILES]

Given a PDF or media card ID, list its files first:

```bash template
heptabase file list --card-id 22222222-2222-4222-8222-222222222222
```

Example response:

```json output-only
{
    "cardId": "22222222-2222-4222-8222-222222222222",
    "cardType": "pdf",
    "files": [
        {
            "id": "55555555-5555-4555-8555-555555555555",
            "purpose": "content",
            "name": "report.pdf",
            "mimeType": "application/pdf",
            "size": 123456,
            "lastEditedTime": "2026-05-02T00:00:00.000Z"
        }
    ]
}
```

Pick the file `id` for the required `purpose`, then pass that `id` to `file export` as `<fileId>`.

## [03]-[EXPORT_AND_READ]

1. Create a scratch directory:

```bash copy-safe
mktemp -d
```

Copy the returned directory path for the next command.

2. Export the file:

```bash template
heptabase file export 55555555-5555-4555-8555-555555555555 --output-dir <scratchDirFromMktemp>
```

3. Parse the JSON response and read the returned `path` with your native file-reading tool.

Example response:

```json output-only
{
    "fileId": "55555555-5555-4555-8555-555555555555",
    "path": "/tmp/hepta-read/report-55555555-5555-4555-8555-555555555555.pdf",
    "filename": "report-55555555-5555-4555-8555-555555555555.pdf",
    "originalName": "report.pdf",
    "mimeType": "application/pdf",
    "size": 123456,
    "lastEditedTime": "2026-05-02T00:00:00.000Z"
}
```

Now read `/tmp/hepta-read/report-55555555-5555-4555-8555-555555555555.pdf` with your native file-reading tool.

## [04]-[AVOID_READING_HUGE_FILES_BLINDLY]

- Check `size`, `mimeType`, and `name` before reading.
- For textual PDF reads, prefer `references/pdf-reading.md` and `heptabase pdf read` over exporting the raw PDF.
- If the file is large, ask the user before reading the whole file or use targeted extraction, search, or page reads to avoid wasting tokens.

## [05]-[CLEAN_UP_SCRATCH_FILES]

- Exported files are temporary scratch copies. After reading them, delete the scratch directory created by `mktemp -d`.
- Do not delete the scratch directory until all tools that need the returned `path` are done.

## [06]-[TROUBLESHOOTING]

- `file list --card-id` returns empty `files`: this card has no exportable local file. If the user expected a PDF/media file, ask them to verify the card.
- `file export` says the file is unavailable locally: ask the user to open/sync the file in Heptabase, then retry.
- Invalid or missing `--output-dir`: create a scratch directory with `mktemp -d` and retry.
