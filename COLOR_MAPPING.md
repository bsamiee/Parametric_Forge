# Color Mapping - Parametric Forge

Complete inventory of color definitions and their usage across all project configurations.

## Color Palette Foundation

**Dracula Color Scheme** - Primary color system used throughout:

| Color | Hex | Usage Context |
|-------|-----|---------------|
| **Background** | `#282a36` | Dark gray backgrounds, inverted text |
| **Foreground** | `#f8f8f2` | Light gray text, default foreground |
| **Current Line** | `#44475a` | Highlights, selections, borders |
| **Comment** | `#6272a4` | Muted elements, inactive states |
| **Cyan** | `#8be9fd` | Primary accents, directories, technical |
| **Green** | `#50fa7b` | Success, active states, good status |
| **Orange** | `#ffb86c` | Warnings, medium priority |
| **Pink** | `#ff79c6` | Creative files, links, errors |
| **Purple** | `#bd93f9` | Professional tools, active tabs |
| **Red** | `#ff5555` | Critical alerts, errors, deletions |
| **Yellow** | `#f1fa8c` | Cautions, temporary states |

## Application-Specific Color Usage

### SketchyBar (`01.home/00.core/configs/apps/sketchybar/`)

**Primary Colors** (`modules/colors.lua`):

- Background: `0xff282a36` - Bar background
- Foreground: `0xfff8f8f2` - Default text
- Comment: `0xff6272a4` - Inactive elements

**Component States**:

- **Spaces**: Active `0xff8be9fd` (cyan), Inactive `0xff6272a4` (comment)
- **Battery**: Good `0xff50fa7b`, Medium `0xffffb86c`, Low `0xffff5555`
- **CPU**: Good `0xff50fa7b`, Medium `0xfff1fa8c`, High `0xffff5555`
- **Clock**: Icon `colors.purple` (`0xffbd93f9`)
- **Volume**: Icon `colors.orange` (`0xffffb86c`)
- **Front App**: Background `colors.green` (`0xff50fa7b`)

**Ecosystem Context System** (`modules/items/spaces.lua`):

- **Project Type Detection**: Dynamic colors based on codebase type:
  - Nix: `colors.cyan` (`0xff8be9fd`) with snowflake icon
  - Rust: `colors.orange` (`0xffffb86c`)
  - Python: `colors.yellow` (`0xfff1fa8c`)
  - Git: `colors.red` (`0xffff5555`)
  - General: `colors.comment` (`0xff6272a4`)
- **Advanced Transparency**: Bitwise operations for 25% alpha
  - Formula: `(color) & 0x00ffffff | 0x40000000`
  - Removes alpha channel, adds 25% opacity via bitwise OR

**Advanced Interactions** (`modules/core/interactions.lua`):

- **Popup System**: Background `0xff282a36`, Border `0xff6272a4`
- **Hover States**: Background `0xff44475a` (current line)

**Usage**: Intelligent system status bar with context-aware project type detection

### Yazi File Manager (`01.home/00.core/configs/apps/yazi/`)

**Core Interface** (`dracula-flavor.toml`):

- Current directory: `#8be9fd` (cyan, bold) - Primary navigation
- Selection hover: `#282a36` bg, `#bd93f9` fg (inverted purple)
- Search terms: `#282a36` bg, `#f1fa8c` fg (high contrast yellow)

**File Type Colors**:

- **Programming**: Python `#50fa7b`, JavaScript `#f1fa8c`, TypeScript/Nix `#8be9fd`
- **Creative 3D**: Rhino/Grasshopper `#8be9fd` (technical precision)
- **CAD/Architecture**: AutoCAD/Revit `#bd93f9` (professional)
- **Adobe Creative**: Photoshop `#ff79c6`, Illustrator `#bd93f9`, InDesign `#ffb86c`
- **Documents**: PDF `#ff5555`, Markdown `#f8f8f2`

**Directory Icons** (`theme.toml`):

