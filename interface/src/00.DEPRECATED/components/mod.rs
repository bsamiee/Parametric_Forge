// Title         : components/mod.rs
// Author        : Bardia Samiee
// Project       : Parametric Forge Interface
// License       : MIT
// Path          : interface/src/components/mod.rs
// ----------------------------------------------------------------------------

mod registry;
mod router;

pub use registry::ComponentRegistry;
pub use router::{ActionRouter, ComponentId};

use crate::core::Action;
use crate::layouts::BorderSpec;
use color_eyre::eyre::Result;
use crossterm::event::{Event, KeyEvent, MouseEvent};
use ratatui::{
    layout::Rect,
    widgets::{Block, Borders, Paragraph},
    Frame,
};
use std::sync::mpsc::Sender;

// --- Event Interest System --------------------------------------------------
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct EventInterestMask(u16);

impl EventInterestMask {
    pub const NONE: Self = Self(0);
    pub const KEY_PRESS: Self = Self(1 << 0);
    pub const KEY_RELEASE: Self = Self(1 << 1);
    pub const KEY_REPEAT: Self = Self(1 << 2);
    pub const MOUSE_MOVE: Self = Self(1 << 3);
    pub const MOUSE_CLICK: Self = Self(1 << 4);
    pub const MOUSE_SCROLL: Self = Self(1 << 5);
    pub const MOUSE_DRAG: Self = Self(1 << 6);
    pub const RESIZE: Self = Self(1 << 7);
    pub const FOCUS_EVENTS: Self = Self(1 << 8);
    pub const PASTE: Self = Self(1 << 9);
    pub const ALL_KEYS: Self = Self(7); // 0b111
    pub const ALL_MOUSE: Self = Self(120); // 0b1111000
    pub const INTERACTIVE: Self = Self(263); // ALL_KEYS | MOUSE_CLICK | FOCUS_EVENTS
    pub const ALL: Self = Self(0xFFFF);

    pub const fn with(self, mask: EventInterestMask) -> Self {
        Self(self.0 | mask.0)
    }

    pub fn matches(&self, event: &Event) -> bool {
        let flag = match event {
            Event::Key(KeyEvent {
                kind: crossterm::event::KeyEventKind::Press,
                ..
            }) => Self::KEY_PRESS.0,
            Event::Key(KeyEvent {
                kind: crossterm::event::KeyEventKind::Release,
                ..
            }) => Self::KEY_RELEASE.0,
            Event::Key(KeyEvent {
                kind: crossterm::event::KeyEventKind::Repeat,
                ..
            }) => Self::KEY_REPEAT.0,
            Event::Mouse(MouseEvent {
                kind: crossterm::event::MouseEventKind::Moved,
                ..
            }) => Self::MOUSE_MOVE.0,
            Event::Mouse(MouseEvent {
                kind: crossterm::event::MouseEventKind::Down(_) | crossterm::event::MouseEventKind::Up(_),
                ..
            }) => Self::MOUSE_CLICK.0,
            Event::Mouse(MouseEvent {
                kind:
                    crossterm::event::MouseEventKind::ScrollDown
                    | crossterm::event::MouseEventKind::ScrollUp
                    | crossterm::event::MouseEventKind::ScrollLeft
                    | crossterm::event::MouseEventKind::ScrollRight,
                ..
            }) => Self::MOUSE_SCROLL.0,
            Event::Mouse(MouseEvent {
                kind: crossterm::event::MouseEventKind::Drag(_),
                ..
            }) => Self::MOUSE_DRAG.0,
            Event::Resize(_, _) => Self::RESIZE.0,
            Event::Paste(_) => Self::PASTE.0,
            Event::FocusGained | Event::FocusLost => Self::FOCUS_EVENTS.0,
        };
        (self.0 & flag) != 0
    }
}

impl Default for EventInterestMask {
    fn default() -> Self {
        Self::INTERACTIVE
    }
}

