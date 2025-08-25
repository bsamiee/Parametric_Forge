// Title         : functionality/visual/indicators.rs
// Author        : Bardia Samiee
// Project       : Parametric Forge
// License       : MIT
// Path          : interface/src/functionality/visual/indicators.rs
// ----------------------------------------------------------------------------
//! Status and progress indicators with spatial calculations

use derive_more::{Constructor, From, Display};
use getset::{CopyGetters, Getters};
use bitflags::bitflags;
use rustc_hash::FxHashMap;
use std::time::{Duration, Instant};
use crate::functionality::core::{geometry::{Point, Rect, ScreenSpace, SpatialEngine, Scalar}, state::StateFlags};
use super::theming::{ThemeEngine, ThemeColor};
use super::animation::{Animator, AnimationState, EasingFn};

// --- Using Core Coordinate Spaces -------------------------------------------
// Eliminated: ProgressSpace, StatusSpace, LoadingSpace, BadgeSpace
// Using: ScreenSpace, LogicalSpace, GridSpace from core::geometry

// --- Progress and Indicator Flags -------------------------------------------
// Using core::state::StateFlags + specialized indicator flags
bitflags! {
    pub struct ProgressFlags: u16 {
        const HORIZONTAL    = 1 << 0; const VERTICAL      = 1 << 1;
        const CIRCULAR      = 1 << 2; const SEGMENTED     = 1 << 3;
        const ANIMATED      = 1 << 4; const GRADIENT      = 1 << 5;
    }
}

// --- Progress Indicator with Spatial Awareness ------------------------------

#[derive(Debug, Clone, Constructor, CopyGetters)]
pub struct ProgressIndicator<T: Scalar = u16> {
    #[getset(get_copy = "pub")]
    value: f32, // 0.0 to 1.0
    max_value: f32,
    bounds: Rect<T, ScreenSpace>,
    progress_flags: ProgressFlags,
    animator: Option<Animator>,
}

impl<T: Scalar> ProgressIndicator<T> {
    pub fn new(value: f32, max_value: f32, bounds: Rect<T, ScreenSpace>, progress_flags: ProgressFlags) -> Self {
        let animator = if progress_flags.contains(ProgressFlags::ANIMATED) {
            Some(Animator::new(Duration::from_millis(300), super::animation::easing::EASE_OUT))
        } else { None };
        Self { value, max_value, bounds, progress_flags, animator }
    }
    
    pub fn progress(&self) -> f32 { self.value / self.max_value.max(1e-6) }
    
    pub fn set_value(&mut self, new_value: f32) {
        if let Some(ref mut animator) = self.animator {
            animator.start(self.value, new_value);
        }
        self.value = new_value.clamp(0.0, self.max_value);
    }
    
    pub fn increment(&mut self, delta: f32) {
        self.set_value(self.value + delta);
    }
    
    pub fn current_visual_progress(&self) -> f32 {
        if let Some(ref animator) = self.animator {
            animator.current_value().unwrap_or(self.progress())
        } else {
            self.progress()
        }
    }
    
    pub fn calculate_fill_rect(&self) -> Rect<T, ScreenSpace> {
        let progress = self.current_visual_progress();
        
        if self.progress_flags.contains(ProgressFlags::HORIZONTAL) {
            let fill_width = (self.bounds.w().to_f32().unwrap_or(0.0) * progress) as u64;
            Rect::new(self.bounds.x(), self.bounds.y(), T::from(fill_width).unwrap_or(T::zero()), self.bounds.h())
        } else if self.progress_flags.contains(ProgressFlags::VERTICAL) {
            let fill_height = (self.bounds.h().to_f32().unwrap_or(0.0) * progress) as u64;
            let y_offset = self.bounds.h() - T::from(fill_height).unwrap_or(T::zero());
            Rect::new(self.bounds.x(), self.bounds.y() + y_offset, self.bounds.w(), T::from(fill_height).unwrap_or(T::zero()))
        } else {
            // Default to horizontal
            let fill_width = (self.bounds.w().to_f32().unwrap_or(0.0) * progress) as u64;
            Rect::new(self.bounds.x(), self.bounds.y(), T::from(fill_width).unwrap_or(T::zero()), self.bounds.h())
        }
    }
    
