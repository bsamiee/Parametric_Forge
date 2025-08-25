// Title         : functionality/layout/responsive.rs
// Author        : Bardia Samiee
// Project       : Parametric Forge
// License       : MIT
// Path          : interface/src/functionality/layout/responsive.rs
// ----------------------------------------------------------------------------
//! Responsive layout with euclid spaces, kurbo geometry, spatial delegation

use super::{LayoutBehavior, LayoutResult, LayoutFlags, LayoutNode, ComponentId, ResponsiveSpace, ScreenSpace};
use super::super::core::geometry::{SpatialEngine, SpatialFlags, ScreenRect, Scalar};
use arrayvec::ArrayVec;
use smallvec::SmallVec;
use euclid::{Size2D, Transform3D, Rect};
use kurbo::Rect as KRect;
use rayon::prelude::*;
use num_traits::ToPrimitive;
use std::hash::{Hash, Hasher};

// --- Viewport Classification ---------------------------------------------
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Hash)]
#[repr(u8)]
pub enum ViewportSize { Minimal = 0, Small = 1, Medium = 2, Large = 3, XLarge = 4, Ultra = 5 }

impl ViewportSize {
    pub fn from_rect(r: Rect<u16, ResponsiveSpace>) -> Self {
        match (r.size.width, r.size.height) {
            (w, h) if w < 40 || h < 10 => Self::Minimal, (w, h) if w < 80 || h < 24 => Self::Small,
            (w, h) if w < 120 || h < 40 => Self::Medium, (w, h) if w < 160 || h < 50 => Self::Large,
            (w, h) if w >= 240 && h >= 80 => Self::Ultra, _ => Self::XLarge,
        }
    }
    pub const fn margin(self) -> u16 { [0, 1, 2, 2, 3, 3][self as usize] }
    pub const fn spacing(self) -> u16 { [0, 1, 2, 3, 3, 4][self as usize] }
}

// --- Responsive Configuration & Component --------------------------------
#[derive(Debug, Clone, Copy)]
pub struct ResponsiveConfig<T: Scalar = u16> {
    pub min: Size2D<T, ResponsiveSpace>, pub priority: u8,
}

impl<T: Scalar> ResponsiveConfig<T> where T: From<u8> {
    pub fn new(w: T, h: T) -> Self { Self { min: Size2D::new(w, h), priority: 128 } }
    pub fn with_priority(mut self, p: u8) -> Self { self.priority = p; self }
    pub fn effective_size(&self, v: ViewportSize) -> Size2D<T, ResponsiveSpace> {
        let s = v as u8 as f32 / 3.0;
        Size2D::new(T::from((self.min.width.to_f32().unwrap_or(0.0) * s) as u8), T::from((self.min.height.to_f32().unwrap_or(0.0) * s) as u8))
    }
    pub fn should_show(&self, v: ViewportSize) -> bool { v != ViewportSize::Minimal || self.priority > 64 }
}

#[derive(Debug, Clone, Copy)]
pub struct ResponsiveComponent<T: Scalar = u16> {
    pub id: ComponentId, pub config: ResponsiveConfig<T>, pub transform: Transform3D<f32, ResponsiveSpace, ScreenSpace>,
}

impl<T: Scalar> ResponsiveComponent<T> where T: From<u8> {
    pub fn new(id: ComponentId, cfg: ResponsiveConfig<T>) -> Self { Self { id, config: cfg, transform: Transform3D::identity() } }
}

// --- Responsive Behavior Variants ---------------------------------------
#[derive(Debug, Clone)]
pub enum ResponsiveBehavior<T: Scalar = u16> {
    Adaptive { components: ArrayVec<ResponsiveComponent<T>, 8> },
    Breakpoint { components: ArrayVec<ResponsiveComponent<T>, 8>, breakpoints: [ViewportSize; 3] },
    Priority { components: SmallVec<[ResponsiveComponent<T>; 16]> },
    ContentAware { components: ArrayVec<ResponsiveComponent<T>, 8>, bounds: Rect<u16, ResponsiveSpace> },
}

impl<T: Scalar> ResponsiveBehavior<T> where T: From<u8> + ToPrimitive + Send + Sync {
    pub fn adaptive(components: ArrayVec<ResponsiveComponent<T>, 8>) -> Self { Self::Adaptive { components } }
    pub fn breakpoint(components: ArrayVec<ResponsiveComponent<T>, 8>, breakpoints: [ViewportSize; 3]) -> Self { Self::Breakpoint { components, breakpoints } }
    pub fn priority(components: SmallVec<[ResponsiveComponent<T>; 16]>) -> Self { Self::Priority { components } }
    pub fn content_aware(components: ArrayVec<ResponsiveComponent<T>, 8>, bounds: Rect<u16, ResponsiveSpace>) -> Self { Self::ContentAware { components, bounds } }
}

// --- Responsive Layout Implementation --------------------------------------

impl<T: Scalar> ResponsiveBehavior<T> where T: From<u8> + ToPrimitive + Send + Sync {
    pub fn calculate_with_engine(&self, engine: &mut SpatialEngine<T>, bounds: KRect) -> LayoutResult<T> {
        let viewport_rect = Rect::new(euclid::Point2D::new(bounds.x0 as u16, bounds.y0 as u16), Size2D::new((bounds.width()) as u16, (bounds.height()) as u16));
        let viewport = ViewportSize::from_rect(viewport_rect);
        match self {
            Self::Adaptive { components } => Self::layout_adaptive(viewport_rect, viewport, components),
            Self::Breakpoint { components, breakpoints } => Self::layout_breakpoint(viewport_rect, viewport, components, breakpoints),
            Self::Priority { components } => Self::layout_priority(engine, viewport_rect, viewport, components),
            Self::ContentAware { components, bounds } => Self::layout_content_aware(viewport_rect, viewport, components, *bounds),
        }
    }

