// Title         : widgets/form.rs
// Author        : Bardia Samiee
// Project       : Parametric Forge Interface
// License       : MIT
// Path          : interface/src/widgets/form.rs
// ----------------------------------------------------------------------------

//! Composable form container widget with validation and field navigation

use color_eyre::eyre::Result;
use crossterm::event::{Event, KeyCode, KeyModifiers};
use indexmap::IndexMap;
use ratatui::{
    layout::{Constraint, Direction as LayoutDirection, Layout, Rect},
    style::{Color, Style},
    text::{Line, Span},
    widgets::{Block, Borders, Paragraph},
    Frame,
};
use std::sync::mpsc::Sender;

use super::{apply_border, FocusManager, Validator, WidgetConfig, WidgetState};
use crate::{
    components::Component,
    core::{calculate_index, Action, Direction},
    layouts::BorderSpec,
};

// --- Form Configuration ----------------------------------------------------

crate::widget_config! {
    pub struct FormConfig {
        pub title: Option<String> = None,
        pub submit_label: String = "Submit".to_string(),
        pub cancel_label: String = "Cancel".to_string(),
        pub show_validation_summary: bool = true
    }
}

// --- Form Field Definition -------------------------------------------------

pub struct FormField {
    pub id: String,
    pub label: String,
    pub required: bool,
    pub help_text: Option<String>,
    pub component: Box<dyn Component>,
}

// --- Form State ------------------------------------------------------------

#[derive(Debug, Clone)]
pub struct FormState {
    pub focused_field: Option<String>,
    pub field_values: IndexMap<String, String>,
    pub field_errors: IndexMap<String, String>,
    pub is_submitting: bool,
    pub is_valid: bool,
    pub is_dirty: bool,
    pub is_focused: bool,
}

impl Default for FormState {
    fn default() -> Self {
        Self {
            focused_field: None,
            field_values: IndexMap::new(),
            field_errors: IndexMap::new(),
            is_submitting: false,
            is_valid: true,
            is_dirty: false,
            is_focused: false,
        }
    }
}

impl WidgetState for FormState {
    fn reset(&mut self) {
        self.focused_field = None;
        self.field_values.clear();
        self.field_errors.clear();
        self.is_submitting = false;
        self.is_valid = true;
        self.is_dirty = false;
        self.is_focused = false;
    }

    fn is_dirty(&self) -> bool {
        self.is_dirty
    }
}

impl super::FocusManager for FormState {
    fn is_widget_focused(&self) -> bool {
        self.is_focused
    }

    fn set_widget_focused(&mut self, focused: bool) {
        self.is_focused = focused;
    }
}

impl super::StandardFocusManager for FormState {
    fn get_selected(&self) -> Option<usize> {
        // Form doesn't have traditional selection, use default
        None
    }

    fn set_selected(&mut self, _idx: Option<usize>) {
        // Form doesn't have traditional selection
    }
}

// --- Form Widget -----------------------------------------------------------

pub struct FormWidget {
    config: FormConfig,
    state: FormState,
    fields: Vec<FormField>,
    field_order: Vec<String>,
    validators: IndexMap<String, Vec<Box<dyn Validator<String>>>>,
    action_tx: Option<Sender<Action>>,
}

impl FormWidget {
    pub fn new() -> Self {
        Self {
            config: FormConfig::default(),
            state: FormState::default(),
            fields: Vec::new(),
            field_order: Vec::new(),
            validators: IndexMap::new(),
            action_tx: None,
        }
    }

    pub fn with_config(mut self, config: FormConfig) -> Self {
        self.config = config;
        self
    }

    pub fn with_title(mut self, title: String) -> Self {
        self.config.title = Some(title);
        self
    }

