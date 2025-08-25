// Title         : config.rs
// Author        : Bardia Samiee
// Project       : Parametric Forge Interface
// License       : MIT
// Path          : interface/src/config.rs
// ----------------------------------------------------------------------------
//! Application configuration and platform-aware path management.

use color_eyre::eyre::{Result, WrapErr};
use directories::{BaseDirs, ProjectDirs};
use once_cell::sync::Lazy;
use std::path::PathBuf;

// --- Project Directories ----------------------------------------------------

static PROJECT_DIRS: Lazy<Option<ProjectDirs>> =
    Lazy::new(|| ProjectDirs::from("com", "parametric-forge", "forge-interface"));

pub struct AppPaths {
    pub config_dir: PathBuf,
    pub cache_dir: PathBuf,
    pub data_dir: PathBuf,
}

impl AppPaths {
    pub fn new() -> Result<Self> {
        let dirs = PROJECT_DIRS
            .as_ref()
            .ok_or_else(|| color_eyre::eyre::eyre!("Failed to determine platform directories"))?;

        Ok(Self {
            config_dir: dirs.config_dir().to_path_buf(),
            cache_dir: dirs.cache_dir().to_path_buf(),
            data_dir: dirs.data_dir().to_path_buf(),
        })
    }

    pub fn ensure_directories(&self) -> Result<()> {
        std::fs::create_dir_all(&self.config_dir)
            .wrap_err_with(|| format!("Failed to create config directory: {}", self.config_dir.display()))?;
        std::fs::create_dir_all(&self.cache_dir)
            .wrap_err_with(|| format!("Failed to create cache directory: {}", self.cache_dir.display()))?;
        std::fs::create_dir_all(&self.data_dir)
            .wrap_err_with(|| format!("Failed to create data directory: {}", self.data_dir.display()))?;
        Ok(())
    }

    pub fn config_file(&self) -> PathBuf {
        self.config_dir.join("configuration.json")
    }

    pub fn cache_file(&self, name: &str) -> PathBuf {
        self.cache_dir.join(name)
    }

    pub fn data_file(&self, name: &str) -> PathBuf {
        self.data_dir.join(name)
    }
}

// --- Platform-Specific Paths ------------------------------------------------

pub fn default_paths() -> AppPaths {
    AppPaths::new().unwrap_or_else(|_| {
        let home_dir = BaseDirs::new()
            .map(|b| b.home_dir().to_path_buf())
            .unwrap_or_else(|| PathBuf::from("/tmp"));

        #[cfg(target_os = "macos")]
        let (config_base, cache_base, data_base) = (
            "Library/Application Support/parametric-forge/forge-interface",
            "Library/Caches/parametric-forge/forge-interface",
            "Library/Application Support/parametric-forge/forge-interface/data",
        );

        #[cfg(target_os = "linux")]
        let (config_base, cache_base, data_base) = (
            ".config/parametric-forge/forge-interface",
            ".cache/parametric-forge/forge-interface",
            ".local/share/parametric-forge/forge-interface",
        );

        #[cfg(not(any(target_os = "macos", target_os = "linux")))]
        let (config_base, cache_base, data_base) = ("./config", "./cache", "./data");

        AppPaths {
            config_dir: home_dir.join(config_base),
            cache_dir: home_dir.join(cache_base),
            data_dir: home_dir.join(data_base),
        }
    })
}
