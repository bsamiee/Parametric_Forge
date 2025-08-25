// Title         : functionality/core/geometry.rs
// Author        : Bardia Samiee
// Project       : Parametric Forge
// License       : MIT
// Path          : interface/src/functionality/core/geometry.rs
// ----------------------------------------------------------------------------
//! Spatial calculation engine with type-safe coordinate systems

use derive_more::{Constructor, From, Display, Deref, DerefMut};
use getset::CopyGetters;
use bitflags::bitflags;
use num_traits::{Zero, One, Num, NumCast, ToPrimitive, Saturating};
use ahash::AHashMap;
use arrayvec::ArrayVec;
use rayon::prelude::*;
use std::ops::Range;
use std::sync::atomic::{AtomicU64, Ordering};

// --- Universal Numeric Trait -------------------------------------------------

pub trait Scalar: Num + NumCast + Copy + PartialOrd + Saturating + ToPrimitive + Send + Sync {}
impl<T> Scalar for T where T: Num + NumCast + Copy + PartialOrd + Saturating + ToPrimitive + Send + Sync {}

// --- Type-Safe Coordinate Spaces ---------------------------------------------

pub struct ScreenSpace;
pub struct LogicalSpace;
pub struct GridSpace;

// --- Spatial Flags -----------------------------------------------------------

bitflags! {
    pub struct SpatialFlags: u32 {
        // Layout algorithms
        const LINEAR     = 1 << 0;  const GRID       = 1 << 1;
        const TREE       = 1 << 2;  const VIRTUAL    = 1 << 3;
        // Movement behaviors
        const WRAP       = 1 << 4;  const CLAMP      = 1 << 5;
        const CENTER     = 1 << 6;  const SMOOTH     = 1 << 7;
        // Performance optimizations
        const CACHE      = 1 << 8;  const PREFETCH   = 1 << 9;
        const DIRTY      = 1 << 10; const SIMD       = 1 << 11;
        // Advanced features
        const BOUNDED    = Self::CLAMP.bits();
        const INFINITE   = Self::VIRTUAL.bits() | Self::WRAP.bits();
        const OPTIMIZED  = Self::CACHE.bits() | Self::PREFETCH.bits();
        const RESPONSIVE = Self::CENTER.bits() | Self::SMOOTH.bits();
    }
}

// --- Core Spatial Types ------------------------------------------------------

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Constructor, From, Display)]
#[display("({}, {})", x, y)]
pub struct Point<T: Scalar = u16, S = ScreenSpace>(pub T, pub T, std::marker::PhantomData<S>);

impl<T: Scalar, S> Point<T, S> {
    pub fn new(x: T, y: T) -> Self { Self(x, y, std::marker::PhantomData) }
    pub fn x(&self) -> T { self.0 }
    pub fn y(&self) -> T { self.1 }
    pub fn zero() -> Self where T: Zero { Self::new(T::zero(), T::zero()) }
    pub fn cast<U: Scalar>(self) -> Point<U, S> where U: NumCast {
        Point::new(U::from(self.0).unwrap(), U::from(self.1).unwrap())
    }
    pub fn to_space<NewS>(self) -> Point<T, NewS> { Point::new(self.0, self.1) }
    pub fn distance(self, other: Self) -> T { (self.0 - other.0).abs() + (self.1 - other.1).abs() }
    pub fn within(self, bounds: Rect<T, S>) -> bool { bounds.contains(self) }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Constructor, CopyGetters, Deref)]
pub struct Rect<T: Scalar = u16, S = ScreenSpace> {
    #[getset(get_copy = "pub")] #[deref]
    inner: (T, T, T, T), // (x, y, w, h)
    _space: std::marker::PhantomData<S>,
}

impl<T: Scalar, S> Rect<T, S> {
    pub fn new(x: T, y: T, w: T, h: T) -> Self { Self { inner: (x, y, w, h), _space: std::marker::PhantomData } }
    pub fn x(&self) -> T { self.inner.0 } pub fn y(&self) -> T { self.inner.1 }
    pub fn w(&self) -> T { self.inner.2 } pub fn h(&self) -> T { self.inner.3 }
    pub fn area(&self) -> T { self.w() * self.h() }
    pub fn contains(&self, p: Point<T, S>) -> bool {
        p.x() >= self.x() && p.y() >= self.y() && p.x() < self.x() + self.w() && p.y() < self.y() + self.h()
    }
    pub fn intersects(&self, other: &Self) -> bool {
        !(self.x() >= other.x() + other.w() || other.x() >= self.x() + self.w() ||
          self.y() >= other.y() + other.h() || other.y() >= self.y() + self.h())
    }
    pub fn center(&self) -> Point<T, S> where T: Num {
        Point::new(self.x() + self.w() / (T::one() + T::one()), self.y() + self.h() / (T::one() + T::one()))
    }
}

