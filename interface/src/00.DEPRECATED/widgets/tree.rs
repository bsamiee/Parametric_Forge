// Title         : widgets/tree.rs
// Author        : Bardia Samiee
// Project       : Parametric Forge Interface
// License       : MIT
// Path          : interface/src/widgets/tree.rs
// ----------------------------------------------------------------------------

//! Tree widget for hierarchical data display with expand/collapse functionality

use color_eyre::eyre::Result;
use crossterm::event::{Event, KeyCode};
use indexmap::IndexMap;
use ratatui::{
    layout::Rect,
    style::{Color, Style},
    text::{Line, Span},
    widgets::{List, ListItem, ListState},
    Frame,
};
use std::collections::{hash_map::DefaultHasher, HashSet};
use std::hash::{Hash, Hasher};
use std::path::{Path, PathBuf};
use std::sync::mpsc::Sender;

use super::{apply_themed_border, FocusManager, FocusStyle, WidgetConfig, WidgetState};
use crate::components::{Component, EventInterestMask};
use crate::core::{Action, Direction};
use crate::layouts::BorderSpec;

// --- File Metadata ----------------------------------------------------------

#[derive(Debug, Clone)]
pub struct FileMeta {
    pub git_status: Option<char>, // 'M', 'A', 'D', '?', '!'
    pub icon: &'static str,       // NerdFont icon
    pub is_symlink: bool,
    pub size: Option<u64>,
}

impl FileMeta {
    fn for_path(path: &Path, git_map: &IndexMap<PathBuf, char>) -> Self {
        let git_status = git_map.get(path).copied();
        let icon = Self::get_icon(path);
        let metadata = path.metadata().ok();

        Self {
            git_status,
            icon,
            is_symlink: metadata.as_ref().map_or(false, |m| m.file_type().is_symlink()),
            size: metadata
                .as_ref()
                .and_then(|m| if m.is_file() { Some(m.len()) } else { None }),
        }
    }

    fn get_icon(path: &Path) -> &'static str {
        if path.is_dir() {
            ""
        } else {
            match path.extension().and_then(|e| e.to_str()) {
                Some("rs") => "",
                Some("nix") => "",
                Some("toml") | Some("yaml") | Some("yml") => "",
                Some("md") => "",
                Some("json") => "",
                Some("js") | Some("jsx") | Some("ts") | Some("tsx") => "",
                Some("py") => "",
                Some("sh") | Some("bash") | Some("zsh") => "",
                Some("txt") => "",
                _ => "",
            }
        }
    }
}

// --- Tree Node Data Structure -----------------------------------------------

#[derive(Debug, Clone)]
pub struct TreeNode {
    pub id: String,
    pub label: String,
    pub children: Vec<TreeNode>,
    pub is_leaf: bool,
    pub data: Option<String>,        // Optional data payload
    pub file_meta: Option<FileMeta>, // NEW: File metadata including Git status
}

impl TreeNode {
    pub fn new(id: String, label: String) -> Self {
        Self {
            id,
            label,
            children: Vec::new(),
            is_leaf: true,
            data: None,
            file_meta: None,
        }
    }

    pub fn with_children(mut self, children: Vec<TreeNode>) -> Self {
        self.is_leaf = children.is_empty();
        self.children = children;
        self
    }

    pub fn with_data(mut self, data: String) -> Self {
        self.data = Some(data);
        self
    }

    pub fn from_path(path: &Path) -> Result<Self> {
        // Use empty git map for backward compatibility
        let git_map = IndexMap::new();
        Self::from_path_with_git(path, &git_map)
    }

    pub fn from_path_with_git(path: &Path, git_map: &IndexMap<PathBuf, char>) -> Result<Self> {
        let label = path.file_name().and_then(|n| n.to_str()).unwrap_or("?").to_string();

        let id = path.to_string_lossy().to_string();
        let file_meta = Some(FileMeta::for_path(path, git_map));

        if path.is_dir() {
            let mut children = Vec::new();
            if let Ok(entries) = std::fs::read_dir(path) {
                for entry in entries.flatten() {
                    // Skip hidden files/directories (starting with .)
                    if let Some(name) = entry.file_name().to_str() {
                        if name.starts_with('.') && name != ".." {
                            continue;
                        }
                    }
                    if let Ok(child_node) = Self::from_path_with_git(&entry.path(), git_map) {
                        children.push(child_node);
                    }
                }
            }
            children.sort_by(|a, b| {
                // Directories first, then files, both alphabetically
                match (a.is_leaf, b.is_leaf) {
                    (false, true) => std::cmp::Ordering::Less,
                    (true, false) => std::cmp::Ordering::Greater,
                    _ => a.label.cmp(&b.label),
                }
            });
            let mut node = Self::new(id, label).with_children(children);
            node.file_meta = file_meta;
            Ok(node)
        } else {
            let mut node = Self::new(id, label);
            node.file_meta = file_meta;
            Ok(node)
        }
    }
}

