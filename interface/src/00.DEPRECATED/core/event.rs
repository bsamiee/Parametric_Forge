// Title         : core/event.rs
// Author        : Bardia Samiee
// Project       : Parametric Forge Interface
// License       : MIT
// Path          : interface/src/core/event.rs
// ----------------------------------------------------------------------------

use super::action::{Action, Direction};
use super::state::{Focus, State};
use crossterm::event::{Event as TermEvent, KeyCode, KeyEvent, KeyModifiers};
use once_cell::sync::Lazy;
use rustc_hash::FxHashMap;

// --- Event Key Type ---------------------------------------------------------
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
struct EventKey {
    code: KeyCode,
    modifiers: KeyModifiers,
}

impl EventKey {
    const fn new(code: KeyCode, modifiers: KeyModifiers) -> Self {
        Self { code, modifiers }
    }
}

// --- Focus-aware Action Type ------------------------------------------------
#[derive(Debug, Clone)]
enum FocusAction {
    Global(Action),     // Works in any focus mode
    Navigation(Action), // Only in Navigation focus
    Input(Action),      // Only in Input focus
    InputChar,          // Special case for character input
    Confirm(Action),    // Only in Confirm focus
}

// Macro for efficient dispatch table generation
macro_rules! dispatch_entries {
    (global: $($key:expr => $action:expr),*; nav: $($nkey:expr => $naction:expr),*) => {
        {
            let mut map = FxHashMap::default();
            $(map.insert($key, FocusAction::Global($action));)*
            $(map.insert($nkey, FocusAction::Navigation($naction));)*
            map
        }
    };
}

// Streamlined dispatch table with macro generation
static DISPATCH_TABLE: Lazy<FxHashMap<EventKey, FocusAction>> = Lazy::new(|| {
    let mut map = dispatch_entries! {
        global:
            EventKey::new(KeyCode::Char('q'), KeyModifiers::CONTROL) => Action::Exit,
            EventKey::new(KeyCode::Char('c'), KeyModifiers::CONTROL) => Action::Exit;
        nav:
            EventKey::new(KeyCode::Esc, KeyModifiers::NONE) => Action::Back,
            EventKey::new(KeyCode::Char('q'), KeyModifiers::NONE) => Action::Exit,
            // Arrow keys
            EventKey::new(KeyCode::Up, KeyModifiers::NONE) => Action::Move(Direction::Up),
            EventKey::new(KeyCode::Down, KeyModifiers::NONE) => Action::Move(Direction::Down),
            EventKey::new(KeyCode::Left, KeyModifiers::NONE) => Action::Move(Direction::Left),
            EventKey::new(KeyCode::Right, KeyModifiers::NONE) => Action::Move(Direction::Right),
            // Vim keys
            EventKey::new(KeyCode::Char('k'), KeyModifiers::NONE) => Action::Move(Direction::Up),
            EventKey::new(KeyCode::Char('j'), KeyModifiers::NONE) => Action::Move(Direction::Down),
            EventKey::new(KeyCode::Char('h'), KeyModifiers::NONE) => Action::Move(Direction::Left),
            EventKey::new(KeyCode::Char('l'), KeyModifiers::NONE) => Action::Move(Direction::Right)
    };

    // Page navigation with modifier variants
    for modifier in [KeyModifiers::NONE, KeyModifiers::SHIFT, KeyModifiers::CONTROL] {
        map.insert(
            EventKey::new(KeyCode::PageUp, modifier),
            FocusAction::Navigation(Action::Move(Direction::PageUp)),
        );
        map.insert(
            EventKey::new(KeyCode::PageDown, modifier),
            FocusAction::Navigation(Action::Move(Direction::PageDown)),
        );
        map.insert(
            EventKey::new(KeyCode::Home, modifier),
            FocusAction::Navigation(Action::Move(Direction::Home)),
        );
        map.insert(
            EventKey::new(KeyCode::End, modifier),
            FocusAction::Navigation(Action::Move(Direction::End)),
        );
    }

    // Additional navigation shortcuts
    map.extend([
        (
            EventKey::new(KeyCode::Char('g'), KeyModifiers::NONE),
            FocusAction::Navigation(Action::Move(Direction::Home)),
        ),
        (
            EventKey::new(KeyCode::Char('G'), KeyModifiers::SHIFT),
            FocusAction::Navigation(Action::Move(Direction::End)),
        ),
        (
            EventKey::new(KeyCode::Char('u'), KeyModifiers::CONTROL),
            FocusAction::Navigation(Action::Move(Direction::PageUp)),
        ),
        (
            EventKey::new(KeyCode::Char('d'), KeyModifiers::CONTROL),
            FocusAction::Navigation(Action::Move(Direction::PageDown)),
        ),
    ]);

    // Selection and tab navigation
    map.extend([
        (
            EventKey::new(KeyCode::Enter, KeyModifiers::NONE),
            FocusAction::Navigation(Action::Select),
        ),
        (
            EventKey::new(KeyCode::Char(' '), KeyModifiers::NONE),
            FocusAction::Navigation(Action::Select),
        ),
        (
            EventKey::new(KeyCode::Tab, KeyModifiers::NONE),
            FocusAction::Navigation(Action::NextTab),
        ),
        (
            EventKey::new(KeyCode::BackTab, KeyModifiers::SHIFT),
            FocusAction::Navigation(Action::PrevTab),
        ),
        (
            EventKey::new(KeyCode::Char('t'), KeyModifiers::CONTROL),
            FocusAction::Navigation(Action::NextTab),
        ),
        (
            EventKey::new(KeyCode::Char('w'), KeyModifiers::CONTROL),
            FocusAction::Navigation(Action::Exit),
        ),
    ]);

    // Direct tab access (1-5)
    for (i, ch) in ['1', '2', '3', '4', '5'].iter().enumerate() {
        map.insert(
            EventKey::new(KeyCode::Char(*ch), KeyModifiers::NONE),
            FocusAction::Navigation(Action::SelectTab(i)),
        );
    }

    map
});

