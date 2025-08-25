// Title         : widgets/list.rs
// Author        : Bardia Samiee
// Project       : Parametric Forge Interface
// License       : MIT
// Path          : interface/src/widgets/list.rs
// ----------------------------------------------------------------------------

//! Advanced list widget with selection, filtering, and virtualization

use color_eyre::eyre::Result;
use crossterm::event::{Event, KeyCode, KeyModifiers};
use ratatui::{
    layout::{Constraint, Direction as LayoutDirection, Layout, Rect},
    style::{Color, Modifier, Style},
    text::{Line, Span},
    widgets::{Block, Borders, List, ListItem, ListState, Paragraph},
    Frame,
};
use std::collections::HashSet;
use std::sync::mpsc::Sender;

use super::{apply_border, FocusManager, WidgetConfig, WidgetState};
use crate::components::{Component, StatefulComponent};
use crate::core::{Action, Direction};
use crate::layouts::BorderSpec;

// --- List Configuration -----------------------------------------------------

crate::widget_config! {
    pub struct ListConfig {
        pub multi_select: bool = false,
        pub searchable: bool = true,
        pub filterable: bool = true,
        pub virtualized: bool = true,
        pub page_size: usize = 100
    }
}

// --- List State -------------------------------------------------------------

#[derive(Debug, Clone)]
pub struct ListWidgetState {
    pub selected: Option<usize>,
    pub multi_selected: HashSet<usize>,
    pub search_query: String,
    pub search_active: bool,
    pub filtered_indices: Vec<usize>,
    pub scroll_offset: usize,
    pub viewport_size: usize,
    pub is_focused: bool,
}

impl Default for ListWidgetState {
    fn default() -> Self {
        Self {
            selected: None,
            multi_selected: HashSet::new(),
            search_query: String::new(),
            search_active: false,
            filtered_indices: Vec::new(),
            scroll_offset: 0,
            viewport_size: 0,
            is_focused: false,
        }
    }
}

impl WidgetState for ListWidgetState {
    fn reset(&mut self) {
        *self = Self::default();
    }

    fn is_dirty(&self) -> bool {
        self.selected.is_some() || !self.multi_selected.is_empty() || !self.search_query.is_empty()
    }
}

impl super::FocusManager for ListWidgetState {
    fn is_widget_focused(&self) -> bool {
        self.is_focused
    }

    fn set_widget_focused(&mut self, focused: bool) {
        self.is_focused = focused;
    }
}

impl super::StandardFocusManager for ListWidgetState {
    fn get_selected(&self) -> Option<usize> {
        self.selected
    }

    fn set_selected(&mut self, idx: Option<usize>) {
        self.selected = idx;
    }
}

// --- List Item --------------------------------------------------------------

#[derive(Debug, Clone)]
pub struct ListItemData {
    pub text: String,
    pub value: String,
    pub searchable_text: String,
    pub selectable: bool,
}

impl ListItemData {
    pub fn new(text: String) -> Self {
        let searchable_text = text.to_lowercase();
        Self {
            value: text.clone(),
            searchable_text,
            text,
            selectable: true,
        }
    }

    pub fn with_value(text: String, value: String) -> Self {
        let searchable_text = text.to_lowercase();
        Self {
            text,
            value,
            searchable_text,
            selectable: true,
        }
    }

    pub fn matches_search(&self, query: &str) -> bool {
        if query.is_empty() {
            return true;
        }
        self.searchable_text.contains(&query.to_lowercase())
    }
}

// --- List Widget ------------------------------------------------------------

pub struct ListWidget {
    items: Vec<ListItemData>,
    state: ListWidgetState,
    config: ListConfig,
    action_tx: Option<Sender<Action>>,
    ratatui_state: ListState,
}

impl ListWidget {
    pub fn new(items: Vec<ListItemData>) -> Self {
        let mut widget = Self {
            items,
            state: ListWidgetState::default(),
            config: ListConfig::default(),
            action_tx: None,
            ratatui_state: ListState::default(),
        };
        widget.update_filtered_indices();
        widget
    }

