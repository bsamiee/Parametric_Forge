// Title         : functionality/core/tabs.rs
// Author        : Bardia Samiee
// Project       : Parametric Forge
// License       : MIT
// Path          : interface/src/functionality/core/tabs.rs
// ----------------------------------------------------------------------------
//! Tab management system integrated with spatial engine

use super::geometry::{Point, SpatialEngine, SpatialFlags, Direction, Scalar, GridSpace, ScreenSpace};
use super::state::ComponentId;
use bitflags::bitflags;
use derive_more::{Constructor, CopyGetters, From, Into, Deref};
use rustc_hash::FxHashMap;
use tinyvec::TinyVec;
use compact_str::CompactString;
use std::marker::PhantomData;

// --- Tab Flags ---------------------------------------------------------------

bitflags! {
    pub struct TabFlags: u16 {
        const CLOSABLE = 1; const REORDERABLE = 2; const BADGE_ENABLED = 4;
        const KEYBOARD_NAV = 8; const MOUSE_NAV = 16; const SPATIAL_NAV = 32;
        const INTERACTIVE = Self::KEYBOARD_NAV.bits() | Self::MOUSE_NAV.bits() | Self::SPATIAL_NAV.bits();
        const ADVANCED = Self::CLOSABLE.bits() | Self::REORDERABLE.bits() | Self::INTERACTIVE.bits();
    }
}

// --- Tab Entry ---------------------------------------------------------------

#[derive(Debug, Clone, Constructor, CopyGetters, From, Into)]
pub struct TabEntry<S = ScreenSpace> {
    #[getset(get_copy = "pub")] id: ComponentId,
    title: CompactString, flags: TabFlags, badge_count: Option<u16>,
    spatial_position: Point<usize, S>,
    _space: PhantomData<S>,
}

impl<S> TabEntry<S> {
    pub fn simple(id: ComponentId, title: impl Into<CompactString>, position: Point<usize, S>) -> Self {
        Self::new(id, title.into(), TabFlags::INTERACTIVE, None, position, PhantomData)
    }
    
    pub fn with_badge(mut self, count: u16) -> Self {
        self.flags |= TabFlags::BADGE_ENABLED;
        self.badge_count = Some(count);
        self
    }
    
    pub fn to_space<T>(self) -> TabEntry<T> {
        TabEntry::new(self.id, self.title, self.flags, self.badge_count,
                     self.spatial_position.to_space(), PhantomData)
    }
    
    pub fn title(&self) -> &str { self.title.as_str() }
    pub fn has_badge(&self) -> bool { self.flags.contains(TabFlags::BADGE_ENABLED) }
    pub fn position(&self) -> Point<usize, S> { self.spatial_position }
}

// --- Tab Manager -------------------------------------------------------------

#[derive(Debug, Clone, Constructor)]
pub struct TabManager<T: Scalar = usize> {
    tabs: TinyVec<[TabEntry<GridSpace>; 8]>,
    spatial: SpatialEngine<T>,
    selected: usize,
    flags: TabFlags,
}

impl<T: Scalar> Default for TabManager<T> where T: From<u8> + num_traits::Zero + num_traits::One {
    fn default() -> Self {
        Self::new(
            TinyVec::new(),
            SpatialEngine::linear().with_caching(),
            0,
            TabFlags::INTERACTIVE
        )
    }
}

impl<T: Scalar> TabManager<T> where T: From<u8> + num_traits::Zero + num_traits::One {
    pub fn with_capacity(capacity: usize) -> Self {
        let spatial = SpatialEngine::linear()
            .with_caching()
            .optimized();
        Self::new(
            TinyVec::with_capacity(capacity),
            spatial,
            0,
            TabFlags::ADVANCED
        )
    }
    
    pub fn register_tab(&mut self, id: ComponentId, title: impl Into<CompactString>) {
        let position = Point::new(self.tabs.len(), 0).to_space::<GridSpace>();
        let tab = TabEntry::simple(id, title, position);
        self.tabs.push(tab);
        self.spatial.max_items = T::from(self.tabs.len() as u8).unwrap();
        self.spatial.invalidate_cache();
    }
    
    pub fn navigate(&mut self, direction: Direction) -> Option<ComponentId> {
        let new_idx = self.spatial.calculate_position(
            T::from(self.selected as u8).unwrap(),
            direction
        ).to_usize().unwrap();
        if new_idx != self.selected && new_idx < self.tabs.len() {
            self.selected = new_idx;
            self.tabs.get(self.selected).map(|tab| tab.id())
        } else { None }
    }
    
    pub fn select_tab(&mut self, index: usize) -> Option<ComponentId> {
        if index < self.tabs.len() {
            self.selected = index;
            self.tabs.get(index).map(|tab| tab.id())
        } else { None }
    }
    
    pub fn cycle_tab(&mut self, forward: bool) -> Option<ComponentId> {
        self.navigate(if forward { Direction::Right } else { Direction::Left })
    }
    
    pub fn current_tab(&self) -> Option<&TabEntry<GridSpace>> { self.tabs.get(self.selected) }
    pub fn tab_count(&self) -> usize { self.tabs.len() }
    pub fn selected_index(&self) -> usize { self.selected }
    pub fn tabs(&self) -> impl Iterator<Item = (usize, &TabEntry<GridSpace>)> {
        self.tabs.iter().enumerate()
    }
    
    pub fn spatial_stats(&self) -> (usize, usize) { self.spatial.cache_stats() }
    pub fn invalidate_cache(&mut self) { self.spatial.invalidate_cache(); }
}