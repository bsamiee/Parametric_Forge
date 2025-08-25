// Title         : functionality/core/state.rs
// Author        : Bardia Samiee
// Project       : Parametric Forge
// License       : MIT
// Path          : interface/src/functionality/core/state.rs
// ----------------------------------------------------------------------------
//! State management system with geometry-inspired caching

use super::geometry::{Viewport, Scalar};
use super::events::FocusContext;
use super::modes::AppMode;
use super::feedback::{FeedbackManager, FeedbackLevel, FeedbackEntry};
use super::tabs::{TabManager, TabEntry};
use bitflags::bitflags;
use derive_more::{Constructor, From, Deref, Display};
use getset::{Getters, MutGetters, CopyGetters};
use rustc_hash::{FxHashSet, FxHashMap};
use tinyvec::TinyVec;
use std::hash::{Hash, Hasher, DefaultHasher};
use compact_str::CompactString;
use std::time::Instant;

// --- State Flags -------------------------------------------------------------

bitflags! {
    pub struct StateFlags: u32 {
        const FOCUSED = 1; const SELECTING = 2; const MULTI_SELECT = 4; const DIRTY = 8;
        const ERROR_STATE = 16; const STATUS_ACTIVE = 32; const TAB_AWARE = 64; const MODE_LOCKED = 128;
        const UI_ENHANCED = Self::TAB_AWARE.bits() | Self::STATUS_ACTIVE.bits();
        const FEEDBACK_ENABLED = Self::ERROR_STATE.bits() | Self::STATUS_ACTIVE.bits();
    }
}

bitflags! {
    pub struct ComponentFlags: u16 {
        const FOCUSABLE = 1; const SELECTABLE = 2; const EXPANDABLE = 4; const SCROLLABLE = 8;
    }
}

// --- Core State Types --------------------------------------------------------

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Constructor, CopyGetters)]
pub struct Position { #[getset(get_copy = "pub")] pub index: usize, pub row: usize, pub col: usize }

impl Position {
    pub fn linear(index: usize) -> Self { Self::new(index, 0, 0) }
    pub fn grid(index: usize, columns: usize) -> Self { Self::new(index, index / columns, index % columns) }
}

#[derive(Debug, Clone, Default, Constructor, Getters)]
pub struct Selection {
    #[getset(get = "pub")] selected: FxHashSet<usize>,
    anchor: Option<usize>, range_end: Option<usize>,
}

impl Selection {
    pub fn single(index: usize) -> Self {
        let mut selected = FxHashSet::default(); selected.insert(index);
        Self::new(selected, Some(index), None)
    }
    pub fn range(start: usize, end: usize) -> Self {
        let mut selected = FxHashSet::default();
        for i in start.min(end)..=start.max(end) { selected.insert(i); }
        Self::new(selected, Some(start), Some(end))
    }
    pub fn is_selected(&self, index: usize) -> bool { self.selected.contains(&index) }
    pub fn count(&self) -> usize { self.selected.len() }
    pub fn anchor(&self) -> Option<usize> { self.anchor }
    pub fn indices(&self) -> impl Iterator<Item = usize> + '_ { self.selected.iter().copied() }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, From, Constructor)]
pub struct ComponentId(pub u32);

#[derive(Debug, Clone, Default, Constructor)]
pub struct FocusChain {
    chain: TinyVec<[ComponentId; 4]>, current: Option<usize>,
}

impl FocusChain {
    pub fn push(&mut self, id: ComponentId) { self.chain.push(id); }
    pub fn remove(&mut self, id: ComponentId) { self.chain.retain(|&cid| cid != id); }
    pub fn cycle(&mut self, forward: bool) -> Option<ComponentId> {
        if self.chain.is_empty() { return None; }
        let pos = self.current.map_or(0, |p|
            if forward { (p + 1) % self.chain.len() }
            else { p.wrapping_sub(1) % self.chain.len() });
        self.current = Some(pos);
        self.chain.get(pos).copied()
    }
    pub fn current(&self) -> Option<ComponentId> {
        self.current.and_then(|p| self.chain.get(p)).copied()
    }
}

// --- Widget State ------------------------------------------------------------

#[derive(Debug, Clone, Constructor, Getters, MutGetters)]
pub struct WidgetState {
    #[getset(get = "pub", get_mut = "pub")] pub position: Position,
    #[getset(get = "pub")] pub viewport: Viewport,
    #[getset(get = "pub", get_mut = "pub")] pub selection: Selection,
    pub flags: StateFlags, pub columns: Option<usize>,
    focus_chain: FocusChain, layout_hash: Option<u64>,
    feedback: Option<FeedbackManager>, tabs: Option<TabManager>,
    mode_context: Option<AppMode>,
}

impl WidgetState {
    pub fn new_enhanced(max_items: usize, mode: AppMode) -> Self {
        Self::new(
            Position::linear(0), Viewport::new(0, 10, max_items), Selection::default(),
            StateFlags::UI_ENHANCED, None, FocusChain::default(), None,
            Some(FeedbackManager::new()), Some(TabManager::default()), Some(mode)
        )
    }
    
