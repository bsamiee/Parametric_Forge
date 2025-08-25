# Nomad Features Analysis - Missing in Our Tree Widget

## Overview
This document compares features from the [nomad](https://github.com/JosephLai241/nomad) TUI file manager with our current `tree.rs` implementation, identifying missing features that could enhance our widget system.

## Current Implementation Status

### ✅ Features We Already Have
1. **Tree Structure Rendering**
   - Hierarchical display with expand/collapse
   - Indentation control
   - Custom expand/collapse symbols

2. **Git Integration**
   - Git status markers ('M', 'A', 'D', '?')
   - Color-coded git status display
   - Git status caching with background updates

3. **File Metadata**
   - File icons (NerdFont support)
   - Symlink detection
   - File size tracking

4. **Navigation**
   - Arrow key navigation (Up/Down/Left/Right)
   - Vim key support (h/j/k/l)
   - Page navigation (PageUp/PageDown/Home/End)
   - Parent navigation

5. **Filtering**
   - Pattern-based filtering
   - Filter applies to directories and descendants

6. **State Management**
   - Expand/collapse state persistence
   - Selection tracking
   - Focus management

7. **Performance Optimizations**
   - Flat item caching
   - State hash-based cache invalidation
   - Render tracking to avoid unnecessary redraws

## ❌ Missing Features from Nomad

### 1. **Interactive File Operations**
- [ ] **File Preview Integration**
  - `bat` integration for syntax-highlighted file preview
  - Quick preview in inspect widget
  - Scrollable content preview

- [ ] **File Editing**
  - Launch preferred text editor
  - Support for multiple editors (Neovim, Vim, Vi, Nano)
  - Return to TUI after editing

- [ ] **File Selection System**
  - Label items for batch operations
  - Multi-select capability
  - Visual selection indicators

### 2. **Advanced Git Operations**
- [ ] **Git Commands**
  - `git add` selected files
  - `git blame` view with author coloring
  - `git diff` visualization
  - `git commit` interface
  - `git branch` display
  - `git status` tree mode

- [ ] **Git Visualization**
  - Author-based coloring for blame
  - Diff highlighting
  - Branch indicators

### 3. **Search and Pattern Matching**
- [ ] **Regex Search**
  - Full regex pattern support
  - Search within file contents
  - Highlight matches

- [ ] **Glob Patterns**
  - Include/exclude by glob patterns
  - Multiple pattern support

- [ ] **Smart Filtering**
  - Filetype-based filtering
  - Size-based filtering
  - Date-based filtering

### 4. **UI Enhancements**
- [ ] **Breadcrumb Navigation**
  - Interactive path breadcrumbs
  - Click/select to navigate
  - Visual path representation

- [ ] **Split View Support**
  - Inspect widget for file contents
  - Side-by-side tree and preview
  - Resizable panes

- [ ] **Help System**
  - Context-aware help
  - Keybinding display
  - Interactive help mode

- [ ] **Popup Interactions**
  - Error message popups
  - Confirmation dialogs
  - Input prompts for operations

### 5. **File Information Display**
- [ ] **Lines of Code Integration**
  - Tokei integration for code statistics
  - Display LoC for files and directories
  - Language detection

- [ ] **Extended Metadata**
  - File permissions display
  - Creation/modification dates
  - Owner/group information

- [ ] **File Type Detection**
  - MIME type detection
  - Binary vs text detection
  - Executable status

### 6. **Customization Features**
- [ ] **Theme System**
  - Customizable color schemes
  - Per-filetype colors
  - Git status color customization
  - Border style customization

- [ ] **Display Options**
  - Toggle hidden files
  - Sort options (name, size, date, type)
  - Tree line style customization
  - Icon set selection

- [ ] **Configuration Management**
  - Save/load configurations
  - Config file editing interface
  - Preview configuration changes

### 7. **Performance Features**
- [ ] **Lazy Loading**
  - Load directories on-demand
  - Virtual scrolling for large trees
  - Progressive rendering

- [ ] **Async Operations**
  - Background directory scanning
  - Non-blocking file operations
  - Progress indicators for long operations

### 8. **Keyboard Shortcuts**
- [ ] **Extended Navigation**
  - Jump to first/last sibling
  - Navigate to parent directory
  - Quick jump by typing filename

- [ ] **Action Shortcuts**
  - Copy path to clipboard
  - Open in external application
  - Create new file/directory
  - Rename items
  - Delete with confirmation

### 9. **Integration Features**
- [ ] **Respect Ignore Files**
  - .gitignore support (partially done)
  - .ignore file support
  - Custom ignore patterns

- [ ] **External Tool Integration**
  - ripgrep for searching
  - fd for finding files
  - External diff tools

## Implementation Priority

### High Priority (Core Functionality)
1. File preview integration
2. Multi-select capability
3. Breadcrumb navigation
4. Extended keyboard shortcuts
5. Sort options

### Medium Priority (Enhanced UX)
1. Help system
2. Popup interactions
3. Theme customization
4. Search improvements
5. Split view support

### Low Priority (Nice to Have)
1. Tokei integration
2. Extended git operations
3. External tool integrations
4. Virtual scrolling
5. Config management UI

## Architecture Considerations

### Feature Module Structure
```
features/
├── preview.rs       # File preview functionality
├── selection.rs     # Multi-select and labeling
├── search.rs        # Advanced search/filter
├── file_ops.rs      # File operations (edit, create, delete)
├── git_ops.rs       # Extended git operations
├── shortcuts.rs     # Keyboard shortcut management
├── themes.rs        # Theme and customization
└── mod.rs          # Feature module coordination
```

### Integration Points
1. **Component Level**: Features should be mixins that any widget can adopt
2. **State Management**: Extend existing state with feature-specific data
3. **Event Handling**: Chain feature event handlers with existing handlers
4. **Rendering**: Layer feature rendering on top of base widget rendering

## Next Steps
1. Create feature module structure
2. Implement trait-based feature system
3. Start with high-priority features
4. Create universal feature application system
5. Document feature APIs for widget developers