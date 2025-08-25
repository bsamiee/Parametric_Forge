// Title         : functionality/core/events.rs
// Author        : Bardia Samiee
// Project       : Parametric Forge
// License       : MIT
// Path          : interface/src/functionality/core/events.rs
// ----------------------------------------------------------------------------
//! Event dispatch system with compile-time optimization and spatial integration

use super::geometry::Direction;
use super::modes::AppMode;
use super::feedback::FeedbackLevel;
use super::state::ComponentId;
use crossterm::event::{KeyCode, KeyEvent, KeyModifiers, MouseEvent, MouseEventKind};
use bitflags::bitflags;
use derive_more::{Constructor, From, Display, Into, Deref};
use once_cell::sync::Lazy;
use rustc_hash::FxHashMap;
use tinyvec::TinyVec;
use compact_str::CompactString;
use std::marker::PhantomData;

// --- Event Spaces ------------------------------------------------------------

pub struct GlobalSpace;
pub struct NavigationSpace;
pub struct InputSpace;
pub struct TabSpace;

// --- Event Classification ----------------------------------------------------

bitflags! {
    #[derive(Clone, Copy, PartialEq, Eq, Hash)]
    pub struct EventClass: u8 {
        const NAV = 1; const INPUT = 2; const MOUSE = 4; const FOCUS = 8;
        const BATCH = 16; const SYSTEM = 32;
        const ENHANCED = Self::NAV.bits() | Self::FOCUS.bits();
    }
}

bitflags! {
    pub struct FocusContext: u16 {
        const GLOBAL = 1; const NAVIGATION = 2; const INPUT = 4; const CONFIRM = 8;
        const TAB_MANAGEMENT = 16; const MODE_AWARE = 32; const FEEDBACK_ACTIVE = 64;
        const ENHANCED = Self::TAB_MANAGEMENT.bits() | Self::MODE_AWARE.bits();
    }
}

// --- Phantom Type Events -----------------------------------------------------

#[derive(Debug, Clone, Copy, Constructor, Deref)]
pub struct Event<S = GlobalSpace> {
    #[deref] pub class: EventClass,
    pub direction: Option<Direction>,
    pub position: Option<(u16, u16)>,
    pub modifiers: KeyModifiers,
    _space: PhantomData<S>,
}

impl<S> Event<S> {
    pub fn to_space<T>(self) -> Event<T> {
        Event::new(self.class, self.direction, self.position, self.modifiers, PhantomData)
    }
}

// --- Action System -----------------------------------------------------------

#[derive(Debug, Clone)]
pub enum Action {
    Navigate(Direction), Select(usize),
    #[display("Mouse({}, {})", _0, _1)]
    Mouse(u16, u16), Input(char),
    TabNext, TabPrev, TabSelect(usize), ModeTransition(AppMode),
    FeedbackAdd(FeedbackLevel, CompactString), Exit, Refresh,
}

// --- Static Dispatch Tables --------------------------------------------------

type EventKey = (KeyCode, KeyModifiers);
type DispatchEntry = (Action, FocusContext);

