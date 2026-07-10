# [CODEX_SKILL_AUTHORING]

Authoring skills FOR Codex: the on-disk format, discovery roots, trigger mechanics, the `agents/openai.yaml` metadata surface, and the exact deltas from Claude-side skills. A skill is a directory holding a `SKILL.md` whose frontmatter carries `name` and `description`; `scripts/`, `references/`, and `assets/` ride alongside optionally. The format follows the agent-skills open standard, so a Claude-side bundle ports with only frontmatter and routing deltas.

## [01]-[FORMAT_AND_LIMITS]

```md template
---
name: skill-name
description: What the skill does and exactly when it does and does not trigger.
---

Skill instructions for Codex to follow.
```

- [NAME]: 64 characters maximum; the qualified plugin-namespaced form caps at 128.
- [DESCRIPTION]: 1024 characters maximum — the hard truncation point, not a style budget.
- [SCAN]: Discovery walks 6 directory levels deep, 2000 skill directories per root.
- [BODY]: Imperative instructions; scripts execute without entering context; references load on demand.

## [02]-[DISCOVERY_ROOTS]

| [INDEX] | [SCOPE]  | [LOCATION]                                      | [NOTES]                                                 |
| :-----: | :------- | :---------------------------------------------- | :------------------------------------------------------ |
|  [01]   | `REPO`   | `.agents/skills` in cwd, parents, and repo root | Checked-in team skills; nearest-directory scoping       |
|  [02]   | `USER`   | `$HOME/.agents/skills`                          | Current user root                                       |
|  [03]   | `USER`   | `$CODEX_HOME/skills` (`~/.codex/skills`)        | Deprecated root, still loaded — the estate's codex host |
|  [04]   | `ADMIN`  | `/etc/codex/skills`                             | Machine-shared                                          |
|  [05]   | `SYSTEM` | Bundled, cached at `$CODEX_HOME/skills/.system` | `skill-creator`, `skill-installer`, plan — never edited |

Symlinked skill folders resolve to their targets. Two skills sharing a `name` do not merge and do not shadow — both list, unlike Claude Code where personal beats project. Codex detects skill changes automatically; a missing update means restart.

## [03]-[TRIGGERS]

Invocation is explicit (`$skill-name` in the prompt, or `/skills` in the CLI/IDE) or implicit by description match. The initial skills list rides at most 2% of the model's context window (8000 characters when unknown); descriptions shorten first and whole skills drop from the list under pressure — the owned deliverable and primary trigger nouns ride the first clause of the description, the boundary closes it. The selected skill's full `SKILL.md` always loads regardless of listing truncation.

## [04]-[OPENAI_YAML]

`agents/openai.yaml` is the optional Codex-native metadata file: app-surface presentation, invocation policy, and tool dependencies.

```yaml template
interface:
    display_name: "User-facing name"
    short_description: "User-facing description"
    icon_small: "./assets/small-logo.svg"
    icon_large: "./assets/large-logo.png"
    brand_color: "#3B82F6"
    default_prompt: "Surrounding prompt to use the skill with"

policy:
    allow_implicit_invocation: false # default true; false leaves only explicit $skill

dependencies:
    tools:
        - type: "mcp"
          value: "serverName"
          description: "What the server provides"
          transport: "streamable_http"
          url: "https://example.com/mcp"
```

`[[skills.config]]` rows in `~/.codex/config.toml` disable a skill without deleting it (`path = ".../SKILL.md"`, `enabled = false`); restart applies.

## [05]-[CLAUDE_DELTAS]

- [FRONTMATTER]: `disable-model-invocation`, `user-invocable`, `context: fork`, `allowed-tools`, and dynamic context injection are Claude Code extensions — Codex ignores them; invocation policy moves to `policy.allow_implicit_invocation` in `agents/openai.yaml`.
- [USE_CASES]: `use_cases.yaml` is an upstream eval convention — activation-query fixtures some vendor repos ship for trigger testing — not part of the Codex format; a ported skill drops it.
- [METADATA]: Upstream-tracking frontmatter (`metadata.github-*`, `version`) is vendor sync bookkeeping; an estate-owned skill carries `name` and `description` only.
- [DISTRIBUTION]: Plugins are the installable unit for sharing (one or more skills plus optional app mappings and MCP config); `$skill-installer <name>` pulls curated skills locally; direct folders serve authoring and repo scoping.
- [ESTATE]: Estate codex skills are ports of the Claude-side Forge masters — same body, Claude-only frontmatter stripped, `agents/openai.yaml` added where app-surface metadata or invocation policy earns it. `~/.agents/skills` is the target root for new ports; the deprecated `~/.codex/skills` root still loads and hosts the standing estate until drained.
- [HOME_ONLY]: Codex surfaces are home-only — a project-local `.codex/` directory is a defect: port load-bearing rows to `~/.codex`, then delete it. Checked-in repo skills ride `.agents/skills`, never `.codex/`.
