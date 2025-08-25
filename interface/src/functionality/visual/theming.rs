// Title         : functionality/visual/theming.rs
// Author        : Bardia Samiee
// Project       : Parametric Forge
// License       : MIT
// Path          : interface/src/functionality/visual/theming.rs
// ----------------------------------------------------------------------------
//! Theme management with type-safe color spaces and spatial integration

use derive_more::{Constructor, From, Display, Deref, DerefMut};
use getset::CopyGetters;
use bitflags::bitflags;
use rustc_hash::FxHashMap;
use compact_str::CompactString;
use ratatui::style::{Color, Style, Stylize};
use crate::functionality::core::geometry::{Point, Rect, ScreenSpace, SpatialEngine, Scalar};

// --- Type-Safe Theme Spaces -------------------------------------------------

pub struct LightSpace;
pub struct DarkSpace;
pub struct HighContrastSpace;
pub struct CustomSpace;

// --- Theme Flags -------------------------------------------------------------

bitflags! {
    pub struct ThemeFlags: u32 {
        // Theme types
        const LIGHT          = 1 << 0;  const DARK           = 1 << 1;
        const HIGH_CONTRAST  = 1 << 2;  const CUSTOM         = 1 << 3;
        // Visual features
        const ANIMATED       = 1 << 4;  const GRADIENT       = 1 << 5;
        const TRANSPARENCY   = 1 << 6;  const SHADOW         = 1 << 7;
        // Performance optimizations
        const CACHE          = 1 << 8;  const PRECOMPUTE     = 1 << 9;
        const LAZY_LOAD      = 1 << 10; const BATCH_UPDATE   = 1 << 11;
        // Accessibility
        const A11Y           = 1 << 12; const REDUCED_MOTION = 1 << 13;
        // Composite flags
        const ACCESSIBLE     = Self::HIGH_CONTRAST.bits() | Self::A11Y.bits() | Self::REDUCED_MOTION.bits();
        const PERFORMANCE    = Self::CACHE.bits() | Self::PRECOMPUTE.bits() | Self::BATCH_UPDATE.bits();
        const ENHANCED       = Self::ANIMATED.bits() | Self::GRADIENT.bits() | Self::TRANSPARENCY.bits();
        const OPTIMIZED      = Self::PERFORMANCE.bits() | Self::LAZY_LOAD.bits();
    }
}

// --- Color Palette with Spatial Awareness -----------------------------------

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Constructor, Display)]
#[display("rgb({}, {}, {})", r, g, b)]
pub struct ThemeColor<S = LightSpace> {
    pub r: u8, pub g: u8, pub b: u8,
    _space: std::marker::PhantomData<S>,
}

impl<S> ThemeColor<S> {
    pub fn new(r: u8, g: u8, b: u8) -> Self { Self { r, g, b, _space: std::marker::PhantomData } }
    pub fn to_space<NewS>(self) -> ThemeColor<NewS> { ThemeColor::new(self.r, self.g, self.b) }
    pub fn to_ratatui(self) -> Color { Color::Rgb(self.r, self.g, self.b) }
    pub fn blend(self, other: Self, factor: f32) -> Self {
        let factor = factor.clamp(0.0, 1.0);
        Self::new(
            (self.r as f32 * (1.0 - factor) + other.r as f32 * factor) as u8,
            (self.g as f32 * (1.0 - factor) + other.g as f32 * factor) as u8,
            (self.b as f32 * (1.0 - factor) + other.b as f32 * factor) as u8,
        )
    }
    pub fn darken(self, amount: f32) -> Self {
        let factor = (1.0 - amount.clamp(0.0, 1.0));
        Self::new((self.r as f32 * factor) as u8, (self.g as f32 * factor) as u8, (self.b as f32 * factor) as u8)
    }
    pub fn lighten(self, amount: f32) -> Self {
        let factor = 1.0 + amount.clamp(0.0, 1.0);
        Self::new((self.r as f32 * factor).min(255.0) as u8, (self.g as f32 * factor).min(255.0) as u8, (self.b as f32 * factor).min(255.0) as u8)
    }
}

// --- Spatial Theme Palette --------------------------------------------------

#[derive(Debug, Clone, Constructor, CopyGetters)]
pub struct ThemePalette<S = LightSpace> {
    #[getset(get_copy = "pub")]
    primary: ThemeColor<S>, secondary: ThemeColor<S>, accent: ThemeColor<S>,
    background: ThemeColor<S>, surface: ThemeColor<S>, text: ThemeColor<S>,
    success: ThemeColor<S>, warning: ThemeColor<S>, error: ThemeColor<S>,
    _space: std::marker::PhantomData<S>,
}

