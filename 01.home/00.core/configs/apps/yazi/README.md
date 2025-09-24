# Yazi Terminal File Manager • Technical Manual

## Overview

This configuration transforms Yazi into a powerful file management hub with deep WezTerm integration, advanced plugins, and workflow optimizations. The setup emphasizes keyboard-driven efficiency while maintaining discoverability through visual cues and command palettes.

## Architecture

### Core Components

```
yazi/
├── init.lua           # Plugin initialization & safety wrappers
├── keymap.toml        # Keybinding extensions (prepend pattern)
├── package.toml       # Plugin dependency management
├── theme.toml         # Dracula theme with custom icons
├── yazi.toml          # Core behavior configuration
└── plugins/
    ├── smart-switch.yazi/   # Tab creation on demand
    └── smart-tab.yazi/      # Directory-aware tab creation
```

### Integration Points

- **WezTerm**: Bidirectional workspace synchronization via `wezterm-utils.sh`
- **Yabai**: Window manager coordination for workspace/space alignment
- **System Clipboard**: Automatic synchronization of yanks/cuts
- **macOS**: Native Quick Look preview, Finder reveal, tag support
- **Git**: Inline status display, lazygit integration

## Essential Keybindings

### Navigation & Movement

| Key | Action | Description |
|-----|--------|-------------|
| `h` | Smart leave | Skip single-child parent directories |
| `l` | Smart enter | Skip single-child subdirectories |
| `j/k` | Move down/up | Standard navigation |
| `gg/G` | Jump to top/bottom | File list boundaries |
| `J` | EasyJump | Fuzzy search jump to any file |
| `H` | Directory history | Navigate through visited paths |
| `gp` | Project switcher | Jump to saved project directories |
| `gf` | Git files filter | Show only git-tracked files |

### Tab Management

