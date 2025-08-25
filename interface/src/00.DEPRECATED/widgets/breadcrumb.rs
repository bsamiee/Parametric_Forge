// Title         : widgets/breadcrumb.rs
// Author        : Bardia Samiee
// Project       : Parametric Forge Interface
// License       : MIT
// Path          : interface/src/widgets/breadcrumb.rs
// ----------------------------------------------------------------------------

//! Navigation breadcrumb widget for displaying navigation path with clickable segments

use color_eyre::eyre::Result;
use crossterm::event::{Event, KeyCode, KeyModifiers};
use ratatui::{
    layout::Rect,
    style::{Color, Modifier, Style},
    text::{Line, Span},
    widgets::Paragraph,
    Frame,
};
use std::sync::mpsc::Sender;

use super::{apply_themed_border, FocusStyle, ResponsiveDesign, WidgetConfig, WidgetState};
use crate::components::Component;
use crate::core::{calculate_index, Action, Direction};
use crate::layouts::BorderSpec;

// --- Breadcrumb Configuration -----------------------------------------------

#[derive(Debug, Clone)]
pub struct BreadcrumbConfig {
    pub separator: String,
    pub max_segments: Option<usize>,
    pub truncate_middle: bool,
    pub show_home: bool,
    pub widget: WidgetConfig,
}

impl Default for BreadcrumbConfig {
    fn default() -> Self {
        Self {
            separator: " > ".to_string(),
            max_segments: Some(5),
            truncate_middle: true,
            show_home: true,
            widget: WidgetConfig::default(),
        }
    }
}

// --- Breadcrumb Segment ------------------------------------------------------

#[derive(Debug, Clone)]
pub struct BreadcrumbSegment {
    pub label: String,
    pub action: Option<Action>,
    pub clickable: bool,
}

impl BreadcrumbSegment {
    pub fn new(label: impl Into<String>) -> Self {
        Self {
            label: label.into(),
            action: None,
            clickable: false,
        }
    }

    pub fn with_action(mut self, action: Action) -> Self {
        self.action = Some(action);
        self.clickable = true;
        self
    }

    pub fn clickable(mut self) -> Self {
        self.clickable = true;
        self
    }
}

// --- Breadcrumb State -------------------------------------------------------

#[derive(Debug, Clone)]
pub struct BreadcrumbState {
    pub selected_index: Option<usize>,
    pub is_focused: bool,
    pub visible_segments: Vec<usize>, // Indices of segments to display after truncation
}

impl Default for BreadcrumbState {
    fn default() -> Self {
        Self {
            selected_index: None,
            is_focused: false,
            visible_segments: Vec::new(),
        }
    }
}

impl WidgetState for BreadcrumbState {
    fn reset(&mut self) {
        self.selected_index = None;
        self.visible_segments.clear();
    }
}

// --- Breadcrumb Widget -------------------------------------------------------

pub struct BreadcrumbWidget {
    segments: Vec<BreadcrumbSegment>,
    config: BreadcrumbConfig,
    state: BreadcrumbState,
    action_tx: Option<Sender<Action>>,
}

impl BreadcrumbWidget {
    pub fn new(segments: Vec<(String, Option<Action>)>) -> Self {
        let breadcrumb_segments = segments
            .into_iter()
            .map(|(label, action)| {
                if let Some(action) = action {
                    BreadcrumbSegment::new(label).with_action(action)
                } else {
                    BreadcrumbSegment::new(label)
                }
            })
            .collect();

        Self {
            segments: breadcrumb_segments,
            config: BreadcrumbConfig::default(),
            state: BreadcrumbState::default(),
            action_tx: None,
        }
    }

    pub fn with_config(mut self, config: BreadcrumbConfig) -> Self {
        self.config = config;
        self
    }

    pub fn add_segment(&mut self, segment: BreadcrumbSegment) {
        self.segments.push(segment);
        self.update_visible_segments();
    }

