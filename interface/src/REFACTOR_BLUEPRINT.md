# Refactoring Blueprint: Composable Functionality Architecture

## Executive Summary

This document outlines a comprehensive refactoring strategy to transform our TUI interface from monolithic widget implementations to a composable, behavior-driven architecture. By extracting common functionality into reusable modules, we can eliminate duplication, accelerate feature development, and create a more maintainable codebase.

## Current State Analysis

### Problem: Scattered Functionality

Our codebase currently has functionality distributed across multiple layers without clear separation of concerns:

```
Current Distribution:
- Root level (src/): Domain logic mixed with infrastructure
- widgets/: Duplicated behaviors across 14+ widget files
- widgets/mod.rs: 1000+ LOC of mixed concerns (traits, helpers, macros)
- core/: Appropriate abstractions but tightly coupled
```

### Code Duplication Examples

1. **Navigation Logic**: Repeated in list.rs, table.rs, tree.rs, menu.rs
2. **Focus Management**: Implemented separately in each widget
3. **Scrolling**: Virtual scrolling reimplemented per widget
4. **Input Handling**: Text operations duplicated across input widgets
5. **Validation**: Framework in widgets/validation.rs but not universally used

### Identified Issues

- **Maintenance Burden**: Bug fixes must be applied in multiple places
- **Inconsistent Behavior**: Similar widgets behave differently
- **Feature Addition Complexity**: New features require touching many files
- **Testing Overhead**: Similar logic tested multiple times
- **Code Size**: ~600+ LOC of duplication identified in widgets/mod.rs alone

## Proposed Architecture

### Design Principles

1. **Composition over Inheritance**: Widgets compose behaviors rather than implementing them
2. **Single Responsibility**: Each module has one clear purpose
3. **Universal Features**: Features added once, available everywhere
4. **Testability**: Behaviors testable in isolation
5. **Zero Waste**: No dead code, maximum reuse

### Directory Structure

```
interface/src/
├── core/                 # Core abstractions (KEEP AS-IS)
│   ├── action.rs        # Action command pattern
│   ├── event.rs         # Event dispatch system
│   ├── state.rs         # Central state management
│   └── mod.rs           # Core exports
│
├── functionality/        # NEW: Extracted reusable behaviors
│   ├── mod.rs           # Public API exports
│   │
│   ├── navigation/      # Navigation patterns
│   │   ├── mod.rs
│   │   ├── cursor.rs    # Cursor movement (char/word/line)
│   │   ├── selection.rs # Single/multi selection management
│   │   ├── scrolling.rs # Viewport & virtual scrolling
│   │   └── focus.rs     # Focus chain management
│   │
│   ├── input/           # Input handling
│   │   ├── mod.rs
│   │   ├── text.rs      # Text operations (insert/delete/replace)
│   │   ├── clipboard.rs # Yank/paste operations
│   │   ├── history.rs   # Undo/redo system
│   │   ├── validation.rs # Validation framework (moved)
│   │   └── masking.rs   # Input masking (password, format)
│   │
│   ├── visual/          # Visual capabilities
│   │   ├── mod.rs
│   │   ├── theming.rs   # Theme application & management
│   │   ├── borders.rs   # Border rendering & styles
│   │   ├── icons.rs     # Nerd Font icon integration
│   │   ├── animations.rs # Transition effects
│   │   └── indicators.rs # Loading, progress, status
│   │
│   ├── layout/          # Layout behaviors
│   │   ├── mod.rs
│   │   ├── responsive.rs # Responsive design helpers
│   │   ├── constraints.rs # Constraint calculations
│   │   └── positioning.rs # Positioning strategies
│   │
│   └── domain/          # Business/domain logic
│       ├── mod.rs
│       ├── git.rs       # Git operations (moved from root)
│       ├── nix.rs       # Nix operations (moved from root)
│       ├── persistence.rs # State persistence (moved from root)
│       ├── system.rs    # System utilities (moved from root)
│       └── config.rs    # Configuration (moved from root)
│
├── features/            # Feature gap documentation (KEEP)
│   └── *.md            # Feature comparison documents
│
├── widgets/             # Widget implementations (REFACTORED)
│   ├── mod.rs          # Widget infrastructure only
│   └── *.rs            # Individual widgets using functionality/
│
├── components/          # Component infrastructure (KEEP)
├── layouts/            # Layout system (KEEP/INTEGRATE)
├── runtime/            # Runtime infrastructure (KEEP)
└── app.rs              # Application orchestration (KEEP)
```