// Consolidated input/confirm dispatch tables
static INPUT_DISPATCH: Lazy<FxHashMap<EventKey, Action>> = Lazy::new(|| {
    let mut map = FxHashMap::default();
    map.extend([
        (EventKey::new(KeyCode::Esc, KeyModifiers::NONE), Action::Back),
        (EventKey::new(KeyCode::Enter, KeyModifiers::NONE), Action::Submit),
    ]);

    // Delete keys with all modifier variants
    for key in [KeyCode::Backspace, KeyCode::Delete] {
        for modifier in [KeyModifiers::NONE, KeyModifiers::SHIFT, KeyModifiers::CONTROL] {
            map.insert(EventKey::new(key, modifier), Action::DeleteChar);
        }
    }
    map
});

static CONFIRM_DISPATCH: Lazy<FxHashMap<EventKey, Action>> = Lazy::new(|| {
    let mut map = FxHashMap::default();
    map.extend([
        (EventKey::new(KeyCode::Char('y'), KeyModifiers::NONE), Action::Submit),
        (EventKey::new(KeyCode::Char('Y'), KeyModifiers::NONE), Action::Submit),
        (EventKey::new(KeyCode::Char('Y'), KeyModifiers::SHIFT), Action::Submit),
        (EventKey::new(KeyCode::Char('n'), KeyModifiers::NONE), Action::Back),
        (EventKey::new(KeyCode::Char('N'), KeyModifiers::NONE), Action::Back),
        (EventKey::new(KeyCode::Char('N'), KeyModifiers::SHIFT), Action::Back),
        (EventKey::new(KeyCode::Esc, KeyModifiers::NONE), Action::Back),
        (EventKey::new(KeyCode::Enter, KeyModifiers::NONE), Action::Submit),
    ]);
    map
});

// --- Event Mapping (Public API) ---------------------------------------------
pub fn map_event(event: TermEvent, state: &State) -> Option<Action> {
    match event {
        TermEvent::Key(key) => map_key_optimized(key, state),
        TermEvent::Resize(..) => None, // Handle in render
        _ => None,
    }
}

// --- Optimized Key Mapping with Dispatch Tables ----------------------------
fn map_key_optimized(key: KeyEvent, state: &State) -> Option<Action> {
    // Don't process key releases or repeats
    if key.kind != crossterm::event::KeyEventKind::Press {
        return None;
    }

    let event_key = EventKey::new(key.code, key.modifiers);

    // Check main dispatch table first
    if let Some(focus_action) = DISPATCH_TABLE.get(&event_key) {
        return match (focus_action, &state.ui.focus) {
            (FocusAction::Global(action), _) => Some(action.clone()),
            (FocusAction::Navigation(action), Focus::Navigation) => Some(action.clone()),
            _ => None,
        };
    }

    // Handle focus-specific dispatching
    match &state.ui.focus {
        Focus::Input(_) => {
            // Check input-specific keys
            if let Some(action) = INPUT_DISPATCH.get(&event_key) {
                return Some(action.clone());
            }

            // Handle character input (special case)
            if let KeyCode::Char(c) = key.code {
                if key.modifiers == KeyModifiers::NONE || key.modifiers == KeyModifiers::SHIFT {
                    return Some(Action::AppendChar(c));
                }
            }
            None
        }

        Focus::Confirm => {
            // Check confirm-specific keys
            CONFIRM_DISPATCH.get(&event_key).cloned()
        }

        _ => None,
    }
}
