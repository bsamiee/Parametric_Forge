# [CARD_CONTENT_SCHEMA]

Read before generating ProseMirror JSON: the card content schema is strict, and guessed structures fail validation or damage card content.

Prefer Markdown for ordinary writing and appending. Use ProseMirror JSON only to preserve existing structure or to create schema nodes/marks that Markdown cannot express.

## [01]-[TOP_LEVEL_JSON_SHAPE]

A ProseMirror document is a JSON object:

```json template
{
    "type": "doc",
    "content": [
        {
            "type": "paragraph",
            "attrs": { "id": null },
            "content": [{ "type": "text", "text": "Hello" }]
        }
    ]
}
```

The `text` node is special: put the characters in a `text` property (not in `attrs`), and put optional formatting in a `marks` array on the same object. See [Marks](#marks) and [Paragraph With Marks And Link](#paragraph-with-marks-and-link).

The document must contain at least one block. `{"type":"doc","content":[]}` is invalid.

When editing existing content, preserve existing `id` values from `read`. For new blocks, omit `id` or set it to `null`; the CLI save handler backfills valid IDs. Do not create custom string IDs yourself.

Editing a card or journal reads first, edits the returned `content`, and saves with the latest `contentMd5` from that read; a stale `contentMd5` rejects the write.

## [02]-[MARKDOWN_CONTENT]

Markdown syntax maps to the ProseMirror nodes and marks the CLI creates:

<!-- prettier-ignore -->

| [INDEX] | [MARKDOWN]                                                              | [PROSEMIRROR]                                         |
| :-----: | :---------------------------------------------------------------------- | :---------------------------------------------------- |
|  [01]   | `# H1` through `###### H6`                                              | `heading`                                             |
|  [02]   | Plain text paragraphs                                                   | `paragraph`                                           |
|  [03]   | `>` quote                                                               | `blockquote`                                          |
|  [04]   | `- item`                                                                | `bullet_list_item`                                    |
|  [05]   | `1. item`                                                               | `numbered_list_item`                                  |
|  [06]   | `- [ ] item`, `- [x] item`                                              | `todo_list_item`                                      |
|  [07]   | `+ item`                                                                | `toggle_list_item`                                    |
|  [08]   | Triple backtick fences                                                  | `code_block`                                          |
|  [09]   | `---`                                                                   | `horizontal_rule`                                     |
|  [10]   | Markdown tables                                                         | `table`                                               |
|  [11]   | `![](src)`, `![](src "title")`                                          | `image` block (`alt` is ignored so no need to set it) |
|  [12]   | `{{video URL}}`, `{{youtube URL}}`, `{{vimeo URL}}`, `{{bilibili URL}}` | `video` block                                         |
|  [13]   | `{{card UUID}}`                                                         | inline `card` mention                                 |
|  [14]   | `{{pdf_card UUID}}`                                                     | inline `pdf_card` mention                             |
|  [15]   | `{{whiteboard UUID}}`                                                   | inline `whiteboard` mention                           |
|  [16]   | `{{date YYYY-MM-DD}}`                                                   | inline `date` mention                                 |
|  [17]   | `$x$`, `$$x$$`                                                          | `math_inline`, `math_display`                         |
|  [18]   | `**bold**`, `*italic*`, `~~strike~~`, `` `code` ``, `[link](url)`       | marks                                                 |

Below is an example with inline mentions, an image block, a standalone video line (note the blank lines), and a `todo` item:

```markdown template
# Sprint notes

Discussed in {{card 11111111-1111-4111-8111-111111111111}} on {{date 2026-06-04}}.

This is an image:

![](https://example.com/diagram.png)

This is a video:

{{youtube https://www.youtube.com/watch?v=example}}

- [ ] Summarize the recording
```

Video markdown rules:

- The whole line must be only `{{video URL}}`, `{{youtube URL}}`, `{{vimeo URL}}`, or `{{bilibili URL}}` — no text before or after on the same line.
- Put a blank line before and after the video line when other blocks are nearby.
- Invalid: `Watch this: {{youtube https://...}}` (trailing text prevents a `video` block).

Every card, PDF, and whiteboard mention UUID resolves from a CLI read or list first; a guessed UUID targets nothing.

## [03]-[PROSEMIRROR_NODES]

### [03.1]-[BLOCKS]

Optional attrs carry a trailing `?`. Every `id` and `fileId` is a UUID string or null; string attrs (`src`, `url`, `width`, `title`, and peers) are string or null; `originalWidth`/`originalHeight` are number or null; timestamp attrs are ISO 8601 strings (see [Timestamp Attrs](#timestamp-attrs)). Media `reference` attrs are preserved from `read`, never created manually (see [Media References](#media-references)). For `table_cell`/`table_header`, `colspan?`/`rowspan?` are positive integers, `colwidth?` is a positive integer[] or null, and `backgroundColor?`/`textColor?` are an editor color or null (see [Editor Colors](#editor-colors)). For `embed` and `mention`, `objectType` is `note`, `journal`, `highlightElement`, `image`, `video`, or `audio`, and `objectId` is a UUID string, or `YYYY-MM-DD` when `objectType` is `journal`. Deprecated `image`/`video` attrs live in [Deprecated attributes](#deprecated-attributes).

<!-- prettier-ignore -->

| [INDEX] | [NODE]                       | [CONTENT]                     | [ATTRS]                                                               |
| :-----: | :--------------------------- | :---------------------------- | :-------------------------------------------------------------------- |
|  [01]   | `doc`                        | `block+`                      | none                                                                  |
|  [02]   | `paragraph`                  | `inline*`                     | `id?`                                                                 |
|  [03]   | `heading`                    | `inline*`                     | `id?`, `level?` 1-6 (default `1`)                                     |
|  [04]   | `blockquote`                 | `block+`                      | `id?`                                                                 |
|  [05]   | `horizontal_rule`            | none                          | `id?`                                                                 |
|  [06]   | `code_block`                 | `text*`                       | `id?`, `params?`                                                      |
|  [07]   | `math_display`               | `text*`                       | `id?`                                                                 |
|  [08]   | `bullet_list_item`           | `paragraph block*`            | `id?`, `folded?`, `format?`                                           |
|  [09]   | `numbered_list_item`         | `paragraph block*`            | `id?`, `order?`, `format?`                                            |
|  [10]   | `todo_list_item`             | `paragraph block*`            | `id?`, `checked?`, `dueDate?`, `lastCheckedTime?`, `lastUpdatedTime?` |
|  [11]   | `toggle_list_item`           | `(heading\|paragraph) block*` | `id?`, `folded?`                                                      |
|  [12]   | `table`                      | `table_row+`                  | `id?`, `hasRowHeader?`, `hasColumnHeader?`                            |
|  [13]   | `table_row`                  | `(table_cell\|table_header)*` | `id?`                                                                 |
|  [14]   | `table_cell`, `table_header` | `block+`                      | `id?`, `colspan?`, `rowspan?`, `colwidth?`                            |
|  [15]   | `image`                      | none                          | `id?`, `src?`, `fileId?`, `width?`, `alignment?`, `reference?`        |
|  [16]   | `video`                      | none                          | `id?`, `fileId?`, `url?`, `width?`, `alignment?`, `reference?`        |
|  [17]   | `audio`                      | none                          | `id?`, `url?`, `fileId?`, `reference?`                                |
|  [18]   | `file`                       | none                          | `id?`, `fileId?`, `url?`, `reference?`                                |
|  [19]   | `bookmark`                   | none                          | `url` (required), `id?`, `title?`, `description?`, and peers          |
|  [20]   | `embed`                      | none                          | `objectType`, `objectId`, `id?`, `width`, `alignment`                 |
|  [21]   | `mention`                    | none                          | `objectType`, `objectId`, `id?`                                       |

- `format?` ∈ 0, 1, 2, "0", "1", "2", or null; `order?` positive integer or null; `dueDate?` YYYY-MM-DD or null.
- `alignment?` ∈ left/center/right; image and video also `originalWidth?`, `originalHeight?`.
- `bookmark` also `thumbnailUrl?`, `faviconUrl?`, `siteName?`, `lastUpdatedTime?`; `url` is a full URL string.
- `embed` also `originalWidth`, `originalHeight`; `code_block` `params?` see [Code Block Params](#code-block-params), default `""`.
- `table_cell`/`table_header` also `backgroundColor?`, `textColor?`.

Block media nodes cannot appear inside a paragraph. Use inline mention nodes for inline references.

#### [CODE_BLOCK_PARAMS]

Code block `params` are serialized as `[!]<language>[:displayMode]`, where a leading `!` wraps lines and `displayMode` applies to Mermaid blocks (`code`, `preview`, or `split`). See [Code Block](#code-block).

#### [TIMESTAMP_ATTRS]

Use ISO 8601 strings for timestamp attrs, for example `2026-05-26T00:00:00.000Z`.

#### [MEDIA_REFERENCES]

Media `reference` attrs are internal metadata. Preserve them when editing existing JSON from `read`, but do not create them manually. If present, the value must be either `null` or an object with `objectType` and `objectId`. Supported `objectType` values are `card`, `textElement`, `journal`, `highlightElement`, `mediaElement`, `mediaCard`, `pdfCard`, `insight`, `chatMessage`, `chat2AccountRelation`, and `webCard`. `objectId` must be a UUID string, except `journal` references use a `YYYY-MM-DD` date string.

#### [EDITOR_COLORS]

Editor colors for `table_cell` / `table_header` `backgroundColor` and `textColor` are `gray`, `brown`, `orange`, `yellow`, `green`, `blue`, `purple`, `pink`, and `red`.

### [03.2]-[INLINE_NODES]

<!-- prettier-ignore -->

| [INDEX] | [NODE]                                   | [ATTRS]                                                         |
| :-----: | :--------------------------------------- | :-------------------------------------------------------------- |
|  [01]   | `text`                                   | none                                                            |
|  [02]   | `math_inline`                            | none                                                            |
|  [03]   | `hard_break`                             | none                                                            |
|  [04]   | `web`                                    | `url: full URL string`, `title?: string or null`                |
|  [05]   | `date`                                   | `date: string` (`YYYY-MM-DD`)                                   |
|  [06]   | `whiteboard`                             | `whiteboardId: UUID string`                                     |
|  [07]   | `card`                                   | `cardId: UUID string`                                           |
|  [08]   | `pdf_card`                               | `pdfCardId: UUID string`                                        |
|  [09]   | `section`                                | `sectionId: UUID string`                                        |
|  [10]   | `tag`                                    | `tagId: UUID string`                                            |
|  [11]   | `highlight_element`                      | `highlightElementId: UUID string`                               |
|  [12]   | `image_card`, `video_card`, `audio_card` | `cardId: UUID string`                                           |
|  [13]   | `web_card`                               | `webCardId: UUID string`                                        |
|  [14]   | `chat`                                   | `chatId: UUID string`, `chatMessageId?`, `quotedChatMessageId?` |

- `chat`: `chatMessageId?` and `quotedChatMessageId?` are UUID string or null.

- **`text`** — Put characters in `text` (required) and optional formatting in `marks`. See [Top-Level JSON Shape](#top-level-json-shape) and [Marks](#marks).
- **`math_inline`** — Put the TeX inside `content` as a child `text` node. See [Math](#math).
- **`people`** — Do not use `people`. It exists in a special editor schema, but the CLI save schema rejects it.

### [03.3]-[MARKS]

Marks only attach to `text` nodes. Each mark is an entry in that node's `marks` array: `{ "type": "<mark>", "attrs": ... }` (many marks have no `attrs`).

Saving as Markdown yields bold, italic, and the other marks from the syntax in [Markdown Content](#markdown-content). Underline and text/background color have no Markdown syntax — save as JSON (ProseMirror) for those marks.

<!-- prettier-ignore -->

| [INDEX] | [MARK]      | [ATTRS]                                         | [NOTES]                                                      |
| :-----: | :---------- | :---------------------------------------------- | :----------------------------------------------------------- |
|  [01]   | `em`        | none                                            | italic                                                       |
|  [02]   | `strong`    | none                                            | bold                                                         |
|  [03]   | `strike`    | none                                            | strikethrough                                                |
|  [04]   | `underline` | none                                            | underline                                                    |
|  [05]   | `code`      | none                                            | inline code                                                  |
|  [06]   | `link`      | `href: non-empty string`                        | `href` required; deprecated attrs preserved from `read`      |
|  [07]   | `color`     | `type: text\|background`, `color: editor color` | both attrs required when the mark is present                 |
|  [08]   | `highlight` | `ids: UUID string[]`                            | read-only highlight/comment metadata; do not create manually |
|  [09]   | `anchor`    | `ids: UUID string[]`                            | read-only anchor metadata; do not create manually            |

- `link` deprecated (legacy markdown) attrs: `title`, `data-internal-href`, `edited` — preserve from `read` if present, never set on new links.
- `color` `color` ∈ gray, brown, orange, yellow, green, blue, purple, pink, or red.

### [03.4]-[DEPRECATED_ATTRIBUTES]

Some attrs remain in the schema as legacy. When creating new JSON, omit them unless round-tripping an existing document from `read`:

<!-- prettier-ignore -->

| [INDEX] | [NODE_MARK] | [DEPRECATED]                            | [NOTES]                                                                        |
| :-----: | :---------- | :-------------------------------------- | :----------------------------------------------------------------------------- |
|  [01]   | `image`     | `alt`, `title`                          | Markdown import ignores them; use `fileId` / `src` and `alignment` instead     |
|  [02]   | `video`     | `source`                                | Legacy iframe `data-source`; use `fileId` or `url`                             |
|  [03]   | `link`      | `title`, `data-internal-href`, `edited` | Use `href` only for new external links; internal links are resolved by the app |

## [04]-[EXAMPLES]

### [04.1]-[MINIMAL_NOTE]

```json template
{
    "type": "doc",
    "content": [{ "type": "heading", "attrs": { "level": 1, "id": null } }]
}
```

### [04.2]-[PARAGRAPH_WITH_MARKS_AND_LINK]

```json template
{
    "type": "doc",
    "content": [
        {
            "type": "paragraph",
            "attrs": { "id": null },
            "content": [
                { "type": "text", "text": "This is " },
                { "type": "text", "marks": [{ "type": "strong" }], "text": "bold" },
                { "type": "text", "text": " and " },
                { "type": "text", "marks": [{ "type": "em" }], "text": "italic" },
                { "type": "text", "text": ", with " },
                {
                    "type": "text",
                    "marks": [
                        {
                            "type": "link",
                            "attrs": { "href": "https://heptabase.com" }
                        }
                    ],
                    "text": "a link"
                },
                { "type": "text", "text": "." }
            ]
        }
    ]
}
```

### [04.3]-[TODO_ITEM]

```json template
{
    "type": "doc",
    "content": [
        {
            "type": "todo_list_item",
            "attrs": {
                "id": null,
                "checked": false,
                "lastUpdatedTime": "2026-05-26T00:00:00.000Z"
            },
            "content": [
                {
                    "type": "paragraph",
                    "attrs": { "id": null },
                    "content": [{ "type": "text", "text": "Review schema rules" }]
                }
            ]
        }
    ]
}
```

### [04.4]-[CODE_BLOCK]

```json template
{
    "type": "doc",
    "content": [
        {
            "type": "code_block",
            "attrs": { "id": null, "params": "typescript" },
            "content": [{ "type": "text", "text": "const answer = 42;" }]
        },
        {
            "type": "code_block",
            "attrs": { "id": null, "params": "!mermaid:preview" },
            "content": [{ "type": "text", "text": "flowchart TD\n  A[Draft] --> B[Review]" }]
        }
    ]
}
```

Use `!` to enable line wrapping, for example `!typescript`. For Mermaid code blocks, append `:code`, `:preview`, or `:split` to choose the display mode.

### [04.5]-[INLINE_CARD_MENTION]

```json template
{
    "type": "doc",
    "content": [
        {
            "type": "paragraph",
            "attrs": { "id": null },
            "content": [
                { "type": "text", "text": "See also: " },
                {
                    "type": "card",
                    "attrs": { "cardId": "11111111-1111-4111-8111-111111111111" }
                }
            ]
        }
    ]
}
```

### [04.6]-[MIRROR_EMBED]

```json template
{
    "type": "doc",
    "content": [
        {
            "type": "embed",
            "attrs": {
                "id": null,
                "objectType": "note",
                "objectId": "11111111-1111-4111-8111-111111111111",
                "width": "100%",
                "alignment": "center"
            }
        }
    ]
}
```

### [04.7]-[MATH]

`math_display` is a block; `math_inline` is an inline sibling next to `text` inside a paragraph. Neither uses `attrs` or a top-level `text` property for the formula. Put the TeX string in `content` as a single child `text` node. Multiple child `text` nodes are schema-valid, but prefer one child `text` node when creating new math content.

```json template
{
    "type": "doc",
    "content": [
        {
            "type": "math_display",
            "attrs": { "id": null },
            "content": [{ "type": "text", "text": "\\int_0^1 x^2 \\,dx = \\frac{1}{3}" }]
        },
        {
            "type": "paragraph",
            "attrs": { "id": null },
            "content": [
                { "type": "text", "text": "Inline: " },
                {
                    "type": "math_inline",
                    "content": [{ "type": "text", "text": "a^2 + b^2 = c^2" }]
                },
                { "type": "text", "text": " in a sentence." }
            ]
        }
    ]
}
```

### [04.8]-[TABLE]

```json template
{
    "type": "doc",
    "content": [
        {
            "type": "table",
            "attrs": { "id": null, "hasRowHeader": false, "hasColumnHeader": true },
            "content": [
                {
                    "type": "table_row",
                    "attrs": { "id": null },
                    "content": [
                        {
                            "type": "table_header",
                            "attrs": { "colspan": 1, "rowspan": 1 },
                            "content": [
                                {
                                    "type": "paragraph",
                                    "attrs": { "id": null },
                                    "content": [{ "type": "text", "text": "Name" }]
                                }
                            ]
                        },
                        {
                            "type": "table_header",
                            "attrs": { "colspan": 1, "rowspan": 1 },
                            "content": [
                                {
                                    "type": "paragraph",
                                    "attrs": { "id": null },
                                    "content": [{ "type": "text", "text": "Status" }]
                                }
                            ]
                        }
                    ]
                },
                {
                    "type": "table_row",
                    "attrs": { "id": null },
                    "content": [
                        {
                            "type": "table_cell",
                            "attrs": { "colspan": 1, "rowspan": 1 },
                            "content": [
                                {
                                    "type": "paragraph",
                                    "attrs": { "id": null },
                                    "content": [{ "type": "text", "text": "Schema docs" }]
                                }
                            ]
                        },
                        {
                            "type": "table_cell",
                            "attrs": { "colspan": 1, "rowspan": 1 },
                            "content": [
                                {
                                    "type": "paragraph",
                                    "attrs": { "id": null },
                                    "content": [{ "type": "text", "text": "Draft" }]
                                }
                            ]
                        }
                    ]
                }
            ]
        }
    ]
}
```
