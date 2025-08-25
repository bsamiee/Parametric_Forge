// Title         : functionality/input/mod.rs
// Author        : Bardia Samiee
// Project       : Parametric Forge
// License       : MIT
// Path          : interface/src/functionality/input/mod.rs
// ----------------------------------------------------------------------------
//! Unified input processing engine with phantom type safety and spatial integration

use crate::functionality::core::{
    geometry::{SpatialEngine, SpatialFlags, Direction, ScreenSpace},
    events::{EventDispatcher, FocusContext, Action},
    state::{WidgetState, Position},
    modes::AppMode,
};
use bitflags::bitflags;
use derive_more::{Constructor, From, Display, Deref, DerefMut};
use compact_str::CompactString;
use crossterm::event::{KeyEvent, KeyCode, KeyModifiers};
use std::marker::PhantomData;

// --- Type Spaces for Compile-Time Safety ------------------------------------

pub struct TextSpace;
pub struct ClipboardSpace;
pub struct ValidationSpace;
pub struct MaskSpace;
pub struct HistorySpace;

// --- Input Behavior Flags ----------------------------------------------------

bitflags! {
    #[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
    pub struct InputFlags: u32 {
        const TEXT      = 1 << 0;  const CLIPBOARD = 1 << 1;  const HISTORY   = 1 << 2;
        const VALIDATE  = 1 << 3;  const MASK      = 1 << 4;  const MULTILINE = 1 << 5;
        const SELECTION = 1 << 6;  const CACHE     = 1 << 7;  const SPATIAL   = 1 << 8;
        const COMPLETE  = Self::TEXT.bits() | Self::CLIPBOARD.bits() | Self::HISTORY.bits();
        const SECURED   = Self::MASK.bits() | Self::VALIDATE.bits();
        const ENHANCED  = Self::COMPLETE.bits() | Self::SECURED.bits() | Self::SPATIAL.bits();
    }
}

// --- Core Input Engine Trait ------------------------------------------------

pub trait InputEngine<T> {
    type Input;
    type Output;
    type Error;
    
    fn process(&mut self, input: Self::Input) -> Result<Self::Output, Self::Error>;
    fn reset(&mut self);
    fn is_dirty(&self) -> bool;
    fn with_flags(self, flags: InputFlags) -> Self;
}

// --- Input State with Phantom Types -----------------------------------------

#[derive(Debug, Clone, Constructor, From, Deref, DerefMut)]
pub struct InputState<S> {
    #[deref] #[deref_mut]
    pub content: CompactString,
    pub cursor: Position,
    pub selection: Option<(Position, Position)>,
    pub flags: InputFlags,
    _space: PhantomData<S>,
}

impl<S> InputState<S> {
    pub fn new(content: impl Into<CompactString>) -> Self {
        Self {
            content: content.into(),
            cursor: Position::linear(0),
            selection: None,
            flags: InputFlags::TEXT,
            _space: PhantomData,
        }
    }
    
    pub fn to_space<T>(self) -> InputState<T> {
        InputState {
            content: self.content,
            cursor: self.cursor,
            selection: self.selection,
            flags: self.flags,
            _space: PhantomData,
        }
    }
}

// --- Unified Input Processing Engine ----------------------------------------

#[derive(Debug, Clone)]
pub struct UnifiedInput<const CACHE_SIZE: usize = 64> {
    pub text_state: InputState<TextSpace>,
    pub spatial_engine: SpatialEngine<usize, CACHE_SIZE>,
    pub widget_state: WidgetState,
    pub flags: InputFlags,
}

impl<const CACHE_SIZE: usize> UnifiedInput<CACHE_SIZE> {
    pub const fn new() -> Self {
        Self {
            text_state: InputState {
                content: CompactString::new_inline(""),
                cursor: Position { index: 0, row: 0, col: 0 },
                selection: None,
                flags: InputFlags::TEXT,
                _space: PhantomData,
            },
            spatial_engine: SpatialEngine::new(0, 10, 1000, None, SpatialFlags::LINEAR),
            widget_state: WidgetState::new(),
            flags: InputFlags::TEXT,
        }
    }
}