// --- Tree Navigation Support -------------------------------------------------

#[derive(Debug, Clone, Copy, Default)]
pub struct TreeNode<T: Scalar> {
    pub depth: u8,
    pub parent: Option<T>,
    pub children: ArrayVec<T, 8>, // Most tree nodes have <8 children
}

// --- Direction ---------------------------------------------------------------

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, From)]
#[repr(u8)]
pub enum Direction {
    Up = 0, Down = 1, Left = 2, Right = 3,
    PageUp = 4, PageDown = 5, Home = 6, End = 7,
}

impl Direction {
    pub fn is_vertical(self) -> bool { matches!(self, Self::Up | Self::Down | Self::PageUp | Self::PageDown) }
    pub fn is_horizontal(self) -> bool { matches!(self, Self::Left | Self::Right) }
    pub fn is_absolute(self) -> bool { matches!(self, Self::Home | Self::End) }
    pub fn delta(self) -> (isize, isize) {
        match self {
            Self::Up => (0, -1), Self::Down => (0, 1), Self::Left => (-1, 0), Self::Right => (1, 0),
            Self::PageUp => (0, -10), Self::PageDown => (0, 10), Self::Home => (isize::MIN, 0), Self::End => (isize::MAX, 0),
        }
    }
}

// --- Viewport ----------------------------------------------------------------

#[derive(Debug, Clone, Copy, Constructor, CopyGetters)]
pub struct Viewport<T: Scalar = usize> {
    #[getset(get_copy = "pub")]
    offset: T, size: T, max_items: T,
}

impl<T: Scalar> Viewport<T> where T: From<u8> + Zero + One {
    pub fn range(self) -> Range<T> { self.offset..(self.offset + self.size).min(self.max_items) }
    pub fn visible(self, index: T) -> bool { self.range().contains(&index) }
    pub fn scroll_to(mut self, index: T) -> Self {
        self.offset = if index < self.offset { index }
        else if index >= self.offset + self.size { index.saturating_sub(&(self.size - T::one())) }
        else { self.offset }; self
    }
    pub fn scroll_by(mut self, delta: isize) -> Self {
        self.offset = if delta > 0 {
            (self.offset + T::from((delta as u8).min(255))).min(self.max_items.saturating_sub(&self.size))
        } else {
            self.offset.saturating_sub(&T::from(((-delta) as u8).min(255)))
        }; self
    }
    pub fn center_on(mut self, index: T) -> Self {
        self.offset = index.saturating_sub(&(self.size / (T::one() + T::one()))); self
    }
}

// --- Performance Metrics -----------------------------------------------------

#[derive(Debug, Default)]
pub struct SpatialMetrics {
    pub batch_ops: AtomicU64,
    pub cache_hits: AtomicU64,
    pub cache_misses: AtomicU64,
    pub simd_ops: AtomicU64,
}

impl SpatialMetrics {
    pub fn cache_hit_rate(&self) -> f32 {
        let hits = self.cache_hits.load(Ordering::Relaxed) as f32;
        let misses = self.cache_misses.load(Ordering::Relaxed) as f32;
        if hits + misses == 0.0 { 0.0 } else { hits / (hits + misses) }
    }
    pub fn record_cache_hit(&self) { self.cache_hits.fetch_add(1, Ordering::Relaxed); }
    pub fn record_cache_miss(&self) { self.cache_misses.fetch_add(1, Ordering::Relaxed); }
    pub fn record_batch_op(&self) { self.batch_ops.fetch_add(1, Ordering::Relaxed); }
    pub fn record_simd_op(&self) { self.simd_ops.fetch_add(1, Ordering::Relaxed); }
}

// --- Spatial Calculation Engine (Core) --------------------------------------

/// Core spatial engine with const-generic cache optimization
#[derive(Debug, Clone)]
pub struct SpatialEngine<T: Scalar = usize, const CACHE_SIZE: usize = 128> {
    pub offset: T, pub size: T, pub max_items: T, pub columns: Option<T>, pub flags: SpatialFlags,
    cache_array: ArrayVec<(u64, T), CACHE_SIZE>,
    cache_map: AHashMap<u64, T>,
    tree_nodes: Option<Vec<TreeNode<T>>>,
    pub metrics: Option<Box<SpatialMetrics>>,
}

