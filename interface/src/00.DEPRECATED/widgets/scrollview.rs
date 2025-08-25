// Title         : widgets/scrollview.rs
// Author        : Bardia Samiee
// Project       : Parametric Forge Interface
// License       : MIT
// Path          : interface/src/widgets/scrollview.rs
// ----------------------------------------------------------------------------

//! Scrollable view widget for content navigation with viewport management

use color_eyre::eyre::Result;
use crossterm::event::{Event, KeyCode};
use ratatui::{
    layout::{Constraint, Direction as LayoutDirection, Layout, Rect},
    style::{Color, Style},
    text::{Line, Span},
    widgets::{Paragraph, Scrollbar, ScrollbarOrientation, ScrollbarState},
    Frame,
};
use std::sync::mpsc::Sender;

use super::{apply_border, FocusManager, WidgetConfig, WidgetState};
use crate::components::Component;
use crate::core::{calculate_index, Action, Direction};
use crate::layouts::BorderSpec;

// --- Scrollview Configuration -----------------------------------------------

#[derive(Debug, Clone)]
pub struct ScrollviewConfig {
    pub show_scrollbar: bool,
    pub scrollbar_orientation: ScrollbarOrientation,
    pub scroll_step: usize,
    pub page_size: usize,
    pub widget: WidgetConfig,
}

impl Default for ScrollviewConfig {
    fn default() -> Self {
        Self {
            show_scrollbar: true,
            scrollbar_orientation: ScrollbarOrientation::VerticalRight,
            scroll_step: 1,
            page_size: 10,
            widget: WidgetConfig::default(),
        }
    }
}

// --- Scrollview State -------------------------------------------------------

#[derive(Debug, Clone)]
pub struct ScrollviewState {
    pub scroll_offset: usize,
    pub content_height: usize,
    pub viewport_height: usize,
    pub horizontal_offset: usize,
    pub content_width: usize,
    pub viewport_width: usize,
    pub is_focused: bool,
}

impl Default for ScrollviewState {
    fn default() -> Self {
        Self {
            scroll_offset: 0,
            content_height: 0,
            viewport_height: 0,
            horizontal_offset: 0,
            content_width: 0,
            viewport_width: 0,
            is_focused: false,
        }
    }
}

impl WidgetState for ScrollviewState {
    fn reset(&mut self) {
        *self = Self::default();
    }

    fn is_dirty(&self) -> bool {
        self.scroll_offset > 0 || self.horizontal_offset > 0
    }
}

impl super::FocusManager for ScrollviewState {
    fn is_widget_focused(&self) -> bool {
        self.is_focused
    }

    fn set_widget_focused(&mut self, focused: bool) {
        self.is_focused = focused;
    }
}

// --- Scrollable Content Trait -----------------------------------------------

pub trait ScrollableContent: Send {
    /// Get the total number of lines in the content
    fn content_height(&self) -> usize;

    /// Get the maximum width of the content
    fn content_width(&self) -> usize;

    /// Render the visible portion of content within the given area
    fn render_content(
        &mut self,
        frame: &mut Frame,
        area: Rect,
        scroll_offset: usize,
        horizontal_offset: usize,
    ) -> Result<()>;
}

// --- Text Content Implementation ---------------------------------------------

#[derive(Debug, Clone)]
pub struct TextContent {
    pub lines: Vec<String>,
}

impl TextContent {
    pub fn new(lines: Vec<String>) -> Self {
        Self { lines }
    }

    pub fn from_text(text: &str) -> Self {
        Self {
            lines: text.lines().map(|s| s.to_string()).collect(),
        }
    }
}

impl ScrollableContent for TextContent {
    fn content_height(&self) -> usize {
        self.lines.len()
    }

    fn content_width(&self) -> usize {
        self.lines.iter().map(|line| line.len()).max().unwrap_or(0)
    }

    fn render_content(
        &mut self,
        frame: &mut Frame,
        area: Rect,
        scroll_offset: usize,
        horizontal_offset: usize,
    ) -> Result<()> {
        let visible_lines: Vec<Line> = self
            .lines
            .iter()
            .skip(scroll_offset)
            .take(area.height as usize)
            .map(|line| {
                let visible_text = if horizontal_offset < line.len() {
                    &line[horizontal_offset..]
                } else {
                    ""
                };
                Line::from(Span::raw(visible_text))
            })
            .collect();

        let paragraph = Paragraph::new(visible_lines).style(Style::default());

        frame.render_widget(paragraph, area);
        Ok(())
    }
}

