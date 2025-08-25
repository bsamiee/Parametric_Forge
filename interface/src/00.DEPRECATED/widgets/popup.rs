// Title         : widgets/popup.rs
// Author        : Bardia Samiee
// Project       : Parametric Forge Interface
// License       : MIT
// Path          : interface/src/widgets/popup.rs
// ----------------------------------------------------------------------------

//! Modal popup and dialog system with backdrop and positioning

use super::FocusManager;
use crate::{
    components::Component,
    core::{calculate_index, Action, Direction},
    layouts::BorderSpec,
};
use color_eyre::eyre::Result;
use crossterm::event::{Event, KeyCode, KeyModifiers};
use ratatui::{
    layout::{Alignment, Constraint, Direction as LayoutDirection, Layout, Margin, Rect},
    style::{Color, Modifier, Style},
    text::Text,
    widgets::{Block, Borders, Clear, Paragraph, Wrap},
    Frame,
};
use std::sync::mpsc::Sender;

// --- Popup Types ------------------------------------------------------------

#[derive(Debug, Clone)]
pub enum PopupType {
    Info,
    Warning,
    Error,
    Confirm,
    Custom,
}

#[derive(Debug, Clone)]
pub struct PopupButton {
    pub label: String,
    pub action: Action,
    pub is_default: bool,
    pub style: ButtonStyle,
}

#[derive(Debug, Clone)]
pub enum ButtonStyle {
    Primary,
    Secondary,
    Danger,
}

// --- Popup Configuration ---------------------------------------------------

#[derive(Debug, Clone)]
pub struct PopupConfig {
    pub popup_type: PopupType,
    pub title: Option<String>,
    pub width_percent: u16,
    pub height_percent: u16,
    pub show_backdrop: bool,
    pub closable: bool,
}

impl Default for PopupConfig {
    fn default() -> Self {
        Self {
            popup_type: PopupType::Info,
            title: None,
            width_percent: 60,
            height_percent: 40,
            show_backdrop: true,
            closable: true,
        }
    }
}

// --- Popup State ------------------------------------------------------------

#[derive(Debug, Clone)]
pub struct PopupState {
    pub visible: bool,
    pub selected_button: usize,
    pub content: String,
    pub buttons: Vec<PopupButton>,
    pub is_focused: bool,
}

impl Default for PopupState {
    fn default() -> Self {
        Self {
            visible: false,
            selected_button: 0,
            content: String::new(),
            buttons: Vec::new(),
            is_focused: false,
        }
    }
}

impl super::WidgetState for PopupState {
    fn reset(&mut self) {
        self.visible = false;
        self.selected_button = 0;
        self.content.clear();
        self.buttons.clear();
        self.is_focused = false;
    }

    fn is_dirty(&self) -> bool {
        self.visible
    }
}

impl super::FocusManager for PopupState {
    fn is_widget_focused(&self) -> bool {
        self.is_focused
    }

    fn set_widget_focused(&mut self, focused: bool) {
        self.is_focused = focused;
    }
}

// --- Popup Widget ----------------------------------------------------------

pub struct PopupWidget {
    config: PopupConfig,
    state: PopupState,
    action_tx: Option<Sender<Action>>,
}

impl PopupWidget {
    pub fn new(config: PopupConfig) -> Self {
        Self {
            config,
            state: PopupState::default(),
            action_tx: None,
        }
    }

    pub fn info(title: &str, message: &str) -> Self {
        let mut popup = Self::new(PopupConfig {
            popup_type: PopupType::Info,
            title: Some(title.to_string()),
            ..Default::default()
        });
        popup.set_content(message);
        popup.add_button("OK", Action::Back, true, ButtonStyle::Primary);
        popup
    }

    pub fn warning(title: &str, message: &str) -> Self {
        let mut popup = Self::new(PopupConfig {
            popup_type: PopupType::Warning,
            title: Some(title.to_string()),
            ..Default::default()
        });
        popup.set_content(message);
        popup.add_button("OK", Action::Back, true, ButtonStyle::Primary);
        popup
    }

