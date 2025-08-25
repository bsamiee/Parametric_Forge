---
inclusion: always
---

# Spec Research Requirements

## Pre-Spec Research Mandate

Before creating any spec in specialized environments, conduct thorough research to ensure high-quality, well-informed specifications.

## Specialized Environment Detection

### Interface Development (interface/ folder)

- **Primary Stack**: ratatui + crossterm for TUI applications
- **Language**: Rust
- **Architecture**: Component-based UI with state management

### Nix Ecosystem Development (main project)

- **Primary Stack**: Nix flakes, nix-darwin, home-manager, NixOS
- **Language**: Nix expression language
- **Architecture**: Declarative configuration management with flake-parts modular organization

### Research Protocol for Specialized Environments

#### 1. Official Documentation Research

- **Read official docs thoroughly** - Start with getting started guides, architecture overviews
- **Understand core concepts** - Key abstractions, design patterns, best practices
- **Study API references** - Available components, methods, configuration options
- **Review examples** - Official examples and tutorials

#### 2. Advanced Implementation Research

- **Find exemplary projects** - Search for well-regarded projects using the same stack
- **Analyze architecture patterns** - How do advanced projects structure their code?
- **Study integration approaches** - How do they handle state, events, rendering?
- **Identify common pitfalls** - What mistakes do projects commonly make?

#### 3. Best Practices Research

- **Performance considerations** - Rendering optimization, memory management
- **Testing strategies** - How to test TUI applications effectively
- **Error handling patterns** - Robust error handling in the specific environment
- **Accessibility** - Platform-specific accessibility requirements

### Research Protocol for Nix Ecosystem

#### 1. Official Documentation Research

- **Nix Manual** - Read current Nix package manager documentation, language reference
- **NixOS Manual** - Study module system, configuration options, service management
- **nix-darwin Documentation** - Review macOS-specific configuration patterns and limitations
- **home-manager Manual** - Understand user-level configuration, available options, platform differences
- **Nixpkgs Manual** - Package creation, overlays, cross-compilation, contribution guidelines

#### 2. Advanced Implementation Research

- **Exemplary flake projects** - Study well-structured flakes with similar complexity
- **Community configurations** - Analyze popular dotfiles and system configurations
- **Enterprise patterns** - Look for large-scale Nix deployments and their architectural decisions
- **Platform-specific examples** - Find projects handling Darwin/NixOS/container abstractions

#### 3. Current Standards Research

- **Flake best practices** - Modern flake structure, input management, reproducibility
- **Module patterns** - Current approaches to reusable, composable modules
- **Performance optimization** - Build caching, evaluation efficiency, dependency management
- **Security considerations** - Trusted substituters, input validation, sandboxing

## Research Documentation Requirements

### In Spec Requirements Phase

- **Document research findings** - Summarize key insights that inform requirements
- **Reference authoritative sources** - Link to official docs, exemplary projects
- **Justify design decisions** - Explain why certain approaches were chosen
- **Note constraints** - Technical limitations or platform-specific considerations

### Research Quality Standards

- **Multiple authoritative sources** - Don't rely on single sources
- **Current information** - Ensure documentation and examples are up-to-date
- **Practical validation** - Verify approaches work with current versions
- **Community consensus** - Look for widely-adopted patterns

## Environment-Specific Research Areas

### For ratatui/crossterm (interface/)

- **Widget composition patterns** - How to build complex UIs from simple components
- **State management** - Event handling, application state, component communication
- **Terminal compatibility** - Cross-platform terminal behavior differences
- **Performance optimization** - Efficient rendering, minimal redraws
- **Testing approaches** - Unit testing components, integration testing

### For Nix Ecosystem Development (main project)

- **Nix package manager** - Current syntax, best practices, performance considerations
- **NixOS configuration** - Module system, services, system-level configuration patterns
- **nix-darwin specifics** - macOS system configuration, service management, homebrew integration
- **home-manager patterns** - User-level configuration, dotfile management, cross-platform compatibility
- **Flake architecture** - Input management, output structure, flake-parts organization
- **Module composition** - Reusable modules, configuration layering, platform abstraction
- **Package management** - Custom packages, overlays, version pinning, dependency management

## Quality Gates for Spec Creation

### Before Writing Requirements

- [ ] Official documentation reviewed and understood
- [ ] 2-3 exemplary projects analyzed for patterns
- [ ] Key technical constraints identified
- [ ] Best practices documented
- [ ] Research findings summarized in spec context

### During Requirements Writing

- [ ] Requirements reflect researched best practices
- [ ] Technical constraints are properly addressed
- [ ] Implementation approach aligns with community standards
- [ ] Edge cases from research are considered

## Nix Ecosystem Research Standards

### Required Documentation Sources

- **Official Nix Manual** - https://nixos.org/manual/nix/stable/
- **NixOS Manual** - https://nixos.org/manual/nixos/stable/
- **nix-darwin Documentation** - Current GitHub repository and wiki
- **home-manager Manual** - Current release documentation
- **Nixpkgs Manual** - https://nixos.org/manual/nixpkgs/stable/

### Community Reference Projects

- **Search for exemplary flakes** - GitHub topics: nix-flakes, nixos-config, nix-darwin
- **Study configuration patterns** - Look for projects with similar scope and complexity
- **Analyze module organization** - How do successful projects structure reusable components
- **Review platform abstraction** - Projects handling multiple platforms (Darwin/NixOS/containers)

### Version Compatibility Research

- **Check current stable versions** - Ensure compatibility with latest stable releases
- **Review breaking changes** - Study recent release notes for API changes
- **Validate deprecated features** - Identify and avoid deprecated syntax or patterns
- **Test with unstable** - Verify compatibility with nixpkgs-unstable when used

### Quality Gates for Nix Specs

#### Before Writing Requirements

- [ ] Current Nix/NixOS/nix-darwin/home-manager documentation reviewed
- [ ] 2-3 exemplary flake projects analyzed for architectural patterns
- [ ] Version compatibility verified for all components
- [ ] Platform-specific constraints documented
- [ ] Performance and security considerations researched

#### During Requirements Writing

- [ ] Requirements use current Nix syntax and patterns
- [ ] Platform abstraction needs are properly addressed
- [ ] Module composition strategy aligns with best practices
- [ ] Build performance implications are considered
- [ ] Security and reproducibility requirements are included
