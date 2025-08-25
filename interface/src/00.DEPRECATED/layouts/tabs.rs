// Title         : layouts/tabs.rs
// Author        : Bardia Samiee
// Project       : Parametric Forge Interface
// License       : MIT
// Path          : interface/src/layouts/tabs.rs
// ----------------------------------------------------------------------------

use super::{merge_updates, LayoutCalculation, LayoutResult, LayoutType, TabState};
use crate::core::State;
use ratatui::layout::{Constraint, Direction, Layout as RatatuiLayout, Rect};

// --- Tab Style --------------------------------------------------------------
#[derive(Debug, Clone, Copy)]
pub enum TabStyle {
    Compact,    // Just labels
    WithIcons,  // Icons + labels
    Breadcrumb, // Path-style tabs
}

// --- Tab Layout -------------------------------------------------------------
#[derive(Clone)]
pub struct TabLayout {
    children_layouts: Vec<Option<LayoutType>>,
    bar_height: u16,
    style: TabStyle,
}

impl TabLayout {
    pub fn new() -> Self {
        Self {
            children_layouts: Vec::new(),
            bar_height: 3,
            style: TabStyle::Compact,
        }
    }

    pub fn with_layout(mut self, layout: LayoutType) -> Self {
        self.children_layouts.push(Some(layout));
        self
    }

    pub fn bar_height(mut self, height: u16) -> Self {
        self.bar_height = height;
        self
    }

    pub fn style(mut self, style: TabStyle) -> Self {
        self.style = style;
        self
    }
}

impl TabLayout {
    pub fn calculate(&self, area: Rect, state: &State) -> LayoutCalculation {
        let mut result = LayoutResult::new();
        let mut state_updates = None;

        // Split into tab bar and content area
        let chunks = RatatuiLayout::default()
            .direction(Direction::Vertical)
            .constraints([Constraint::Length(self.bar_height), Constraint::Min(0)])
            .split(area);

        let tab_bar_area = chunks[0];
        let content_area = chunks[1];

        // Use tabs from state's layout
        if let Some((active_id, _)) = state.ui.layout.tabs.current() {
            result.set_tab_state(TabState {
                bar_area: tab_bar_area,
                tabs: state.ui.layout.tabs.tabs.clone(),
                active: state.ui.layout.tabs.selected,
            });

            // Set visibility: only active tab visible
            for (id, _) in &state.ui.layout.tabs.tabs {
                result.set_visible(id.clone(), id == active_id);
            }

            // Calculate layout for active tab's content
            let child_layout = self
                .children_layouts
                .get(state.ui.layout.tabs.selected)
                .and_then(|l| l.as_ref());
            if let Some(child_layout) = child_layout {
                let child_calc = child_layout.calculate(content_area, state);

                // Merge all child results efficiently
                result.areas.extend(child_calc.result.areas);
                result.visible.extend(child_calc.result.visible);
                result.borders.extend(child_calc.result.borders);
                if !child_calc.result.z_order.is_empty() {
                    result.set_z_order(child_calc.result.z_order);
                }
                result.focus_area = child_calc.result.focus_area;
                state_updates = child_calc.state_updates.map(|u| merge_updates(state_updates, u));
            } else {
                // Simple full area for active tab
                result.areas.insert(active_id.clone(), content_area);
                result.visible.insert(active_id.clone());
            }
        }

        LayoutCalculation { result, state_updates }
    }
}
