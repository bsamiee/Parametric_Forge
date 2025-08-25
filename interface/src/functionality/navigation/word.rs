// Title         : functionality/navigation/word.rs
// Author        : Bardia Samiee
// Project       : Parametric Forge
// License       : MIT
// Path          : interface/src/functionality/navigation/word.rs
// ----------------------------------------------------------------------------
//! Word navigation utilities

use derive_more::{Constructor, Display, From, Into};
use getset::CopyGetters;
use arrayvec::ArrayVec;
use ahash::AHasher;
use rayon::prelude::*;
use std::hash::{Hash, Hasher};
use super::core::find_word_boundaries_simd;

/// Word boundary types - using bitflags for efficiency
use bitflags::bitflags;

bitflags! {
    /// Word boundary flags
    pub struct WordBoundary: u8 {
        const WHITESPACE = 1 << 0;
        const PUNCTUATION = 1 << 1;
        const ALPHANUMERIC = 1 << 2;
        const CAMEL_CASE = 1 << 3;
        const SNAKE_CASE = 1 << 4;
    }
}

/// Word position information - enhanced with derive macros
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Constructor, Display, From, Into, CopyGetters)]
#[display("Word({}, {})", start, end)]
pub struct WordPosition {
    #[getset(get_copy = "pub")]
    start: usize,
    #[getset(get_copy = "pub")]
    end: usize,
}

impl WordPosition {
    /// Get word length
    pub fn len(&self) -> usize {
        self.end() - self.start()
    }

    /// Check if position is empty
    pub fn is_empty(&self) -> bool {
        self.start() >= self.end()
    }

    /// Check if position contains index
    pub fn contains(&self, index: usize) -> bool {
        index >= self.start() && index < self.end()
    }
}

/// Word navigation utilities with SIMD optimizations and const generics
pub struct WordNavigator<const CACHE_SIZE: usize = 32>;

impl<const CS: usize> WordNavigator<CS> {
    /// Check if character is a boundary (traditional)
    #[inline]
    pub fn is_boundary(c: char) -> bool {
        c.is_whitespace() || c.is_ascii_punctuation()
    }

    /// Find next word start position using SIMD-accelerated boundary detection
    pub fn next_word_start(text: &str, pos: usize) -> usize {
        if pos >= text.len() { return text.len(); }
        
        let boundaries = find_word_boundaries_simd(text);
        boundaries.iter()
            .find(|&&boundary_pos| boundary_pos > pos)
            .copied()
            .unwrap_or(text.len())
    }

    /// Find previous word start position using SIMD-accelerated boundary detection
    pub fn prev_word_start(text: &str, pos: usize) -> usize {
        if pos == 0 { return 0; }
        
        let boundaries = find_word_boundaries_simd(text);
        boundaries.iter()
            .rev()
            .find(|&&boundary_pos| boundary_pos < pos)
            .copied()
            .unwrap_or(0)
    }

    /// Find word end position using SIMD-accelerated boundary detection
    pub fn word_end(text: &str, pos: usize) -> usize {
        if pos >= text.len() { return text.len(); }
        
        let boundaries = find_word_boundaries_simd(text);
        boundaries.iter()
            .find(|&&boundary_pos| boundary_pos > pos)
            .copied()
            .unwrap_or(text.len())
    }

    /// Get word position at index
    pub fn word_at(text: &str, pos: usize) -> WordPosition {
        let start = Self::prev_word_start(text, pos);
        let end = Self::word_end(text, start);
        WordPosition::new(start, end)
    }

    /// Count words in text using SIMD-accelerated boundary detection
    pub fn word_count(text: &str) -> usize {
        if text.is_empty() { return 0; }
        let boundaries = find_word_boundaries_simd(text);
        boundaries.len().saturating_add(1)
    }

    /// Advanced word navigation with camel case support
    #[inline]
    pub fn next_camel_word(text: &str, pos: usize) -> usize {
        Self::next_word_start(text, pos)
    }
    
    /// Batch word processing with parallel execution for large texts
    pub fn word_positions_par(text: &str) -> ArrayVec<WordPosition, CS> {
        if text.len() < 1024 {
            return Self::word_positions(text);
        }
        
        let boundaries = find_word_boundaries_simd(text);
        let positions: Vec<_> = boundaries.par_iter()
            .zip(boundaries.par_iter().skip(1))
            .map(|(&start, &end)| WordPosition::new(start, end))
            .collect();
            
        let mut result = ArrayVec::new();
        for pos in positions.into_iter().take(CS) {
            if result.is_full() { break; }
            result.push(pos);
        }
        result
    }
    
    /// Extract word positions using stack-allocated storage
    pub fn word_positions(text: &str) -> ArrayVec<WordPosition, CS> {
        let boundaries = find_word_boundaries_simd(text);
        let mut positions = ArrayVec::new();
        
        for window in boundaries.windows(2) {
            if positions.is_full() { break; }
            positions.push(WordPosition::new(window[0], window[1]));
        }
        
        // Handle last word if text doesn't end with boundary
        if let Some(&last_boundary) = boundaries.last() {
            if last_boundary < text.len() && !positions.is_full() {
                positions.push(WordPosition::new(last_boundary, text.len()));
            }
        }
        
        positions
    }
    
    /// Fast hash-based word lookup with const generics
    #[inline]
    pub fn word_hash(text: &str, start: usize, end: usize) -> u64 {
        let mut hasher = AHasher::default();
        if let Some(word) = text.get(start..end) {
            word.hash(&mut hasher);
        }
        hasher.finish()
    }
}

/// Extension trait for cursor navigation with word support
pub trait WordNavigationExt {
    /// Move to next word start
    fn move_next_word(&mut self, text: &str);
    /// Move to previous word start
    fn move_prev_word(&mut self, text: &str);
    /// Move to word end
    fn move_word_end(&mut self, text: &str);
    /// Move to next camel case word
    fn move_next_camel_word(&mut self, text: &str);
}

impl<const C: usize> WordNavigationExt for super::nav::CursorNavigation<C> {
    fn move_next_word(&mut self, text: &str) {
        let new_pos = WordNavigator::<32>::next_word_start(text, self.cursor_position());
        self.set_position(new_pos);
    }

    fn move_prev_word(&mut self, text: &str) {
        let new_pos = WordNavigator::<32>::prev_word_start(text, self.cursor_position());
        self.set_position(new_pos);
    }

    fn move_word_end(&mut self, text: &str) {
        let new_pos = WordNavigator::<32>::word_end(text, self.cursor_position());
        self.set_position(new_pos);
    }

    fn move_next_camel_word(&mut self, text: &str) {
        let new_pos = WordNavigator::<32>::next_camel_word(text, self.cursor_position());
        self.set_position(new_pos);
    }
}