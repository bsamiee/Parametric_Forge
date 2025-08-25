// Title         : nix.rs
// Author        : Bardia Samiee
// Project       : Parametric Forge Interface
// License       : MIT
// Path          : interface/src/nix.rs
// ----------------------------------------------------------------------------

use crate::core::Context;
use crate::system::execute_status_command;
use color_eyre::eyre::{eyre, Result, WrapErr};
use serde_json::Value;
use tokio::process::Command;

// --- Nix Integration --------------------------------------------------------
pub async fn get_context_and_config() -> Result<(Context, Value)> {
    let output = Command::new("nix")
        .args([
            "eval",
            "--json",
            "--impure",
            "--expr",
            r#"
               let
                 flake = builtins.getFlake (toString ./.);
                 context = flake.lib.detectContext builtins.currentSystem (builtins.getEnv "USER");
                 # Read persisted configuration if it exists
                 configPath = ./configuration.json;
                 userConfig = if builtins.pathExists configPath
                   then builtins.fromJSON (builtins.readFile configPath)
                   else { };
                 # Get defaults from lib and merge with user config
                 defaultConfig = flake.lib.configDefaults { inherit (context) isDarwin; };
                 config = builtins.recursiveUpdate defaultConfig userConfig;
               in
               {
                 inherit (context) system isDarwin isLinux user;
                 hasConfig = builtins.pathExists configPath;
                 inherit config;
               }
               "#,
        ])
        .output()
        .await
        .wrap_err("Failed to execute nix eval command")?;

    if !output.status.success() {
        return Err(eyre!("Nix eval failed: {}", String::from_utf8_lossy(&output.stderr)));
    }

    let result: Value = serde_json::from_slice(&output.stdout).wrap_err("Failed to parse Nix output as JSON")?;

    let context = Context {
        system: result["system"].as_str().unwrap_or("unknown").to_string(),
        is_darwin: result["isDarwin"].as_bool().unwrap_or(false),
        is_linux: result["isLinux"].as_bool().unwrap_or(false),
        user: result["user"].as_str().unwrap_or("user").to_string(),
        has_nix: true, // If we're here, Nix is working
        has_config: result["hasConfig"].as_bool().unwrap_or(false),
    };

    let config = result["config"].clone();

    Ok((context, config))
}

// --- Config Persistence -----------------------------------------------------
pub async fn write_config(config: &Value) -> Result<()> {
    // Write as JSON for simpler integration with module system
    let json_content = serde_json::to_string_pretty(config).wrap_err("Failed to serialize configuration to JSON")?;
    tokio::fs::write("./configuration.json", json_content)
        .await
        .wrap_err("Failed to write configuration.json file")?;
    Ok(())
}

// --- Nix Commands -----------------------------------------------------------

/// Install Nix with optional interactive prompt
pub async fn install_nix(interactive: bool) -> Result<()> {
    if interactive {
        println!("Nix is required to run Parametric Forge.");
        println!("Would you like to install it now? (y/n)");

        let response = tokio::task::spawn_blocking(|| {
            use std::io::{self, BufRead};
            let mut response = String::new();
            io::stdin().lock().read_line(&mut response)?;
            Ok::<String, color_eyre::eyre::Error>(response)
        })
        .await??;

        if response.trim().to_lowercase() != "y" {
            std::process::exit(1);
        }
    }

    println!("Installing Determinate Nix...");
    if !interactive {
        println!("This will take a moment.\n");
    }

    execute_status_command("sh", &["-c", "curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --no-confirm"], "nix installer").await?;

    if interactive {
        println!("\nInstallation complete! Please restart the application.");
        tokio::time::sleep(std::time::Duration::from_secs(1)).await;
    }
    Ok(())
}

/// Legacy sync wrapper for backwards compatibility with main.rs bootstrap
pub fn run_installer() -> Result<()> {
    let rt = tokio::runtime::Runtime::new().wrap_err("Failed to create runtime for installer")?;
    rt.block_on(install_nix(true))
}

pub async fn build_config(config: &str) -> Result<()> {
    println!("Building configuration: {}", config);
    execute_status_command(
        "nix",
        &["build", ".#darwinConfigurations.default.system", "--no-link"],
        "nix build",
    )
    .await
}

pub async fn apply_config() -> Result<()> {
    println!("Applying configuration...");
    execute_status_command("darwin-rebuild", &["switch", "--flake", "."], "darwin-rebuild").await
}

pub async fn check_config() -> Result<()> {
    println!("Checking configuration...");
    execute_status_command("nix", &["flake", "check"], "nix flake check").await
}

pub async fn format_config() -> Result<()> {
    println!("Formatting configuration...");
    execute_status_command("nix", &["fmt"], "nix fmt").await
}
