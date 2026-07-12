---
name: heptabase-cli
description: Interact with Heptabase using the CLI to manage knowledge base content, search cards, edit properties, read parsed PDF and media transcript content, export local files, manage whiteboard cards, and browse AI Tutor goals, courses, and lessons.
allowed-tools: Bash(heptabase *) Bash(jq *) Bash(mktemp *)
metadata:
    heptabase-cli-version-range: '0.4.x'
---

# [HEPTABASE_CLI]

Manage Heptabase knowledge base content through the local CLI; every read and write enters through the `heptabase` command and returns JSON on stdout for `jq` parsing or downstream piping.

## [01]-[ROUTING]

- [01]-[CARD_CONTENT_SCHEMA](references/card-content-schema.md): ProseMirror JSON structure, card and whiteboard mentions, dates, videos, math extensions
- [02]-[PROPERTY_VALUES](references/property-values.md): property value formats by type, relation write semantics
- [03]-[FILE_READING](references/file-reading.md): file listing and export from PDF and media cards
- [04]-[PDF_READING](references/pdf-reading.md): parsed PDF page metadata and page-range reads
- [05]-[TRANSCRIPT_READING](references/transcript-reading.md): audio and video transcript metadata and time-range reads
- [06]-[CODEX_SANDBOX](references/codex-sandbox.md): local CLI server access under the Codex sandbox

## [02]-[PREREQUISITES]

- CLI installed from the desktop app. The command is `heptabase` on macOS/Linux; Windows installs `heptabase.cmd` for cmd/PowerShell and a `heptabase` shim for POSIX shells.
- Check version compatibility before use with `heptabase --version`. An installed CLI version outside this skill's compatibility range (`0.4.x`) halts work: stop and ask the user to update either the Heptabase desktop app or this skill package before continuing.

## [03]-[COMMAND_DISCOVERY]

Run `heptabase help` for the live top-level command list; each command carries `--help` for detailed usage:

```bash copy-safe
heptabase help
heptabase note --help
heptabase note create --help
```

## [04]-[COMMON_RECIPES]

Use these as quick recipes for frequent requests. For less common flags or if a command fails, run `heptabase help` or `<command> --help` to discover the correct syntax.

- [RECENT_CARDS]: `heptabase card list --sort createdTime --direction descending --limit 20`
- [TODAYS_JOURNAL]: `heptabase journal read $(date +%Y-%m-%d)`
- [SEARCH_CARDS_BY_KEYWORD]: `heptabase card list -q "<keyword>" --limit 20`
- [CREATE_A_NOTE_FROM_MARKDOWN]: `heptabase note create --content "# Title\n\nBody"`
- [APPEND_MARKDOWN_TO_A_NOTE]: `heptabase note append <cardId> --content "More content"`
- [EDIT_NOTE_CONTENT_WITH_JSON_SAVE]: first read `card-content-schema.md`, then use `heptabase note read <cardId>`, modify the returned ProseMirror JSON, and save with `heptabase note save <cardId> --content-md5 <contentMd5> --content-file <path>`.
- [LIST_TAG_PROPERTIES]: `heptabase tag properties <tagId>`
- [LIST_CARDS_WITH_PROPERTY_VALUES]: `heptabase tag cards <tagId> --include-properties`
- [READ_CARD_PROPERTIES]: `heptabase card properties <cardIdOrDate>`
- [SET_CARD_PROPERTY]: first read `property-values.md`, then use `heptabase card set-property <cardIdOrDate> --property-id <propertyId> --value "Published"` for strings/options or `--json-value ...` for typed JSON values.
- [READ_PARSED_PDF_CONTENT]: first read `pdf-reading.md`, then use `heptabase pdf metadata <pdfCardId>` to discover `totalPages`, and read a page range with `heptabase pdf read <pdfCardId> --start-page N --end-page N`.
- [READ_TRANSCRIPT_CONTENT]: first read `transcript-reading.md`, then use `heptabase audio metadata <audioCardId>` or `heptabase video metadata <videoCardId>` to discover `transcriptStatus` and `durationSeconds`, and read overlapping transcript entries in a time range with `heptabase audio read <audioCardId> --start-seconds 0 --end-seconds 300` or `heptabase video read <videoCardId> --start-seconds 0 --end-seconds 300`.
- [READ_A_FILE_FROM_A_PDF_MEDIA_CARD]: first read `file-reading.md`, then use `heptabase file list --card-id <cardId>` to find the right file `id`, run `mktemp -d`, and pass the returned directory path to `heptabase file export <fileId> --output-dir <scratchDir>`. Read the returned `path` with your native file-reading tool.
- [READ_A_FILE_BY_FILEID]: first read `file-reading.md`, then run `mktemp -d` and pass the returned directory path to `heptabase file export <fileId> --output-dir <scratchDir>`. Read the returned `path` with your native file-reading tool.
- [LIST_CARDS_ON_A_WHITEBOARD]: `heptabase whiteboard cards <whiteboardId>`
- [ADD_A_CARD_TO_A_WHITEBOARD]: `heptabase whiteboard add-card --whiteboard-id <whiteboardId> --card-id <cardIdOrDate>`

