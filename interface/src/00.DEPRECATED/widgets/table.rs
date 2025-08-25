// Title         : widgets/table.rs
// Author        : Bardia Samiee
// Project       : Parametric Forge Interface
// License       : MIT
// Path          : interface/src/widgets/table.rs
// ----------------------------------------------------------------------------

//! Advanced table widget with sorting, filtering, and virtualization

use color_eyre::eyre::Result;
use crossterm::event::{Event, KeyCode, KeyModifiers};
use ratatui::{
    layout::{Constraint, Rect},
    style::{Color, Modifier, Style},
    text::{Line, Span},
    widgets::{Row, Table, TableState},
    Frame,
};

use std::sync::mpsc::Sender;

use super::{apply_themed_border, FocusStyle, WidgetConfig, WidgetState};
use crate::components::Component;
use crate::core::Action;
use crate::layouts::BorderSpec;

// --- Table Data Structures --------------------------------------------------

#[derive(Debug, Clone)]
pub struct TableColumn {
    pub header: String,
    pub width: Constraint,
    pub sortable: bool,
    pub filterable: bool,
}

impl TableColumn {
    pub fn new(header: String, width: Constraint) -> Self {
        Self {
            header,
            width,
            sortable: true,
            filterable: true,
        }
    }

    pub fn fixed_width(header: String, width: u16) -> Self {
        Self::new(header, Constraint::Length(width))
    }

    pub fn percentage_width(header: String, percentage: u16) -> Self {
        Self::new(header, Constraint::Percentage(percentage))
    }

    pub fn min_width(header: String, min: u16) -> Self {
        Self::new(header, Constraint::Min(min))
    }

    pub fn not_sortable(mut self) -> Self {
        self.sortable = false;
        self
    }

    pub fn not_filterable(mut self) -> Self {
        self.filterable = false;
        self
    }
}

#[derive(Debug, Clone)]
pub struct TableRow {
    pub cells: Vec<String>,
    pub data: Option<String>, // Optional data payload
}

impl TableRow {
    pub fn new(cells: Vec<String>) -> Self {
        Self { cells, data: None }
    }

    pub fn with_data(mut self, data: String) -> Self {
        self.data = Some(data);
        self
    }
}

// --- Sorting and Filtering ---------------------------------------------------

#[derive(Debug, Clone, PartialEq)]
pub enum SortOrder {
    Ascending,
    Descending,
}

#[derive(Debug, Clone)]
pub struct SortState {
    pub column: Option<usize>,
    pub order: SortOrder,
}

impl Default for SortState {
    fn default() -> Self {
        Self {
            column: None,
            order: SortOrder::Ascending,
        }
    }
}

#[derive(Debug, Clone)]
pub struct FilterState {
    pub query: String,
    pub column: Option<usize>, // None means filter all columns
    pub active: bool,
}

impl Default for FilterState {
    fn default() -> Self {
        Self {
            query: String::new(),
            column: None,
            active: false,
        }
    }
}

// --- Table Configuration ----------------------------------------------------

crate::widget_config! {
    pub struct TableConfig {
        /// Show table header row
        pub show_header: bool = true,
        /// Show row numbers in first column
        pub show_row_numbers: bool = false,
        /// Highlight selected row
        pub highlight_selected: bool = true,
        /// Start virtualizing above this many rows
        pub virtualization_threshold: usize = 1000,
        /// Page size for virtualization
        pub page_size: usize = 100
    }
}

// --- Table State ------------------------------------------------------------

#[derive(Debug, Clone)]
pub struct TableWidgetState {
    pub selected: Option<usize>,
    pub is_focused: bool,
    pub scroll_offset: usize,
    pub sort: SortState,
    pub filter: FilterState,
    pub filtered_indices: Vec<usize>, // Indices of rows that match filter
    pub virtualized_start: usize,
    pub virtualized_end: usize,
}

impl Default for TableWidgetState {
    fn default() -> Self {
        Self {
            selected: None,
            is_focused: false,
            scroll_offset: 0,
            sort: SortState::default(),
            filter: FilterState::default(),
            filtered_indices: Vec::new(),
            virtualized_start: 0,
            virtualized_end: 0,
        }
    }
}

