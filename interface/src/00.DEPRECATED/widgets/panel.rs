// Title         : widgets/panel.rs
// Author        : Bardia Samiee
// Project       : Parametric Forge Interface
// License       : MIT
// Path          : interface/src/widgets/panel.rs
// ----------------------------------------------------------------------------

//! Composable panel container system for dynamic widget composition

use color_eyre::eyre::Result;
use crossterm::event::Event;
use indexmap::IndexMap;
use ratatui::{
    layout::{Constraint, Rect},
    style::{Color, Style},
    text::Span,
    widgets::Paragraph,
    Frame,
};
use std::sync::mpsc::Sender;

use super::{apply_border, FocusManager, WidgetConfig, WidgetState};
use crate::{
    components::{Component, ComponentId},
    core::{calculate_index, Action, Direction, State},
    layouts::{BorderSpec, LayoutBuilder, LayoutCalculation, LayoutType},
};

// --- Panel Configuration ---------------------------------------------------

#[derive(Debug, Clone)]
pub struct PanelConfig {
    pub title: Option<String>,
    pub collapsible: bool,
    pub resizable: bool,
    pub scrollable: bool,
    pub widget: WidgetConfig,
}

impl Default for PanelConfig {
    fn default() -> Self {
        Self {
            title: None,
            collapsible: false,
            resizable: false,
            scrollable: false,
            widget: WidgetConfig::default(),
        }
    }
}

// --- Panel State -----------------------------------------------------------

#[derive(Debug, Clone)]
pub struct PanelState {
    pub collapsed: bool,
    pub focused_child: Option<ComponentId>,
    pub scroll_offset: u16,
    pub is_dirty: bool,
    pub is_focused: bool,
}

impl Default for PanelState {
    fn default() -> Self {
        Self {
            collapsed: false,
            focused_child: None,
            scroll_offset: 0,
            is_dirty: false,
            is_focused: false,
        }
    }
}

impl WidgetState for PanelState {
    fn reset(&mut self) {
        self.collapsed = false;
        self.focused_child = None;
        self.scroll_offset = 0;
        self.is_dirty = false;
        self.is_focused = false;
    }

    fn is_dirty(&self) -> bool {
        self.is_dirty
    }
}

impl super::FocusManager for PanelState {
    fn is_widget_focused(&self) -> bool {
        self.is_focused
    }

    fn set_widget_focused(&mut self, focused: bool) {
        self.is_focused = focused;
    }
}

// --- Panel Child Entry -----------------------------------------------------

struct PanelChild {
    component: Box<dyn Component>,
    constraint: Constraint,
    visible: bool,
}

// --- Panel Widget ----------------------------------------------------------

pub struct PanelWidget {
    config: PanelConfig,
    state: PanelState,
    children: IndexMap<ComponentId, PanelChild>,
    child_order: Vec<ComponentId>,
    layout: LayoutType,
    action_tx: Option<Sender<Action>>,
}

impl PanelWidget {
    pub fn new() -> Self {
        Self {
            config: PanelConfig::default(),
            state: PanelState::default(),
            children: IndexMap::new(),
            child_order: Vec::new(),
            layout: LayoutType::Builder(LayoutBuilder::vertical()),
            action_tx: None,
        }
    }

    pub fn with_config(mut self, config: PanelConfig) -> Self {
        self.config = config;
        self
    }

    pub fn with_title(mut self, title: String) -> Self {
        self.config.title = Some(title);
        self
    }

    pub fn with_layout(mut self, layout: LayoutType) -> Self {
        self.layout = layout;
        self
    }

    pub fn add_child<C: Component + 'static>(mut self, id: ComponentId, component: C, constraint: Constraint) -> Self {
        let child = PanelChild {
            component: Box::new(component),
            constraint,
            visible: true,
        };

