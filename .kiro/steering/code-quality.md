---
inclusion: always
---

# Code Quality & Minimalism Guidelines

## Core Philosophy: Sophisticated Minimalism

Maintain a "less-is-more" mentality. Quality over quantity with zero tolerance for unused functionality or over-engineering.

## Pre-Implementation Analysis

### Before Creating New Code
1. **Read existing files completely** - Scan from top to bottom to understand current functionality
2. **Search for similar patterns** - Use grep/search to find existing implementations
3. **Identify refactor opportunities** - Improve existing code rather than duplicating functionality
4. **Choose direct solutions** - Implement the minimal necessary change, not grand architectures

### File Size & Proliferation Controls
- **300 LOC maximum** per file (as defined in tech.md)
- **Consolidate related functionality** into existing modules
- **Refactor before expanding** - Clean up existing code before adding new features
- **Delete unused code** immediately upon discovery

## Implementation Standards

### Integration Requirements
- **Immediate integration mandatory** - Never create isolated functionality
- **Establish connections** during implementation, not after
- **Test integration points** to prevent dead code islands
- **Update imports/exports** as part of the same change

### Refactoring Guidelines
- **Respect existing patterns** - Follow established import paths and integration styles
- **Analyze dependencies** - Understand downstream impacts before changes
- **Maintain compatibility** - Preserve existing function signatures when possible
- **Update documentation** inline with code changes

### Change Impact Assessment
- **Map function connections** before modifying shared utilities
- **Verify import chains** remain intact after refactoring
- **Test integration points** affected by changes
- **Consider platform-specific impacts** (Darwin vs NixOS vs containers)

## Quality Gates

### Before Committing
- [ ] No duplicate functionality exists
- [ ] New code is immediately integrated and used
- [ ] File size remains under limits
- [ ] Existing patterns are followed
- [ ] All imports/exports are updated
- [ ] No dead code remains
