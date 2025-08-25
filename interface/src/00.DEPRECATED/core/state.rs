// Title         : core/state.rs
// Author        : Bardia Samiee
// Project       : Parametric Forge Interface
// License       : MIT
// Path          : interface/src/core/state.rs
// ----------------------------------------------------------------------------

use crate::components::ComponentId;
use indexmap::IndexMap;
use serde_json::Value;
use smallvec::{smallvec, SmallVec};
use std::collections::hash_map::DefaultHasher;
use std::hash::{Hash, Hasher};
use strum::{Display, EnumString};

// Optimized focus chain with inline storage for up to 4 components
type ComponentFocusChain = SmallVec<[ComponentId; 4]>;

// --- Application State ------------------------------------------------------
#[derive(Debug, Clone)]
pub struct State {
    // --- Core Application State ---
    pub mode: Mode,
    pub context: Context,
    pub config: Value,

    // --- UI State ---
    pub ui: UIState,

    // --- Feedback State ---
    pub error: Option<String>,
    pub status: Option<String>,

    // --- Performance Optimization ---
    cached_layout_hash: Option<u64>,
    layout_dirty: bool,
}

// --- UI State ---------------------------------------------------------------
#[derive(Debug, Clone)]
pub struct UIState {
    // Navigation
    pub focus: Focus,
    pub focus_chain: ComponentFocusChain,
    pub selection: usize,
    pub items_count: usize,

    // Input
    pub input: String,

    // Layout
    pub layout: LayoutState,

    // Component-specific states (for complex stateful components)
    pub component_states: IndexMap<ComponentId, ComponentState>,
}

// --- Layout State -----------------------------------------------------------
#[derive(Debug, Clone)]
pub struct LayoutState {
    pub tabs: TabsState,
    pub expanded: IndexMap<ComponentId, bool>,
    pub collapsed_borders: IndexMap<ComponentId, bool>,
}

impl LayoutState {
    pub fn new() -> Self {
        Self {
            tabs: TabsState::new(),
            expanded: IndexMap::with_capacity(4), // Typical: 4 expandable panels
            collapsed_borders: IndexMap::with_capacity(4), // Typical: 4 panels with borders
        }
    }
}

// --- Tabs State -------------------------------------------------------------
#[derive(Debug, Clone)]
pub struct TabsState {
    pub selected: usize,
    pub tabs: Vec<(ComponentId, String)>,
}

impl TabsState {
    pub fn new() -> Self {
        Self {
            selected: 0,
            tabs: Vec::new(),
        }
    }

    pub fn select(&mut self, index: usize) {
        if index < self.tabs.len() {
            self.selected = index;
        }
    }

    pub fn current(&self) -> Option<&(ComponentId, String)> {
        self.tabs.get(self.selected)
    }
}

// --- Component State --------------------------------------------------------
#[derive(Debug, Clone)]
pub enum ComponentState {
    Tree {
        expanded: Vec<String>,
        selected: Option<usize>,
    },
    Table {
        sort_column: Option<usize>,
        filter: String,
    },
    Input {
        cursor: usize,
        scroll: usize,
    },
    Custom(IndexMap<String, Value>),
}

impl UIState {
    pub fn new() -> Self {
        Self {
            focus: Focus::Navigation,
            focus_chain: smallvec![],
            selection: 0,
            items_count: 0,
            input: String::new(),
            layout: LayoutState::new(),
            component_states: IndexMap::with_capacity(8),
        }
    }

    fn cycle_focus(&mut self, forward: bool) {
        if self.focus_chain.is_empty() {
            return;
        }

        let new_pos = match &self.focus {
            Focus::Component(current) => self
                .focus_chain
                .iter()
                .position(|id| id == current)
                .map(|pos| {
                    if forward {
                        (pos + 1) % self.focus_chain.len()
                    } else {
                        if pos == 0 {
                            self.focus_chain.len() - 1
                        } else {
                            pos - 1
                        }
                    }
                })
                .unwrap_or(0),
            _ => {
                if forward {
                    0
                } else {
                    self.focus_chain.len() - 1
                }
            }
        };
        self.focus = Focus::Component(self.focus_chain[new_pos].clone());
    }

    pub fn focus_next(&mut self) {
        self.cycle_focus(true);
    }
    pub fn focus_prev(&mut self) {
        self.cycle_focus(false);
    }

    pub fn get_focused_component(&self) -> Option<&ComponentId> {
        match &self.focus {
            Focus::Component(id) => Some(id),
            _ => None,
        }
    }
}

// --- Application Modes ------------------------------------------------------
#[derive(Debug, Clone, PartialEq, Display, EnumString)]
pub enum Mode {
    NixInstall, // Nix not detected
    Configure,  // Fresh machine setup
    Manage,     // Existing config management
}

// --- Focus Areas ------------------------------------------------------------
#[derive(Debug, Clone, PartialEq)]
pub enum Focus {
    Navigation,
    Input(InputMode),
    Confirm,
    Component(crate::components::ComponentId),
}

#[derive(Debug, Clone, PartialEq, Display, EnumString)]
pub enum InputMode {
    Text,
    Password,
    Multiline,
}

impl std::hash::Hash for Focus {
    fn hash<H: std::hash::Hasher>(&self, state: &mut H) {
        match self {
            Focus::Navigation => 0.hash(state),
            Focus::Input(mode) => {
                1.hash(state);
                match mode {
                    InputMode::Text => 0.hash(state),
                    InputMode::Password => 1.hash(state),
                    InputMode::Multiline => 2.hash(state),
                }
            }
            Focus::Confirm => 2.hash(state),
            Focus::Component(id) => {
                3.hash(state);
                id.hash(state);
            }
        }
    }
}

