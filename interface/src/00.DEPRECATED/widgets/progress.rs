// Title         : widgets/progress.rs
// Author        : Bardia Samiee
// Project       : Parametric Forge Interface
// License       : MIT
// Path          : interface/src/widgets/progress.rs
// ----------------------------------------------------------------------------

//! Unified progress indication widget for bars, spinners, and status indicators

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

use super::{apply_themed_border, FocusManager, ResponsiveDesign, WidgetConfig, WidgetState, WidgetTheme};
use crate::components::Component;
use crate::core::Action;
use crate::layouts::BorderSpec;

// --- Progress Configuration -------------------------------------------------

#[derive(Debug, Clone)]
pub struct ProgressConfig {
    pub show_percentage: bool,
    pub show_label: bool,
    pub animation_speed: u64, // milliseconds between spinner updates
    pub widget: WidgetConfig,
}

impl Default for ProgressConfig {
    fn default() -> Self {
        Self {
            show_percentage: true,
            show_label: true,
            animation_speed: 250,
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

// --- Progress Type ----------------------------------------------------------

#[derive(Debug, Clone)]
pub enum ProgressType {
    /// Determinate progress bar with known completion percentage
    Bar { value: f64, total: f64 },
    /// Indeterminate spinner for unknown duration tasks
    Spinner { state: usize },
    /// Pulse indicator for continuous processes
    Pulse { phase: f64 },
    /// Simple text status without visual indicator
    Status,
}

impl ProgressType {
    pub fn bar(value: f64, total: f64) -> Self {
        Self::Bar {
            value: value.max(0.0),
            total: total.max(1.0),
        }
    }

    pub fn spinner() -> Self {
        Self::Spinner { state: 0 }
    }

    pub fn pulse() -> Self {
        Self::Pulse { phase: 0.0 }
    }

    pub fn status() -> Self {
        Self::Status
    }

    pub fn get_ratio(&self) -> f64 {
        match self {
            Self::Bar { value, total } => (value / total).clamp(0.0, 1.0),
            Self::Pulse { phase } => (phase.sin() + 1.0) / 2.0,
            _ => 0.0,
        }
    }

    pub fn get_spinner_char(&self) -> char {
        match self {
            Self::Spinner { state } => match state % 4 {
                0 => '|',
                1 => '/',
                2 => '-',
                3 => '\\',
                _ => '|',
            },
            _ => ' ',
        }
    }

    pub fn update_animation(&mut self) {
        match self {
            Self::Spinner { ref mut state } => {
                *state = (*state + 1) % 4;
            }
            Self::Pulse { ref mut phase } => {
                *phase += 0.2;
                if *phase > std::f64::consts::PI * 2.0 {
                    *phase = 0.0;
                }
            }
            _ => {}
        }
    }
}

// --- Progress State ---------------------------------------------------------

#[derive(Debug, Clone)]
pub struct ProgressState {
    pub is_dirty: bool,
    pub last_update: std::time::Instant,
    pub last_animation: std::time::Instant,
    pub is_focused: bool,
}

impl Default for ProgressState {
    fn default() -> Self {
        let now = std::time::Instant::now();
        Self {
            is_dirty: false,
            last_update: now,
            last_animation: now,
            is_focused: false,
        }
    }
}

impl WidgetState for ProgressState {
    fn reset(&mut self) {
        self.is_dirty = false;
        let now = std::time::Instant::now();
        self.last_update = now;
        self.last_animation = now;
        self.is_focused = false;
    }

    fn is_dirty(&self) -> bool {
        self.is_dirty
    }
}

impl super::FocusManager for ProgressState {
    fn is_widget_focused(&self) -> bool {
        self.is_focused
    }

    fn set_widget_focused(&mut self, focused: bool) {
        self.is_focused = focused;
    }
}

// --- Progress Widget --------------------------------------------------------

pub struct ProgressWidget {
    config: ProgressConfig,
    state: ProgressState,
    progress_type: ProgressType,
    label: Option<String>,
    style: Style,
    action_tx: Option<Sender<Action>>,
}

impl ProgressWidget {
    pub fn new(progress_type: ProgressType) -> Self {
        Self {
            config: ProgressConfig::default(),
            state: ProgressState::default(),
            progress_type,
            label: None,
            style: Style::default().fg(Color::Green),
            action_tx: None,
        }
    }

    pub fn with_config(mut self, config: ProgressConfig) -> Self {
        self.config = config;
        self
    }

    pub fn with_label(mut self, label: impl Into<String>) -> Self {
        self.label = Some(label.into());
        self
    }

    pub fn with_style(mut self, style: Style) -> Self {
        self.style = style;
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

    // --- Progress Management ------------------------------------------------

    pub fn set_progress(&mut self, value: f64, total: f64) {
        self.progress_type = ProgressType::bar(value, total);
        self.mark_dirty();
    }

    pub fn set_progress_ratio(&mut self, ratio: f64) {
        self.progress_type = ProgressType::bar(ratio * 100.0, 100.0);
        self.mark_dirty();
    }

    pub fn set_spinner(&mut self) {
        self.progress_type = ProgressType::spinner();
        self.mark_dirty();
    }

    pub fn set_pulse(&mut self) {
        self.progress_type = ProgressType::pulse();
        self.mark_dirty();
    }

    pub fn set_status_only(&mut self) {
        self.progress_type = ProgressType::status();
        self.mark_dirty();
    }

    pub fn set_label(&mut self, label: impl Into<String>) {
        self.label = Some(label.into());
        self.mark_dirty();
    }

    pub fn clear_label(&mut self) {
        self.label = None;
        self.mark_dirty();
    }

    pub fn get_progress_ratio(&self) -> f64 {
        self.progress_type.get_ratio()
    }

    pub fn get_progress_percentage(&self) -> u16 {
        (self.get_progress_ratio() * 100.0) as u16
    }

    // --- State Management ---------------------------------------------------

    fn mark_dirty(&mut self) {
        self.state.is_dirty = true;
        self.state.last_update = std::time::Instant::now();
    }

    fn should_animate(&self) -> bool {
        let elapsed = self.state.last_animation.elapsed();
        elapsed.as_millis() >= self.config.animation_speed as u128
    }

    fn update_animation(&mut self) {
        if self.should_animate() {
            self.progress_type.update_animation();
            self.state.last_animation = std::time::Instant::now();
            self.mark_dirty();
        }
    }

    // --- Rendering ----------------------------------------------------------

    fn render_progress_bar(&self, area: Rect) -> Gauge {
        let ratio = self.get_progress_ratio();
        let percentage = self.get_progress_percentage();

        let label = if self.config.show_label && self.config.show_percentage {
            if let Some(ref custom_label) = self.label {
                format!("{} {}%", custom_label, percentage)
            } else {
                format!("{}%", percentage)
            }
        } else if self.config.show_percentage {
            format!("{}%", percentage)
        } else if let Some(ref custom_label) = self.label {
            custom_label.clone()
        } else {
            String::new()
        };

        Gauge::default()
            .block(Block::default())
            .gauge_style(self.style)
            .ratio(ratio)
            .label(label)
    }

    fn render_spinner(&self, area: Rect) -> Paragraph {
        let spinner_char = self.progress_type.get_spinner_char();

        let content = if let Some(ref label) = self.label {
            format!("{} {}", spinner_char, label)
        } else {
            spinner_char.to_string()
        };

        let span = Span::styled(content, self.style);
        let line = Line::from(vec![span]);

        Paragraph::new(line).alignment(Alignment::Left).block(Block::default())
    }

    fn render_pulse(&self, area: Rect) -> Gauge {
        let ratio = self.get_progress_ratio();

        let label = if let Some(ref custom_label) = self.label {
            custom_label.clone()
        } else {
            "Working...".to_string()
        };

        // Use a pulsing color effect
        let pulse_style = self.style.fg(if ratio > 0.5 { Color::Green } else { Color::Yellow });

        Gauge::default()
            .block(Block::default())
            .gauge_style(pulse_style)
            .ratio(ratio)
            .label(label)
    }

    fn render_status(&self, area: Rect) -> Paragraph {
        let content = if let Some(ref label) = self.label {
            label.clone()
        } else {
            "Ready".to_string()
        };

        let span = Span::styled(content, self.style);
        let line = Line::from(vec![span]);

        Paragraph::new(line).alignment(Alignment::Left).block(Block::default())
    }
}

// --- Component Implementation -----------------------------------------------

impl Component for ProgressWidget {
    fn register_action_handler(&mut self, tx: Sender<Action>) -> Result<()> {
        self.action_tx = Some(tx);
        Ok(())
    }

    fn handle_events(&mut self, _event: Option<Event>) -> Result<Option<Action>> {
        // Progress widget is typically non-interactive
        Ok(None)
    }

    fn update(&mut self, action: Action) -> Result<Option<Action>> {
        match action {
            Action::SetStatus(status) => {
                self.set_label(status);
                Ok(None)
            }
            Action::SetError(error) => {
                self.set_label(format!("Error: {}", error));
                self.style = self.style.fg(Color::Red);
                self.mark_dirty();
                Ok(None)
            }
            Action::ClearError => {
                self.style = Style::default().fg(Color::Green);
                self.mark_dirty();
                Ok(None)
            }
            _ => Ok(None),
        }
    }

    fn draw(&mut self, frame: &mut Frame, area: Rect, border: Option<&BorderSpec>) -> Result<()> {
        let theme = &self.config.widget.theme;
        let title = self.config.widget.title.as_deref();

        let render_area = apply_themed_border(frame, area, border, theme, self.state.is_focused, title);

        // Use responsive design to handle small areas
        if ResponsiveDesign::is_minimal(render_area) {
            return Ok(());
        }

        // Update animation if needed
        self.update_animation();

        // Render based on progress type
        match &self.progress_type {
            ProgressType::Bar { .. } => {
                let gauge = self.render_progress_bar(render_area);
                frame.render_widget(gauge, render_area);
            }
            ProgressType::Spinner { .. } => {
                let paragraph = self.render_spinner(render_area);
                frame.render_widget(paragraph, render_area);
            }
            ProgressType::Pulse { .. } => {
                let gauge = self.render_pulse(render_area);
                frame.render_widget(gauge, render_area);
            }
            ProgressType::Status => {
                let paragraph = self.render_status(render_area);
                frame.render_widget(paragraph, render_area);
            }
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

pub struct ProgressBuilder {
    widget: ProgressWidget,
}

impl ProgressBuilder {
    pub fn new(progress_type: ProgressType) -> Self {
        Self {
            widget: ProgressWidget::new(progress_type),
        }
    }

    pub fn bar(value: f64, total: f64) -> Self {
        Self::new(ProgressType::bar(value, total))
    }

    pub fn spinner() -> Self {
        Self::new(ProgressType::spinner())
    }

    pub fn pulse() -> Self {
        Self::new(ProgressType::pulse())
    }

    pub fn status() -> Self {
        Self::new(ProgressType::status())
    }

    pub fn with_config(mut self, config: ProgressConfig) -> Self {
        self.widget = self.widget.with_config(config);
        self
    }

    pub fn with_label(mut self, label: impl Into<String>) -> Self {
        self.widget = self.widget.with_label(label);
        self
    }

    pub fn with_style(mut self, style: Style) -> Self {
        self.widget = self.widget.with_style(style);
        self
    }

    pub fn with_color(mut self, color: Color) -> Self {
        self.widget = self.widget.with_color(color);
        self
    }

    pub fn bold(mut self) -> Self {
        self.widget = self.widget.bold();
        self
    }

    pub fn show_percentage(mut self, show: bool) -> Self {
        self.widget.config.show_percentage = show;
        self
    }

    pub fn show_label(mut self, show: bool) -> Self {
        self.widget.config.show_label = show;
        self
    }

    pub fn animation_speed(mut self, speed_ms: u64) -> Self {
        self.widget.config.animation_speed = speed_ms;
        self
    }

    pub fn focusable(mut self, focusable: bool) -> Self {
        self.widget.config.widget.focusable = focusable;
        self
    }

    pub fn with_border(mut self, border: bool) -> Self {
        self.widget.config.widget.border = border;
        self
    }

    pub fn with_title(mut self, title: impl Into<String>) -> Self {
        self.widget.config.widget.title = Some(title.into());
        self
    }

    pub fn build(self) -> ProgressWidget {
        self.widget
    }
}

// --- Convenience Constructors -----------------------------------------------

impl ProgressWidget {
    /// Create a progress bar with value/total
    pub fn bar(value: f64, total: f64) -> Self {
        Self::new(ProgressType::bar(value, total))
    }

    /// Create a progress bar with ratio (0.0 to 1.0)
    pub fn ratio(ratio: f64) -> Self {
        Self::new(ProgressType::bar(ratio * 100.0, 100.0))
    }

    /// Create an indeterminate spinner
    pub fn spinner() -> Self {
        Self::new(ProgressType::spinner())
    }

    /// Create a pulsing indicator
    pub fn pulse() -> Self {
        Self::new(ProgressType::pulse())
    }

    /// Create a status-only indicator
    pub fn status() -> Self {
        Self::new(ProgressType::status())
    }
}