// --- Tree Configuration -----------------------------------------------------

crate::widget_config! {
    pub struct TreeConfig {
        pub show_icons: bool = true,
        pub indent_size: usize = 2,
        pub expand_symbol: String = "▶".to_string(),
        pub collapse_symbol: String = "▼".to_string(),
        pub leaf_symbol: String = "•".to_string()
    }
}

// --- Tree State -------------------------------------------------------------

#[derive(Debug, Clone, PartialEq)]
pub struct TreeState {
    pub expanded: HashSet<String>,
    pub selected: Option<usize>,
    pub is_focused: bool,
    pub scroll_offset: usize,
}

impl Default for TreeState {
    fn default() -> Self {
        Self {
            expanded: HashSet::new(),
            selected: None,
            is_focused: false,
            scroll_offset: 0,
        }
    }
}

impl WidgetState for TreeState {
    fn reset(&mut self) {
        self.expanded.clear();
        self.selected = None;
        self.scroll_offset = 0;
    }

    fn is_dirty(&self) -> bool {
        // Tree is dirty if selection exists or nodes are expanded
        self.selected.is_some() || !self.expanded.is_empty()
    }

    fn get_change_flags(&self) -> super::WidgetChangeFlags {
        super::WidgetChangeFlags {
            content_changed: !self.expanded.is_empty(),
            selection_changed: self.selected.is_some(),
            focus_changed: self.is_focused,
            layout_changed: false,
            style_changed: self.is_focused,
        }
    }
}

impl super::FocusManager for TreeState {
    fn is_widget_focused(&self) -> bool {
        self.is_focused
    }

    fn set_widget_focused(&mut self, focused: bool) {
        self.is_focused = focused;
    }
}

impl super::StandardFocusManager for TreeState {
    fn get_selected(&self) -> Option<usize> {
        self.selected
    }

    fn set_selected(&mut self, idx: Option<usize>) {
        self.selected = idx;
    }
}

// --- Flattened Tree Item for Rendering --------------------------------------

#[derive(Debug, Clone)]
struct FlatTreeItem {
    node_id: String,
    label: String,
    depth: usize,
    is_expanded: bool,
    is_leaf: bool,
    data: Option<String>,
    file_meta: Option<FileMeta>,
}

// --- Consolidated Tree Cache -----------------------------------------------

#[derive(Debug, Default)]
struct TreeCache {
    flat_items: Option<Vec<FlatTreeItem>>,
    state_hash: u64,
    filter_hash: u64,
    render_state: Option<TreeState>,
    render_area: Option<Rect>,
    is_dirty: bool,
}

impl TreeCache {
    fn invalidate(&mut self) {
        self.flat_items = None;
        self.is_dirty = true;
    }

    fn is_valid(&self, current_state_hash: u64, current_filter_hash: u64) -> bool {
        !self.is_dirty
            && self.flat_items.is_some()
            && self.state_hash == current_state_hash
            && self.filter_hash == current_filter_hash
    }

    fn update(&mut self, items: Vec<FlatTreeItem>, state_hash: u64, filter_hash: u64) {
        self.flat_items = Some(items);
        self.state_hash = state_hash;
        self.filter_hash = filter_hash;
        self.is_dirty = false;
    }

    fn should_render(&self, current_state: &TreeState, current_area: Rect) -> bool {
        self.render_state.as_ref() != Some(current_state) || self.render_area.map_or(true, |area| area != current_area)
    }

    fn update_render_tracking(&mut self, state: TreeState, area: Rect) {
        self.render_state = Some(state);
        self.render_area = Some(area);
    }
}

// --- Navigation Actions ----------------------------------------------------

#[derive(Debug, Clone)]
enum NavigationAction {
    Move(Direction),
    Expand(String),
    Collapse(String),
    Toggle(String),
}

/// Generic hash calculation function
fn calculate_hash<T: Hash>(data: &T) -> u64 {
    let mut hasher = DefaultHasher::new();
    data.hash(&mut hasher);
    hasher.finish()
}

// --- Tree Widget ------------------------------------------------------------

pub struct TreeWidget {
    nodes: Vec<TreeNode>,
    config: TreeConfig,
    state: TreeState,
    list_state: ListState,
    action_tx: Option<Sender<Action>>,
    filter_pattern: Option<String>,
    cache: TreeCache,
}

