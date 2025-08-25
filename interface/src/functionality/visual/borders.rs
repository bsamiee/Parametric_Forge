// Title         : functionality/visual/borders.rs
// Author        : Bardia Samiee
// Project       : Parametric Forge
// License       : MIT
// Path          : interface/src/functionality/visual/borders.rs
// ----------------------------------------------------------------------------
//! Spatial-aware border rendering with performance optimization

use derive_more::{Constructor, From, Display};
use getset::CopyGetters;
use bitflags::bitflags;
use rustc_hash::FxHashMap;
use ratatui::symbols::border;
use ratatui::widgets::{Block, BorderType, Borders};
use crate::functionality::core::{geometry::{Point, Rect, ScreenSpace, SpatialEngine, Scalar}, state::StateFlags};
use super::theming::{ThemeEngine, ThemeColor};

// --- Using Core Coordinate Spaces and Ratatui Types ----------------------
// Eliminated: SingleSpace, DoubleSpace, RoundedSpace, ThickSpace
// Using: ScreenSpace from core::geometry + ratatui::BorderType directly

// --- Border Configuration Flags ---------------------------------------------
// Simplified to essential border configuration only
bitflags! {
    pub struct BorderConfig: u8 {
        const SHADOW = 1; const GLOW = 2; const CONNECTED = 4; const COLLAPSED = 8;
    }
}

// --- Border Style with Type Safety ------------------------------------------

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Constructor, Display)]
pub struct BorderStyle {
    pub border_type: BorderType,
    pub thickness: u8,
    pub corner_radius: u8,
    pub config: BorderConfig,
}

impl BorderStyle {
    pub fn new(border_type: BorderType, thickness: u8, corner_radius: u8, config: BorderConfig) -> Self {
        Self { border_type, thickness, corner_radius, config }
    }
    pub fn to_ratatui(self) -> BorderType { self.border_type }
}

// --- Spatial Border Calculator ----------------------------------------------

#[derive(Debug, Clone, Constructor)]
pub struct BorderEngine<T: Scalar = usize> {
    pub style: BorderStyle,
    spatial_engine: Option<SpatialEngine<T>>,
    cache: FxHashMap<u64, BorderMetrics>,
}

#[derive(Debug, Clone, Copy, Constructor, CopyGetters)]
pub struct BorderMetrics {
    #[getset(get_copy = "pub")]
    outer_rect: Rect<u16, ScreenSpace>,
    inner_rect: Rect<u16, ScreenSpace>,
    corner_positions: [Point<u16, ScreenSpace>; 4],
    side_lengths: [u16; 4], // top, right, bottom, left
}

#[derive(Debug, Clone, Copy, Constructor)]
pub struct BorderConnection {
    from: Point<u16, ScreenSpace>,
    to: Point<u16, ScreenSpace>,
    connection_type: ConnectionType,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ConnectionType {
    Corner, Side, Junction
}

impl<T: Scalar> BorderEngine<T> where T: From<u8> {
    pub fn calculate_metrics(&mut self, rect: Rect<u16, ScreenSpace>) -> BorderMetrics {
        // Simplified caching - always enabled for performance
            let key = self.cache_key(&rect);
            if let Some(&cached) = self.cache.get(&key) { return cached; }
        }
        
        let thickness = self.style.thickness as u16;
        let outer_rect = rect;
        let inner_rect = Rect::new(
            rect.x() + thickness,
            rect.y() + thickness,
            rect.w().saturating_sub(thickness * 2),
            rect.h().saturating_sub(thickness * 2)
        );
        
        let corner_positions = self.calculate_corners(&outer_rect);
        let side_lengths = [
            outer_rect.w(),  // top
            outer_rect.h(),  // right
            outer_rect.w(),  // bottom  
            outer_rect.h(),  // left
        ];
        
        let metrics = BorderMetrics::new(outer_rect, inner_rect, corner_positions, side_lengths);
        
        // Simplified caching - always enabled for performance
            self.cache.insert(self.cache_key(&rect), metrics);
        }
        
