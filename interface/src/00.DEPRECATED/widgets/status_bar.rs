// Title         : widgets/status_bar.rs
// Author        : Bardia Samiee
// Project       : Parametric Forge Interface
// License       : MIT
// Path          : interface/src/widgets/status_bar.rs
// ----------------------------------------------------------------------------

//! Status bar widget with multi-section display for status information and progress

use color_eyre::eyre::Result;
use crossterm::event::Event;
use ratatui::{
    layout::{Alignment, Rect},
    style::{Color, Modifier, Style},
    text::{Line, Span},
    widgets::{Block, Gauge, Paragraph},
    Frame,
};
use std::sync::mpsc::Sender;

use super::{apply_border, FocusManager, WidgetConfig, WidgetState, WidgetTheme};
use crate::components::Component;
use crate::core::Action;
use crate::layouts::BorderSpec;

// --- Status Bar Configuration -----------------------------------------------

#[derive(Debug, Clone)]
pub struct StatusBarConfig {
    pub show_borders: bool,
    pub show_progress: bool,
    pub progress_width: u16,
    pub separator: String,
    pub widget: WidgetConfig,
}

impl Default for StatusBarConfig {
    fn default() -> Self {
        Self {
            show_borders: false,
            show_progress: true,
            progress_width: 20,
            separator: " | ".to_string(),
            widget: WidgetConfig {
                focusable: false,
                border: false,
                title: None,
                theme: WidgetTheme::default(),
                responsive: true,
            },
        }
    }
}

// --- Status Section ---------------------------------------------------------

#[derive(Debug, Clone)]
pub struct StatusSection {
    pub content: String,
    pub style: Style,
    pub alignment: Alignment,
    pub visible: bool,
}

impl StatusSection {
    pub fn new(content: impl Into<String>) -> Self {
        Self {
            content: content.into(),
            style: Style::default(),
            alignment: Alignment::Left,
            visible: true,
        }
    }

    pub fn with_style(mut self, style: Style) -> Self {
        self.style = style;
        self
    }

    pub fn with_alignment(mut self, alignment: Alignment) -> Self {
        self.alignment = alignment;
        self
    }

    pub fn with_color(mut self, color: Color) -> Self {
        self.style = self.style.fg(color);
        self
    }

    pub fn bold(mut self) -> Self {
        self.style = self.style.add_modifier(Modifier::BOLD);
        self
    }

    pub fn hidden(mut self) -> Self {
        self.visible = false;
        self
    }
}

// --- Progress Indicator -----------------------------------------------------

#[derive(Debug, Clone)]
pub struct ProgressIndicator {
    pub value: f64, // 0.0 to 1.0
    pub label: Option<String>,
    pub style: Style,
    pub visible: bool,
    pub indeterminate: bool,
    pub spinner_state: usize,
}

impl ProgressIndicator {
    pub fn new(value: f64) -> Self {
        Self {
            value: value.clamp(0.0, 1.0),
            label: None,
            style: Style::default().fg(Color::Green),
            visible: true,
            indeterminate: false,
            spinner_state: 0,
        }
    }

    pub fn indeterminate() -> Self {
        Self {
            value: 0.0,
            label: None,
            style: Style::default().fg(Color::Yellow),
            visible: true,
            indeterminate: true,
            spinner_state: 0,
        }
    }

    pub fn with_label(mut self, label: impl Into<String>) -> Self {
        self.label = Some(label.into());
        self
    }

    pub fn with_style(mut self, style: Style) -> Self {
        self.style = style;
        self
    }

    pub fn hidden(mut self) -> Self {
        self.visible = false;
        self
    }

    pub fn update_spinner(&mut self) {
        if self.indeterminate {
            self.spinner_state = (self.spinner_state + 1) % 4;
        }
    }

