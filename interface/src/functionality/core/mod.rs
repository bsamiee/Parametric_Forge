// Title         : functionality/core/mod.rs
// Author        : Bardia Samiee
// Project       : Parametric Forge
// License       : MIT
// Path          : interface/src/functionality/core/mod.rs
// ----------------------------------------------------------------------------
//! Core TUI functionality with spatial foundation

use derive_more::{Constructor, From, Into, Deref, DerefMut};
use bitflags::bitflags;

// --- Module Organization -----------------------------------------------------

mod events;
mod feedback;
mod geometry;
mod modes;
mod state;
mod tabs;

// --- Public Exports ----------------------------------------------------------

pub use geometry::{SpatialEngine, SpatialFlags, Direction, Scalar, Point, Rect, ScreenPoint, ScreenRect, Viewport, LogicalSpace, ScreenSpace, find_word_boundaries_simd};
pub use events::{Event, EventClass, EventDispatcher, FocusContext, Action, GlobalSpace, NavigationSpace, InputSpace, TabSpace};
pub use modes::{AppMode, ModeEngine, ModeContext, ModeError, ModeFlags};
pub use state::{
    StateFlags, Position, Selection, WidgetState, StateQuery, StateOwner, FeedbackQuery,
    ComponentId, FocusChain
};
pub use feedback::{FeedbackManager, FeedbackEntry, FeedbackLevel, TraceSpace, InfoSpace, ErrorSpace};
pub use tabs::{TabManager, TabEntry, TabFlags};
pub use crossterm::event::{KeyEvent, MouseEvent, KeyCode, KeyModifiers};

// --- Core Flags --------------------------------------------------------------

bitflags! {
    pub struct CoreFlags: u32 {
        // Spatial engine flags
        const SPATIAL_LINEAR = 1; const SPATIAL_GRID = 2; const SPATIAL_VIRTUAL = 4;
        const SPATIAL_WRAP = 8; const SPATIAL_CLAMP = 16; const SPATIAL_CACHE = 32;
        // State management flags
        const STATE_FOCUSED = 64; const STATE_SELECTING = 128; const STATE_MULTI_SELECT = 256;
        const STATE_TAB_ENABLED = 512; const STATE_FEEDBACK_ENABLED = 1024; const STATE_MODE_AWARE = 2048;
        // Composite flags
        const ENHANCED_UI = Self::STATE_TAB_ENABLED.bits() | Self::STATE_FEEDBACK_ENABLED.bits();
        const FULL_FEATURED = Self::ENHANCED_UI.bits() | Self::STATE_MODE_AWARE.bits();
    }
}

impl CoreFlags {
    pub fn spatial(&self) -> SpatialFlags {
        let mut f = SpatialFlags::empty();
        if self.contains(Self::SPATIAL_LINEAR) { f |= SpatialFlags::LINEAR; }
        if self.contains(Self::SPATIAL_GRID) { f |= SpatialFlags::GRID; }
        if self.contains(Self::SPATIAL_VIRTUAL) { f |= SpatialFlags::VIRTUAL; }
        if self.contains(Self::SPATIAL_WRAP) { f |= SpatialFlags::WRAP; }
        if self.contains(Self::SPATIAL_CLAMP) { f |= SpatialFlags::CLAMP; }
        if self.contains(Self::SPATIAL_CACHE) { f |= SpatialFlags::CACHE; }
        f
    }

    pub fn state(&self) -> StateFlags {
        let mut f = StateFlags::empty();
        if self.contains(Self::STATE_FOCUSED) { f |= StateFlags::FOCUSED; }
        if self.contains(Self::STATE_SELECTING) { f |= StateFlags::SELECTING; }
        if self.contains(Self::STATE_MULTI_SELECT) { f |= StateFlags::MULTI_SELECT; }
        if self.contains(Self::STATE_TAB_ENABLED) { f |= StateFlags::TAB_AWARE; }
        if self.contains(Self::STATE_FEEDBACK_ENABLED) { f |= StateFlags::FEEDBACK_ENABLED; }
        f
    }

    pub const fn supports_tabs(&self) -> bool { self.contains(Self::STATE_TAB_ENABLED) }
    pub const fn supports_feedback(&self) -> bool { self.contains(Self::STATE_FEEDBACK_ENABLED) }
    pub const fn is_mode_aware(&self) -> bool { self.contains(Self::STATE_MODE_AWARE) }
}

// --- Core Engine -------------------------------------------------------------

#[derive(Debug, Clone, Constructor, Deref, DerefMut)]
pub struct CoreEngine<T: Scalar = usize> {
    #[deref] #[deref_mut]
    pub spatial: SpatialEngine<T>,
    pub state: WidgetState,
    pub flags: CoreFlags,
}

impl<T: Scalar> CoreEngine<T> where T: From<u8> + num_traits::Zero + num_traits::One {
    pub fn with_flags(max_items: T, viewport_size: T, flags: CoreFlags, mode: AppMode) -> Self {
        let spatial = SpatialEngine::new(T::zero(), viewport_size, max_items, None, flags.spatial(), rustc_hash::FxHashMap::default());
        let state = WidgetState::new_enhanced(max_items.to_usize().unwrap(), mode);
        Self::new(spatial, state, flags)
    }

