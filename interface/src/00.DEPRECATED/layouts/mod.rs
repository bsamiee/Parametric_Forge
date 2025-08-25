// Title         : layouts/mod.rs
// Author        : Bardia Samiee
// Project       : Parametric Forge Interface
// License       : MIT
// Path          : interface/src/layouts/mod.rs
// ----------------------------------------------------------------------------

mod builder;
mod grid;
mod tabs;

pub use builder::LayoutBuilder;
pub use grid::GridLayout;
pub use tabs::TabLayout;

use crate::components::ComponentId;
use crate::core::{LayoutStateUpdates, State};
use indexmap::IndexMap;
use ratatui::layout::{Constraint, Direction, Layout as RatatuiLayout, Rect};
use std::collections::HashSet;

// --- Layout Enum (Static Dispatch) -----------------------------------------
#[derive(Clone)]
pub enum LayoutType {
    Builder(LayoutBuilder),
    Grid(GridLayout),
    Tabs(TabLayout),
}

impl LayoutType {
    pub fn calculate(&self, area: Rect, state: &State) -> LayoutCalculation {
        match self {
            LayoutType::Builder(layout) => layout.calculate(area, state),
            LayoutType::Grid(layout) => layout.calculate(area, state),
            LayoutType::Tabs(layout) => layout.calculate(area, state),
        }
    }
}

// --- Layout Calculation Result ----------------------------------------------
#[derive(Debug)]
pub struct LayoutCalculation {
    pub result: LayoutResult,
    pub state_updates: Option<LayoutStateUpdates>,
}

// --- Border Specification ---------------------------------------------------
#[derive(Debug, Clone, Copy, PartialEq)]
pub enum BorderStyle {
    Normal,
    Collapsed,
    Hidden,
}

#[derive(Debug, Clone, Default)]
pub struct BorderConnections {
    pub top: bool,
    pub bottom: bool,
    pub left: bool,
    pub right: bool,
}

#[derive(Debug, Clone)]
pub struct BorderSpec {
    pub style: BorderStyle,
    pub connections: BorderConnections,
}

// --- Tab State --------------------------------------------------------------
#[derive(Debug, Clone)]
pub struct TabState {
    pub bar_area: Rect,
    pub tabs: Vec<(ComponentId, String)>,
    pub active: usize,
}

// --- Layout Result ----------------------------------------------------------
#[derive(Debug)]
pub struct LayoutResult {
    pub areas: IndexMap<ComponentId, Rect>,
    pub visible: HashSet<ComponentId>,
    pub z_order: Vec<ComponentId>,
    pub borders: IndexMap<ComponentId, BorderSpec>,
    pub focus_area: Option<Rect>,
    pub tab_state: Option<TabState>,
}

impl LayoutResult {
    pub fn new() -> Self {
        Self {
            areas: IndexMap::with_capacity(8),   // Typical: <8 component areas
            visible: HashSet::with_capacity(8),  // Typical: <8 visible components
            z_order: Vec::with_capacity(8),      // Typical: <8 z-ordered components
            borders: IndexMap::with_capacity(8), // Typical: <8 bordered components
            focus_area: None,
            tab_state: None,
        }
    }

    pub fn set_visible(&mut self, id: ComponentId, visible: bool) {
        if visible {
            self.visible.insert(id);
        } else {
            self.visible.remove(&id);
        }
    }

    pub fn set_z_order(&mut self, order: Vec<ComponentId>) {
        self.z_order = order;
    }

    pub fn add_border(&mut self, id: ComponentId, spec: BorderSpec) {
        self.borders.insert(id, spec);
    }

    pub fn set_tab_state(&mut self, state: TabState) {
        self.tab_state = Some(state);
    }
}

// --- Layout Cache -----------------------------------------------------------
#[derive(Debug)]
pub struct LayoutCache {
    pub last_area: Option<Rect>,
    pub last_state_hash: Option<u64>,
    pub cached_calculation: Option<LayoutCalculation>,
}

impl LayoutCache {
    pub fn new() -> Self {
        Self {
            last_area: None,
            last_state_hash: None,
            cached_calculation: None,
        }
    }

    pub fn get_or_calculate<F>(&mut self, area: Rect, state_hash: u64, calculate_fn: F) -> &LayoutCalculation
    where
        F: FnOnce() -> LayoutCalculation,
    {
        let needs_recalc = self.last_area != Some(area) || self.last_state_hash != Some(state_hash);

        if needs_recalc {
            self.cached_calculation = Some(calculate_fn());
            self.last_area = Some(area);
            self.last_state_hash = Some(state_hash);
        }

        self.cached_calculation.as_ref().unwrap()
    }

    pub fn invalidate(&mut self) {
        self.cached_calculation = None;
        self.last_area = None;
        self.last_state_hash = None;
    }
}

// --- Shared Layout Utilities -----------------------------------------------

/// Merge layout state updates from multiple sources
pub fn merge_updates(existing: Option<LayoutStateUpdates>, new: LayoutStateUpdates) -> LayoutStateUpdates {
    match existing {
        Some(mut updates) => {
            if new.tab_selection.is_some() {
                updates.tab_selection = new.tab_selection;
            }
            updates.expanded_panels.extend(new.expanded_panels);
            updates.collapsed_borders.extend(new.collapsed_borders);
            updates
        }
        None => new,
    }
}

/// Create centered rectangle for modals and popups
pub fn centered_rect(percent_x: u16, percent_y: u16, r: Rect) -> Rect {
    let popup_layout = RatatuiLayout::default()
        .direction(Direction::Vertical)
        .constraints([
            Constraint::Percentage((100 - percent_y) / 2),
            Constraint::Percentage(percent_y),
            Constraint::Percentage((100 - percent_y) / 2),
        ])
        .split(r);

    RatatuiLayout::default()
        .direction(Direction::Horizontal)
        .constraints([
            Constraint::Percentage((100 - percent_x) / 2),
            Constraint::Percentage(percent_x),
            Constraint::Percentage((100 - percent_x) / 2),
        ])
        .split(popup_layout[1])[1]
}

/// Adjust constraints for collapsed borders with optimal distribution
pub fn adjust_constraints_for_borders(constraints: &[Constraint], count: u16) -> Vec<Constraint> {
    constraints
        .iter()
        .enumerate()
        .map(|(i, c)| {
            let ratio = if i < count as usize - 1 { 49 } else { 51 };
            match c {
                Constraint::Percentage(p) => Constraint::Percentage((p * ratio) / 50),
                Constraint::Ratio(n, d) => Constraint::Ratio((((*n as u16) * ratio) / 50) as u32, *d),
                _ => *c,
            }
        })
        .collect()
}
