// Title         : components/registry.rs
// Author        : Bardia Samiee
// Project       : Parametric Forge Interface
// License       : MIT
// Path          : interface/src/components/registry.rs
// ----------------------------------------------------------------------------

use super::{ActionRouter, Component, ComponentId, ComponentType, EventInterestMask};
use crate::core::{Action, State};
use crate::layouts::{LayoutCache, LayoutType, TabState};
use color_eyre::eyre::Result;
use crossterm::event::Event;
use ratatui::{
    layout::Rect,
    style::{Color, Style},
    text::{Line, Span},
    widgets::{Block, Borders, Tabs},
    Frame,
};
use rustc_hash::FxHashMap;

// --- Component Registry -----------------------------------------------------
pub struct ComponentRegistry {
    components: Vec<(ComponentId, ComponentType, EventInterestMask)>,
    id_to_index: FxHashMap<ComponentId, usize>,
    layout: Option<LayoutType>,
    router: ActionRouter,
    layout_cache: LayoutCache,
}

impl ComponentRegistry {
    pub fn new() -> Self {
        Self {
            components: Vec::with_capacity(8),
            id_to_index: FxHashMap::default(),
            layout: None,
            router: ActionRouter::new(),
            layout_cache: LayoutCache::new(),
        }
    }

    pub fn set_layout(&mut self, layout: LayoutType) {
        self.layout = Some(layout);
    }

    pub fn register(&mut self, id: ComponentId, mut component: ComponentType, state: &mut State) -> Result<()> {
        if self.id_to_index.contains_key(&id) {
            return Ok(());
        }

        let tx = self.router.register(id.clone());
        component.register_action_handler(tx)?;
        component.init(Rect::default())?;

        if component.can_focus() {
            state.register_component(id.clone(), true);
        }

        let index = self.components.len();
        let interest_mask = component.event_interest();

        self.components.push((id.clone(), component, interest_mask));
        self.id_to_index.insert(id, index);

        Ok(())
    }

    pub fn unregister(&mut self, id: &ComponentId, state: &mut State) -> Option<ComponentType> {
        state.unregister_component(id);
        let index = self.id_to_index.remove(id)?;
        let (_, component, _) = self.components.swap_remove(index);

        if index < self.components.len() {
            let swapped_id = &self.components[index].0;
            self.id_to_index.insert(swapped_id.clone(), index);
        }

        self.router.unregister(id);
        Some(component)
    }

    #[inline]
    fn get_component(&self, id: &ComponentId) -> Option<&ComponentType> {
        self.id_to_index
            .get(id)
            .and_then(|&idx| self.components.get(idx).map(|(_, c, _)| c))
    }

    #[inline]
    fn get_component_mut(&mut self, id: &ComponentId) -> Option<&mut ComponentType> {
        self.id_to_index
            .get(id)
            .and_then(|&idx| self.components.get_mut(idx).map(|(_, c, _)| c))
    }

    pub fn handle_event(&mut self, event: Event, state: &State) -> Result<Option<Action>> {
        if let Some(focused_id) = state.ui.get_focused_component() {
            if let Some(&index) = self.id_to_index.get(focused_id) {
                if let Some((_, component, interest_mask)) = self.components.get_mut(index) {
                    if interest_mask.matches(&event) {
                        return component.handle_events(Some(event));
                    }
                }
            }
        }
        Ok(None)
    }

    pub fn broadcast_event(&mut self, event: Event) -> Result<Vec<Action>> {
        let mut actions = Vec::new();
        for (_, component, interest_mask) in &mut self.components {
            if interest_mask.matches(&event) {
                if let Some(action) = component.handle_events(Some(event.clone()))? {
                    actions.push(action);
                }
            }
        }
        Ok(actions)
    }

