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

Manage Heptabase knowledge base content through the local CLI; every read and write enters through the `heptabase` command and returns JSON on stdout for `jq` parsing or downstream piping. Access rides the CLI alone — app databases, storage, cache files, and internal endpoints stay untouched. Oversized request bodies reject, so bulk content lands as successive `append` passes rather than one body.

`heptabase help` lists the live command set and every command carries `--help`.

## [01]-[MEDIA_READS]

Parsed text is the read path — `pdf read`, `audio read`, and `video read` return Heptabase's own parsed markdown and transcript entries; `file export` is the raw-binary escape hatch for visual or structural inspection alone. Metadata precedes every read: `parsedStatus` and `totalPages` for a PDF, `transcriptStatus` and `durationSeconds` for media. Any status other than parsed — `processing`, `failed`, `notSupported`, `null` — carries no content, and the only move is asking the user to parse or transcribe the card in the app.

```bash template
heptabase card list --card-types pdf -q "<keyword>" -l 20  # audio,video for media; ids feed every command below
heptabase pdf metadata <cardId>                            # totalPages + parsedStatus
heptabase pdf read <cardId> --start-page 1 --end-page 5    # 1-indexed inclusive, both flags required
heptabase audio metadata <cardId>                          # video metadata identical; durationSeconds + transcriptStatus
heptabase audio read <cardId> --start-seconds 0 --end-seconds 600
```

- Ranges bound the window: 5-10 pages and 10-minute transcript slices per call; past 100 pages or an hour of transcript asks the user first.
- Pages with no extractable text return `markdown: ""`, keeping the range continuous; a transcript range returns every entry overlapping it, so a 55-65s entry lands in a 60-120s request.

Raw bytes route through `file`, and only when parsed text cannot answer:

```bash template
heptabase file list --card-id <cardId>                      # exportable files; empty array = nothing local to export
heptabase file export <fileId> --output-dir "$(mktemp -d)"  # pick <fileId> by its purpose field
```

- Read only the returned `path`; app-internal paths stay untouched, and the scratch directory deletes once every tool holding the path is done.
- `size` and `mimeType` gate the read: a large file takes targeted extraction or the user's go-ahead, never a whole-file pull.
- Empty `files` or an unavailable export means the card has no synced local file — the user verifies or opens it in Heptabase, then the command retries.

## [02]-[PROPERTIES]

Property writes are typed and single-valued: `card set-property` replaces one property on one card and takes exactly one of `--value`, whose argument reaches the server as a literal string, or `--json-value`, which carries the JSON type numbers, booleans, arrays, objects, relations, and `null` need — `--json-value null` clears. Reading precedes every write, because the write needs a property id, its type, and its allowed options; a card id or a `YYYY-MM-DD` journal date addresses the card in either command.

```bash template
heptabase card properties <cardIdOrDate>          # current values grouped by tag
heptabase tag properties <tagId>                  # column definitions: id, name, type, options, relationTargetTagId
heptabase tag cards <tagId> --include-properties  # both, across a whole database
heptabase card set-property <cardIdOrDate> --property-id <propertyId> --value "<literal>"
heptabase card set-property <cardIdOrDate> --property-id <propertyId> --json-value '<json>'
```

| [INDEX] | [TYPE]                | [WRITE]                                                                |
| :-----: | :-------------------- | :--------------------------------------------------------------------- |
|  [01]   | `text`                | `--value "Draft notes"` — lands as a plain-text paragraph              |
|  [02]   | `number`              | `--json-value 42`, or a formatted numeric string via `--value "1,234"` |
|  [03]   | `select`              | `--value "Published"` — an existing option name or a raw option id     |
|  [04]   | `multiSelect`         | `--json-value '["Research","Draft"]'` — option names or raw option ids |
|  [05]   | `date`                | `--json-value '{"start":"2026-05-05T00:00:00.000Z"}'`                  |
|  [06]   | `checkbox`            | `--json-value true`                                                    |
|  [07]   | `url` `phone` `email` | a bare literal via `--value "https://example.com"`                     |
|  [08]   | `relation`            | `--json-value '["<cardId>","2026-05-05"]'` — card ids or journal dates |