impl WidgetState for TableWidgetState {
    fn reset(&mut self) {
        self.selected = None;
        self.scroll_offset = 0;
        self.sort = SortState::default();
        self.filter = FilterState::default();
        self.filtered_indices.clear();
        self.virtualized_start = 0;
        self.virtualized_end = 0;
    }
}

impl super::FocusManager for TableWidgetState {
    fn is_widget_focused(&self) -> bool {
        self.is_focused
    }

    fn set_widget_focused(&mut self, focused: bool) {
        self.is_focused = focused;
    }
}

impl super::StandardFocusManager for TableWidgetState {
    fn get_selected(&self) -> Option<usize> {
        self.selected
    }

    fn set_selected(&mut self, idx: Option<usize>) {
        self.selected = idx;
    }
}

// --- Table Widget -----------------------------------------------------------

pub struct TableWidget {
    columns: Vec<TableColumn>,
    rows: Vec<TableRow>,
    config: TableConfig,
    state: TableWidgetState,
    table_state: TableState,
    action_tx: Option<Sender<Action>>,
}

impl TableWidget {
    pub fn new(columns: Vec<TableColumn>) -> Self {
        let mut widget = Self {
            columns,
            rows: Vec::new(),
            config: TableConfig::default(),
            state: TableWidgetState::default(),
            table_state: TableState::default(),
            action_tx: None,
        };
        widget.update_filtered_indices();
        widget
    }

    pub fn with_config(mut self, config: TableConfig) -> Self {
        self.config = config;
        self
    }

    pub fn with_rows(mut self, rows: Vec<TableRow>) -> Self {
        self.rows = rows;
        self.update_filtered_indices();
        self.update_virtualization();
        self
    }

    pub fn add_row(&mut self, row: TableRow) {
        self.rows.push(row);
        self.update_filtered_indices();
        self.update_virtualization();
    }

    pub fn clear_rows(&mut self) {
        self.rows.clear();
        self.state.selected = None;
        self.update_filtered_indices();
        self.update_virtualization();
    }

    pub fn selected_row(&self) -> Option<&TableRow> {
        if let Some(selected_idx) = self.state.selected {
            if let Some(&actual_idx) = self.state.filtered_indices.get(selected_idx) {
                return self.rows.get(actual_idx);
            }
        }
        None
    }

    pub fn selected_data(&self) -> Option<String> {
        self.selected_row().and_then(|row| row.data.clone())
    }

    fn update_filtered_indices(&mut self) {
        if self.state.filter.query.is_empty() || !self.state.filter.active {
            // No filter active, include all rows
            self.state.filtered_indices = (0..self.rows.len()).collect();
        } else {
            // Apply filter
            self.state.filtered_indices.clear();
            let query = self.state.filter.query.to_lowercase();

            for (idx, row) in self.rows.iter().enumerate() {
                let matches = if let Some(col_idx) = self.state.filter.column {
                    // Filter specific column
                    row.cells
                        .get(col_idx)
                        .map(|cell| cell.to_lowercase().contains(&query))
                        .unwrap_or(false)
                } else {
                    // Filter all columns
                    row.cells.iter().any(|cell| cell.to_lowercase().contains(&query))
                };

                if matches {
                    self.state.filtered_indices.push(idx);
                }
            }
        }

        // Apply sorting to filtered indices
        self.apply_sort();
    }

    fn apply_sort(&mut self) {
        if let Some(sort_col) = self.state.sort.column {
            if sort_col < self.columns.len() && self.columns[sort_col].sortable {
                let empty_string = String::new();
                self.state.filtered_indices.sort_by(|&a, &b| {
                    let cell_a = self
                        .rows
                        .get(a)
                        .and_then(|row| row.cells.get(sort_col))
                        .unwrap_or(&empty_string);
                    let cell_b = self
                        .rows
                        .get(b)
                        .and_then(|row| row.cells.get(sort_col))
                        .unwrap_or(&empty_string);

                    let cmp = cell_a.cmp(cell_b);
                    match self.state.sort.order {
                        SortOrder::Ascending => cmp,
                        SortOrder::Descending => cmp.reverse(),
                    }
                });
            }
        }
    }

