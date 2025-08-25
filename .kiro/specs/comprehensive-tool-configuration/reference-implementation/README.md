# NET-NEW Reference Implementation Deployment Guide

This directory contains a CLEANED reference implementation focusing ONLY on tools and configurations not already present in the actual Parametric Forge system. After comprehensive audit against the actual project (01.home/), this reference implementation provides genuine net-new value without duplication.

## Purpose

This reference implementation serves as:
- **NET-NEW Template**: Example configurations for unconfigured tools only
- **Gap Filler**: Addresses missing configurations identified in audit
- **Validated Patterns**: Demonstrates framework patterns for new tools
- **Migration Guide**: Step-by-step example for implementing missing configurations

## Audit Results Summary

**REMOVED (Already in actual project)**:
- All package files (100% duplication)
- Most environment variables (80% duplication)
- Existing program configurations (git-tools.nix, shell-tools.nix, ssh.nix, zsh.nix)
- Existing config file deployments (wezterm, starship, git configs, language servers, formatters)

**RETAINED (Net-new value)**:
- 30 tool configurations not in actual project
- Tool-specific environment variables for unconfigured tools
- Static configuration files for unconfigured tools
- Program configurations for unconfigured tools

## NET-NEW Structure Overview

```
reference-implementation/
├── 00.core/                    # NET-NEW core configurations only
│   ├── programs/              # Programs for unconfigured tools only
│   │   ├── default.nix       # Updated imports (removed duplicates)
│   │   ├── essential-tools.nix    # broot, mcfly
│   │   ├── development-workflow.nix # just, pre-commit, hyperfine, tokei
│   │   ├── system-monitoring.nix  # procs, bottom
│   │   ├── network-tools.nix      # xh, doggo, gping
│   │   ├── file-managers.nix      # yazi, lf
│   │   └── [other NET-NEW programs]
│   └── configs/              # Static configs for unconfigured tools only
│       ├── development/      # just, jq, hyperfine configs
│       ├── system/          # procs, bottom, duf, dust configs
│       ├── network/         # xh, doggo, gping configs
│       └── [other NET-NEW configs]
├── darwin/                   # macOS-specific NET-NEW configurations
├── nixos/                    # Linux-specific NET-NEW configurations
├── environment.nix           # NET-NEW environment variables only
├── file-management.nix       # NET-NEW file deployments only
└── default.nix              # Main module integration
```

## Audit and Cleanup Status

- [x] Removed duplicate package files (100% duplication)
- [x] Cleaned environment.nix (removed 80% duplicate variables)
- [x] Cleaned file-management.nix (removed duplicate deployments)
- [x] Removed duplicate program files (git-tools, shell-tools, ssh, zsh)
- [x] Updated documentation to reflect net-new focus
- [x] Created comprehensive audit report
- [x] Validated remaining configurations provide genuine value

## Deployment Instructions

### Prerequisites

Before deploying any configurations from this reference implementation:

1. **Backup Current Configuration**
   ```bash
   # Create timestamped backup
   cp -r 01.home/00.core 01.home/00.core.backup.$(date +%Y%m%d_%H%M%S)
   cp 01.home/environment.nix 01.home/environment.nix.backup.$(date +%Y%m%d_%H%M%S)
   cp 01.home/file-management.nix 01.home/file-management.nix.backup.$(date +%Y%m%d_%H%M%S)
   ```

2. **Verify System Compatibility**
   ```bash
   # Check Nix version
   nix --version
   
   # Verify home-manager availability
   home-manager --version
   
   # Check platform detection
   uname -s  # Should show Darwin or Linux
   ```

3. **Review Current Configuration**
   ```bash
   # Check current configuration builds
   nix flake check
   
   # Review current packages
   home-manager packages | head -20
   ```

### Phase 1: Environment Variables Integration

**Step 1: Review Environment Variables**
```bash
# Compare current environment.nix with reference implementation
diff 01.home/environment.nix .kiro/specs/comprehensive-tool-configuration/reference-implementation/environment.nix
```

**Step 2: Selective Integration**
```bash
# Copy specific sections from reference environment.nix
# DO NOT replace entire file - integrate incrementally
# Focus on XDG compliance improvements first
```

**Step 3: Validation**
```bash
# Test environment variable changes
nix flake check
home-manager switch --flake . --dry-run
```

### Phase 2: Package Integration

