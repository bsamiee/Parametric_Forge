// Title         : functionality/core/feedback.rs
// Author        : Bardia Samiee
// Project       : Parametric Forge
// License       : MIT
// Path          : interface/src/functionality/core/feedback.rs
// ----------------------------------------------------------------------------
//! Feedback system with phantom types and geometry-inspired caching

use super::modes::ModeError;
use super::state::StateFlags;
use derive_more::{Constructor, From, Display, CopyGetters, Deref, Into};
use rustc_hash::FxHashSet;
use tinyvec::ArrayVec;
use compact_str::CompactString;
use std::hash::{Hash, Hasher, DefaultHasher};
use std::time::{Duration, Instant};
use std::marker::PhantomData;

// --- Feedback Spaces ---------------------------------------------------------

pub struct TraceSpace;
pub struct InfoSpace;
pub struct ErrorSpace;

// --- Feedback Levels ---------------------------------------------------------

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Display)]
#[repr(u8)]
pub enum FeedbackLevel { Trace = 0, Info = 1, Success = 2, Warning = 3, Error = 4, Critical = 5 }

impl FeedbackLevel {
    pub const fn priority(self) -> u8 { self as u8 }
    pub const fn is_error(self) -> bool { self as u8 >= 4 }
    pub const fn requires_attention(self) -> bool { self as u8 >= 3 }
}

// --- Feedback Entry ----------------------------------------------------------

#[derive(Debug, Clone, Constructor, CopyGetters, From)]
pub struct FeedbackEntry<S = InfoSpace> {
    #[getset(get_copy = "pub")]
    message: CompactString, level: FeedbackLevel, timestamp: Instant,
    expires_at: Option<Instant>, hash_cache: Option<u64>,
    _space: PhantomData<S>,
}

impl<S> FeedbackEntry<S> {
    pub fn info(msg: impl Into<CompactString>) -> Self {
        Self::new(msg.into(), FeedbackLevel::Info, Instant::now(),
                 Some(Instant::now() + Duration::from_secs(5)), None, PhantomData)
    }

    pub fn error(msg: impl Into<CompactString>) -> Self {
        Self::new(msg.into(), FeedbackLevel::Error, Instant::now(),
                 Some(Instant::now() + Duration::from_secs(10)), None, PhantomData)
    }

    pub fn persistent(msg: impl Into<CompactString>, level: FeedbackLevel) -> Self {
        Self::new(msg.into(), level, Instant::now(), None, None, PhantomData)
    }

    pub fn mode_error(error: ModeError) -> Self { Self::error(error.to_string()) }

    pub fn to_space<T>(self) -> FeedbackEntry<T> {
        FeedbackEntry::new(self.message, self.level, self.timestamp,
                          self.expires_at, self.hash_cache, PhantomData)
    }

    pub fn compute_hash(&mut self) -> u64 {
        *self.hash_cache.get_or_insert_with(|| {
            let mut hasher = DefaultHasher::new();
            (self.message.as_str(), self.level.priority(), self.timestamp).hash(&mut hasher);
            hasher.finish()
        })
    }

    pub fn is_expired(&self) -> bool {
        self.expires_at.map_or(false, |exp| Instant::now() >= exp)
    }

    pub fn level(&self) -> FeedbackLevel { self.level }
}

// --- Feedback Manager --------------------------------------------------------

#[derive(Debug, Clone, Default, Constructor)]
pub struct FeedbackManager {
    entries: TinyVec<[FeedbackEntry; 4]>,
    error_mask: u8,
    last_cleanup: Instant,
    flags_cache: Option<StateFlags>,
}

impl FeedbackManager {
    pub const fn new() -> Self {
        Self {
            entries: TinyVec::new(),
            error_mask: 0,
            last_cleanup: Instant::now(),
            flags_cache: None
        }
    }

    pub fn add_entry(&mut self, entry: FeedbackEntry) {
        if self.should_cleanup() { self.cleanup_expired(); }
        if entry.level().is_error() { self.error_mask |= 1 << entry.level().priority(); }
        self.entries.push(entry);
        self.flags_cache = None;
    }

    pub fn info(&mut self, msg: impl Into<CompactString>) {
        self.add_entry(FeedbackEntry::info(msg));
    }

    pub fn error(&mut self, msg: impl Into<CompactString>) {
        self.add_entry(FeedbackEntry::error(msg));
    }

    pub fn mode_error(&mut self, error: ModeError) {
        self.add_entry(FeedbackEntry::mode_error(error));
    }

    pub fn state_flags(&mut self) -> StateFlags {
        *self.flags_cache.get_or_insert_with(|| {
            let mut flags = StateFlags::empty();
            if self.error_mask > 0 { flags |= StateFlags::ERROR_STATE; }
            if !self.entries.is_empty() { flags |= StateFlags::STATUS_ACTIVE; }
            flags
        })
    }

    pub fn has_errors(&self) -> bool { self.error_mask > 0 }
    pub fn has_active_feedback(&self) -> bool { !self.entries.is_empty() }
    pub fn latest(&self) -> Option<&FeedbackEntry> { self.entries.last() }
    pub fn latest_error(&self) -> Option<&FeedbackEntry> {
        self.entries.iter().rev().find(|e| e.level().is_error())
    }

    pub fn clear(&mut self) {
        self.entries.clear();
        self.error_mask = 0;
        self.last_cleanup = Instant::now();
        self.flags_cache = None;
    }

    fn cleanup_expired(&mut self) {
        let old_error_mask = self.error_mask;
        self.entries.retain(|entry| !entry.is_expired());
        self.error_mask = self.entries.iter()
            .filter(|e| e.level().is_error())
            .fold(0u8, |mask, e| mask | (1 << e.level().priority()));
        self.last_cleanup = Instant::now();
        if old_error_mask != self.error_mask { self.flags_cache = None; }
    }

    fn should_cleanup(&self) -> bool {
        self.entries.len() >= 4 || self.last_cleanup.elapsed() > Duration::from_secs(30)
    }
}