    fn update_virtualization(&mut self) {
        let total_rows = self.state.filtered_indices.len();

        if total_rows <= self.config.virtualization_threshold {
            // No virtualization needed
            self.state.virtualized_start = 0;
            self.state.virtualized_end = total_rows;
        } else {
            // Calculate virtualized window
            let selected = self.state.selected.unwrap_or(0);
            let half_page = self.config.page_size / 2;

            self.state.virtualized_start = selected.saturating_sub(half_page);
            self.state.virtualized_end = (self.state.virtualized_start + self.config.page_size).min(total_rows);

            // Adjust start if we're near the end
            if self.state.virtualized_end == total_rows {
                self.state.virtualized_start = total_rows.saturating_sub(self.config.page_size);
            }
        }
    }

    fn toggle_sort(&mut self, column: usize) {
        if column >= self.columns.len() || !self.columns[column].sortable {
            return;
        }

        if let Some(current_col) = self.state.sort.column {
            if current_col == column {
                // Toggle sort order for same column
                self.state.sort.order = match self.state.sort.order {
                    SortOrder::Ascending => SortOrder::Descending,
                    SortOrder::Descending => SortOrder::Ascending,
                };
            } else {
                // Sort by new column, ascending
                self.state.sort.column = Some(column);
                self.state.sort.order = SortOrder::Ascending;
            }
        } else {
            // First sort
            self.state.sort.column = Some(column);
            self.state.sort.order = SortOrder::Ascending;
        }

        self.apply_sort();
        self.update_virtualization();
    }

    fn render_header(&self) -> Row<'_> {
        let mut cells = Vec::new();

        if self.config.show_row_numbers {
            cells.push("#".to_string());
        }

        for (idx, column) in self.columns.iter().enumerate() {
            let mut header = column.header.clone();

            // Add sort indicator
            if let Some(sort_col) = self.state.sort.column {
                if sort_col == idx {
                    let indicator = match self.state.sort.order {
                        SortOrder::Ascending => " ↑",
                        SortOrder::Descending => " ↓",
                    };
                    header.push_str(indicator);
                }
            }

            cells.push(header);
        }

        Row::new(cells).style(Style::default().add_modifier(Modifier::BOLD))
    }

    fn render_rows(&self) -> Vec<Row<'_>> {
        let mut rendered_rows = Vec::new();

        let start = self.state.virtualized_start;
        let end = self.state.virtualized_end;

        for i in start..end {
            if let Some(&actual_idx) = self.state.filtered_indices.get(i) {
                if let Some(row) = self.rows.get(actual_idx) {
                    let mut cells = Vec::new();

                    if self.config.show_row_numbers {
                        cells.push((i + 1).to_string());
                    }

                    for cell in &row.cells {
                        cells.push(cell.clone());
                    }

                    rendered_rows.push(Row::new(cells));
                }
            }
        }

        rendered_rows
    }

    fn get_column_constraints(&self) -> Vec<Constraint> {
        let mut constraints = Vec::new();

        if self.config.show_row_numbers {
            constraints.push(Constraint::Length(4));
        }

        for column in &self.columns {
            constraints.push(column.width);
        }

        constraints
    }

    /// Check if widget has any items
    fn has_items(&self) -> bool {
        !self.state.filtered_indices.is_empty()
    }
}

// --- NavigableWidget Implementation -----------------------------------------

impl super::NavigableWidget for TableWidget {
    fn get_item_count(&self) -> usize {
        self.state.filtered_indices.len()
    }

    fn get_selected(&self) -> Option<usize> {
        self.state.selected
    }

    fn set_selected(&mut self, idx: Option<usize>) {
        self.state.selected = idx;
        if let Some(selected) = idx {
            self.table_state.select(Some(selected));
        } else {
            self.table_state.select(None);
        }
        self.update_virtualization();
    }
}

impl Component for TableWidget {
    fn register_action_handler(&mut self, tx: Sender<Action>) -> Result<()> {
        self.action_tx = Some(tx);
        Ok(())
    }

    fn can_focus(&self) -> bool {
        self.config.widget.focusable
    }

    fn on_focus(&mut self) -> Result<()> {
        self.state.is_focused = true;
        // Initialize selection if none exists and we have rows
        if self.state.selected.is_none() && !self.state.filtered_indices.is_empty() {
            self.state.selected = Some(0);
            self.table_state.select(Some(0));
            self.update_virtualization();
        }
        Ok(())
    }

