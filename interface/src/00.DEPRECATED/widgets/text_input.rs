// Title         : widgets/text_input.rs
// Author        : Bardia Samiee
// Project       : Parametric Forge Interface
// License       : MIT
// Path          : interface/src/widgets/text_input.rs
// ----------------------------------------------------------------------------

//! Advanced text input widget with cursor management and validation

use color_eyre::eyre::Result;
use crossterm::event::{Event, KeyCode};
use ratatui::{
    layout::Rect,
    style::Style,
    text::{Line, Span},
    widgets::Paragraph,
    Frame,
};
use std::sync::mpsc::Sender;

use super::{apply_themed_border, FocusManager, FocusStyle, Validator, WidgetConfig, WidgetState};
use crate::components::Component;
use crate::core::{Action, Direction};
use crate::layouts::BorderSpec;

// --- Text Input Configuration -----------------------------------------------

#[derive(Debug, Clone, PartialEq)]
pub enum InputMode {
    Text,
    Password,
    Numeric,
}

crate::widget_config! {
    pub struct TextInputConfig {
        pub mode: InputMode = InputMode::Text,
        pub placeholder: Option<String> = None,
        pub max_length: Option<usize> = None,
        pub multiline: bool = false
    }
}

// --- Text Input State -------------------------------------------------------

#[derive(Debug, Clone)]
pub struct TextInputState {
    pub value: String,
    pub cursor_position: usize,
    pub scroll_offset: usize,
    pub is_focused: bool,
    pub is_dirty: bool,
}

impl Default for TextInputState {
    fn default() -> Self {
        Self {
            value: String::new(),
            cursor_position: 0,
            scroll_offset: 0,
            is_focused: false,
            is_dirty: false,
        }
    }
}

impl WidgetState for TextInputState {
    fn reset(&mut self) {
        self.value.clear();
        self.cursor_position = 0;
        self.scroll_offset = 0;
        self.is_dirty = false;
    }

    fn is_dirty(&self) -> bool {
        self.is_dirty
    }
}

impl FocusManager for TextInputState {
    fn is_widget_focused(&self) -> bool {
        self.is_focused
    }

    fn set_widget_focused(&mut self, focused: bool) {
        self.is_focused = focused;
    }
}

impl super::StandardFocusManager for TextInputState {
    // TextInput doesn't have selection concept, use default implementations
}

// --- Text Input Widget ------------------------------------------------------

pub struct TextInputWidget {
    inner: tui_input::Input,
    config: TextInputConfig,
    state: TextInputState,
    validators: Vec<Box<dyn Validator<String>>>,
    action_tx: Option<Sender<Action>>,
}

impl TextInputWidget {
    pub fn new() -> Self {
        Self {
            inner: tui_input::Input::default(),
            config: TextInputConfig::default(),
            state: TextInputState::default(),
            validators: Vec::new(),
            action_tx: None,
        }
    }

    pub fn with_config(mut self, config: TextInputConfig) -> Self {
        self.config = config;
        self
    }

    pub fn with_placeholder(mut self, placeholder: String) -> Self {
        self.config.placeholder = Some(placeholder);
        self
    }

    pub fn with_mode(mut self, mode: InputMode) -> Self {
        self.config.mode = mode;
        self
    }

    pub fn with_max_length(mut self, max_length: usize) -> Self {
        self.config.max_length = Some(max_length);
        self
    }

    pub fn add_validator<V: Validator<String> + 'static>(mut self, validator: V) -> Self {
        self.validators.push(Box::new(validator));
        self
    }

    pub fn value(&self) -> &str {
        &self.state.value
    }

    pub fn set_value(&mut self, value: String) {
        self.state.value = value.clone();
        self.state.cursor_position = value.chars().count();
        self.inner = tui_input::Input::new(value);
        self.state.is_dirty = true;
        self.validate_input();
    }

    /// Trigger validation manually - useful for form validation
    pub fn validate(&mut self) -> bool {
        self.validate_input();
        self.is_valid()
    }

    /// Check if the current value is valid by running validators
    pub fn is_valid(&self) -> bool {
        for validator in &self.validators {
            if validator.validate(&self.state.value).is_err() {
                return false;
            }
        }
        true
    }

    fn validate_input(&mut self) {
        for validator in &self.validators {
            if let Err(e) = validator.validate(&self.state.value) {
                // Send error to core state management via Action::SetError
                if let Some(tx) = &self.action_tx {
                    let _ = tx.send(Action::SetError(format!("Input: {}", e)));
                }
                return;
            }
        }

        // Clear any previous validation errors via Action::ClearError
        if let Some(tx) = &self.action_tx {
            let _ = tx.send(Action::ClearError);
        }
    }

    fn handle_input_char(&mut self, c: char) -> Result<Option<Action>> {
        // Check input mode restrictions
        match self.config.mode {
            InputMode::Numeric => {
                if !c.is_ascii_digit() && c != '.' && c != '-' {
                    return Ok(None);
                }
            }
            _ => {}
        }

        // Check max length
        if let Some(max_len) = self.config.max_length {
            if self.state.value.len() >= max_len {
                return Ok(None);
            }
        }

        // Handle the input manually by inserting at cursor position
        let mut chars: Vec<char> = self.state.value.chars().collect();
        chars.insert(self.state.cursor_position, c);
        self.state.value = chars.into_iter().collect();
        self.state.cursor_position += 1;
        self.state.is_dirty = true;

        // Update the inner tui-input for consistency
        self.inner = tui_input::Input::new(self.state.value.clone());

        self.validate_input();

        Ok(None)
    }

    fn render_display_text(&self) -> String {
        match self.config.mode {
            InputMode::Password => "*".repeat(self.state.value.len()),
            _ => self.state.value.clone(),
        }
    }

    fn render_placeholder(&self) -> Option<String> {
        if self.state.value.is_empty() {
            self.config.placeholder.clone()
        } else {
            None
        }
    }

    /// TextInput doesn't have items concept, always returns false
    fn has_items(&self) -> bool {
        false
    }
}

