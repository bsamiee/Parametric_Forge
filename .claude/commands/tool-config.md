# Tool Configuration Research & Implementation

**ARGUMENTS PARSING:**
Extract from "$ARGUMENTS":

- `tool` - Required: Tool URL, or name to research and configure (e.g., "yazi", "bat", "ripgrep")

**CRITICAL PARALLEL EXECUTION REQUIREMENTS:**

- Phase 1: MUST invoke 5 tool-researcher agents in ONE SINGLE message with multiple Task tool calls
- Phase 2: MUST invoke config agents (builder/refactor mix) in ONE SINGLE message with multiple Task tool calls
- NEVER invoke agents sequentially - always batch in single messages for true parallelism

## PHASE 1: PARALLEL RESEARCH (5 Concurrent Agents)

**MANDATORY:** Create ALL 5 research agents in a SINGLE message using multiple Task tool invocations:

1. **Config Format Researcher**

   - Focus: Configuration file formats, locations, XDG compliance
   - Output: Config format (TOML/YAML/JSON), paths, XDG status

1. **Environment & Runtime Researcher**

   - Focus: Environment variables, runtime dependencies, shell integrations
   - Output: All env vars, dependencies, shell requirements

1. **Platform Differences Researcher**

   - Focus: Darwin vs Linux differences, package manager variations
   - Output: Platform-specific paths, features, limitations

1. **Home-Manager Integration Researcher**

   - Focus: Nixpkgs support, home.programs availability, Nix patterns
   - Output: Module existence, package name, Nix-specific requirements

1. **Examples & Patterns Researcher**

   - Focus: GitHub examples, dotfiles, well-maintained configs
   - Output: 3+ real-world examples, common patterns, best practices

**Synthesis Step:**
After receiving ALL 5 agent responses, synthesize findings into:

```json
{
  "tool": "name",
  "config_format": "TOML/YAML/JSON/none",
  "xdg_compliant": true/false,
  "home_manager_module": true/false,
  "files_needed": {
    "environment.nix": ["VAR1", "VAR2"],
    "xdg.nix": ["configHome", "dataHome"],
    "configs/": "path/to/config",
    "programs/": "module-name",
    "file-management.nix": ["deployments"]
  },
  "action": "implement/refactor/mixed"
}
```

## PHASE 2: PARALLEL IMPLEMENTATION/REFACTORING (Up to 5 Concurrent Agents)

**MANDATORY:** Based on synthesis, create ALL needed agents in a SINGLE message:

**Decision Matrix:**

- New tool → Use tool-config-builder agents
- Existing tool needing updates → Use tool-config-refactor agents
- Mixed scenario → Use appropriate mix

**Agent Allocation (create all needed in ONE message):**

1. **Environment Agent** - Handle environment.nix changes
1. **XDG Agent** - Handle xdg.nix changes
1. **Config Agent** - Handle configs/apps/{tool}/ creation/updates
1. **Programs Agent** - Handle programs/{category}-tools.nix changes
1. **File Deployment Agent** - Handle file-management.nix changes

Pass synthesized JSON to each agent with their specific scope:

```json
{
  "tool": "name",
  "scope": "environment|xdg|configs|programs|file-management",
  "action": "implement|refactor",
  "data": {/* relevant subset of synthesis */}
}
```

## VALIDATION

After Phase 2 completion, perform final checks:

- Verify no duplicate configurations
- Ensure separation of concerns maintained
- Confirm all files follow Parametric Forge standards
- Run `nix flake check`

## CRITICAL REMINDERS

1. **NEVER** invoke agents one-by-one - ALWAYS batch in single messages
1. **ALWAYS** wait for ALL agents to complete before proceeding to next phase
1. **ENSURE** each agent receives specific, scoped instructions
1. **VERIFY** findings before implementation - no guessing or assumptions
1. **MAINTAIN** Parametric Forge standards - surgical edits, alphabetical order, KISS

## OUTPUT

Final report showing:

- Tool researched
- Files modified/created
- Configurations implemented/refactored
- Validation status