    // Removed to_space - no longer needed without phantom types
}

// --- Status Badge with Smart Positioning ------------------------------------

#[derive(Debug, Clone, Constructor, CopyGetters, Getters)]
pub struct StatusBadge<T: Scalar = u16> {
    #[getset(get_copy = "pub")]
    status: StatusType,
    position: Point<T, ScreenSpace>,
    #[getset(get = "pub")]
    message: Option<String>,
    state_flags: StateFlags,
    pulse_animator: Option<Animator>,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum StatusType {
    Success, Warning, Error, Info, Loading, Custom(u8),
}

impl<T: Scalar> StatusBadge<T> {
    pub fn success(position: Point<T, ScreenSpace>) -> Self {
        Self::new(StatusType::Success, position, None, StateFlags::empty(), None)
    }
    
    pub fn error(position: Point<T, ScreenSpace>) -> Self {
        Self::new(StatusType::Error, position, None, StateFlags::ERROR_STATE,
                  Some(Animator::new(Duration::from_millis(800), super::animation::easing::EASE_IN_OUT)))
    }
    
    pub fn warning(position: Point<T, ScreenSpace>) -> Self {
        Self::new(StatusType::Warning, position, None, StateFlags::empty(),
                  Some(Animator::new(Duration::from_millis(600), super::animation::easing::LINEAR)))
    }
    
    pub fn loading(position: Point<T, ScreenSpace>) -> Self {
        Self::new(StatusType::Loading, position, None, StateFlags::empty(),
                  Some(Animator::new(Duration::from_millis(1000), super::animation::easing::LINEAR)))
    }
    
    pub fn with_message(mut self, message: String) -> Self {
        self.message = Some(message); self
    }
    
    pub fn get_color(&self) -> ThemeColor {
        match self.status {
            StatusType::Success => ThemeColor::new(34, 197, 94),   // Green
            StatusType::Warning => ThemeColor::new(251, 191, 36),  // Yellow
            StatusType::Error => ThemeColor::new(239, 68, 68),     // Red
            StatusType::Info => ThemeColor::new(59, 130, 246),     // Blue
            StatusType::Loading => ThemeColor::new(156, 163, 175), // Gray
            StatusType::Custom(v) => ThemeColor::new(v, v, v),     // Custom gray
        }
    }
    
    pub fn get_icon(&self) -> char {
        match self.status {
            StatusType::Success => '✓',
            StatusType::Warning => '⚠',
            StatusType::Error => '✗',
            StatusType::Info => 'ℹ',
            StatusType::Loading => '⟲',
            StatusType::Custom(_) => '●',
        }
    }
    
    pub fn current_opacity(&self) -> f32 {
        if let Some(ref animator) = self.pulse_animator {
            let base = 0.7;
            let variation = 0.3;
            if let Some(progress) = animator.current_value() {
                base + variation * (progress * 2.0 * std::f32::consts::PI).sin()
            } else { 1.0 }
        } else { 1.0 }
    }
}

// --- Loading Spinner with Spatial Integration -------------------------------

#[derive(Debug, Clone, Constructor, CopyGetters)]
pub struct LoadingSpinner<T: Scalar = u16> {
    #[getset(get_copy = "pub")]
    center: Point<T, ScreenSpace>,
    radius: T,
    segments: u8,
    rotation: f32,
    animator: Animator,
}

impl<T: Scalar> LoadingSpinner<T> where T: From<u8> {
    pub fn new(center: Point<T, ScreenSpace>, radius: T, segments: u8) -> Self {
        let animator = Animator::new(Duration::from_millis(1200), super::animation::easing::LINEAR);
        Self { center, radius, segments, rotation: 0.0, animator }
    }
    
