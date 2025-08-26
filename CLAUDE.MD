# Parametric Forge • Execution Standards

## Code Quality

### Nix Requirements

**ALWAYS**
- Use latest nixpkgs-unstable
- Leverage `myLib` functions over reimplementing
- Platform detection via `context` (never hardcode)
- Atomic operations only (rollback-safe)
- Pure functions where possible

**NEVER**
- Pin old nixpkgs versions
- Create wrapper modules for single options
- Mix system and home-manager scopes
- Use `with pkgs;` at file level (scope pollution)
- Create files "for later" or "just in case"

### Code Density

**Target**: 300 LOC max per file. If approaching limit:
1. Extract to `lib/` if reusable
2. Split by concern if truly distinct
3. Refactor for density if neither applies
EXCEPTION: Some files are justified to be larger than LOC limit (must be justified - long list, single concern files)

**Patterns**:
```nix
# YES: Dense, multi-capable
mkService = { name, exec, env ? {}, after ? [], ... }@args:
  let
    baseService = { inherit exec env; wantedBy = ["default.target"]; };
    withDeps = if after != [] then baseService // { inherit after; } else baseService;
  in withDeps // (removeAttrs args ["name" "exec" "env" "after"]);

# NO: Function spam
mkSimpleService = name: exec: { inherit exec; };
mkServiceWithEnv = name: exec: env: { inherit exec env; };
mkServiceWithDeps = name: exec: after: { inherit exec after; };
```

### File Structure

```nix
# Title         : [filename]
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /[relative-path]
# ----------------------------------------------------------------------------
# [One-line description if complex]

{ lib, pkgs, myLib, context, ... }:

let
  # Minimal let bindings (prefer inline)
  critical = computeExpensive args;
in
{
  # Direct implementation
}
```

## Execution Philosophy

### YAGNI + KISS

**Before adding ANY code, ask**:
1. Does `lib/` already provide this?
2. Does nixpkgs have a solution?
3. Can I extend existing pattern?
4. Is this needed NOW (not "might be useful")?

If any "no" → don't add it.

### Refactoring > Rewriting

**When modifying**:
- Read entire file first
- Understand existing patterns
- Surgically modify in-place
- Never create "improved" versions

**Example**:
```nix
# File exists with 10 functions
# Need: Add SSL support to one function

# YES: Extend existing function
someFn = args:
  let base = originalLogic args;
  in base // lib.optionalAttrs (args ? ssl) { inherit (args) ssl; };

# NO: Create new function
someFnWithSSL = args: ...  # Function spam
```

### Platform Awareness

**Context-driven code**:
```nix
# YES: Platform-aware
home.packages = lib.flatten [
  commonPackages
  (lib.optionals context.isDarwin darwinPackages)
  (lib.optionals context.isLinux linuxPackages)
];

# NO: Hardcoded assumptions
home.packages = if pkgs.stdenv.isDarwin then...
```

## Language-Specific Standards

### Python (Secondary)
- Python 3.13+ only (never older)
- `uv` for package management
- `ruff` for all linting/formatting
- `basedpyright` over mypy
- `anyio` + `aiofiles` for async

### Rust (Tertiary)
- Latest stable toolchain
- `cargo-deny` for security
- Workspace-first organization
- `#![deny(warnings)]` always

### Shell Scripts
- IMPORTANT: CRITICAL: Always add the .sh extension to bash scripts
- `set -euo pipefail` mandatory
- ShellCheck must pass
- Prefer Nix `writeShellScriptBin` over raw scripts

## Testing & Validation

**Every change**:
```bash
# Required
nix flake check         # Must pass
darwin-rebuild build    # Must succeed

# Before commit
nix fmt                 # Format all
nix run .#check-system  # Verify deployment
```

## Module Patterns

### Options (sparingly)
```nix
# Only if TRULY configurable
options.myFeature = {
  enable = mkEnableOption "feature";
  # Minimal options, maximum inference
};

# Prefer direct config over options
config = {
  # Direct implementation
};
```

### Imports
```nix
# YES: Specific imports
{ lib, pkgs, myLib, context, ... }:

# NO: Kitchen sink
{ self, config, lib, pkgs, inputs, ... }:
```

### Library Extensions
```nix
# lib/[new-feature].nix - Only if:
# 1. Used in 3+ places
# 2. Complex logic (>10 lines)
# 3. Platform/context agnostic
```

## Anti-Patterns to Avoid

**Function Spam**: Multiple functions doing similar things
**Wrapper Modules**: Modules that just wrap other modules
**Anticipatory Code**: "Might need this later"
**Over-Abstraction**: More abstraction than implementation
**Dead Code**: Commented out or unreachable code
**Version Pinning**: Using old versions without critical reason
**Manual Checks**: Hardcoded platform/user detection

## Commit Standards

**Message Format**:
```
[scope]: action

- Specific change 1
- Specific change 2
```

**Scopes**: `nix`, `darwin`, `home`, `lib`, `flake`
**Actions**: `add`, `fix`, `refactor`, `remove` (never "update" or "improve")

## Performance

**Build Time**:
- Prefer `imports` over inline modules
- Use `mkIf` for conditional heavy evaluations
- Cache derivations in `let` bindings

**Runtime**:
- Scripts: Parallelize with `&` and `wait`
- Services: Lazy activation where possible
- File ops: Batch with `symlinkJoin`

## Remember

IMPORTANT: CRITICAL:This is Nix configuration, not application code. Every line either:
1. Configures the system/user environment
2. Deploys files/packages
3. Enables services

If it doesn't do one of these, it doesn't belong here.