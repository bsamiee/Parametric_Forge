// Title         : functionality/visual/icons.rs
// Author        : Bardia Samiee
// Project       : Parametric Forge
// License       : MIT
// Path          : interface/src/functionality/visual/icons.rs
// ----------------------------------------------------------------------------
//! Nerd Font icon system with spatial positioning and type safety

use derive_more::{Constructor, From, Display, Deref};
use getset::CopyGetters;
use bitflags::bitflags;
use rustc_hash::FxHashMap;
use compact_str::CompactString;
use std::fmt;
use crate::functionality::core::{geometry::{Point, Rect, ScreenSpace, SpatialEngine, Scalar}, state::StateFlags};
use super::theming::{ThemeEngine, ThemeColor};

// --- Using Core Coordinate Spaces -------------------------------------------
// Eliminated: IconSpace, GlyphSpace, SymbolSpace
// Using: ScreenSpace, LogicalSpace, GridSpace from core::geometry

// --- Icon Category Flags -----------------------------------------------------
// Using core::state::StateFlags + specialized icon flags
bitflags! {
    pub struct IconCategory: u8 {
        const FILE = 1; const FOLDER = 2; const DEVICE = 4; const NETWORK = 8;
        const STATUS = 16; const ACTION = 32; const UI = 64; const SYMBOL = 128;
    }
}

// --- Icon Definition with Type Safety ---------------------------------------

#[derive(Debug, Clone, PartialEq, Eq, Hash, Constructor)]
pub struct Icon {
    pub glyph: char,
    pub name: CompactString,
    pub category: CompactString,
    pub category_flags: IconCategory,
}

impl Icon {
    pub fn new(glyph: char, name: &str, category: &str, category_flags: IconCategory) -> Self {
        Self {
            glyph, 
            name: CompactString::from(name),
            category: CompactString::from(category),
            category_flags,
        }
    }
    pub fn is_category(&self, category: &str) -> bool { self.category == category }
    pub fn matches(&self, query: &str) -> bool {
        self.name.contains(query) || self.category.contains(query)
    }
}

impl Display for Icon {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{}", self.glyph)
    }
}

// --- Positioned Icon with Spatial Awareness ---------------------------------

#[derive(Debug, Clone, Constructor, CopyGetters)]
pub struct PositionedIcon<T: Scalar = u16> {
    #[getset(get_copy = "pub")]
    icon: Icon,
    position: Point<T, ScreenSpace>,
    bounds: Option<Rect<T, ScreenSpace>>,
    scale: f32,
    rotation: f32,
}

impl<T: Scalar> PositionedIcon<T> {
    pub fn at_position(icon: Icon, position: Point<T, ScreenSpace>) -> Self {
        Self::new(icon, position, None, 1.0, 0.0)
    }
    
    pub fn within_bounds(mut self, bounds: Rect<T, ScreenSpace>) -> Self {
        self.bounds = Some(bounds); self
    }
    
    pub fn scaled(mut self, scale: f32) -> Self {
        self.scale = scale; self
    }
    
    pub fn rotated(mut self, degrees: f32) -> Self {
        self.rotation = degrees; self
    }
    
    pub fn is_visible_in(&self, viewport: Rect<T, ScreenSpace>) -> bool {
        if let Some(bounds) = self.bounds {
            viewport.intersects(&bounds)
        } else {
            viewport.contains(self.position)
        }
    }
}

// --- Icon Registry with Fast Lookup -----------------------------------------

#[derive(Debug, Clone, Constructor)]
pub struct IconRegistry {
    icons: FxHashMap<CompactString, Icon>,
    categories: FxHashMap<CompactString, Vec<CompactString>>,
    glyph_lookup: FxHashMap<char, CompactString>,
}

impl IconRegistry {
    pub fn new() -> Self {
        let mut registry = Self {
            icons: FxHashMap::default(),
            categories: FxHashMap::default(),
            glyph_lookup: FxHashMap::default(),
        };
        registry.load_nerd_fonts();
        registry
    }
    
    pub fn get(&self, name: &str) -> Option<&Icon> {
        self.icons.get(name)
    }
    
    pub fn get_by_glyph(&self, glyph: char) -> Option<&Icon> {
        self.glyph_lookup.get(&glyph)
            .and_then(|name| self.icons.get(name))
    }
    
    pub fn search(&self, query: &str) -> Vec<&Icon> {
        self.icons.values()
            .filter(|icon| icon.matches(query))
            .collect()
    }
    
    pub fn get_category(&self, category: &str) -> Vec<&Icon> {
        self.categories.get(category)
            .map(|names| names.iter().filter_map(|name| self.icons.get(name)).collect())
            .unwrap_or_default()
    }
    
