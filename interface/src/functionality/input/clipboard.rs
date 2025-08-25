// Title         : functionality/input/clipboard.rs
// Author        : Bardia Samiee
// Project       : Parametric Forge
// License       : MIT
// Path          : interface/src/functionality/input/clipboard.rs
// ----------------------------------------------------------------------------
//! Ultra-compact clipboard operations using arboard

use arboard::Clipboard;
use once_cell::sync::Lazy;
use derive_more::{Constructor, From, Into, Display, Deref, DerefMut};
use bitflags::bitflags;
use std::marker::PhantomData;
use crate::functionality::core::geometry::ScreenSpace;

static CLIPBOARD: Lazy<Clipboard> = Lazy::new(|| Clipboard::new().unwrap());

bitflags! {
    #[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
    pub struct ClipboardFlags: u8 {
        const SYSTEM = 1 << 0;
        const CACHE  = 1 << 1;
        const SYNC   = 1 << 2;
        const BUFFER = 1 << 3;
    }
}

#[derive(Debug, Clone, Copy, Constructor, From, Into, Display, Deref, DerefMut, PartialEq, Eq, Hash)]
#[display("ClipboardEngine({})", flags)]
pub struct ClipboardEngine<S = ScreenSpace> {
    #[deref] #[deref_mut]
    flags: ClipboardFlags,
    _space: PhantomData<S>,
}

impl<S> ClipboardEngine<S> {
    pub fn copy(&self, text: &str) -> Result<(), arboard::Error> {
        CLIPBOARD.set_text(text)
    }
    
    pub fn paste(&self) -> Result<String, arboard::Error> {
        CLIPBOARD.get_text()
    }
}

impl<S> Default for ClipboardEngine<S> {
    fn default() -> Self {
        Self::new(ClipboardFlags::SYSTEM | ClipboardFlags::SYNC, PhantomData)
    }
}

pub type SystemClipboard = ClipboardEngine<ScreenSpace>;