    pub fn feedback_mut(&mut self) -> &mut FeedbackManager {
        self.feedback.get_or_insert_with(FeedbackManager::new)
    }
    
    pub fn feedback(&self) -> &FeedbackManager {
        static DEFAULT: FeedbackManager = FeedbackManager::new();
        self.feedback.as_ref().unwrap_or(&DEFAULT)
    }
    
    pub fn tabs_mut(&mut self) -> &mut TabManager {
        self.tabs.get_or_insert_with(TabManager::default)
    }
    
    pub fn tabs(&self) -> &TabManager {
        static DEFAULT: TabManager = TabManager::default();
        self.tabs.as_ref().unwrap_or(&DEFAULT)
    }
    
    pub fn set_mode(&mut self, mode: AppMode) {
        self.mode_context = Some(mode);
        self.invalidate_cache();
    }
    
    pub fn current_mode(&self) -> AppMode {
        self.mode_context.unwrap_or(AppMode::NixInstall)
    }
    
    pub fn compute_hash(&self) -> u64 {
        let mut hasher = DefaultHasher::new();
        (self.position.index, self.viewport.offset(), self.selection.count(),
         self.tabs().tab_count(), self.tabs().selected_index(),
         self.feedback().has_active_feedback(), self.current_mode()).hash(&mut hasher);
        hasher.finish()
    }
    
    pub fn invalidate_cache(&mut self) { self.layout_hash = None; }
    pub fn cached_hash(&self) -> Option<u64> { self.layout_hash }
    pub fn update_cache(&mut self) { self.layout_hash = Some(self.compute_hash()); }
    
    pub fn register_component(&mut self, id: ComponentId) { self.focus_chain.push(id); }
    pub fn cycle_focus(&mut self, forward: bool) -> Option<ComponentId> { self.focus_chain.cycle(forward) }
    pub fn focused_component(&self) -> Option<ComponentId> { self.focus_chain.current() }
    
    pub fn is_focused(&self) -> bool { self.flags.contains(StateFlags::FOCUSED) }
    pub fn is_dirty(&self) -> bool { self.flags.contains(StateFlags::DIRTY) }
    pub fn supports_multi_select(&self) -> bool { self.flags.contains(StateFlags::MULTI_SELECT) }
}

// --- Trait System ------------------------------------------------------------

pub trait StateQuery { fn state(&self) -> &WidgetState; }
pub trait StateOwner: StateQuery { fn state_mut(&mut self) -> &mut WidgetState; }
pub trait FeedbackQuery: StateQuery {
    fn feedback(&self) -> Option<&FeedbackManager> { None }
    fn tabs(&self) -> Option<&TabManager> { None }
}