**Step 1: Review Package Additions**
```bash
# Compare package files with reference implementation
for pkg_file in core dev-tools devops python-tools rust-tools; do
    echo "=== Comparing $pkg_file.nix ==="
    diff 01.home/01.packages/$pkg_file.nix .kiro/specs/comprehensive-tool-configuration/reference-implementation/packages/$pkg_file.nix
done
```

**Step 2: Add New Packages Incrementally**
```bash
# Add 5-10 packages at a time to avoid overwhelming the system
# Start with low-risk tools (utilities, formatters, analyzers)
# Test each batch before proceeding
```

**Step 3: Validation**
```bash
# Build and test package additions
nix build .#homeConfigurations.default.activationPackage
home-manager switch --flake . --dry-run
```

### Phase 3: Programs Configuration Integration

**Step 1: Review Programs Structure**
```bash
# Compare programs directory structure
ls -la 01.home/00.core/programs/
ls -la .kiro/specs/comprehensive-tool-configuration/reference-implementation/00.core/programs/
```

**Step 2: Integrate Programs Incrementally**

**High-Priority Tools (Week 1)**
```bash
# Start with essential daily tools
# Copy and uncomment configurations for:
# - broot (file explorer)
# - just (task runner) 
# - jq (JSON processor)
# - procs (process viewer)
# - bottom (system monitor)
```

**Medium-Priority Tools (Week 2)**
```bash
# Add system and development tools:
# - mcfly (shell history)
# - hyperfine (benchmarking)
# - tokei (code statistics)
# - vivid (LS_COLORS)
# - rsync (file sync)
```

**Specialized Tools (Week 3-4)**
```bash
# Add remaining tools based on usage:
# - Container tools (docker, colima)
# - Language tools (rustup, bacon)
# - File managers (yazi, lf)
# - Network tools (xh, doggo, gping)
```

**Step 3: Update Programs Default Import**
```bash
# Update 01.home/00.core/programs/default.nix to import new program files
# Follow the pattern in reference-implementation/00.core/programs/default.nix
```

### Phase 4: Static Configuration Integration

**Step 1: Review Config Structure**
```bash
# Compare configs directory structure
find 01.home/00.core/configs -type d
find .kiro/specs/comprehensive-tool-configuration/reference-implementation/00.core/configs -type d
```

**Step 2: Integrate Static Configs by Category**

**Development Tools**
```bash
# Copy configuration files for:
# - just/ (task runner configs)
# - jq/ (JSON processor configs)
# - development/ (various dev tool configs)
```

**System Tools**
```bash
# Copy configuration files for:
# - system/ (procs, bottom, duf, dust configs)
# - network/ (xh, doggo, gping configs)
# - file-ops/ (rsync, ouch configs)
```

**Specialized Tools**
```bash
# Copy configuration files for:
# - containers/ (docker, colima configs)
# - languages/ (rust, bacon configs)
# - file-managers/ (yazi, lf configs)
```

### Phase 5: File Management Integration

**Step 1: Review File Management Changes**
```bash
# Compare file-management.nix files
diff 01.home/file-management.nix .kiro/specs/comprehensive-tool-configuration/reference-implementation/file-management.nix
```

**Step 2: Integrate File Deployments**
```bash
# Add file deployment entries for new static configs
# Follow XDG compliance patterns from reference implementation
# Test each deployment category separately
```

### Phase 6: Platform-Specific Integration

**Step 1: Darwin-Specific (macOS)**
```bash
# If on macOS, review Darwin-specific configurations
ls -la .kiro/specs/comprehensive-tool-configuration/reference-implementation/darwin/
ls -la .kiro/specs/comprehensive-tool-configuration/reference-implementation/configs/darwin/
```

**Step 2: NixOS-Specific (Linux)**
```bash
# If on Linux, review NixOS-specific configurations  
ls -la .kiro/specs/comprehensive-tool-configuration/reference-implementation/nixos/
ls -la .kiro/specs/comprehensive-tool-configuration/reference-implementation/configs/nixos/
```

## Migration Strategy

### Incremental Deployment Approach

**Week 1: Foundation**
- Environment variables (XDG compliance)
- Essential packages (5-10 tools)
- Basic programs configuration
- Core static configs

**Week 2: Development Tools**
- Development workflow packages
- Development programs configuration
- Development static configs
- Shell enhancements

**Week 3: System Tools**
- System monitoring packages
- System programs configuration
- System static configs
- Network tools

**Week 4: Specialized Tools**
- Container and DevOps tools
- Language-specific tools
- Advanced configurations
- Platform-specific configs

### Validation Procedures