    pub fn navigate(&mut self, dir: Direction) -> bool {
        let new_pos = self.spatial.calculate_position(T::from(self.state.position.index).unwrap(), dir).to_usize().unwrap();
        if new_pos != self.state.position.index {
            self.state.position = self.state.columns.map_or(Position::linear(new_pos), |cols| Position::grid(new_pos, cols));
            self.state.invalidate_cache(); true
        } else { false }
    }

    pub fn handle_mouse(&mut self, point: ScreenPoint, area: ScreenRect) -> bool {
        self.spatial.screen_to_index(point, area).map_or(false, |idx| {
            let new_idx = idx.to_usize().unwrap();
            self.state.position = self.state.columns.map_or(Position::linear(new_idx), |cols| Position::grid(new_idx, cols));
            self.state.invalidate_cache(); true
        })
    }

    pub fn process_action(&mut self, action: Action) -> bool {
        match action {
            Action::Navigate(dir) => self.navigate(dir),
            Action::Select(idx) => {
                self.state.position = self.state.columns.map_or(Position::linear(idx), |cols| Position::grid(idx, cols));
                self.state.invalidate_cache(); true
            },
            Action::Mouse(x, y) => self.handle_mouse(ScreenPoint::new(x, y), ScreenRect::new(0, 0, 100, 50)),
            Action::TabNext => self.state.tabs_mut().cycle_tab(true).is_some(),
            Action::TabPrev => self.state.tabs_mut().cycle_tab(false).is_some(),
            Action::TabSelect(idx) => self.state.tabs_mut().select_tab(idx).is_some(),
            Action::FeedbackAdd(level, msg) => {
                self.state.feedback_mut().add_entry(FeedbackEntry::persistent(msg, level));
                self.state.invalidate_cache(); true
            },
            Action::FeedbackClear => {
                self.state.feedback_mut().clear();
                self.state.invalidate_cache(); true
            },
            Action::ModeTransition(mode) => {
                self.state.set_mode(mode);
                true
            },
            _ => false,
        }
    }

    pub fn process_events(&mut self, events: tinyvec::TinyVec<[KeyEvent; 8]>, context: FocusContext) -> usize {
        let mode = self.state.current_mode();
        let actions = EventDispatcher::batch_process(events, context, mode);
        actions.into_iter().map(|action| self.process_action(action) as usize).sum()
    }

    pub fn handle_event(&mut self, event: Event) -> bool {
        match (event.class, event.direction) {
            (c, Some(dir)) if c.contains(EventClass::NAV) => self.navigate(dir),
            _ => false,
        }
    }
}

// --- Widget Trait ------------------------------------------------------------

pub trait Widget: StateQuery {
    type Content;
    fn core(&mut self) -> &mut CoreEngine;
    fn handle_event(&mut self, event: Event) -> bool { self.core().handle_event(event) }
    fn content(&self) -> &Self::Content;
}

// --- Core Builder ------------------------------------------------------------

#[derive(Constructor, From, Into)]
pub struct CoreBuilder<C, T: Scalar = usize> {
    content: C, max_items: T, viewport_size: T, flags: CoreFlags, columns: Option<T>,
}

impl<C> CoreBuilder<C, usize> {
    pub fn new(content: C, max_items: usize, mode: AppMode) -> Self {
        Self::new(content, max_items, 10, CoreFlags::FULL_FEATURED, None)
    }
}

impl<C, T: Scalar> CoreBuilder<C, T> where T: From<u8> + num_traits::Zero + num_traits::One {
    pub fn grid(mut self, cols: T) -> Self { self.columns = Some(cols); self.flags = (self.flags - CoreFlags::SPATIAL_LINEAR) | CoreFlags::SPATIAL_GRID; self }
    pub fn wrap(mut self) -> Self { self.flags |= CoreFlags::SPATIAL_WRAP; self }
    pub fn cache(mut self) -> Self { self.flags |= CoreFlags::SPATIAL_CACHE; self }
    pub fn select(mut self) -> Self { self.flags |= CoreFlags::STATE_SELECTING; self }
    pub fn focus_aware(mut self) -> Self { self.flags |= CoreFlags::STATE_FOCUSED; self }
    pub fn build(self, mode: AppMode) -> CoreEngine<T> {
        let mut e = CoreEngine::with_flags(self.max_items, self.viewport_size, self.flags, mode);
        if let Some(cols) = self.columns { e.spatial.columns = Some(cols); }
        e.state.update_cache(); e
    }
}

// --- Performance Monitoring --------------------------------------------------

pub struct CoreMetrics {
    pub cache_hits: u64,
    pub cache_misses: u64,
    pub actions_processed: u64,
    pub batch_operations: u64,
}

impl CoreMetrics {
    pub fn new() -> Self {
        Self { cache_hits: 0, cache_misses: 0, actions_processed: 0, batch_operations: 0 }
    }

    pub fn cache_hit_rate(&self) -> f64 {
        if self.cache_hits + self.cache_misses == 0 { return 0.0; }
        self.cache_hits as f64 / (self.cache_hits + self.cache_misses) as f64
    }

    pub fn reset(&mut self) {
        *self = Self::new();
    }
}