## [05]-[CONTENT_EDITING]

Use `create` / `append` with Markdown for ordinary writing. Reading `card-content-schema.md` is mandatory before calling `heptabase note save` / `heptabase journal save` with ProseMirror JSON, and before generating Markdown that uses Heptabase-specific extensions such as card mentions, whiteboard mentions, dates, videos, math, or `toggle`/`todo` lists.

## [06]-[PROPERTY_EDITING]

Setting a property value requires reading `property-values.md` first and inspecting the target property with `heptabase card properties <cardIdOrDate>` and/or `heptabase tag properties <tagId>`. Property formats vary by type, and relation writes replace the full relation value. For relation properties, use `heptabase tag properties <sourceTagId>` to get the property definition's `relationTargetTagId`, then list valid related cards before writing.

## [07]-[TROUBLESHOOTING]

- [DESKTOP_APP_MUST_BE_RUNNING]: The CLI communicates with a local server inside the app. If the app is closed, all commands fail. Run `heptabase start` to launch and wait for readiness.
- [CODEX_SANDBOX_MAY_BLOCK_LOCAL_CLI_SERVER]: If Heptabase starts but Codex says the CLI server is not ready, read `codex-sandbox.md`; retry `heptabase` commands outside the sandbox when Codex permits escalation.
- [MUTATIONS_ARE_SERIALIZED]: Write operations (create, save, append, trash, restore, tag add/remove, card set-property, file export, whiteboard add-card/remove-card) run one at a time to prevent conflicts. Reads are concurrent.
- [REQUEST_BODY_SIZE_LIMIT]: The server rejects request bodies larger than 1 MB.
- [REQUEST_TIMEOUT]: The server times out requests that take longer than 10 seconds to send their body.

## [08]-[BOUNDARIES]

- [CLI_ONLY_ACCESS]: Never directly read, write, or modify Heptabase app data through local database files, app storage, cache files, internal endpoints, or any other non-CLI mechanism. If the CLI does not carry the requested operation, stop and report that it is not supported.
- [LOCAL_SERVER_SETUP]: If the local CLI server is disabled or CLI wiring is missing, the skill cannot repair it by itself; ask the user to enable Local CLI Server and CLI install from desktop settings first.
- [LOCAL_FILES_ONLY]: `heptabase file export` works only when the file metadata and raw file are already available locally in the desktop app. It does not download missing files from cloud storage.
- [BINARY_UPLOAD]: This skill is for JSON/text operations on notes/journals/tags/cards and AI Tutor reads, not file upload or media-processing APIs.
- [WHITEBOARD_MUTATION]: Listing whiteboards and adding, listing, or removing cards on them works; creating, renaming, moving, or deleting whiteboards does not.
- [PROPERTY_FILTERING]: Reading tag property schemas, reading property values, and setting one property value on a card works; querying cards by property value does not.
