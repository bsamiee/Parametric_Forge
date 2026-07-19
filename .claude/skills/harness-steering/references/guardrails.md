# [GUARDRAILS]

Guardrails bind beneath permissions: the sandbox isolates Bash at the OS level, the auto-mode classifier adjudicates commands no rule decided, and managed lockdown rows freeze what a fleet's users can re-open. Permission rules decide what the model may ask for; guardrails decide what the process can physically reach.

## [01]-[SANDBOX]

`sandbox.enabled` wraps Bash in OS isolation — Seatbelt on macOS, bubblewrap plus socat on Linux (`sandbox.bwrapPath`, `sandbox.socatPath` when off the default PATH), no native Windows lane — and `/sandbox` inspects the live state. `sandbox.failIfUnavailable` hard-fails where the OS lane is missing instead of silently degrading. Sandbox schema binds three reaches:

- [FILESYSTEM]: `sandbox.filesystem.allowRead`, `allowWrite`, `denyRead`, `denyWrite` take path rows whose `/`, `~/`, and `./` prefixes resolve as sandbox paths, not `Read`/`Edit` permission specifiers — the two grammars look alike and differ; `allowManagedReadPathsOnly` hands the read roster to managed scope.
- [NETWORK]: `sandbox.network.allowedDomains` and `deniedDomains` gate egress, `tlsTerminate` inspects HTTPS at the proxy, `httpProxyPort` and `socksProxyPort` route through local proxies, and `allowManagedDomainsOnly` locks the domain list to managed scope.
- [CREDENTIALS]: `sandbox.credentials` rows over files and env vars carry deny or mask behavior, `injectHosts` re-injects masked values for named hosts only, and `allowPlaintextInject` is the explicit downgrade.

Escape rows price every exception: `excludedCommands` runs named commands unsandboxed, `allowUnsandboxedCommands: false` is strict mode — the model cannot even request escape — and `autoAllowBashIfSandboxed` trades the Bash approval prompt for the sandbox boundary itself, the row that makes prompt-free autonomous lanes safe. Steering splits from permissions: a deny rule stops one spelling of a command, the sandbox stops the effect under every spelling.

## [02]-[AUTO_MODE]

`defaultMode: "auto"` routes unadjudicated commands through a background classifier; the `autoMode` block tunes it with prose rules, not specifiers. `allow`, `soft_deny`, and `hard_deny` arrays carry natural-language rules with `"$defaults"` splicing the shipped set into a custom list; `autoMode.environment` describes the machine so the classifier judges in context; `autoMode.classifyAllShell: true` routes every shell command through the classifier, including commands permission rules already allow. `autoMode` reads from user, local, and managed scopes and never from shared project settings — a repository cannot loosen its contributors' classifier. `claude auto-mode defaults`, `config`, and `critique` print the shipped rules, the effective merge, and a review of a candidate config; `permissions.disableAutoMode` removes the mode at managed scope.

## [03]-[LOCKDOWN]

Managed-scope rows freeze customization classes fleet-wide; each is a one-way door user and project scopes cannot re-open.

| [INDEX] | [ROW]                               | [FREEZES]                                      |
| :-----: | :---------------------------------- | :--------------------------------------------- |
|  [01]   | `disableAllHooks`                   | Every hook at every scope                      |
|  [02]   | `allowManagedHooksOnly`             | Hooks outside managed settings                 |
|  [03]   | `allowedHttpHookUrls`               | HTTP hook endpoints off the allowlist          |
|  [04]   | `allowManagedPermissionRulesOnly`   | Permission rules outside managed settings      |
|  [05]   | `allowManagedMcpServersOnly`        | MCP servers outside the managed allowlist      |
|  [06]   | `disableSkillShellExecution`        | Shell pre-injection lines inside skills        |
|  [07]   | `disableBundledSkills`              | The skills shipped inside Claude Code          |
|  [08]   | `disableSideloadFlags`              | `--plugin-dir`, `--agents`, and kin at launch  |
|  [09]   | `skipDangerousModePermissionPrompt` | The interactive confirm before dangerous modes |
|  [10]   | `disableBypassPermissionsMode`      | `bypassPermissions` as a reachable mode        |

Marketplace lockdown — `strictKnownMarketplaces`, `blockedMarketplaces`, managed `extraKnownMarketplaces` — rides `plugins.md`.