impl Component for TextInputWidget {
    fn register_action_handler(&mut self, tx: Sender<Action>) -> Result<()> {
        self.action_tx = Some(tx);
        Ok(())
    }

    fn can_focus(&self) -> bool {
        self.config.widget.focusable
    }

    fn on_focus(&mut self) -> Result<()> {
        self.state.on_focus()
    }

    fn on_blur(&mut self) -> Result<()> {
        self.state.on_blur()
    }
    fn event_interest(&self) -> crate::components::EventInterestMask {
        // Use the event profile system for cleaner code
        super::WidgetEventProfile::Input.to_mask()
    }

    fn handle_events(&mut self, event: Option<Event>) -> Result<Option<Action>> {
        if let Some(Event::Key(key)) = event {
            match key.code {
                KeyCode::Char(c) => Ok(Some(Action::AppendChar(c))),
                KeyCode::Backspace => Ok(Some(Action::DeleteChar)),
                KeyCode::Delete => {
                    // Handle forward delete separately since Action::Delete is for backspace
                    let chars: Vec<char> = self.state.value.chars().collect();
                    if self.state.cursor_position < chars.len() {
                        let mut chars = chars;
                        chars.remove(self.state.cursor_position);
                        self.state.value = chars.into_iter().collect();
                        self.state.is_dirty = true;

                        // Update the inner tui-input for consistency
                        self.inner = tui_input::Input::new(self.state.value.clone());

                        self.validate_input();
                    }
                    Ok(None)
                }
                KeyCode::Left => Ok(Some(Action::Move(Direction::Left))),
                KeyCode::Right => Ok(Some(Action::Move(Direction::Right))),
                KeyCode::Home => Ok(Some(Action::Move(Direction::Home))),
                KeyCode::End => Ok(Some(Action::Move(Direction::End))),
                KeyCode::Enter => Ok(Some(Action::Submit)),
                KeyCode::Esc => Ok(Some(Action::Back)),
                _ => Ok(None),
            }
        } else {
            Ok(None)
        }
    }

    fn update(&mut self, action: Action) -> Result<Option<Action>> {
        match action {
            Action::Input(s) => {
                // Handle string input by appending each character
                for c in s.chars() {
                    self.handle_input_char(c)?;
                }
                Ok(None)
            }
            Action::AppendChar(c) => self.handle_input_char(c),
            Action::DeleteChar => {
                if self.state.cursor_position > 0 {
                    let mut chars: Vec<char> = self.state.value.chars().collect();
                    chars.remove(self.state.cursor_position - 1);
                    self.state.value = chars.into_iter().collect();
                    self.state.cursor_position -= 1;
                    self.state.is_dirty = true;

                    // Update the inner tui-input for consistency
                    self.inner = tui_input::Input::new(self.state.value.clone());

                    self.validate_input();
                }
                Ok(None)
            }
            Action::Move(direction) => {
                let chars_len = self.state.value.chars().count();
                match direction {
                    Direction::Left => {
                        if self.state.cursor_position > 0 {
                            self.state.cursor_position -= 1;
                        }
                    }
                    Direction::Right => {
                        if self.state.cursor_position < chars_len {
                            self.state.cursor_position += 1;
                        }
                    }
                    Direction::Home => {
                        self.state.cursor_position = 0;
                    }
                    Direction::End => {
                        self.state.cursor_position = chars_len;
                    }
                    _ => {} // Up/Down/PageUp/PageDown not applicable for single-line input
                }
                Ok(None)
            }
            Action::SetError(error) => {
                // External validation errors are now handled by core state
                // No local error storage needed
                Ok(None)
            }
            Action::ClearError => {
                // Clear validation errors are now handled by core state
                // No local error storage needed
                Ok(None)
            }
            _ => Ok(None),
        }
    }

    fn draw(&mut self, frame: &mut Frame, area: Rect, border: Option<&BorderSpec>) -> Result<()> {
        let theme = &self.config.widget.theme;
        let title = self.config.widget.title.as_deref();

        let render_area = apply_themed_border(frame, area, border, theme, self.state.is_focused, title);

        let display_text = self.render_display_text();
        let placeholder = self.render_placeholder();

        let content = if let Some(ref placeholder_text) = placeholder {
            Line::from(vec![Span::styled(
                placeholder_text.clone(),
                Style::default().fg(theme.text_dim),
            )])
        } else {
            Line::from(display_text)
        };

        // Use themed styling based on state
        let style = FocusStyle::text(theme, self.state.is_focused, false);

        let paragraph = Paragraph::new(content).style(style);
        frame.render_widget(paragraph, render_area);

        // Render cursor if focused
        if self.state.is_focused && placeholder.is_none() {
            let cursor_x = render_area.x + self.state.cursor_position as u16;
            if cursor_x < render_area.x + render_area.width {
                frame.set_cursor_position((cursor_x, render_area.y));
            }
        }

        Ok(())
    }
}
