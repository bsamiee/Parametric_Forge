// Title         : functionality/layout/mod.rs
// Author        : Bardia Samiee
// Project       : Parametric Forge
// License       : MIT
// Path          : interface/src/functionality/layout/mod.rs
// ----------------------------------------------------------------------------
//! Trait-based layout system with euclid spaces, kurbo geometry, and zero-cost composition

use super::core::geometry::{SpatialEngine, SpatialFlags, ScreenRect, Direction, Scalar, TreeNode};
use super::core::state::ComponentId;
use arrayvec::ArrayVec;
use smallvec::SmallVec;
use bitflags::bitflags;
use delegate::delegate;
use euclid::{Transform3D, Size2D};
use kurbo::Rect as KRect;
use num_traits::{ToPrimitive, Zero, One};
use std::marker::PhantomData;

// --- Type-Safe Layout Spaces ------------------------------------------------
pub struct LayoutSpace; pub struct ConstraintSpace; pub struct ResponsiveSpace; pub struct ScreenSpace;
// --- Compact Layout State ----------------------------------------------------
bitflags! {
    #[derive(Clone, Copy, Debug, PartialEq, Eq)]
    pub struct LayoutFlags: u16 {
        const FIXED = 1 << 0; const LINEAR = 1 << 1; const GRID = 1 << 2; const FLEX = 1 << 3; const RESPONSIVE = 1 << 4;
        const WRAP = 1 << 5; const CENTER = 1 << 6; const STRETCH = 1 << 7; const CACHE = 1 << 8; const PARALLEL = 1 << 9;
        const BOUNDED = Self::WRAP.bits(); const OPTIMIZED = Self::CACHE.bits() | Self::PARALLEL.bits();
    }
}

// --- Core Layout Traits -----------------------------------------------------
pub trait LayoutBehavior<T: Scalar> {
    type Result; type Config;
    fn calculate(&self, config: &Self::Config, bounds: KRect) -> Self::Result;
    fn flags(&self) -> LayoutFlags;
    fn cache_key(&self, config: &Self::Config, bounds: KRect) -> u64;
}


// --- Layout Implementations -------------------------------------------------
#[derive(Debug, Clone)]
pub struct LayoutNode<T: Scalar, S = LayoutSpace> {
    pub id: ComponentId, pub transform: Transform3D<f32, S, ScreenSpace>, pub size: Size2D<T, S>,
    pub flags: LayoutFlags, pub children: ArrayVec<LayoutNode<T, S>, 16>, _space: PhantomData<S>,
}
impl<T: Scalar, S> LayoutNode<T, S> {
    pub fn new(id: ComponentId, size: Size2D<T, S>) -> Self {
        Self { id, transform: Transform3D::identity(), size, flags: LayoutFlags::empty(), children: ArrayVec::new(), _space: PhantomData }
    }
    pub fn with_flags(mut self, flags: LayoutFlags) -> Self { self.flags = flags; self }
}

// --- Geometry-Backed Layout Engine ------------------------------------------
#[derive(Debug)]
pub struct LayoutEngine<T: Scalar = u16, const CACHE: usize = 64> {
    spatial: SpatialEngine<T, CACHE>, flags: LayoutFlags,
}

#[derive(Debug, Clone)]
pub struct LayoutResult<T: Scalar = u16> {
    pub nodes: SmallVec<[LayoutNode<T>; 16]>, pub visible: SmallVec<[ComponentId; 16]>,
    pub viewport: KRect, pub overflow: bool,
}


// --- Concrete Layout Types --------------------------------------------------
#[derive(Debug, Clone, Default)]
pub struct LinearLayout<T: Scalar> { pub direction: Direction, pub spacing: T, pub items: SmallVec<[T; 16]> }

// --- Core Implementation -----------------------------------------------------

impl<T: Scalar> LayoutBehavior<T> for LinearLayout<T> where T: ToPrimitive + From<u8> + Zero + One {
    type Result = LayoutResult<T>; type Config = KRect;
    fn flags(&self) -> LayoutFlags { LayoutFlags::LINEAR }
    fn cache_key(&self, _: &Self::Config, b: KRect) -> u64 {
        use std::hash::{Hash, Hasher}; let mut h = ahash::AHasher::default();
        (self.direction as u8, self.spacing.to_u64().unwrap_or(0), b.x0 as u64, b.width() as u64).hash(&mut h); h.finish()
    }
    fn calculate(&self, b: &Self::Config, _: KRect) -> Self::Result {
        let mut n = SmallVec::new(); let mut v = SmallVec::new();
        let sz = if self.direction.is_vertical() { b.height() / self.items.len() as f64 } else { b.width() / self.items.len() as f64 };
        for i in 0..self.items.len() {
            let id = ComponentId(i as u32);
            let s = if self.direction.is_vertical() { Size2D::new(T::from(b.width() as u8), T::from(sz as u8)) } else { Size2D::new(T::from(sz as u8), T::from(b.height() as u8)) };
            n.push(LayoutNode::new(id, s)); v.push(id);
        }
        LayoutResult { nodes: n, visible: v, viewport: *b, overflow: false }
    }
}

// --- Engine Implementation --------------------------------------------------

impl<T: Scalar, const CACHE: usize> LayoutEngine<T, CACHE> where T: From<u8> + Zero + One + Send + Sync + ToPrimitive {
    pub fn new(spatial: SpatialEngine<T, CACHE>) -> Self { Self { spatial, flags: LayoutFlags::CACHE | LayoutFlags::PARALLEL } }
    pub fn calculate<L: LayoutBehavior<T>>(&mut self, layout: &L, bounds: KRect) -> L::Result { layout.calculate(&bounds, bounds) }
    pub fn spatial_engine(&mut self) -> &mut SpatialEngine<T, CACHE> { &mut self.spatial }
    delegate! { to self.spatial { 
        pub fn set_tree_nodes(&mut self, nodes: Vec<TreeNode<T>>);
        pub fn calculate_position(&mut self, current: T, direction: Direction) -> T;
        pub fn screen_to_index(&self, point: super::core::geometry::Point<u16>, area: ScreenRect) -> Option<T>;
        pub fn invalidate_cache(&mut self);
    } }
}

// --- Defaults ----------------------------------------------------------------

impl<T: Scalar> Default for LayoutResult<T> {
    fn default() -> Self { Self { nodes: SmallVec::new(), visible: SmallVec::new(), viewport: KRect::ZERO, overflow: false } }
}