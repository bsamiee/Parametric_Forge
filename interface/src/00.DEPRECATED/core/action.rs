// Title         : core/action.rs
// Author        : Bardia Samiee
// Project       : Parametric Forge Interface
// License       : MIT
// Path          : interface/src/core/action.rs
// ----------------------------------------------------------------------------

use super::state::{Focus, Mode, State, Transition};
use std::borrow::Cow;
use strum::{Display, EnumIter, EnumString};

// --- Actions ----------------------------------------------------------------
#[derive(Clone, Debug, PartialEq)]
pub enum Action {
    // Navigation
    Move(Direction),
    Select,
    SelectIndex(usize),
    Back,

    // Tab Navigation
    NextTab,
    PrevTab,
    SelectTab(usize),

    // Input
    Input(String),
    AppendChar(char),
    DeleteChar,
    Submit,

    // Nix operations
    NixInstall,
    NixBuild(Cow<'static, str>),
    NixCheck,
    NixFormat,
    NixQuery(Query),

    // UI control
    SetMode(Mode),
    SetError(String),
    SetStatus(String),
    ClearError,
    Exit,

    // Batched operations
    Batch(Vec<Action>),

    // Custom component actions
    Custom(String),
}

// EnumIter enables Direction::iter() for dynamic UI generation (e.g., navigation menus)
#[derive(Clone, Debug, PartialEq, Display, EnumString, EnumIter)]
pub enum Direction {
    Up,
    Down,
    Left,
    Right,
    PageUp,
    PageDown,
    Home,
    End,
}

// EnumIter allows Query::iter() for generating query type selection menus
#[derive(Clone, Debug, PartialEq, Display, EnumString, EnumIter)]
pub enum Query {
    Context,
    Config,
    Packages,
    Status,
}

// --- Effects ----------------------------------------------------------------
#[derive(Clone, Debug, Display)]
pub enum Effect {
    Nix(NixCommand),
    Exit,
}

#[derive(Clone, Debug, Display)]
pub enum NixCommand {
    Install,
    Build(Cow<'static, str>), // Optimized: zero-copy for static strings, minimal cloning for dynamic
    Query(Query),
    Apply,
    Check,
    Format,
}

// Optimized batch processing with state tracking and deduplication
pub fn process_batch(actions: Vec<Action>, state: &State) -> (Vec<Transition>, Vec<Effect>) {
    let mut batch_state = state.clone();
    let mut last_state = LastStateTracker::new();
    let mut other_transitions = Vec::new();
    let mut effects = Vec::new();

    for action in actions {
        let (transition, effect) = process(action, &batch_state);

        if let Some(t) = transition {
            // transition now returns Option<FocusChange>, but we don't need it here
            // since this is batch processing and focus will be handled at the app level
            let _ = batch_state.transition(t.clone());
            last_state.update(&t, &mut other_transitions);
        }
        if let Some(e) = effect {
            effects.push(e);
        }
    }

    let mut final_transitions = other_transitions;
    last_state.add_final_transitions(&mut final_transitions);
    (final_transitions, effects)
}

// Efficient state tracking for optimization
struct LastStateTracker {
    select: Option<usize>,
    focus: Option<Focus>,
    error: Option<Option<String>>,
    status: Option<Option<String>>,
}

impl LastStateTracker {
    fn new() -> Self {
        Self {
            select: None,
            focus: None,
            error: None,
            status: None,
        }
    }

    fn update(&mut self, transition: &Transition, others: &mut Vec<Transition>) {
        match transition {
            Transition::Select(idx) => self.select = Some(*idx),
            Transition::SetFocus(focus) => self.focus = Some(focus.clone()),
            Transition::SetError(error) => self.error = Some(error.clone()),
            Transition::SetStatus(status) => self.status = Some(status.clone()),
            _ => others.push(transition.clone()),
        }
    }

