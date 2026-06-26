# [H1][GLOBAL-CONFIG]

Mermaid v11+ configuration via YAML frontmatter; ELK layout engine for advanced graph positioning.

[CRITICAL] v10.5.0 deprecates `%%{init:...}%%`; use YAML frontmatter with `config:` key exclusively.

## [01]-[FRONTMATTER]

**Structure:** Opening `---` (line 1), `config:` root key (not `init:`), nested diagram-specific settings, closing `---` (before diagram).
**Precedence:** Mermaid defaults -> Site `initialize()` -> Diagram frontmatter (lowest to highest).

[IMPORTANT] Consistent indentation required; case-sensitive keys; misspellings silently ignored; malformed YAML breaks diagram.

## [02]-[APPEARANCE]

| [INDEX] | [KEY]            | [TYPE]  | [DEFAULT] | [DESCRIPTION]                                  |
| :-----: | ---------------- | ------- | :-------: | ---------------------------------------------- |
|  [01]   | `look`           | string  |   `neo`   | `neo`, `classic` (flowcharts/state only)       |
|  [02]   | `theme`          | string  | `default` | `default`, `base`, `dark`, `forest`, `neutral` |
|  [03]   | `themeVariables` | object  |   `{}`    | Custom overrides (`base` theme only)           |
|  [04]   | `themeCSS`       | string  |  `null`   | Direct CSS injection                           |
|  [05]   | `darkMode`       | boolean |  `false`  | Dark mode color adjustments                    |

## [03]-[TYPOGRAPHY]

**Fonts:** `fontFamily` (trebuchet ms), `altFontFamily` (null), `fontSize` (16px).
**Wrapping:** `markdownAutoWrap` (true, v10.1.0+), `wrap` (false, global).

## [04]-[RUNTIME]

| [INDEX] | [KEY]                    | [TYPE]  | [DEFAULT] | [DESCRIPTION]                     |
| :-----: | ------------------------ | ------- | :-------: | --------------------------------- |
|  [01]   | `logLevel`               | number  |    `5`    | 0=trace, 1=debug, 2=info, 5=fatal |
|  [02]   | `maxTextSize`            | number  |  `50000`  | Max diagram text chars (DoS)      |
|  [03]   | `maxEdges`               | number  |   `500`   | Max edge count (DoS)              |
|  [04]   | `suppressErrorRendering` | boolean |  `false`  | Hide syntax error diagrams        |
|  [05]   | `deterministicIds`       | boolean |  `false`  | Reproducible SVG IDs              |
|  [06]   | `htmlLabels`             | boolean |  `true`   | Allow HTML tags in labels         |

## [05]-[SECURITY]

| [INDEX] | [LEVEL]      | [BEHAVIOR]                                         |
| :-----: | ------------ | -------------------------------------------------- |
|  [01]   | `strict`     | Default; tags encoded, scripts disabled, no clicks |
|  [02]   | `antiscript` | HTML allowed (no scripts), clicks enabled          |
|  [03]   | `loose`      | HTML + scripts allowed, clicks + links enabled     |
|  [04]   | `sandbox`    | Isolated iframe, no JavaScript                     |

**Config:** `securityLevel` (strict), `secure` (restricted keys), `startOnLoad` (true), `dompurifyConfig` ({}).

[CRITICAL] Frontmatter ignores `securityLevel` overrides — use `initialize()` only.

## [06]-[LAYOUT]

**Algorithms:** Dagre (`layout: dagre`, default hierarchical), ELK (`layout: elk`, requires `@mermaid-js/layout-elk`).

**ELK options:** `mergeEdges` (false), `nodePlacementStrategy` (BRANDES_KOEPF | NETWORK_SIMPLEX | LINEAR_SEGMENTS | SIMPLE), `cycleBreakingStrategy` (GREEDY_MODEL_ORDER | MODEL_ORDER | GREEDY | DEPTH_FIRST | INTERACTIVE), `forceNodeModelOrder` (false), `considerModelOrder` (NODES_AND_EDGES).

## [07]-[DIRECTION]

**Values:** `LR`, `RL`, `TB`, `BT`. Applies to flowchart, ER, class, state. Sequence diagrams: `TB` implicit — direction ignored.

## [08]-[SECURE_KEYS]

**Restricted to `initialize()` only:** `maxTextSize`, `maxEdges` (DoS), `secure`, `securityLevel`, `dompurifyConfig` (security), `startOnLoad`, `suppressErrorRendering` (runtime).

[CRITICAL] Frontmatter ignores these keys; configure via `mermaid.initialize()` at site level.