static DISPATCH_TABLE: Lazy<FxHashMap<EventKey, DispatchEntry>> = Lazy::new(|| {
    use KeyCode::*; use Direction::*; use FocusContext::*;
    [
        // System
        ((Char('q'), KeyModifiers::CONTROL), (Action::Exit, GLOBAL)),
        ((F(5), KeyModifiers::NONE), (Action::Refresh, GLOBAL)),

        // Navigation
        ((Up, KeyModifiers::NONE), (Action::Navigate(Up), NAVIGATION)),
        ((Down, KeyModifiers::NONE), (Action::Navigate(Down), NAVIGATION)),
        ((Left, KeyModifiers::NONE), (Action::Navigate(Left), NAVIGATION)),
        ((Right, KeyModifiers::NONE), (Action::Navigate(Right), NAVIGATION)),
        ((Home, KeyModifiers::NONE), (Action::Navigate(Home), NAVIGATION)),
        ((End, KeyModifiers::NONE), (Action::Navigate(End), NAVIGATION)),
        ((PageUp, KeyModifiers::NONE), (Action::Navigate(PageUp), NAVIGATION)),
        ((PageDown, KeyModifiers::NONE), (Action::Navigate(PageDown), NAVIGATION)),

        // Vim bindings - basic navigation
        ((Char('k'), KeyModifiers::NONE), (Action::Navigate(Up), NAVIGATION)),
        ((Char('j'), KeyModifiers::NONE), (Action::Navigate(Down), NAVIGATION)),
        ((Char('h'), KeyModifiers::NONE), (Action::Navigate(Left), NAVIGATION)),
        ((Char('l'), KeyModifiers::NONE), (Action::Navigate(Right), NAVIGATION)),

        // Vim bindings - page navigation
        ((Char('u'), KeyModifiers::CONTROL), (Action::Navigate(PageUp), NAVIGATION)),
        ((Char('d'), KeyModifiers::CONTROL), (Action::Navigate(PageDown), NAVIGATION)),
        ((Char('g'), KeyModifiers::NONE), (Action::Navigate(Home), NAVIGATION)),
        ((Char('G'), KeyModifiers::SHIFT), (Action::Navigate(End), NAVIGATION)),

        // Tab management
        ((Tab, KeyModifiers::NONE), (Action::TabNext, TAB_MANAGEMENT)),
        ((BackTab, KeyModifiers::SHIFT), (Action::TabPrev, TAB_MANAGEMENT)),

        // Direct tab access
        ((Char('1'), KeyModifiers::ALT), (Action::TabSelect(0), TAB_MANAGEMENT)),
        ((Char('2'), KeyModifiers::ALT), (Action::TabSelect(1), TAB_MANAGEMENT)),
        ((Char('3'), KeyModifiers::ALT), (Action::TabSelect(2), TAB_MANAGEMENT)),
    ].into_iter().collect()
});

// --- Event Dispatcher --------------------------------------------------------

pub struct EventDispatcher;

impl EventDispatcher {
    pub fn dispatch(event: KeyEvent, focus: FocusContext, mode: AppMode) -> Option<Action> {
        let key = (event.code, event.modifiers);
        DISPATCH_TABLE.get(&key)
            .filter(|(_, context)| context.intersects(focus | FocusContext::GLOBAL))
            .map(|(action, _)| action.clone())
            .or_else(|| Self::mode_dispatch(key, mode))
    }

    fn mode_dispatch(key: EventKey, mode: AppMode) -> Option<Action> {
        use KeyCode::*;
        match (mode, key) {
            (AppMode::Configure, (Char('r'), KeyModifiers::CONTROL)) => Some(Action::Refresh),
            (AppMode::Manage, (Char('b'), KeyModifiers::CONTROL)) =>
                Some(Action::ModeTransition(AppMode::Configure)),
            _ => None,
        }
    }

    pub fn batch_process(events: TinyVec<[KeyEvent; 8]>, focus: FocusContext, mode: AppMode)
        -> TinyVec<[Action; 8]> {
        events.iter().filter_map(|&e| Self::dispatch(e, focus, mode)).collect()
    }
}

// --- Mouse Integration -------------------------------------------------------

impl EventDispatcher {
    /// Main mouse event handler with full support for all mouse interactions
    pub fn handle_mouse(event: MouseEvent) -> Option<Action> {
        use MouseEventKind::*;
        match event.kind {
            Down(_) | Up(_) => Some(Action::Mouse(event.column, event.row)),
            ScrollUp => Some(Action::Navigate(Direction::Up)),
            ScrollDown => Some(Action::Navigate(Direction::Down)),
            ScrollLeft => Some(Action::Navigate(Direction::Left)),
            ScrollRight => Some(Action::Navigate(Direction::Right)),
            Drag(_) => Some(Action::Mouse(event.column, event.row)),
            Moved => None, // Optional: track hover if needed
        }
    }

    /// Convert mouse event to navigation direction (for scroll/gesture support)
    pub fn mouse_to_direction(event: &MouseEvent) -> Option<Direction> {
        use MouseEventKind::*;
        match event.kind {
            ScrollUp => Some(Direction::Up),
            ScrollDown => Some(Direction::Down),
            ScrollLeft => Some(Direction::Left),
            ScrollRight => Some(Direction::Right),
            _ => None,
        }
    }

    /// Handle batch of mouse events efficiently
    pub fn handle_mouse_batch(events: &[MouseEvent]) -> TinyVec<[Action; 8]> {
        let mut actions = TinyVec::new();
        for event in events.iter().take(8) {
            if let Some(action) = Self::handle_mouse(*event) {
                actions.push(action);
            }
        }
        actions
    }
}