// --- Main InputEngine Implementation ----------------------------------------

impl<const CACHE_SIZE: usize> InputEngine<KeyEvent> for UnifiedInput<CACHE_SIZE> {
    type Input = KeyEvent;
    type Output = CompactString;
    type Error = &'static str;
    
    fn process(&mut self, input: KeyEvent) -> Result<CompactString, Self::Error> {
        // Use EventDispatcher from core::events
        let action = EventDispatcher::dispatch(
            input, 
            FocusContext::INPUT, 
            AppMode::Normal
        );
        
        match action {
            Some(Action::Input(c)) => {
                self.text_state.content.push(c);
                self.text_state.cursor.index += 1;
                self.widget_state.mark_dirty();
            }
            Some(Action::Navigate(Direction::Left)) => {
                if self.text_state.cursor.index > 0 {
                    self.text_state.cursor.index -= 1;
                }
            }
            Some(Action::Navigate(Direction::Right)) => {
                if self.text_state.cursor.index < self.text_state.content.len() {
                    self.text_state.cursor.index += 1;
                }
            }
            _ => {
                // Handle character input directly for unmatched events
                if let KeyCode::Char(c) = input.code {
                    self.text_state.content.push(c);
                    self.text_state.cursor.index += 1;
                    self.widget_state.mark_dirty();
                } else if input.code == KeyCode::Backspace {
                    if self.text_state.cursor.index > 0 {
                        self.text_state.content.remove(self.text_state.cursor.index - 1);
                        self.text_state.cursor.index -= 1;
                        self.widget_state.mark_dirty();
                    }
                } else if input.code == KeyCode::Delete {
                    if self.text_state.cursor.index < self.text_state.content.len() {
                        self.text_state.content.remove(self.text_state.cursor.index);
                        self.widget_state.mark_dirty();
                    }
                }
            }
        }
        
        Ok(self.text_state.content.clone())
    }
    
    fn reset(&mut self) {
        self.text_state.content.clear();
        self.text_state.cursor = Position::linear(0);
        self.text_state.selection = None;
        self.widget_state.clear_dirty();
    }
    
    fn is_dirty(&self) -> bool {
        self.widget_state.is_dirty()
    }
    
    fn with_flags(mut self, flags: InputFlags) -> Self {
        self.flags = flags;
        self
    }
}

// --- Fluent Builder API ------------------------------------------------------

impl<const CACHE_SIZE: usize> UnifiedInput<CACHE_SIZE> {
    pub fn text() -> Self { Self::new().with_flags(InputFlags::TEXT) }
    pub fn multiline() -> Self { Self::new().with_flags(InputFlags::TEXT | InputFlags::MULTILINE) }
    pub fn complete() -> Self { Self::new().with_flags(InputFlags::COMPLETE) }
    pub fn secured() -> Self { Self::new().with_flags(InputFlags::SECURED) }
    pub fn enhanced() -> Self { Self::new().with_flags(InputFlags::ENHANCED) }
    pub fn with_spatial(mut self) -> Self { 
        self.flags |= InputFlags::SPATIAL;
        self.spatial_engine = SpatialEngine::linear().with_caching();
        self
    }
    pub fn cached(mut self) -> Self { self.flags |= InputFlags::CACHE; self }
}

// --- Re-exports for Agent Integration ---------------------------------------

pub use text::{TextBehavior, TextResult, CursorMove};
pub use clipboard::{ClipboardEngine, ClipboardFlags, SystemClipboard};
pub use history::{HistoryBehavior, HistoryResult};
pub use validation::{ValidationBehavior, ValidationResult};
pub use masking::{MaskBehavior, MaskResult};

// Module declarations for existing functionality
mod text;
mod clipboard; 
mod history;
mod validation;
mod masking;