- `select` and `multiSelect` option names are case-sensitive against the database UI; duplicate resolved options and duplicate relation cards reject.
- `date` normalizes `start` to an ISO UTC string with milliseconds and stores `end: null`, because the UI displays no ranges.
- Relation reads return populated objects — `[{"id": "<cardId>", "type": "note"}]` — never a plain id array, and a relation write replaces the entire value.
- Querying cards by property value has no CLI surface; `tag cards --include-properties` and a local filter are the whole path.

Relation writes resolve their target database first, and admissible ids are never guessed from an unrelated search: `card properties <cardIdOrDate>` names the source tag holding the relation property, `tag properties <sourceTagId>` yields that property's `relationTargetTagId`, and `tag cards <relationTargetTagId>` lists the candidates. Source-type cards reject even inside the target database.

## [03]-[CARD_CONTENT]

Markdown owns ordinary writing — `create` and `append` take it on `-c` or `-f`, and a `# heading` first line titles a new note. ProseMirror JSON enters only through `save`, which replaces the whole document, to preserve existing structure or to author what markdown cannot express. Editing reads first, edits the returned `content`, and saves with the `contentMd5` from that same read; a stale hash rejects the write. Schema validation is strict, so a guessed structure fails outright or damages the card.

```bash template
heptabase note create -f <body.md>                             # journal create takes -d <YYYY-MM-DD>, 409 once it has content
heptabase note append <cardId> -c "<markdown>"                 # journal append <YYYY-MM-DD>; --content-md5 optional here
heptabase note read <cardId>                                   # id, title, content, contentMd5 — journal read <YYYY-MM-DD>
heptabase note save <cardId> --content-md5 <md5> -f <doc.json> # journal save <YYYY-MM-DD>; whole-document replace
heptabase tag add --card-id <cardIdOrDate> --tag-name "<tag>"  # creates the tag when absent; tag remove drops it
```


Markdown covers the ordinary constructs one to one — headings, paragraphs, quotes, fences, rules, tables, images, and bullet, numbered, and checkbox list items — while `+ item` opens a `toggle_list_item`. Heptabase extends it three ways: `$x$` and `$$x$$` open `math_inline` and `math_display`; inline mentions are `{{card UUID}}`, `{{pdf_card UUID}}`, `{{whiteboard UUID}}`, and `{{date YYYY-MM-DD}}`; and a `video` block is a line holding only `{{video URL}}`, with `youtube`, `vimeo`, and `bilibili` swapping in for `video`.

```markdown template
# Sprint notes

Discussed in {{card 11111111-1111-4111-8111-111111111111}} on {{date 2026-06-04}}.

![](https://example.com/diagram.png)

{{youtube https://www.youtube.com/watch?v=example}}

- [ ] Summarize the recording
```

Trailing text leaves a video line a paragraph, image `alt` and `title` drop on import, every mention UUID resolves from a read or list, and underline and color reach no markdown syntax at all — those take the JSON path below.

Every document is `{"type": "doc", "content": [...]}` over at least one block; an empty array is invalid. Nodes are `{type, attrs?, content?}`, and `text` is the exception — characters ride a `text` property, formatting a `marks` array on the same object.

New blocks omit `id` or set it `null` for the save handler to backfill, ids from `read` round-trip verbatim, and a hand-minted id is never valid. Block media never sits inside a paragraph, so inline references are mention nodes. Containers nest whole: a list item opens with a `paragraph` before any further block, and `table` holds `table_row+` holding `table_cell`/`table_header` holding `block+`.