    fn load_nerd_fonts(&mut self) {
        // File system icons
        self.register("file", '\u{f15b}', "file", IconCategory::FILE);
        self.register("folder", '\u{f07b}', "file", IconCategory::FOLDER);
        self.register("folder_open", '\u{f07c}', "file", IconCategory::FOLDER);
        self.register("image", '\u{f03e}', "file", IconCategory::FILE);
        self.register("code", '\u{f121}', "file", IconCategory::FILE);
        self.register("document", '\u{f0f6}', "file", IconCategory::FILE);
        
        // Status indicators
        self.register("success", '\u{f00c}', "status", IconCategory::STATUS);
        self.register("error", '\u{f00d}', "status", IconCategory::STATUS);
        self.register("warning", '\u{f071}', "status", IconCategory::STATUS);
        self.register("info", '\u{f05a}', "status", IconCategory::STATUS);
        self.register("loading", '\u{f110}', "status", IconCategory::STATUS);
        
        // Navigation and UI
        self.register("arrow_up", '\u{f062}', "ui", IconCategory::UI);
        self.register("arrow_down", '\u{f063}', "ui", IconCategory::UI);
        self.register("arrow_left", '\u{f060}', "ui", IconCategory::UI);
        self.register("arrow_right", '\u{f061}', "ui", IconCategory::UI);
        self.register("chevron_up", '\u{f077}', "ui", IconCategory::UI);
        self.register("chevron_down", '\u{f078}', "ui", IconCategory::UI);
        self.register("menu", '\u{f0c9}', "ui", IconCategory::UI);
        self.register("close", '\u{f00d}', "ui", IconCategory::UI);
        
        // Actions
        self.register("edit", '\u{f044}', "action", IconFlags::ACTION);
        self.register("save", '\u{f0c7}', "action", IconFlags::ACTION);
        self.register("delete", '\u{f2ed}', "action", IconFlags::ACTION | IconFlags::COLORED);
        self.register("copy", '\u{f0c5}', "action", IconFlags::ACTION);
        self.register("search", '\u{f002}', "action", IconFlags::ACTION);
        self.register("settings", '\u{f013}', "action", IconFlags::ACTION);
        
        // Devices and network
        self.register("computer", '\u{f108}', "device", IconFlags::DEVICE);
        self.register("mobile", '\u{f10b}', "device", IconFlags::DEVICE);
        self.register("server", '\u{f233}', "device", IconFlags::DEVICE);
        self.register("network", '\u{f0e8}', "network", IconFlags::NETWORK);
        self.register("wifi", '\u{f1eb}', "network", IconFlags::NETWORK);
        
        // Programming symbols
        self.register("git", '\u{f1d3}', "symbol", IconFlags::SYMBOL);
        self.register("github", '\u{f09b}', "symbol", IconFlags::SYMBOL);
        self.register("terminal", '\u{f120}', "symbol", IconFlags::SYMBOL);
        self.register("code_branch", '\u{f126}', "symbol", IconFlags::SYMBOL);
    }
    
    fn register(&mut self, name: &str, glyph: char, category: &str, category_flags: IconCategory) {
        let name_str = CompactString::from(name);
        let category_str = CompactString::from(category);
        let icon = Icon::new(glyph, name, category, category_flags);
        
        self.icons.insert(name_str.clone(), icon);
        self.glyph_lookup.insert(glyph, name_str.clone());
        
        self.categories.entry(category_str)
            .or_insert_with(Vec::new)
            .push(name_str);
    }
}

// --- Icon Positioning Engine ------------------------------------------------

#[derive(Debug, Clone, Constructor)]
pub struct IconEngine<T: Scalar = u16> {
    registry: IconRegistry,
    spatial_engine: Option<SpatialEngine<T>>,
    cache: FxHashMap<u64, Point<T, ScreenSpace>>,
    positioned_icons: Vec<PositionedIcon<T>>,
    state_flags: StateFlags,
}

impl<T: Scalar> IconEngine<T> where T: From<u8> + num_traits::Zero + num_traits::One {
    pub fn calculate_position(&mut self, icon_name: &str, base_rect: Rect<T, ScreenSpace>, alignment: IconAlignment) -> Option<Point<T, ScreenSpace>> {
        let icon = self.registry.get(icon_name)?;
        
        if self.state_flags.contains(StateFlags::empty()) { // Simplified caching
            let key = self.cache_key(icon_name, &base_rect, alignment);
            if let Some(&cached) = self.cache.get(&key) { return Some(cached); }
        }
        
        let position = match alignment {
            IconAlignment::Center => Point::new(
                base_rect.x() + base_rect.w() / (T::one() + T::one()),
                base_rect.y() + base_rect.h() / (T::one() + T::one())
            ),
            IconAlignment::TopLeft => Point::new(base_rect.x(), base_rect.y()),
            IconAlignment::TopRight => Point::new(base_rect.x() + base_rect.w() - T::one(), base_rect.y()),
            IconAlignment::BottomLeft => Point::new(base_rect.x(), base_rect.y() + base_rect.h() - T::one()),
            IconAlignment::BottomRight => Point::new(
                base_rect.x() + base_rect.w() - T::one(),
                base_rect.y() + base_rect.h() - T::one()
            ),
            IconAlignment::Left => Point::new(base_rect.x(), base_rect.y() + base_rect.h() / (T::one() + T::one())),
            IconAlignment::Right => Point::new(
                base_rect.x() + base_rect.w() - T::one(),
                base_rect.y() + base_rect.h() / (T::one() + T::one())
            ),
        };
        
        if self.state_flags.contains(StateFlags::empty()) { // Simplified caching
            self.cache.insert(self.cache_key(icon_name, &base_rect, alignment), position);
        }
        
        Some(position)
    }
    
