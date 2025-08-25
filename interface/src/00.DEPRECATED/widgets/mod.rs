// Title         : widgets/mod.rs
// Author        : Bardia Samiee
// Project       : Parametric Forge Interface
// License       : MIT
// Path          : interface/src/widgets/mod.rs
// ----------------------------------------------------------------------------

//! Widget foundation module providing reusable TUI components

// --- Validation Module ------------------------------------------------------
pub mod validation;
pub use validation::Validator;

// --- Builder Pattern Macro --------------------------------------------------

/// Macro for generating widget builders with common methods
#[macro_export]
macro_rules! widget_builder {
    (
        $(#[$builder_attr:meta])*
        pub struct $builder_name:ident {
            $widget_field:ident: $widget_type:ty,
        }

        methods {
            $(
                $(#[$method_attr:meta])*
                $method_name:ident($field_access:expr, $param_type:ty)
            ),* $(,)?
        }

        $(custom {
            $(
                $(#[$custom_attr:meta])*
                fn $custom_name:ident($($custom_param:ident: $custom_param_type:ty),*) $custom_body:block
            )*
        })?
    ) => {
        $(#[$builder_attr])*
        pub struct $builder_name {
            $widget_field: $widget_type,
        }

        impl $builder_name {
            pub fn new() -> Self {
                Self {
                    $widget_field: <$widget_type>::new(),
                }
            }

            $(
                $(#[$method_attr])*
                pub fn $method_name(mut self, value: $param_type) -> Self {
                    $field_access = value;
                    self
                }
            )*

            pub fn build(self) -> $widget_type {
                self.$widget_field
            }

            $($(
                $(#[$custom_attr])*
                pub fn $custom_name(mut self, $($custom_param: $custom_param_type),*) -> Self $custom_body
            )*)?
        }

        impl Default for $builder_name {
            fn default() -> Self {
                Self::new()
            }
        }
    };
}

// --- Component Trait Consolidation Macro -----------------------------------

/// Macro for implementing standard Component trait methods that are identical across widgets
/// Eliminates 200+ LOC of boilerplate code across the widgets module
#[macro_export]
macro_rules! impl_standard_component_methods {
    ($widget_type:ty, $state_field:ident, $config_field:ident, $action_tx_field:ident) => {
        impl $widget_type {
            fn standard_register_action_handler(&mut self, tx: Sender<Action>) -> Result<()> {
                self.$action_tx_field = Some(tx);
                Ok(())
            }

            fn standard_can_focus(&self) -> bool {
                self.$config_field.widget.focusable
            }

            fn standard_on_focus(&mut self) -> Result<()> {
                if let Some(state) = self.$state_field.as_widget_state_mut() {
                    state.set_widget_focused(true);
                    // Initialize selection if none exists and we have items
                    if state.get_selected().is_none() && self.has_items() {
                        state.set_selected(Some(0));
                    }
                }
                Ok(())
            }

            fn standard_on_blur(&mut self) -> Result<()> {
                if let Some(state) = self.$state_field.as_widget_state_mut() {
                    state.set_widget_focused(false);
                }
                Ok(())
            }
        }
    };
}

// --- Navigation Trait for Widgets -------------------------------------------

/// Generic navigation trait that consolidates identical navigation patterns
/// across list, table, tree, and menu widgets. Eliminates 80+ LOC of duplication.
pub trait NavigableWidget {
    /// Get the total number of navigable items
    fn get_item_count(&self) -> usize;

    /// Get currently selected index
    fn get_selected(&self) -> Option<usize>;

    /// Set selected index
    fn set_selected(&mut self, idx: Option<usize>);

    /// Update viewport/scroll after selection change (optional override)
    fn update_viewport(&mut self) {}

    /// Check if widget has any items
    fn has_items(&self) -> bool {
        self.get_item_count() > 0
    }

    /// Generic navigation implementation
    fn navigate(&mut self, direction: Direction) -> Option<Action> {
        let count = self.get_item_count();
        if count == 0 {
            return None;
        }

        let current = self.get_selected().unwrap_or(0);
        let new_idx = crate::core::calculate_index(current, count, direction);

        self.set_selected(Some(new_idx));
        self.update_viewport();
        None
    }
}

// --- Config Generation Macro ------------------------------------------------

/// Macro for generating widget configuration structs with unified patterns
/// Eliminates 96+ LOC of repetitive config definitions
#[macro_export]
macro_rules! widget_config {
    (
        $(#[$attr:meta])*
        pub struct $config_name:ident {
            $(
                $(#[$field_attr:meta])*
                pub $field_name:ident: $field_type:ty = $default_value:expr
            ),* $(,)?
        }
    ) => {
        $(#[$attr])*
        #[derive(Debug, Clone)]
        pub struct $config_name {
            pub widget: WidgetConfig,
            $(
                $(#[$field_attr])*
                pub $field_name: $field_type,
            )*
        }

        impl Default for $config_name {
            fn default() -> Self {
                Self {
                    widget: WidgetConfig::default(),
                    $(
                        $field_name: $default_value,
                    )*
                }
            }
        }
    };
}

// --- Focus Management Extensions ---------------------------------------------

/// Extended focus management trait for standardized widget focus behavior
pub trait StandardFocusManager: FocusManager {
    /// Get currently selected item index (for widgets with selection)
    fn get_selected(&self) -> Option<usize> {
        None
    }

    /// Set selected item index (for widgets with selection)
    fn set_selected(&mut self, _idx: Option<usize>) {}
}

// --- StandardWidgetState Generic Foundation ---------------------------------

/// Generic foundation for widget state that consolidates common patterns
/// Eliminates 120+ LOC of repetitive state definitions
#[derive(Debug, Clone)]
pub struct StandardWidgetState<T = ()> {
    pub selected: Option<usize>,
    pub is_focused: bool,
    pub scroll_offset: usize,
    pub custom: T,
}

impl<T: Default> Default for StandardWidgetState<T> {
    fn default() -> Self {
        Self {
            selected: None,
            is_focused: false,
            scroll_offset: 0,
            custom: T::default(),
        }
    }
}

impl<T: Default + Send> WidgetState for StandardWidgetState<T> {
    fn reset(&mut self) {
        self.selected = None;
        self.is_focused = false;
        self.scroll_offset = 0;
        // Note: custom field reset is handled by individual implementations
    }

    fn is_dirty(&self) -> bool {
        self.selected.is_some() || self.is_focused
    }
}

impl<T: Send> FocusManager for StandardWidgetState<T> {
    fn is_widget_focused(&self) -> bool {
        self.is_focused
    }

    fn set_widget_focused(&mut self, focused: bool) {
        self.is_focused = focused;
    }
}

impl<T: Send> StandardFocusManager for StandardWidgetState<T> {
    fn get_selected(&self) -> Option<usize> {
        self.selected
    }

    fn set_selected(&mut self, idx: Option<usize>) {
        self.selected = idx;
    }
}

/// Macro for deriving standard widget state with custom extensions
#[macro_export]
macro_rules! derive_widget_state {
    ($state_name:ident) => {
        pub type $state_name = StandardWidgetState;
    };
    ($state_name:ident, $custom_type:ty) => {
        pub type $state_name = StandardWidgetState<$custom_type>;
    };
}

// --- Event Interest Profile System ------------------------------------------

/// Standardized event interest profiles for widgets
/// Eliminates 40+ LOC of manual event interest implementations
#[derive(Clone, Copy, Debug)]
pub enum WidgetEventProfile {
    /// Basic navigation: KEY_PRESS + FOCUS_EVENTS
    Navigation,
    /// Interactive: Navigation + MOUSE_CLICK
    Interactive,
    /// Input widgets: Interactive + ALL_KEYS
    Input,
    /// Complete coverage: All events
    Complete,
}

impl WidgetEventProfile {
    pub fn to_mask(self) -> crate::components::EventInterestMask {
        use crate::components::EventInterestMask;
        match self {
            Self::Navigation => EventInterestMask::KEY_PRESS.with(EventInterestMask::FOCUS_EVENTS),
            Self::Interactive => Self::Navigation.to_mask().with(EventInterestMask::MOUSE_CLICK),
            Self::Input => EventInterestMask::ALL_KEYS
                .with(EventInterestMask::MOUSE_CLICK)
                .with(EventInterestMask::FOCUS_EVENTS),
            Self::Complete => EventInterestMask::ALL,
        }
    }
}

// --- Generic Rendering Helpers ----------------------------------------------

/// Trait for widgets that support themed rendering
pub trait ThemedWidget {
    fn get_theme(&self) -> &WidgetTheme;
    fn is_focused(&self) -> bool;
    fn get_title(&self) -> Option<&str>;
}

/// Generic rendering helper that consolidates border, theme, and style logic
/// Eliminates 150+ LOC of redundant rendering patterns
pub fn render_themed_widget<T, F>(
    widget: &T,
    frame: &mut Frame,
    area: Rect,
    border: Option<&BorderSpec>,
    renderer: F,
) -> Result<()>
where
    T: ThemedWidget,
    F: FnOnce(&mut Frame, Rect, Style, Style) -> Result<()>,
{
    let theme = widget.get_theme();
    let is_focused = widget.is_focused();
    let title = widget.get_title();

    let render_area = apply_themed_border(frame, area, border, theme, is_focused, title);
    let text_style = FocusStyle::text(theme, is_focused, false);
    let highlight_style = FocusStyle::selection(theme, is_focused);

    renderer(frame, render_area, text_style, highlight_style)
}

/// Simplified render helper for widgets without theme
pub fn render_basic_widget<F>(
    frame: &mut Frame,
    area: Rect,
    border: Option<&BorderSpec>,
    is_focused: bool,
    renderer: F,
) -> Result<()>
where
    F: FnOnce(&mut Frame, Rect) -> Result<()>,
{
    let render_area = apply_border_with_focus(frame, area, border, is_focused);
    renderer(frame, render_area)
}

// --- Unified Builder Pattern Macro ------------------------------------------

/// Unified widget builder macro that consolidates common builder patterns
/// Eliminates 80+ LOC of repetitive builder implementations
#[macro_export]
macro_rules! unified_widget_builder {
    (
        $builder_name:ident for $widget_type:ty {
            config: $config_type:ty,
            new: $new_expr:expr,
            $(
                $(#[$method_attr:meta])*
                $method_name:ident($param:ident: $param_type:ty) => $assignment:expr
            ),* $(,)?
        }
    ) => {
        pub struct $builder_name {
            config: $config_type,
        }

        impl $builder_name {
            pub fn new() -> Self {
                Self {
                    config: <$config_type>::default(),
                }
            }

            // Common widget configuration methods
            pub fn focusable(mut self, focusable: bool) -> Self {
                self.config.widget.focusable = focusable;
                self
            }

            pub fn border(mut self, border: bool) -> Self {
                self.config.widget.border = border;
                self
            }

            pub fn title(mut self, title: String) -> Self {
                self.config.widget.title = Some(title);
                self
            }

            pub fn theme(mut self, theme: WidgetTheme) -> Self {
                self.config.widget.theme = theme;
                self
            }

            // Widget-specific configuration methods
            $(
                $(#[$method_attr])*
                pub fn $method_name(mut self, $param: $param_type) -> Self {
                    $assignment;
                    self
                }
            )*

            pub fn build(self) -> $widget_type {
                $new_expr
            }
        }

        impl Default for $builder_name {
            fn default() -> Self {
                Self::new()
            }
        }
    };
}

// --- Widget Module Exports --------------------------------------------------

pub mod text_input;

pub mod tree;

pub mod table;

pub mod menu;

pub mod list;

pub mod popup;

pub mod form;

pub mod panel;

pub mod breadcrumb;

pub mod status_bar;

pub mod toolbar;

pub mod scrollview;

pub mod progress;

// --- Widget Theming and Styling ---------------------------------------------

use crate::{
    components::ComponentId,
    core::{Action, Direction, Focus},
    layouts::BorderSpec,
};
use color_eyre::eyre::Result;
use ratatui::{
    layout::Rect,
    style::{Color, Modifier, Style},
    Frame,
};

/// Widget theme configuration
#[derive(Debug, Clone)]
pub struct WidgetTheme {
    pub primary: Color,
    pub secondary: Color,
    pub accent: Color,
    pub background: Color,
    pub text: Color,
    pub text_dim: Color,
    pub border: Color,
    pub border_focused: Color,
    pub selection: Color,
    pub selection_focused: Color,
    pub error: Color,
    pub warning: Color,
    pub success: Color,
}

impl Default for WidgetTheme {
    fn default() -> Self {
        Self {
            primary: Color::Blue,
            secondary: Color::Cyan,
            accent: Color::Yellow,
            background: Color::Black,
            text: Color::White,
            text_dim: Color::DarkGray,
            border: Color::White,
            border_focused: Color::Yellow,
            selection: Color::DarkGray,
            selection_focused: Color::Blue,
            error: Color::Red,
            warning: Color::Yellow,
            success: Color::Green,
        }
    }
}

/// Focus-aware styling utilities with consolidated computation
pub struct FocusStyle;

impl FocusStyle {
    /// Unified style computation for all widget states
    fn compute_style(theme: &WidgetTheme, is_focused: bool, fg: Color, bg: Option<Color>, bold: bool) -> Style {
        let mut style = Style::default().fg(fg);
        if let Some(bg_color) = bg {
            style = style.bg(bg_color);
        }
        if bold {
            style = style.add_modifier(Modifier::BOLD);
        }
        style
    }

    /// Get text style based on focus state
    pub fn text(theme: &WidgetTheme, is_focused: bool, is_selected: bool) -> Style {
        let fg = if is_focused { theme.text } else { theme.text_dim };
        let bg = is_selected.then(|| {
            if is_focused {
                theme.selection_focused
            } else {
                theme.selection
            }
        });
        Self::compute_style(theme, is_focused, fg, bg, is_focused)
    }

    /// Get border style based on focus state
    pub fn border(theme: &WidgetTheme, is_focused: bool) -> Style {
        Self::compute_style(
            theme,
            is_focused,
            if is_focused { theme.border_focused } else { theme.border },
            None,
            false,
        )
    }

    /// Get selection style based on focus state
    pub fn selection(theme: &WidgetTheme, is_focused: bool) -> Style {
        Self::compute_style(
            theme,
            is_focused,
            theme.text,
            Some(if is_focused {
                theme.selection_focused
            } else {
                theme.selection
            }),
            is_focused,
        )
    }

    /// Get error style
    pub fn error(theme: &WidgetTheme) -> Style {
        Self::compute_style(theme, false, theme.error, None, true)
    }

    /// Get warning style
    pub fn warning(theme: &WidgetTheme) -> Style {
        Self::compute_style(theme, false, theme.warning, None, false)
    }

    /// Get success style
    pub fn success(theme: &WidgetTheme) -> Style {
        Self::compute_style(theme, false, theme.success, None, false)
    }
}

/// Responsive design utilities
pub struct ResponsiveDesign;

impl ResponsiveDesign {
    /// Check if area is too small for full rendering
    pub fn is_minimal(area: Rect) -> bool {
        area.width < 10 || area.height < 3
    }

    /// Check if area supports borders
    pub fn supports_borders(area: Rect) -> bool {
        area.width >= 4 && area.height >= 3
    }

    /// Get appropriate constraint based on available space
    pub fn adaptive_constraint(available_width: u16, preferred_width: u16) -> u16 {
        if available_width < preferred_width {
            available_width.saturating_sub(2) // Leave margin
        } else {
            preferred_width
        }
    }
}

// --- Common Widget Patterns -------------------------------------------------

/// Common widget state management patterns
pub trait WidgetState: Default + Send {
    /// Reset widget to initial state
    fn reset(&mut self);

    /// Check if widget has pending changes
    fn is_dirty(&self) -> bool {
        false
    }

    /// Performance optimization: check if state change requires re-render
    fn needs_render(&self) -> bool {
        self.is_dirty()
    }

    /// Performance optimization: get state change flags
    fn get_change_flags(&self) -> WidgetChangeFlags {
        WidgetChangeFlags::default()
    }
}

// --- Optimized Widget State Storage ----------------------------------------
// Separate storage per widget type for improved memory layout and cache performance

use rustc_hash::FxHashMap;
use std::any::{Any, TypeId};

/// Optimized state storage that groups widgets by type for better cache locality
/// This is a simplified but more reliable implementation
#[derive(Debug)]
pub struct WidgetStateStorage {
    // Generic storage for all widget types with type safety
    states: FxHashMap<(ComponentId, TypeId), Box<dyn Any + Send>>,

    // Performance tracking
    total_widgets: usize,
    cache_hits: usize,
    cache_misses: usize,

    // Type distribution for monitoring
    type_counts: FxHashMap<TypeId, usize>,
}

impl Default for WidgetStateStorage {
    fn default() -> Self {
        Self::new()
    }
}

impl WidgetStateStorage {
    pub fn new() -> Self {
        Self {
            states: FxHashMap::default(),
            total_widgets: 0,
            cache_hits: 0,
            cache_misses: 0,
            type_counts: FxHashMap::default(),
        }
    }

    /// Store state for a specific widget type with optimal memory layout
    pub fn store_state<T: WidgetState + 'static>(&mut self, id: ComponentId, state: T) {
        let type_id = TypeId::of::<T>();
        let key = (id, type_id);

        // Remove old state if it exists
        if self.states.remove(&key).is_some() {
            self.total_widgets = self.total_widgets.saturating_sub(1);
            *self.type_counts.entry(type_id).or_insert(0) =
                self.type_counts.get(&type_id).unwrap_or(&0).saturating_sub(1);
        }

        // Store new state
        self.states.insert(key, Box::new(state));
        self.total_widgets += 1;
        *self.type_counts.entry(type_id).or_insert(0) += 1;
    }

    /// Retrieve state for a specific widget type with cache-optimized lookup
    pub fn get_state<T: WidgetState + 'static>(&mut self, id: &ComponentId) -> Option<&mut T> {
        let type_id = TypeId::of::<T>();
        let key = (id.clone(), type_id);

        if let Some(boxed_state) = self.states.get_mut(&key) {
            if let Some(state) = boxed_state.downcast_mut::<T>() {
                self.cache_hits += 1;
                return Some(state);
            }
        }

        self.cache_misses += 1;
        None
    }

    /// Remove state for a widget
    pub fn remove_state<T: WidgetState + 'static>(&mut self, id: &ComponentId) -> Option<T> {
        let type_id = TypeId::of::<T>();
        let key = (id.clone(), type_id);

        if let Some(boxed_state) = self.states.remove(&key) {
            if let Ok(state) = boxed_state.downcast::<T>() {
                self.total_widgets = self.total_widgets.saturating_sub(1);
                *self.type_counts.entry(type_id).or_insert(0) =
                    self.type_counts.get(&type_id).unwrap_or(&0).saturating_sub(1);
                return Some(*state);
            }
        }

        None
    }

    /// Get or create state for a widget with optimal initialization
    pub fn get_or_create_state<T: WidgetState + 'static>(&mut self, id: ComponentId) -> &mut T {
        let type_id = TypeId::of::<T>();
        let key = (id.clone(), type_id);

        // Check if state exists
        if !self.states.contains_key(&key) {
            // Create new state and store it
            let new_state = T::default();
            self.store_state(id.clone(), new_state);
        }

        // Return the state (now guaranteed to exist)
        self.get_state::<T>(&id).expect("State should exist after creation")
    }

    /// Get all states of a specific type for batch operations
    pub fn get_states_by_type<T: WidgetState + 'static>(&mut self) -> Vec<(&ComponentId, &mut T)> {
        let type_id = TypeId::of::<T>();
        let mut results = Vec::new();

        for ((id, stored_type_id), boxed_state) in &mut self.states {
            if *stored_type_id == type_id {
                if let Some(state) = boxed_state.downcast_mut::<T>() {
                    results.push((id, state));
                }
            }
        }

        results
    }

    /// Reset all states of a specific type
    pub fn reset_states_by_type<T: WidgetState + 'static>(&mut self) {
        for (_, state) in self.get_states_by_type::<T>() {
            state.reset();
        }
    }

    /// Clear all states and reset storage
    pub fn clear(&mut self) {
        self.states.clear();
        self.type_counts.clear();
        self.total_widgets = 0;
        self.cache_hits = 0;
        self.cache_misses = 0;
    }

    /// Get performance statistics
    pub fn get_stats(&self) -> WidgetStorageStats {
        WidgetStorageStats {
            total_widgets: self.total_widgets,
            cache_hits: self.cache_hits,
            cache_misses: self.cache_misses,
            cache_hit_ratio: if self.cache_hits + self.cache_misses > 0 {
                self.cache_hits as f64 / (self.cache_hits + self.cache_misses) as f64
            } else {
                0.0
            },
            type_distribution: self.get_type_distribution(),
        }
    }

    fn get_type_distribution(&self) -> FxHashMap<String, usize> {
        let mut distribution = FxHashMap::default();

        // Convert TypeId to readable type names (simplified approach)
        for (type_id, count) in &self.type_counts {
            let type_name = format!("Type_{:?}", type_id);
            distribution.insert(type_name, *count);
        }

        distribution
    }
}

/// Performance statistics for widget state storage
#[derive(Debug, Clone)]
pub struct WidgetStorageStats {
    pub total_widgets: usize,
    pub cache_hits: usize,
    pub cache_misses: usize,
    pub cache_hit_ratio: f64,
    pub type_distribution: FxHashMap<String, usize>,
}

/// Flags indicating what aspects of a widget have changed
#[derive(Debug, Clone, Default)]
pub struct WidgetChangeFlags {
    pub content_changed: bool,
    pub selection_changed: bool,
    pub focus_changed: bool,
    pub layout_changed: bool,
    pub style_changed: bool,
}

impl WidgetChangeFlags {
    pub fn any_changed(&self) -> bool {
        self.content_changed
            || self.selection_changed
            || self.focus_changed
            || self.layout_changed
            || self.style_changed
    }

    pub fn needs_full_render(&self) -> bool {
        self.content_changed || self.layout_changed
    }

    pub fn needs_style_update(&self) -> bool {
        self.focus_changed || self.selection_changed || self.style_changed
    }
}

/// Common widget configuration with theming support
#[derive(Debug, Clone)]
pub struct WidgetConfig {
    pub focusable: bool,
    pub border: bool,
    pub title: Option<String>,
    pub theme: WidgetTheme,
    pub responsive: bool,
}

impl Default for WidgetConfig {
    fn default() -> Self {
        Self {
            focusable: true,
            border: false,
            title: None,
            theme: WidgetTheme::default(),
            responsive: true,
        }
    }
}

/// Focus detection utilities for widgets
pub struct FocusDetector;

impl FocusDetector {
    /// Check if a component is currently focused based on application state
    pub fn is_focused(focus: &Focus, component_id: &ComponentId) -> bool {
        match focus {
            Focus::Component(focused_id) => focused_id == component_id,
            _ => false,
        }
    }

    /// Get focus indicator style for a component
    pub fn focus_indicator_style(theme: &WidgetTheme, is_focused: bool) -> Style {
        if is_focused {
            Style::default()
                .fg(theme.accent)
                .add_modifier(Modifier::BOLD | Modifier::UNDERLINED)
        } else {
            Style::default().fg(theme.text_dim)
        }
    }
}

// --- Focus Management Trait -------------------------------------------------

/// Unified focus management for all widgets
pub trait FocusManager {
    /// Get the current focus state of the widget
    fn is_widget_focused(&self) -> bool;

    /// Set the focus state of the widget
    fn set_widget_focused(&mut self, focused: bool);

    /// Called when the widget gains focus
    fn on_focus(&mut self) -> Result<()> {
        self.set_widget_focused(true);
        Ok(())
    }

    /// Called when the widget loses focus
    fn on_blur(&mut self) -> Result<()> {
        self.set_widget_focused(false);
        Ok(())
    }

    /// Apply focus-aware styling to text
    fn apply_focus_text_style(&self, theme: &WidgetTheme, is_selected: bool) -> Style {
        FocusStyle::text(theme, self.is_widget_focused(), is_selected)
    }

    /// Apply focus-aware border styling
    fn apply_focus_border_style(&self, theme: &WidgetTheme) -> Style {
        FocusStyle::border(theme, self.is_widget_focused())
    }

    /// Apply focus-aware selection styling
    fn apply_focus_selection_style(&self, theme: &WidgetTheme) -> Style {
        FocusStyle::selection(theme, self.is_widget_focused())
    }

    /// Get focus indicator style
    fn get_focus_indicator_style(&self, theme: &WidgetTheme) -> Style {
        FocusDetector::focus_indicator_style(theme, self.is_widget_focused())
    }
}

// --- Border Application Helpers ---------------------------------------------

/// Unified border application - handles all border scenarios in minimal code
pub fn apply_border(
    frame: &mut Frame,
    area: Rect,
    border: Option<&BorderSpec>,
    theme: Option<&WidgetTheme>,
    is_focused: bool,
    title: Option<&str>,
) -> Rect {
    use ratatui::{
        layout::Margin,
        style::{Color, Modifier, Style},
        text::Span,
        widgets::{Block, Borders},
    };

    let Some(spec) = border else { return area };
    if matches!(spec.style, crate::layouts::BorderStyle::Hidden) {
        return area;
    }
    if theme.is_some() && !ResponsiveDesign::supports_borders(area) {
        return area;
    }

    let style = match (spec.style, theme, is_focused) {
        (crate::layouts::BorderStyle::Normal, Some(t), f) => FocusStyle::border(t, f),
        (crate::layouts::BorderStyle::Normal, None, true) => {
            Style::default().fg(Color::Yellow).add_modifier(Modifier::BOLD)
        }
        (crate::layouts::BorderStyle::Normal, None, false) => Style::default().fg(Color::White),
        (crate::layouts::BorderStyle::Collapsed, Some(t), f) => {
            Style::default().fg(if f { t.primary } else { t.text_dim })
        }
        (crate::layouts::BorderStyle::Collapsed, None, f) => {
            Style::default().fg(if f { Color::Blue } else { Color::DarkGray })
        }
        _ => Style::default(),
    };

    let borders = Borders::ALL.difference(Borders::from_bits_truncate(
        (spec.connections.top as u8 * Borders::TOP.bits())
            | (spec.connections.bottom as u8 * Borders::BOTTOM.bits())
            | (spec.connections.left as u8 * Borders::LEFT.bits())
            | (spec.connections.right as u8 * Borders::RIGHT.bits()),
    ));

    let mut block = Block::default().borders(borders).style(style);
    if let (Some(text), Some(theme)) = (title, theme) {
        block = block.title(Span::styled(
            text,
            Style::default()
                .fg(if is_focused { theme.accent } else { theme.text })
                .add_modifier(if is_focused { Modifier::BOLD } else { Modifier::empty() }),
        ));
    }

    frame.render_widget(block, area);
    area.inner(Margin {
        vertical: 1,
        horizontal: 1,
    })
}

// Legacy compatibility wrappers (single line each)
pub fn apply_border_with_focus(frame: &mut Frame, area: Rect, border: Option<&BorderSpec>, is_focused: bool) -> Rect {
    apply_border(frame, area, border, None, is_focused, None)
}

pub fn apply_themed_border(
    frame: &mut Frame,
    area: Rect,
    border: Option<&BorderSpec>,
    theme: &WidgetTheme,
    is_focused: bool,
    title: Option<&str>,
) -> Rect {
    apply_border(frame, area, border, Some(theme), is_focused, title)
}
