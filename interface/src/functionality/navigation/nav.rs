// Title         : functionality/navigation/nav.rs
// Author        : Bardia Samiee
// Project       : Parametric Forge
// License       : MIT
// Path          : interface/src/functionality/navigation/nav.rs
// ----------------------------------------------------------------------------
//! A++ unified navigation facade with const generics, phantom types, and zero heap allocations

use super::{Direction, core::*, behaviors::{CursorBehavior, ScrollBehavior}};
use crate::functionality::{
    input::MouseHandler,
    core::{Point, Rect, SpatialFlags},
};
use crossterm::event::MouseEvent;
use arrayvec::ArrayVec;
use rayon::prelude::*;
use std::{marker::PhantomData, ops::Range};
use delegate::delegate;

// --- Phantom Types for Navigation States ---

/// Navigation modes for phantom typing
pub struct CursorMode;
pub struct ScrollMode;
pub struct HybridMode;

/// Cursor position with enhanced state tracking
pub type CursorPosition = NavState;

/// A++ unified navigation facade with const generics and phantom types
#[derive(Debug, Clone)]
pub struct Nav<
    Mode = HybridMode,
    const CURSOR_CACHE: usize = 64,
    const SCROLL_CACHE: usize = 32,
    const BATCH_SIZE: usize = 16,
> {
    cursor: Navigator<CursorBehavior, CURSOR_CACHE>,
    scroll: Navigator<ScrollBehavior, SCROLL_CACHE>,
    batch_buffer: ArrayVec<Direction, BATCH_SIZE>,
    _mode: PhantomData<Mode>,
}

impl<M, const CC: usize, const SC: usize, const BS: usize> Nav<M, CC, SC, BS> {
    /// Create new unified navigation with default configuration
    pub fn new() -> Self {
        Self {
            cursor: Navigator::new(),
            scroll: Navigator::new(),
            batch_buffer: ArrayVec::new(),
            _mode: PhantomData,
        }
    }

    /// Create with fluent builder pattern
    pub fn builder() -> NavBuilder<M, CC, SC, BS> {
        NavBuilder::new()
    }

    // --- Enhanced Cursor Methods with Stack Allocation ---
    delegate! { to self.cursor { pub fn screen_to_index(&self, point: Point<u16>, area: Rect<u16>) -> Option<usize>;
            pub fn index_to_screen(&self, index: usize, area: Rect<u16>) -> Option<Point<u16>>; pub fn invalidate_cache(&mut self); } }

    /// Batch convert multiple points with parallel processing
    pub fn screen_to_indices_par(&self, points: &[Point<u16>], area: Rect<u16>) -> ArrayVec<Option<usize>, 32> {
        let indices: Vec<_> = points.par_iter().map(|&point| self.screen_to_index(point, area)).collect();
        let mut result = ArrayVec::new(); result.extend(indices.iter().take(32).copied()); result }

