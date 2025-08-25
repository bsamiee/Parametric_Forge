// Title         : functionality/visual/effects.rs
// Author        : Bardia Samiee
// Project       : Parametric Forge
// License       : MIT
// Path          : interface/src/functionality/visual/effects.rs
// ----------------------------------------------------------------------------
//! Enhanced visual effects system with spatial integration

use derive_more::{Constructor, From, Display};
use getset::CopyGetters;
use bitflags::bitflags;
use rustc_hash::FxHashMap;
use tinyvec::TinyVec;
use std::time::{Duration, Instant};
use crate::functionality::core::{geometry::{Point, Rect, ScreenSpace, SpatialEngine, Scalar}, state::StateFlags};
use super::theming::{ThemeEngine, ThemeColor};
use super::animation::{Animator, AnimationState, EasingFn};

// --- Using Core Coordinate Spaces -------------------------------------------
// Eliminated: TransitionSpace, FeedbackSpace, InteractionSpace, AmbientSpace
// Using: ScreenSpace, LogicalSpace, GridSpace from core::geometry

// --- Extended Core State Flags ----------------------------------------------
// Using core::state::StateFlags instead of duplicate EffectFlags
// Extended with visual effect flags
bitflags! {
    pub struct VisualFlags: u32 {
        // Visual properties only (leverage StateFlags for core functionality)
        const FADE          = 1 << 0;  const SLIDE         = 1 << 1;
        const SCALE         = 1 << 2;  const ROTATE        = 1 << 3;
        const BLUR          = 1 << 4;  const GLOW          = 1 << 5;
        const RIPPLE        = 1 << 6;  const SHAKE         = 1 << 7;
        // Timing behaviors
        const INSTANT       = 1 << 8;  const SMOOTH        = 1 << 9;
        const ELASTIC       = 1 << 10; const BOUNCE        = 1 << 11;
        // Composite flags
        const ENHANCED      = Self::GLOW.bits() | Self::BLUR.bits() | Self::RIPPLE.bits();
        const DYNAMIC       = Self::SHAKE.bits() | Self::RIPPLE.bits() | Self::BOUNCE.bits();
    }
}

// --- Enhanced Animation with Spatial Integration ----------------------------

#[derive(Debug, Clone, Constructor, CopyGetters)]
pub struct SpatialAnimation<T: Scalar = u16> {
    #[getset(get_copy = "pub")]
    start_pos: Point<T, ScreenSpace>,
    end_pos: Point<T, ScreenSpace>,
    start_rect: Option<Rect<T, ScreenSpace>>,
    end_rect: Option<Rect<T, ScreenSpace>>,
    animator: Animator,
    state_flags: StateFlags,
    visual_flags: VisualFlags,
}

impl<T: Scalar> SpatialAnimation<T> where T: num_traits::Zero + num_traits::One {
    pub fn point_to_point(start: Point<T, ScreenSpace>, end: Point<T, ScreenSpace>, duration: Duration, easing: EasingFn) -> Self {
        let mut animator = Animator::new(duration, easing);
        animator.start(0.0, 1.0);
        Self::new(start, end, None, None, animator, StateFlags::empty(), VisualFlags::SMOOTH)
    }
    
    pub fn rect_to_rect(start: Rect<T, ScreenSpace>, end: Rect<T, ScreenSpace>, duration: Duration, easing: EasingFn) -> Self {
        let mut animator = Animator::new(duration, easing);
        animator.start(0.0, 1.0);
        Self::new(
            Point::new(start.x(), start.y()), Point::new(end.x(), end.y()),
            Some(start), Some(end), animator, 
            StateFlags::empty(), VisualFlags::SMOOTH
        )
    }
    
    pub fn current_position(&self) -> Option<Point<T, ScreenSpace>> {
        self.animator.current_value().map(|progress| {
            let start_x_f32 = self.start_pos.x().to_f32().unwrap_or(0.0);
            let start_y_f32 = self.start_pos.y().to_f32().unwrap_or(0.0);
            let end_x_f32 = self.end_pos.x().to_f32().unwrap_or(0.0);
            let end_y_f32 = self.end_pos.y().to_f32().unwrap_or(0.0);
            
            let current_x = start_x_f32 + (end_x_f32 - start_x_f32) * progress;
            let current_y = start_y_f32 + (end_y_f32 - start_y_f32) * progress;
            
            Point::new(
                T::from(current_x as u64).unwrap_or(T::zero()),
                T::from(current_y as u64).unwrap_or(T::zero())
            )
        })
    }
    
