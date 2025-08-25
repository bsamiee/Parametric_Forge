// Title         : system.rs
// Author        : Bardia Samiee
// Project       : Parametric Forge Interface
// License       : MIT
// Path          : interface/src/system.rs
// ----------------------------------------------------------------------------

use color_eyre::eyre::{eyre, Result, WrapErr};
use std::path::PathBuf;
use std::process::{Command, Output};
use tokio::process::Command as AsyncCommand;
use which::which;

// --- Prerequisites Check ----------------------------------------------------
pub fn check_nix() -> Result<bool> {
    let Ok(nix_path) = which("nix") else {
        return Ok(false);
    };

    let output = Command::new(nix_path)
        .args(["--version"])
        .output()
        .wrap_err("Failed to check Nix version")?;

    if output.status.success() {
        let version = String::from_utf8_lossy(&output.stdout);
        Ok(version.contains("Determinate") || version.contains("nix"))
    } else {
        Ok(false)
    }
}

// --- Project Location -------------------------------------------------------
pub fn find_project_root() -> Result<PathBuf> {
    let mut current = std::env::current_dir().wrap_err("Failed to get current directory")?;

    loop {
        if current.join("flake.nix").exists() {
            return Ok(current);
        }

        match current.parent() {
            Some(parent) => current = parent.to_path_buf(),
            None => {
                return Err(eyre!(
                    "Not in a Parametric Forge project - no flake.nix found in parent directories"
                ));
            }
        }
    }
}

// --- Unified Command Execution ---------------------------------------------

/// Execute a command and return its output, or error if command fails
pub async fn execute_command(cmd: &str, args: &[&str], description: &str) -> Result<Output> {
    let output = AsyncCommand::new(cmd)
        .args(args)
        .output()
        .await
        .wrap_err_with(|| format!("Failed to execute {}", description))?;

    if !output.status.success() {
        return Err(eyre!(
            "{} failed: {}",
            description,
            String::from_utf8_lossy(&output.stderr)
        ));
    }
    Ok(output)
}

/// Execute a command expecting only success/failure (ignores output)
pub async fn execute_status_command(cmd: &str, args: &[&str], description: &str) -> Result<()> {
    execute_command(cmd, args, description).await?;
    Ok(())
}