    pub fn get_spinner_char(&self) -> char {
        if self.indeterminate {
            match self.spinner_state {
                0 => '|',
                1 => '/',
                2 => '-',
                3 => '\\',
                _ => '|',
            }
        } else {
            ' '
        }
    }
}

// --- Status Bar State -------------------------------------------------------

#[derive(Debug, Clone)]
pub struct StatusBarState {
    pub is_dirty: bool,
    pub last_update: std::time::Instant,
    pub is_focused: bool,
}

impl Default for StatusBarState {
    fn default() -> Self {
        Self {
            is_dirty: false,
            last_update: std::time::Instant::now(),
            is_focused: false,
        }
    }
}

impl WidgetState for StatusBarState {
    fn reset(&mut self) {
        self.is_dirty = false;
        self.last_update = std::time::Instant::now();
        self.is_focused = false;
    }

    fn is_dirty(&self) -> bool {
        self.is_dirty
    }
}

impl super::FocusManager for StatusBarState {
    fn is_widget_focused(&self) -> bool {
        self.is_focused
    }

    fn set_widget_focused(&mut self, focused: bool) {
        self.is_focused = focused;
    }
}

// --- Status Bar Widget ------------------------------------------------------

pub struct StatusBarWidget {
    config: StatusBarConfig,
    state: StatusBarState,
    left_section: StatusSection,
    center_section: StatusSection,
    right_section: StatusSection,
    progress: Option<ProgressIndicator>,
    action_tx: Option<Sender<Action>>,
}

impl StatusBarWidget {
    pub fn new() -> Self {
        Self {
            config: StatusBarConfig::default(),
            state: StatusBarState::default(),
            left_section: StatusSection::new(""),
            center_section: StatusSection::new("").with_alignment(Alignment::Center),
            right_section: StatusSection::new("").with_alignment(Alignment::Right),
            progress: None,
            action_tx: None,
        }
    }

    pub fn with_config(mut self, config: StatusBarConfig) -> Self {
        self.config = config;
        self
    }

    // --- Section Management -------------------------------------------------

    pub fn set_left(&mut self, content: impl Into<String>) {
        self.left_section.content = content.into();
        self.mark_dirty();
    }

    pub fn set_center(&mut self, content: impl Into<String>) {
        self.center_section.content = content.into();
        self.mark_dirty();
    }

    pub fn set_right(&mut self, content: impl Into<String>) {
        self.right_section.content = content.into();
        self.mark_dirty();
    }

    pub fn set_left_section(&mut self, section: StatusSection) {
        self.left_section = section;
        self.mark_dirty();
    }

    pub fn set_center_section(&mut self, section: StatusSection) {
        self.center_section = section;
        self.mark_dirty();
    }

    pub fn set_right_section(&mut self, section: StatusSection) {
        self.right_section = section;
        self.mark_dirty();
    }

    // --- Progress Management ------------------------------------------------

    pub fn set_progress(&mut self, progress: ProgressIndicator) {
        self.progress = Some(progress);
        self.mark_dirty();
    }

    pub fn set_progress_value(&mut self, value: f64) {
        if let Some(ref mut progress) = self.progress {
            progress.value = value.clamp(0.0, 1.0);
            self.mark_dirty();
        } else {
            self.progress = Some(ProgressIndicator::new(value));
            self.mark_dirty();
        }
    }

    pub fn set_progress_label(&mut self, label: impl Into<String>) {
        if let Some(ref mut progress) = self.progress {
            progress.label = Some(label.into());
            self.mark_dirty();
        }
    }

    pub fn clear_progress(&mut self) {
        self.progress = None;
        self.mark_dirty();
    }

    pub fn show_spinner(&mut self, label: Option<String>) {
        let mut spinner = ProgressIndicator::indeterminate();
        if let Some(label) = label {
            spinner = spinner.with_label(label);
        }
        self.progress = Some(spinner);
        self.mark_dirty();
    }

    // --- Status Updates -----------------------------------------------------

