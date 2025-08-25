// Title         : functionality/layout/positioning.rs
// Author        : Bardia Samiee
// Project       : Parametric Forge
// License       : MIT
// Path          : interface/src/functionality/layout/positioning.rs
// ----------------------------------------------------------------------------
//! Zero-duplication positioning with euclid transforms and kurbo geometry

use super::{LayoutBehavior, LayoutResult, LayoutFlags, ComponentId, SpatialEngine, ScreenSpace};
use super::super::core::geometry::{SpatialFlags, ScreenRect, Direction, Scalar};
use arrayvec::ArrayVec;
use derive_more::Constructor;
use delegate::delegate;
use euclid::{Transform3D, Size2D, Point2D};
use kurbo::{Rect as KRect, Point2, Vec2, Affine};
use std::hash::{Hash, Hasher};
use num_traits::{ToPrimitive, Zero};

// --- Core Position Types -----------------------------------------------------
pub type PositionTransform<T> = Transform3D<f32, super::ResponsiveSpace, ScreenSpace>;
pub type ResponsiveSize<T> = Size2D<T, super::ResponsiveSpace>;
#[derive(Debug, Clone, Copy, Constructor)]
pub struct PositionSpec<T: Scalar> {
    pub bounds: ResponsiveSize<T>, pub offset: Vec2, pub transform: PositionTransform<T>,
}
#[derive(Debug, Constructor)]
pub struct PositionedComponent<T: Scalar> {
    pub id: ComponentId, pub spec: PositionSpec<T>, pub transform: PositionTransform<T>, pub z_order: u8,
}

// --- Position Behaviors ------------------------------------------------------
#[derive(Debug, Clone)]
pub enum PositionBehavior<T: Scalar = u16> {
    Fixed { components: ArrayVec<PositionedComponent<T>, 8> },
    Aligned { components: ArrayVec<PositionedComponent<T>, 8>, anchor: Point2 },
    Anchored { components: ArrayVec<PositionedComponent<T>, 8>, affine: Affine },
    Floating { base: ArrayVec<PositionedComponent<T>, 4>, overlays: ArrayVec<PositionedComponent<T>, 8> },
}

// --- PositionEngine ----------------------------------------------------------
#[derive(Debug)]
pub struct PositionEngine<T: Scalar = u16, const CACHE: usize = 32> { spatial: SpatialEngine<T, CACHE> }

impl<T: Scalar, const CACHE: usize> PositionEngine<T, CACHE> where T: From<u8> + ToPrimitive + Send + Sync + Zero {
    pub fn new(spatial: SpatialEngine<T, CACHE>) -> Self { Self { spatial } }

    fn calculate_position(&self, b: &PositionBehavior<T>, bounds: KRect) -> LayoutResult<T> {
        match b {
            PositionBehavior::Fixed { components } => self.position_fixed(components, bounds),
            PositionBehavior::Aligned { components, anchor } => self.position_aligned(components, bounds, *anchor),
            PositionBehavior::Anchored { components, affine } => self.position_anchored(components, bounds, *affine),
            PositionBehavior::Floating { base, overlays } => self.position_floating(base, overlays, bounds),
        }
    }

    fn position_components(&self, components: &[PositionedComponent<T>], bounds: KRect, transform_fn: impl Fn(&PositionedComponent<T>, usize) -> (PositionTransform<T>, LayoutFlags)) -> LayoutResult<T> {
        let (nodes, visible): (Vec<_>, Vec<_>) = components.iter().enumerate()
            .map(|(i, c)| {
                let (transform, flags) = transform_fn(c, i);
                let mut node = super::LayoutNode::new(c.id, c.spec.bounds).with_flags(flags);
                node.transform = transform;
                (node, c.id)
            }).unzip();
        LayoutResult { nodes: nodes.into(), visible: visible.into(), viewport: bounds, overflow: false }
    }

    fn position_fixed(&self, components: &[PositionedComponent<T>], bounds: KRect) -> LayoutResult<T> {
        self.position_components(components, bounds, |c, _| (c.transform, LayoutFlags::FIXED))
    }