        self.children.insert(id.clone(), child);
        self.child_order.push(id);
        self.state.is_dirty = true;
        self
    }

    pub fn set_child_visibility(&mut self, id: &ComponentId, visible: bool) {
        if let Some(child) = self.children.get_mut(id) {
            child.visible = visible;
            self.state.is_dirty = true;
        }
    }

    pub fn remove_child(&mut self, id: &ComponentId) -> Option<Box<dyn Component>> {
        if let Some(child) = self.children.swap_remove(id) {
            self.child_order.retain(|child_id| child_id != id);
            self.state.is_dirty = true;
            Some(child.component)
        } else {
            None
        }
    }

    pub fn get_child_count(&self) -> usize {
        self.children.len()
    }

    pub fn is_empty(&self) -> bool {
        self.children.is_empty()
    }

    // --- Validation Coordination --------------------------------------------

    /// Validate all child components that support validation
    pub fn validate_all_children(&mut self) -> bool {
        for (_, child) in &mut self.children {
            // Trigger validation on child components
            let _ = child.component.update(Action::Submit);
        }
        true // Core state now handles validation aggregation
    }

    /// Clear validation errors for all child components
    pub fn clear_all_validation_errors(&mut self) {
        if let Some(tx) = &self.action_tx {
            let _ = tx.send(Action::ClearError);
        }
    }

    // --- Focus Management ---------------------------------------------------

    pub fn focus_child(&mut self, id: ComponentId) -> Result<()> {
        // Blur current child
        if let Some(ref current_id) = self.state.focused_child {
            if let Some(child) = self.children.get_mut(current_id) {
                child.component.on_blur()?;
            }
        }

        // Focus new child
        if self.children.contains_key(&id) {
            self.state.focused_child = Some(id.clone());
            if let Some(child) = self.children.get_mut(&id) {
                child.component.on_focus()?;
            }
        }

        Ok(())
    }

    pub fn focus_next_child(&mut self) -> Result<()> {
        if self.child_order.is_empty() {
            return Ok(());
        }

        let current_index = if let Some(ref current_id) = self.state.focused_child {
            self.child_order.iter().position(|id| id == current_id).unwrap_or(0)
        } else {
            0
        };

        // Use core's calculate_index for consistent navigation
        let next_index = calculate_index(current_index, self.child_order.len(), Direction::Down);

        if let Some(next_id) = self.child_order.get(next_index) {
            self.focus_child(next_id.clone())?;
        }

        Ok(())
    }

    pub fn focus_previous_child(&mut self) -> Result<()> {
        if self.child_order.is_empty() {
            return Ok(());
        }

        let current_index = if let Some(ref current_id) = self.state.focused_child {
            self.child_order.iter().position(|id| id == current_id).unwrap_or(0)
        } else {
            0
        };

        // Use core's calculate_index for consistent navigation
        let prev_index = calculate_index(current_index, self.child_order.len(), Direction::Up);

        if let Some(prev_id) = self.child_order.get(prev_index) {
            self.focus_child(prev_id.clone())?;
        }

        Ok(())
    }

    // --- Panel Actions ------------------------------------------------------

    pub fn toggle_collapse(&mut self) {
        if self.config.collapsible {
            self.state.collapsed = !self.state.collapsed;
            self.state.is_dirty = true;
        }
    }

    pub fn set_collapsed(&mut self, collapsed: bool) {
        if self.config.collapsible {
            self.state.collapsed = collapsed;
            self.state.is_dirty = true;
        }
    }

    // --- Layout Management --------------------------------------------------

    fn calculate_child_layout(&self, area: Rect) -> Result<LayoutCalculation> {
        // TODO: This is a design limitation - panels are widgets that contain layouts,
        // but widgets don't have access to global State during draw.
        // For now, we create a minimal state just for layout calculation.
        // A better design would be to separate panel layouts from widget panels.
        let temp_state = self.create_minimal_state();
        Ok(self.layout.calculate(area, &temp_state))
    }

    fn create_minimal_state(&self) -> State {
        use crate::core::{Context, Mode};
        use serde_json::Value;

        let context = Context {
            system: "unknown".to_string(),
            is_darwin: false,
            is_linux: false,
            user: "unknown".to_string(),
            has_nix: false,
            has_config: false,
        };

        State::new(Mode::Manage, context, Value::Null)
    }

    // --- Rendering ----------------------------------------------------------

    fn render_title(&self, frame: &mut Frame, area: Rect) {
        if let Some(ref title) = self.config.title {
            let title_style = if self.state.collapsed {
                Style::default().fg(Color::DarkGray)
            } else {
                Style::default().fg(Color::White)
            };

            let title_text = if self.config.collapsible {
                let indicator = if self.state.collapsed { "▶" } else { "▼" };
                format!("{} {}", indicator, title)
            } else {
                title.clone()
            };

            let title_span = Span::styled(title_text, title_style);
            let title_paragraph = Paragraph::new(title_span);
            frame.render_widget(title_paragraph, area);
        }
    }

    fn render_children(&mut self, frame: &mut Frame, area: Rect) -> Result<()> {
        if self.state.collapsed {
            return Ok(());
        }

        let layout_calc = self.calculate_child_layout(area)?;
        let layout_result = layout_calc.result;

        // Render visible children in their calculated areas
        for child_id in &self.child_order {
            if let Some(child) = self.children.get_mut(child_id) {
                if !child.visible {
                    continue;
                }

                if let Some(child_area) = layout_result.areas.get(child_id) {
                    let child_border = layout_result.borders.get(child_id);
                    child.component.draw(frame, *child_area, child_border)?;
                }
            }
        }

        Ok(())
    }

    fn render_empty_state(&self, frame: &mut Frame, area: Rect) {
        if !self.is_empty() || self.state.collapsed {
            return;
        }

        let empty_text = "No content";
        let empty_paragraph = Paragraph::new(empty_text).style(Style::default().fg(Color::DarkGray));
        frame.render_widget(empty_paragraph, area);
    }
}

// --- Component Implementation -----------------------------------------------

impl Component for PanelWidget {
    fn register_action_handler(&mut self, tx: Sender<Action>) -> Result<()> {
        self.action_tx = Some(tx.clone());

        // Register action handlers for all child components
        for (_, child) in &mut self.children {
            child.component.register_action_handler(tx.clone())?;
        }

        Ok(())
    }