impl TreeWidget {
    pub fn new(nodes: Vec<TreeNode>) -> Self {
        Self {
            nodes,
            config: TreeConfig::default(),
            state: TreeState::default(),
            list_state: ListState::default(),
            action_tx: None,
            filter_pattern: None,
            cache: TreeCache::default(),
        }
    }

    /// Check if widget has any items
    fn has_items(&self) -> bool {
        !self.nodes.is_empty()
    }

    pub fn with_config(mut self, config: TreeConfig) -> Self {
        self.config = config;
        self
    }

    pub fn from_directory<P: AsRef<Path>>(path: P) -> Result<Self> {
        // Try to get git status, fallback to empty map
        let git_status = crate::git::get_git_status_sync(path.as_ref()).unwrap_or_default();
        let root_node = TreeNode::from_path_with_git(path.as_ref(), &git_status)?;
        Ok(Self::new(vec![root_node]))
    }

    pub fn set_filter(&mut self, pattern: String) {
        self.filter_pattern = if pattern.is_empty() { None } else { Some(pattern) };
        self.state.selected = None;
        self.list_state.select(None);
        self.cache.invalidate();
    }

    pub fn clear_filter(&mut self) {
        self.filter_pattern = None;
        self.state.selected = None;
        self.list_state.select(None);
        self.cache.invalidate();
    }

    // --- Optimized Cache Management ----------------------------------------

    fn get_current_hashes(&self) -> (u64, u64) {
        let mut expanded_vec: Vec<&String> = self.state.expanded.iter().collect();
        expanded_vec.sort();

        let state_hash = calculate_hash(&expanded_vec);
        let filter_hash = calculate_hash(&self.filter_pattern);

        (state_hash, filter_hash)
    }

    pub fn selected_node(&mut self) -> Option<String> {
        let selected_idx = self.state.selected?;
        let flat_items = self.get_or_compute_flat_items();
        flat_items.get(selected_idx).map(|item| item.node_id.clone())
    }

    pub fn selected_data(&mut self) -> Option<String> {
        let selected_idx = self.state.selected?;
        let flat_items = self.get_or_compute_flat_items();
        flat_items.get(selected_idx).and_then(|item| item.data.clone())
    }

    fn get_or_compute_flat_items(&mut self) -> &Vec<FlatTreeItem> {
        let (state_hash, filter_hash) = self.get_current_hashes();

        if !self.cache.is_valid(state_hash, filter_hash) {
            let mut items = Vec::new();
            for node in &self.nodes {
                self.flatten_node(node, 0, &mut items);
            }
            self.cache.update(items, state_hash, filter_hash);
        }

        self.cache.flat_items.as_ref().unwrap()
    }

    fn flatten_node(&self, node: &TreeNode, depth: usize, items: &mut Vec<FlatTreeItem>) {
        let is_expanded = self.state.expanded.contains(&node.id);

        // Apply filter if set
        if let Some(ref pattern) = self.filter_pattern {
            // For directories, check if any descendant matches
            if !node.is_leaf {
                let has_matching_descendant = self.node_has_matching_descendant(node, pattern);
                if !has_matching_descendant {
                    return; // Skip this entire branch
                }
            } else {
                // For files, check direct match
                if !node.label.to_lowercase().contains(&pattern.to_lowercase()) {
                    return; // Skip this leaf
                }
            }
        }

        items.push(FlatTreeItem {
            node_id: node.id.clone(),
            label: node.label.clone(),
            depth,
            is_expanded,
            is_leaf: node.is_leaf,
            data: node.data.clone(),
            file_meta: node.file_meta.clone(), // Include metadata
        });

        if is_expanded && !node.is_leaf {
            for child in &node.children {
                self.flatten_node(child, depth + 1, items);
            }
        }
    }

    fn node_has_matching_descendant(&self, node: &TreeNode, pattern: &str) -> bool {
        // Check if the node itself matches
        if node.label.to_lowercase().contains(&pattern.to_lowercase()) {
            return true;
        }

        // Check all descendants
        for child in &node.children {
            if self.node_has_matching_descendant(child, pattern) {
                return true;
            }
        }

        false
    }

    fn toggle_expand(&mut self, node_id: &str) {
        if self.state.expanded.contains(node_id) {
            self.state.expanded.remove(node_id);
        } else {
            self.state.expanded.insert(node_id.to_string());
        }
        self.cache.invalidate();
    }