// --- Scrollview Widget ------------------------------------------------------

pub struct ScrollviewWidget {
    config: ScrollviewConfig,
    state: ScrollviewState,
    content: Box<dyn ScrollableContent>,
    action_tx: Option<Sender<Action>>,
    scrollbar_state: ScrollbarState,
}

impl ScrollviewWidget {
    pub fn new(content: Box<dyn ScrollableContent>) -> Self {
        Self {
            config: ScrollviewConfig::default(),
            state: ScrollviewState::default(),
            content,
            action_tx: None,
            scrollbar_state: ScrollbarState::default(),
        }
    }

    pub fn with_config(mut self, config: ScrollviewConfig) -> Self {
        self.config = config;
        self
    }

    pub fn with_text_content(text: &str) -> Self {
        let content = Box::new(TextContent::from_text(text));
        Self::new(content)
    }

    fn update_viewport(&mut self, area: Rect) {
        let content_area = if self.config.show_scrollbar {
            match self.config.scrollbar_orientation {
                ScrollbarOrientation::VerticalRight | ScrollbarOrientation::VerticalLeft => Rect {
                    width: area.width.saturating_sub(1),
                    ..area
                },
                ScrollbarOrientation::HorizontalBottom | ScrollbarOrientation::HorizontalTop => Rect {
                    height: area.height.saturating_sub(1),
                    ..area
                },
            }
        } else {
            area
        };

        self.state.viewport_height = content_area.height as usize;
        self.state.viewport_width = content_area.width as usize;
        self.state.content_height = self.content.content_height();
        self.state.content_width = self.content.content_width();

        // Update scrollbar state
        self.scrollbar_state = self
            .scrollbar_state
            .content_length(self.state.content_height)
            .viewport_content_length(self.state.viewport_height)
            .position(self.state.scroll_offset);
    }

    fn scroll_to(&mut self, direction: Direction) -> Option<Action> {
        let old_offset = self.state.scroll_offset;
        let old_horizontal = self.state.horizontal_offset;

        match direction {
            Direction::Up | Direction::Down | Direction::Home | Direction::End => {
                // Use core calculate_index for vertical navigation
                let max_scroll = self.state.content_height.saturating_sub(self.state.viewport_height);
                self.state.scroll_offset = calculate_index(self.state.scroll_offset, max_scroll + 1, direction);
            }
            Direction::PageUp => {
                // Use core calculate_index with Up direction, then apply page step
                let max_scroll = self.state.content_height.saturating_sub(self.state.viewport_height);
                self.state.scroll_offset = self.state.scroll_offset.saturating_sub(self.config.page_size);
            }
            Direction::PageDown => {
                // Use core calculate_index with Down direction, then apply page step
                let max_scroll = self.state.content_height.saturating_sub(self.state.viewport_height);
                self.state.scroll_offset = (self.state.scroll_offset + self.config.page_size).min(max_scroll);
            }
            Direction::Left => {
                self.state.horizontal_offset = self.state.horizontal_offset.saturating_sub(self.config.scroll_step);
            }
            Direction::Right => {
                let max_horizontal = self.state.content_width.saturating_sub(self.state.viewport_width);
                self.state.horizontal_offset =
                    (self.state.horizontal_offset + self.config.scroll_step).min(max_horizontal);
            }
        }

        // Update scrollbar position
        self.scrollbar_state = self.scrollbar_state.position(self.state.scroll_offset);

        // Return action if scroll position changed
        if old_offset != self.state.scroll_offset || old_horizontal != self.state.horizontal_offset {
            Some(Action::SetStatus(format!(
                "Scroll: {}/{}",
                self.state.scroll_offset + 1,
                self.state.content_height.max(1)
            )))
        } else {
            None
        }
    }
}

// --- Component Implementation ------------------------------------------------

