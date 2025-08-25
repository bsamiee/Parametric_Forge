// Title         : widgets/menu.rs
// Author        : Bardia Samiee
// Project       : Parametric Forge Interface
// License       : MIT
// Path          : interface/src/widgets/menu.rs
// ----------------------------------------------------------------------------

//! Hierarchical menu system with keyboard shortcuts and dynamic content

use color_eyre::eyre::Result;
use crossterm::event::{Event, KeyCode, KeyModifiers};
use ratatui::{
    layout::Rect,
    style::{Color, Modifier, Style},
    text::{Line, Span},
    widgets::{Block, Borders, List, ListItem, ListState, Paragraph},
    Frame,
};
use std::sync::mpsc::Sender;

use super::{apply_border, WidgetConfig, WidgetState};
use crate::components::Component;
use crate::core::{Action, Direction};
use crate::layouts::BorderSpec;

// --- Menu Configuration -----------------------------------------------------

crate::widget_config! {
    pub struct MenuConfig {
        pub show_shortcuts: bool = true,
        pub show_icons: bool = false,
        pub max_visible_items: Option<usize> = None
    }
}

// --- Menu Item ---------------------------------------------------------------

#[derive(Debug, Clone)]
pub struct MenuItem {
    pub id: String,
    pub label: String,
    pub shortcut: Option<String>,
    pub icon: Option<String>,
    pub action: Option<Action>,
    pub children: Vec<MenuItem>,
    pub enabled: bool,
    pub separator_after: bool,
}

impl MenuItem {
    pub fn new(id: impl Into<String>, label: impl Into<String>) -> Self {
        Self {
            id: id.into(),
            label: label.into(),
            shortcut: None,
            icon: None,
            action: None,
            children: Vec::new(),
            enabled: true,
            separator_after: false,
        }
    }

    pub fn with_shortcut(mut self, shortcut: impl Into<String>) -> Self {
        self.shortcut = Some(shortcut.into());
        self
    }

    pub fn with_icon(mut self, icon: impl Into<String>) -> Self {
        self.icon = Some(icon.into());
        self
    }

    pub fn with_action(mut self, action: Action) -> Self {
        self.action = Some(action);
        self
    }

    pub fn with_children(mut self, children: Vec<MenuItem>) -> Self {
        self.children = children;
        self
    }

    pub fn disabled(mut self) -> Self {
        self.enabled = false;
        self
    }

    pub fn with_separator(mut self) -> Self {
        self.separator_after = true;
        self
    }

    pub fn is_submenu(&self) -> bool {
        !self.children.is_empty()
    }
}

// --- Menu State --------------------------------------------------------------

#[derive(Debug, Clone)]
pub struct MenuState {
    pub selected_index: usize,
    pub menu_stack: Vec<Vec<MenuItem>>,
    pub selection_stack: Vec<usize>,
    pub is_focused: bool,
    pub context_menu_position: Option<(u16, u16)>,
    pub is_context_menu: bool,
}

impl Default for MenuState {
    fn default() -> Self {
        Self {
            selected_index: 0,
            menu_stack: Vec::new(),
            selection_stack: Vec::new(),
            is_focused: false,
            context_menu_position: None,
            is_context_menu: false,
        }
    }
}

impl WidgetState for MenuState {
    fn reset(&mut self) {
        self.selected_index = 0;
        self.menu_stack.clear();
        self.selection_stack.clear();
        self.context_menu_position = None;
        self.is_context_menu = false;
    }

    fn is_dirty(&self) -> bool {
        !self.menu_stack.is_empty()
    }
}

impl super::FocusManager for MenuState {
    fn is_widget_focused(&self) -> bool {
        self.is_focused
    }

    fn set_widget_focused(&mut self, focused: bool) {
        self.is_focused = focused;
    }
}

impl super::StandardFocusManager for MenuState {
    fn get_selected(&self) -> Option<usize> {
        Some(self.selected_index)
    }

    fn set_selected(&mut self, idx: Option<usize>) {
        self.selected_index = idx.unwrap_or(0);
    }
}

// --- Menu Widget -------------------------------------------------------------

pub struct MenuWidget {
    config: MenuConfig,
    state: MenuState,
    root_items: Vec<MenuItem>,
    action_tx: Option<Sender<Action>>,
}

impl MenuWidget {
    pub fn new(items: Vec<MenuItem>) -> Self {
        let mut state = MenuState::default();
        state.menu_stack.push(items.clone());

        Self {
            config: MenuConfig::default(),
            state,
            root_items: items,
            action_tx: None,
        }
    }

    pub fn with_config(mut self, config: MenuConfig) -> Self {
        self.config = config;
        self
    }

    pub fn context_menu(items: Vec<MenuItem>, position: (u16, u16)) -> Self {
        let mut widget = Self::new(items);
        widget.state.context_menu_position = Some(position);
        widget.state.is_context_menu = true;
        widget
    }

