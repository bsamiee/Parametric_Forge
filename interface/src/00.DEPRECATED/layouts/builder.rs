// Title         : layouts/builder.rs
// Author        : Bardia Samiee
// Project       : Parametric Forge Interface
// License       : MIT
// Path          : interface/src/layouts/builder.rs
// ----------------------------------------------------------------------------

use super::{centered_rect, merge_updates, LayoutCalculation, LayoutResult, LayoutType};
use crate::components::ComponentId;
use crate::core::{Focus, LayoutStateUpdates, State};
use indexmap::IndexMap;
use ratatui::layout::{Constraint, Direction, Layout as RatatuiLayout, Rect};

// --- Visibility Rules -------------------------------------------------------
#[derive(Clone)]
pub enum VisibilityRule {
    Always,
    Never,
    WhenWidthGreaterThan(u16),
    WhenHeightGreaterThan(u16),
    Custom(fn(&State, &Rect) -> bool),
}

// --- Layer Support ----------------------------------------------------------
#[derive(Clone)]
pub struct Layer {
    pub components: Vec<ComponentId>,
    pub mode: LayerMode,
}

#[derive(Clone)]
pub enum LayerMode {
    Stack,       // All components in same area
    Float(Rect), // Floating at specific position
    Modal,       // Centered with backdrop
}

// --- Expand Modes -----------------------------------------------------------
#[derive(Clone)]
pub enum ExpandMode {
    Focus(ComponentId),    // Expand one, minimize others
    Maximize(ComponentId), // Full screen one component
    Balanced,              // Equal distribution
}

// --- Layout Builder ---------------------------------------------------------
#[derive(Clone)]
pub struct LayoutBuilder {
    direction: Direction,
    constraints: Vec<(ComponentId, Constraint)>,
    margin: u16,
    spacing: u16,
    children: IndexMap<ComponentId, LayoutType>,
    visibility: IndexMap<ComponentId, VisibilityRule>,
    z_layers: Vec<Layer>,
    expand_mode: Option<ExpandMode>,
}

impl LayoutBuilder {
    pub fn new(direction: Direction) -> Self {
        Self {
            direction,
            constraints: Vec::with_capacity(4), // Typical: 3-4 layout segments
            margin: 0,
            spacing: 0,
            children: IndexMap::with_capacity(4),   // Typical: 3-4 child layouts
            visibility: IndexMap::with_capacity(4), // Typical: 3-4 visibility rules
            z_layers: Vec::with_capacity(2),        // Typical: 1-2 layers
            expand_mode: None,
        }
    }

    pub fn add(mut self, id: ComponentId, constraint: Constraint) -> Self {
        self.constraints.push((id, constraint));
        self
    }

    pub fn add_child(mut self, id: ComponentId, constraint: Constraint, layout: LayoutType) -> Self {
        self.constraints.push((id.clone(), constraint));
        self.children.insert(id, layout);
        self
    }

    pub fn margin(mut self, margin: u16) -> Self {
        self.margin = margin;
        self
    }

    pub fn spacing(mut self, spacing: u16) -> Self {
        self.spacing = spacing;
        self
    }

    pub fn with_visibility(mut self, id: ComponentId, rule: VisibilityRule) -> Self {
        self.visibility.insert(id, rule);
        self
    }

    pub fn add_layer(mut self, layer: Layer) -> Self {
        self.z_layers.push(layer);
        self
    }

    pub fn with_expand_mode(mut self, mode: ExpandMode) -> Self {
        self.expand_mode = Some(mode);
        self
    }

    // --- Dynamic Adjustments ------------------------------------------------
    pub fn responsive(mut self, area: Rect) -> Self {
        // Adjust constraints based on terminal size
        if area.width < 80 {
            // Compact mode - stack vertically
            self.direction = Direction::Vertical;
            self.spacing = 0;
        } else if area.width < 120 {
            // Standard mode
            self.spacing = 1;
        } else {
            // Wide mode - more spacing
            self.spacing = 2;
        }
        self
    }

    pub fn with_focus(mut self, focus: &ComponentId, expand_ratio: u16) -> Self {
        // Dynamically adjust constraints to expand focused component
        let total_components = self.constraints.len() as u16;
        self.constraints = self
            .constraints
            .into_iter()
            .map(|(id, _constraint)| {
                if &id == focus {
                    // Expand focused component
                    (id, Constraint::Percentage(expand_ratio.min(90)))
                } else {
                    // Minimize others
                    let remaining = (100 - expand_ratio) / (total_components - 1);
                    (id, Constraint::Percentage(remaining.max(5)))
                }
            })
            .collect();
        self
    }
}

