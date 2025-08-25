// Title         : git.rs
// Author        : Bardia Samiee
// Project       : Parametric Forge Interface
// License       : MIT
// Path          : interface/src/git.rs
// ----------------------------------------------------------------------------

use crate::system::execute_command;
use color_eyre::eyre::{Result, WrapErr};
use indexmap::IndexMap;
use once_cell::sync::Lazy;
use std::path::{Path, PathBuf};
use std::process::Output;
use std::sync::{Arc, Mutex};
use std::thread;
use std::time::{Duration, Instant};

#[cfg(unix)]
use std::os::unix::process::ExitStatusExt;

// --- Git Status Detection ---------------------------------------------------
pub async fn get_git_status(root: &Path) -> Result<IndexMap<PathBuf, char>> {
    let original_dir = std::env::current_dir().wrap_err("Failed to get current directory")?;
    std::env::set_current_dir(root).wrap_err("Failed to change to git repository directory")?;

    let output = execute_command("git", &["status", "--porcelain", "-uall"], "git status")
        .await
        .or_else(|_| -> Result<Output> {
            // Restore directory and return empty map if git fails
            let _ = std::env::set_current_dir(&original_dir);
            // Create empty output - git command failed but we handle this gracefully
            #[cfg(unix)]
            let status = std::process::ExitStatus::from_raw(1);
            #[cfg(not(unix))]
            let status = std::process::Command::new("cmd")
                .args(["/C", "exit 1"])
                .status()
                .unwrap();

            Ok(Output {
                status,
                stdout: Vec::new(),
                stderr: Vec::new(),
            })
        })?;

    std::env::set_current_dir(&original_dir).wrap_err("Failed to restore original directory")?;

    if !output.status.success() {
        return Ok(IndexMap::new());
    }

    let mut status_map = IndexMap::with_capacity(100); // Pre-allocate for typical repo with ~100 changed files
    let status_text = String::from_utf8_lossy(&output.stdout);

    for line in status_text.lines() {
        if line.len() < 4 {
            continue;
        }

        let status = line.chars().nth(1).unwrap_or(' ');
        let path = &line[3..];

        let status_char = match status {
            'M' | 'A' | 'D' | 'R' | 'C' => status,
            '?' => '?',
            _ if line.starts_with("??") => '?',
            _ => continue,
        };

        status_map.insert(root.join(path), status_char);
    }

    Ok(status_map)
}

// --- Background Git Status Cache -------------------------------------------
// Thread-safe cache for git status that can be updated asynchronously

#[derive(Debug)]
struct GitStatusCache {
    data: IndexMap<PathBuf, char>,
    last_updated: Instant,
    root_path: PathBuf,
}

impl GitStatusCache {
    fn new(root_path: PathBuf) -> Self {
        Self {
            data: IndexMap::new(),
            last_updated: Instant::now() - Duration::from_secs(60), // Force initial update
            root_path,
        }
    }

    fn is_stale(&self, max_age: Duration) -> bool {
        self.last_updated.elapsed() > max_age
    }

    fn update(&mut self, new_data: IndexMap<PathBuf, char>) {
        self.data = new_data;
        self.last_updated = Instant::now();
    }
}

// Shared runtime for all async git operations
static SHARED_RUNTIME: Lazy<tokio::runtime::Runtime> =
    Lazy::new(|| tokio::runtime::Runtime::new().expect("Failed to create shared runtime for git operations"));

/// Global git status cache with background updates
static GIT_CACHE: std::sync::OnceLock<Arc<Mutex<Option<GitStatusCache>>>> = std::sync::OnceLock::new();

/// Initialize the git status cache for a repository root
pub fn init_git_cache(root: &Path) -> Result<()> {
    let cache = GIT_CACHE.get_or_init(|| Arc::new(Mutex::new(None)));

    {
        let mut cache_guard = cache.lock().unwrap();
        *cache_guard = Some(GitStatusCache::new(root.to_path_buf()));
    }

    // Start background update thread with shared runtime
    let cache_clone = cache.clone();
    let root_clone = root.to_path_buf();

    thread::spawn(move || {
        SHARED_RUNTIME.block_on(async {
            loop {
                tokio::time::sleep(Duration::from_secs(5)).await;

                let should_update = {
                    let cache_guard = cache_clone.lock().unwrap();
                    if let Some(ref cache) = *cache_guard {
                        cache.is_stale(Duration::from_secs(5))
                    } else {
                        false
                    }
                };

                if should_update {
                    if let Ok(new_status) = get_git_status(&root_clone).await {
                        let mut cache_guard = cache_clone.lock().unwrap();
                        if let Some(ref mut cache) = *cache_guard {
                            cache.update(new_status);
                        }
                    }
                }
            }
        });
    });

    Ok(())
}

/// Get git status synchronously from cache (non-blocking)
pub fn get_git_status_sync(_root: &Path) -> Result<IndexMap<PathBuf, char>> {
    let cache = GIT_CACHE.get_or_init(|| Arc::new(Mutex::new(None)));

    let cache_guard = cache.lock().unwrap();
    if let Some(ref cache_data) = *cache_guard {
        // Return a clone of the cached data
        Ok(cache_data.data.clone())
    } else {
        // Cache not initialized, return empty map
        Ok(IndexMap::new())
    }
}

/// Force an immediate git status update (runs in background)
pub fn refresh_git_status() {
    let cache = GIT_CACHE.get_or_init(|| Arc::new(Mutex::new(None)));

    let root_path = {
        let cache_guard = cache.lock().unwrap();
        if let Some(ref cache_data) = *cache_guard {
            cache_data.root_path.clone()
        } else {
            return; // Cache not initialized
        }
    };

    let cache_clone = cache.clone();
    thread::spawn(move || {
        SHARED_RUNTIME.block_on(async {
            if let Ok(new_status) = get_git_status(&root_path).await {
                let mut cache_guard = cache_clone.lock().unwrap();
                if let Some(ref mut cache) = *cache_guard {
                    cache.update(new_status);
                }
            }
        });
    });
}

// --- Color Mapping ----------------------------------------------------------
pub fn status_color(status: Option<char>) -> ratatui::style::Color {
    use ratatui::style::Color;
    match status {
        Some('M') => Color::Yellow,
        Some('A') => Color::Green,
        Some('D') => Color::Red,
        Some('?') => Color::Gray,
        _ => Color::Reset,
    }
}