    fn handle_navigation(&mut self, action: NavigationAction) -> Option<Action> {
        match action {
            NavigationAction::Move(direction) => {
                let (len, current) = {
                    let flat_items = self.get_or_compute_flat_items();
                    if flat_items.is_empty() {
                        return None;
                    }
                    (flat_items.len(), self.state.selected.unwrap_or(0))
                };

                let new_idx = crate::core::calculate_index(current, len, direction);
                self.state.selected = Some(new_idx);
                self.list_state.select(Some(new_idx));
                None
            }
            NavigationAction::Expand(node_id)
            | NavigationAction::Collapse(node_id)
            | NavigationAction::Toggle(node_id) => {
                self.toggle_expand(&node_id);
                None
            }
        }
    }

    fn navigate(&mut self, direction: Direction) -> Option<Action> {
        let current = self.state.selected.unwrap_or(0);

        // First, get the data we need without holding any borrows
        let (is_empty, expand_node, collapse_node, parent_idx) = {
            let flat_items = self.get_or_compute_flat_items();

            if flat_items.is_empty() {
                return None;
            }

            let current_item = flat_items.get(current);

            let expand_node = if direction == Direction::Right {
                current_item
                    .filter(|item| !item.is_leaf && !item.is_expanded)
                    .map(|item| item.node_id.clone())
            } else {
                None
            };

            let collapse_node = if direction == Direction::Left {
                current_item
                    .filter(|item| !item.is_leaf && item.is_expanded)
                    .map(|item| item.node_id.clone())
            } else {
                None
            };

            let parent_idx = if direction == Direction::Left && expand_node.is_none() && collapse_node.is_none() {
                current_item.filter(|item| item.depth > 0).and_then(|item| {
                    flat_items
                        .iter()
                        .enumerate()
                        .rev()
                        .find(|(idx, parent_item)| *idx < current && parent_item.depth < item.depth)
                        .map(|(idx, _)| idx)
                })
            } else {
                None
            };

            (false, expand_node, collapse_node, parent_idx)
        };

        // Now handle the navigation without holding any borrows
        if let Some(node_id) = expand_node {
            self.handle_navigation(NavigationAction::Expand(node_id))
        } else if let Some(node_id) = collapse_node {
            self.handle_navigation(NavigationAction::Collapse(node_id))
        } else if let Some(idx) = parent_idx {
            self.state.selected = Some(idx);
            self.list_state.select(Some(idx));
            None
        } else {
            match direction {
                Direction::Right | Direction::Left => None,
                _ => self.handle_navigation(NavigationAction::Move(direction)),
            }
        }
    }

    fn render_tree_items(&mut self) -> Vec<ListItem<'static>> {
        let RenderConfig {
            indent_size,
            show_icons,
            leaf_symbol,
            collapse_symbol,
            expand_symbol,
        } = RenderConfig::from_tree_config(&self.config);

        let flat_items = self.get_or_compute_flat_items();

        flat_items
            .iter()
            .map(|item| {
                let indent = " ".repeat(item.depth * indent_size);
                let symbol = Self::get_item_symbol(item, &leaf_symbol, &collapse_symbol, &expand_symbol);
                let (symbol_style, label_style) = Self::get_item_styles(item);

                let mut spans = vec![Span::raw(indent)];

                if show_icons {
                    spans.push(Span::styled(symbol, symbol_style));
                    spans.push(Span::raw(" "));
                }
                spans.push(Span::styled(item.label.clone(), label_style));

                ListItem::new(Line::from(spans))
            })
            .collect()
    }

    fn get_item_symbol(item: &FlatTreeItem, leaf: &str, collapse: &str, expand: &str) -> String {
        if let Some(ref meta) = item.file_meta {
            meta.icon.to_string()
        } else if item.is_leaf {
            leaf.to_string()
        } else if item.is_expanded {
            collapse.to_string()
        } else {
            expand.to_string()
        }
    }

    fn get_item_styles(item: &FlatTreeItem) -> (Style, Style) {
        if let Some(ref meta) = item.file_meta {
            let color = crate::git::status_color(meta.git_status);
            (Style::default().fg(color), Style::default().fg(color))
        } else {
            (Style::default().fg(Color::Cyan), Style::default())
        }
    }
}

// --- Render Configuration Helper --------------------------------------------

struct RenderConfig {
    indent_size: usize,
    show_icons: bool,
    leaf_symbol: String,
    collapse_symbol: String,
    expand_symbol: String,
}