    pub fn update(&mut self) {
        if let Some(progress) = self.animator.current_value() {
            self.rotation = progress * 360.0;
        }
    }
    
    pub fn get_segment_positions(&self) -> Vec<Point<T, ScreenSpace>> {
        let mut positions = Vec::with_capacity(self.segments as usize);
        let angle_step = 360.0 / self.segments as f32;
        
        for i in 0..self.segments {
            let angle = (i as f32 * angle_step + self.rotation).to_radians();
            let x_offset = (self.radius.to_f32().unwrap_or(0.0) * angle.cos()) as u64;
            let y_offset = (self.radius.to_f32().unwrap_or(0.0) * angle.sin()) as u64;
            
            let x = self.center.x() + T::from(x_offset).unwrap_or(T::zero());
            let y = self.center.y() + T::from(y_offset).unwrap_or(T::zero());
            
            positions.push(Point::new(x, y));
        }
        
        positions
    }
    
    pub fn get_segment_opacity(&self, segment_index: u8) -> f32 {
        let phase = (segment_index as f32 / self.segments as f32) * 2.0 * std::f32::consts::PI;
        let time_offset = (self.rotation / 360.0) * 2.0 * std::f32::consts::PI;
        0.3 + 0.7 * ((phase + time_offset).sin().max(0.0))
    }
}

// --- Indicator Engine with Performance Optimization -------------------------

#[derive(Debug, Clone, Constructor)]
pub struct IndicatorEngine<T: Scalar = u16> {
    progress_bars: FxHashMap<String, ProgressIndicator<T>>,
    status_badges: FxHashMap<String, StatusBadge<T>>,
    loading_spinners: FxHashMap<String, LoadingSpinner<T>>,
    spatial_engine: Option<SpatialEngine<T>>,
    state_flags: StateFlags,
    cache: FxHashMap<u64, (Point<T, ScreenSpace>, f32)>, // position, opacity
}

impl<T: Scalar> IndicatorEngine<T> where T: From<u8> + num_traits::Zero + num_traits::One {
    pub fn add_progress(&mut self, id: String, progress: ProgressIndicator<T>) {
        self.progress_bars.insert(id, progress);
    }
    
    pub fn add_status(&mut self, id: String, status: StatusBadge<T>) {
        self.status_badges.insert(id, status);
    }
    
    pub fn add_spinner(&mut self, id: String, spinner: LoadingSpinner<T>) {
        self.loading_spinners.insert(id, spinner);
    }
    
    pub fn update_progress(&mut self, id: &str, value: f32) {
        if let Some(progress) = self.progress_bars.get_mut(id) {
            progress.set_value(value);
        }
    }
    
    pub fn remove_indicator(&mut self, id: &str) {
        self.progress_bars.remove(id);
        self.status_badges.remove(id);
        self.loading_spinners.remove(id);
    }
    
    pub fn update_all(&mut self) {
        for spinner in self.loading_spinners.values_mut() {
            spinner.update();
        }
    }
    
    pub fn get_visible_in_area(&self, area: Rect<T, ScreenSpace>) -> IndicatorCollection<T> {
        let progress_bars: Vec<_> = self.progress_bars.iter()
            .filter(|(_, p)| area.intersects(&p.bounds))
            .map(|(id, p)| (id.clone(), p.clone()))
            .collect();
            
        let status_badges: Vec<_> = self.status_badges.iter()
            .filter(|(_, s)| area.contains(s.position))
            .map(|(id, s)| (id.clone(), s.clone()))
            .collect();
            
        let loading_spinners: Vec<_> = self.loading_spinners.iter()
            .filter(|(_, s)| area.contains(s.center))
            .map(|(id, s)| (id.clone(), s.clone()))
            .collect();
            
        IndicatorCollection { progress_bars, status_badges, loading_spinners }
    }
    
