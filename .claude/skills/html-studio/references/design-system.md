# [DESIGN_SYSTEM]

NOCTURNE is the single visual voice: a Dracula-descended dark-first system on a violet-black ground with two committed accent roles and an editorial serif voice. The baseline stylesheet is a stamped byte region — `studio.py stamp` writes it from the canon at `scripts/nocturne/baseline.css` and the gate fails any drifted copy — so a template carries the floor byte-identically and adds only template-local rules after it, in the declared layers. A second color vocabulary, a raw hex outside the token block, or an sRGB `color-mix` is a defect the gate flags.

## [01]-[CONTRACT]

One `<!doctype html>` file: one `<title>`, all CSS in one `<style>`, one executable `<script>`, and optional `application/json` payload scripts as inert data. Zero network references — no CDN, no webfont, no `https://` in any `src`/`href`, no `url()` that resolves off-machine.

| [INDEX] | [ALLOW]        | [FORM]                                                     |
| :-----: | :------------- | :--------------------------------------------------------- |
|  [01]   | In-page anchor | `href="#section-id"`                                       |
|  [02]   | Inline asset   | `data:` URI                                                |
|  [03]   | Sibling page   | relative `href` to a sibling                               |
|  [04]   | Return channel | server-injected `artifact-return` + `artifact-token` metas |

Wide content — tables, diagrams, code — rides inside an `overflow-x:auto` container (`.twrap`, `pre`); `body` sets `overflow-x:hidden` so the page never scrolls sideways.

## [02]-[TOKENS]

Semantic names only; a consumer reads intent, never hex. Dark is the shipped base; light arrives through `data-theme="light"` and the system-preference media query.

- Elevation: `--bg` `--surface` `--raised` `--raised-2` `--overlay` — each step perceptibly lighter than the one below, so depth is carried by tone; `--line`/`--line-strong` are white-alpha hairlines that read at every elevation, and `--boundary` is the bright containment stroke every dashed zone and container border binds — the shared boundary color the mermaid skill draws its containers with.
- Text: `--text` `--text-muted` `--text-faint` — `--text-muted` is contrast-guaranteed legal body copy; `--text-faint` is legal only for pure decoration at 13px and above (grip dots, disabled controls, filter-dimmed de-emphasis). Any label carrying real information at 12px or below binds `--text-muted`, never `--text-faint` — at 11px on `--raised`, faint sits near 3.4:1 and fails the text floor.
- Violet (`--accent` family): the interactive role — buttons, links, focus, selection, toggles, meters.
- Copper (`--editorial` family): the editorial role — eyebrows, section numerals, keyline callouts, figure captions.
- Status: `--ok` `--warn` `--fail` `--info` — chips, verdicts, rails; hue reinforces, the bracket marker carries state.
- Series: `--series-1`..`--series-6` — chart marks only; a dataviz skill, when present, owns their assignment.
- Space: `--s1`..`--s8` (4/8/12/16/24/32/48/64) — every gap, pad, and margin rides a token.
- Type: `--fs-2xs`..`--fs-4xl` on a 1.20 modular scale. Mono is the systemic voice — every numeral, stat figure, label, tag, chip, keycap, data cell, stamp, and code span rides `--font-mono`; serif (`--font-display`) is a restrained editorial accent spent only on `h1`/`h2` and an optional deck lead, and `--font-sans` carries sentences and nothing else.
- Motion: entries ride `--dur-1/2/3` with `--ease-out` `--ease-standard` `--ease-spring`; exits ride the shorter `--dur-out-2/3` with `--ease-standard` — leaving is quicker and quieter than arriving. Reduced-motion zeroes every duration.
- Shape: `--r-1/2/3` `--r-full` `--shadow-1/2` `--measure`.

Status color never carries state alone: the chip's bracket text — `[DONE]` `[BLOCKED]` `[OPEN]` `[AT-RISK]` — is the accessible carrier and the hue is reinforcement. All derived color is `color-mix(in oklch, ...)`.

## [03]-[BASELINE]