    pub fn with_config(items: Vec<ListItemData>, config: ListConfig) -> Self {
        let mut widget = Self {
            items,
            state: ListWidgetState::default(),
            config,
            action_tx: None,
            ratatui_state: ListState::default(),
        };
        widget.update_filtered_indices();
        widget
    }

    // --- Data Management ----------------------------------------------------

    pub fn set_items(&mut self, items: Vec<ListItemData>) {
        self.items = items;
        self.state.selected = None;
        self.state.multi_selected.clear();
        self.update_filtered_indices();
    }

    pub fn add_item(&mut self, item: ListItemData) {
        self.items.push(item);
        self.update_filtered_indices();
    }

    pub fn get_selected_item(&self) -> Option<&ListItemData> {
        self.state
            .selected
            .and_then(|idx| self.state.filtered_indices.get(idx))
            .and_then(|&real_idx| self.items.get(real_idx))
    }

    pub fn get_selected_items(&self) -> Vec<&ListItemData> {
        if self.config.multi_select {
            self.state
                .multi_selected
                .iter()
                .filter_map(|&idx| self.state.filtered_indices.get(idx))
                .filter_map(|&real_idx| self.items.get(real_idx))
                .collect()
        } else {
            self.get_selected_item().into_iter().collect()
        }
    }

    // --- Filtering and Search -----------------------------------------------

    fn update_filtered_indices(&mut self) {
        self.state.filtered_indices = self
            .items
            .iter()
            .enumerate()
            .filter(|(_, item)| item.matches_search(&self.state.search_query))
            .map(|(idx, _)| idx)
            .collect();

        // Adjust selection if current selection is filtered out
        if let Some(selected) = self.state.selected {
            if selected >= self.state.filtered_indices.len() {
                self.state.selected = if self.state.filtered_indices.is_empty() {
                    None
                } else {
                    Some(self.state.filtered_indices.len() - 1)
                };
            }
        }
    }

    fn set_search_query(&mut self, query: String) {
        self.state.search_query = query;
        self.update_filtered_indices();
    }

    // --- Selection ----------------------------------------------------------

    fn toggle_selection(&mut self) -> Option<Action> {
        if let Some(selected) = self.state.selected {
            if self.config.multi_select {
                if self.state.multi_selected.contains(&selected) {
                    self.state.multi_selected.remove(&selected);
                } else {
                    self.state.multi_selected.insert(selected);
                }
            }
            Some(Action::Select)
        } else {
            None
        }
    }

    // --- Rendering ----------------------------------------------------------

    fn render_search_bar(&self, frame: &mut Frame, area: Rect) {
        if !self.config.searchable || !self.state.search_active {
            return;
        }

        let search_text = if self.state.search_query.is_empty() {
            "Search..."
        } else {
            &self.state.search_query
        };

        let search_style = if self.state.search_query.is_empty() {
            Style::default().fg(Color::DarkGray)
        } else {
            Style::default().fg(Color::White)
        };

        let search_paragraph = Paragraph::new(format!("🔍 {}", search_text))
            .style(search_style)
            .block(Block::default().borders(Borders::BOTTOM));

        frame.render_widget(search_paragraph, area);
    }

    /// Check if widget has any items
    fn has_items(&self) -> bool {
        !self.state.filtered_indices.is_empty()
    }

    fn create_list_items<'a>(
        items: &'a [ListItemData],
        state: &ListWidgetState,
        config: &ListConfig,
    ) -> Vec<ListItem<'a>> {
        let start = if config.virtualized { state.scroll_offset } else { 0 };

        let end = if config.virtualized {
            (start + state.viewport_size).min(state.filtered_indices.len())
        } else {
            state.filtered_indices.len()
        };

        state.filtered_indices[start..end]
            .iter()
            .enumerate()
            .filter_map(|(display_idx, &real_idx)| {
                items.get(real_idx).map(|item| {
                    let list_idx = start + display_idx;
                    let is_selected = state.selected == Some(list_idx);
                    let is_multi_selected = config.multi_select && state.multi_selected.contains(&list_idx);

                    let mut style = Style::default();
                    let mut prefix = " ";

                    if is_selected {
                        style = style.bg(Color::Blue).fg(Color::White);
                    }

                    if is_multi_selected {
                        prefix = "✓";
                        style = style.add_modifier(Modifier::BOLD);
                    }

                    let content = format!("{} {}", prefix, item.text);
                    ListItem::new(Line::from(Span::styled(content, style)))
                })
            })
            .collect()
    }
}