```json template
{
    "type": "doc",
    "content": [
        { "type": "heading", "attrs": { "id": null, "level": 1 }, "content": [{ "type": "text", "text": "Sprint notes" }] },
        {
            "type": "paragraph",
            "attrs": { "id": null },
            "content": [
                { "type": "text", "text": "Plain, " },
                { "type": "text", "marks": [{ "type": "strong" }], "text": "bold" },
                { "type": "text", "marks": [{ "type": "link", "attrs": { "href": "https://heptabase.com" } }], "text": ", a link" },
                { "type": "text", "text": ", a mention " },
                { "type": "card", "attrs": { "cardId": "11111111-1111-4111-8111-111111111111" } },
                { "type": "text", "text": ", and " },
                { "type": "math_inline", "content": [{ "type": "text", "text": "a^2 + b^2 = c^2" }] }
            ]
        },
        {
            "type": "todo_list_item",
            "attrs": { "id": null, "checked": false, "lastUpdatedTime": "2026-05-26T00:00:00.000Z" },
            "content": [{ "type": "paragraph", "attrs": { "id": null }, "content": [{ "type": "text", "text": "A block container opens with a paragraph" }] }]
        },
        {
            "type": "code_block",
            "attrs": { "id": null, "params": "!mermaid:preview" },
            "content": [{ "type": "text", "text": "flowchart TD\n  A[Draft] --> B[Review]" }]
        },
        { "type": "embed", "attrs": { "id": null, "objectType": "note", "objectId": "11111111-1111-4111-8111-111111111111", "width": "100%", "alignment": "center" } }
    ]
}
```

Every node but `doc` carries `id?`, so the rows below list what each takes beyond it. Optional attrs end in `?`; ids and `fileId` are a UUID string or null, string attrs (`src`, `url`, `width`, `title`, and peers) string or null, `originalWidth`/`originalHeight` number or null, and timestamps ISO 8601 (`2026-05-26T00:00:00.000Z`).

| [INDEX] | [NODE]                       | [CONTENT]                     | [ATTRS]                                                        |
| :-----: | :--------------------------- | :---------------------------- | :------------------------------------------------------------- |
|  [01]   | `doc`                        | `block+`                      | none                                                           |
|  [02]   | `paragraph`                  | `inline*`                     | none                                                           |
|  [03]   | `heading`                    | `inline*`                     | `level?` 1-6, default `1`                                      |
|  [04]   | `blockquote`                 | `block+`                      | none                                                           |
|  [05]   | `horizontal_rule`            | none                          | none                                                           |
|  [06]   | `code_block`                 | `text*`                       | `params?`, default `""`                                        |
|  [07]   | `math_display`               | `text*`                       | none                                                           |
|  [08]   | `bullet_list_item`           | `paragraph block*`            | `folded?`, `format?`                                           |
|  [09]   | `numbered_list_item`         | `paragraph block*`            | `order?`, `format?`                                            |
|  [10]   | `todo_list_item`             | `paragraph block*`            | `checked?`, `dueDate?`, `lastCheckedTime?`, `lastUpdatedTime?` |
|  [11]   | `toggle_list_item`           | `(heading\|paragraph) block*` | `folded?`                                                      |
|  [12]   | `table`                      | `table_row+`                  | `hasRowHeader?`, `hasColumnHeader?`                            |
|  [13]   | `table_row`                  | `(table_cell\|table_header)*` | none                                                           |
|  [14]   | `table_cell`, `table_header` | `block+`                      | `colspan?`, `rowspan?`, `colwidth?`                            |
|  [15]   | `image`                      | none                          | `src?`, `fileId?`, `width?`, `alignment?`, `reference?`        |
|  [16]   | `video`                      | none                          | `fileId?`, `url?`, `width?`, `alignment?`, `reference?`        |
|  [17]   | `audio`                      | none                          | `url?`, `fileId?`, `reference?`                                |
|  [18]   | `file`                       | none                          | `fileId?`, `url?`, `reference?`                                |
|  [19]   | `bookmark`                   | none                          | `url` required, `title?`, `description?`                       |
|  [20]   | `embed`                      | none                          | `objectType`, `objectId`, `width`, `alignment`                 |
|  [21]   | `mention`                    | none                          | `objectType`, `objectId`                                       |