    pub fn set_status(&mut self, status: impl Into<String>) {
        self.set_left(status);
    }

    pub fn set_error(&mut self, error: impl Into<String>) {
        self.left_section = StatusSection::new(format!("Error: {}", error.into()))
            .with_color(Color::Red)
            .bold();
        self.mark_dirty();
    }

    pub fn set_success(&mut self, message: impl Into<String>) {
        self.left_section = StatusSection::new(message).with_color(Color::Green);
        self.mark_dirty();
    }

    pub fn set_warning(&mut self, warning: impl Into<String>) {
        self.left_section = StatusSection::new(format!("Warning: {}", warning.into())).with_color(Color::Yellow);
        self.mark_dirty();
    }

    pub fn clear_status(&mut self) {
        self.left_section = StatusSection::new("");
        self.mark_dirty();
    }

    // --- State Management ---------------------------------------------------

    fn mark_dirty(&mut self) {
        self.state.is_dirty = true;
        self.state.last_update = std::time::Instant::now();
    }

    pub fn update_spinner(&mut self) {
        if let Some(ref mut progress) = self.progress {
            progress.update_spinner();
            self.mark_dirty();
        }
    }

    // --- Rendering ----------------------------------------------------------

    fn render_section(&self, section: &StatusSection, _area: Rect) -> Paragraph {
        if !section.visible || section.content.is_empty() {
            return Paragraph::new("");
        }

        let span = Span::styled(section.content.clone(), section.style);
        let line = Line::from(vec![span]);

        Paragraph::new(line).alignment(section.alignment)
    }

    fn render_progress(&self, _area: Rect) -> Option<(Gauge, String)> {
        if let Some(ref progress) = self.progress {
            if !progress.visible {
                return None;
            }

            if progress.indeterminate {
                // Render spinner
                let spinner_char = progress.get_spinner_char();
                let label = progress.label.as_deref().unwrap_or("Working");
                let spinner_text = format!("{} {}", spinner_char, label);

                let gauge = Gauge::default()
                    .block(Block::default())
                    .gauge_style(progress.style)
                    .ratio(0.0);

                Some((gauge, spinner_text))
            } else {
                // Render progress bar
                let percentage = (progress.value * 100.0) as u16;
                let label = if let Some(ref custom_label) = progress.label {
                    format!("{} {}%", custom_label, percentage)
                } else {
                    format!("{}%", percentage)
                };

                let gauge = Gauge::default()
                    .block(Block::default())
                    .gauge_style(progress.style)
                    .ratio(progress.value)
                    .label(label.clone());

                Some((gauge, label))
            }
        } else {
            None
        }
    }

    fn calculate_layout(&self, area: Rect) -> (Rect, Rect, Rect, Option<Rect>) {
        let progress_width = if self.progress.is_some() && self.config.show_progress {
            self.config.progress_width
        } else {
            0
        };

        let available_width = area.width.saturating_sub(progress_width);
        let section_width = available_width / 3;

        let left_area = Rect {
            x: area.x,
            y: area.y,
            width: section_width,
            height: area.height,
        };

        let center_area = Rect {
            x: area.x + section_width,
            y: area.y,
            width: section_width,
            height: area.height,
        };

        let right_area = Rect {
            x: area.x + (section_width * 2),
            y: area.y,
            width: available_width - (section_width * 2),
            height: area.height,
        };

        let progress_area = if progress_width > 0 {
            Some(Rect {
                x: area.x + available_width,
                y: area.y,
                width: progress_width,
                height: area.height,
            })
        } else {
            None
        };

        (left_area, center_area, right_area, progress_area)
    }
}

// --- Component Implementation -----------------------------------------------

impl Component for StatusBarWidget {
    fn register_action_handler(&mut self, tx: Sender<Action>) -> Result<()> {
        self.action_tx = Some(tx);
        Ok(())
    }

