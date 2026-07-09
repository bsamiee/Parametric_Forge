# Review context — Parametric_Forge

Machine-owner repo: nix-darwin + Home Manager flake for one macOS Apple Silicon host running Determinate Nix on nixpkgs-unstable. Every line configures the system, deploys files/packages, or enables services — anything else does not belong.

## Design paradigms

- Fewer, deeper polymorphic surfaces beat many loose files. Optimization means collapsing types/options/functions into denser dispatch surfaces in the same file — never extraction, never capability loss. LOC is measured in lines, never bytes.
- Parameterize ingress and egress. Hardcoded strings, repo paths, usernames, ports, or geometry numbers are defects; values are rows, parameters, or model-derived.
- One owner per axis: docs/standards/nix-doctrine.md declares the vocabulary owners (color, keybind, MCP server, tool admission, generated config); a value placed outside its owner or duplicated into a consumer is a defect, whatever the owner's current file name.
- Service estate is IaC: external service state lives as typed Pulumi rows under services/; container provisioning rides the schema-v3 JSON envelope contract under overlays/forge-provision.
- Deploy rail: forge-redeploy owns switch lifecycle with typed receipts and exact-closure activation; its deploy arm is proven — treat edits there as high-risk.
- Receipts over narration: lifecycle commands emit typed receipt lines; scripts that print prose status instead of structured receipts are below the bar.

## Universal bar

Anticipate 10x functionality growth: surfaces absorb new modalities as rows, cases, or dispatch arms — never as new files, flags, or knobs. Defects: knob/param/flag spam, hardcoded values, fragile string plumbing, naive happy-path logic, hand-rolled reimplementations of capability the ecosystem already provides. External packages are first-class implementation material at full power, newest stable versions. Everything ships agent-first: composable, receipt-bearing, self-describing. Collapse spam relentlessly.

## Review priorities

1. Regression against a landed law (vocabulary ownership, schema-v3 envelopes, pnpm-only node, no-LFS) outranks style.
2. New public surface (option, command, flag, file) demands justification against extending an existing owner.
3. Secret-adjacent code: values must never reach agent-facing JSON, logs, or Pulumi outputs unredacted; parsing never touches secret bytes with eval/source.

## Load-bearing exceptions

Code that violates generic best practice on purpose — do not flag:

- Aggressive API breaks with every call site updated in the same change are the sanctioned rename path, not regressions.
- Dense single-expression bodies and heavy polymorphic dispatch are the bar, not obfuscation.
- Absent defensive guards inside domain logic reflect admission-once boundaries, not missing error handling.
- Sparse 1-2 line agent-facing comments are compliance with comment law, not missing documentation.
- Nix string-interpolated shell bodies with declared runtimeInputs are the packaging idiom, not embedded-script smell.
- A large file that owns one full concern is sanctioned; never recommend splitting by size.

## Durable prose and skill detection

Durable markdown — docs, standards, skills, prompts — is agent-facing law. Flag:

- No-op intensifiers: quality adjectives (careful, high-quality, robust, thorough) in a sentence with no owner, action, trigger, or gate.
- Filler lead-ins: "it is important to note", "note that", "make sure to", "be sure to", "remember to", "keep in mind".
- Restated harness obligations: telling an agent to follow CLAUDE.md/AGENTS.md, use available tools, or obey system instructions.
- Quality ladders (good/better/best, minimum/ideal) where a contract gate belongs.
- Command catalogs with no task trigger or acceptance signal per row.
- Generic lifecycle sequences (think, plan, implement, validate, summarize) and mandated reasoning shapes.
- Closing checklists with no machine-checkable gate.
- Process ledgers: ship-status markers, decision tags, freshness stamps, session narration in durable prose.
- Meta-commentary: sentences whose subject is the document itself (this skill, this file, this section) outside routing rows.
- Defensive caveats: hedges (may, might, generally, usually, when possible) softening settled rules; contract qualifiers (optional, if present, where supported, unless) survive.
- Bare abstractions: three or more abstract guidance bullets with no paired rejected/accepted example, template, or gate.
- Fixed output skeletons: one mandated report shape (summary, findings, recommendations, next steps) regardless of consumer.
- Skill bundles (.claude/skills/**): first/second-person frontmatter descriptions — quoted user-utterance trigger phrases are not voice; over-broad or keyword-stuffed trigger descriptions; SKILL.md over 500 lines or carrying reference banks inline; references that only route to other references; deterministic multi-step procedures narrated in prose where a bundled script belongs; instructed network fetches or global installs inside skill bodies, except an owned install surface naming exact source, scope, and verification.