// --- Context ----------------------------------------------------------------
#[derive(Debug, Clone)]
pub struct Context {
    pub system: String,
    pub is_darwin: bool,
    pub is_linux: bool,
    pub user: String,
    pub has_nix: bool,
    pub has_config: bool,
}

impl Context {
    /// Create a new context with provided nix status
    pub fn with_nix_status(mut self, has_nix: bool) -> Self {
        self.has_nix = has_nix;
        self
    }
}

// --- State Transitions ------------------------------------------------------
#[derive(Debug, Clone)]
pub enum Transition {
    SetMode(Mode),
    SetFocus(Focus),
    Select(usize),
    SetInput(String),
    AppendInput(char),
    DeleteChar,
    SetError(Option<String>),
    SetStatus(Option<String>),
    SetItemsCount(usize),
    // UI State transitions
    FocusNext,
    FocusPrev,
    UpdateLayoutState(LayoutStateUpdates),
    SetComponentState(ComponentId, ComponentState),
}

// --- Focus Change Tracking --------------------------------------------------
#[derive(Debug, Clone)]
pub struct FocusChange {
    pub old_focus: Option<ComponentId>,
    pub new_focus: Option<ComponentId>,
}

// --- Layout State Updates ---------------------------------------------------
#[derive(Debug, Clone)]
pub struct LayoutStateUpdates {
    pub tab_selection: Option<usize>,
    pub expanded_panels: Vec<(ComponentId, bool)>,
    pub collapsed_borders: Vec<(ComponentId, bool)>,
}

impl State {
    pub fn new(mode: Mode, context: Context, config: Value) -> Self {
        Self {
            mode,
            context,
            config,
            ui: UIState::new(),
            error: None,
            status: None,
            cached_layout_hash: None,
            layout_dirty: true,
        }
    }

    pub fn transition(&mut self, t: Transition) -> Option<FocusChange> {
        // Mark layout dirty for layout-affecting transitions
        if matches!(
            t,
            Transition::SetFocus(_)
                | Transition::Select(_)
                | Transition::UpdateLayoutState(_)
                | Transition::FocusNext
                | Transition::FocusPrev
        ) {
            self.invalidate_layout_cache();
        }

        // Track focus changes
        let old_focus = self.ui.get_focused_component().cloned();

        match t {
            Transition::SetMode(mode) => self.mode = mode,
            Transition::SetFocus(focus) => self.ui.focus = focus,
            Transition::Select(idx) => self.ui.selection = idx.min(self.ui.items_count.saturating_sub(1)),
            Transition::SetInput(input) => self.ui.input = input,
            Transition::AppendInput(c) => self.ui.input.push(c),
            Transition::DeleteChar => {
                self.ui.input.pop();
            }
            Transition::SetError(error) => self.error = error,
            Transition::SetStatus(status) => self.status = status,
            Transition::SetItemsCount(count) => {
                self.ui.items_count = count;
                if self.ui.selection >= count && count > 0 {
                    self.ui.selection = count - 1;
                }
            }
            Transition::FocusNext => self.ui.focus_next(),
            Transition::FocusPrev => self.ui.focus_prev(),
            Transition::UpdateLayoutState(updates) => self.apply_layout_updates(updates),
            Transition::SetComponentState(id, state) => {
                self.ui.component_states.insert(id, state);
            }
        }

        // Detect focus changes and return them
        let new_focus = self.ui.get_focused_component().cloned();
        if old_focus != new_focus {
            Some(FocusChange { old_focus, new_focus })
        } else {
            None
        }
    }

    pub fn apply_layout_updates(&mut self, updates: LayoutStateUpdates) {
        if let Some(tab_idx) = updates.tab_selection {
            self.ui.layout.tabs.select(tab_idx);
        }

        for (id, expanded) in updates.expanded_panels {
            self.ui.layout.expanded.insert(id, expanded);
        }

        for (id, collapsed) in updates.collapsed_borders {
            self.ui.layout.collapsed_borders.insert(id, collapsed);
        }
    }

    pub fn register_component(&mut self, id: ComponentId, can_focus: bool) {
        if can_focus {
            self.ui.focus_chain.push(id);
        }
    }

    pub fn unregister_component(&mut self, id: &ComponentId) {
        self.ui.focus_chain.retain(|cid| cid != id);
        self.ui.component_states.swap_remove(id);
    }

    pub fn should_quit(&self) -> bool {
        false // Will be set via Effect::Exit
    }

    pub fn layout_hash(&self) -> u64 {
        if !self.layout_dirty {
            if let Some(cached) = self.cached_layout_hash {
                return cached;
            }
        }
        self.compute_layout_hash()
    }

    fn compute_layout_hash(&self) -> u64 {
        let mut hasher = DefaultHasher::new();
        (
            &self.ui.focus,
            self.ui.selection,
            self.ui.layout.tabs.selected,
            self.ui.layout.expanded.len(),
        )
            .hash(&mut hasher);
        hasher.finish()
    }

    pub fn invalidate_layout_cache(&mut self) {
        self.layout_dirty = true;
        self.cached_layout_hash = None;
    }

    pub fn update_layout_cache(&mut self) {
        if self.layout_dirty {
            self.cached_layout_hash = Some(self.compute_layout_hash());
            self.layout_dirty = false;
        }
    }
}
