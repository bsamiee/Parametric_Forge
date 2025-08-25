// Title         : main.rs
// Author        : Bardia Samiee
// Project       : Parametric Forge Interface
// License       : MIT
// Path          : interface/src/main.rs
// ----------------------------------------------------------------------------

use color_eyre::eyre::{Result, WrapErr};

mod app;
mod components;
mod config;
mod core;
mod git;
mod layouts;
mod nix;
mod persistence;
mod runtime;
mod system;
mod widgets;

use app::App;

#[tokio::main]
async fn main() -> Result<()> {
    // Install color-eyre hooks for better error reporting and panic handling
    install_hooks()?;

    // Find project root
    let project_root = system::find_project_root().wrap_err("Failed to find project root directory")?;
    std::env::set_current_dir(&project_root)
        .wrap_err_with(|| format!("Failed to change directory to {}", project_root.display()))?;

    // Check for Nix (still sync for now, will convert later)
    let has_nix = system::check_nix().wrap_err("Failed to check Nix installation status")?;

    // Get context and config asynchronously
    let (context, config) = nix::get_context_and_config()
        .await
        .wrap_err("Failed to get Nix context and configuration")?;

    // Initialize git status cache for better performance
    git::init_git_cache(&project_root).wrap_err("Failed to initialize git status cache")?;

    // Create context for core with nix status
    let core_context = context.with_nix_status(has_nix);

    // Run application
    let mut app = App::new(core_context, config).wrap_err("Failed to initialize application")?;
    app.run().await.wrap_err("Application runtime error")?;

    Ok(())
}

fn install_hooks() -> Result<()> {
    // Install color-eyre for better error reporting
    color_eyre::config::HookBuilder::default()
        .panic_section(format!("Parametric Forge Interface v{}", env!("CARGO_PKG_VERSION")))
        .capture_span_trace_by_default(false) // Disable for cleaner TUI output
        .display_env_section(false) // Don't show env vars in TUI
        .install()?;

    // Install custom panic handler that cleans up terminal before panicking
    let original_hook = std::panic::take_hook();
    std::panic::set_hook(Box::new(move |panic_info| {
        // Try to clean up terminal state before showing panic
        let _ = crossterm::terminal::disable_raw_mode();
        let _ = crossterm::execute!(
            std::io::stderr(),
            crossterm::terminal::LeaveAlternateScreen,
            crossterm::cursor::Show
        );

        // Now show the panic with the original handler
        original_hook(panic_info);
    }));

    Ok(())
}
