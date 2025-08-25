// Title         : functionality/visual/traits.rs
// Author        : Bardia Samiee
// Project       : Parametric Forge
// License       : MIT
// Path          : interface/src/functionality/visual/traits.rs
// ----------------------------------------------------------------------------
//! Unified trait definitions for all visual components

use crate::functionality::core::geometry::{Scalar, SpatialEngine, Point, Rect, ScreenSpace};
use super::spaces::VisualSpaceMarker;
use bitflags::bitflags;
use rustc_hash::FxHashMap;

// --- Numeric Conversion Traits ----------------------------------------------

/// Universal numeric conversion trait - replaces duplicate ToF32 implementations
pub trait ToF32<T> {
    fn to_f32(&self) -> Option<f32>;
    fn saturating_sub(&self, other: T) -> T;
}

impl<T: Scalar> ToF32<T> for T {
    fn to_f32(&self) -> Option<f32> {
        num_traits::ToPrimitive::to_f32(self)
    }
    
    fn saturating_sub(&self, other: T) -> T {
        num_traits::Saturating::saturating_sub(self, &other)
    }
}

// --- Universal Visual Engine Traits -----------------------------------------

/// Core engine behavior shared across all visual systems
pub trait VisualEngine<T: Scalar> {
    type Flags: Copy + Clone;
    
    fn flags(&self) -> Self::Flags;
    fn set_flags(&mut self, flags: Self::Flags);
    fn with_spatial_engine(self, engine: SpatialEngine<T>) -> Self;
    fn invalidate_cache(&mut self);
    fn cache_stats(&self) -> (usize, usize);
}

/// Rendering capability for visual components
pub trait Renderable<T: Scalar> {
    type Output;
    
    fn render(&mut self, area: Rect<T, ScreenSpace>) -> Self::Output;
    fn is_visible_in(&self, viewport: Rect<T, ScreenSpace>) -> bool;
}

/// Animation support for visual components
pub trait Animatable {
    fn update_animation(&mut self) -> bool; // Returns true if still animating
    fn start_animation(&mut self);
    fn stop_animation(&mut self);
    fn is_animating(&self) -> bool;
}

/// Spatial positioning for visual components
pub trait Positionable<T: Scalar, S: VisualSpaceMarker> {
    fn position(&self) -> Point<T, ScreenSpace>;
    fn set_position(&mut self, position: Point<T, ScreenSpace>);
    fn move_by(&mut self, delta: Point<T, ScreenSpace>);
    fn bounds(&self) -> Option<Rect<T, ScreenSpace>>;
}

/// Theme integration for visual components
pub trait Themeable<T: Scalar> {
    fn apply_theme(&mut self, theme_engine: &mut dyn VisualEngine<T>);
    fn supports_theme_transitions(&self) -> bool { false }
}

/// Performance optimization traits
pub trait Cacheable {
    fn enable_caching(&mut self);
    fn disable_caching(&mut self);
    fn is_caching_enabled(&self) -> bool;
}

pub trait BatchRenderable<T: Scalar> {
    type Item;
    type Output;
    
    fn batch_render(&mut self, items: &[Self::Item], area: Rect<T, ScreenSpace>) -> Vec<Self::Output>;
}

// --- Fluent Configuration Trait ---------------------------------------------

/// Standard fluent API pattern for all visual engines
pub trait FluentConfig<T: Scalar>: Sized {
    type Engine: VisualEngine<T>;
    
    fn optimized(self) -> Self;
    fn enhanced(self) -> Self;
    fn with_caching(self) -> Self;
    fn spatial_aware(self) -> Self;
}

// --- Spatial Integration Traits ---------------------------------------------

/// Integration with the core spatial system
pub trait SpatialIntegration<T: Scalar> {
    fn spatial_engine(&self) -> Option<&SpatialEngine<T>>;
    fn spatial_engine_mut(&mut self) -> Option<&mut SpatialEngine<T>>;
    fn set_spatial_engine(&mut self, engine: SpatialEngine<T>);
    fn calculate_spatial_bounds(&self) -> Option<Rect<T, ScreenSpace>>;
}

/// Collection management for visual components
pub trait VisualCollection<T: Scalar> {
    type Item;
    
    fn add_item(&mut self, item: Self::Item);
    fn remove_item(&mut self, id: &str) -> Option<Self::Item>;
    fn get_items_in_area(&self, area: Rect<T, ScreenSpace>) -> Vec<&Self::Item>;
    fn update_all(&mut self);
    fn clear(&mut self);
    fn count(&self) -> usize;
}