// --- Component Trait --------------------------------------------------------
pub trait Component: Send {
    fn init(&mut self, _area: Rect) -> Result<()> {
        Ok(())
    }
    fn register_action_handler(&mut self, _tx: Sender<Action>) -> Result<()> {
        Ok(())
    }
    fn event_interest(&self) -> EventInterestMask {
        EventInterestMask::default()
    }
    fn handle_events(&mut self, _event: Option<Event>) -> Result<Option<Action>> {
        Ok(None)
    }
    fn update(&mut self, _action: Action) -> Result<Option<Action>> {
        Ok(None)
    }
    fn draw(&mut self, frame: &mut Frame, area: Rect, border: Option<&BorderSpec>) -> Result<()>;
    fn can_focus(&self) -> bool {
        false
    }
    fn on_focus(&mut self) -> Result<()> {
        Ok(())
    }
    fn on_blur(&mut self) -> Result<()> {
        Ok(())
    }
}

// --- Stateful Component Trait -----------------------------------------------
pub trait StatefulComponent: Component {
    type State: Default + Send;
    fn state(&self) -> &Self::State;
    fn state_mut(&mut self) -> &mut Self::State;
}

// --- Component Types --------------------------------------------------------
#[derive(Debug)]
pub enum ComponentType {
    Header(HeaderComponent),
    Footer(FooterComponent),
    Main(MainComponent),
    Sidebar(SidebarComponent),
}

#[derive(Debug, Default)]
pub struct HeaderComponent;

#[derive(Debug, Default)]
pub struct FooterComponent;

#[derive(Debug, Default)]
pub struct MainComponent;

#[derive(Debug, Default)]
pub struct SidebarComponent;

// --- Macro for Component Dispatch -------------------------------------------
macro_rules! component_dispatch {
    ($self:expr, $method:ident $(, $($arg:expr),*)?) => {
        match $self {
            ComponentType::Header(c) => c.$method($($($arg),*)?),
            ComponentType::Footer(c) => c.$method($($($arg),*)?),
            ComponentType::Main(c) => c.$method($($($arg),*)?),
            ComponentType::Sidebar(c) => c.$method($($($arg),*)?),
        }
    };
}

impl Component for ComponentType {
    fn init(&mut self, area: Rect) -> Result<()> {
        component_dispatch!(self, init, area)
    }
    fn register_action_handler(&mut self, tx: Sender<Action>) -> Result<()> {
        component_dispatch!(self, register_action_handler, tx)
    }
    fn event_interest(&self) -> EventInterestMask {
        component_dispatch!(self, event_interest)
    }
    fn handle_events(&mut self, event: Option<Event>) -> Result<Option<Action>> {
        component_dispatch!(self, handle_events, event)
    }
    fn update(&mut self, action: Action) -> Result<Option<Action>> {
        component_dispatch!(self, update, action)
    }
    fn draw(&mut self, frame: &mut Frame, area: Rect, border: Option<&BorderSpec>) -> Result<()> {
        component_dispatch!(self, draw, frame, area, border)
    }
    fn can_focus(&self) -> bool {
        component_dispatch!(self, can_focus)
    }
    fn on_focus(&mut self) -> Result<()> {
        component_dispatch!(self, on_focus)
    }
    fn on_blur(&mut self) -> Result<()> {
        component_dispatch!(self, on_blur)
    }
}

// --- Component Implementations ----------------------------------------------
fn draw_component(frame: &mut Frame, area: Rect, text: &str) {
    let widget = Paragraph::new(text).block(Block::default().borders(Borders::ALL));
    frame.render_widget(widget, area);
}

impl Component for HeaderComponent {
    fn draw(&mut self, frame: &mut Frame, area: Rect, _border: Option<&BorderSpec>) -> Result<()> {
        draw_component(frame, area, "Header");
        Ok(())
    }
}

impl Component for FooterComponent {
    fn draw(&mut self, frame: &mut Frame, area: Rect, _border: Option<&BorderSpec>) -> Result<()> {
        draw_component(frame, area, "Footer");
        Ok(())
    }
}

impl Component for MainComponent {
    fn draw(&mut self, frame: &mut Frame, area: Rect, _border: Option<&BorderSpec>) -> Result<()> {
        draw_component(frame, area, "Main Content");
        Ok(())
    }
    fn can_focus(&self) -> bool {
        true
    }
}

impl Component for SidebarComponent {
    fn draw(&mut self, frame: &mut Frame, area: Rect, _border: Option<&BorderSpec>) -> Result<()> {
        draw_component(frame, area, "Sidebar");
        Ok(())
    }
    fn can_focus(&self) -> bool {
        true
    }
}
