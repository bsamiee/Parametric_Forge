// Title         : persistence.rs
// Author        : Bardia Samiee
// Project       : Parametric Forge Interface
// License       : MIT
// Path          : interface/src/persistence.rs
// ----------------------------------------------------------------------------

use crate::config::AppPaths;
use color_eyre::eyre::{Result, WrapErr};
use serde_json::Value;
use std::path::PathBuf;

pub struct StatePersistence {
    path: PathBuf,
}

impl StatePersistence {
    pub fn new() -> Result<Self> {
        // Always use platform-specific directories
        let paths = AppPaths::new().wrap_err("Failed to determine platform directories")?;
        paths
            .ensure_directories()
            .wrap_err("Failed to create application directories")?;
        Ok(Self {
            path: paths.config_file(),
        })
    }

    pub fn with_path(path: PathBuf) -> Self {
        // Allow custom path for testing or special cases
        Self { path }
    }

    pub fn load(&self) -> Result<Value> {
        if self.path.exists() {
            let content = std::fs::read_to_string(&self.path)
                .wrap_err_with(|| format!("Failed to read {}", self.path.display()))?;
            Ok(serde_json::from_str(&content).wrap_err("Failed to parse configuration as JSON")?)
        } else {
            Ok(Value::Object(Default::default()))
        }
    }

    pub fn save(&self, state: &Value) -> Result<()> {
        let content = serde_json::to_string_pretty(state).wrap_err("Failed to serialize state to JSON")?;
        std::fs::write(&self.path, content).wrap_err_with(|| format!("Failed to write to {}", self.path.display()))?;
        Ok(())
    }
}