    fn position_aligned(&self, components: &[PositionedComponent<T>], bounds: KRect, anchor: Point2) -> LayoutResult<T> {
        let off = Vec2::new(anchor.x - bounds.center().x, anchor.y - bounds.center().y);
        self.position_components(components, bounds, |_, _| (PositionTransform::translation(off.x as f32, off.y as f32, 0.0), LayoutFlags::CENTER))
    }

    fn position_anchored(&self, components: &[PositionedComponent<T>], bounds: KRect, affine: Affine) -> LayoutResult<T> {
        self.position_components(components, bounds, |c, _| {
            let p = affine * Point2::new(0.0, 0.0);
            (PositionTransform::translation(p.x as f32, p.y as f32, c.z_order as f32), LayoutFlags::FIXED)
        })
    }

    fn position_floating(&self, base: &[PositionedComponent<T>], overlays: &[PositionedComponent<T>], bounds: KRect) -> LayoutResult<T> {
        let mut r = if !base.is_empty() {
            let h = bounds.height() / base.len() as f64;
            self.position_components(base, bounds, |_, i| (PositionTransform::translation(bounds.x0 as f32, (bounds.y0 + i as f64 * h) as f32, 0.0), LayoutFlags::RESPONSIVE))
        } else { LayoutResult { nodes: smallvec::SmallVec::new(), visible: smallvec::SmallVec::new(), viewport: bounds, overflow: false } };
        let o = self.position_components(overlays, bounds, |c, _| (c.transform, LayoutFlags::empty()));
        r.nodes.extend(o.nodes); r.visible.extend(o.visible); r
    }
}

// --- LayoutBehavior Implementation -----------------------------------

impl<T: Scalar> LayoutBehavior<T> for PositionBehavior<T> where T: From<u8> + ToPrimitive + Send + Sync + Zero {
    type Result = LayoutResult<T>;
    type Config = KRect;

    fn calculate(&self, config: &Self::Config, _: KRect) -> Self::Result {
        let engine = PositionEngine::new(SpatialEngine::new(T::zero(), T::from(100), T::from(1000), None, SpatialFlags::CACHE, ()));
        engine.calculate_position(self, *config)
    }

    fn flags(&self) -> LayoutFlags {
        match self {
            Self::Fixed { .. } => LayoutFlags::FIXED,
            Self::Aligned { .. } => LayoutFlags::CENTER | LayoutFlags::RESPONSIVE,
            Self::Anchored { .. } => LayoutFlags::FIXED | LayoutFlags::BOUNDED,
            Self::Floating { .. } => LayoutFlags::RESPONSIVE | LayoutFlags::FLEX,
        }
    }

    fn cache_key(&self, config: &Self::Config, bounds: KRect) -> u64 {
        let mut hasher = ahash::AHasher::default();
        (config.x0 as u64, config.y0 as u64, bounds.width() as u64, bounds.height() as u64).hash(&mut hasher);
        match self {
            Self::Fixed { components } => (0u8, components.len()).hash(&mut hasher),
            Self::Aligned { components, .. } => (1u8, components.len()).hash(&mut hasher),
            Self::Anchored { components, .. } => (2u8, components.len()).hash(&mut hasher),
            Self::Floating { base, overlays } => (3u8, base.len(), overlays.len()).hash(&mut hasher),
        }
        hasher.finish()
    }
}

// --- Spatial Engine Delegation ------------------------------------------
impl<T: Scalar, const CACHE: usize> PositionEngine<T, CACHE> where T: From<u8> + ToPrimitive + Send + Sync + Zero {
    pub fn spatial_engine(&mut self) -> &mut SpatialEngine<T, CACHE> { &mut self.spatial }
}

// --- Defaults ----------------------------------------------------------------
impl<T: Scalar> Default for PositionSpec<T> where T: From<u8> + Zero {
    fn default() -> Self { Self::new(Size2D::new(T::zero(), T::zero()), Vec2::ZERO, Transform3D::identity()) }
}