- `format?` ∈ 0, 1, 2, "0", "1", "2", or null; `order?` a positive integer or null; `dueDate?` `YYYY-MM-DD` or null; `alignment?` ∈ left, center, right.
- `colspan?`/`rowspan?` are positive integers and `colwidth?` a positive-integer array or null; `image`, `video`, and `embed` also carry `originalWidth`/`originalHeight`, and `bookmark` also `thumbnailUrl?`, `faviconUrl?`, `siteName?`, `lastUpdatedTime?`.
- `code_block` `params` serialize as `[!]<language>[:displayMode]` — a leading `!` wraps lines, and `code`, `preview`, or `split` sets a Mermaid block's display mode.
- `embed` and `mention` take `objectType` ∈ note, journal, highlightElement, image, video, audio, and `objectId` a UUID, or `YYYY-MM-DD` when the type is journal.
- Editor colors — `table_cell`/`table_header` `backgroundColor?` and `textColor?`, and the `color` mark — are gray, brown, orange, yellow, green, blue, purple, pink, and red.
- Media `reference` attrs are internal metadata that round-trips from `read` and is never authored: `null`, or an object whose `objectType` ∈ card, textElement, journal, highlightElement, mediaElement, mediaCard, pdfCard, insight, chatMessage, chat2AccountRelation, webCard, and whose `objectId` is a UUID, or `YYYY-MM-DD` for a journal.
- Legacy attrs round-trip only, never set on new content: `image` `alt`/`title` (markdown import ignores them — `fileId`/`src` and `alignment` carry the intent), `video` `source` (use `fileId` or `url`), `link` `title`/`data-internal-href`/`edited` (`href` alone for new external links, since the app resolves internal ones).

Inline mention nodes take one id attr, their own name camelCased and suffixed `Id` — `whiteboardId`, `pdfCardId`, `webCardId`, `sectionId`, `tagId`, `highlightElementId` — except `card`, `image_card`, `video_card`, and `audio_card`, which all take `cardId`. `math_inline` and `math_display` hold their TeX as one child `text` node, never in `attrs`. `people` exists in a separate editor schema the CLI save schema rejects.

| [INDEX] | [INLINE_NODE] | [ATTRS]                                                                        |
| :-----: | :------------ | :----------------------------------------------------------------------------- |
|  [01]   | `text`        | none                                                                           |
|  [02]   | `math_inline` | none                                                                           |
|  [03]   | `hard_break`  | none                                                                           |
|  [04]   | `web`         | `url` a full URL string, `title?` string or null                               |
|  [05]   | `date`        | `date` as `YYYY-MM-DD`                                                         |
|  [06]   | `chat`        | `chatId`, with `chatMessageId?` and `quotedChatMessageId?` UUID string or null |

Marks attach to `text` nodes alone, each an entry in that node's `marks` array shaped `{"type": "<mark>", "attrs": ...}`.

| [INDEX] | [MARK]      | [STYLE]                 | [ATTRS]                                                           |
| :-----: | :---------- | :---------------------- | :---------------------------------------------------------------- |
|  [01]   | `em`        | italic                  | none                                                              |
|  [02]   | `strong`    | bold                    | none                                                              |
|  [03]   | `strike`    | strikethrough           | none                                                              |
|  [04]   | `underline` | underline               | none                                                              |
|  [05]   | `code`      | inline code             | none                                                              |
|  [06]   | `link`      | hyperlink               | `href` non-empty string, required                                 |
|  [07]   | `color`     | text or background fill | `type` ∈ text, background; `color` an editor color, both required |
|  [08]   | `highlight` | highlight and comment   | `ids` UUID string array                                           |
|  [09]   | `anchor`    | anchor                  | `ids` UUID string array                                           |

- `underline` and `color` have no markdown syntax and reach a card through `save` alone; `link` carries legacy attrs that round-trip from `read`.
- `highlight` and `anchor` are read-only app metadata — preserved on a round trip, never authored.