    fn layout_adaptive(r: Rect<u16, ResponsiveSpace>, v: ViewportSize, cs: &[ResponsiveComponent<T>]) -> LayoutResult<T> {
        let mut res = LayoutResult::default(); let m = v.margin(); let cr = r.inflate(-m as i16, -m as i16);
        for c in cs.iter().filter(|c| c.config.should_show(v)) {
            let s = c.config.effective_size(v);
            if cr.size.width >= s.width && cr.size.height >= s.height {
                res.nodes.push(LayoutNode::new(c.id, s).with_flags(LayoutFlags::RESPONSIVE));
            }
        }
        res.viewport = KRect::new(r.origin.x as f64, r.origin.y as f64, (r.origin.x + r.size.width) as f64, (r.origin.y + r.size.height) as f64); res
    }

    fn layout_breakpoint(r: Rect<u16, ResponsiveSpace>, v: ViewportSize, cs: &[ResponsiveComponent<T>], _: &[ViewportSize; 3]) -> LayoutResult<T> {
        let mut res = LayoutResult::default(); let m = v.margin(); let sp = v.spacing(); let cr = r.inflate(-m as i16, -m as i16); let mut y = 0u16;
        for c in cs.iter().filter(|c| c.config.should_show(v)) {
            let s = c.config.effective_size(v);
            if y + s.height <= cr.size.height {
                res.nodes.push(LayoutNode::new(c.id, s).with_flags(LayoutFlags::LINEAR)); y += s.height + sp;
            } else { res.overflow = true; break; }
        }
        res.viewport = KRect::new(r.origin.x as f64, r.origin.y as f64, (r.origin.x + r.size.width) as f64, (r.origin.y + r.size.height) as f64); res
    }

    fn layout_priority(e: &mut SpatialEngine<T>, r: Rect<u16, ResponsiveSpace>, v: ViewportSize, cs: &[ResponsiveComponent<T>]) -> LayoutResult<T> {
        let mut sorted: SmallVec<[_; 16]> = cs.iter().collect();
        if cs.len() > 8 && e.flags.contains(SpatialFlags::PARALLEL) { sorted.par_sort_by_key(|c| std::cmp::Reverse(c.config.priority)); } else { sorted.sort_by_key(|c| std::cmp::Reverse(c.config.priority)); }
        let mut res = LayoutResult::default(); let m = v.margin(); let mut av = r.inflate(-m as i16, -m as i16);
        for c in sorted.iter().filter(|c| c.config.should_show(v)) {
            let s = c.config.effective_size(v);
            if av.size.width >= s.width && av.size.height >= s.height {
                res.nodes.push(LayoutNode::new(c.id, s).with_flags(LayoutFlags::RESPONSIVE));
                av.origin.y += s.height; av.size.height = av.size.height.saturating_sub(s.height);
            } else { res.overflow = true; break; }
        }
        res.viewport = KRect::new(r.origin.x as f64, r.origin.y as f64, (r.origin.x + r.size.width) as f64, (r.origin.y + r.size.height) as f64); res
    }

    fn layout_content_aware(r: Rect<u16, ResponsiveSpace>, v: ViewportSize, cs: &[ResponsiveComponent<T>], cb: Rect<u16, ResponsiveSpace>) -> LayoutResult<T> {
        Self::layout_adaptive(r.intersection(&cb).unwrap_or(r), v, cs)
    }
}

// --- LayoutBehavior Implementation ---------------------------------------
impl<T: Scalar> LayoutBehavior<T> for ResponsiveBehavior<T> where T: From<u8> + ToPrimitive + Send + Sync {
    type Result = LayoutResult<T>; type Config = KRect;
    fn calculate(&self, config: &Self::Config, _: KRect) -> Self::Result {
        // Requires external engine - use ResponsiveEngine::calculate instead
        LayoutResult::default()
    }
    fn flags(&self) -> LayoutFlags {
        match self {
            Self::Adaptive { .. } => LayoutFlags::RESPONSIVE | LayoutFlags::CENTER,
            Self::Breakpoint { .. } => LayoutFlags::RESPONSIVE | LayoutFlags::LINEAR,
            Self::Priority { .. } => LayoutFlags::RESPONSIVE | LayoutFlags::PARALLEL,
            Self::ContentAware { .. } => LayoutFlags::RESPONSIVE | LayoutFlags::BOUNDED,
        }
    }
    fn cache_key(&self, c: &Self::Config, _: KRect) -> u64 {
        let mut h = ahash::AHasher::default();
        (c.x0 as u64, c.width() as u64).hash(&mut h);
        match self {
            Self::Adaptive { components } => components.len().hash(&mut h),
            Self::Breakpoint { components, breakpoints } => (components.len(), *breakpoints).hash(&mut h),
            Self::Priority { components } => components.len().hash(&mut h),
            Self::ContentAware { components, bounds } => (components.len(), *bounds).hash(&mut h),
        } h.finish()
    }
}