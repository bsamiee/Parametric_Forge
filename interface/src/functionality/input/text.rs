// Title         : functionality/input/text.rs
// Author        : Bardia Samiee
// Project       : Parametric Forge
// License       : MIT
// Path          : interface/src/functionality/input/text.rs
// ----------------------------------------------------------------------------
//! Ultra-compact text engine leveraging tui-input with spatial integration

use tui_input::Input as TuiInput;
use crate::functionality::core::{SpatialEngine, Point, Scalar, Selection};
use std::marker::PhantomData;

// --- Phantom Type Spaces ----------------------------------------------------

pub struct TextSpace;
pub struct MultilineSpace;

// --- Core Text Engine -------------------------------------------------------

#[derive(Debug, Clone)]
pub struct TextEngine<T: Scalar = u16, S = TextSpace> {
    inner: TuiInput,
    spatial: SpatialEngine<T>,
    selection: Selection,
    _space: PhantomData<S>,
}

#[derive(Debug, Clone)]
pub struct MultilineEngine<T: Scalar = u16> {
    inner: TuiInput,
    spatial: SpatialEngine<T>,
    selection: Selection,
    _space: PhantomData<MultilineSpace>,
}

// --- Implementation ----------------------------------------------------------

impl<T: Scalar> TextEngine<T, TextSpace> where T: From<u8> + num_traits::Zero + num_traits::One {
    pub fn new(inner: TuiInput, spatial: SpatialEngine<T>, selection: Selection) -> Self {
        Self { inner, spatial, selection, _space: PhantomData }
    }
    
    pub fn single() -> Self {
        Self::new(TuiInput::default(), SpatialEngine::linear().with_caching(), Selection::default())
    }
    
    pub fn cursor_pos(&self) -> Point<T> {
        let pos = T::from(self.inner.cursor() as u8);
        Point::new(pos, T::zero())
    }
    
    pub fn to_multiline(self) -> MultilineEngine<T> {
        MultilineEngine::new(self.inner, SpatialEngine::virtual_content().with_wrapping(), self.selection)
    }
}

impl<T: Scalar> MultilineEngine<T> where T: From<u8> + num_traits::Zero + num_traits::One {
    pub fn new(inner: TuiInput, spatial: SpatialEngine<T>, selection: Selection) -> Self {
        Self { inner, spatial, selection, _space: PhantomData }
    }
    
    pub fn multi() -> Self {
        Self::new(TuiInput::default(), SpatialEngine::virtual_content().with_wrapping().with_caching(), Selection::default())
    }
    
    pub fn cursor_pos(&self) -> Point<T> {
        let lines: Vec<&str> = self.inner.value().lines().collect();
        let cursor_pos = self.inner.cursor();
        let (line, col) = lines.iter().enumerate()
            .scan(0, |acc, (i, line)| {
                let start = *acc;
                *acc += line.len() + 1;
                if cursor_pos < *acc { Some((i, cursor_pos - start)) } else { None }
            })
            .next()
            .unwrap_or((0, 0));
        Point::new(T::from(col as u8), T::from(line as u8))
    }
}

// --- Deref implementations for tui-input delegation -------------------------

impl<T: Scalar, S> std::ops::Deref for TextEngine<T, S> {
    type Target = TuiInput;
    fn deref(&self) -> &Self::Target { &self.inner }
}

impl<T: Scalar, S> std::ops::DerefMut for TextEngine<T, S> {
    fn deref_mut(&mut self) -> &mut Self::Target { &mut self.inner }
}

impl<T: Scalar> std::ops::Deref for MultilineEngine<T> {
    type Target = TuiInput;
    fn deref(&self) -> &Self::Target { &self.inner }
}

impl<T: Scalar> std::ops::DerefMut for MultilineEngine<T> {
    fn deref_mut(&mut self) -> &mut Self::Target { &mut self.inner }
}

// --- Type Aliases ------------------------------------------------------------

pub type SingleLineText = TextEngine<u16, TextSpace>;
pub type MultiLineText = MultilineEngine<u16>;