// --- NavigableWidget Implementation -----------------------------------------

impl super::NavigableWidget for ListWidget {
    fn get_item_count(&self) -> usize {
        self.state.filtered_indices.len()
    }

    fn get_selected(&self) -> Option<usize> {
        self.state.selected
    }

    fn set_selected(&mut self, idx: Option<usize>) {
        self.state.selected = idx;
        if let Some(selected) = idx {
            self.ratatui_state.select(Some(selected));
        } else {
            self.ratatui_state.select(None);
        }
    }

    fn update_viewport(&mut self) {
        if let Some(selected) = self.state.selected {
            let viewport_size = self.state.viewport_size;
            if viewport_size == 0 {
                return;
            }

            // Ensure selected item is visible
            if selected < self.state.scroll_offset {
                self.state.scroll_offset = selected;
            } else if selected >= self.state.scroll_offset + viewport_size {
                self.state.scroll_offset = selected.saturating_sub(viewport_size - 1);
            }
        }
    }
}

// --- Component Implementation -----------------------------------------------

impl Component for ListWidget {
    fn register_action_handler(&mut self, tx: Sender<Action>) -> Result<()> {
        self.action_tx = Some(tx);
        Ok(())
    }

    fn can_focus(&self) -> bool {
        self.config.widget.focusable
    }

    fn on_focus(&mut self) -> Result<()> {
        self.state.set_widget_focused(true);
        if self.state.selected.is_none() && !self.state.filtered_indices.is_empty() {
            self.state.selected = Some(0);
        }
        Ok(())
    }

    fn on_blur(&mut self) -> Result<()> {
        self.state.set_widget_focused(false);
        self.state.search_active = false;
        Ok(())
    }
    fn event_interest(&self) -> crate::components::EventInterestMask {
        // Use the event profile system for cleaner code
        super::WidgetEventProfile::Interactive.to_mask()
    }

    fn handle_events(&mut self, event: Option<Event>) -> Result<Option<Action>> {
        if let Some(Event::Key(key)) = event {
            match (key.code, key.modifiers) {
                // Search mode toggle
                (KeyCode::Char('/'), KeyModifiers::NONE) if self.config.searchable => {
                    self.state.search_active = !self.state.search_active;
                    if !self.state.search_active {
                        self.set_search_query(String::new());
                    }
                    return Ok(None);
                }

                // Search input
                (KeyCode::Char(c), KeyModifiers::NONE | KeyModifiers::SHIFT) if self.state.search_active => {
                    let mut query = self.state.search_query.clone();
                    query.push(c);
                    self.set_search_query(query);
                    return Ok(None);
                }

                (KeyCode::Backspace, _) if self.state.search_active => {
                    let mut query = self.state.search_query.clone();
                    query.pop();
                    self.set_search_query(query);
                    return Ok(None);
                }

                (KeyCode::Esc, _) if self.state.search_active => {
                    self.state.search_active = false;
                    self.set_search_query(String::new());
                    return Ok(None);
                }

                // Navigation (when not in search mode)
                _ if !self.state.search_active => match key.code {
                    KeyCode::Up | KeyCode::Char('k') => {
                        return Ok(super::NavigableWidget::navigate(self, Direction::Up))
                    }
                    KeyCode::Down | KeyCode::Char('j') => {
                        return Ok(super::NavigableWidget::navigate(self, Direction::Down))
                    }
                    KeyCode::PageUp => return Ok(super::NavigableWidget::navigate(self, Direction::PageUp)),
                    KeyCode::PageDown => return Ok(super::NavigableWidget::navigate(self, Direction::PageDown)),
                    KeyCode::Home | KeyCode::Char('g') => {
                        return Ok(super::NavigableWidget::navigate(self, Direction::Home))
                    }
                    KeyCode::End | KeyCode::Char('G') => {
                        return Ok(super::NavigableWidget::navigate(self, Direction::End))
                    }
                    KeyCode::Enter | KeyCode::Char(' ') => return Ok(self.toggle_selection()),
                    _ => {}
                },

                _ => {}
            }
        }
        Ok(None)
    }

