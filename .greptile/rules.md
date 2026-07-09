# Review context — Parametric_Forge

Machine-owner repo: nix-darwin + Home Manager flake for one macOS Apple Silicon host running Determinate Nix on nixpkgs-unstable. Every line configures the system, deploys files/packages, or enables services — anything else does not belong.

## Design paradigms

- Fewer, deeper polymorphic surfaces beat many loose files. Optimization means collapsing types/options/functions into denser dispatch surfaces in the same file — never extraction, never capability loss. LOC is measured in lines, never bytes.
- Parameterize ingress and egress. Hardcoded strings, repo paths, usernames, ports, or geometry numbers are defects; values are rows, parameters, or model-derived.
- Canonical owners: config.forge.theme (all color), apps/chords.nix (all keybinds), mcp-fleet.nix (MCP servers: one row = launcher + registration + probe), owner package tables (tool admissions), services/ (Pulumi-owned external service estate), overlays/forge-provision (container provisioning, schema-v3 JSON contract).
- Deploy rail: forge-redeploy owns switch lifecycle with typed receipts and exact-closure activation; its deploy arm is proven — treat edits there as high-risk.
- Receipts over narration: lifecycle commands emit typed receipt lines; scripts that print prose status instead of structured receipts are below the bar.

## Universal bar

Anticipate 10x functionality growth: surfaces absorb new modalities as rows, cases, or dispatch arms — never as new files, flags, or knobs. Defects: knob/param/flag spam, hardcoded values, fragile string plumbing, naive happy-path logic, hand-rolled reimplementations of capability the ecosystem already provides. External packages are first-class implementation material at full power, newest stable versions. Everything ships agent-first: composable, receipt-bearing, self-describing. Collapse spam relentlessly.

## Review priorities

1. Regression against a landed law (theme tokens, chord ownership, schema-v3 envelopes, pnpm-only node, no-LFS) outranks style.
2. New public surface (option, command, flag, file) demands justification against extending an existing owner.
3. Secret-adjacent code: values must never reach agent-facing JSON, logs, or Pulumi outputs unredacted; parsing never touches secret bytes with eval/source.