    fn add_final_transitions(&self, transitions: &mut Vec<Transition>) {
        if let Some(idx) = self.select {
            transitions.push(Transition::Select(idx));
        }
        if let Some(ref focus) = self.focus {
            transitions.push(Transition::SetFocus(focus.clone()));
        }
        if let Some(ref error) = self.error {
            transitions.push(Transition::SetError(error.clone()));
        }
        if let Some(ref status) = self.status {
            transitions.push(Transition::SetStatus(status.clone()));
        }
    }
}

// Streamlined action processing with pattern consolidation
pub fn process(action: Action, state: &State) -> (Option<Transition>, Option<Effect>) {
    use super::{InputMode, Mode};

    match action {
        Action::Batch(actions) => {
            let (transitions, effects) = process_batch(actions, state);
            (transitions.into_iter().next(), effects.into_iter().next())
        }

        // Navigation actions
        Action::Move(dir) => (
            Some(Transition::Select(calculate_index(
                state.ui.selection,
                state.ui.items_count,
                dir,
            ))),
            None,
        ),
        Action::SelectIndex(idx) => (Some(Transition::Select(idx)), None),
        Action::Select => match (&state.mode, &state.ui.focus) {
            (Mode::NixInstall, _) => (None, Some(Effect::Nix(NixCommand::Install))),
            (_, Focus::Navigation) => (Some(Transition::SetFocus(Focus::Input(InputMode::Text))), None),
            _ => (None, None),
        },
        Action::Back => match &state.ui.focus {
            Focus::Input(_) | Focus::Confirm => (Some(Transition::SetFocus(Focus::Navigation)), None),
            _ => (None, None),
        },

        // Input actions with focus validation
        Action::Input(text) => (Some(Transition::SetInput(text)), None),
        Action::AppendChar(c) if matches!(state.ui.focus, Focus::Input(_)) => (Some(Transition::AppendInput(c)), None),
        Action::DeleteChar if matches!(state.ui.focus, Focus::Input(_)) => (Some(Transition::DeleteChar), None),
        Action::Submit if matches!(state.ui.focus, Focus::Input(_)) => {
            let focus_nav = Some(Transition::SetFocus(Focus::Navigation));
            match state.mode {
                Mode::Configure if !state.ui.input.is_empty() => (
                    focus_nav,
                    Some(Effect::Nix(NixCommand::Build(Cow::Owned(state.ui.input.clone())))),
                ),
                Mode::Manage => (focus_nav, Some(Effect::Nix(NixCommand::Apply))),
                _ => (focus_nav, None),
            }
        }

        // Direct effect actions
        Action::NixInstall => (None, Some(Effect::Nix(NixCommand::Install))),
        Action::NixBuild(config) => (None, Some(Effect::Nix(NixCommand::Build(config)))),
        Action::NixCheck => (None, Some(Effect::Nix(NixCommand::Check))),
        Action::NixFormat => (None, Some(Effect::Nix(NixCommand::Format))),
        Action::NixQuery(query) => (None, Some(Effect::Nix(NixCommand::Query(query)))),
        Action::Exit => (None, Some(Effect::Exit)),

        // Direct transition actions
        Action::SetMode(mode) => (Some(Transition::SetMode(mode)), None),
        Action::SetError(msg) => (Some(Transition::SetError(Some(msg))), None),
        Action::SetStatus(msg) => (Some(Transition::SetStatus(Some(msg))), None),
        Action::ClearError => (Some(Transition::SetError(None)), None),
        Action::NextTab => (Some(Transition::FocusNext), None),
        Action::PrevTab => (Some(Transition::FocusPrev), None),

        // No-op actions and fallthrough cases
        Action::SelectTab(_) | Action::Custom(_) | Action::AppendChar(_) | Action::DeleteChar | Action::Submit => {
            (None, None)
        }
    }
}

// Optimized index calculation with bounds checking
pub fn calculate_index(current: usize, count: usize, direction: Direction) -> usize {
    if count == 0 {
        return 0;
    }
    let max_idx = count - 1;

    match direction {
        Direction::Up => current.saturating_sub(1),
        Direction::Down => (current + 1).min(max_idx),
        Direction::PageUp => current.saturating_sub(10),
        Direction::PageDown => (current + 10).min(max_idx),
        Direction::Home => 0,
        Direction::End => max_idx,
        _ => current,
    }
}