impl<S> ThemePalette<S> {
    pub fn to_space<NewS>(self) -> ThemePalette<NewS> {
        ThemePalette::new(
            self.primary.to_space(), self.secondary.to_space(), self.accent.to_space(),
            self.background.to_space(), self.surface.to_space(), self.text.to_space(),
            self.success.to_space(), self.warning.to_space(), self.error.to_space(),
            std::marker::PhantomData
        )
    }
}

// --- Theme Engine with Spatial Integration ----------------------------------

#[derive(Debug, Clone, Constructor)]
pub struct ThemeEngine<T: Scalar = usize, S = LightSpace> {
    palette: ThemePalette<S>,
    pub flags: ThemeFlags,
    spatial_engine: Option<SpatialEngine<T>>,
    cache: FxHashMap<u64, Style>,
    transitions: FxHashMap<CompactString, f32>,
}

impl<T: Scalar, S> ThemeEngine<T, S> where T: From<u8> {
    pub fn apply_style(&mut self, base: Style, position: Option<Point<u16, ScreenSpace>>) -> Style {
        if self.flags.contains(ThemeFlags::CACHE) {
            let key = self.cache_key(&base, position);
            if let Some(&cached) = self.cache.get(&key) { return cached; }
        }
        
        let mut style = base;
        
        // Apply spatial-aware styling
        if let (Some(pos), Some(engine)) = (position, &self.spatial_engine) {
            style = self.apply_spatial_effects(style, pos, engine);
        }
        
        // Apply theme-specific enhancements
        if self.flags.contains(ThemeFlags::ENHANCED) {
            style = self.apply_enhanced_effects(style);
        }
        
        if self.flags.contains(ThemeFlags::CACHE) {
            self.cache.insert(self.cache_key(&base, position), style);
        }
        
        style
    }
    
    pub fn create_gradient(&self, from: ThemeColor<S>, to: ThemeColor<S>, steps: usize) -> Vec<ThemeColor<S>> {
        (0..steps).map(|i| {
            let factor = i as f32 / (steps - 1).max(1) as f32;
            from.blend(to, factor)
        }).collect()
    }
    
    pub fn transition_color(&mut self, name: &str, from: ThemeColor<S>, to: ThemeColor<S>, progress: f32) -> ThemeColor<S> {
        let key = CompactString::from(name);
        let current_progress = *self.transitions.get(&key).unwrap_or(&0.0);
        let new_progress = if self.flags.contains(ThemeFlags::REDUCED_MOTION) { 1.0 } else { progress };
        self.transitions.insert(key, new_progress);
        from.blend(to, new_progress)
    }
    
    // --- Spatial Integration -------------------------------------------------
    
    fn apply_spatial_effects(&self, style: Style, position: Point<u16, ScreenSpace>, engine: &SpatialEngine<T>) -> Style {
        // Apply position-based color variations
        let variation = ((position.x() as f32 * 0.01) + (position.y() as f32 * 0.005)).sin() * 0.1;
        
        if let Some(bg) = style.bg {
            if let Color::Rgb(r, g, b) = bg {
                let factor = 1.0 + variation;
                style.bg(Color::Rgb(
                    (r as f32 * factor).clamp(0.0, 255.0) as u8,
                    (g as f32 * factor).clamp(0.0, 255.0) as u8,
                    (b as f32 * factor).clamp(0.0, 255.0) as u8,
                ))
            } else { style }
        } else { style }
    }
    
    fn apply_enhanced_effects(&self, style: Style) -> Style {
        let mut enhanced = style;
        
        if self.flags.contains(ThemeFlags::SHADOW) {
            enhanced = enhanced.underlined();
        }
        
        if self.flags.contains(ThemeFlags::GRADIENT) && enhanced.bg.is_some() {
            // Gradient effect would be applied here in a real implementation
            enhanced = enhanced.italic();
        }
        
        enhanced
    }
    
    fn cache_key(&self, style: &Style, position: Option<Point<u16, ScreenSpace>>) -> u64 {
        let pos_hash = position.map_or(0, |p| (p.x() as u64) << 16 | (p.y() as u64));
        let style_hash = style.fg.map_or(0, |_| 1) | (style.bg.map_or(0, |_| 2) << 1);
        pos_hash ^ style_hash ^ (self.flags.bits() as u64)
    }
    
    // --- Performance Operations ----------------------------------------------
    
    pub fn precompute_styles(&mut self, positions: &[Point<u16, ScreenSpace>]) {
        if !self.flags.contains(ThemeFlags::PRECOMPUTE) { return; }
        
        let base_style = Style::default();
        for &pos in positions {
            self.apply_style(base_style, Some(pos));
        }
    }
    