The baseline declares the layer order — `reset, tokens, base, components, utilities, print, overrides` — and populates every layer but `utilities`; template-local rules land in `components`, `utilities`, or `overrides`, never unlayered. Print flips to the light palette on white; forced colors hand the palette to the system. The byte canon is `scripts/nocturne/baseline.css`, stamped between the `NOCTURNE_BASELINE` markers by `studio.py stamp` and byte-verified by `studio.py gate`; a fresh composed artifact starts from `studio.py stamp --new`, never from a hand-copied floor. The registered `@property` declarations (`--tone`, `--raise`, `--lift`) travel with the baseline, above the layer statement.

## [04]-[COMPONENTS]

- `.eyebrow` + `h1` + `.deck` — the header triad: copper mono kicker, serif display title, muted deck line.
- `.section` + `h2::before` — CSS-counter section numerals in copper mono; the page body sets `counter-reset:sec`.
- `.card` — one lifted concern block on `--raised` with hairline and shadow.
- `.grid` — responsive `auto-fit` columns for direction sets and swimlanes.
- `.chip` — the 20px uppercase mono status pill carrying bracket text; add `ok`/`warn`/`fail`/`info`. `.dot` is its passive sibling — an 8px status point beside a plain label for ambient state that earns no pill.
- `.stat` — mono display numeral at weight 600 with an optional `.delta.up`/`.delta.down` trend pill.
- `.kv` — the key-value fact grid: mono uppercase `dt` labels in a fixed 6–10rem column, values baseline-aligned beside them; owners, dates, ids, and metadata read as one aligned ledger instead of scattered `small` runs.
- `.rail` — 3px keyline callout; copper by default, status hue by class.
- `.toc` — sticky in-page nav; `.on` marks the active section, stamped by the kernel's scroll spy.
- `.meter` — violet gradient fill driven by the `--value` custom property (0–100), so JS writes one number and never an inline width; `.meter.seg` stacks `ok`/`warn`/`fail` segments for pass/fail/skip.
- `.btn` — the 32px dense control; secondary at rest, `.primary` the filled violet action, `.ghost` the quiet sibling; pressed state rides `aria-pressed="true"`.
- `.seg` — a fixed choice set as a radio group styled as one segmented control; `:has(input:checked)` carries the latch with zero script.
- `.field` — top-aligned form anatomy: mono uppercase label, 32px control, help line below; `:user-invalid` flips the border and help to `--fail`.
- `.toolbar` — the sticky control band: 48px, translucent `--raised-2` under blur, one hairline below, controls in labeled `.group` clusters.
- `.pop` + `.toast` — top-layer surfaces on `--raised-2`: the anchored popover panel and the timed status flash, both entering on `--dur-2` and leaving on `--dur-out-2`.
- `.export-bar` + `.drawer-tab` — the export drawer: a `--raised` pill anchored bottom-right opens a rounded side panel at 60vh, never full-height or full-width, interior order fixed — send, disk egress, per-type fields. The drawer markup is the stamped `NOCTURNE_DRAWER` region; per-type controls append into `[data-drawer-fields]` at render time.
- `.twrap` `.kbd` `.num` `.skip` `.rowline` `pre`/`code` — wide-content shell, keycap, tabular numerals, skip link, inline flow row, code surfaces.

Derived structural devices — the heat cell, timeline spine, split pane, sidenote — live in [styling.md](styling.md) with their recipes and ceilings; the baseline owns only the classes above.

## [05]-[THEME]

The base `:root` is NOCTURNE dark; the light palette arrives through `@media (prefers-color-scheme:light)` scoped `:root:not([data-theme])`, so a stamped choice suppresses the media query entirely. `:root[data-theme="light"]` restates the light palette and wins in both directions. The kernel's theme controller stamps `data-theme` on `documentElement` and persists it under a title-slug key; with nothing stored the page follows the system preference and ships dark otherwise.

## [06]-[CHARTS_AND_FIGURES]

Charts and diagrams are inline `<svg>` only — no canvas, no image, no library. Every stroke and fill reads a token through CSS classes (`--accent`, `--ok`, `--line`, `--series-*`); wide plots ride `.twrap`. Chart mark and palette decisions defer to a dataviz skill when the host exposes one; diagram construction law — markers, flows, node interaction, standalone export — is [svg.md](svg.md).