**After Each Phase**
```bash
# 1. Verify configuration builds
nix flake check

# 2. Test configuration application
home-manager switch --flake . --dry-run

# 3. Apply configuration
home-manager switch --flake .

# 4. Test tool functionality
# Run basic commands for newly configured tools

# 5. Performance check
time zsh -i -c exit  # Should be <2 seconds

# 6. Rollback if issues
home-manager rollback  # If problems occur
```

**Weekly Comprehensive Testing**
```bash
# 1. Full system test
nix flake check
home-manager switch --flake .

# 2. Tool health check
# Test all configured tools for basic functionality

# 3. Performance assessment
# Measure shell startup time and resource usage

# 4. Integration testing
# Test tool interactions and workflows
```

## Rollback Procedures

### Immediate Rollback
```bash
# Quick rollback to previous generation
home-manager rollback
```

### Configuration-Level Rollback
```bash
# Restore from backup
cp -r 01.home/00.core.backup.YYYYMMDD_HHMMSS 01.home/00.core
cp 01.home/environment.nix.backup.YYYYMMDD_HHMMSS 01.home/environment.nix
cp 01.home/file-management.nix.backup.YYYYMMDD_HHMMSS 01.home/file-management.nix

# Rebuild configuration
home-manager switch --flake .
```

### Selective Rollback
```bash
# Remove specific tool configurations
# Comment out problematic tools in programs/ files
# Remove problematic static configs
# Rebuild and test
```

## Testing Recommendations

### Pre-Deployment Testing
1. **Syntax Validation**: `nix flake check`
2. **Build Testing**: `nix build .#homeConfigurations.default.activationPackage`
3. **Dry Run**: `home-manager switch --flake . --dry-run`

### Post-Deployment Testing
1. **Tool Availability**: Verify all tools are in PATH
2. **Configuration Loading**: Test tool-specific configurations
3. **XDG Compliance**: Verify tools use XDG directories
4. **Performance Impact**: Measure shell startup time
5. **Integration Testing**: Test tool interactions

### Ongoing Monitoring
1. **Daily Health Checks**: Automated tool availability checks
2. **Weekly Performance Reviews**: Monitor system performance
3. **Monthly Configuration Audits**: Review configuration accuracy
4. **Quarterly Comprehensive Reviews**: Full system assessment

## Documentation References

### Framework Documentation
- **Program Templates**: `docs/program-templates.md`
- **Config Templates**: `docs/config-templates.md`
- **Environment Framework**: `docs/environment-framework.md`
- **File Management Framework**: `docs/file-management-framework.md`

### Implementation Guides
- **Implementation Roadmap**: `implementation-docs/integration-guides/implementation-roadmap.md`
- **Maintenance Guide**: `implementation-docs/integration-guides/maintenance-guide.md`
- **Platform-Specific Guides**: `implementation-docs/platform-specific/`

### Research Documentation
- **Tool Research**: `docs/*-tools-research.md`
- **Configuration Examples**: `docs/config-examples/`
- **Program Examples**: `docs/program-examples/`

## Support and Troubleshooting

### Common Issues

**Configuration Build Failures**
- Check Nix syntax with `nix-instantiate --parse file.nix`
- Verify import paths and attribute references
- Review error messages for missing dependencies

**Tool Integration Problems**
- Verify environment variables are set correctly
- Check file deployment with `ls -la ~/.config/tool-name/`
- Test XDG compliance with tool-specific commands

**Performance Issues**
- Profile shell startup with `time zsh -i -c exit`
- Monitor resource usage with `top` or `htop`
- Optimize or defer expensive operations

### Getting Help

1. **Review Documentation**: Check relevant framework and implementation docs
2. **Check Tool Documentation**: Consult official tool documentation
3. **Test in Isolation**: Test problematic tools in clean environment
4. **Incremental Debugging**: Remove configurations until issue is isolated
5. **Community Resources**: Consult Nix/home-manager community resources

## Success Criteria

### Deployment Success Indicators
- [ ] All configurations build without errors
- [ ] All tools are available and functional
- [ ] XDG compliance achieved for supported tools
- [ ] Shell startup time remains under 2 seconds
- [ ] No configuration-related system issues
- [ ] User workflow improvements are measurable

### Long-term Success Metrics
- **Configuration Coverage**: 100% of desired tools configured
- **System Stability**: No configuration-related issues
- **Performance**: Minimal impact on system performance
- **Maintainability**: Easy to add new tools and update configurations
- **User Satisfaction**: Improved development workflow efficiency

This deployment guide provides comprehensive instructions for safely and effectively integrating the reference implementation into your live Parametric Forge system.