    pub fn add_field<C: Component + 'static>(
        mut self,
        id: String,
        label: String,
        component: C,
        required: bool,
    ) -> Self {
        let field = FormField {
            id: id.clone(),
            label,
            required,
            help_text: None,
            component: Box::new(component),
        };

        self.fields.push(field);
        self.field_order.push(id.clone());

        // Initialize field value
        self.state.field_values.insert(id, String::new());

        self
    }

    pub fn add_field_validator<V: Validator<String> + 'static>(mut self, field_id: String, validator: V) -> Self {
        self.validators
            .entry(field_id)
            .or_insert_with(Vec::new)
            .push(Box::new(validator));
        self
    }

    pub fn get_field_value(&self, field_id: &str) -> Option<&String> {
        self.state.field_values.get(field_id)
    }

    pub fn set_field_value(&mut self, field_id: String, value: String) {
        self.state.field_values.insert(field_id.clone(), value.clone());
        self.state.is_dirty = true;

        // Validate using field validators
        if let Some(validators) = self.validators.get(&field_id) {
            for validator in validators {
                if let Err(e) = validator.validate(&value) {
                    let error_msg = e.to_string();
                    self.state.field_errors.insert(field_id.clone(), error_msg.clone());
                    // Send error to core state management
                    if let Some(tx) = &self.action_tx {
                        let _ = tx.send(Action::SetError(format!("{}: {}", field_id, error_msg)));
                    }
                    return;
                }
            }
        }
        // Clear field error if validation passed
        self.state.field_errors.shift_remove(&field_id);

        self.update_form_validity();
    }

    pub fn get_all_values(&self) -> &IndexMap<String, String> {
        &self.state.field_values
    }

    // --- Field Navigation ---------------------------------------------------

    fn navigate_fields(&mut self, direction: Direction) {
        if self.field_order.is_empty() {
            return;
        }

        let current_index = if let Some(ref current_field) = self.state.focused_field {
            self.field_order.iter().position(|id| id == current_field).unwrap_or(0)
        } else {
            0
        };

        // Use core's calculate_index for consistent navigation
        let new_index = calculate_index(current_index, self.field_order.len(), direction);

        if let Some(field_id) = self.field_order.get(new_index) {
            self.focus_field(field_id.clone());
        }
    }

    fn focus_field(&mut self, field_id: String) {
        // Blur current field
        if let Some(ref current_field) = self.state.focused_field {
            if let Some(field) = self.fields.iter_mut().find(|f| f.id == *current_field) {
                let _ = field.component.on_blur();
            }
        }

        // Focus new field
        self.state.focused_field = Some(field_id.clone());
        if let Some(field) = self.fields.iter_mut().find(|f| f.id == field_id) {
            let _ = field.component.on_focus();
        }
    }

    // --- Validation ---------------------------------------------------------

    fn validate_field(&mut self, field_id: &str) {
        if let Some(value) = self.state.field_values.get(field_id) {
            // Check required fields first
            if let Some(field) = self.fields.iter().find(|f| f.id == field_id) {
                if field.required && value.trim().is_empty() {
                    let error = "This field is required".to_string();
                    self.state.field_errors.insert(field_id.to_string(), error.clone());
                    if let Some(tx) = &self.action_tx {
                        let _ = tx.send(Action::SetError(format!("{}: {}", field_id, error)));
                    }
                    return;
                }
            }

            // Run field validators
            if let Some(validators) = self.validators.get(field_id) {
                for validator in validators {
                    if let Err(e) = validator.validate(value) {
                        let error_msg = e.to_string();
                        self.state.field_errors.insert(field_id.to_string(), error_msg.clone());
                        if let Some(tx) = &self.action_tx {
                            let _ = tx.send(Action::SetError(format!("{}: {}", field_id, error_msg)));
                        }
                        return;
                    }
                }
            }

            // Clear error if all validation passed
            self.state.field_errors.shift_remove(field_id);
        }
    }

    fn validate_all_fields(&mut self) {
        let mut all_errors = Vec::new();

        // Validate each field
        for field in &self.fields {
            if let Some(value) = self.state.field_values.get(&field.id) {
                // Check required
                if field.required && value.trim().is_empty() {
                    let error = "This field is required".to_string();
                    self.state.field_errors.insert(field.id.clone(), error.clone());
                    all_errors.push(format!("{}: {}", field.label, error));
                    continue;
                }

                // Run validators
                if let Some(validators) = self.validators.get(&field.id) {
                    for validator in validators {
                        if let Err(e) = validator.validate(value) {
                            let error_msg = e.to_string();
                            self.state.field_errors.insert(field.id.clone(), error_msg.clone());
                            all_errors.push(format!("{}: {}", field.label, error_msg));
                            break; // Only show first error per field
                        }
                    }
                }
            }
        }

        // Send aggregated error or clear
        if let Some(tx) = &self.action_tx {
            if all_errors.is_empty() {
                let _ = tx.send(Action::ClearError);
            } else {
                let _ = tx.send(Action::SetError(all_errors.join("; ")));
            }
        }

        self.update_form_validity();
    }

    fn update_form_validity(&mut self) {
        self.state.is_valid = self.state.field_errors.is_empty();
    }

    // --- Form Actions -------------------------------------------------------

    fn submit_form(&mut self) -> Result<Option<Action>> {
        self.validate_all_fields();

        if !self.state.is_valid {
            return Ok(None);
        }

        self.state.is_submitting = true;

        // Create a submit action with form data
        // This could be extended to include the form values
        Ok(Some(Action::Submit))
    }

    fn cancel_form(&mut self) -> Result<Option<Action>> {
        self.state.reset();
        Ok(Some(Action::Back))
    }

    // --- Rendering ----------------------------------------------------------

    fn render_field_labels(&self, frame: &mut Frame, area: Rect) {
        if self.fields.is_empty() {
            return;
        }

        let field_height = area.height / self.fields.len() as u16;

        for (i, field) in self.fields.iter().enumerate() {
            let field_area = Rect {
                x: area.x,
                y: area.y + (i as u16 * field_height),
                width: area.width,
                height: field_height,
            };

            let is_focused = self.state.focused_field.as_ref() == Some(&field.id);
            let has_error = self.state.field_errors.contains_key(&field.id);

            let mut label_style = Style::default();
            if is_focused {
                label_style = label_style.fg(Color::Yellow);
            }
            if has_error {
                label_style = label_style.fg(Color::Red);
            }

            let label_text = if field.required {
                format!("{}*", field.label)
            } else {
                field.label.clone()
            };

            let label_line = Line::from(vec![Span::styled(label_text, label_style)]);

            let paragraph = Paragraph::new(label_line);
            frame.render_widget(paragraph, field_area);
        }
    }

    fn render_validation_summary(&self, frame: &mut Frame, area: Rect) {
        if !self.config.show_validation_summary || self.state.field_errors.is_empty() {
            return;
        }

        let error_messages: Vec<Line> = self
            .state
            .field_errors
            .iter()
            .map(|(field, error)| {
                Line::from(vec![
                    Span::styled("• ", Style::default().fg(Color::Red)),
                    Span::styled(format!("{}: {}", field, error), Style::default().fg(Color::Red)),
                ])
            })
            .collect();

        let error_text = error_messages;
        let paragraph = Paragraph::new(error_text);
        frame.render_widget(paragraph, area);
    }

    fn render_form_actions(&self, frame: &mut Frame, area: Rect) {
        let button_layout = Layout::default()
            .direction(LayoutDirection::Horizontal)
            .constraints([Constraint::Percentage(50), Constraint::Percentage(50)])
            .split(area);

        // Submit button
        let submit_style = if self.state.is_valid {
            Style::default().fg(Color::Green)
        } else {
            Style::default().fg(Color::DarkGray)
        };

        let submit_text = if self.state.is_submitting {
            "Submitting..."
        } else {
            &self.config.submit_label
        };

        let submit_paragraph = Paragraph::new(submit_text).style(submit_style);
        frame.render_widget(submit_paragraph, button_layout[0]);

        // Cancel button
        let cancel_paragraph =
            Paragraph::new(self.config.cancel_label.as_str()).style(Style::default().fg(Color::Gray));
        frame.render_widget(cancel_paragraph, button_layout[1]);
    }

    /// Check if widget has any items (fields)
    fn has_items(&self) -> bool {
        !self.fields.is_empty()
    }
}

