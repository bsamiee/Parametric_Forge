// Title         : functionality/layout/constraints.rs
// Author        : Bardia Samiee
// Project       : Parametric Forge
// License       : MIT
// Path          : interface/src/functionality/layout/constraints.rs
// ----------------------------------------------------------------------------
//! Kurbo-backed constraint resolution with ConstraintSpace coordinates

use super::{
    LayoutBehavior, LayoutResult, LayoutFlags, ConstraintSpace,
    SpatialEngine, SpatialFlags, ScreenRect, Direction, Scalar, ComponentId
};
use arrayvec::ArrayVec;
use bitflags::bitflags;
use euclid::Size2D;
use kurbo::Rect;
use num_traits::{ToPrimitive, Zero, One};
use std::hash::{Hash, Hasher};

bitflags! {
    #[derive(Clone, Copy, Debug)]
    pub struct ConstraintFlags: u16 {
        const FIXED = 1; const FLEX = 2; const GRID = 4; const PROPORTIONAL = 8;
        const MIN_SIZE = 16; const MAX_SIZE = 32; const ASPECT = 64; const WEIGHTED = 128;
        const ADAPTIVE = Self::FLEX.bits() | Self::PROPORTIONAL.bits();
        const BOUNDED = Self::MIN_SIZE.bits() | Self::MAX_SIZE.bits();
    }
}

#[derive(Debug, Clone)]
pub enum ConstraintBehavior<T: Scalar = u16> {
    Fixed { sizes: ArrayVec<T, 8>, direction: Direction, flags: ConstraintFlags },
    Flex { items: ArrayVec<FlexItem<T>, 8>, direction: Direction, flags: ConstraintFlags },
    Grid { dimensions: (u8, u8), cells: ArrayVec<GridCell<T>, 16>, flags: ConstraintFlags },
}

#[derive(Debug, Clone, Copy)]
pub struct FlexItem<T: Scalar> { pub min: T, pub weight: u8, pub priority: u8 }
#[derive(Debug, Clone, Copy)]
pub struct GridCell<T: Scalar> { pub pos: (u8, u8), pub span: (u8, u8), pub item: FlexItem<T>, pub id: ComponentId }

// --- Constraint Resolution --------------------------------------------------

impl<T: Scalar> ConstraintBehavior<T> where T: From<u8> + ToPrimitive + Zero + One + Send + Sync {
    pub fn fixed(sizes: ArrayVec<T, 8>, direction: Direction) -> Self {
        Self::Fixed { sizes, direction, flags: ConstraintFlags::FIXED }
    }
    pub fn flex(items: ArrayVec<FlexItem<T>, 8>, direction: Direction) -> Self {
        Self::Flex { items, direction, flags: ConstraintFlags::ADAPTIVE }
    }
    pub fn grid(dimensions: (u8, u8), cells: ArrayVec<GridCell<T>, 16>) -> Self {
        Self::Grid { dimensions, cells, flags: ConstraintFlags::GRID | ConstraintFlags::FLEX }
    }
}

// --- LayoutBehavior Implementation ---------------------------------------
impl<T: Scalar> LayoutBehavior<T> for ConstraintBehavior<T> where T: From<u8> + ToPrimitive + Zero + One + Send + Sync {
    type Result = LayoutResult<T>; type Config = ScreenRect;

    fn calculate(&self, _: &Self::Config, bounds: kurbo::Rect) -> Self::Result {
        let mut result = LayoutResult::default();
        result.viewport = bounds;
        match self {
            Self::Fixed { sizes, .. } => {
                for i in 0..sizes.len() { result.visible.push(ComponentId(i as u32)); }
            },
            Self::Flex { items, direction, .. } => {
                let total: u16 = items.iter().map(|i| i.weight as u16).sum();
                let avail = if direction.is_horizontal() { bounds.width() } else { bounds.height() };
                for i in 0..items.len() { result.visible.push(ComponentId(i as u32)); }
            },
            Self::Grid { cells, .. } => {
                for cell in cells { result.visible.push(cell.id); }
            },
        }
        result
    }

    fn flags(&self) -> LayoutFlags {
        match self {
            Self::Fixed { .. } => LayoutFlags::FIXED | LayoutFlags::LINEAR,
            Self::Flex { .. } => LayoutFlags::FLEX | LayoutFlags::RESPONSIVE,
            Self::Grid { .. } => LayoutFlags::GRID | LayoutFlags::RESPONSIVE,
        }
    }

    fn cache_key(&self, c: &Self::Config, b: kurbo::Rect) -> u64 {
        let mut h = ahash::AHasher::default();
        (c.x(), c.y(), c.w(), c.h(), b.x0 as u64, b.width() as u64).hash(&mut h);
        match self {
            Self::Fixed { sizes, direction, flags } => (sizes.len(), *direction as u8, flags.bits()).hash(&mut h),
            Self::Flex { items, direction, flags } => (items.len(), *direction as u8, flags.bits()).hash(&mut h),
            Self::Grid { dimensions, cells, flags } => (dimensions, cells.len(), flags.bits()).hash(&mut h),
        } h.finish()
    }
}

// --- Helpers -----------------------------------------------------------------

impl<T: Scalar> FlexItem<T> where T: From<u8> {
    pub fn new(min: T, weight: u8) -> Self { Self { min, weight, priority: 128 } }
}
impl<T: Scalar> GridCell<T> where T: From<u8> {
    pub fn new(pos: (u8, u8), span: (u8, u8), item: FlexItem<T>, id: ComponentId) -> Self { Self { pos, span, item, id } }
}