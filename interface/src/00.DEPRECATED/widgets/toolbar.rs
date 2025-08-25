// Title         : widgets/toolbar.rs
// Author        : Bardia Samiee
// Project       : Parametric Forge Interface
// License       : MIT
// Path          : interface/src/widgets/toolbar.rs
// ----------------------------------------------------------------------------

//! Toolbar widget for action buttons with keyboard shortcuts and navigation

use color_eyre::eyre::Result;
use crossterm::event::{Event, KeyCode, KeyModifiers};
use ratatui::{
    layout::{Alignment, Rect},
    style::{Modifier, Style},
    text::{Line, Span},
    widgets::{Block, Borders, Paragraph},
    Frame,
};
use std::sync::mpsc::Sender;

use super::{apply_themed_border, FocusStyle, ResponsiveDesign, WidgetConfig, WidgetState, WidgetTheme};
use crate::components::Component;
use crate::core::{calculate_index, Action, Direction};
use crate::layouts::BorderSpec;

// --- Toolbar Configuration --------------------------------------------------

#[derive(Debug, Clone)]
pub struct ToolbarConfig {
    pub orientation: ToolbarOrientation,
    pub button_spacing: u16,
    pub show_shortcuts: bool,
    pub show_borders: bool,
    pub widget: WidgetConfig,
}

impl Default for ToolbarConfig {
    fn default() -> Self {
        Self {
            orientation: ToolbarOrientation::Horizontal,
            button_spacing: 1,
            show_shortcuts: true,
            show_borders: false,
            widget: WidgetConfig::default(),
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq)]
pub enum ToolbarOrientation {
    Horizontal,
    Vertical,
}

// --- Toolbar Button ---------------------------------------------------------

#[derive(Debug, Clone)]
pub struct ToolbarButton {
    pub label: String,
    pub action: Action,
    pub shortcut: Option<String>,
    pub enabled: bool,
    pub visible: bool,
    pub style: ToolbarButtonStyle,
}

impl ToolbarButton {
    pub fn new(label: impl Into<String>, action: Action) -> Self {
        Self {
            label: label.into(),
            action,
            shortcut: None,
            enabled: true,
            visible: true,
            style: ToolbarButtonStyle::Normal,
        }
    }

    pub fn with_shortcut(mut self, shortcut: impl Into<String>) -> Self {
        self.shortcut = Some(shortcut.into());
        self
    }

    pub fn disabled(mut self) -> Self {
        self.enabled = false;
        self
    }

    pub fn hidden(mut self) -> Self {
        self.visible = false;
        self
    }

    pub fn with_style(mut self, style: ToolbarButtonStyle) -> Self {
        self.style = style;
        self
    }

    pub fn primary(mut self) -> Self {
        self.style = ToolbarButtonStyle::Primary;
        self
    }

    pub fn danger(mut self) -> Self {
        self.style = ToolbarButtonStyle::Danger;
        self
    }
}

#[derive(Debug, Clone, Copy, PartialEq)]
pub enum ToolbarButtonStyle {
    Normal,
    Primary,
    Danger,
    Success,
}

impl ToolbarButtonStyle {
    pub fn get_style(self, theme: &WidgetTheme, is_selected: bool, is_focused: bool, enabled: bool) -> Style {
        let base_color = match self {
            ToolbarButtonStyle::Normal => theme.text,
            ToolbarButtonStyle::Primary => theme.primary,
            ToolbarButtonStyle::Danger => theme.error,
            ToolbarButtonStyle::Success => theme.success,
        };

        let mut style = Style::default().fg(base_color);

        if !enabled {
            style = style.fg(theme.text_dim);
        } else if is_selected && is_focused {
            style = FocusStyle::selection(theme, true);
        } else if is_selected {
            style = style.add_modifier(Modifier::UNDERLINED);
        }

        style
    }
}

// --- Toolbar State ----------------------------------------------------------

#[derive(Debug, Clone)]
pub struct ToolbarState {
    pub selected_index: usize,
    pub is_focused: bool,
    pub visible_buttons: Vec<usize>,
}

impl Default for ToolbarState {
    fn default() -> Self {
        Self {
            selected_index: 0,
            is_focused: false,
            visible_buttons: Vec::new(),
        }
    }
}

impl WidgetState for ToolbarState {
    fn reset(&mut self) {
        self.selected_index = 0;
        self.visible_buttons.clear();
    }
}

// --- Toolbar Widget ---------------------------------------------------------

pub struct ToolbarWidget {
    buttons: Vec<ToolbarButton>,
    config: ToolbarConfig,
    state: ToolbarState,
    action_tx: Option<Sender<Action>>,
}

impl ToolbarWidget {
    pub fn new(buttons: Vec<(String, Action)>) -> Self {
        let toolbar_buttons = buttons
            .into_iter()
            .map(|(label, action)| ToolbarButton::new(label, action))
            .collect();

        Self {
            buttons: toolbar_buttons,
            config: ToolbarConfig::default(),
            state: ToolbarState::default(),
            action_tx: None,
        }
    }