    pub fn current_items(&self) -> &[MenuItem] {
        self.state.menu_stack.last().unwrap_or(&self.root_items)
    }

    pub fn current_item(&self) -> Option<&MenuItem> {
        let items = self.current_items();
        items.get(self.state.selected_index)
    }

    pub fn navigate(&mut self, direction: Direction) -> Option<Action> {
        match direction {
            Direction::Up | Direction::Down => {
                // Use NavigableWidget trait for Up/Down navigation
                super::NavigableWidget::navigate(self, direction)
            }
            Direction::Right => {
                if let Some(item) = self.current_item() {
                    if item.is_submenu() && item.enabled {
                        return self.enter_submenu();
                    }
                }
                None
            }
            Direction::Left => self.exit_submenu(),
            _ => None,
        }
    }

    pub fn enter_submenu(&mut self) -> Option<Action> {
        let current_index = self.state.selected_index;
        let items = self.current_items();

        if let Some(item) = items.get(current_index) {
            if item.is_submenu() && item.enabled {
                let children = item.children.clone();
                self.state.selection_stack.push(current_index);
                self.state.menu_stack.push(children);
                self.state.selected_index = 0;
            }
        }
        None
    }

    pub fn exit_submenu(&mut self) -> Option<Action> {
        if self.state.menu_stack.len() > 1 {
            self.state.menu_stack.pop();
            if let Some(previous_selection) = self.state.selection_stack.pop() {
                self.state.selected_index = previous_selection;
            }
        } else if self.state.is_context_menu {
            // Close context menu
            return Some(Action::Back);
        }
        None
    }

    pub fn select_current(&mut self) -> Option<Action> {
        if let Some(item) = self.current_item() {
            if !item.enabled {
                return None;
            }

            if item.is_submenu() {
                self.enter_submenu()
            } else if let Some(action) = &item.action {
                Some(action.clone())
            } else {
                None
            }
        } else {
            None
        }
    }

    pub fn handle_shortcut(&mut self, key: char, modifiers: KeyModifiers) -> Option<Action> {
        let shortcut_str = if modifiers.contains(KeyModifiers::CONTROL) {
            format!("Ctrl+{}", key.to_uppercase())
        } else if modifiers.contains(KeyModifiers::ALT) {
            format!("Alt+{}", key.to_uppercase())
        } else {
            key.to_string()
        };

        // Search current menu level for matching shortcut
        for (index, item) in self.current_items().iter().enumerate() {
            if let Some(ref shortcut) = item.shortcut {
                if shortcut == &shortcut_str && item.enabled {
                    self.state.selected_index = index;
                    return self.select_current();
                }
            }
        }

        None
    }

    fn render_menu_item(&self, item: &MenuItem, is_selected: bool) -> ListItem {
        let mut spans = Vec::new();

        // Icon
        if self.config.show_icons {
            if let Some(ref icon) = item.icon {
                spans.push(Span::raw(format!("{} ", icon)));
            } else {
                spans.push(Span::raw("  "));
            }
        }

        // Label
        let label_style = if !item.enabled {
            Style::default().fg(Color::DarkGray)
        } else if is_selected {
            Style::default().fg(Color::Black).bg(Color::White)
        } else {
            Style::default().fg(Color::White)
        };

        spans.push(Span::styled(item.label.clone(), label_style));

        // Submenu indicator
        if item.is_submenu() {
            spans.push(Span::styled(" ▶", label_style));
        }

        // Shortcut
        if self.config.show_shortcuts {
            if let Some(ref shortcut) = item.shortcut {
                spans.push(Span::raw("  "));
                spans.push(Span::styled(
                    format!("[{}]", shortcut),
                    Style::default().fg(Color::DarkGray),
                ));
            }
        }

        ListItem::new(Line::from(spans))
    }

    /// Check if widget has any items
    fn has_items(&self) -> bool {
        !self.current_items().is_empty()
    }
}

// --- NavigableWidget Implementation -----------------------------------------

impl super::NavigableWidget for MenuWidget {
    fn get_item_count(&self) -> usize {
        self.current_items().len()
    }

    fn get_selected(&self) -> Option<usize> {
        Some(self.state.selected_index)
    }

    fn set_selected(&mut self, idx: Option<usize>) {
        self.state.selected_index = idx.unwrap_or(0);
    }
}

impl Component for MenuWidget {
    fn register_action_handler(&mut self, tx: Sender<Action>) -> Result<()> {
        self.action_tx = Some(tx);
        Ok(())
    }

    fn can_focus(&self) -> bool {
        self.config.widget.focusable
    }

    fn on_focus(&mut self) -> Result<()> {
        self.state.is_focused = true;
        Ok(())
    }

    fn on_blur(&mut self) -> Result<()> {
        self.state.is_focused = false;
        Ok(())
    }
    fn event_interest(&self) -> crate::components::EventInterestMask {
        use crate::components::EventInterestMask;
        // Menu widget needs key presses for navigation and selection,
        // mouse clicks for menu item selection
        EventInterestMask::KEY_PRESS
            .with(EventInterestMask::MOUSE_CLICK)
            .with(EventInterestMask::FOCUS_EVENTS)
    }

