// Title         : functionality/core/modes.rs
// Author        : Bardia Samiee
// Project       : Parametric Forge
// License       : MIT
// Path          : interface/src/functionality/core/modes.rs
// ----------------------------------------------------------------------------
//! State machine for application modes with compile-time validation

use super::geometry::Scalar;
use super::events::{Action, FocusContext};
use super::state::{StateFlags, ComponentId};
use bitflags::bitflags;
use derive_more::{Constructor, Display, From, Into};
use strum::{EnumIter, EnumString, IntoEnumIterator};
use once_cell::sync::Lazy;
use rustc_hash::FxHashMap;
use tinyvec::TinyVec;
use thiserror::Error;
use compact_str::CompactString;

// --- Mode Behavior Flags -----------------------------------------------------

bitflags! {
    pub struct ModeFlags: u16 {
        const NIX_REQUIRED = 1; const CONFIG_AWARE = 2; const ASYNC_OPS = 4;
        const BATCH_CAPABLE = 8; const TAB_ENABLED = 16; const FOCUS_MANAGED = 32;
        const ERROR_HANDLING = 64; const STATUS_UPDATES = 128;
        const FULL_FEATURED = Self::TAB_ENABLED.bits() | Self::FOCUS_MANAGED.bits() | Self::ERROR_HANDLING.bits();
        const NIX_DEPENDENT = Self::NIX_REQUIRED.bits() | Self::CONFIG_AWARE.bits() | Self::ASYNC_OPS.bits();
    }
}

// --- Application Modes -------------------------------------------------------

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Display, EnumString, EnumIter)]
#[repr(u8)]
pub enum AppMode {
    #[display("Nix Installation Required")]
    #[strum(serialize = "install")]
    NixInstall = 0,
    #[display("System Configuration")]
    #[strum(serialize = "configure")]
    Configure = 1,
    #[display("Configuration Management")]
    #[strum(serialize = "manage")]
    Manage = 2,
}

impl AppMode {
    pub const fn flags(self) -> ModeFlags {
        match self {
            Self::NixInstall => ModeFlags::from_bits_truncate(
                ModeFlags::ERROR_HANDLING.bits() | ModeFlags::STATUS_UPDATES.bits()
            ),
            Self::Configure => ModeFlags::from_bits_truncate(
                ModeFlags::NIX_DEPENDENT.bits() | ModeFlags::FULL_FEATURED.bits()
            ),
            Self::Manage => ModeFlags::from_bits_truncate(
                ModeFlags::NIX_DEPENDENT.bits() | ModeFlags::FULL_FEATURED.bits() | ModeFlags::BATCH_CAPABLE.bits()
            ),
        }
    }
    
    pub const fn requires_nix(self) -> bool { self.flags().contains(ModeFlags::NIX_REQUIRED) }
    pub const fn supports_tabs(self) -> bool { self.flags().contains(ModeFlags::TAB_ENABLED) }
    pub const fn supports_async(self) -> bool { self.flags().contains(ModeFlags::ASYNC_OPS) }
    pub const fn can_transition_to(self, target: Self) -> bool {
        matches!((self, target),
            (Self::NixInstall, Self::Configure) | (Self::Configure, Self::Manage) |
            (Self::Manage, Self::Configure) | (mode, same) if mode as u8 == same as u8)
    }
}

// --- Mode Context ------------------------------------------------------------

#[derive(Debug, Clone, Constructor)]
pub struct ModeContext {
    pub current: AppMode,
    pub available_modes: TinyVec<[AppMode; 3]>,
    pub nix_detected: bool,
    pub config_exists: bool,
    flags_cache: Option<ModeFlags>,
}

impl ModeContext {
    pub fn detect_optimal(nix_detected: bool, config_exists: bool) -> Self {
        let current = match (nix_detected, config_exists) {
            (false, _) => AppMode::NixInstall,
            (true, false) => AppMode::Configure,
            (true, true) => AppMode::Manage,
        };
        let available_modes = AppMode::iter()
            .filter(|&mode| match mode {
                AppMode::NixInstall => !nix_detected,
                AppMode::Configure => nix_detected,
                AppMode::Manage => nix_detected && config_exists,
            })
            .collect();
        Self::new(current, available_modes, nix_detected, config_exists, None)
    }
    
    pub fn current_flags(&mut self) -> ModeFlags {
        *self.flags_cache.get_or_insert_with(|| self.current.flags())
    }
    
