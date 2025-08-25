// Title         : layouts/grid.rs
// Author        : Bardia Samiee
// Project       : Parametric Forge Interface
// License       : MIT
// Path          : interface/src/layouts/grid.rs
// ----------------------------------------------------------------------------

use super::{
    adjust_constraints_for_borders, BorderConnections, BorderSpec, BorderStyle, LayoutCalculation, LayoutResult,
};
use crate::components::ComponentId;
use crate::core::State;
use indexmap::IndexMap;
use ratatui::layout::{Constraint, Direction, Layout as RatatuiLayout, Rect};

// --- Grid Cell Definition ---------------------------------------------------
#[derive(Debug, Clone)]
struct GridCell {
    col: u16,
    row: u16,
    col_span: u16,
    row_span: u16,
}

// --- Grid Layout ------------------------------------------------------------
#[derive(Clone)]
pub struct GridLayout {
    cols: u16,
    rows: u16,
    collapsed_borders: bool,
    cell_mapping: IndexMap<ComponentId, GridCell>,
    col_constraints: Vec<Constraint>,
    row_constraints: Vec<Constraint>,
    spacing: u16,
}

impl GridLayout {
    pub fn new(cols: u16, rows: u16) -> Self {
        // Default to equal distribution
        let col_constraints = (0..cols).map(|_| Constraint::Ratio(1, cols as u32)).collect();
        let row_constraints = (0..rows).map(|_| Constraint::Ratio(1, rows as u32)).collect();

        Self {
            cols,
            rows,
            collapsed_borders: false,
            cell_mapping: IndexMap::with_capacity((cols * rows) as usize), // Pre-allocate for grid size
            col_constraints,
            row_constraints,
            spacing: 1,
        }
    }

    pub fn place(mut self, id: ComponentId, col: u16, row: u16) -> Self {
        self.cell_mapping.insert(
            id,
            GridCell {
                col,
                row,
                col_span: 1,
                row_span: 1,
            },
        );
        self
    }

    pub fn place_span(mut self, id: ComponentId, col: u16, row: u16, col_span: u16, row_span: u16) -> Self {
        self.cell_mapping.insert(
            id,
            GridCell {
                col,
                row,
                col_span,
                row_span,
            },
        );
        self
    }

    pub fn collapsed_borders(mut self, enabled: bool) -> Self {
        self.collapsed_borders = enabled;
        self.spacing = if enabled { 0 } else { 1 };
        self
    }

    pub fn col_constraints(mut self, constraints: Vec<Constraint>) -> Self {
        if constraints.len() == self.cols as usize {
            self.col_constraints = constraints;
        }
        self
    }

    pub fn row_constraints(mut self, constraints: Vec<Constraint>) -> Self {
        if constraints.len() == self.rows as usize {
            self.row_constraints = constraints;
        }
        self
    }

    pub fn spacing(mut self, spacing: u16) -> Self {
        if !self.collapsed_borders {
            self.spacing = spacing;
        }
        self
    }

    // --- Helper: Calculate cell bounds --------------------------------------
    fn calculate_cell_rect(&self, cell: &GridCell, col_areas: &[Rect], row_areas: &[Rect]) -> Option<Rect> {
        let start_col = cell.col as usize;
        let end_col = (cell.col + cell.col_span - 1).min(self.cols - 1) as usize;
        let start_row = cell.row as usize;
        let end_row = (cell.row + cell.row_span - 1).min(self.rows - 1) as usize;

        // Validate bounds
        if start_col >= col_areas.len() || start_row >= row_areas.len() {
            return None;
        }

        let x = col_areas[start_col].x;
        let y = row_areas[start_row].y;

        // Calculate width including spanned columns
        let mut width = 0;
        for col in start_col..=end_col.min(col_areas.len() - 1) {
            width += col_areas[col].width;
            if col < end_col && !self.collapsed_borders {
                width += self.spacing;
            }
        }

        // Calculate height including spanned rows
        let mut height = 0;
        for row in start_row..=end_row.min(row_areas.len() - 1) {
            height += row_areas[row].height;
            if row < end_row && !self.collapsed_borders {
                height += self.spacing;
            }
        }

        Some(Rect { x, y, width, height })
    }
}