    fn handle_events(&mut self, event: Option<Event>) -> Result<Option<Action>> {
        if let Some(Event::Key(key)) = event {
            match (key.code, key.modifiers) {
                // Navigation
                (KeyCode::Up, KeyModifiers::NONE) => Ok(self.navigate(Direction::Up)),
                (KeyCode::Down, KeyModifiers::NONE) => Ok(self.navigate(Direction::Down)),
                (KeyCode::Left, KeyModifiers::NONE) => Ok(self.navigate(Direction::Left)),
                (KeyCode::Right, KeyModifiers::NONE) => Ok(self.navigate(Direction::Right)),

                // Vim navigation
                (KeyCode::Char('k'), KeyModifiers::NONE) => Ok(self.navigate(Direction::Up)),
                (KeyCode::Char('j'), KeyModifiers::NONE) => Ok(self.navigate(Direction::Down)),
                (KeyCode::Char('h'), KeyModifiers::NONE) => Ok(self.navigate(Direction::Left)),
                (KeyCode::Char('l'), KeyModifiers::NONE) => Ok(self.navigate(Direction::Right)),

                // Selection
                (KeyCode::Enter, KeyModifiers::NONE) => Ok(self.select_current()),
                (KeyCode::Char(' '), KeyModifiers::NONE) => Ok(self.select_current()),

                // Back/Escape
                (KeyCode::Esc, KeyModifiers::NONE) => Ok(self.exit_submenu()),
                (KeyCode::Backspace, KeyModifiers::NONE) => Ok(self.exit_submenu()),

                // Shortcut handling
                (KeyCode::Char(c), modifiers) => Ok(self.handle_shortcut(c, modifiers)),

                _ => Ok(None),
            }
        } else {
            Ok(None)
        }
    }

    fn update(&mut self, action: Action) -> Result<Option<Action>> {
        match action {
            Action::Move(direction) => Ok(self.navigate(direction)),
            Action::Select => Ok(self.select_current()),
            Action::Back => Ok(self.exit_submenu()),
            _ => Ok(None),
        }
    }

    fn draw(&mut self, frame: &mut Frame, area: Rect, border: Option<&BorderSpec>) -> Result<()> {
        let render_area = if self.state.is_context_menu {
            // For context menus, use the provided area directly
            area
        } else {
            apply_border(
                frame,
                area,
                border,
                Some(&self.config.widget.theme),
                self.state.is_focused,
                self.config.widget.title.as_deref(),
            )
        };

        let items = self.current_items();
        let list_items: Vec<ListItem> = items
            .iter()
            .enumerate()
            .map(|(index, item)| self.render_menu_item(item, index == self.state.selected_index))
            .collect();

        let mut list_state = ListState::default();
        list_state.select(Some(self.state.selected_index));

        let list = List::new(list_items).highlight_style(Style::default().add_modifier(Modifier::REVERSED));

        // For context menus, add a border
        if self.state.is_context_menu {
            let block = Block::default()
                .borders(Borders::ALL)
                .style(Style::default().fg(Color::White));

            let list_with_border = list.block(block);
            frame.render_stateful_widget(list_with_border, render_area, &mut list_state);
        } else {
            frame.render_stateful_widget(list, render_area, &mut list_state);
        }

        // Show breadcrumb for nested menus
        if self.state.menu_stack.len() > 1 && !self.state.is_context_menu {
            let breadcrumb_area = Rect {
                x: render_area.x,
                y: render_area.y.saturating_sub(1),
                width: render_area.width,
                height: 1,
            };

            let breadcrumb_text = format!("Menu Level: {}", self.state.menu_stack.len());
            let breadcrumb = Paragraph::new(breadcrumb_text).style(Style::default().fg(Color::DarkGray));

            frame.render_widget(breadcrumb, breadcrumb_area);
        }

        Ok(())
    }
}

// --- Menu Builder Helpers ---------------------------------------------------

pub struct MenuBuilder {
    items: Vec<MenuItem>,
}

impl MenuBuilder {
    pub fn new() -> Self {
        Self { items: Vec::new() }
    }

    pub fn item(mut self, item: MenuItem) -> Self {
        self.items.push(item);
        self
    }

    pub fn separator(mut self) -> Self {
        if let Some(last_item) = self.items.last_mut() {
            last_item.separator_after = true;
        }
        self
    }

    pub fn submenu(mut self, label: impl Into<String>, children: Vec<MenuItem>) -> Self {
        let label_str = label.into();
        let item = MenuItem::new(label_str.clone(), label_str).with_children(children);
        self.items.push(item);
        self
    }

    pub fn build(self) -> Vec<MenuItem> {
        self.items
    }
}

impl Default for MenuBuilder {
    fn default() -> Self {
        Self::new()
    }
}