    pub fn with_config(mut self, config: ToolbarConfig) -> Self {
        self.config = config;
        self
    }

    pub fn add_button(&mut self, button: ToolbarButton) {
        self.buttons.push(button);
        self.update_visible_buttons();
    }

    pub fn set_buttons(&mut self, buttons: Vec<ToolbarButton>) {
        self.buttons = buttons;
        self.update_visible_buttons();
    }

    pub fn set_button_enabled(&mut self, index: usize, enabled: bool) {
        if let Some(button) = self.buttons.get_mut(index) {
            button.enabled = enabled;
        }
    }

    pub fn set_button_visible(&mut self, index: usize, visible: bool) {
        if let Some(button) = self.buttons.get_mut(index) {
            button.visible = visible;
            self.update_visible_buttons();
        }
    }

    fn update_visible_buttons(&mut self) {
        self.state.visible_buttons = self
            .buttons
            .iter()
            .enumerate()
            .filter(|(_, button)| button.visible)
            .map(|(i, _)| i)
            .collect();

        if !self.state.visible_buttons.is_empty() && !self.state.visible_buttons.contains(&self.state.selected_index) {
            self.state.selected_index = self.state.visible_buttons[0];
        }
    }

    fn navigate(&mut self, direction: Direction) {
        if !self.state.visible_buttons.is_empty() {
            let current_pos = self
                .state
                .visible_buttons
                .iter()
                .position(|&i| i == self.state.selected_index)
                .unwrap_or(0);

            let new_pos = calculate_index(current_pos, self.state.visible_buttons.len(), direction);
            if new_pos < self.state.visible_buttons.len() {
                self.state.selected_index = self.state.visible_buttons[new_pos];
            }
        }
    }

    fn activate_selected(&self) -> Option<Action> {
        self.buttons
            .get(self.state.selected_index)
            .filter(|button| button.enabled && button.visible)
            .map(|button| button.action.clone())
    }

    fn render_button(&self, button: &ToolbarButton, is_selected: bool, _area: Rect) -> Paragraph {
        let theme = &self.config.widget.theme;
        let style = button
            .style
            .get_style(theme, is_selected, self.state.is_focused, button.enabled);

        let content = if self.config.show_shortcuts && button.shortcut.is_some() {
            format!("{} ({})", button.label, button.shortcut.as_ref().unwrap())
        } else {
            button.label.clone()
        };

        let span = Span::styled(content, style);
        let line = Line::from(vec![span]);
        let paragraph = Paragraph::new(line).alignment(Alignment::Center);

        if self.config.show_borders && is_selected && self.state.is_focused {
            let border_style = FocusStyle::border(theme, true);
            paragraph.block(Block::default().borders(Borders::ALL).style(border_style))
        } else {
            paragraph
        }
    }

    fn calculate_button_areas(&self, area: Rect) -> Vec<(usize, Rect)> {
        let visible_count = self.state.visible_buttons.len();
        if visible_count == 0 {
            return Vec::new();
        }

        let mut areas = Vec::new();

        match self.config.orientation {
            ToolbarOrientation::Horizontal => {
                let button_width = area.width / visible_count as u16;
                let spacing = self.config.button_spacing;

                for (display_idx, &button_idx) in self.state.visible_buttons.iter().enumerate() {
                    let x = area.x + (display_idx as u16 * button_width);
                    let width = if display_idx == visible_count - 1 {
                        area.width - (display_idx as u16 * button_width)
                    } else {
                        button_width.saturating_sub(spacing)
                    };

                    let button_area = Rect {
                        x,
                        y: area.y,
                        width,
                        height: area.height,
                    };
                    areas.push((button_idx, button_area));
                }
            }
            ToolbarOrientation::Vertical => {
                let button_height = area.height / visible_count as u16;
                let spacing = self.config.button_spacing;

                for (display_idx, &button_idx) in self.state.visible_buttons.iter().enumerate() {
                    let y = area.y + (display_idx as u16 * button_height);
                    let height = if display_idx == visible_count - 1 {
                        area.height - (display_idx as u16 * button_height)
                    } else {
                        button_height.saturating_sub(spacing)
                    };

                    let button_area = Rect {
                        x: area.x,
                        y,
                        width: area.width,
                        height,
                    };
                    areas.push((button_idx, button_area));
                }
            }
        }

        areas
    }
}

// --- Component Implementation -----------------------------------------------

impl Component for ToolbarWidget {
    fn register_action_handler(&mut self, tx: Sender<Action>) -> Result<()> {
        self.action_tx = Some(tx);
        Ok(())
    }