    fn handle_events(&mut self, event: Option<Event>) -> Result<Option<Action>> {
        use crossterm::event::{KeyCode, KeyModifiers};

        if let Some(Event::Key(key)) = event {
            match (key.code, key.modifiers) {
                // Panel-specific controls
                (KeyCode::Char(' '), KeyModifiers::CONTROL) => {
                    self.toggle_collapse();
                    Ok(None)
                }

                // Child navigation
                (KeyCode::Tab, KeyModifiers::NONE) => {
                    self.focus_next_child()?;
                    Ok(None)
                }
                (KeyCode::BackTab, KeyModifiers::SHIFT) => {
                    self.focus_previous_child()?;
                    Ok(None)
                }

                // Delegate to focused child
                _ => {
                    if let Some(ref focused_id) = self.state.focused_child.clone() {
                        if let Some(child) = self.children.get_mut(focused_id) {
                            return child.component.handle_events(event);
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
            Action::Move(Direction::Down) => {
                self.focus_next_child()?;
                Ok(None)
            }
            Action::Move(Direction::Up) => {
                self.focus_previous_child()?;
                Ok(None)
            }
            Action::Submit => {
                // Trigger validation on all children when form is submitted
                self.validate_all_children();

                // Forward submit action to all children
                for (_, child) in &mut self.children {
                    child.component.update(action.clone())?;
                }
                Ok(Some(action))
            }
            Action::SetError(_) | Action::ClearError => {
                // Forward validation actions to all children
                for (_, child) in &mut self.children {
                    child.component.update(action.clone())?;
                }
                Ok(None)
            }
            _ => {
                // Update all child components
                for (_, child) in &mut self.children {
                    child.component.update(action.clone())?;
                }
                Ok(None)
            }
        }
    }

    fn draw(&mut self, frame: &mut Frame, area: Rect, border: Option<&BorderSpec>) -> Result<()> {
        let render_area = apply_border(frame, area, border, None, self.state.is_focused, None);

        // Render title if present
        if self.config.title.is_some() {
            let title_area = Rect {
                x: render_area.x,
                y: render_area.y,
                width: render_area.width,
                height: 1,
            };
            self.render_title(frame, title_area);

            // Adjust content area to account for title
            let content_area = Rect {
                x: render_area.x,
                y: render_area.y + 1,
                width: render_area.width,
                height: render_area.height.saturating_sub(1),
            };

            self.render_children(frame, content_area)?;
            self.render_empty_state(frame, content_area);
        } else {
            self.render_children(frame, render_area)?;
            self.render_empty_state(frame, render_area);
        }

        Ok(())
    }

    fn can_focus(&self) -> bool {
        self.config.widget.focusable && !self.children.is_empty()
    }

    fn on_focus(&mut self) -> Result<()> {
        self.state.set_widget_focused(true);
        // Focus first focusable child if none is focused
        if self.state.focused_child.is_none() {
            for child_id in &self.child_order {
                if let Some(child) = self.children.get(child_id) {
                    if child.component.can_focus() {
                        self.focus_child(child_id.clone())?;
                        break;
                    }
                }
            }
        }
        Ok(())
    }

    fn on_blur(&mut self) -> Result<()> {
        self.state.set_widget_focused(false);
        // Blur current focused child
        if let Some(ref focused_id) = self.state.focused_child {
            if let Some(child) = self.children.get_mut(focused_id) {
                child.component.on_blur()?;
            }
        }
        Ok(())
    }
}

// --- Builder Pattern -------------------------------------------------------

pub struct PanelBuilder {
    panel: PanelWidget,
}

impl PanelBuilder {
    pub fn new() -> Self {
        Self {
            panel: PanelWidget::new(),
        }
    }

    pub fn vertical() -> Self {
        Self {
            panel: PanelWidget::new().with_layout(LayoutType::Builder(LayoutBuilder::vertical())),
        }
    }

    pub fn horizontal() -> Self {
        Self {
            panel: PanelWidget::new().with_layout(LayoutType::Builder(LayoutBuilder::horizontal())),
        }
    }

    pub fn title(mut self, title: &str) -> Self {
        self.panel.config.title = Some(title.to_string());
        self
    }

    pub fn collapsible(mut self, collapsible: bool) -> Self {
        self.panel.config.collapsible = collapsible;
        self
    }

    pub fn resizable(mut self, resizable: bool) -> Self {
        self.panel.config.resizable = resizable;
        self
    }

    pub fn scrollable(mut self, scrollable: bool) -> Self {
        self.panel.config.scrollable = scrollable;
        self
    }

    pub fn add_child<C: Component + 'static>(mut self, id: ComponentId, component: C, constraint: Constraint) -> Self {
        self.panel = self.panel.add_child(id, component, constraint);
        self
    }

    pub fn with_layout(mut self, layout: LayoutType) -> Self {
        self.panel = self.panel.with_layout(layout);
        self
    }

    pub fn build(self) -> PanelWidget {
        self.panel
    }
}

impl Default for PanelBuilder {
    fn default() -> Self {
        Self::new()
    }
}