    pub fn current_rect(&self) -> Option<Rect<T, ScreenSpace>> {
        if let (Some(start_rect), Some(end_rect), Some(progress)) = 
           (self.start_rect, self.end_rect, self.animator.current_value()) {
            
            let lerp_value = |start: T, end: T, p: f32| -> T {
                let start_f32 = start.to_f32().unwrap_or(0.0);
                let end_f32 = end.to_f32().unwrap_or(0.0);
                let current = start_f32 + (end_f32 - start_f32) * p;
                T::from(current as u64).unwrap_or(T::zero())
            };
            
            Some(Rect::new(
                lerp_value(start_rect.x(), end_rect.x(), progress),
                lerp_value(start_rect.y(), end_rect.y(), progress),
                lerp_value(start_rect.w(), end_rect.w(), progress),
                lerp_value(start_rect.h(), end_rect.h(), progress),
            ))
        } else {
            None
        }
    }
    
    pub fn is_complete(&self) -> bool {
        matches!(self.animator.state, AnimationState::Idle) ||
        self.animator.current_value().map_or(false, |v| v >= 1.0)
    }
}

// --- Visual Feedback Effects ------------------------------------------------

#[derive(Debug, Clone, Constructor, CopyGetters)]
pub struct FeedbackEffect<T: Scalar = u16> {
    #[getset(get_copy = "pub")]
    center: Point<T, ScreenSpace>,
    max_radius: T,
    color: ThemeColor,
    intensity: f32,
    animator: Animator,
    visual_flags: VisualFlags,
}

impl<T: Scalar> FeedbackEffect<T> where T: From<u8> + num_traits::Zero {
    pub fn ripple(center: Point<T, ScreenSpace>, max_radius: T, color: ThemeColor) -> Self {
        let mut animator = Animator::new(Duration::from_millis(600), super::animation::easing::EASE_OUT);
        animator.start(0.0, 1.0);
        Self::new(center, max_radius, color, 1.0, animator, VisualFlags::RIPPLE | VisualFlags::FADE)
    }
    
    pub fn glow(center: Point<T, ScreenSpace>, intensity: f32, color: ThemeColor) -> Self {
        let mut animator = Animator::new(Duration::from_millis(400), super::animation::easing::EASE_IN_OUT);
        animator.start(0.0, 1.0);
        Self::new(center, T::from(20).unwrap_or(T::zero()), color, intensity, animator, VisualFlags::GLOW | VisualFlags::FADE)
    }
    
    pub fn shake(center: Point<T, ScreenSpace>, intensity: f32) -> Self {
        let mut animator = Animator::new(Duration::from_millis(200), super::animation::easing::ELASTIC);
        animator.start(0.0, 1.0);
        Self::new(center, T::from(5).unwrap_or(T::zero()), ThemeColor::new(255, 255, 255), intensity, animator, VisualFlags::SHAKE | VisualFlags::ELASTIC)
    }
    
    pub fn current_radius(&self) -> T {
        let progress = self.animator.current_value().unwrap_or(0.0);
        let radius_f32 = self.max_radius.to_f32().unwrap_or(0.0) * progress;
        T::from(radius_f32 as u64).unwrap_or(T::zero())
    }
    
    pub fn current_opacity(&self) -> f32 {
        let progress = self.animator.current_value().unwrap_or(0.0);
        if self.visual_flags.contains(VisualFlags::FADE) {
            self.intensity * (1.0 - progress)
        } else {
            self.intensity
        }
    }
    
    pub fn current_offset(&self) -> Point<T, ScreenSpace> {
        if self.visual_flags.contains(VisualFlags::SHAKE) {
            let progress = self.animator.current_value().unwrap_or(0.0);
            let shake_intensity = self.intensity * (1.0 - progress);
            let offset_x = (shake_intensity * (progress * 20.0).sin()) as i32;
            let offset_y = (shake_intensity * (progress * 25.0).cos()) as i32;
            
            Point::new(
                if offset_x >= 0 { self.center.x() + T::from(offset_x as u64).unwrap_or(T::zero()) }
                else { self.center.x().saturating_sub(T::from((-offset_x) as u64).unwrap_or(T::zero())) },
                if offset_y >= 0 { self.center.y() + T::from(offset_y as u64).unwrap_or(T::zero()) }
                else { self.center.y().saturating_sub(T::from((-offset_y) as u64).unwrap_or(T::zero())) }
            )
        } else {
            self.center
        }
    }
}