## Implementation Plan

### Phase 1: Foundation (Week 1)
**Goal**: Create functionality structure without breaking existing code

1. Create `functionality/` directory structure
2. Move domain logic (git.rs, nix.rs, etc.) to `functionality/domain/`
3. Create module structure with public APIs
4. Update imports to use new paths

**Deliverables**:
- [ ] Directory structure created
- [ ] Domain modules moved and working
- [ ] All tests passing

### Phase 2: Extract Navigation (Week 2)
**Goal**: Centralize navigation behaviors

1. Extract `NavigableWidget` trait to `functionality/navigation/mod.rs`
2. Create `CursorNavigation` struct for cursor management
3. Create `SelectionManager` for selection handling
4. Create `ScrollViewport` for scrolling logic
5. Refactor list.rs to use new navigation modules

**Deliverables**:
- [ ] Navigation modules implemented
- [ ] List widget refactored as proof of concept
- [ ] Navigation tests written

### Phase 3: Extract Input Handling (Week 3)
**Goal**: Centralize input operations

1. Move validation.rs to `functionality/input/`
2. Extract text operations from text_input.rs
3. Create clipboard module for yank/paste
4. Create history module for undo/redo
5. Refactor text_input.rs to use new modules

**Deliverables**:
- [ ] Input modules implemented
- [ ] TextInput widget refactored
- [ ] Input operation tests written

### Phase 4: Extract Visual Systems (Week 4)
**Goal**: Centralize rendering behaviors

1. Extract theming from widgets/mod.rs
2. Extract border rendering helpers
3. Create focus management module
4. Create icon integration module
5. Refactor popup.rs to use visual modules

**Deliverables**:
- [ ] Visual modules implemented
- [ ] Popup widget refactored
- [ ] Visual system tests written

### Phase 5: Widget Refactoring (Weeks 5-6)
**Goal**: Refactor all widgets to use functionality modules

Refactor remaining widgets:
- [ ] table.rs
- [ ] tree.rs
- [ ] menu.rs
- [ ] form.rs
- [ ] panel.rs
- [ ] breadcrumb.rs
- [ ] status_bar.rs
- [ ] toolbar.rs
- [ ] scrollview.rs
- [ ] progress.rs

### Phase 6: Optimization (Week 7)
**Goal**: Clean up and optimize

1. Remove duplicate code from widgets/mod.rs
2. Consolidate macro usage
3. Performance profiling
4. Documentation updates
5. Integration tests

**Deliverables**:
- [ ] widgets/mod.rs reduced to <300 LOC
- [ ] All macros consolidated
- [ ] Performance benchmarks
- [ ] Updated documentation

## Example Transformations

### Before: Monolithic Widget
```rust
// widgets/list.rs - 500+ LOC
pub struct ListWidget {
    // Everything embedded
    selected: Option<usize>,
    scroll_offset: usize,
    items: Vec<String>,
    // ... dozens of fields
}

impl ListWidget {
    fn handle_navigation(&mut self, direction: Direction) {
        // 50+ lines of navigation logic
    }
    
    fn handle_selection(&mut self) {
        // 30+ lines of selection logic
    }
    
    fn calculate_viewport(&mut self) {
        // 40+ lines of scrolling logic
    }
}
```

### After: Composed Widget
```rust
// widgets/list.rs - ~200 LOC
use crate::functionality::{
    navigation::{CursorNavigation, SelectionManager, ScrollViewport},
    visual::{FocusRenderer, ThemeApplicator},
};

pub struct ListWidget {
    // Composed from functionality modules
    navigation: CursorNavigation,
    selection: SelectionManager,
    viewport: ScrollViewport,
    renderer: FocusRenderer,
    
    // Widget-specific only
    items: Vec<String>,
    config: ListConfig,
}

impl ListWidget {
    fn handle_navigation(&mut self, direction: Direction) {
        self.navigation.move_cursor(direction);
        self.viewport.ensure_visible(self.navigation.position());
    }
}
```