    fn update(&mut self, action: Action) -> Result<Option<Action>> {
        match action {
            Action::Move(direction) if !self.state.search_active => {
                super::NavigableWidget::navigate(self, direction);
            }
            Action::Select => {
                self.toggle_selection();
            }
            _ => {}
        }
        Ok(None)
    }

    fn draw(&mut self, frame: &mut Frame, area: Rect, border: Option<&BorderSpec>) -> Result<()> {
        let render_area = apply_border(
            frame,
            area,
            border,
            Some(&self.config.widget.theme),
            self.state.is_focused,
            self.config.widget.title.as_deref(),
        );

        // Calculate viewport size for virtualization
        let available_height = if self.config.searchable && self.state.search_active {
            render_area.height.saturating_sub(2) // Reserve space for search bar
        } else {
            render_area.height
        };
        self.state.viewport_size = available_height as usize;

        let layout = if self.config.searchable && self.state.search_active {
            Layout::default()
                .direction(LayoutDirection::Vertical)
                .constraints([Constraint::Length(2), Constraint::Min(0)])
                .split(render_area)
        } else {
            Layout::default()
                .direction(LayoutDirection::Vertical)
                .constraints([Constraint::Min(0)])
                .split(render_area)
        };

        // Render search bar if active
        if self.config.searchable && self.state.search_active {
            self.render_search_bar(frame, layout[0]);
        }

        // Render list
        let list_area = if self.config.searchable && self.state.search_active {
            layout[1]
        } else {
            layout[0]
        };

        // Update ratatui state for proper highlighting
        if let Some(selected) = self.state.selected {
            let display_selected = if self.config.virtualized {
                selected.saturating_sub(self.state.scroll_offset)
            } else {
                selected
            };
            self.ratatui_state.select(Some(display_selected));
        } else {
            self.ratatui_state.select(None);
        }

        let items = Self::create_list_items(&self.items, &self.state, &self.config);
        let list = List::new(items)
            .style(Style::default().fg(Color::White))
            .highlight_style(Style::default().bg(Color::Blue).fg(Color::White));

        frame.render_stateful_widget(list, list_area, &mut self.ratatui_state);

        Ok(())
    }
}

impl StatefulComponent for ListWidget {
    type State = ListWidgetState;

    fn state(&self) -> &Self::State {
        &self.state
    }

    fn state_mut(&mut self) -> &mut Self::State {
        &mut self.state
    }
}

// --- Builder Pattern --------------------------------------------------------

pub struct ListBuilder {
    items: Vec<ListItemData>,
    config: ListConfig,
}

impl ListBuilder {
    pub fn new() -> Self {
        Self {
            items: Vec::new(),
            config: ListConfig::default(),
        }
    }

    pub fn items(mut self, items: Vec<ListItemData>) -> Self {
        self.items = items;
        self
    }

    pub fn multi_select(mut self, enabled: bool) -> Self {
        self.config.multi_select = enabled;
        self
    }

    pub fn searchable(mut self, enabled: bool) -> Self {
        self.config.searchable = enabled;
        self
    }

    pub fn virtualized(mut self, enabled: bool) -> Self {
        self.config.virtualized = enabled;
        self
    }

    pub fn page_size(mut self, size: usize) -> Self {
        self.config.page_size = size;
        self
    }

    pub fn build(self) -> ListWidget {
        ListWidget::with_config(self.items, self.config)
    }
}

impl Default for ListBuilder {
    fn default() -> Self {
        Self::new()
    }
}