    pub fn update(&mut self, action: Action, _state: &State) -> Result<Vec<Action>> {
        let mut follow_ups = Vec::new();

        match action {
            Action::Batch(actions) => {
                for action in actions {
                    for (_, component, _) in &mut self.components {
                        if let Some(follow_up) = component.update(action.clone())? {
                            follow_ups.push(follow_up);
                        }
                    }
                }
            }
            _ => {
                for (_, component, _) in &mut self.components {
                    if let Some(follow_up) = component.update(action.clone())? {
                        follow_ups.push(follow_up);
                    }
                }
            }
        }

        Ok(follow_ups)
    }

    pub fn calculate_layout(&mut self, area: Rect, state: &State) -> Option<crate::core::LayoutStateUpdates> {
        self.layout
            .as_ref()
            .map(|layout| {
                let state_hash = state.layout_hash();
                self.layout_cache
                    .get_or_calculate(area, state_hash, || layout.calculate(area, state))
                    .state_updates
                    .clone()
            })
            .flatten()
    }

    pub fn render(&mut self, frame: &mut Frame, area: Rect, state: &State) -> Result<()> {
        if let Some(layout) = &self.layout {
            let state_hash = state.layout_hash();
            let needs_recalc =
                self.layout_cache.last_area != Some(area) || self.layout_cache.last_state_hash != Some(state_hash);

            if needs_recalc {
                let layout_calc = layout.calculate(area, state);
                self.layout_cache.last_area = Some(area);
                self.layout_cache.last_state_hash = Some(state_hash);
                self.layout_cache.cached_calculation = Some(layout_calc);
            }

            // Extract data from cache before mutable borrows
            let (tab_state, z_order, areas, visible, borders) = {
                let calc = self.layout_cache.cached_calculation.as_ref().unwrap();
                (
                    calc.result.tab_state.clone(),
                    calc.result.z_order.clone(),
                    calc.result.areas.clone(),
                    calc.result.visible.clone(),
                    calc.result.borders.clone(),
                )
            };

            if let Some(ref tab_state) = tab_state {
                self.draw_tab_bar(frame, tab_state);
            }

            let components_to_draw = if !z_order.is_empty() {
                z_order
            } else {
                self.components.iter().map(|(id, _, _)| id.clone()).collect::<Vec<_>>()
            };

            for id in &components_to_draw {
                if let (Some(component_area), true, border_spec) =
                    (areas.get(id).copied(), visible.contains(id), borders.get(id).cloned())
                {
                    if let Some(component) = self.get_component_mut(id) {
                        component.draw(frame, component_area, border_spec.as_ref())?;
                    }
                }
            }
        } else {
            if let Some(component) = self.get_component_mut(&ComponentId::Root) {
                component.draw(frame, area, None)?;
            } else if let Some(focused_id) = state.ui.get_focused_component() {
                if let Some(component) = self.get_component_mut(focused_id) {
                    component.draw(frame, area, None)?;
                }
            }
        }
        Ok(())
    }

    fn draw_tab_bar(&self, frame: &mut Frame, tab_state: &TabState) {
        let titles: Vec<Line> = tab_state
            .tabs
            .iter()
            .enumerate()
            .map(|(i, (_, label))| {
                if i == tab_state.active {
                    Line::from(vec![Span::styled(label.as_str(), Style::default().fg(Color::Yellow))])
                } else {
                    Line::from(label.as_str())
                }
            })
            .collect();

        let tabs = Tabs::new(titles)
            .block(Block::default().borders(Borders::BOTTOM))
            .style(Style::default().fg(Color::White))
            .highlight_style(Style::default().fg(Color::Yellow))
            .select(tab_state.active);

        frame.render_widget(tabs, tab_state.bar_area);
    }

    pub fn handle_focus_change(
        &mut self,
        old_focus: Option<&ComponentId>,
        new_focus: Option<&ComponentId>,
    ) -> Result<()> {
        if let Some(old_id) = old_focus {
            if let Some(component) = self.get_component_mut(old_id) {
                component.on_blur()?;
            }
        }
        if let Some(new_id) = new_focus {
            if let Some(component) = self.get_component_mut(new_id) {
                component.on_focus()?;
            }
        }
        Ok(())
    }

    pub fn poll_action(&mut self) -> Option<Action> {
        self.router.poll_action()
    }
}
