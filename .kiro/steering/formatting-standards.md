---
inclusion: always
---

# Code Formatting Standards

## Universal File Headers

All files must include the standard header format:

**Nix files (.nix):**
```nix
# Title         : filename.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /path/to/file.nix
# ----------------------------------------------------------------------------
```

**Rust files (.rs):**
```rust
// Title         : filename.rs
// Author        : Bardia Samiee
// Project       : Parametric Forge Interface
// License       : MIT
// Path          : interface/src/filename.rs
// ---------------------------------------------------------------------------
```

## Section Organization

Use consistent section dividers for logical code organization:

**Nix files:**
```nix
# --- Section Name ---------------------------------------------------------
```

**Rust files:**
```rust
// --- Section Name --------------------------------------------------------
```

## Formatting Requirements

- **Preserve existing formatting** - Match indentation, spacing, and alignment patterns
- **Use established section dividers** - Follow the `# ---` or `// ---` patterns shown above
- **Maintain header consistency** - Always include complete headers in new files
- **Respect line length** - Follow existing line length conventions in each file
- **Match comment styles** - Use the same comment formatting as surrounding code

## Quality Gates

### Before Committing
- [ ] Standard file headers are present and correct
- [ ] Section dividers follow established patterns
- [ ] Code formatting matches existing style