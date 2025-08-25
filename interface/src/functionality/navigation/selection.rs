// Title         : functionality/navigation/selection.rs
// Author        : Bardia Samiee
// Project       : Parametric Forge
// License       : MIT
// Path          : interface/src/functionality/navigation/selection.rs
// ----------------------------------------------------------------------------
//! Thin selection wrapper extending core::state::Selection with navigation

use super::{core::*, behaviors::SelectionBehavior};
use crate::functionality::core::state::{Selection as CoreSelection, Position};
use crate::functionality::core::{Point, Rect};
use derive_more::{Constructor, Display, From};
use std::ops::RangeInclusive;
use delegate::delegate;

// --- Selection Range ---------------------------------------------------------

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Constructor, Display, From)]
#[display("[{}..{}]", start, end)]
pub struct SelectionRange {
    start: usize,
    end: usize,
}

impl SelectionRange {
    #[inline] pub fn start(&self) -> usize { self.start }
    #[inline] pub fn end(&self) -> usize { self.end }
    #[inline] pub fn normalized(start: usize, end: usize) -> Self { Self::new(start.min(end), start.max(end)) }
    #[inline] pub fn contains(&self, index: usize) -> bool { index >= self.start && index <= self.end }
    #[inline] pub fn iter(&self) -> RangeInclusive<usize> { self.start..=self.end }
    #[inline] pub fn len(&self) -> usize { self.end.saturating_sub(self.start).saturating_add(1) }
    #[inline] pub fn is_empty(&self) -> bool { self.start > self.end }
}

// --- Selection Manager -------------------------------------------------------

/// Thin wrapper over core Selection with navigation integration
pub struct SelectionManager<const CACHE_SIZE: usize = 64> {
    nav: Navigator<SelectionBehavior<32>, CACHE_SIZE>,
    selection: CoreSelection,
}

impl<const CS: usize> SelectionManager<CS> {
    pub fn new() -> Self {
        Self {
            nav: Navigator::new(),
            selection: CoreSelection::default(),
        }
    }

    // Navigation delegation
    delegate! {
        to self.nav {
            pub fn navigate(&mut self, direction: super::Direction) -> bool;
            pub fn screen_to_index(&self, point: Point<u16>, area: Rect<u16>) -> Option<usize>;
            pub fn index_to_screen(&self, index: usize, area: Rect<u16>) -> Option<Point<u16>>;
            pub fn invalidate_cache(&mut self);
        }
    }

    // Selection operations using core Selection
    pub fn select(&mut self, index: usize) -> bool {
        if index >= self.nav.state.max_items() { return false; }
        self.selection = CoreSelection::single(index);
        self.nav.state.anchor = Some(index);
        true
    }

    pub fn select_range(&mut self, from: usize, to: usize) {
        self.selection = CoreSelection::range(from, to);
        self.nav.state.anchor = Some(from);
    }

    pub fn toggle(&mut self, index: usize) -> bool {
        if self.selection.is_selected(index) {
            // Remove from selection by rebuilding without this index
            let indices: Vec<usize> = self.selection.indices()
                .filter(|&idx| idx != index)
                .collect();
            self.selection = Self::build_selection(indices);
            false
        } else {
            // Add to selection
            let mut indices: Vec<usize> = self.selection.indices().collect();
            indices.push(index);
            self.selection = Self::build_selection(indices);
            true
        }
    }

    pub fn clear(&mut self) {
        self.selection = CoreSelection::default();
        self.nav.state.anchor = None;
    }

    // Query operations
    #[inline] pub fn is_selected(&self, index: usize) -> bool { self.selection.is_selected(index) }
    #[inline] pub fn count(&self) -> usize { self.selection.count() }
    #[inline] pub fn selected_indices(&self) -> Vec<usize> { self.selection.indices().collect() }
    #[inline] pub fn anchor(&self) -> Option<usize> { self.selection.anchor() }

    // Helper to build selection from indices
    fn build_selection(indices: Vec<usize>) -> CoreSelection {
        use rustc_hash::FxHashSet;
        let mut selected = FxHashSet::default();
        for idx in indices { selected.insert(idx); }
        let anchor = selected.iter().next().copied();
        CoreSelection::new(selected, anchor, None)
    }
}

impl<const CS: usize> Default for SelectionManager<CS> {
    fn default() -> Self { Self::new() }
}

// --- Selection Mode ----------------------------------------------------------

pub type SelectionMode = NavFlags;

// Type aliases for convenience
pub type DefaultSelection = SelectionManager<64>;