// --- Transition Collections for Performance ---------------------------------

#[derive(Debug, Clone)]
pub struct TransitionGroup<T: Scalar> {
    animations: TinyVec<[SpatialAnimation<T>; 4]>,
    effects: TinyVec<[FeedbackEffect<T>; 2]>,
    state_flags: StateFlags,
    start_time: Instant,
}

impl<T: Scalar> TransitionGroup<T> where T: From<u8> + num_traits::Zero + num_traits::One {
    pub fn new() -> Self {
        Self {
            animations: TinyVec::new(),
            effects: TinyVec::new(),
            state_flags: StateFlags::empty(),
            start_time: Instant::now(),
        }
    }
    
    pub fn add_animation(&mut self, animation: SpatialAnimation<T>) {
        self.animations.push(animation);
    }
    
    pub fn add_effect(&mut self, effect: FeedbackEffect<T>) {
        self.effects.push(effect);
    }
    
    pub fn update(&mut self) -> bool {
        let any_active = !self.animations.iter().all(|a| a.is_complete()) ||
                        !self.effects.iter().all(|e| e.animator.current_value().map_or(false, |v| v >= 1.0));
        
        if !any_active {
            self.animations.clear();
            self.effects.clear();
        }
        
        any_active
    }
    
    pub fn get_active_animations(&self) -> impl Iterator<Item = &SpatialAnimation<T>> {
        self.animations.iter().filter(|a| !a.is_complete())
    }
    
    pub fn get_active_effects(&self) -> impl Iterator<Item = &FeedbackEffect<T>> {
        self.effects.iter().filter(|e| e.animator.current_value().map_or(true, |v| v < 1.0))
    }
}

// --- Effects Engine with Spatial Integration --------------------------------

#[derive(Debug, Clone, Constructor)]
pub struct EffectsEngine<T: Scalar = u16> {
    transition_groups: FxHashMap<String, TransitionGroup<T>>,
    spatial_engine: Option<SpatialEngine<T>>,
    state_flags: StateFlags,
    cache: FxHashMap<u64, (Point<T, ScreenSpace>, f32, f32)>, // position, scale, opacity
    performance_stats: PerformanceStats,
}

#[derive(Debug, Clone, Default, CopyGetters)]
pub struct PerformanceStats {
    #[getset(get_copy = "pub")]
    active_animations: usize,
    active_effects: usize,
    frame_time_ms: f32,
    cache_hit_rate: f32,
}

impl<T: Scalar> EffectsEngine<T> where T: From<u8> + num_traits::Zero + num_traits::One {
    pub fn create_transition(&mut self, id: String, from: Point<T, ScreenSpace>, to: Point<T, ScreenSpace>, duration: Duration) {
        let animation = SpatialAnimation::point_to_point(from, to, duration, super::animation::easing::EASE_OUT);
        let mut group = TransitionGroup::new();
        group.add_animation(animation);
        self.transition_groups.insert(id, group);
    }
    
    pub fn create_rect_transition(&mut self, id: String, from: Rect<T, ScreenSpace>, to: Rect<T, ScreenSpace>, duration: Duration) {
        let animation = SpatialAnimation::rect_to_rect(from, to, duration, super::animation::easing::EASE_IN_OUT);
        let mut group = TransitionGroup::new();
        group.add_animation(animation);
        self.transition_groups.insert(id, group);
    }
    
    pub fn create_feedback(&mut self, id: String, effect_type: FeedbackType, position: Point<T, ScreenSpace>, color: ThemeColor) {
        let effect = match effect_type {
            FeedbackType::Ripple => FeedbackEffect::ripple(position, T::from(30).unwrap_or(T::zero()), color),
            FeedbackType::Glow => FeedbackEffect::glow(position, 0.8, color),
            FeedbackType::Shake => FeedbackEffect::shake(position, 0.6),
        };
        
        self.transition_groups.entry(id)
            .or_insert_with(TransitionGroup::new)
            .add_effect(effect);
    }
    
    pub fn trigger_interaction_feedback(&mut self, position: Point<T, ScreenSpace>, interaction: InteractionType) {
        let id = format!("interaction_{}", std::ptr::addr_of!(position) as usize);
        let (effect_type, color) = match interaction {
            InteractionType::Click => (FeedbackType::Ripple, ThemeColor::new(59, 130, 246)),
            InteractionType::Hover => (FeedbackType::Glow, ThemeColor::new(156, 163, 175)),
            InteractionType::Focus => (FeedbackType::Glow, ThemeColor::new(34, 197, 94)),
            InteractionType::Error => (FeedbackType::Shake, ThemeColor::new(239, 68, 68)),
        };
        
        self.create_feedback(id, effect_type, position, color);
    }
    
