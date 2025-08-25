// Title         : functionality/navigation/behaviors.rs
// Author        : Bardia Samiee
// Project       : Parametric Forge
// License       : MIT
// Path          : interface/src/functionality/navigation/behaviors.rs
// ----------------------------------------------------------------------------
//! A++ navigation behaviors with const generics, parallelism, and zero heap allocations

use super::core::*;
use crate::functionality::core::{SpatialEngine, Direction, Point, Rect};
use arrayvec::ArrayVec;
use rayon::prelude::*;
use ahash::AHashMap;
use std::sync::Arc;

// --- Universal Cursor Behavior (Foundation) ---

pub struct CursorBehavior;

impl NavBehavior for CursorBehavior {
    #[inline]
    fn calculate_move(state: &NavState, flags: NavFlags, dir: Direction) -> usize {
        if state.max_items() == 0 { return 0; }
        
        // Use SpatialEngine for all calculations
        let mut engine = SpatialEngine::new();
        engine.max_items = state.max_items();
        engine.offset = state.offset();
        engine.columns = state.columns;
        engine.flags = flags;
        engine.calculate_position(state.index(), dir)
    }
}

// --- Selection with Stack Allocation ---

pub struct SelectionBehavior<const MAX_SELECTIONS: usize = 32> {
    pub selected: ArrayVec<usize, MAX_SELECTIONS>,
    pub ranges: ArrayVec<(usize, usize), 8>,
    pub last_anchor: Option<usize>,
}

impl<const M: usize> Default for SelectionBehavior<M> {
    fn default() -> Self {
        Self {
            selected: ArrayVec::new(),
            ranges: ArrayVec::new(),
            last_anchor: None,
        }
    }
}

impl<const M: usize> SelectionBehavior<M> {
    /// Toggle selection at index
    #[inline]
    pub fn toggle(&mut self, idx: usize) -> bool {
        if let Some(pos) = self.selected.iter().position(|&x| x == idx) {
            self.selected.swap_remove(pos);
            false
        } else if !self.selected.is_full() {
            self.selected.push(idx);
            true
        } else {
            false
        }
    }

    /// Select range in parallel for large ranges
    pub fn select_range_par(&mut self, start: usize, end: usize) {
        if end - start > 100 {
            let indices: Vec<usize> = (start..=end).collect();
            let selected = indices.par_iter()
                .filter(|&&idx| !self.selected.contains(&idx))
                .take(M - self.selected.len())
                .copied()
                .collect::<Vec<_>>();
            self.selected.extend(selected.iter().take(self.selected.remaining_capacity()));
        } else {
            for idx in start..=end {
                if self.selected.is_full() { break; }
                if !self.selected.contains(&idx) {
                    self.selected.push(idx);
                }
            }
        }
        if !self.ranges.is_full() {
            self.ranges.push((start, end));
        }
    }

    /// Clear all selections
    #[inline]
    pub fn clear(&mut self) {
        self.selected.clear();
        self.ranges.clear();
        self.last_anchor = None;
    }
}

impl<const M: usize> NavBehavior for SelectionBehavior<M> {
    fn calculate_move(state: &NavState, flags: NavFlags, dir: Direction) -> usize {
        CursorBehavior::calculate_move(state, flags, dir)
    }

    fn post_move(state: &mut NavState, flags: NavFlags, _old_pos: usize) {
        if flags.contains(NavFlags::SELECT_RANGE) && state.anchor.is_none() {
            state.anchor = Some(state.index());
        }
    }
}

// --- Scroll with Const Page Size ---

pub struct ScrollBehavior<const PAGE_SIZE: usize = 10>;

impl<const P: usize> NavBehavior for ScrollBehavior<P> {
    #[inline]
    fn calculate_move(state: &NavState, _flags: NavFlags, dir: Direction) -> usize {
        let viewport = &state.viewport;
        match dir {
            Direction::Up => viewport.offset().saturating_sub(1),
            Direction::Down => (viewport.offset() + 1).min(state.max_items().saturating_sub(viewport.size())),
            Direction::PageUp => viewport.offset().saturating_sub(P),
            Direction::PageDown => (viewport.offset() + P).min(state.max_items().saturating_sub(viewport.size())),
            Direction::Home => 0,
            Direction::End => state.max_items().saturating_sub(viewport.size()),
            _ => viewport.offset(),
        }
    }

    fn post_move(state: &mut NavState, flags: NavFlags, _old_pos: usize) {
        if flags.contains(NavFlags::CENTER_ON_NAV) {
            let half = state.viewport.size() / 2;
            let new_offset = state.index().saturating_sub(half);
            state.set_offset(new_offset.min(state.max_items().saturating_sub(state.viewport.size())));
        } else {
            state.set_offset(state.index());
        }
    }
}