    pub fn invalidate_cache(&mut self) { self.cache.clear(); self.transitions.clear(); }
    pub fn cache_stats(&self) -> (usize, usize) { (self.cache.len(), self.cache.capacity()) }
}

// --- Fluent Theme Configuration API -----------------------------------------

impl<T: Scalar, S> ThemeEngine<T, S> where T: From<u8> {
    pub fn light() -> ThemeEngine<T, LightSpace> {
        let palette = ThemePalette::new(
            ThemeColor::new(59, 130, 246),   // Primary blue
            ThemeColor::new(99, 102, 241),   // Secondary indigo  
            ThemeColor::new(34, 197, 94),    // Accent green
            ThemeColor::new(255, 255, 255),  // Background white
            ThemeColor::new(249, 250, 251),  // Surface gray
            ThemeColor::new(17, 24, 39),     // Text dark
            ThemeColor::new(34, 197, 94),    // Success green
            ThemeColor::new(251, 191, 36),   // Warning yellow
            ThemeColor::new(239, 68, 68),    // Error red
            std::marker::PhantomData
        );
        ThemeEngine::new(palette, ThemeFlags::LIGHT | ThemeFlags::PERFORMANCE, None, FxHashMap::default(), FxHashMap::default())
    }
    
    pub fn dark() -> ThemeEngine<T, DarkSpace> {
        let palette = ThemePalette::new(
            ThemeColor::new(96, 165, 250),   // Primary light blue
            ThemeColor::new(129, 140, 248),  // Secondary light indigo
            ThemeColor::new(52, 211, 153),   // Accent light green
            ThemeColor::new(17, 24, 39),     // Background dark
            ThemeColor::new(31, 41, 55),     // Surface dark gray
            ThemeColor::new(243, 244, 246),  // Text light
            ThemeColor::new(52, 211, 153),   // Success light green
            ThemeColor::new(252, 211, 77),   // Warning light yellow
            ThemeColor::new(248, 113, 113),  // Error light red
            std::marker::PhantomData
        );
        ThemeEngine::new(palette, ThemeFlags::DARK | ThemeFlags::PERFORMANCE, None, FxHashMap::default(), FxHashMap::default())
    }
    
    pub fn high_contrast() -> ThemeEngine<T, HighContrastSpace> {
        let palette = ThemePalette::new(
            ThemeColor::new(0, 0, 0),        // Primary black
            ThemeColor::new(64, 64, 64),     // Secondary dark gray
            ThemeColor::new(255, 255, 0),    // Accent yellow
            ThemeColor::new(255, 255, 255),  // Background white
            ThemeColor::new(240, 240, 240),  // Surface light gray
            ThemeColor::new(0, 0, 0),        // Text black
            ThemeColor::new(0, 255, 0),      // Success bright green
            ThemeColor::new(255, 165, 0),    // Warning orange
            ThemeColor::new(255, 0, 0),      // Error bright red
            std::marker::PhantomData
        );
        ThemeEngine::new(palette, ThemeFlags::ACCESSIBLE, None, FxHashMap::default(), FxHashMap::default())
    }
    
    pub fn with_spatial_engine(mut self, engine: SpatialEngine<T>) -> Self { self.spatial_engine = Some(engine); self }
    pub fn with_animations(mut self) -> Self { self.flags |= ThemeFlags::ANIMATED; self }
    pub fn with_gradients(mut self) -> Self { self.flags |= ThemeFlags::GRADIENT; self }
    pub fn with_transparency(mut self) -> Self { self.flags |= ThemeFlags::TRANSPARENCY; self }
    pub fn optimized(mut self) -> Self { self.flags |= ThemeFlags::OPTIMIZED; self }
    pub fn enhanced(mut self) -> Self { self.flags |= ThemeFlags::ENHANCED; self }
    pub fn accessible(mut self) -> Self { self.flags |= ThemeFlags::ACCESSIBLE; self }
}

// --- Type Aliases ------------------------------------------------------------

pub type LightTheme<T = usize> = ThemeEngine<T, LightSpace>;
pub type DarkTheme<T = usize> = ThemeEngine<T, DarkSpace>;
pub type HighContrastTheme<T = usize> = ThemeEngine<T, HighContrastSpace>;
pub type LightColor = ThemeColor<LightSpace>;
pub type DarkColor = ThemeColor<DarkSpace>;

// --- Default Implementation --------------------------------------------------

impl<T: Scalar> Default for ThemeEngine<T, LightSpace> where T: From<u8> {
    fn default() -> Self { Self::light() }
}