    fn handle_events(&mut self, event: Option<Event>) -> Result<Option<Action>> {
        if !self.state.is_focused {
            return Ok(None);
        }

        if let Some(Event::Key(key)) = event {
            match (key.code, key.modifiers) {
                (KeyCode::Enter, KeyModifiers::NONE) | (KeyCode::Char(' '), KeyModifiers::NONE) => {
                    Ok(self.activate_selected())
                }
                (KeyCode::Left, KeyModifiers::NONE) | (KeyCode::Up, KeyModifiers::NONE) => {
                    Ok(Some(Action::Move(Direction::Up)))
                }
                (KeyCode::Right, KeyModifiers::NONE) | (KeyCode::Down, KeyModifiers::NONE) => {
                    Ok(Some(Action::Move(Direction::Down)))
                }
                (KeyCode::Home, KeyModifiers::NONE) => Ok(Some(Action::Move(Direction::Home))),
                (KeyCode::End, KeyModifiers::NONE) => Ok(Some(Action::Move(Direction::End))),
                (KeyCode::Char(c), KeyModifiers::NONE) => {
                    // Check for shortcut keys
                    for button in &self.buttons {
                        if let Some(ref shortcut) = button.shortcut {
                            if shortcut.len() == 1
                                && shortcut.chars().next().unwrap().to_ascii_lowercase() == c.to_ascii_lowercase()
                                && button.enabled
                                && button.visible
                            {
                                return Ok(Some(button.action.clone()));
                            }
                        }
                    }
                    Ok(None)
                }
                _ => Ok(None),
            }
        } else {
            Ok(None)
        }
    }

    fn update(&mut self, action: Action) -> Result<Option<Action>> {
        if let Action::Move(direction) = action {
            if self.state.is_focused {
                self.navigate(direction);
            }
        }
        Ok(None)
    }

    fn draw(&mut self, frame: &mut Frame, area: Rect, border: Option<&BorderSpec>) -> Result<()> {
        let theme = &self.config.widget.theme;
        let title = self.config.widget.title.as_deref();

        let render_area = apply_themed_border(frame, area, border, theme, self.state.is_focused, title);

        // Use responsive design to handle small areas
        if ResponsiveDesign::is_minimal(render_area) {
            return Ok(());
        }

        self.update_visible_buttons();
        let button_areas = self.calculate_button_areas(render_area);

        for (button_idx, button_area) in button_areas {
            if let Some(button) = self.buttons.get(button_idx) {
                let is_selected = button_idx == self.state.selected_index;
                let button_widget = self.render_button(button, is_selected, button_area);
                frame.render_widget(button_widget, button_area);
            }
        }

        Ok(())
    }

    fn can_focus(&self) -> bool {
        self.config.widget.focusable && self.buttons.iter().any(|b| b.enabled && b.visible)
    }

    fn on_focus(&mut self) -> Result<()> {
        self.state.is_focused = true;
        self.update_visible_buttons();
        Ok(())
    }

    fn on_blur(&mut self) -> Result<()> {
        self.state.is_focused = false;
        Ok(())
    }
}

// --- Builder Pattern --------------------------------------------------------

pub struct ToolbarBuilder {
    buttons: Vec<ToolbarButton>,
    config: ToolbarConfig,
}

impl ToolbarBuilder {
    pub fn new() -> Self {
        Self {
            buttons: Vec::new(),
            config: ToolbarConfig::default(),
        }
    }

    pub fn add_button(mut self, label: impl Into<String>, action: Action) -> Self {
        self.buttons.push(ToolbarButton::new(label, action));
        self
    }

    pub fn add_button_with_shortcut(
        mut self,
        label: impl Into<String>,
        action: Action,
        shortcut: impl Into<String>,
    ) -> Self {
        self.buttons
            .push(ToolbarButton::new(label, action).with_shortcut(shortcut));
        self
    }

    pub fn add_primary_button(mut self, label: impl Into<String>, action: Action) -> Self {
        self.buttons.push(ToolbarButton::new(label, action).primary());
        self
    }

    pub fn add_danger_button(mut self, label: impl Into<String>, action: Action) -> Self {
        self.buttons.push(ToolbarButton::new(label, action).danger());
        self
    }

    pub fn horizontal(mut self) -> Self {
        self.config.orientation = ToolbarOrientation::Horizontal;
        self
    }

    pub fn vertical(mut self) -> Self {
        self.config.orientation = ToolbarOrientation::Vertical;
        self
    }

    pub fn with_borders(mut self, show_borders: bool) -> Self {
        self.config.show_borders = show_borders;
        self
    }

    pub fn with_shortcuts(mut self, show_shortcuts: bool) -> Self {
        self.config.show_shortcuts = show_shortcuts;
        self
    }

    pub fn button_spacing(mut self, spacing: u16) -> Self {
        self.config.button_spacing = spacing;
        self
    }

    pub fn build(self) -> ToolbarWidget {
        let mut widget = ToolbarWidget {
            buttons: self.buttons,
            config: self.config,
            state: ToolbarState::default(),
            action_tx: None,
        };

        widget.update_visible_buttons();
        widget
    }
}

impl Default for ToolbarBuilder {
    fn default() -> Self {
        Self::new()
    }
}