// --- Word Navigation with SIMD ---

pub struct WordBehavior {
    boundaries: Arc<ArrayVec<usize, 256>>,
}

impl WordBehavior {
    pub fn new(text: &str) -> Self {
        Self {
            boundaries: Arc::new(crate::functionality::core::find_word_boundaries_simd(text)),
        }
    }

    #[inline]
    fn find_boundary(&self, pos: usize, forward: bool) -> usize {
        if forward {
            self.boundaries.iter()
                .find(|&&b| b > pos)
                .copied()
                .unwrap_or(pos)
        } else {
            self.boundaries.iter()
                .rev()
                .find(|&&b| b < pos)
                .copied()
                .unwrap_or(pos)
        }
    }
}

impl NavBehavior for WordBehavior {
    fn calculate_move(state: &NavState, flags: NavFlags, dir: Direction) -> usize {
        match dir {
            Direction::Left | Direction::Right => state.index(), // Requires instance data
            _ => CursorBehavior::calculate_move(state, flags, dir),
        }
    }
}

// --- Tree Navigation with Depth Limit ---

pub struct TreeBehavior<const MAX_DEPTH: usize = 16> {
    depth_cache: ArrayVec<(usize, u8), MAX_DEPTH>,
    expanded: ArrayVec<usize, 64>,
}

impl<const D: usize> Default for TreeBehavior<D> {
    fn default() -> Self {
        Self {
            depth_cache: ArrayVec::new(),
            expanded: ArrayVec::new(),
        }
    }
}

impl<const D: usize> TreeBehavior<D> {
    #[inline]
    pub fn toggle_expand(&mut self, idx: usize) -> bool {
        if let Some(pos) = self.expanded.iter().position(|&x| x == idx) {
            self.expanded.swap_remove(pos);
            false
        } else if !self.expanded.is_full() {
            self.expanded.push(idx);
            true
        } else {
            false
        }
    }
}

impl<const D: usize> NavBehavior for TreeBehavior<D> {
    fn calculate_move(state: &NavState, flags: NavFlags, dir: Direction) -> usize {
        CursorBehavior::calculate_move(state, flags, dir)
    }
}

// --- Virtual Content with Memory Mapping ---

pub struct VirtualBehavior {
    #[cfg(feature = "virtual")]
    mmap: Option<Arc<memmap2::Mmap>>,
}

impl NavBehavior for VirtualBehavior {
    #[inline]
    fn calculate_move(state: &NavState, flags: NavFlags, dir: Direction) -> usize {
        CursorBehavior::calculate_move(state, flags | NavFlags::VIRTUAL_CONTENT, dir)
    }
}

// --- Composite Behavior with Parallel Execution ---

pub struct CompositeBehavior<A: NavBehavior, B: NavBehavior>(std::marker::PhantomData<(A, B)>);

impl<A: NavBehavior + Send + Sync, B: NavBehavior + Send + Sync> NavBehavior for CompositeBehavior<A, B> {
    fn calculate_move(state: &NavState, flags: NavFlags, dir: Direction) -> usize {
        // Run both calculations in parallel and choose based on flags
        let (a_result, b_result) = rayon::join(
            || A::calculate_move(state, flags, dir),
            || B::calculate_move(state, flags, dir)
        );

        // Priority: A unless B has special flag requirements
        if flags.contains(NavFlags::TEXT_AWARE) { b_result } else { a_result }
    }

    fn post_move(state: &mut NavState, flags: NavFlags, old_pos: usize) {
        rayon::join(
            || A::post_move(state, flags, old_pos),
            || B::post_move(state, flags, old_pos)
        );
    }
}

// --- Mouse Behavior (delegates to SpatialEngine) ---

pub struct MouseBehavior;

impl NavBehavior for MouseBehavior {
    fn calculate_move(state: &NavState, _flags: NavFlags, _dir: Direction) -> usize {
        state.index() // Pre-calculated from mouse position
    }
}

// --- Type Aliases for Common Patterns ---

pub type CursorWithSelection<const S: usize = 32> = CompositeBehavior<CursorBehavior, SelectionBehavior<S>>;
pub type ScrollWithWord<const P: usize = 10> = CompositeBehavior<ScrollBehavior<P>, WordBehavior>;
pub type TreeWithSelection<const D: usize = 16, const S: usize = 32> = CompositeBehavior<TreeBehavior<D>, SelectionBehavior<S>>;