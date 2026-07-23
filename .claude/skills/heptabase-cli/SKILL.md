---
name: heptabase-cli
description: >-
    Reads and writes Heptabase through the local `heptabase` CLI: note, journal, and card
    content as Markdown or ProseMirror JSON under contentMd5 concurrency, typed tag property
    writes including relations, whiteboard card add/remove, parsed PDF pages, audio and video
    transcript ranges, local raw file export, and AI Tutor goals, courses, lessons. Use when a
    task saves, appends, or edits Heptabase content, sets a card property, or pulls a PDF or
    transcript — "add this to my Heptabase", "update that card's status", "get the transcript".
---

# [HEPTABASE_CLI]

Manage Heptabase knowledge base content through the local CLI; every read and write enters through the `heptabase` command and returns JSON on stdout for `jq` parsing or downstream piping.

## [01]-[ROUTING]

- [01]-[CARD_CONTENT_SCHEMA](references/card-content-schema.md): mandatory read before any ProseMirror save payload or extension-bearing Markdown.
- [02]-[PROPERTY_VALUES](references/property-values.md): mandatory read before any property write; value formats by type, relation write semantics
- [03]-[FILE_READING](references/file-reading.md): file listing and export from PDF and media cards
- [04]-[PDF_READING](references/pdf-reading.md): parsed PDF page metadata and page-range reads
- [05]-[TRANSCRIPT_READING](references/transcript-reading.md): audio and video transcript metadata and time-range reads

## [02]-[PREREQUISITES]

- Desktop app installs the CLI: `heptabase` on macOS/Linux, `heptabase.cmd` on Windows for cmd/PowerShell beside a `heptabase` POSIX shim.
- `heptabase --version` proves the CLI is reachable; a command this skill names but `heptabase help` does not list halts work rather than being guessed — ask the user to update the desktop app.

## [03]-[COMMAND_DISCOVERY]

Run `heptabase help` for the live top-level command list; each command carries `--help` for detailed usage:

```bash copy-safe
heptabase help
heptabase note --help
heptabase note create --help
```

## [04]-[TROUBLESHOOTING]

- [DESKTOP_APP_MUST_BE_RUNNING]: Every command reaches a local server in the app, so a closed app fails all; `heptabase start` launches to readiness.
- [MUTATIONS_ARE_SERIALIZED]: Every mutating command serializes server-side to prevent conflicts; reads run concurrent.
- [REQUEST_BOUNDS]: Oversized request bodies reject, bulk content lands as multiple `append` passes, never one giant body.

## [05]-[BOUNDARIES]

- [CLI_ONLY_ACCESS]: Never reach app data through local database files, app storage, cache files, internal endpoints, or any non-CLI mechanism.
- [UNSUPPORTED_OPERATION]: An operation the CLI omits stops and reports as unsupported.
- [LOCAL_SERVER_SETUP]: This skill never repairs local CLI wiring; ask the user to enable Local CLI Server and CLI install in desktop settings.
- [LOCAL_FILES_ONLY]: `heptabase file export` reaches only metadata and raw files local to the desktop app, never downloading from cloud storage.
- [BINARY_UPLOAD]: This skill is for JSON/text operations on notes/journals/tags/cards and AI Tutor reads, not file upload or media-processing APIs.
- [WHITEBOARD_MUTATION]: Listing whiteboards and adding, listing, or removing their cards works; creating, renaming, moving, or deleting one does not.
- [PROPERTY_FILTERING]: Reading tag property schemas and values and setting one value on a card works; querying cards by property value does not.