    fn on_blur(&mut self) -> Result<()> {
        self.state.is_focused = false;
        Ok(())
    }
    fn event_interest(&self) -> crate::components::EventInterestMask {
        // Use the event profile system for cleaner code
        super::WidgetEventProfile::Interactive.to_mask()
    }

    fn handle_events(&mut self, event: Option<Event>) -> Result<Option<Action>> {
        if let Some(Event::Key(key)) = event {
            match (key.code, key.modifiers) {
                (KeyCode::Enter, _) => {
                    // Select current row
                    if let Some(tx) = &self.action_tx {
                        let _ = tx.send(Action::Select);
                    }
                    Ok(Some(Action::Select))
                }
                (KeyCode::Char('s'), KeyModifiers::CONTROL) => {
                    // Toggle sort on first column (or implement column selection)
                    self.toggle_sort(0);
                    Ok(None)
                }
                (KeyCode::Char('f'), KeyModifiers::CONTROL) => {
                    // Toggle filter mode
                    self.state.filter.active = !self.state.filter.active;
                    if !self.state.filter.active {
                        self.state.filter.query.clear();
                        self.update_filtered_indices();
                        self.update_virtualization();
                    }
                    Ok(None)
                }
                (KeyCode::Char(c), _) if self.state.filter.active => {
                    // Add character to filter
                    self.state.filter.query.push(c);
                    self.update_filtered_indices();
                    self.update_virtualization();
                    Ok(None)
                }
                (KeyCode::Backspace, _) if self.state.filter.active => {
                    // Remove character from filter
                    self.state.filter.query.pop();
                    self.update_filtered_indices();
                    self.update_virtualization();
                    Ok(None)
                }
                _ => {
                    // Let core handle standard navigation
                    Ok(None)
                }
            }
        } else {
            Ok(None)
        }
    }

    fn update(&mut self, action: Action) -> Result<Option<Action>> {
        match action {
            Action::Move(direction) => {
                super::NavigableWidget::navigate(self, direction);
                Ok(None)
            }
            _ => Ok(None),
        }
    }

    fn draw(&mut self, frame: &mut Frame, area: Rect, border: Option<&BorderSpec>) -> Result<()> {
        let theme = &self.config.widget.theme;
        let title = self.config.widget.title.as_deref();

        let render_area = apply_themed_border(frame, area, border, theme, self.state.is_focused, title);

        let header = if self.config.show_header {
            Some(self.render_header())
        } else {
            None
        };

        let rows = self.render_rows();
        let constraints = self.get_column_constraints();

        let style = FocusStyle::text(theme, self.state.is_focused, false);

        let highlight_style = if self.config.highlight_selected {
            FocusStyle::selection(theme, self.state.is_focused)
        } else {
            Style::default()
        };

        let table = Table::new(rows, constraints)
            .style(style)
            .row_highlight_style(highlight_style);

        let table = if let Some(header) = header {
            table.header(header)
        } else {
            table
        };

        // Render filter status if active
        if self.state.filter.active && !self.state.filter.query.is_empty() {
            let filter_line = Line::from(vec![
                Span::styled("Filter: ", Style::default().fg(Color::Yellow)),
                Span::raw(self.state.filter.query.clone()),
            ]);

            if render_area.height > 1 {
                frame.render_widget(
                    ratatui::widgets::Paragraph::new(filter_line),
                    Rect {
                        x: render_area.x,
                        y: render_area.y + render_area.height - 1,
                        width: render_area.width,
                        height: 1,
                    },
                );

                // Adjust table area to account for filter line
                let table_area = Rect {
                    x: render_area.x,
                    y: render_area.y,
                    width: render_area.width,
                    height: render_area.height - 1,
                };

                let mut table_state = self.table_state.clone();
                frame.render_stateful_widget(table, table_area, &mut table_state);
                self.table_state = table_state;
            } else {
                let mut table_state = self.table_state.clone();
                frame.render_stateful_widget(table, render_area, &mut table_state);
                self.table_state = table_state;
            }
        } else {
            let mut table_state = self.table_state.clone();
            frame.render_stateful_widget(table, render_area, &mut table_state);
            self.table_state = table_state;
        }

        Ok(())
    }
}