## [07]-[MICRO_SCALE]

Quality lives at the per-element level: every text class carries an exact size, weight, and floor, and any element rendering below its floor is a defect regardless of how the system reads at a glance.

| [INDEX] | [CLASS]                                       | [TOKEN]      | [FAMILY_WEIGHT]         | [FLOOR] |
| :-----: | :-------------------------------------------- | :----------- | :---------------------- | :------ |
|  [01]   | h1                                            | `--fs-3xl`   | serif 600               | 30px    |
|  [02]   | h2                                            | `--fs-xl`    | serif 600               | 21px    |
|  [03]   | h3                                            | `--fs-lg`    | sans 600                | 18px    |
|  [04]   | deck / lead                                   | `--fs-lg`    | sans or serif 400       | 17px    |
|  [05]   | stat numeral, KPI value                       | `--fs-2xl`   | mono 600, tabular       | 22px    |
|  [06]   | body p, li                                    | `--fs-md`    | sans 400                | 15px    |
|  [07]   | table cell                                    | `--fs-sm`    | sans 400 / mono for num | 13px    |
|  [08]   | pre / code block                              | `--fs-xs`    | mono 400                | 12px    |
|  [09]   | small / caption                               | `--fs-xs`    | sans 400                | 12px    |
|  [10]   | svg canvas label                              | 11px literal | mono 400-500            | 11px    |
|  [11]   | eyebrow, chip, th, kbd, delta, stamp, numeral | `--fs-2xs`   | mono 600, uppercase     | 11px    |

- `--fs-2xs` is the label floor and is legal only for uppercase mono at weight 600 with letter-spacing at or above `.06em` — never sentence text, never `--text-faint` ink.
- Letter-spacing per role: eyebrow `.08em`, th, chips, kv labels, and section numerals `.06em`; numerals track `-.01em` and always set `tabular-nums`.
- Nothing on an SVG canvas renders below 11px; a value label that must dominate its axis binds `--text` at weight 600 while tick numerals stay `--text-muted`.
- Component anatomy is fixed: chips 20px tall with `--s2` inline padding; buttons and inputs 32px; toolbars 48px; icon gaps `--s1` inside chips and `--s2` inside buttons; card padding `--s4` with `--s3` compact and `--s5` reading variants; kv rows baseline-aligned.
- Elevation nesting: a chip, input, code block, or `th` sits one step DOWN from its host (`--surface` on `--raised`); a nested card steps UP to `--raised-2` — never `--raised` on `--raised`. A fill meeting a same-tone neighbor without a `--s4` gap steps its border to `--line-strong`; card-to-card separation is otherwise carried by the gap, since `--line` between equal elevations reads near 1.3:1 and vanishes.
- An inline diagram sits on the page body or inside a container one elevation below its canvas; a diagram whose canvas tone is within one elevation step of its host card loses its edge and either the card steps down or the SVG takes a `--line-strong` frame.

## [08]-[HIERARCHY_BUDGETS]

Redundancy and salience carry hard budgets; the review counts them.

- One fact, one form: a card or row states a given status, owner, date, or priority exactly once — a status chip beside a status-tinted border beside a status pill restating the same state is the duplication defect, and a dependency annotation (`[BLOCKED-BY] <name>`) replaces, never accompanies, the bare `[BLOCKED]` chip it explains.
- One primary signal per region: a card, panel, or viewport region carries one element at display scale and at most three secondary signals; a second competing numeral or headline demotes or leaves.
- Header band anatomy: metadata (eyebrow, chips, date) sits above or baseline-beside the title, the title follows within `--s2`, actions sit at the right edge — a title never sandwiches between two metadata rows.
- Edge budget: a viewport exposes at most three major left edges — shell, content, inset — and a card at most two interior left edges; a fourth alignment axis is a layout defect.
- Accent budget: violet appears as a filled field somewhere above the fold and covers well under a tenth of the viewport; status hues stay under a twentieth — a page glowing with status color has spent its alarm before anything is wrong.