impl LayoutBuilder {
    pub fn calculate(&self, area: Rect, state: &State) -> LayoutCalculation {
        let mut result = LayoutResult::new();
        let mut z_order = Vec::new();
        let mut state_updates = None;

        // Apply expand mode if set
        let effective_constraints = if let Some(ref expand_mode) = self.expand_mode {
            // Track expansion state changes
            let mut updates = LayoutStateUpdates {
                tab_selection: None,
                expanded_panels: Vec::new(),
                collapsed_borders: Vec::new(),
            };

            match expand_mode {
                ExpandMode::Focus(id) | ExpandMode::Maximize(id) => {
                    updates.expanded_panels.push((id.clone(), true));
                }
                _ => {}
            }

            if !updates.expanded_panels.is_empty() {
                state_updates = Some(updates);
            }

            self.apply_expand_mode(expand_mode)
        } else {
            self.constraints.clone()
        };

        // Filter visible components
        let visible_constraints: Vec<(ComponentId, Constraint)> = effective_constraints
            .into_iter()
            .filter(|(id, _)| self.is_visible(id, state, &area))
            .collect();

        // Extract just the constraints for Ratatui
        let constraints: Vec<Constraint> = visible_constraints.iter().map(|(_, c)| *c).collect();

        // Calculate areas using Ratatui's layout engine
        if !constraints.is_empty() {
            let areas = RatatuiLayout::default()
                .direction(self.direction)
                .margin(self.margin)
                .constraints(&constraints)
                .split(area);

            // Map calculated areas to component IDs
            for (i, (id, _)) in visible_constraints.iter().enumerate() {
                if let Some(area) = areas.get(i) {
                    // If this component has a child layout, recurse
                    if let Some(child_layout) = self.children.get(id) {
                        let child_calc = child_layout.calculate(*area, state);
                        // Merge child areas into our result
                        for (child_id, child_area) in child_calc.result.areas {
                            result.areas.insert(child_id.clone(), child_area);
                            result.visible.insert(child_id.clone());
                            z_order.push(child_id);
                        }
                        if let Some(focus) = child_calc.result.focus_area {
                            result.focus_area = Some(focus);
                        }
                        // Merge child state updates
                        if let Some(child_updates) = child_calc.state_updates {
                            state_updates = Some(merge_updates(state_updates, child_updates));
                        }
                    } else {
                        result.areas.insert(id.clone(), *area);
                        result.visible.insert(id.clone());
                        z_order.push(id.clone());
                    }
                }
            }
        }

        // Process layers (stack/modal/float)
        for layer in &self.z_layers {
            self.process_layer(layer, area, state, &mut result, &mut z_order);
        }

        // Set final z-order
        if !z_order.is_empty() {
            result.set_z_order(z_order);
        }

        // Handle focus area if component has focus
        if let Focus::Component(focused_id) = &state.ui.focus {
            if let Some(area) = result.areas.get(focused_id) {
                result.focus_area = Some(*area);
            }
        }

        LayoutCalculation { result, state_updates }
    }
}

// --- Convenience Constructors -----------------------------------------------
impl LayoutBuilder {
    pub fn vertical() -> Self {
        Self::new(Direction::Vertical)
    }

    pub fn horizontal() -> Self {
        Self::new(Direction::Horizontal)
    }

    pub fn split_horizontal(left: ComponentId, right: ComponentId, ratio: u16) -> Self {
        Self::horizontal()
            .add(left, Constraint::Percentage(ratio))
            .add(right, Constraint::Percentage(100 - ratio))
    }

    pub fn split_vertical(top: ComponentId, bottom: ComponentId, ratio: u16) -> Self {
        Self::vertical()
            .add(top, Constraint::Percentage(ratio))
            .add(bottom, Constraint::Percentage(100 - ratio))
    }

    pub fn with_header_footer(main: ComponentId, header_height: u16, footer_height: u16) -> Self {
        Self::vertical()
            .add(ComponentId::Header, Constraint::Length(header_height))
            .add(main, Constraint::Min(0))
            .add(ComponentId::Footer, Constraint::Length(footer_height))
    }

    // --- Helper Methods -----------------------------------------------------
    fn is_visible(&self, id: &ComponentId, state: &State, area: &Rect) -> bool {
        self.visibility.get(id).map_or(true, |rule| match rule {
            VisibilityRule::Always => true,
            VisibilityRule::Never => false,
            VisibilityRule::WhenWidthGreaterThan(min) => area.width > *min,
            VisibilityRule::WhenHeightGreaterThan(min) => area.height > *min,
            VisibilityRule::Custom(f) => f(state, area),
        })
    }

    fn apply_expand_mode(&self, mode: &ExpandMode) -> Vec<(ComponentId, Constraint)> {
        let count = self.constraints.len() as u16;
        match mode {
            ExpandMode::Focus(focused_id) => {
                let other_pct = 20 / (count - 1);
                self.constraints
                    .iter()
                    .map(|(id, _)| {
                        (
                            id.clone(),
                            if id == focused_id {
                                Constraint::Percentage(80)
                            } else {
                                Constraint::Percentage(other_pct)
                            },
                        )
                    })
                    .collect()
            }
            ExpandMode::Maximize(maximized_id) => self
                .constraints
                .iter()
                .filter_map(|(id, _)| (id == maximized_id).then(|| (id.clone(), Constraint::Percentage(100))))
                .collect(),
            ExpandMode::Balanced => {
                let pct = 100 / count;
                self.constraints
                    .iter()
                    .map(|(id, _)| (id.clone(), Constraint::Percentage(pct)))
                    .collect()
            }
        }
    }

    fn process_layer(
        &self,
        layer: &Layer,
        area: Rect,
        state: &State,
        result: &mut LayoutResult,
        z_order: &mut Vec<ComponentId>,
    ) {
        let layer_area = match layer.mode {
            LayerMode::Stack => area,
            LayerMode::Float(rect) => rect,
            LayerMode::Modal => centered_rect(60, 60, area),
        };

        for id in &layer.components {
            if self.is_visible(id, state, &layer_area) {
                result.areas.insert(id.clone(), layer_area);
                result.visible.insert(id.clone());
                z_order.push(id.clone());
            }
        }
    }
}