    pub fn error(title: &str, message: &str) -> Self {
        let mut popup = Self::new(PopupConfig {
            popup_type: PopupType::Error,
            title: Some(title.to_string()),
            ..Default::default()
        });
        popup.set_content(message);
        popup.add_button("OK", Action::Back, true, ButtonStyle::Primary);
        popup
    }

    pub fn confirm(title: &str, message: &str, confirm_action: Action) -> Self {
        let mut popup = Self::new(PopupConfig {
            popup_type: PopupType::Confirm,
            title: Some(title.to_string()),
            ..Default::default()
        });
        popup.set_content(message);
        popup.add_button("Yes", confirm_action, true, ButtonStyle::Primary);
        popup.add_button("No", Action::Back, false, ButtonStyle::Secondary);
        popup
    }

    pub fn custom(title: &str, message: &str) -> Self {
        let mut popup = Self::new(PopupConfig {
            popup_type: PopupType::Custom,
            title: Some(title.to_string()),
            ..Default::default()
        });
        popup.set_content(message);
        popup
    }

    // --- Content Management ------------------------------------------------

    pub fn set_content(&mut self, content: &str) {
        self.state.content = content.to_string();
    }

    pub fn add_button(&mut self, label: &str, action: Action, is_default: bool, style: ButtonStyle) {
        self.state.buttons.push(PopupButton {
            label: label.to_string(),
            action,
            is_default,
            style,
        });

        // Set default button as selected
        if is_default && self.state.selected_button == 0 {
            self.state.selected_button = self.state.buttons.len() - 1;
        }
    }

    pub fn show(&mut self) {
        self.state.visible = true;
    }

    pub fn hide(&mut self) {
        self.state.visible = false;
    }

    pub fn is_visible(&self) -> bool {
        self.state.visible
    }

    // --- Navigation ---------------------------------------------------------

    fn handle_navigation(&mut self, direction: Direction) {
        if self.state.buttons.is_empty() {
            return;
        }

        // Use core's calculate_index for consistent navigation
        let new_index = calculate_index(self.state.selected_button, self.state.buttons.len(), direction);

        self.state.selected_button = new_index;
    }

    fn execute_selected_button(&self) -> Option<Action> {
        self.state
            .buttons
            .get(self.state.selected_button)
            .map(|button| button.action.clone())
    }

    // --- Rendering ----------------------------------------------------------

    fn render_backdrop(&self, frame: &mut Frame, area: Rect) {
        if self.config.show_backdrop {
            let backdrop = Block::default().style(Style::default().bg(Color::Black).add_modifier(Modifier::DIM));
            frame.render_widget(Clear, area);
            frame.render_widget(backdrop, area);
        }
    }

    fn get_popup_area(&self, area: Rect) -> Rect {
        let popup_layout = Layout::default()
            .direction(LayoutDirection::Vertical)
            .constraints([
                Constraint::Percentage((100 - self.config.height_percent) / 2),
                Constraint::Percentage(self.config.height_percent),
                Constraint::Percentage((100 - self.config.height_percent) / 2),
            ])
            .split(area);

        Layout::default()
            .direction(LayoutDirection::Horizontal)
            .constraints([
                Constraint::Percentage((100 - self.config.width_percent) / 2),
                Constraint::Percentage(self.config.width_percent),
                Constraint::Percentage((100 - self.config.width_percent) / 2),
            ])
            .split(popup_layout[1])[1]
    }

    fn get_popup_style(&self) -> Style {
        match self.config.popup_type {
            PopupType::Info => Style::default().fg(Color::White).bg(Color::Blue),
            PopupType::Warning => Style::default().fg(Color::Black).bg(Color::Yellow),
            PopupType::Error => Style::default().fg(Color::White).bg(Color::Red),
            PopupType::Confirm => Style::default().fg(Color::White).bg(Color::Cyan),
            PopupType::Custom => Style::default().fg(Color::White).bg(Color::Gray),
        }
    }