- Git repos: `#ff79c6`, Node modules: `#50fa7b`, Config: `#bd93f9`

**Advanced Lua System** (`init.lua`):

- **Complete Dracula Palette Definition**:
  ```lua
  dracula_colors = {
      background = "#282a36", current_line = "#44475a",
      foreground = "#f8f8f2", comment = "#6272a4",
      cyan = "#8be9fd", green = "#50fa7b", orange = "#ffb86c",
      pink = "#ff79c6", purple = "#bd93f9", red = "#ff5555", yellow = "#f1fa8c"
  }
  ```
- **Git Status Linemode**: Semantic colors for repository status
  - Modified: `#f1fa8c` (yellow) - Changed files
  - Added: `#50fa7b` (green) - Staged files
  - Deleted: `#ff5555` (red) - Removed files
  - Untracked: `#bd93f9` (purple) - New files
- **Plugin Color Systems**:
  - **Simple-tag**: Full Dracula palette mapping for file tagging
    - `*` = `#bd93f9` (purple), `$` = `#50fa7b` (green)
    - `!` = `#ff5555` (red), `@` = `#8be9fd` (cyan)
    - `#` = `#f1fa8c` (yellow), `%` = `#ffb86c` (orange), `&` = `#ff79c6` (pink)
  - **Keyjump**: Navigation key highlighting
    - Icon foreground: `#ff79c6` (pink) - High visibility
    - First key: `#50fa7b` (green) - Primary action
  - **Searchjump**: Smart search visualization
    - Unmatch: `#6272a4` (comment) - Muted non-matches
    - Match highlight: `#282a36` fg, `#f1fa8c` bg - High contrast
    - First match: `#282a36` fg, `#50fa7b` bg - Primary result
    - Labels: `#282a36` fg, `#ff79c6` bg - Action indicators
- **XDG-Compliant Ecosystem Integration**:
  - Path: `$XDG_STATE_HOME/ecosystem/yazi_cwd`
  - Triggers SketchyBar ecosystem context updates on directory changes

### Eza Theme (`01.home/00.core/configs/system/eza/theme.yml`)

**File Types**:

- Normal files: `#f8f8f2`, Directories: `#8be9fd` (bold)
- Executables: `#50fa7b` (bold), Symlinks: `#ff79c6`

**Expanded File Type Colors** (Recent Updates):

- **Media**: Images `#ff79c6`, Videos `#bd93f9`, Music `#8be9fd`
- **Documents**: Text `#f1fa8c`, Compressed `#ffb86c`, Temp `#6272a4` (dimmed)
- **Code**: Source `#50fa7b`, Compiled `#ff5555`, Build `#ffb86c`

**Permissions**:

- Read: `#f1fa8c` (user), `#bd93f9` (group), `#8be9fd` (other)
- Write: `#ff5555` (user), `#bd93f9` (group), `#8be9fd` (other)
- Execute: `#50fa7b` (universal)

**Date Hierarchy** (New Feature):

- Just now: `#50fa7b` (green), Hour old: `#8be9fd` (cyan)
- Day old: `#f1fa8c` (yellow), Week old: `#bd93f9` (purple)
- Older: `#6272a4` (comment, dimmed)

**Git Status**:

- New: `#50fa7b`, Modified: `#f1fa8c`, Deleted: `#ff5555`
- Renamed: `#bd93f9`, Conflicted: `#ff5555` (bold)

**Advanced Features**:

- **Overlays**: ACL `#ffb86c`, Extended attributes `#8be9fd`
- **Broken Links**: `#ff5555` (underlined), Path overlay `#44475a`

### WezTerm Terminal (`01.home/00.core/configs/apps/wezterm.lua`)

**Base Palette**:

```lua
colors = {
    bg = "#282a36", fg = "#f8f8f2",
    red = "#ff5555", green = "#50fa7b", yellow = "#f1fa8c",
    blue = "#6272a4", cyan = "#8be9fd", purple = "#bd93f9",
    orange = "#ffb86c", pink = "#ff79c6"
}
```