    pub fn set_segments(&mut self, segments: Vec<(String, Option<Action>)>) {
        self.segments = segments
            .into_iter()
            .map(|(label, action)| {
                if let Some(action) = action {
                    BreadcrumbSegment::new(label).with_action(action)
                } else {
                    BreadcrumbSegment::new(label)
                }
            })
            .collect();
        self.update_visible_segments();
    }

    fn update_visible_segments(&mut self) {
        let total_segments = self.segments.len();

        if let Some(max_segments) = self.config.max_segments {
            if total_segments <= max_segments {
                self.state.visible_segments = (0..total_segments).collect();
            } else if self.config.truncate_middle {
                // Show first, last, and middle segments with ellipsis
                let mut visible = Vec::new();
                let show_count = max_segments.saturating_sub(1); // Reserve space for ellipsis
                let half = show_count / 2;

                // First segments
                for i in 0..half {
                    visible.push(i);
                }

                // Last segments
                let start = total_segments.saturating_sub(show_count - half);
                for i in start..total_segments {
                    if !visible.contains(&i) {
                        visible.push(i);
                    }
                }

                self.state.visible_segments = visible;
            } else {
                // Show last segments only
                let start = total_segments.saturating_sub(max_segments);
                self.state.visible_segments = (start..total_segments).collect();
            }
        } else {
            self.state.visible_segments = (0..total_segments).collect();
        }
    }

    fn navigate(&mut self, direction: Direction) -> Option<Action> {
        let clickable_indices: Vec<usize> = self
            .state
            .visible_segments
            .iter()
            .filter(|&&i| i < self.segments.len() && self.segments[i].clickable)
            .copied()
            .collect();

        if clickable_indices.is_empty() {
            return None;
        }

        // Find current position in clickable indices
        let current_pos = if let Some(selected) = self.state.selected_index {
            clickable_indices.iter().position(|&i| i == selected).unwrap_or(0)
        } else {
            0
        };

        // Use core's calculate_index for consistent navigation
        let new_pos = match direction {
            Direction::Left => calculate_index(current_pos, clickable_indices.len(), Direction::Up),
            Direction::Right => calculate_index(current_pos, clickable_indices.len(), Direction::Down),
            Direction::Home => calculate_index(current_pos, clickable_indices.len(), Direction::Home),
            Direction::End => calculate_index(current_pos, clickable_indices.len(), Direction::End),
            _ => current_pos,
        };

        // Update selection to the new clickable index
        if new_pos < clickable_indices.len() {
            self.state.selected_index = Some(clickable_indices[new_pos]);
        }

        None
    }

    fn activate_selected(&self) -> Option<Action> {
        if let Some(index) = self.state.selected_index {
            if index < self.segments.len() {
                return self.segments[index].action.clone();
            }
        }
        None
    }

    fn render_segments(&self, _area: Rect) -> Vec<Span> {
        let mut spans = Vec::new();
        let total_visible = self.state.visible_segments.len();

        for (display_idx, &segment_idx) in self.state.visible_segments.iter().enumerate() {
            if segment_idx >= self.segments.len() {
                continue;
            }

            let segment = &self.segments[segment_idx];
            let is_selected = self.state.selected_index == Some(segment_idx);
            let is_last = display_idx == total_visible - 1;

            // Determine style based on state using theming system
            let theme = &self.config.widget.theme;
            let style = if is_selected && self.state.is_focused {
                FocusStyle::selection(theme, true)
            } else if segment.clickable {
                Style::default().fg(theme.secondary).add_modifier(Modifier::UNDERLINED)
            } else {
                FocusStyle::text(theme, self.state.is_focused, false)
            };

            spans.push(Span::styled(segment.label.clone(), style));

            // Add separator if not last segment
            if !is_last {
                // Check if we need to show ellipsis
                let next_segment_idx = self.state.visible_segments.get(display_idx + 1);
                if let Some(&next_idx) = next_segment_idx {
                    if next_idx > segment_idx + 1 {
                        spans.push(Span::styled(" ... ", Style::default().fg(theme.text_dim)));
                    } else {
                        spans.push(Span::styled(
                            self.config.separator.clone(),
                            Style::default().fg(theme.text_dim),
                        ));
                    }
                } else {
                    spans.push(Span::styled(
                        self.config.separator.clone(),
                        Style::default().fg(Color::DarkGray),
                    ));
                }
            }
        }

        spans
    }
}