    // --- Performance Operations ----------------------------------------------
    
    pub fn batch_update_progress(&mut self, updates: &[(String, f32)]) {
        // Batch update simplified - no longer needed with StateFlags
            for (id, value) in updates {
                self.update_progress(id, *value);
            }
        } else {
            for (id, value) in updates {
                self.update_progress(id, *value);
            }
        }
    }
    
    pub fn invalidate_cache(&mut self) { 
        self.cache.clear(); 
    }
    
    pub fn cache_stats(&self) -> (usize, usize) { 
        (self.cache.len(), self.cache.capacity()) 
    }
    
    pub fn indicator_count(&self) -> usize {
        self.progress_bars.len() + self.status_badges.len() + self.loading_spinners.len()
    }
}

// --- Indicator Collection for Rendering -------------------------------------

#[derive(Debug, Clone)]
pub struct IndicatorCollection<T: Scalar> {
    pub progress_bars: Vec<(String, ProgressIndicator<T>)>,
    pub status_badges: Vec<(String, StatusBadge<T>)>,
    pub loading_spinners: Vec<(String, LoadingSpinner<T>)>,
}

// --- Fluent Indicator Configuration API -------------------------------------

impl<T: Scalar> IndicatorEngine<T> where T: From<u8> + num_traits::Zero + num_traits::One {
    pub fn new() -> Self {
        Self::default()
    }
    
    // Using derive_more::Constructor instead of fluent methods
    pub fn with_spatial_engine(mut self, engine: SpatialEngine<T>) -> Self { 
        self.spatial_engine = Some(engine); self 
    }
}

// --- Helper Trait Extensions ------------------------------------------------

pub trait ProgressExt<T: Scalar> {
    fn horizontal(bounds: Rect<T, ScreenSpace>) -> ProgressIndicator<T>;
    fn vertical(bounds: Rect<T, ScreenSpace>) -> ProgressIndicator<T>;
    fn circular(center: Point<T, ScreenSpace>, radius: T) -> ProgressIndicator<T>;
}

impl<T: Scalar> ProgressExt<T> for ProgressIndicator<T> {
    fn horizontal(bounds: Rect<T, ScreenSpace>) -> ProgressIndicator<T> {
        ProgressIndicator::new(0.0, 100.0, bounds, ProgressFlags::HORIZONTAL)
    }
    
    fn vertical(bounds: Rect<T, ScreenSpace>) -> ProgressIndicator<T> {
        ProgressIndicator::new(0.0, 100.0, bounds, ProgressFlags::VERTICAL)
    }
    
    fn circular(center: Point<T, ScreenSpace>, radius: T) -> ProgressIndicator<T> {
        let bounds = Rect::new(
            center.x() - radius, center.y() - radius,
            radius + radius, radius + radius
        );
        ProgressIndicator::new(0.0, 100.0, bounds, ProgressFlags::CIRCULAR)
    }
}

// --- Type Aliases ------------------------------------------------------------

pub type HorizontalProgress<T = u16> = ProgressIndicator<T>;
pub type VerticalProgress<T = u16> = ProgressIndicator<T>;
pub type CircularProgress<T = u16> = ProgressIndicator<T>;

// --- Default Implementation --------------------------------------------------

impl<T: Scalar> Default for IndicatorEngine<T> where T: From<u8> + num_traits::Zero + num_traits::One {
    fn default() -> Self {
        Self::new(
            FxHashMap::default(), FxHashMap::default(), FxHashMap::default(),
            None, StateFlags::empty(), FxHashMap::default()
        )
    }
}

// --- Trait Extensions for Scalar Types --------------------------------------

trait ToF32 {
    fn to_f32(&self) -> Option<f32>;
}

impl<T: Scalar> ToF32 for T {
    fn to_f32(&self) -> Option<f32> {
        self.to_f32()
    }
}