    pub fn place_icon(&mut self, icon_name: &str, position: Point<T, ScreenSpace>) -> Option<PositionedIcon<T>> {
        let icon = self.registry.get(icon_name)?.clone();
        let positioned = PositionedIcon::at_position(icon, position);
        self.positioned_icons.push(positioned.clone());
        Some(positioned)
    }
    
    pub fn place_in_grid(&mut self, icons: &[&str], grid_rect: Rect<T, ScreenSpace>, columns: T) -> Vec<PositionedIcon<T>> {
        let mut positioned = Vec::new();
        let cell_width = grid_rect.w() / columns;
        let cell_height = cell_width; // Square cells
        
        for (i, &icon_name) in icons.iter().enumerate() {
            if let Some(icon) = self.registry.get(icon_name) {
                let row = T::from((i / columns.to_usize().unwrap_or(1)) as u8).unwrap_or(T::zero());
                let col = T::from((i % columns.to_usize().unwrap_or(1)) as u8).unwrap_or(T::zero());
                
                let x = grid_rect.x() + col * cell_width + cell_width / (T::one() + T::one());
                let y = grid_rect.y() + row * cell_height + cell_height / (T::one() + T::one());
                
                let pos_icon = PositionedIcon::at_position(icon.clone(), Point::new(x, y));
                positioned.push(pos_icon.clone());
                self.positioned_icons.push(pos_icon);
            }
        }
        
        positioned
    }
    
    pub fn get_icons_in_area(&self, area: Rect<T, ScreenSpace>) -> Vec<&PositionedIcon<T>> {
        self.positioned_icons.iter()
            .filter(|icon| icon.is_visible_in(area))
            .collect()
    }
    
    // --- Performance Operations ----------------------------------------------
    
    fn cache_key(&self, icon_name: &str, rect: &Rect<T, ScreenSpace>, alignment: IconAlignment) -> u64 {
        use std::collections::hash_map::DefaultHasher;
        use std::hash::{Hash, Hasher};
        
        let mut hasher = DefaultHasher::new();
        icon_name.hash(&mut hasher);
        rect.x().to_u64().unwrap_or(0).hash(&mut hasher);
        rect.y().to_u64().unwrap_or(0).hash(&mut hasher);
        (alignment as u8).hash(&mut hasher);
        hasher.finish()
    }
    
    pub fn invalidate_cache(&mut self) { 
        self.cache.clear(); 
        self.positioned_icons.clear(); 
    }
    
    pub fn cache_stats(&self) -> (usize, usize) { 
        (self.cache.len(), self.cache.capacity()) 
    }
}

// --- Icon Alignment ----------------------------------------------------------

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
#[repr(u8)]
pub enum IconAlignment {
    Center = 0, TopLeft = 1, TopRight = 2, BottomLeft = 3,
    BottomRight = 4, Left = 5, Right = 6,
}

// --- Fluent Icon Configuration API ------------------------------------------

impl<T: Scalar> IconEngine<T> where T: From<u8> + num_traits::Zero + num_traits::One {
    pub fn with_registry() -> Self {
        Self::new(IconRegistry::new(), None, FxHashMap::default(), Vec::new(), IconFlags::OPTIMIZED)
    }
    
    pub fn with_spatial_engine(mut self, engine: SpatialEngine<T>) -> Self { 
        self.spatial_engine = Some(engine); self 
    }
    pub fn with_caching(mut self) -> Self { self.flags |= IconFlags::CACHED; self }
    pub fn with_preloading(mut self) -> Self { self.flags |= IconFlags::PRELOAD; self }
    pub fn interactive(mut self) -> Self { self.flags |= IconFlags::INTERACTIVE; self }
    pub fn enhanced(mut self) -> Self { self.flags |= IconFlags::ENHANCED; self }
    pub fn optimized(mut self) -> Self { self.flags |= IconFlags::OPTIMIZED; self }
}

// --- Type Aliases ------------------------------------------------------------

pub type FileIcon = Icon;
pub type StatusIcon = Icon;
pub type UIIcon = Icon;

// --- Default Implementation --------------------------------------------------

impl Default for IconRegistry {
    fn default() -> Self { Self::new() }
}

impl<T: Scalar> Default for IconEngine<T> where T: From<u8> + num_traits::Zero + num_traits::One {
    fn default() -> Self { Self::with_registry() }
}