    pub fn validate_transition(&self, target: AppMode) -> Result<AppMode, ModeError> {
        if !self.current.can_transition_to(target) {
            return Err(ModeError::InvalidTransition { from: self.current, to: target });
        }
        if target.requires_nix() && !self.nix_detected {
            return Err(ModeError::NixRequired(target));
        }
        if !self.available_modes.contains(&target) {
            return Err(ModeError::ModeUnavailable(target));
        }
        Ok(target)
    }
    
    pub fn update_context(&mut self, nix_detected: bool, config_exists: bool) {
        if self.nix_detected != nix_detected || self.config_exists != config_exists {
            self.nix_detected = nix_detected;
            self.config_exists = config_exists;
            self.available_modes = AppMode::iter().filter(|&mode| match mode {
                AppMode::NixInstall => !nix_detected,
                AppMode::Configure => nix_detected,
                AppMode::Manage => nix_detected && config_exists,
            }).collect();
            self.flags_cache = None;
        }
    }
}

// --- Static Action Filters ---------------------------------------------------

static ACTION_FILTERS: Lazy<FxHashMap<AppMode, fn(&Action) -> bool>> = Lazy::new(|| {
    [(AppMode::NixInstall, |action| matches!(action, Action::Navigate(_) | Action::Select(_) | Action::Exit) as fn(&Action) -> bool),
     (AppMode::Configure, |action| !matches!(action, Action::TabSelect(_)) as fn(&Action) -> bool),
     (AppMode::Manage, |_| true as fn(&Action) -> bool)]
    .into_iter().collect()
});

// --- Mode Errors -------------------------------------------------------------

#[derive(Debug, Error, Display, Clone)]
pub enum ModeError {
    #[error("Invalid mode transition: {from} -> {to}")]
    InvalidTransition { from: AppMode, to: AppMode },
    #[error("Nix installation required for mode: {0}")]
    NixRequired(AppMode),
    #[error("Mode unavailable: {0}")]
    ModeUnavailable(AppMode),
    #[error("Mode operation failed: {0}")]
    OperationFailed(CompactString),
}

// --- Mode Engine -------------------------------------------------------------

#[derive(Debug, Clone, Constructor)]
pub struct ModeEngine {
    context: ModeContext,
    action_cache: FxHashMap<(AppMode, u32), TinyVec<[Action; 4]>>,
}

impl ModeEngine {
    pub fn filter_actions(&self, actions: &[Action]) -> TinyVec<[Action; 8]> {
        let filter_fn = ACTION_FILTERS.get(&self.context.current).unwrap_or(&(|_| true));
        actions.iter().filter(|action| filter_fn(action)).cloned().collect()
    }
    
    pub fn transition_to(&mut self, target: AppMode) -> Result<(), ModeError> {
        let validated_mode = self.context.validate_transition(target)?;
        self.context.current = validated_mode;
        self.context.flags_cache = None;
        self.action_cache.clear();
        Ok(())
    }
    
    pub fn update_system_context(&mut self, nix_detected: bool, config_exists: bool) {
        let old_mode = self.context.current;
        self.context.update_context(nix_detected, config_exists);
        if let Some(optimal) = self.detect_optimal_mode().ok() {
            if optimal != old_mode && self.context.validate_transition(optimal).is_ok() {
                let _ = self.transition_to(optimal);
            }
        }
    }
    
    fn detect_optimal_mode(&self) -> Result<AppMode, ModeError> {
        Ok(match (self.context.nix_detected, self.context.config_exists) {
            (false, _) => AppMode::NixInstall,
            (true, false) => AppMode::Configure,
            (true, true) => AppMode::Manage,
        })
    }
    
    pub const fn current_mode(&self) -> AppMode { self.context.current }
    pub const fn supports_tabs(&self) -> bool { self.context.current.supports_tabs() }
    pub const fn requires_nix(&self) -> bool { self.context.current.requires_nix() }
    pub fn available_modes(&self) -> impl Iterator<Item = AppMode> + '_ {
        self.context.available_modes.iter().copied()
    }
    pub fn cache_stats(&self) -> (usize, usize) {
        (self.action_cache.len(), self.action_cache.capacity())
    }
}

impl Default for ModeEngine {
    fn default() -> Self {
        Self::new(ModeContext::detect_optimal(false, false), FxHashMap::default())
    }
}