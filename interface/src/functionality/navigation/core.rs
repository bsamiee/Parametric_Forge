// Title         : functionality/navigation/core.rs
// Author        : Bardia Samiee
// Project       : Parametric Forge
// License       : MIT
// Path          : interface/src/functionality/navigation/core.rs
// ----------------------------------------------------------------------------
//! A++ navigation core with parallel operations, const generics, and SIMD support

use crate::functionality::core::{SpatialEngine, SpatialFlags, Viewport, Point, LogicalSpace, Direction};
use arrayvec::ArrayVec;
use derive_more::Constructor;
use rayon::prelude::*;
use std::marker::PhantomData;
use delegate::delegate;

/// Navigation flags - type alias for SpatialFlags with navigation-specific extensions
pub type NavFlags = SpatialFlags;

impl NavFlags {
    pub const SELECT_SINGLE: Self = Self::CACHE;
    pub const SELECT_MULTI: Self = Self::PREFETCH;
    pub const SELECT_RANGE: Self = Self::DIRTY;
    pub const SMOOTH_SCROLL: Self = Self::SMOOTH;
    pub const CENTER_ON_NAV: Self = Self::CENTER;
    pub const WORD_BOUNDARY: Self = Self::SIMD;
    pub const MOUSE_ENABLED: Self = Self::OPTIMIZED;
    pub const TEXT_AWARE: Self = Self::RESPONSIVE;
    pub const VIRTUAL_CONTENT: Self = Self::VIRTUAL;
    pub const HIERARCHICAL: Self = Self::TREE;
    pub const ANIMATED: Self = Self::SMOOTH;
    pub const WRAP_AROUND: Self = Self::WRAP;
    pub const CLAMP_BOUNDS: Self = Self::CLAMP;
    pub const GRID_MODE: Self = Self::GRID;
}

/// Navigation state with virtual content support
#[derive(Debug, Clone, Constructor)]
pub struct NavState {
    pub position: Point<usize, LogicalSpace>,
    pub viewport: Viewport<usize>,
    pub anchor: Option<usize>,
    pub columns: Option<usize>,
}

impl NavState {
    #[inline] pub fn index(&self) -> usize { self.position.x() }
    #[inline] pub fn row(&self) -> usize { self.position.y() }
    #[inline] pub fn col(&self) -> usize { self.position.x() % self.columns.unwrap_or(1) }
    #[inline] pub fn offset(&self) -> usize { self.viewport.offset() }
    #[inline] pub fn max_items(&self) -> usize { self.viewport.max_items() }
    #[inline] pub fn viewport_size(&self) -> usize { self.viewport.size() }
    #[inline] pub fn set_index(&mut self, idx: usize) { self.position = Point::new(idx, self.position.y()); }
    #[inline] pub fn set_offset(&mut self, off: usize) { 
        self.viewport = Viewport::new(off, self.viewport.size(), self.viewport.max_items()); 
    }
}

impl Default for NavState {
    fn default() -> Self { Self::new(Point::new(0, 0), Viewport::new(0, 10, 0), None, None) }
}

/// Navigation behavior specialization trait
pub trait NavBehavior: Send + Sync {
    fn calculate_move(state: &NavState, flags: NavFlags, dir: Direction) -> usize;
    fn post_move(state: &mut NavState, flags: NavFlags, old_pos: usize) {}
    fn validate_position(pos: usize, state: &NavState, flags: NavFlags) -> usize {
        if flags.contains(NavFlags::CLAMP_BOUNDS) { pos.min(state.max_items().saturating_sub(1)) } else { pos }
    }
}

/// Thin navigation wrapper over SpatialEngine with behavior specialization
pub struct Navigator<B: NavBehavior, const CACHE_SIZE: usize = 64> {
    pub state: NavState,
    pub flags: NavFlags,
    engine: SpatialEngine<usize>,
    _behavior: PhantomData<B>,
}

impl<B: NavBehavior, const CS: usize> Navigator<B, CS> {
    pub fn new() -> Self {
        Self {
            state: NavState::default(),
            flags: SpatialFlags::LINEAR | SpatialFlags::CLAMP | SpatialFlags::CACHE,
            engine: SpatialEngine::linear(),
            _behavior: PhantomData,
        }
    }

    pub fn configure(self) -> NavConfig<B, CS> { NavConfig { nav: self, pending_flags: NavFlags::empty() } }

    #[inline]
    pub fn navigate(&mut self, direction: Direction) -> bool {
        let old_pos = self.state.index();
        self.sync_engine();
        let new_pos = B::calculate_move(&self.state, self.flags, direction);
        
        if old_pos != new_pos {
            self.state.set_index(new_pos);
            B::post_move(&mut self.state, self.flags, old_pos);
            true
        } else {
            false
        }
    }

    pub fn navigate_batch_par(&mut self, directions: &[Direction]) -> Vec<bool> {
        self.sync_engine();
        directions.par_iter().map(|&dir| {
            let pos = self.engine.calculate_position(self.state.index(), dir);
            pos != self.state.index()
        }).collect()
    }

    pub fn navigate_batch(&mut self, directions: &[Direction]) -> Vec<bool> {
        directions.iter().map(|&dir| self.navigate(dir)).collect()
    }

    #[inline(always)]
    fn sync_engine(&mut self) {
        self.engine.max_items = self.state.max_items();
        self.engine.offset = self.state.offset();
        self.engine.columns = self.state.columns;
        self.engine.flags = self.flags;
    }

    delegate! {
        to self.engine {
            pub fn screen_to_index(&self, point: Point<u16>, area: Rect<u16>) -> Option<usize>;
            pub fn index_to_screen(&self, index: usize, area: Rect<u16>) -> Option<Point<u16>>;
            pub fn invalidate_cache(&mut self);
        }
    }
}

/// Fluent configuration builder
pub struct NavConfig<B: NavBehavior, const CS: usize = 64> {
    nav: Navigator<B, CS>,
    pending_flags: NavFlags,
}

impl<B: NavBehavior, const CS: usize> NavConfig<B, CS> {
    pub fn max_items(mut self, value: usize) -> Self {
        self.nav.state.viewport = Viewport::new(self.nav.state.viewport.offset(), self.nav.state.viewport.size(), value);
        self
    }

    pub fn viewport_size(mut self, value: usize) -> Self {
        self.nav.state.viewport = Viewport::new(self.nav.state.viewport.offset(), value, self.nav.state.viewport.max_items());
        self
    }

    pub fn columns(mut self, value: Option<usize>) -> Self { self.nav.state.columns = value; self }
    pub fn with_flags(mut self, flags: NavFlags) -> Self { self.pending_flags.insert(flags); self }

    pub fn with_features(mut self, mouse: bool, text: bool, virt: bool, hier: bool, anim: bool) -> Self {
        if mouse { self.pending_flags.insert(NavFlags::MOUSE_ENABLED); }
        if text { self.pending_flags.insert(NavFlags::TEXT_AWARE); }
        if virt { self.pending_flags.insert(NavFlags::VIRTUAL_CONTENT); }
        if hier { self.pending_flags.insert(NavFlags::HIERARCHICAL); }
        if anim { self.pending_flags.insert(NavFlags::ANIMATED); }
        self
    }

    pub fn build(mut self) -> Navigator<B, CS> {
        self.nav.flags.insert(self.pending_flags);
        self.nav.sync_engine();
        self.nav
    }
}

// Word boundary detection is now in core - use that instead
pub use crate::functionality::core::find_word_boundaries_simd;