    fn render_content(&self, frame: &mut Frame, area: Rect) {
        let content_area = if !self.state.buttons.is_empty() {
            // Reserve space for buttons
            let layout = Layout::default()
                .direction(LayoutDirection::Vertical)
                .constraints([
                    Constraint::Min(1),
                    Constraint::Length(3), // Button area
                ])
                .split(area);
            layout[0]
        } else {
            area
        };

        let text = Text::from(self.state.content.as_str());
        let paragraph = Paragraph::new(text)
            .wrap(Wrap { trim: true })
            .alignment(Alignment::Left);

        frame.render_widget(paragraph, content_area);
    }

    fn render_buttons(&self, frame: &mut Frame, area: Rect) {
        if self.state.buttons.is_empty() {
            return;
        }

        let layout = Layout::default()
            .direction(LayoutDirection::Vertical)
            .constraints([
                Constraint::Min(1),
                Constraint::Length(3), // Button area
            ])
            .split(area);

        let button_area = layout[1];
        let button_constraints: Vec<Constraint> = self
            .state
            .buttons
            .iter()
            .map(|_| Constraint::Percentage(100 / self.state.buttons.len() as u16))
            .collect();

        let button_layout = Layout::default()
            .direction(LayoutDirection::Horizontal)
            .constraints(&button_constraints)
            .split(button_area);

        for (i, button) in self.state.buttons.iter().enumerate() {
            if let Some(button_rect) = button_layout.get(i) {
                let is_selected = i == self.state.selected_button;
                let style = self.get_button_style(&button.style, is_selected);

                let button_text = if is_selected {
                    format!("[ {} ]", button.label)
                } else {
                    format!("  {}  ", button.label)
                };

                let button_widget = Paragraph::new(button_text).style(style).alignment(Alignment::Center);

                frame.render_widget(button_widget, *button_rect);
            }
        }
    }

    fn get_button_style(&self, button_style: &ButtonStyle, is_selected: bool) -> Style {
        let base_style = match button_style {
            ButtonStyle::Primary => Style::default().fg(Color::White).bg(Color::Blue),
            ButtonStyle::Secondary => Style::default().fg(Color::Black).bg(Color::Gray),
            ButtonStyle::Danger => Style::default().fg(Color::White).bg(Color::Red),
        };

        if is_selected {
            base_style.add_modifier(Modifier::BOLD | Modifier::UNDERLINED)
        } else {
            base_style
        }
    }
}

// --- Component Implementation -----------------------------------------------

impl Component for PopupWidget {
    fn register_action_handler(&mut self, tx: Sender<Action>) -> Result<()> {
        self.action_tx = Some(tx);
        Ok(())
    }

    fn handle_events(&mut self, event: Option<Event>) -> Result<Option<Action>> {
        if !self.state.visible {
            return Ok(None);
        }

        if let Some(Event::Key(key)) = event {
            match (key.code, key.modifiers) {
                // Navigation - use arrow keys for consistency with other widgets
                (KeyCode::Left, KeyModifiers::NONE) => {
                    self.handle_navigation(Direction::Left);
                    Ok(None)
                }
                (KeyCode::Right, KeyModifiers::NONE) => {
                    self.handle_navigation(Direction::Right);
                    Ok(None)
                }
                (KeyCode::Tab, KeyModifiers::NONE) => {
                    self.handle_navigation(Direction::Right);
                    Ok(None)
                }
                (KeyCode::BackTab, KeyModifiers::SHIFT) => {
                    self.handle_navigation(Direction::Left);
                    Ok(None)
                }

                // Activation
                (KeyCode::Enter, KeyModifiers::NONE) => {
                    if let Some(action) = self.execute_selected_button() {
                        self.hide();
                        Ok(Some(action))
                    } else {
                        Ok(None)
                    }
                }

                // Quick confirm/cancel for confirm dialogs
                (KeyCode::Char('y'), KeyModifiers::NONE) | (KeyCode::Char('Y'), KeyModifiers::NONE) => {
                    if matches!(self.config.popup_type, PopupType::Confirm) {
                        if let Some(yes_button) = self.state.buttons.first().cloned() {
                            self.hide();
                            return Ok(Some(yes_button.action));
                        }
                    }
                    Ok(None)
                }

                (KeyCode::Char('n'), KeyModifiers::NONE) | (KeyCode::Char('N'), KeyModifiers::NONE) => {
                    if matches!(self.config.popup_type, PopupType::Confirm) {
                        self.hide();
                        return Ok(Some(Action::Back));
                    }
                    Ok(None)
                }

                // Close
                (KeyCode::Esc, KeyModifiers::NONE) => {
                    if self.config.closable {
                        self.hide();
                        Ok(Some(Action::Back))
                    } else {
                        Ok(None)
                    }
                }

                _ => Ok(None),
            }
        } else {
            Ok(None)
        }
    }

