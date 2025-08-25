// Title         : core/mod.rs
// Author        : Bardia Samiee
// Project       : Parametric Forge Interface
// License       : MIT
// Path          : interface/src/core/mod.rs
// ----------------------------------------------------------------------------

mod action;
mod event;
mod state;

// Re-export core types with logical grouping
pub use action::{calculate_index, process, Action, Direction, Effect, NixCommand};
pub use event::map_event;
pub use state::{Context, Focus, InputMode, LayoutStateUpdates, Mode, State};
