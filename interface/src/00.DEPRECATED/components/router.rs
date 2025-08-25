// Title         : components/router.rs
// Author        : Bardia Samiee
// Project       : Parametric Forge Interface
// License       : MIT
// Path          : interface/src/components/router.rs
// ----------------------------------------------------------------------------

use crate::core::Action;
use rustc_hash::FxHashMap;
use std::sync::mpsc::{channel, Receiver, Sender};
use strum::{Display, EnumString};

// --- Component Identifier ---------------------------------------------------
#[derive(Debug, Clone, PartialEq, Eq, Hash, Display, EnumString)]
pub enum ComponentId {
    Root,
    Header,
    Footer,
    Main,
    Sidebar,
    Custom(String),
}

impl Default for ComponentId {
    fn default() -> Self {
        ComponentId::Root
    }
}

// --- Action Router ----------------------------------------------------------
pub struct ActionRouter {
    component_channels: FxHashMap<ComponentId, (Sender<Action>, Receiver<Action>)>,
    global_rx: Receiver<Action>,
    global_tx: Sender<Action>,
    action_filters: FxHashMap<ComponentId, ActionFilter>,
}

#[derive(Debug, Clone)]
struct ActionFilter {
    allowed_actions: Vec<ActionType>,
    forward_to_global: bool,
}

impl ActionFilter {
    fn new() -> Self {
        Self {
            allowed_actions: Vec::new(),
            forward_to_global: true,
        }
    }

    fn should_forward(&self, action: &Action) -> bool {
        self.allowed_actions.is_empty() || self.allowed_actions.contains(&ActionType::from_action(action))
    }
}

// --- Action Type Classification for Filtering -------------------------------
#[derive(Debug, Clone, PartialEq)]
pub enum ActionType {
    Navigation, // Move, Select, Focus changes
    Input,      // Text input, key events
    System,     // Exit, Error, Status updates
    Nix,        // Nix commands
    Custom,     // Custom component actions
}

impl ActionType {
    fn from_action(action: &Action) -> Self {
        match action {
            Action::Move(_) | Action::Select | Action::SelectIndex(_) | Action::Back => Self::Navigation,
            Action::NextTab | Action::PrevTab | Action::SelectTab(_) => Self::Navigation,
            Action::Input(_) | Action::AppendChar(_) | Action::DeleteChar | Action::Submit => Self::Input,
            Action::Exit | Action::SetError(_) | Action::SetStatus(_) | Action::ClearError => Self::System,
            Action::NixInstall | Action::NixBuild(_) | Action::NixCheck | Action::NixFormat | Action::NixQuery(_) => {
                Self::Nix
            }
            Action::SetMode(_) => Self::System,
            Action::Batch(_) => Self::System, // Batch actions are system-level
            Action::Custom(_) => Self::Custom,
        }
    }
}

impl ActionRouter {
    pub fn new() -> Self {
        let (tx, rx) = channel();
        Self {
            component_channels: FxHashMap::default(),
            global_rx: rx,
            global_tx: tx,
            action_filters: FxHashMap::default(),
        }
    }

    pub fn register(&mut self, id: ComponentId) -> Sender<Action> {
        let (tx, rx) = channel();
        let tx_clone = tx.clone();
        self.action_filters.insert(id.clone(), ActionFilter::new());
        self.component_channels.insert(id, (tx, rx));
        tx_clone
    }

    pub fn set_component_filter(&mut self, id: ComponentId, action_types: Vec<ActionType>) {
        if let Some(filter) = self.action_filters.get_mut(&id) {
            filter.allowed_actions = action_types;
        }
    }

    pub fn unregister(&mut self, id: &ComponentId) {
        self.component_channels.remove(id);
        self.action_filters.remove(id);
    }

    pub fn poll_action(&mut self) -> Option<Action> {
        if let Ok(action) = self.global_rx.try_recv() {
            return Some(action);
        }

        for (component_id, (_, rx)) in &self.component_channels {
            if let Ok(action) = rx.try_recv() {
                if let Some(filter) = self.action_filters.get(component_id) {
                    if filter.should_forward(&action) && filter.forward_to_global {
                        return Some(action);
                    }
                } else {
                    return Some(action);
                }
            }
        }
        None
    }

    pub fn send_to_component(&self, id: &ComponentId, action: Action) -> Result<(), Action> {
        if let Some((tx, _)) = self.component_channels.get(id) {
            if let Some(filter) = self.action_filters.get(id) {
                if filter.should_forward(&action) {
                    tx.send(action).map_err(|e| e.0)
                } else {
                    Err(action)
                }
            } else {
                tx.send(action).map_err(|e| e.0)
            }
        } else {
            Err(action)
        }
    }

    pub fn broadcast(&self, action: Action) {
        for (component_id, (tx, _)) in &self.component_channels {
            if let Some(filter) = self.action_filters.get(component_id) {
                if filter.should_forward(&action) {
                    let _ = tx.send(action.clone());
                }
            } else {
                let _ = tx.send(action.clone());
            }
        }
    }
}