    pub fn update_all(&mut self) -> PerformanceStats {
        let frame_start = Instant::now();
        let mut active_animations = 0;
        let mut active_effects = 0;
        
        self.transition_groups.retain(|_, group| {
            let is_active = group.update();
            if is_active {
                active_animations += group.animations.len();
                active_effects += group.effects.len();
            }
            is_active
        });
        
        self.performance_stats = PerformanceStats {
            active_animations,
            active_effects,
            frame_time_ms: frame_start.elapsed().as_secs_f32() * 1000.0,
            cache_hit_rate: self.calculate_cache_hit_rate(),
        };
        
        self.performance_stats
    }
    
    pub fn get_active_in_area(&self, area: Rect<T, ScreenSpace>) -> Vec<EffectSnapshot<T>> {
        let mut snapshots = Vec::new();
        
        for (id, group) in &self.transition_groups {
            for animation in group.get_active_animations() {
                if let Some(pos) = animation.current_position() {
                    if area.contains(pos) {
                        snapshots.push(EffectSnapshot::Animation {
                            id: id.clone(),
                            position: pos,
                            rect: animation.current_rect(),
                            progress: animation.animator.current_value().unwrap_or(0.0),
                        });
                    }
                }
            }
            
            for effect in group.get_active_effects() {
                let pos = effect.current_offset();
                if area.contains(pos) {
                    snapshots.push(EffectSnapshot::Effect {
                        id: id.clone(),
                        position: pos,
                        radius: effect.current_radius(),
                        color: effect.color,
                        opacity: effect.current_opacity(),
                    });
                }
            }
        }
        
        snapshots
    }
    
    // --- Performance Operations ----------------------------------------------
    
    fn calculate_cache_hit_rate(&self) -> f32 {
        if self.cache.is_empty() { 1.0 } else { 0.85 } // Placeholder calculation
    }
    
    pub fn invalidate_cache(&mut self) { 
        self.cache.clear(); 
    }
    
    pub fn cache_stats(&self) -> (usize, usize) { 
        (self.cache.len(), self.cache.capacity()) 
    }
    
    pub fn cleanup_completed(&mut self) {
        self.transition_groups.retain(|_, group| {
            !group.animations.is_empty() || !group.effects.is_empty()
        });
    }
}

// --- Effect Snapshots for Rendering -----------------------------------------

#[derive(Debug, Clone)]
pub enum EffectSnapshot<T: Scalar> {
    Animation {
        id: String,
        position: Point<T, ScreenSpace>,
        rect: Option<Rect<T, ScreenSpace>>,
        progress: f32,
    },
    Effect {
        id: String,
        position: Point<T, ScreenSpace>,
        radius: T,
        color: ThemeColor,
        opacity: f32,
    },
}

// --- Effect Type Enums ------------------------------------------------------

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum FeedbackType {
    Ripple, Glow, Shake,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum InteractionType {
    Click, Hover, Focus, Error,
}

// --- Fluent Effects Configuration API ---------------------------------------

impl<T: Scalar> EffectsEngine<T> where T: From<u8> + num_traits::Zero + num_traits::One {
    pub fn new() -> Self {
        Self::default()
    }
    
    // Using derive_more::Constructor instead of fluent methods
    pub fn with_spatial_engine(mut self, engine: SpatialEngine<T>) -> Self { 
        self.spatial_engine = Some(engine); self 
    }
}

// --- Helper Trait Extensions ------------------------------------------------

trait ToF32<T> {
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

// --- Type Aliases ------------------------------------------------------------

pub type PositionTransition<T = u16> = SpatialAnimation<T>;
pub type RectTransition<T = u16> = SpatialAnimation<T>;
pub type RippleEffect<T = u16> = FeedbackEffect<T>;
pub type GlowEffect<T = u16> = FeedbackEffect<T>;

// --- Default Implementation --------------------------------------------------

impl<T: Scalar> Default for EffectsEngine<T> where T: From<u8> + num_traits::Zero + num_traits::One {
    fn default() -> Self {
        Self::new(
            FxHashMap::default(), None, StateFlags::empty(),
            FxHashMap::default(), PerformanceStats::default()
        )
    }
}