impl<T: Scalar, const CACHE_SIZE: usize> SpatialEngine<T, CACHE_SIZE> {
    pub fn new(offset: T, size: T, max_items: T, columns: Option<T>, flags: SpatialFlags, _ignored: ()) -> Self {
        Self { offset, size, max_items, columns, flags, cache_array: ArrayVec::new(), cache_map: AHashMap::new(), tree_nodes: None, metrics: None }
    }
}

impl<T: Scalar, const CACHE_SIZE: usize> SpatialEngine<T, CACHE_SIZE> where T: From<u8> + Zero + One + Send + Sync {
    pub fn calculate_position(&mut self, current: T, direction: Direction) -> T {
        if self.flags.contains(SpatialFlags::CACHE) {
            let key = self.cache_key(current, direction);
            if let Some((_, &val)) = self.cache_array.iter().find(|(k, _)| *k == key) {
                if let Some(ref metrics) = self.metrics { metrics.record_cache_hit(); } return val; }
            if let Some(&cached) = self.cache_map.get(&key) {
                if let Some(ref metrics) = self.metrics { metrics.record_cache_hit(); } return cached; }
            if let Some(ref metrics) = self.metrics { metrics.record_cache_miss(); }
        }
        let result = match (self.flags & (SpatialFlags::GRID | SpatialFlags::TREE | SpatialFlags::VIRTUAL)).bits() {
            x if x & SpatialFlags::GRID.bits() != 0 => self.grid_navigate(current, direction),
            x if x & SpatialFlags::TREE.bits() != 0 => self.tree_navigate(current, direction),
            x if x & SpatialFlags::VIRTUAL.bits() != 0 => self.virtual_navigate(current, direction),
            _ => self.linear_navigate(current, direction),
        }; let final_result = self.apply_constraints(result);
        if self.flags.contains(SpatialFlags::CACHE) { let key = self.cache_key(current, direction);
            if self.cache_array.len() < CACHE_SIZE { self.cache_array.push((key, final_result)); }
            else { self.cache_map.insert(key, final_result); } } final_result }

    pub fn screen_to_index(&self, point: Point<u16>, area: Rect<u16>) -> Option<T> {
        if !area.contains(point) { return None; } let (rx, ry) = ((point.x() - area.x()) as usize, (point.y() - area.y()) as usize);
        let index = match self.columns { Some(cols) => { let col_width = (area.w() as usize / cols.to_usize().unwrap()).max(1);
                ry * cols.to_usize().unwrap() + rx / col_width }, None => self.offset.to_usize().unwrap() + ry, };
        T::from(index).filter(|&idx| idx < self.max_items) }

    pub fn index_to_screen(&self, index: T, area: Rect<u16>) -> Option<Point<u16>> {
        if index >= self.max_items { return None; } let (idx_u, off_u) = (index.to_usize().unwrap(), self.offset.to_usize().unwrap());
        if idx_u < off_u { return None; } let rel_idx = idx_u - off_u;
        match self.columns { Some(cols) => { let c_u = cols.to_usize().unwrap(); let (row, col) = (rel_idx / c_u, rel_idx % c_u);
                Some(Point::new(area.x() + (col * (area.w() as usize / c_u).max(1)) as u16, area.y() + row as u16)) },
            None => Some(Point::new(area.x(), area.y() + rel_idx as u16)), } }

    // --- Navigation Algorithms -----------------------------------------------

    fn linear_navigate(&self, current: T, direction: Direction) -> T {
        let max_idx = self.max_items.saturating_sub(&T::one());
        match direction {
            Direction::Up | Direction::Left => current.saturating_sub(&T::one()),
            Direction::Down | Direction::Right => (current + T::one()).min(max_idx),
            Direction::PageUp => current.saturating_sub(&T::from(10)), Direction::PageDown => (current + T::from(10)).min(max_idx),
            Direction::Home => T::zero(), Direction::End => max_idx, } }