impl Component for ScrollviewWidget {
    fn register_action_handler(&mut self, tx: Sender<Action>) -> Result<()> {
        self.action_tx = Some(tx);
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

    fn handle_events(&mut self, event: Option<Event>) -> Result<Option<Action>> {
        if let Some(Event::Key(key)) = event {
            match key.code {
                KeyCode::Up => Ok(self.scroll_to(Direction::Up)),
                KeyCode::Down => Ok(self.scroll_to(Direction::Down)),
                KeyCode::Left => Ok(self.scroll_to(Direction::Left)),
                KeyCode::Right => Ok(self.scroll_to(Direction::Right)),
                KeyCode::PageUp => Ok(self.scroll_to(Direction::PageUp)),
                KeyCode::PageDown => Ok(self.scroll_to(Direction::PageDown)),
                KeyCode::Home => Ok(self.scroll_to(Direction::Home)),
                KeyCode::End => Ok(self.scroll_to(Direction::End)),
                _ => Ok(None),
            }
        } else {
            Ok(None)
        }
    }

    fn update(&mut self, action: Action) -> Result<Option<Action>> {
        match action {
            Action::Move(direction) => Ok(self.scroll_to(direction)),
            _ => Ok(None),
        }
    }

    fn draw(&mut self, frame: &mut Frame, area: Rect, border: Option<&BorderSpec>) -> Result<()> {
        let render_area = apply_border(frame, area, border, None, self.state.is_focused, None);

        // Update viewport dimensions
        self.update_viewport(render_area);

        // Calculate content and scrollbar areas
        let (content_area, scrollbar_area) =
            if self.config.show_scrollbar && self.state.content_height > self.state.viewport_height {
                match self.config.scrollbar_orientation {
                    ScrollbarOrientation::VerticalRight => {
                        let layout = Layout::default()
                            .direction(LayoutDirection::Horizontal)
                            .constraints([Constraint::Min(0), Constraint::Length(1)])
                            .split(render_area);
                        (layout[0], Some(layout[1]))
                    }
                    ScrollbarOrientation::VerticalLeft => {
                        let layout = Layout::default()
                            .direction(LayoutDirection::Horizontal)
                            .constraints([Constraint::Length(1), Constraint::Min(0)])
                            .split(render_area);
                        (layout[1], Some(layout[0]))
                    }
                    ScrollbarOrientation::HorizontalBottom => {
                        let layout = Layout::default()
                            .direction(LayoutDirection::Vertical)
                            .constraints([Constraint::Min(0), Constraint::Length(1)])
                            .split(render_area);
                        (layout[0], Some(layout[1]))
                    }
                    ScrollbarOrientation::HorizontalTop => {
                        let layout = Layout::default()
                            .direction(LayoutDirection::Vertical)
                            .constraints([Constraint::Length(1), Constraint::Min(0)])
                            .split(render_area);
                        (layout[1], Some(layout[0]))
                    }
                }
            } else {
                (render_area, None)
            };

        // Render content
        self.content.render_content(
            frame,
            content_area,
            self.state.scroll_offset,
            self.state.horizontal_offset,
        )?;

        // Render scrollbar if needed
        if let Some(scrollbar_area) = scrollbar_area {
            let scrollbar = Scrollbar::default()
                .orientation(self.config.scrollbar_orientation.clone())
                .style(Style::default().fg(Color::DarkGray));

            frame.render_stateful_widget(scrollbar, scrollbar_area, &mut self.scrollbar_state);
        }

        Ok(())
    }
}

// --- Builder Pattern --------------------------------------------------------

pub struct ScrollviewBuilder {
    config: ScrollviewConfig,
}

impl ScrollviewBuilder {
    pub fn new() -> Self {
        Self {
            config: ScrollviewConfig::default(),
        }
    }

    pub fn show_scrollbar(mut self, show: bool) -> Self {
        self.config.show_scrollbar = show;
        self
    }

    pub fn scrollbar_orientation(mut self, orientation: ScrollbarOrientation) -> Self {
        self.config.scrollbar_orientation = orientation;
        self
    }

    pub fn scroll_step(mut self, step: usize) -> Self {
        self.config.scroll_step = step;
        self
    }

    pub fn page_size(mut self, size: usize) -> Self {
        self.config.page_size = size;
        self
    }

    pub fn focusable(mut self, focusable: bool) -> Self {
        self.config.widget.focusable = focusable;
        self
    }

    pub fn with_border(mut self, border: bool) -> Self {
        self.config.widget.border = border;
        self
    }

    pub fn with_title<S: Into<String>>(mut self, title: S) -> Self {
        self.config.widget.title = Some(title.into());
        self
    }

    pub fn build_with_content(self, content: Box<dyn ScrollableContent>) -> ScrollviewWidget {
        ScrollviewWidget::new(content).with_config(self.config)
    }

    pub fn build_with_text(self, text: &str) -> ScrollviewWidget {
        let content = Box::new(TextContent::from_text(text));
        ScrollviewWidget::new(content).with_config(self.config)
    }
}

impl Default for ScrollviewBuilder {
    fn default() -> Self {
        Self::new()
    }
}
