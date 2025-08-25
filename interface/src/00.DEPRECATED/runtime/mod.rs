// Title         : runtime/mod.rs
// Author        : Bardia Samiee
// Project       : Parametric Forge Interface
// License       : MIT
// Path          : interface/src/runtime/mod.rs
// ----------------------------------------------------------------------------

mod executor;
mod terminal;

pub use executor::EffectExecutor;
pub use terminal::TerminalRuntime;

use crate::core::Effect;
use color_eyre::eyre::Result;
use crossterm::event::Event;
use std::time::Duration;

// --- Runtime Trait ----------------------------------------------------------
pub trait Runtime {
    fn poll_event(&self, timeout: Duration) -> Result<Option<Event>>;
    fn execute_effect(&mut self, effect: Effect) -> Result<()>;
}