| Key | Action | Description |
|-----|--------|-------------|
| `t` | Smart tab | Create tab and enter if directory |
| `1-9` | Tab switch | Smart switch (creates if doesn't exist) |
| `Tab` | Next tab | Cycle forward through tabs |
| `Shift+Tab` | Previous tab | Cycle backward through tabs |
| `<A-w>` | Close tab | Option+W shortcut |
| `Q` | Close tab | Remove current tab |

### File Operations

| Key | Action | Description |
|-----|--------|-------------|
| `<space>` | Toggle selection | Mark/unmark files |
| `v` | Select all | Mark all items in view |
| `V` | Inverse selection | Flip selection state |
| `<C-c>` | Copy | Yank to clipboard (synced) |
| `<C-x>` | Cut | Cut to clipboard (synced) |
| `<C-v>` | Paste | Paste from clipboard |
| `p` | Smart paste | Paste to hovered directory |
| `dd` | Trash | Move to recycle bin (recoverable) |
| `D` | Delete | Permanent deletion (use with caution) |
| `r` | Rename | Edit selected file names |
| `a` | Create file | New file in current directory |
| `A` | Create directory | New folder in current directory |

### Archive Operations

| Key | Action | Description |
|-----|--------|-------------|
| `ox` | Extract | Extract with 7zz (full paths) |
| `oc` | Compress | Create archive from selection |

### Git Integration

| Key | Action | Description |
|-----|--------|-------------|
| `gg` | Lazygit | Open lazygit in current directory |
| `gd` | Diff | Compare selected with hovered file |

### WezTerm Integration

| Key | Action | Description |
|-----|--------|-------------|
| `<C-n>` / `<C-g> n` | New workspace | Create WezTerm workspace for current directory |
| `<C-t>` | Terminal shell | Drop to interactive shell |

### Trash Management

| Key | Action | Description |
|-----|--------|-------------|
| `gt` | Go to trash | Navigate to trash directory |
| `u` | Undo delete | Restore most recently deleted |
| `Rr` | Restore selected | Restore files from trash |
| `Rd` | Delete from trash | Permanent deletion |
| `Re` | Empty trash | Clear entire recycle bin |
| `RD` | Empty old trash | Delete items older than N days |

### macOS Tags

| Key | Action | Description |
|-----|--------|-------------|
| `Ta` | Add tags | Color tags for organization |
| `Tr` | Remove tags | Clear tags from files |

**Tag Colors**: Red (r), Orange (o), Yellow (y), Green (g), Blue (b), Purple (p)

### Advanced Features

| Key | Action | Description |
|-----|--------|-------------|
| `P` | Toggle panes | Show/hide parent & preview |
| `<C-p>` | Quick Look | macOS preview (images, PDFs, etc) |
| `<A-k>` | Command palette | Searchable command list |
| `/` | Filter | Live filter current directory |
| `f` | Find | Jump to file by character |
| `!` | Shell command | Run command with selection |

### Sudo Operations (Emergency)

| Key | Action | Description |
|-----|--------|-------------|
| `Sr` | Sudo rename | When permission denied |
| `Sp` | Sudo paste | When permission denied |

## Active Plugins

### UI Enhancement

- **starship**: Terminal prompt integration for consistency
- **full-border**: Rounded borders for visual separation
- **git**: Inline git status indicators
- **system-clipboard**: Automatic clipboard synchronization

### Navigation

- **bypass**: Smart directory traversal (skip single-child)
- **easyjump**: Fuzzy file/directory jumping
- **cdhist**: Directory history navigation
- **projects**: Quick access to project directories

### File Management

- **smart-paste**: Context-aware pasting
- **compress**: Archive creation utilities
- **mactag**: macOS file tagging support
- **recycle-bin**: Trash management with recovery
- **restore**: Undo last delete operation

### Productivity

- **lazygit**: Git TUI integration
- **command-palette**: Discoverable command search
- **toggle-pane**: Dynamic pane visibility
- **git-files**: Git-aware file filtering

### Session

- **resurrect** (WezTerm): Workspace state persistence
- **workspace-switcher** (WezTerm): Named workspace management

## Configured Projects

Predefined project shortcuts (access with `gp`):

- **Parametric Forge**: `~/Documents/99.Github/Parametric_Forge`
- **Parametric Arsenal**: `~/Documents/99.Github/Parametric_Arsenal`
- **Github Projects**: `~/Documents/99.Github`
- **Config**: `~/.config`

## WezTerm Integration Details

### Workspace Synchronization

The integration provides bidirectional coordination between Yazi and WezTerm:

1. **Workspace Creation** (`<C-n>`):

   - Creates WezTerm workspace named after current directory
   - Automatically switches to the new workspace (compliments WezTerm’s `Ctrl+w y` when starting from the terminal)
   - Updates yabai space label to match

1. **Workspace Events**:

   - Tab creation inherits workspace context
   - Workspace switches trigger yabai space focus
   - State persistence via resurrect plugin

1. **Helper Script** (`wezterm-utils.sh`):

   - `spawn-workspace`: Create and switch to workspace
   - `switch-workspace`: Change active workspace
   - `space-label`: Update yabai space label
   - `workspace-change`: Internal coordination handler

### Tab Synchronization

Smart tab behaviors enhance the workflow:

- **Smart Tab** (`t`): Creates tab and enters if hovering directory
- **Smart Switch** (`2-9`): Creates missing tabs automatically
- **Tab Persistence**: WezTerm saves tab state every 15 minutes

## Visual Theme

### Dracula Color Semantics

- **Purple** (#bd93f9): Active selections, primary interactions
- **Green** (#50fa7b): Success states, development files, normal mode
- **Yellow** (#f1fa8c): Current directory, search highlights, configs
- **Red** (#ff5555): Errors, destructive actions, warnings
- **Cyan** (#8be9fd): Information, secondary actions, data files
- **Pink** (#ff79c6): Special highlights, creative content
- **Orange** (#ffb86c): Archives, copied items
- **Blue** (#6272a4): Subdued elements, alternate screen indicator

### File Type Icons

- **Development**: `.nix` ❄, `.py` , `.rs` , `.js` , `.go`
- **Configs**: `.json`/`.toml`/`.yaml` with purple highlight
- **3D/CAD**: `.3dm` 󰆧, `.gh` 󱁤, `.dwg` 󰻫, `.blend`
- **Creative**: `.psd` , `.ai` , `.indd`
- **Directories**: `.git` , `node_modules` , `.venv`

## Performance Optimizations

### Caching

- Git repository detection: 5-second TTL
- Image preview: 30ms delay (WezTerm optimized)
- Preview cache: XDG standard location

### Resource Limits

- Image allocation: 512MB
- Max image dimensions: 4096x4096
- Micro workers: 10 (parallel small tasks)
- Macro workers: 10 (parallel large operations)

### Smart Behaviors

- Natural sorting: `1.md < 2.md < 10.md`
- Directory-first listing
- 8-line scroll offset for context
- Mouse support: click, scroll, drag

## Workflows

### Project Navigation

1. **Quick Jump**: `gp` → Select project → Enter
1. **Create Workspace**: Navigate to project → `<C-n>` → New WezTerm workspace
1. **Git Operations**: `gg` for lazygit or `gd` for quick diffs

### File Management

1. **Bulk Operations**: Select with `<space>` → Operation → Smart paste with `p`
1. **Archive Workflow**: Select files → `oc` to compress → `ox` to extract
1. **Trash Safety**: `dd` to trash → `u` to undo → `gt` to review

### Tab Workflows

1. **Multi-Project**: `1-9` creates tabs on demand for different projects
1. **Directory Exploration**: `t` on directories for quick branching
1. **Reference Tab**: Keep one tab at project root, others for exploration

### Terminal Integration

1. **Quick Commands**: `!` for one-off commands with selection
1. **Shell Drop**: `<C-t>` for extended terminal work
1. **Process Launch**: Configure openers in `yazi.toml` for file types

## Troubleshooting

### Common Issues

**Clipboard not syncing**: Ensure `system-clipboard` plugin is loaded in init.lua

**WezTerm workspace not creating**: Check `WEZTERM_UTILS_BIN` environment variable

**Git status not showing**: Verify git is accessible in PATH

**Trash operations failing**: Install `trash-cli` via homebrew

**macOS tags not working**: Install `tag` via `brew install tag`

### Plugin Management

Update plugins:

```bash
ya pack -i  # Install/update from package.toml
ya pack -l  # List installed plugins
```

### Debug Mode

Enable verbose logging:

```bash
YAZI_LOG=debug yazi
```

Check logs at: `~/.local/state/yazi/yazi.log`

## Best Practices

### Organization

- Use projects (`gp`) for frequent directories
- Leverage smart navigation (`h`/`l`) to skip redundant directories
- Create workspaces (`<C-n>`) for distinct work contexts

### Safety

- Prefer trash (`dd`) over delete (`D`)
- Use sudo operations (`Sr`, `Sp`) only when necessary
- Review selections before bulk operations

### Efficiency

- Master smart paste (`p`) for hovered directory operations
- Use command palette (`<A-k>`) to discover features
- Combine selections with operations for batch processing

### Integration

- Align WezTerm workspaces with project boundaries
- Use consistent workspace names for resurrect persistence
- Coordinate yabai spaces with active work contexts

## Customization Points

### Adding Projects

Edit init.lua `projects` setup:

```lua
{ name = "My Project", path = "~/path/to/project" }
```

### Custom Keybindings

Add to keymap.toml `prepend_keymap`:

```toml
{ on = "KEY", run = "COMMAND", desc = "Description" }
```

### File Type Associations

Modify yazi.toml `[opener]` section for application preferences

### Theme Adjustments

Edit theme.toml color values while maintaining semantic consistency

## Dependencies

### Required

- **7zz**: Archive extraction (`brew install sevenzip`)
- **trash-cli**: Recycle bin support (`brew install trash-cli`)
- **git**: Version control integration

### Optional

- **tag**: macOS file tagging (`brew install tag`)
- **lazygit**: Git TUI (`brew install lazygit`)
- **wezterm**: Terminal multiplexer integration
- **yabai**: Window manager coordination

## Summary

This Yazi configuration creates a comprehensive file management system that:

- **Integrates** deeply with WezTerm workspaces and yabai window management
- **Optimizes** navigation with smart directory traversal and fuzzy jumping
- **Enhances** safety with trash management and undo capabilities
- **Accelerates** workflows with smart pasting and bulk operations
- **Maintains** consistency through theme alignment and persistent state

The setup prioritizes keyboard efficiency while preserving discoverability, making it suitable for both quick file operations and extended project management sessions.