impl GridLayout {
    pub fn calculate(&self, area: Rect, state: &State) -> LayoutCalculation {
        let mut result = LayoutResult::new();

        // Calculate column areas with asymmetric splits for collapsed borders
        let col_constraints = if self.collapsed_borders {
            adjust_constraints_for_borders(&self.col_constraints, self.cols)
        } else {
            self.col_constraints.clone()
        };

        let col_layout = RatatuiLayout::default()
            .direction(Direction::Horizontal)
            .constraints(&col_constraints);

        let col_areas = if self.collapsed_borders {
            col_layout.split(area)
        } else {
            col_layout.spacing(self.spacing).split(area)
        };

        // For each column, calculate row divisions
        let mut grid_cells: Vec<Vec<Rect>> = Vec::new();

        for col_area in col_areas.iter() {
            let row_layout = RatatuiLayout::default()
                .direction(Direction::Vertical)
                .constraints(&self.row_constraints);

            let row_areas = if self.collapsed_borders {
                row_layout.split(*col_area)
            } else {
                row_layout.spacing(self.spacing).split(*col_area)
            };

            grid_cells.push(row_areas.to_vec());
        }

        // Map components to their grid positions
        for (id, cell) in &self.cell_mapping {
            // Handle single cells
            if cell.col_span == 1 && cell.row_span == 1 {
                if let Some(column) = grid_cells.get(cell.col as usize) {
                    if let Some(rect) = column.get(cell.row as usize) {
                        result.areas.insert(id.clone(), *rect);
                        result.visible.insert(id.clone());

                        // Generate border spec if collapsed borders enabled
                        if self.collapsed_borders {
                            let border_spec = self.calculate_border_spec(cell);
                            result.add_border(id.clone(), border_spec);
                        }
                    }
                }
            } else {
                // Handle spanning cells
                if let Some(rect) = self.calculate_cell_rect(cell, &col_areas, &grid_cells[0]) {
                    result.areas.insert(id.clone(), rect);
                    result.visible.insert(id.clone());

                    // Generate border spec if collapsed borders enabled
                    if self.collapsed_borders {
                        let border_spec = self.calculate_border_spec(cell);
                        result.add_border(id.clone(), border_spec);
                    }
                }
            }
        }

        // Handle focus if needed
        if let crate::core::Focus::Component(focused_id) = &state.ui.focus {
            if let Some(area) = result.areas.get(focused_id) {
                result.focus_area = Some(*area);
            }
        }

        LayoutCalculation {
            result,
            state_updates: None,
        }
    }
}

// --- Convenience Constructors -----------------------------------------------
impl GridLayout {
    pub fn uniform(cols: u16, rows: u16) -> Self {
        Self::new(cols, rows)
    }

    pub fn dashboard_2x2() -> Self {
        Self::new(2, 2).collapsed_borders(true)
    }

    pub fn dashboard_3x3() -> Self {
        Self::new(3, 3).collapsed_borders(true)
    }

    pub fn with_header(cols: u16, rows: u16) -> Self {
        let mut layout = Self::new(cols, rows + 1);
        layout.row_constraints = std::iter::once(Constraint::Length(3))
            .chain((0..rows).map(|_| Constraint::Ratio(1, rows as u32)))
            .collect();
        layout
    }

    // --- Border Calculation -------------------------------------------------
    // Note: adjust_constraints_for_borders is now shared utility in mod.rs

    fn calculate_border_spec(&self, cell: &GridCell) -> BorderSpec {
        BorderSpec {
            style: BorderStyle::Collapsed,
            connections: BorderConnections {
                right: cell.col + cell.col_span < self.cols && self.has_cell_at(cell.col + cell.col_span, cell.row),
                bottom: cell.row + cell.row_span < self.rows && self.has_cell_at(cell.col, cell.row + cell.row_span),
                left: cell.col > 0 && self.has_cell_at(cell.col - 1, cell.row),
                top: cell.row > 0 && self.has_cell_at(cell.col, cell.row - 1),
            },
        }
    }

    fn has_cell_at(&self, col: u16, row: u16) -> bool {
        self.cell_mapping.values().any(|cell| {
            col >= cell.col && col < cell.col + cell.col_span && row >= cell.row && row < cell.row + cell.row_span
        })
    }
}