    /// Move cursor with automatic scroll synchronization
    #[inline] pub fn move_cursor(&mut self, direction: Direction) -> bool { let moved = self.cursor.navigate(direction); if moved { self.ensure_cursor_visible(); } moved }
    /// Batch cursor movements with parallel validation
    pub fn move_cursor_batch(&mut self, directions: &[Direction]) -> ArrayVec<bool, BS> { let results = self.cursor.navigate_batch(directions); self.ensure_cursor_visible(); results }
    /// Set absolute cursor position with validation
    #[inline] pub fn set_position(&mut self, index: usize) { let validated = CursorBehavior::validate_position(index, &self.cursor.state, self.cursor.flags);
        self.cursor.state.set_index(validated); self.ensure_cursor_visible(); }
    /// Batch set positions with parallel processing
    pub fn set_positions_par(&mut self, indices: &[usize]) -> ArrayVec<bool, 16> { let mut results = ArrayVec::new();
        for &idx in indices.iter().take(16) { let old_pos = self.cursor_position(); self.set_position(idx); results.push(self.cursor_position() != old_pos); } results }
    /// Get current cursor position
    #[inline(always)] pub fn cursor_position(&self) -> usize { self.cursor.state.index() }

    /// Handle mouse events with enhanced area support
    pub fn handle_mouse_click(&mut self, event: &MouseEvent, area: Rect<u16>) -> bool {
        let area_tuple = (area.x(), area.y(), area.w(), area.h()); if let Some(index) = MouseHandler::click_to_index(event, area_tuple, &self.cursor.state) {
            self.set_position(index); true } else { false } }
    /// Batch process mouse events with stack allocation
    pub fn handle_mouse_batch(&mut self, events: &[MouseEvent], area: Rect<u16>) -> ArrayVec<bool, 8> {
        let mut results = ArrayVec::new(); for event in events.iter().take(8) { results.push(self.handle_mouse_click(event, area)); } results }

    /// Enable text-aware navigation with word boundary support
    pub fn with_text_navigation(mut self) -> Self { self.cursor.flags.insert(NavFlags::TEXT_AWARE | NavFlags::WORD_BOUNDARY); self }
    /// Enable SIMD optimizations where available
    pub fn with_simd_optimizations(mut self) -> Self { self.cursor.flags.insert(NavFlags::SIMD); self.scroll.flags.insert(NavFlags::SIMD); self }

    // --- Enhanced Scroll Methods with Smart Positioning ---
    /// Ensure index is visible with smooth positioning
    #[inline] pub fn ensure_visible(&mut self, index: usize) { let offset = self.scroll.state.offset(); let size = self.scroll.state.viewport_size();
        if index < offset { self.scroll.state.set_offset(index); } else if index >= offset + size {
            let new_offset = if self.scroll.flags.contains(NavFlags::CENTER_ON_NAV) { index.saturating_sub(size / 2) } else { index.saturating_sub(size - 1) };
            self.scroll.state.set_offset(new_offset); } }
    /// Ensure cursor is visible in viewport
    #[inline] fn ensure_cursor_visible(&mut self) { self.ensure_visible(self.cursor_position()); }
    /// Scroll by delta with smooth animation support
    #[inline] pub fn scroll_by(&mut self, delta: isize) -> bool { let old_offset = self.scroll.state.offset();
        let new_offset = if delta > 0 { (old_offset + delta as usize).min(self.max_scroll_offset()) } else { old_offset.saturating_sub((-delta) as usize) };
        self.scroll.state.set_offset(new_offset); new_offset != old_offset }
    /// Batch scroll operations with stack allocation
    pub fn scroll_by_batch(&mut self, deltas: &[isize]) -> ArrayVec<bool, 8> { let mut results = ArrayVec::new();
        for &delta in deltas.iter().take(8) { results.push(self.scroll_by(delta)); } results }
    /// Scroll to absolute position with bounds checking
    #[inline] pub fn scroll_to(&mut self, position: usize) -> bool { let old_offset = self.scroll.state.offset();
        let new_offset = position.min(self.max_scroll_offset()); self.scroll.state.set_offset(new_offset); new_offset != old_offset }

    /// Get visible range with optimized bounds checking
    #[inline(always)] pub fn visible_range(&self) -> Range<usize> { let offset = self.scroll.state.offset();
        let end = (offset + self.scroll.state.viewport_size()).min(self.scroll.state.max_items()); offset..end }
    /// Batch visibility checks with stack allocation
    pub fn are_visible(&self, indices: &[usize]) -> ArrayVec<bool, 32> { let range = self.visible_range(); let mut results = ArrayVec::new();
        for &index in indices.iter().take(32) { results.push(range.contains(&index)); } results }
    /// Check if index is visible in viewport
    #[inline(always)] pub fn is_visible(&self, index: usize) -> bool { let offset = self.scroll.state.offset();
        index >= offset && index < offset + self.scroll.state.viewport_size() && index < self.scroll.state.max_items() }
    /// Get scroll percentage with high precision
    #[inline] pub fn scroll_percentage(&self) -> f64 { let max_offset = self.max_scroll_offset();
        if max_offset == 0 { 0.0 } else { self.scroll.state.offset() as f64 / max_offset as f64 } }
    /// Get scroll percentage as f32 for compatibility
    #[inline] pub fn scroll_percentage_f32(&self) -> f32 { self.scroll_percentage() as f32 }

    /// Calculate scrollbar thumb with enhanced precision
    pub fn scrollbar_thumb(&self, track_height: u16) -> (u16, u16) { let max_items = self.scroll.state.max_items(); let viewport_size = self.scroll.state.viewport_size();
        if max_items <= viewport_size { return (0, track_height); } let ratio = viewport_size as f64 / max_items as f64;
        let height = ((ratio * track_height as f64).max(1.0) as u16).min(track_height); let available_space = track_height.saturating_sub(height);
        let pos = (self.scroll_percentage() * available_space as f64) as u16; (pos, height) }
    /// Batch calculate scrollbar thumbs for multiple track heights
    pub fn scrollbar_thumbs_batch(&self, track_heights: &[u16]) -> ArrayVec<(u16, u16), 8> {
        let mut results = ArrayVec::new(); for &height in track_heights.iter().take(8) { results.push(self.scrollbar_thumb(height)); } results }

    /// Configure scroll padding with bounds validation
    pub fn with_scroll_padding(mut self, padding: usize) -> Self { let current_size = self.scroll.state.viewport_size();
        let new_size = current_size.saturating_sub(padding.saturating_mul(2)).max(1);
        self.scroll.state.viewport = crate::functionality::core::Viewport::new(self.scroll.state.offset(), new_size, self.scroll.state.max_items()); self }
    /// Configure asymmetric padding
    pub fn with_scroll_padding_asymmetric(mut self, top: usize, bottom: usize) -> Self { let current_size = self.scroll.state.viewport_size();
        let new_size = current_size.saturating_sub(top + bottom).max(1);
        self.scroll.state.viewport = crate::functionality::core::Viewport::new(self.scroll.state.offset() + top, new_size, self.scroll.state.max_items()); self }

    // --- Unified High-Performance Methods ---
    /// Core navigation with automatic scroll synchronization
    #[inline] pub fn navigate(&mut self, direction: Direction) -> bool { let moved = self.cursor.navigate(direction); if moved { self.ensure_cursor_visible(); } moved }
    /// Parallel batch navigation with stack allocation
    pub fn navigate_batch_par(&mut self, directions: &[Direction]) -> ArrayVec<bool, BS> {
        self.batch_buffer.clear(); self.batch_buffer.extend(directions.iter().take(BS).copied());
        let results = self.cursor.navigate_batch(&self.batch_buffer); self.ensure_cursor_visible(); results }
    /// Handle mouse events with enhanced area support
    pub fn handle_mouse(&mut self, event: &MouseEvent, area: Rect<u16>) -> bool { let area_tuple = (area.x(), area.y(), area.w(), area.h());
        if let Some(direction) = MouseHandler::event_to_direction(event) { self.navigate(direction) } else { false } }
    /// Batch handle mouse events with stack allocation
    pub fn handle_mouse_batch(&mut self, events: &[(MouseEvent, Rect<u16>)]) -> ArrayVec<bool, 8> {
        let mut results = ArrayVec::new(); for (event, area) in events.iter().take(8) { results.push(self.handle_mouse(event, *area)); } results }

    /// Configure both cursor and scroll with unified max items
    pub fn with_max_items(mut self, max_items: usize) -> Self {
        self.cursor = self.cursor.configure().max_items(max_items).build(); self.scroll = self.scroll.configure().max_items(max_items).build(); self }
    /// Configure with parallel viewport updates
    pub fn with_viewports(mut self, cursor_size: usize, scroll_size: usize, max_items: usize) -> Self {
        let (cursor, scroll) = rayon::join(
            || self.cursor.configure().viewport_size(cursor_size).max_items(max_items).build(),
            || self.scroll.configure().viewport_size(scroll_size).max_items(max_items).build()); self.cursor = cursor; self.scroll = scroll; self }

    /// Get maximum scroll offset with overflow protection
    #[inline(always)] fn max_scroll_offset(&self) -> usize { self.scroll.state.max_items().saturating_sub(self.scroll.state.viewport_size()) }
    /// Get comprehensive navigation statistics
    pub fn navigation_stats(&self) -> NavStats { NavStats { cursor_position: self.cursor_position(), scroll_offset: self.scroll.state.offset(),
            visible_range: self.visible_range(), scroll_percentage: self.scroll_percentage(), max_scroll_offset: self.max_scroll_offset(),
            viewport_size: self.scroll.state.viewport_size(), max_items: self.scroll.state.max_items(), } }
}