    fn grid_navigate(&self, current: T, direction: Direction) -> T {
        let cols = self.columns.unwrap_or_else(|| T::one()); let (row, col) = (current / cols, current % cols); let max_row = (self.max_items.saturating_sub(&T::one())) / cols;
        let wrap = self.flags.contains(SpatialFlags::WRAP); let (new_row, new_col) = match direction {
            Direction::Up => (if row > T::zero() { row - T::one() } else if wrap { max_row } else { T::zero() }, col),
            Direction::Down => { let nr = row + T::one(); (if nr * cols + col < self.max_items { nr } else if wrap { T::zero() } else { row }, col) },
            Direction::Left => (row, if col > T::zero() { col - T::one() } else if wrap && row > T::zero() { cols - T::one() } else { T::zero() }),
            Direction::Right => (row, if col + T::one() < cols && row * cols + col + T::one() < self.max_items { col + T::one() } else if wrap && row < max_row { T::zero() } else { col }),
            Direction::Home => (T::zero(), T::zero()), Direction::End => { let last = self.max_items - T::one(); (last / cols, last % cols) },
            Direction::PageUp => (row.saturating_sub(&T::from(5)), col), Direction::PageDown => ((row + T::from(5)).min(max_row), col), };
        (new_row * cols + new_col).min(self.max_items - T::one()) }

    fn tree_navigate(&self, current: T, direction: Direction) -> T {
        if let Some(ref nodes) = self.tree_nodes { if let Some(node) = nodes.get(current.to_usize().unwrap_or(0)) { match direction {
                    Direction::Up => node.parent.unwrap_or(current), Direction::Down => *node.children.first().unwrap_or(&current),
                    Direction::Left | Direction::Right => { if let Some(parent_idx) = node.parent { if let Some(parent) = nodes.get(parent_idx.to_usize().unwrap_or(0)) {
                                let curr_pos = parent.children.iter().position(|&c| c == current); if let Some(pos) = curr_pos {
                                    let new_pos = if direction == Direction::Left { pos.saturating_sub(1) } else { (pos + 1).min(parent.children.len() - 1) };
                                    parent.children[new_pos] } else { current } } else { current } } else { current } },
                    Direction::PageUp | Direction::PageDown => { let delta = if direction == Direction::PageUp { -5isize } else { 5isize };
                        let target = (current.to_isize().unwrap_or(0) + delta).max(0) as usize; T::from(target.min(self.max_items.to_usize().unwrap_or(0) - 1)).unwrap_or(current) },
                    Direction::Home => T::zero(), Direction::End => self.max_items - T::one(), } } else { self.linear_navigate(current, direction) }
        } else { self.linear_navigate(current, direction) } }

    fn virtual_navigate(&self, current: T, direction: Direction) -> T { match direction {
            Direction::Down | Direction::Right => current + T::one(), Direction::Up | Direction::Left => current.saturating_sub(&T::one()),
            _ => self.linear_navigate(current, direction), } }
    fn apply_constraints(&self, position: T) -> T { if self.flags.contains(SpatialFlags::CLAMP) { position.min(self.max_items.saturating_sub(&T::one())) } else { position } }
    fn cache_key(&self, current: T, direction: Direction) -> u64 { ((current.to_u64().unwrap_or(0) << 8) | (direction as u8 as u64)) ^ (self.flags.bits() as u64) }

    // --- Batch Operations with Parallelism ---------------------------------------
    pub fn calculate_positions(&mut self, positions: &[T], direction: Direction) -> Vec<T> { positions.iter().map(|&pos| self.calculate_position(pos, direction)).collect() }
    pub fn calculate_positions_par(&mut self, positions: &[T], direction: Direction) -> Vec<T> {
        if let Some(ref metrics) = self.metrics { metrics.record_batch_op(); } if self.flags.contains(SpatialFlags::SIMD) {
            positions.par_iter().map(|&pos| { let mut local_engine = SpatialEngine::<T, CACHE_SIZE>::new(self.offset, self.size, self.max_items, self.columns, self.flags & !SpatialFlags::CACHE, ());
                    local_engine.tree_nodes = self.tree_nodes.clone(); local_engine.calculate_position(pos, direction) }).collect() } else { self.calculate_positions(positions, direction) } }
    pub fn screen_to_indices_par(&self, points: &[Point<u16>], area: Rect<u16>) -> Vec<Option<T>> {
        if let Some(ref metrics) = self.metrics { metrics.record_batch_op(); } if self.flags.contains(SpatialFlags::SIMD) {
            points.par_iter().map(|&point| self.screen_to_index(point, area)).collect() } else { points.iter().map(|&point| self.screen_to_index(point, area)).collect() } }