// --- Component Implementation -----------------------------------------------

impl Component for BreadcrumbWidget {
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
                // Let core handle standard navigation, but process widget-specific keys
                (KeyCode::Enter, KeyModifiers::NONE) | (KeyCode::Char(' '), KeyModifiers::NONE) => {
                    Ok(self.activate_selected())
                }
                // Return Move actions for core system to handle
                (KeyCode::Left, KeyModifiers::NONE) => Ok(Some(Action::Move(Direction::Left))),
                (KeyCode::Right, KeyModifiers::NONE) => Ok(Some(Action::Move(Direction::Right))),
                (KeyCode::Home, KeyModifiers::NONE) => Ok(Some(Action::Move(Direction::Home))),
                (KeyCode::End, KeyModifiers::NONE) => Ok(Some(Action::Move(Direction::End))),
                _ => Ok(None),
            }
        } else {
            Ok(None)
        }
    }

    fn update(&mut self, action: Action) -> Result<Option<Action>> {
        match action {
            Action::Move(direction) if self.state.is_focused => {
                self.navigate(direction);
                Ok(None)
            }
            _ => {
                // Update visible segments when segments change
                self.update_visible_segments();
                Ok(None)
            }
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

        let spans = self.render_segments(render_area);
        let line = Line::from(spans);
        let paragraph = Paragraph::new(line);

        frame.render_widget(paragraph, render_area);
        Ok(())
    }

    fn can_focus(&self) -> bool {
        self.config.widget.focusable && self.segments.iter().any(|s| s.clickable)
    }

    fn on_focus(&mut self) -> Result<()> {
        self.state.is_focused = true;

        // Select first clickable segment if none selected
        if self.state.selected_index.is_none() {
            let first_clickable = self
                .state
                .visible_segments
                .iter()
                .find(|&&i| i < self.segments.len() && self.segments[i].clickable)
                .copied();
            self.state.selected_index = first_clickable;
        }

        Ok(())
    }

    fn on_blur(&mut self) -> Result<()> {
        self.state.is_focused = false;
        Ok(())
    }
}

// --- Builder Pattern --------------------------------------------------------

pub struct BreadcrumbBuilder {
    segments: Vec<BreadcrumbSegment>,
    config: BreadcrumbConfig,
}

impl BreadcrumbBuilder {
    pub fn new() -> Self {
        Self {
            segments: Vec::new(),
            config: BreadcrumbConfig::default(),
        }
    }

    pub fn add_segment(mut self, label: impl Into<String>) -> Self {
        self.segments.push(BreadcrumbSegment::new(label));
        self
    }

    pub fn add_clickable_segment(mut self, label: impl Into<String>, action: Action) -> Self {
        self.segments.push(BreadcrumbSegment::new(label).with_action(action));
        self
    }

    pub fn with_separator(mut self, separator: impl Into<String>) -> Self {
        self.config.separator = separator.into();
        self
    }

    pub fn with_max_segments(mut self, max: usize) -> Self {
        self.config.max_segments = Some(max);
        self
    }

    pub fn build(self) -> BreadcrumbWidget {
        BreadcrumbWidget {
            segments: self.segments,
            config: self.config,
            state: BreadcrumbState::default(),
            action_tx: None,
        }
    }
}

impl Default for BreadcrumbBuilder {
    fn default() -> Self {
        Self::new()
    }
}
