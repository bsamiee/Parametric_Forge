// Title         : functionality/visual/spaces.rs
// Author        : Bardia Samiee
// Project       : Parametric Forge
// License       : MIT
// Path          : interface/src/functionality/visual/spaces.rs
// ----------------------------------------------------------------------------
//! Unified coordinate space system for all visual components

use derive_more::{Constructor, From, Display};
use std::marker::PhantomData;

// --- Universal Visual Space System ------------------------------------------

/// Base visual space - all visual components operate within this space
pub struct VisualSpace;

/// Border-specific coordinate space for border calculations and rendering
pub struct BorderSpace;

/// Theme coordinate space for color calculations and style applications  
pub struct ThemeSpace;

/// Icon positioning space for icon placement and alignment calculations
pub struct IconSpace;

/// Indicator space for progress bars, status badges, and loading spinners
pub struct IndicatorSpace;

/// Effect space for animations, transitions, and visual feedback
pub struct EffectSpace;

// --- Space Conversion Traits ------------------------------------------------

/// Convert between different visual coordinate spaces
pub trait SpaceConvert<T, From, To> {
    fn convert(self) -> T;
}

/// Marker trait for all valid visual spaces
pub trait VisualSpaceMarker {}

impl VisualSpaceMarker for VisualSpace {}
impl VisualSpaceMarker for BorderSpace {}
impl VisualSpaceMarker for ThemeSpace {}
impl VisualSpaceMarker for IconSpace {}
impl VisualSpaceMarker for IndicatorSpace {}
impl VisualSpaceMarker for EffectSpace {}

// --- Spatial Type Wrapper ---------------------------------------------------

/// Generic spatial type that can exist in any visual space
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Constructor)]
pub struct Spatial<T, S: VisualSpaceMarker> {
    pub value: T,
    _space: PhantomData<S>,
}

impl<T, S: VisualSpaceMarker> Spatial<T, S> {
    pub fn new(value: T) -> Self {
        Self { value, _space: PhantomData }
    }
    
    pub fn into_inner(self) -> T {
        self.value
    }
    
    pub fn to_space<NewS: VisualSpaceMarker>(self) -> Spatial<T, NewS> {
        Spatial::new(self.value)
    }
    
    pub fn map<U, F>(self, f: F) -> Spatial<U, S>
    where F: FnOnce(T) -> U
    {
        Spatial::new(f(self.value))
    }
}

impl<T, S: VisualSpaceMarker> From<T> for Spatial<T, S> {
    fn from(value: T) -> Self {
        Self::new(value)
    }
}

// --- Space-Specific Type Aliases --------------------------------------------

pub type BorderSpatial<T> = Spatial<T, BorderSpace>;
pub type ThemeSpatial<T> = Spatial<T, ThemeSpace>;
pub type IconSpatial<T> = Spatial<T, IconSpace>;
pub type IndicatorSpatial<T> = Spatial<T, IndicatorSpace>;
pub type EffectSpatial<T> = Spatial<T, EffectSpace>;