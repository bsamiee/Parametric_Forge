// Title         : functionality/visual/mod.rs
// Author        : Bardia Samiee
// Project       : Parametric Forge
// License       : MIT
// Path          : interface/src/functionality/visual/mod.rs
// ----------------------------------------------------------------------------
//! Consolidated visual system leveraging core infrastructure and eliminating duplicates

pub mod animation;
pub mod theming;
pub mod borders;
pub mod icons;
pub mod indicators;
pub mod effects;

// --- Core Animation Exports -------------------------------------------------

pub use animation::{
    Animator, AnimationState, EasingFn,
    easing::{LINEAR, EASE_OUT, EASE_IN_OUT},
};

// --- Theme System Exports ---------------------------------------------------

pub use theming::{
    // Type-safe color spaces
    LightSpace, DarkSpace, HighContrastSpace, CustomSpace,
    // Color management
    ThemeColor, ThemePalette, ThemeEngine, ThemeFlags,
    // Type aliases for convenience
    LightTheme, DarkTheme, HighContrastTheme, LightColor, DarkColor,
};

// --- Border System Exports --------------------------------------------------

pub use borders::{
    // Border management (phantom spaces eliminated)
    BorderStyle, BorderEngine, BorderMetrics, BorderConnection, BorderConfig,
    // Type aliases
    SingleBorder, DoubleBorder, RoundedBorder, ThickBorder,
    // Enums
    ConnectionType,
};

// --- Icon System Exports ----------------------------------------------------

pub use icons::{
    // Icon management (phantom spaces eliminated)
    Icon, PositionedIcon, IconRegistry, IconEngine, IconCategory,
    // Type aliases
    FileIcon, StatusIcon, UIIcon,
    // Enums
    IconAlignment,
};

// --- Indicator System Exports -----------------------------------------------

pub use indicators::{
    // Progress indicators (phantom spaces eliminated)
    ProgressIndicator, StatusBadge, LoadingSpinner, IndicatorEngine, ProgressFlags,
    // Collections and helpers
    IndicatorCollection, ProgressExt,
    // Type aliases
    HorizontalProgress, VerticalProgress, CircularProgress,
    // Enums
    StatusType,
};

// --- Effects System Exports -------------------------------------------------

pub use effects::{
    // Animation and effects (phantom spaces eliminated)
    SpatialAnimation, FeedbackEffect, TransitionGroup, EffectsEngine, VisualFlags,
    // Performance monitoring
    PerformanceStats, EffectSnapshot,
    // Type aliases
    PositionTransition, RectTransition, RippleEffect, GlowEffect,
    // Enums
    FeedbackType, InteractionType,
};

// --- Unified Visual Configuration API ---------------------------------------

use crate::functionality::core::geometry::{SpatialEngine, Scalar, Point, Rect, ScreenSpace};

/// Comprehensive visual system builder with fluent API
#[derive(Debug, Clone)]
pub struct VisualSystem<T: Scalar = u16> {
    theme_engine: ThemeEngine<T>,
    border_engine: BorderEngine<T>,
    icon_engine: IconEngine<T>,
    indicator_engine: IndicatorEngine<T>,
    effects_engine: EffectsEngine<T>,
    spatial_engine: Option<SpatialEngine<T>>,
}