    fn handle_events(&mut self, _event: Option<Event>) -> Result<Option<Action>> {
        // Status bar is typically non-interactive
        Ok(None)
    }

    fn update(&mut self, action: Action) -> Result<Option<Action>> {
        match action {
            Action::SetStatus(status) => {
                self.set_status(status);
                Ok(None)
            }
            Action::SetError(error) => {
                self.set_error(error);
                Ok(None)
            }
            Action::ClearError => {
                self.clear_status();
                Ok(None)
            }
            _ => Ok(None),
        }
    }

    fn draw(&mut self, frame: &mut Frame, area: Rect, border: Option<&BorderSpec>) -> Result<()> {
        let render_area = if self.config.show_borders {
            apply_border(frame, area, border, None, false, None)
        } else {
            area
        };

        if render_area.width == 0 || render_area.height == 0 {
            return Ok(());
        }

        // Update spinner animation if needed
        if let Some(ref progress) = self.progress {
            if progress.indeterminate {
                // Only update spinner periodically to avoid excessive redraws
                let elapsed = self.state.last_update.elapsed();
                if elapsed.as_millis() > 250 {
                    // Update every 250ms
                    self.update_spinner();
                }
            }
        }

        let (left_area, center_area, right_area, progress_area) = self.calculate_layout(render_area);

        // Render sections
        if self.left_section.visible && !self.left_section.content.is_empty() {
            let left_paragraph = self.render_section(&self.left_section, left_area);
            frame.render_widget(left_paragraph, left_area);
        }

        if self.center_section.visible && !self.center_section.content.is_empty() {
            let center_paragraph = self.render_section(&self.center_section, center_area);
            frame.render_widget(center_paragraph, center_area);
        }

        if self.right_section.visible && !self.right_section.content.is_empty() {
            let right_paragraph = self.render_section(&self.right_section, right_area);
            frame.render_widget(right_paragraph, right_area);
        }

        // Render progress if present and area is available
        if let (Some(progress_area), Some((gauge, _label))) = (progress_area, self.render_progress(render_area)) {
            frame.render_widget(gauge, progress_area);
        }

        Ok(())
    }

    fn can_focus(&self) -> bool {
        self.config.widget.focusable
    }

    fn on_focus(&mut self) -> Result<()> {
        self.state.set_widget_focused(true);
        Ok(())
    }

    fn on_blur(&mut self) -> Result<()> {
        self.state.set_widget_focused(false);
        Ok(())
    }
}

// --- Builder Pattern --------------------------------------------------------

pub struct StatusBarBuilder {
    widget: StatusBarWidget,
}

impl StatusBarBuilder {
    pub fn new() -> Self {
        Self {
            widget: StatusBarWidget::new(),
        }
    }

    pub fn with_borders(mut self, show_borders: bool) -> Self {
        self.widget.config.show_borders = show_borders;
        self
    }

    pub fn with_progress(mut self, show_progress: bool) -> Self {
        self.widget.config.show_progress = show_progress;
        self
    }

    pub fn progress_width(mut self, width: u16) -> Self {
        self.widget.config.progress_width = width;
        self
    }

    pub fn separator(mut self, separator: impl Into<String>) -> Self {
        self.widget.config.separator = separator.into();
        self
    }

    pub fn left_section(mut self, section: StatusSection) -> Self {
        self.widget.left_section = section;
        self
    }

    pub fn center_section(mut self, section: StatusSection) -> Self {
        self.widget.center_section = section;
        self
    }

    pub fn right_section(mut self, section: StatusSection) -> Self {
        self.widget.right_section = section;
        self
    }

    pub fn with_progress_indicator(mut self, progress: ProgressIndicator) -> Self {
        self.widget.progress = Some(progress);
        self
    }

    pub fn build(self) -> StatusBarWidget {
        self.widget
    }
}

impl Default for StatusBarBuilder {
    fn default() -> Self {
        Self::new()
    }
}