// --- Component Implementation -----------------------------------------------

impl Component for FormWidget {
    fn can_focus(&self) -> bool {
        self.config.widget.focusable
    }

    fn on_focus(&mut self) -> Result<()> {
        self.state.set_widget_focused(true);
        // Focus first field if none is focused
        if self.state.focused_field.is_none() && !self.field_order.is_empty() {
            let first_field = self.field_order[0].clone();
            self.focus_field(first_field);
        }
        Ok(())
    }

    fn on_blur(&mut self) -> Result<()> {
        self.state.set_widget_focused(false);
        // Blur current field
        if let Some(ref current_field) = self.state.focused_field {
            if let Some(field) = self.fields.iter_mut().find(|f| f.id == *current_field) {
                field.component.on_blur()?;
            }
        }
        Ok(())
    }
    fn register_action_handler(&mut self, tx: Sender<Action>) -> Result<()> {
        self.action_tx = Some(tx.clone());

        // Register action handlers for all field components
        for field in &mut self.fields {
            field.component.register_action_handler(tx.clone())?;
        }

        Ok(())
    }

    fn event_interest(&self) -> crate::components::EventInterestMask {
        use crate::components::EventInterestMask;
        // Form widget needs all key events for input and navigation,
        // mouse clicks for field selection
        EventInterestMask::ALL_KEYS
            .with(EventInterestMask::MOUSE_CLICK)
            .with(EventInterestMask::FOCUS_EVENTS)
    }

