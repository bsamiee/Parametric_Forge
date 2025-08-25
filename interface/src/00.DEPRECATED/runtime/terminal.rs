// Title         : runtime/terminal.rs
// Author        : Bardia Samiee
// Project       : Parametric Forge Interface
// License       : MIT
// Path          : interface/src/runtime/terminal.rs
// ----------------------------------------------------------------------------

use color_eyre::eyre::{Result, WrapErr};
use crossterm::{
    event, execute,
    terminal::{disable_raw_mode, enable_raw_mode, EnterAlternateScreen, LeaveAlternateScreen},
};
use ratatui::{backend::CrosstermBackend, layout::Rect, Frame, Terminal};
use std::{io, time::Duration};

// --- Terminal Runtime -------------------------------------------------------
pub struct TerminalRuntime {
    terminal: Terminal<CrosstermBackend<io::Stdout>>,
}

impl TerminalRuntime {
    pub fn new() -> Result<Self> {
        enable_raw_mode().wrap_err("Failed to enable raw mode for terminal")?;
        let mut stdout = io::stdout();
        execute!(stdout, EnterAlternateScreen).wrap_err("Failed to enter alternate screen")?;
        let backend = CrosstermBackend::new(stdout);
        let terminal = Terminal::new(backend).wrap_err("Failed to create terminal")?;

        Ok(Self { terminal })
    }

    pub fn draw<F>(&mut self, render_fn: F) -> Result<()>
    where
        F: FnOnce(&mut Frame),
    {
        self.terminal.draw(render_fn).wrap_err("Failed to draw to terminal")?;
        Ok(())
    }

    pub fn poll_event(&self, timeout: Duration) -> Result<Option<crossterm::event::Event>> {
        if event::poll(timeout).wrap_err("Failed to poll for terminal events")? {
            Ok(Some(event::read().wrap_err("Failed to read terminal event")?))
        } else {
            Ok(None)
        }
    }

    pub fn area(&self) -> Result<Rect> {
        let size = self.terminal.size().wrap_err("Failed to get terminal size")?;
        Ok(Rect::new(0, 0, size.width, size.height))
    }
}

impl Drop for TerminalRuntime {
    fn drop(&mut self) {
        let _ = self.cleanup();
    }
}

impl TerminalRuntime {
    fn cleanup(&mut self) -> Result<()> {
        disable_raw_mode()?;
        execute!(self.terminal.backend_mut(), LeaveAlternateScreen)?;
        self.terminal.show_cursor()?;
        Ok(())
    }
}