## Behavior Module Examples

### Navigation Module
```rust
// functionality/navigation/cursor.rs
pub struct CursorNavigation {
    position: usize,
    max_position: usize,
}

impl CursorNavigation {
    pub fn move_cursor(&mut self, direction: Direction) {
        self.position = calculate_index(self.position, self.max_position, direction);
    }
    
    pub fn move_word_forward(&mut self) { /* ... */ }
    pub fn move_word_backward(&mut self) { /* ... */ }
    pub fn jump_to_start(&mut self) { self.position = 0; }
    pub fn jump_to_end(&mut self) { self.position = self.max_position; }
}
```

### Selection Module
```rust
// functionality/navigation/selection.rs
pub struct SelectionManager {
    selected: HashSet<usize>,
    mode: SelectionMode,
    anchor: Option<usize>,
}

pub enum SelectionMode {
    Single,
    Multiple,
    Range,
}

impl SelectionManager {
    pub fn toggle(&mut self, index: usize) { /* ... */ }
    pub fn select_range(&mut self, from: usize, to: usize) { /* ... */ }
    pub fn clear(&mut self) { /* ... */ }
    pub fn is_selected(&self, index: usize) -> bool { /* ... */ }
}
```

## Benefits & Impact

### Immediate Benefits
1. **Code Reduction**: ~40% less code through deduplication
2. **Consistency**: All widgets behave identically for common operations
3. **Bug Fixes**: Fix once, apply everywhere
4. **Testing**: Test behaviors in isolation

### Long-term Benefits
1. **Feature Velocity**: Add features once, available everywhere
2. **Maintainability**: Clear separation of concerns
3. **Onboarding**: New developers understand structure quickly
4. **Extensibility**: Easy to add new behaviors

### Metrics for Success
- [ ] LOC reduction: Target 40% reduction in widgets/
- [ ] Test coverage: >90% for functionality modules
- [ ] Feature addition time: <2 hours for universal features
- [ ] Bug fix propagation: Single fix location for behavior bugs

## Risk Mitigation

### Risks
1. **Breaking Changes**: Refactoring might introduce bugs
2. **Performance**: Additional abstraction layers
3. **Complexity**: More modules to understand

### Mitigation Strategies
1. **Incremental Refactoring**: One widget at a time
2. **Comprehensive Testing**: Test before and after each phase
3. **Performance Benchmarks**: Profile before and after
4. **Documentation**: Clear module documentation

## Migration Guide

### For Existing Widgets
1. Identify common behaviors
2. Replace with functionality module usage
3. Remove duplicate code
4. Update tests

### For New Features
1. Determine if feature is universal
2. Implement in appropriate functionality module
3. Expose through widget API
4. Document usage

## Success Criteria

### Phase 1 Complete When:
- All domain logic moved to functionality/domain/
- No import errors
- All tests passing

### Phase 2-4 Complete When:
- Target functionality extracted
- At least one widget refactored
- Module tests written
- No regression in widget behavior

### Phase 5 Complete When:
- All widgets refactored
- No duplicate navigation/selection/input code
- All widget tests passing

### Phase 6 Complete When:
- widgets/mod.rs < 300 LOC
- Performance benchmarks show no regression
- Documentation updated
- 90% test coverage on functionality/

## Conclusion

This refactoring will transform our codebase from a collection of standalone widgets to a composable system of behaviors. The investment in this architecture will pay dividends through:

1. **Rapid feature development** - Add once, use everywhere
2. **Reduced maintenance** - Fix bugs in one place
3. **Better testing** - Test behaviors in isolation
4. **Improved consistency** - All widgets behave the same
5. **Easier onboarding** - Clear, logical structure

The phased approach ensures we can deliver value incrementally while maintaining a working system throughout the refactoring process.