impl RenderConfig {
    fn from_tree_config(config: &TreeConfig) -> Self {
        Self {
            indent_size: config.indent_size,
            show_icons: config.show_icons,
            leaf_symbol: config.leaf_symbol.clone(),
            collapse_symbol: config.collapse_symbol.clone(),
            expand_symbol: config.expand_symbol.clone(),
        }
    }
}

// --- NavigableWidget Implementation -----------------------------------------

impl super::NavigableWidget for TreeWidget {
    fn get_item_count(&self) -> usize {
        // We need to compute this without mutating self
        let (state_hash, filter_hash) = self.get_current_hashes();
        if let Some(items) = &self.cache.flat_items {
            if self.cache.is_valid(state_hash, filter_hash) {
                return items.len();
            }
        }
        // If cache is invalid, estimate based on nodes count
        self.nodes.len()
    }

    fn get_selected(&self) -> Option<usize> {
        self.state.selected
    }

    fn set_selected(&mut self, idx: Option<usize>) {
        self.state.selected = idx;
        if let Some(selected) = idx {
            self.list_state.select(Some(selected));
        } else {
            self.list_state.select(None);
        }
    }
}

impl Component for TreeWidget {
    fn register_action_handler(&mut self, tx: Sender<Action>) -> Result<()> {
        self.action_tx = Some(tx);
        Ok(())
    }

    fn can_focus(&self) -> bool {
        self.config.widget.focusable
    }

    fn on_focus(&mut self) -> Result<()> {
        self.state.set_widget_focused(true);
        // Initialize selection if none exists
        if self.state.selected.is_none() && !self.nodes.is_empty() {
            self.state.selected = Some(0);
            self.list_state.select(Some(0));
        }
        Ok(())
    }

    fn on_blur(&mut self) -> Result<()> {
        self.state.set_widget_focused(false);
        Ok(())
    }
    fn event_interest(&self) -> EventInterestMask {
        // Tree widget is interested in key presses for navigation and mouse clicks for selection
        EventInterestMask::KEY_PRESS
            .with(EventInterestMask::MOUSE_CLICK)
            .with(EventInterestMask::FOCUS_EVENTS)
    }

    fn handle_events(&mut self, event: Option<Event>) -> Result<Option<Action>> {
        if let Some(Event::Key(key)) = event {
            match key.code {
                KeyCode::Enter => {
                    if let Some(selected_idx) = self.state.selected {
                        let (is_leaf, node_id) = {
                            let flat_items = self.get_or_compute_flat_items();
                            if let Some(item) = flat_items.get(selected_idx) {
                                (item.is_leaf, item.node_id.clone())
                            } else {
                                return Ok(None);
                            }
                        };

                        if is_leaf {
                            if let Some(tx) = &self.action_tx {
                                let _ = tx.send(Action::Select);
                            }
                            return Ok(Some(Action::Select));
                        } else {
                            self.handle_navigation(NavigationAction::Toggle(node_id));
                            return Ok(None);
                        }
                    }
                    Ok(None)
                }
                KeyCode::Char(' ') => {
                    if let Some(selected_idx) = self.state.selected {
                        let node_id = {
                            let flat_items = self.get_or_compute_flat_items();
                            if let Some(item) = flat_items.get(selected_idx) {
                                if !item.is_leaf {
                                    Some(item.node_id.clone())
                                } else {
                                    None
                                }
                            } else {
                                None
                            }
                        };

                        if let Some(node_id) = node_id {
                            self.handle_navigation(NavigationAction::Toggle(node_id));
                        }
                    }
                    Ok(None)
                }
                _ => {
                    // Let core handle standard navigation
                    Ok(None)
                }
            }
        } else {
            Ok(None)
        }
    }

    fn update(&mut self, action: Action) -> Result<Option<Action>> {
        match action {
            Action::Move(direction) => {
                self.navigate(direction);
                Ok(None)
            }
            _ => Ok(None),
        }
    }

    fn draw(&mut self, frame: &mut Frame, area: Rect, border: Option<&BorderSpec>) -> Result<()> {
        if !self.cache.should_render(&self.state, area) {
            return Ok(());
        }

        let items = self.render_tree_items();
        let theme = &self.config.widget.theme;
        let title = self.config.widget.title.as_deref();
        let is_focused = self.state.is_focused;

        let render_area = apply_themed_border(frame, area, border, theme, is_focused, title);
        let style = FocusStyle::text(theme, is_focused, false);
        let highlight_style = FocusStyle::selection(theme, is_focused);

        let list = List::new(items).style(style).highlight_style(highlight_style);
        frame.render_stateful_widget(list, render_area, &mut self.list_state);

        self.cache.update_render_tracking(self.state.clone(), area);
        Ok(())
    }
}