    fn handle_events(&mut self, event: Option<Event>) -> Result<Option<Action>> {
        if let Some(Event::Key(key)) = event {
            match (key.code, key.modifiers) {
                // Form navigation
                (KeyCode::Tab, KeyModifiers::NONE) => {
                    self.navigate_fields(Direction::Down);
                    Ok(None)
                }
                (KeyCode::BackTab, KeyModifiers::SHIFT) => {
                    self.navigate_fields(Direction::Up);
                    Ok(None)
                }

                // Form actions
                (KeyCode::Enter, KeyModifiers::CONTROL) => self.submit_form(),
                (KeyCode::Esc, KeyModifiers::NONE) => self.cancel_form(),

                // Delegate to focused field
                _ => {
                    if let Some(ref focused_field_id) = self.state.focused_field.clone() {
                        if let Some(field) = self.fields.iter_mut().find(|f| f.id == *focused_field_id) {
                            return field.component.handle_events(event);
                        }
                    }
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
                self.navigate_fields(direction);
                Ok(None)
            }
            Action::Submit => self.submit_form(),
            Action::Back => self.cancel_form(),
            _ => {
                // Update all field components
                for field in &mut self.fields {
                    field.component.update(action.clone())?;
                }
                Ok(None)
            }
        }
    }

    fn draw(&mut self, frame: &mut Frame, area: Rect, border: Option<&BorderSpec>) -> Result<()> {
        let render_area = apply_border(frame, area, border, None, self.state.is_focused, None);

        // Create layout for form sections
        let form_layout = Layout::default()
            .direction(LayoutDirection::Vertical)
            .constraints([
                Constraint::Min(1),    // Fields area
                Constraint::Length(3), // Validation summary
                Constraint::Length(2), // Form actions
            ])
            .split(render_area);

        // Render title if present
        if let Some(ref title) = self.config.title {
            let title_block = Block::default().title(title.as_str()).borders(Borders::BOTTOM);
            frame.render_widget(title_block, form_layout[0]);
        }

        // Render field labels (simplified - in a real implementation,
        // we'd need proper field component rendering)
        self.render_field_labels(frame, form_layout[0]);

        // Render validation summary
        self.render_validation_summary(frame, form_layout[1]);

        // Render form actions
        self.render_form_actions(frame, form_layout[2]);

        Ok(())
    }
}

// --- Builder Pattern -------------------------------------------------------

pub struct FormBuilder {
    form: FormWidget,
}

impl FormBuilder {
    pub fn new() -> Self {
        Self {
            form: FormWidget::new(),
        }
    }

    pub fn title(mut self, title: &str) -> Self {
        self.form.config.title = Some(title.to_string());
        self
    }

    pub fn submit_label(mut self, label: &str) -> Self {
        self.form.config.submit_label = label.to_string();
        self
    }

    pub fn cancel_label(mut self, label: &str) -> Self {
        self.form.config.cancel_label = label.to_string();
        self
    }

    pub fn show_validation_summary(mut self, show: bool) -> Self {
        self.form.config.show_validation_summary = show;
        self
    }

    pub fn add_field<C: Component + 'static>(mut self, id: &str, label: &str, component: C, required: bool) -> Self {
        self.form = self
            .form
            .add_field(id.to_string(), label.to_string(), component, required);
        self
    }

    pub fn add_validator<V: Validator<String> + 'static>(mut self, field_id: &str, validator: V) -> Self {
        self.form = self.form.add_field_validator(field_id.to_string(), validator);
        self
    }

    pub fn build(self) -> FormWidget {
        self.form
    }
}
