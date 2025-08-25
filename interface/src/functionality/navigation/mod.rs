// Title         : functionality/navigation/mod.rs
// Author        : Bardia Samiee
// Project       : Parametric Forge
// License       : MIT
// Path          : interface/src/functionality/navigation/mod.rs
// ----------------------------------------------------------------------------
//! Unified navigation functionality for all widgets

mod core;
mod behaviors;
mod nav;
mod selection;
mod word;

// Core exports
pub use core::{Navigator, NavState, NavFlags, NavConfig, NavBehavior};
pub use behaviors::*;

// Re-export Direction from core
pub use crate::functionality::core::Direction;

// Component exports - consolidated navigation
pub use nav::{Nav, CursorNavigation, CursorPosition, ScrollViewport};
pub use selection::{SelectionManager, SelectionRange, SelectionMode};
pub use word::{WordNavigator, WordPosition, WordBoundary, WordNavigationExt};

// Type aliases for convenience
pub type DefaultWordNavigator = WordNavigator<32>;
pub type DefaultSelection = selection::DefaultSelection;

// Universal content traits for composability
pub trait PositionalContent {
    fn position_to_index(&self, pos: (u16, u16), area: (u16, u16, u16, u16)) -> Option<usize>;
}

pub trait TextualContent {
    fn text(&self) -> &str;
    fn char_boundary(&self, index: usize) -> usize;
}

pub trait VirtualContent {
    fn total_items(&self) -> Option<usize>;
    fn load_range(&mut self, start: usize, count: usize);
}

pub trait HierarchicalContent {
    fn is_expanded(&self, index: usize) -> bool;
    fn toggle_expansion(&mut self, index: usize);
    fn depth(&self, index: usize) -> usize;
}

/// Navigation trait for widgets
pub trait Navigable {
    fn item_count(&self) -> usize;
    fn cursor_position(&self) -> usize;
    fn set_cursor_position(&mut self, position: usize);
    fn navigate(&mut self, direction: Direction) -> NavigationResult;
}

/// Navigation operation result
#[derive(Debug, Clone, PartialEq)]
pub enum NavigationResult {
    Moved { from: usize, to: usize },
    AtBoundary,
    NoItems,
}