    // --- SIMD Optimizations (x86_64 with AVX2) ----------------------------------
    #[cfg(all(target_arch = "x86_64", feature = "simd"))] #[target_feature(enable = "avx2")]
    unsafe fn calculate_positions_simd(&mut self, positions: &[T], direction: Direction) -> Vec<T> {
        use std::arch::x86_64::*; if let Some(ref metrics) = self.metrics { metrics.record_simd_op(); }
        let mut results = Vec::with_capacity(positions.len()); let chunks = positions.chunks_exact(4); let remainder = chunks.remainder();
        for chunk in chunks { for &pos in chunk { results.push(self.calculate_position(pos, direction)); } }
        for &pos in remainder { results.push(self.calculate_position(pos, direction)); } results }
    pub fn invalidate_cache(&mut self) { self.cache_array.clear(); self.cache_map.clear(); }
    pub fn cache_stats(&self) -> (usize, usize, usize) { (self.cache_array.len(), self.cache_map.len(), CACHE_SIZE) }
    pub fn set_tree_nodes(&mut self, nodes: Vec<TreeNode<T>>) { self.tree_nodes = Some(nodes); self.flags |= SpatialFlags::TREE; }
}

// --- Fluent Configuration API ------------------------------------------------
impl<T: Scalar, const CACHE_SIZE: usize> SpatialEngine<T, CACHE_SIZE> where T: From<u8> + Zero + One + Send + Sync {
    pub fn linear() -> Self { Self::new(T::zero(), T::from(10), T::zero(), None, SpatialFlags::LINEAR | SpatialFlags::CLAMP, ()) }
    pub fn grid(cols: T) -> Self { Self::new(T::zero(), T::from(10), T::zero(), Some(cols), SpatialFlags::GRID | SpatialFlags::CLAMP, ()) }
    pub fn virtual_content() -> Self { Self::new(T::zero(), T::from(10), T::from(u8::MAX), None, SpatialFlags::VIRTUAL, ()) }
    pub fn with_wrapping(mut self) -> Self { self.flags |= SpatialFlags::WRAP; self } pub fn with_caching(mut self) -> Self { self.flags |= SpatialFlags::CACHE; self }
    pub fn with_centering(mut self) -> Self { self.flags |= SpatialFlags::CENTER; self } pub fn optimized(mut self) -> Self { self.flags |= SpatialFlags::OPTIMIZED; self }
    pub fn responsive(mut self) -> Self { self.flags |= SpatialFlags::RESPONSIVE; self } }

// --- SIMD Word Boundary Detection -------------------------------------------

/// Find word boundaries using SIMD instructions for performance (x86_64 only)
#[cfg(target_arch = "x86_64")]
pub fn find_word_boundaries_simd(text: &str) -> ArrayVec<usize, 128> {
    use std::arch::x86_64::*;
    let mut boundaries = ArrayVec::new();
    let bytes = text.as_bytes();

    unsafe {
        let space = _mm_set1_epi8(b' ' as i8);
        let mut i = 0;

        while i + 16 <= bytes.len() && !boundaries.is_full() {
            let chunk = _mm_loadu_si128(bytes[i..].as_ptr() as *const __m128i);
            let mask = _mm_movemask_epi8(_mm_cmpeq_epi8(chunk, space)) as u16;

            for bit in 0..16 {
                if mask & (1 << bit) != 0 && !boundaries.is_full() { 
                    boundaries.push(i + bit); 
                }
            }
            i += 16;
        }

        // Handle remaining bytes
        for (idx, &b) in bytes[i..].iter().enumerate() {
            if b == b' ' && !boundaries.is_full() { 
                boundaries.push(i + idx); 
            }
        }
    }
    boundaries
}

/// Fallback word boundary detection for non-x86_64 architectures
#[cfg(not(target_arch = "x86_64"))]
pub fn find_word_boundaries_simd(text: &str) -> ArrayVec<usize, 128> {
    let mut boundaries = ArrayVec::new();
    for (i, ch) in text.char_indices() {
        if ch.is_whitespace() && !boundaries.is_full() { 
            boundaries.push(i); 
        }
    }
    boundaries
}

// --- Type Aliases ------------------------------------------------------------

pub type ScreenPoint = Point<u16, ScreenSpace>;
pub type ScreenRect = Rect<u16, ScreenSpace>;
pub type LogicalPoint = Point<usize, LogicalSpace>;
pub type LogicalRect = Rect<usize, LogicalSpace>;
pub type GridPoint = Point<usize, GridSpace>;

impl<T: Scalar> Default for SpatialEngine<T> where T: From<u8> + Zero + One { fn default() -> Self { Self::linear() } }