**RGBA Transparency System**:

- `invisible = "rgba(0,0,0,0)"` - Fully transparent elements
- `window_bg = "rgba(40, 42, 54, 0.75)"` - Dracula background at 75% opacity

**Tab System**:

- Active tab: `cyan` bg, `#282a36` fg (high contrast)
- Inactive tab: window background, foreground color
- SSH host coding: Prod `red`, Staging `yellow`, Dev `green`

**Mode Indicators**:

- Normal: `green`, Search: `yellow`, Copy: `cyan`, Resize: `orange`

### Bottom System Monitor (`01.home/00.core/configs/system/bottom/bottom.toml`)

**Interface Colors**:

- Headers: `#8be9fd` (cyan), Titles: `#bd93f9` (purple)
- Borders: `#6272a4` (inactive), `#ff79c6` (active)
- Selection: `#44475a` bg, `#282a36` fg

**Performance Graphs**:

- CPU cores: Full Dracula palette rotation (`#ff5555`, `#ffb86c`, `#f1fa8c`, `#50fa7b`, `#8be9fd`, `#bd93f9`, `#ff79c6`)
- Memory: RAM `#ff79c6`, Swap `#ffb86c`, Cache `#bd93f9`
- Network: RX `#50fa7b`, TX `#ff5555`, Totals `#8be9fd`/`#ffb86c`

### Starship Prompt (`01.home/00.core/configs/apps/starship.toml`)

**Dracula Palette Definition**:

```toml
[palettes.dracula]
background = "#282a36"    cyan = "#8be9fd"       red = "#ff5555"
current_line = "#44475a"  green = "#50fa7b"      yellow = "#f1fa8c"
foreground = "#f8f8f2"    orange = "#ffb86c"
comment = "#6272a4"       pink = "#ff79c6"       purple = "#bd93f9"
```

**Module Colors** (Recent Changes):

- Directory: `purple` (bold), Git branch: `pink` (bold)
- Git status: `orange` (bold), Docker: `cyan` (bold)
- Languages: Node `green`, Python `yellow`, Rust `orange`, Go `cyan`
- **Right Format**: Simplified to `cmd_duration` only (time/battery removed)

### Window Borders (`01.home/00.core/configs/apps/borders/bordersrc`)

**Focus States**:

- Active window: `0xffbd93f9` (purple) - Focused attention
- Inactive windows: `0xff6272a4` (comment) - Recessive background

### Bat Syntax Highlighter (`01.home/00.core/configs/system/bat/config`)

**Theme**: `--theme="Dracula"` - Uses built-in Dracula theme for syntax highlighting

### Fastfetch System Info (`01.home/00.core/configs/apps/fastfetch/config.json`)

**Terminal Color Configuration**:

- **Keys**: `"cyan"` - Information labels
- **Title**: `"magenta"` - System hostname/user
- **Separator**: `"90"` - Muted separators (ANSI color code)

**Usage**: System information display with terminal color names matching Dracula palette

### Procs Process Viewer (`01.home/00.core/configs/system/procs/config.toml`)

**Terminal Color System** (using standard color names):

- **Column Colors**:
  - PID: `BrightYellow|Yellow` - Process identifiers
  - User: `BrightGreen|Green` - User names
  - CPU Time: `BrightCyan|Cyan` - Execution time
  - CPU Usage: `BrightMagenta|Magenta` - Performance metrics
  - Memory Usage: `BrightBlue|Blue` - Memory consumption
  - State/Command: `BrightWhite|White` - Process information

**Percentage-Based CPU Colors**:

- 0%: `BrightGreen|Green` - Idle processes
- 25%: `Green|Green` - Low usage
- 50%: `BrightYellow|Yellow` - Medium usage
- 75%: `Yellow|Yellow` - High usage
- 100%: `BrightRed|Red` - Maximum usage

**Process State Colors**:

- Running: `BrightGreen|Green` - Active processes
- Sleeping: `BrightCyan|Cyan` - Waiting processes
- Stopped: `BrightYellow|Yellow` - Suspended processes
- Zombie: `BrightRed|Red` - Dead processes
- Idle: `Magenta|Magenta` - System idle

## Color Usage Patterns

### Semantic Color Coding

**Status Indicators**:

- ✅ Success/Good: `#50fa7b` (green)
- ⚠️ Warning/Medium: `#f1fa8c` (yellow) or `#ffb86c` (orange)
- ❌ Error/Critical: `#ff5555` (red)

**UI Hierarchy**:

- **Primary**: `#8be9fd` (cyan) - Navigation, directories, active states
- **Secondary**: `#bd93f9` (purple) - Professional tools, titles
- **Accent**: `#ff79c6` (pink) - Creative files, highlights
- **Muted**: `#6272a4` (comment) - Inactive, disabled states

**File Type Categories**:

- **Technical/Precision**: `#8be9fd` (cyan) - Nix, TypeScript, 3D modeling
- **Professional/Structural**: `#bd93f9` (purple) - CAD, vector graphics
- **Creative/Artistic**: `#ff79c6` (pink) - Raster graphics, creative 3D
- **Publishing**: `#ffb86c` (orange) - Layout, print documents

### Environment Differentiation

**Development Environments** (WezTerm SSH):

- Production: `#ff5555` (red) - Critical/dangerous
- Staging: `#f1fa8c` (yellow) - Caution required
- Development: `#50fa7b` (green) - Safe environment

## Color Format Reference

### Format Types Used Across Project

| Format | Example | Usage Context |
|--------|---------|---------------|
| **Hex** | `#8be9fd` | Yazi, WezTerm, Starship, Eza, Bottom |
| **32-bit ARGB** | `0xff8be9fd` | SketchyBar (0xff = full opacity) |
| **RGBA** | `rgba(40, 42, 54, 0.75)` | WezTerm transparency |
| **Terminal Names** | `BrightCyan\|Cyan` | Procs process viewer |
| **Bitwise Alpha** | `(color) & 0x00ffffff \| 0x40000000` | SketchyBar (bitwise 25% opacity) |

### Cross-Application Color Validation

**Dracula Cyan (`#8be9fd`) Usage**:

- SketchyBar: `0xff8be9fd` (spaces, accent)
- Yazi: `#8be9fd` (directories, TypeScript, technical files)
- WezTerm: `#8be9fd` (mode indicators, tabs)
- Starship: `cyan = "#8be9fd"` (defined in palette)
- Eza: `#8be9fd` (directories, file sizes)
- Bottom: `#8be9fd` (graphs, network RX)
- Fastfetch: `cyan` (terminal name mapping)

**All hex values verified identical across applications** ✅

### Recent Changes Validation

**SketchyBar Transparency Update**:

- Old: String concatenation `color + "40"`
- New: Bitwise operations `(color) & 0x00ffffff | 0x40000000`
- **Improvement**: More efficient alpha channel manipulation

**Starship Right Format Simplification**:

- Old: `$cmd_duration$time $battery$memory_usage`
- New: `$cmd_duration` only
- **Result**: Cleaner, faster prompt rendering

**Eza Theme Expansion**:

- **Added**: Complete file type color mapping
- **Added**: Date hierarchy coloring system
- **Added**: Advanced overlay and symlink handling

## Implementation Notes

- **Consistency**: All applications use identical hex values for Dracula colors
- **Accessibility**: High contrast maintained with `#282a36` bg + light fg combinations
- **Semantic Logic**: Color meanings preserved across applications (green=good, red=danger, etc.)
- **Format Standardization**: Hex primary, with format-specific variants (ARGB, RGBA, terminal names)
- **Transparency Support**: RGBA and alpha-suffix patterns for transparency effects
- **Plugin Integration**: Comprehensive color systems in Yazi Lua plugins with full Dracula palette
- **Context Awareness**: Intelligent color switching based on project type (SketchyBar ecosystem)
