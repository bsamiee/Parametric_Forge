// Title         : functionality/visual/animation.rs
// Author        : Bardia Samiee
// Project       : Parametric Forge
// License       : MIT
// Path          : interface/src/functionality/visual/animation.rs
// ----------------------------------------------------------------------------
//! Universal animation system

use std::time::{Duration, Instant};

pub type EasingFn = fn(f32) -> f32;

#[derive(Debug, Clone)]
pub struct Animator {
    pub duration: Duration,
    pub easing: EasingFn,
    pub state: AnimationState,
}

#[derive(Debug, Clone)]
pub enum AnimationState {
    Idle,
    Running { start: Instant, from: f32, to: f32 },
}

impl Animator {
    pub fn new(duration: Duration, easing: EasingFn) -> Self {
        Self { duration, easing, state: AnimationState::Idle }
    }

    pub fn start(&mut self, from: f32, to: f32) {
        self.state = AnimationState::Running { start: Instant::now(), from, to };
    }

    pub fn current_value(&self) -> Option<f32> {
        match &self.state {
            AnimationState::Idle => None,
            AnimationState::Running { start, from, to } => {
                let elapsed = start.elapsed();
                if elapsed >= self.duration {
                    Some(*to)
                } else {
                    let progress = elapsed.as_secs_f32() / self.duration.as_secs_f32();
                    Some(from + (to - from) * (self.easing)(progress))
                }
            }
        }
    }
}

// Standard easing functions
pub mod easing {
    use super::EasingFn;
    
    pub const LINEAR: EasingFn = |t| t;
    pub const EASE_OUT: EasingFn = |t| 1.0 - (1.0 - t).powi(2);
    pub const EASE_IN_OUT: EasingFn = |t| if t < 0.5 { 2.0 * t * t } else { 1.0 - (-2.0 * t + 2.0).powi(2) / 2.0 };
}