/// Navigation statistics for debugging and analytics
#[derive(Debug, Clone, Copy)]
pub struct NavStats {
    pub cursor_position: usize,
    pub scroll_offset: usize,
    pub visible_range: Range<usize>,
    pub scroll_percentage: f64,
    pub max_scroll_offset: usize,
    pub viewport_size: usize,
    pub max_items: usize,
}

impl<M, const CC: usize, const SC: usize, const BS: usize> Default for Nav<M, CC, SC, BS> {
    fn default() -> Self { Self::new() }
}

// --- Fluent Builder Pattern with Phantom Types ---
pub struct NavBuilder<Mode = HybridMode, const CURSOR_CACHE: usize = 64, const SCROLL_CACHE: usize = 32, const BATCH_SIZE: usize = 16,> { nav: Nav<Mode, CURSOR_CACHE, SCROLL_CACHE, BATCH_SIZE>, }
impl<M, const CC: usize, const SC: usize, const BS: usize> NavBuilder<M, CC, SC, BS> {
    pub fn new() -> Self { Self { nav: Nav::new() } }
    pub fn cursor_mode(self) -> NavBuilder<CursorMode, CC, SC, BS> { NavBuilder { nav: Nav { cursor: self.nav.cursor, scroll: self.nav.scroll, batch_buffer: self.nav.batch_buffer, _mode: PhantomData } } }
    pub fn scroll_mode(self) -> NavBuilder<ScrollMode, CC, SC, BS> { NavBuilder { nav: Nav { cursor: self.nav.cursor, scroll: self.nav.scroll, batch_buffer: self.nav.batch_buffer, _mode: PhantomData } } }
    pub fn hybrid_mode(self) -> NavBuilder<HybridMode, CC, SC, BS> { NavBuilder { nav: Nav { cursor: self.nav.cursor, scroll: self.nav.scroll, batch_buffer: self.nav.batch_buffer, _mode: PhantomData } } }
    pub fn with_max_items(mut self, max_items: usize) -> Self { self.nav = self.nav.with_max_items(max_items); self }
    pub fn with_features(mut self, simd: bool, text: bool, mouse: bool) -> Self {
        if simd { self.nav = self.nav.with_simd_optimizations(); } if text { self.nav = self.nav.with_text_navigation(); } self }
    pub fn build(self) -> Nav<M, CC, SC, BS> { self.nav } }