impl<T: Scalar> VisualSystem<T> 
where 
    T: From<u8> + num_traits::Zero + num_traits::One + num_traits::ToPrimitive,
{
    /// Create a new visual system with light theme defaults
    pub fn light() -> Self {
        Self {
            theme_engine: ThemeEngine::light(),
            border_engine: BorderEngine::single(),
            icon_engine: IconEngine::with_registry(),
            indicator_engine: IndicatorEngine::new(),
            effects_engine: EffectsEngine::new(),
            spatial_engine: None,
        }
    }
    
    /// Create a new visual system with dark theme defaults
    pub fn dark() -> Self {
        Self {
            theme_engine: ThemeEngine::dark(),
            border_engine: BorderEngine::rounded(),
            icon_engine: IconEngine::with_registry(),
            indicator_engine: IndicatorEngine::new(),
            effects_engine: EffectsEngine::new(),
            spatial_engine: None,
        }
    }
    
    /// Create a high-contrast accessible visual system
    pub fn accessible() -> Self {
        Self {
            theme_engine: ThemeEngine::high_contrast(),
            border_engine: BorderEngine::thick(),
            icon_engine: IconEngine::with_registry(),
            indicator_engine: IndicatorEngine::new(),
            effects_engine: EffectsEngine::new(),
            spatial_engine: None,
        }
    }
    
    // --- Fluent Configuration -----------------------------------------------
    
    pub fn with_spatial_engine(mut self, engine: SpatialEngine<T>) -> Self {
        self.spatial_engine = Some(engine.clone());
        self.theme_engine = self.theme_engine.with_spatial_engine(engine.clone());
        self.border_engine = self.border_engine.with_spatial_engine(engine.clone());
        self.icon_engine = self.icon_engine.with_spatial_engine(engine.clone());
        self.indicator_engine = self.indicator_engine.with_spatial_engine(engine.clone());
        self.effects_engine = self.effects_engine.with_spatial_engine(engine);
        self
    }
    
    pub fn optimized(mut self) -> Self {
        self.theme_engine = self.theme_engine.optimized();
        self.border_engine = self.border_engine.optimized();
        self.icon_engine = self.icon_engine.optimized();
        self.indicator_engine = self.indicator_engine.optimized();
        self.effects_engine = self.effects_engine.optimized();
        self
    }
    
    pub fn enhanced(mut self) -> Self {
        self.theme_engine = self.theme_engine.enhanced();
        self.border_engine = self.border_engine.enhanced();
        self.icon_engine = self.icon_engine.enhanced();
        self.effects_engine = self.effects_engine.enhanced();
        self
    }
    
    pub fn with_animations(mut self) -> Self {
        self.theme_engine = self.theme_engine.with_animations();
        self.effects_engine = self.effects_engine.enhanced();
        self
    }
    
    // --- System Access ------------------------------------------------------
    
    pub fn theme(&self) -> &ThemeEngine<T> { &self.theme_engine }
    pub fn theme_mut(&mut self) -> &mut ThemeEngine<T> { &mut self.theme_engine }
    
    pub fn borders(&self) -> &BorderEngine<T> { &self.border_engine }
    pub fn borders_mut(&mut self) -> &mut BorderEngine<T> { &mut self.border_engine }
    
    pub fn icons(&self) -> &IconEngine<T> { &self.icon_engine }
    pub fn icons_mut(&mut self) -> &mut IconEngine<T> { &mut self.icon_engine }
    
    pub fn indicators(&self) -> &IndicatorEngine<T> { &self.indicator_engine }
    pub fn indicators_mut(&mut self) -> &mut IndicatorEngine<T> { &mut self.indicator_engine }
    
    pub fn effects(&self) -> &EffectsEngine<T> { &self.effects_engine }
    pub fn effects_mut(&mut self) -> &mut EffectsEngine<T> { &mut self.effects_engine }
    
    // --- Unified Operations -------------------------------------------------
    
    pub fn update_frame(&mut self) -> PerformanceStats {
        self.effects_engine.update_all()
    }
    
    pub fn invalidate_all_caches(&mut self) {
        self.theme_engine.invalidate_cache();
        self.border_engine.invalidate_cache();
        self.icon_engine.invalidate_cache();
        self.indicator_engine.invalidate_cache();
        self.effects_engine.invalidate_cache();
    }
    
    pub fn cache_statistics(&self) -> CacheStatistics {
        CacheStatistics {
            theme_cache: self.theme_engine.cache_stats(),
            border_cache: self.border_engine.cache_stats(),
            icon_cache: self.icon_engine.cache_stats(),
            indicator_cache: self.indicator_engine.cache_stats(),
            effects_cache: self.effects_engine.cache_stats(),
        }
    }
    
    /// Render complete visual state for a screen area
    pub fn render_area(&mut self, area: Rect<T, ScreenSpace>) -> VisualSnapshot<T> {
        VisualSnapshot {
            icons: self.icon_engine.get_icons_in_area(area),
            indicators: self.indicator_engine.get_visible_in_area(area),
            effects: self.effects_engine.get_active_in_area(area),
            performance: self.update_frame(),
        }
    }
}

// --- Performance and Statistics Monitoring ----------------------------------

#[derive(Debug, Clone)]
pub struct CacheStatistics {
    pub theme_cache: (usize, usize),
    pub border_cache: (usize, usize),
    pub icon_cache: (usize, usize),
    pub indicator_cache: (usize, usize),
    pub effects_cache: (usize, usize),
}

impl CacheStatistics {
    pub fn total_entries(&self) -> usize {
        self.theme_cache.0 + self.border_cache.0 + self.icon_cache.0 + 
        self.indicator_cache.0 + self.effects_cache.0
    }
    
    pub fn total_capacity(&self) -> usize {
        self.theme_cache.1 + self.border_cache.1 + self.icon_cache.1 + 
        self.indicator_cache.1 + self.effects_cache.1
    }
    
    pub fn efficiency(&self) -> f32 {
        let total_entries = self.total_entries() as f32;
        let total_capacity = self.total_capacity() as f32;
        if total_capacity > 0.0 { total_entries / total_capacity } else { 0.0 }
    }
}

#[derive(Debug, Clone)]
pub struct VisualSnapshot<T: Scalar> {
    pub icons: Vec<&PositionedIcon<T>>,
    pub indicators: IndicatorCollection<T>,
    pub effects: Vec<EffectSnapshot<T>>,
    pub performance: PerformanceStats,
}

// --- Default Implementation --------------------------------------------------

impl<T: Scalar> Default for VisualSystem<T> 
where 
    T: From<u8> + num_traits::Zero + num_traits::One + num_traits::ToPrimitive,
{
    fn default() -> Self { Self::light() }
}

// --- Re-export Core Geometry Types for Convenience -------------------------

pub use crate::functionality::core::geometry::{
    Point, Rect, ScreenSpace, LogicalSpace, GridSpace,
    ScreenPoint, ScreenRect, LogicalPoint, LogicalRect, GridPoint,
    Direction, Viewport, SpatialEngine, SpatialFlags, Scalar,
};