        metrics
    }
    
    pub fn render_border(&mut self, rect: Rect<u16, ScreenSpace>, theme: &mut ThemeEngine<T>) -> Block {
        let metrics = self.calculate_metrics(rect);
        let mut block = Block::default();
        
        // Apply all border sides by default
        let borders = Borders::ALL;
        
        block = block.borders(borders).border_type(self.style.to_ratatui());
        
        // Apply theme-aware styling
        if let Some(color) = self.get_border_color(theme) {
            block = block.border_style(ratatui::style::Style::default().fg(color.to_ratatui()));
        }
        
        // Apply enhanced effects if configured
        if self.style.config.contains(BorderConfig::SHADOW) {
            // Shadow effects would be applied here
        }
        
        block
    }
    
    pub fn connect_borders(&mut self, rects: &[Rect<u16, ScreenSpace>]) -> Vec<BorderConnection> {
        if !self.style.config.contains(BorderConfig::CONNECTED) { return Vec::new(); }
        
        let mut connections = Vec::new();
        
        for (i, &rect1) in rects.iter().enumerate() {
            for &rect2 in rects.iter().skip(i + 1) {
                if let Some(connection) = self.calculate_connection(rect1, rect2) {
                    connections.push(connection);
                }
            }
        }
        
        connections
    }
    
    pub fn calculate_collapsed_layout(&mut self, rects: &[Rect<u16, ScreenSpace>]) -> Vec<Rect<u16, ScreenSpace>> {
        if !self.style.config.contains(BorderConfig::COLLAPSED) { return rects.to_vec(); }
        
        let thickness = self.style.thickness as u16;
        let mut collapsed = Vec::with_capacity(rects.len());
        
        for &rect in rects {
            // Reduce spacing by border thickness to create collapsed effect
            let adjusted = Rect::new(
                rect.x(),
                rect.y(),
                rect.w().saturating_sub(thickness / 2),
                rect.h().saturating_sub(thickness / 2)
            );
            collapsed.push(adjusted);
        }
        
        collapsed
    }
    
    // --- Internal Calculations ----------------------------------------------
    
    fn calculate_corners(&self, rect: &Rect<u16, ScreenSpace>) -> [Point<u16, ScreenSpace>; 4] {
        let radius = self.style.corner_radius as u16;
        [
            Point::new(rect.x() + radius, rect.y() + radius),                    // top-left
            Point::new(rect.x() + rect.w() - radius, rect.y() + radius),        // top-right
            Point::new(rect.x() + rect.w() - radius, rect.y() + rect.h() - radius), // bottom-right
            Point::new(rect.x() + radius, rect.y() + rect.h() - radius),        // bottom-left
        ]
    }
    
    fn calculate_connection(&self, rect1: Rect<u16, ScreenSpace>, rect2: Rect<u16, ScreenSpace>) -> Option<BorderConnection> {
        // Check for adjacency and calculate connection points
        if rect1.intersects(&rect2) {
            let center1 = rect1.center();
            let center2 = rect2.center();
            Some(BorderConnection::new(center1, center2, ConnectionType::Junction))
        } else {
            None
        }
    }
    
    fn apply_smart_adjustments(&self, block: Block, metrics: &BorderMetrics) -> Block {
        // Smart corner detection and adjustment would be implemented here
        // For now, return the block as-is
        block
    }
    
    fn get_border_color(&self, theme: &ThemeEngine<T>) -> Option<ThemeColor> {
        // Integration with theme system for border colors
        Some(ThemeColor::new(128, 128, 128)) // Default gray
    }
    
    fn cache_key(&self, rect: &Rect<u16, ScreenSpace>) -> u64 {
        ((rect.x() as u64) << 48) | ((rect.y() as u64) << 32) | 
        ((rect.w() as u64) << 16) | (rect.h() as u64) ^
        (self.style.config.bits() as u64)
    }
    
    // --- Performance Operations ----------------------------------------------
    
    pub fn batch_calculate(&mut self, rects: &[Rect<u16, ScreenSpace>]) -> Vec<BorderMetrics> {
        // Always use optimized batch processing
            return rects.iter().map(|&rect| self.calculate_metrics(rect)).collect();
        }
        
        // Batch processing for better cache locality
        let mut results = Vec::with_capacity(rects.len());
        for &rect in rects {
            results.push(self.calculate_metrics(rect));
        }
        results
    }
    
    pub fn invalidate_cache(&mut self) { 
        self.cache.clear(); 
        self.connections.clear(); 
    }
    
    pub fn cache_stats(&self) -> (usize, usize) { 
        (self.cache.len(), self.cache.capacity()) 
    }
}

// --- Fluent Border Configuration API ----------------------------------------

impl<T: Scalar> BorderEngine<T> where T: From<u8> {
    pub fn single() -> Self {
        let style = BorderStyle::new(BorderType::Plain, 1, 0, BorderConfig::empty());
        Self::new(style, None, FxHashMap::default())
    }
    
    pub fn double() -> Self {
        let style = BorderStyle::new(BorderType::Double, 2, 0, BorderConfig::empty());
        Self::new(style, None, FxHashMap::default())
    }
    
    pub fn rounded() -> Self {
        let style = BorderStyle::new(BorderType::Rounded, 1, 4, BorderConfig::empty());
        Self::new(style, None, FxHashMap::default())
    }
    
    pub fn thick() -> Self {
        let style = BorderStyle::new(BorderType::Thick, 3, 0, BorderConfig::empty());
        Self::new(style, None, FxHashMap::default())
    }
    
    // Using derive_more::Constructor instead of fluent methods
    pub fn with_spatial_engine(mut self, engine: SpatialEngine<T>) -> Self { 
        self.spatial_engine = Some(engine); self 
    }
    pub fn with_shadow(mut self) -> Self { self.style.config |= BorderConfig::SHADOW; self }
    pub fn connected(mut self) -> Self { self.style.config |= BorderConfig::CONNECTED; self }
    
    // Simplified - borders are now managed by ratatui::Borders directly
}

// --- Type Aliases ------------------------------------------------------------

// Type aliases simplified - all use BorderEngine now
pub type SingleBorder<T = usize> = BorderEngine<T>;
pub type DoubleBorder<T = usize> = BorderEngine<T>;
pub type RoundedBorder<T = usize> = BorderEngine<T>;
pub type ThickBorder<T = usize> = BorderEngine<T>;

// --- Default Implementation --------------------------------------------------

impl<T: Scalar> Default for BorderEngine<T> where T: From<u8> {
    fn default() -> Self { Self::single() }
}