    fn update(&mut self, action: Action) -> Result<Option<Action>> {
        match action {
            // Handle navigation actions from core
            Action::Move(direction) => {
                if self.state.visible {
                    self.handle_navigation(direction);
                }
                Ok(None)
            }
            // These actions should be handled by a dedicated status/error display widget
            // The popup shouldn't auto-show on these actions - let the view decide
            Action::SetError(_) | Action::SetStatus(_) => {
                // Don't handle these here - they're global state changes
                Ok(None)
            }
            _ => Ok(None),
        }
    }

    fn draw(&mut self, frame: &mut Frame, area: Rect, _border: Option<&BorderSpec>) -> Result<()> {
        if !self.state.visible {
            return Ok(());
        }

        // Render backdrop
        self.render_backdrop(frame, area);

        // Get popup area
        let popup_area = self.get_popup_area(area);

        // Clear popup area
        frame.render_widget(Clear, popup_area);

        // Render popup block
        let title = self.config.title.as_deref().unwrap_or("Dialog");
        let block = Block::default()
            .title(title)
            .borders(Borders::ALL)
            .style(self.get_popup_style());

        frame.render_widget(block, popup_area);

        // Get inner area for content
        let inner_area = popup_area.inner(Margin {
            vertical: 1,
            horizontal: 1,
        });

        // Render content
        self.render_content(frame, inner_area);

        // Render buttons
        self.render_buttons(frame, inner_area);

        Ok(())
    }

    fn can_focus(&self) -> bool {
        self.state.visible
    }

    fn on_focus(&mut self) -> Result<()> {
        self.state.set_widget_focused(true);
        // Popup manages its own focus state
        // Don't change app mode - that's the app's responsibility
        Ok(())
    }

    fn on_blur(&mut self) -> Result<()> {
        self.state.set_widget_focused(false);
        Ok(())
    }
}

// --- Builder Pattern -------------------------------------------------------

pub struct PopupBuilder {
    config: PopupConfig,
    content: String,
    buttons: Vec<PopupButton>,
}

impl PopupBuilder {
    pub fn new(popup_type: PopupType) -> Self {
        Self {
            config: PopupConfig {
                popup_type,
                ..Default::default()
            },
            content: String::new(),
            buttons: Vec::new(),
        }
    }

    pub fn title(mut self, title: &str) -> Self {
        self.config.title = Some(title.to_string());
        self
    }

    pub fn content(mut self, content: &str) -> Self {
        self.content = content.to_string();
        self
    }

    pub fn size(mut self, width_percent: u16, height_percent: u16) -> Self {
        self.config.width_percent = width_percent;
        self.config.height_percent = height_percent;
        self
    }

    pub fn backdrop(mut self, show: bool) -> Self {
        self.config.show_backdrop = show;
        self
    }

    pub fn closable(mut self, closable: bool) -> Self {
        self.config.closable = closable;
        self
    }

    pub fn button(mut self, label: &str, action: Action, is_default: bool, style: ButtonStyle) -> Self {
        self.buttons.push(PopupButton {
            label: label.to_string(),
            action,
            is_default,
            style,
        });
        self
    }

    pub fn build(self) -> PopupWidget {
        let mut popup = PopupWidget::new(self.config);
        popup.set_content(&self.content);
        popup.state.buttons = self.buttons;

        // Set default button selection
        if let Some(default_idx) = popup.state.buttons.iter().position(|b| b.is_default) {
            popup.state.selected_button = default_idx;
        }

        popup
    }
}