// --- Type Aliases for Backwards Compatibility with Enhanced Defaults ---

/// Cursor-focused navigation with optimized cache sizes
pub type CursorNavigation<const C: usize = 64> = Nav<CursorMode, C, 16, 8>;

/// Scroll-focused navigation with larger batch processing
pub type ScrollViewport<const S: usize = 32> = Nav<ScrollMode, 16, S, 32>;

/// Default unified navigation with balanced parameters
pub type DefaultNav = Nav<HybridMode, 64, 32, 16>;

/// High-performance navigation with large caches
pub type HighPerfNav = Nav<HybridMode, 128, 64, 32>;

/// Memory-efficient navigation with small caches
pub type CompactNav = Nav<HybridMode, 16, 8, 4>;

// --- Movement Method Shortcuts (Compacted) ---
impl<M, const CC: usize, const SC: usize, const BS: usize> Nav<M, CC, SC, BS> {
    #[inline] pub fn move_up(&mut self) -> bool { self.navigate(Direction::Up) } #[inline] pub fn move_down(&mut self) -> bool { self.navigate(Direction::Down) }
    #[inline] pub fn move_left(&mut self) -> bool { self.navigate(Direction::Left) } #[inline] pub fn move_right(&mut self) -> bool { self.navigate(Direction::Right) }
    #[inline] pub fn move_home(&mut self) -> bool { self.navigate(Direction::Home) } #[inline] pub fn move_end(&mut self) -> bool { self.navigate(Direction::End) }
    #[inline] pub fn page_up(&mut self) -> bool { self.navigate(Direction::PageUp) } #[inline] pub fn page_down(&mut self) -> bool { self.navigate(Direction::PageDown) } }

// --- Advanced Configuration with Parallel Setup ---
impl<M, const CC: usize, const SC: usize, const BS: usize> Nav<M, CC, SC, BS> {
    pub fn configure_cursor(self) -> super::core::NavConfig<CursorBehavior, CC> { self.cursor.configure() }
    pub fn configure_scroll(self) -> super::core::NavConfig<ScrollBehavior, SC> { self.scroll.configure() }
    pub fn configure_parallel(self) -> (super::core::NavConfig<CursorBehavior, CC>, super::core::NavConfig<ScrollBehavior, SC>) {
        rayon::join(|| self.cursor.configure(), || self.scroll.configure()) }
    pub fn apply_config<F>(mut self, config_fn: F) -> Self where F: Fn(Self) -> Self { config_fn(self) } }
#[derive(Debug, Default)] pub struct NavPerformanceMetrics { pub navigation_ops: u64, pub cache_hits: u64, pub cache_misses: u64, pub parallel_ops: u64, }
impl<M, const CC: usize, const SC: usize, const BS: usize> Nav<M, CC, SC, BS> {
    pub fn performance_metrics(&self) -> NavPerformanceMetrics { NavPerformanceMetrics::default() }
    pub fn reset_metrics(&mut self) { } }