// Title         : app.rs
// Author        : Bardia Samiee
// Project       : Parametric Forge Interface
// License       : MIT
// Path          : interface/src/app.rs
// ----------------------------------------------------------------------------
//! Main application struct and lifecycle management.

use color_eyre::eyre::{Result, WrapErr};
use std::time::Duration;

use crate::components::{
    ComponentId, ComponentRegistry, ComponentType, FooterComponent, HeaderComponent, MainComponent,
};
use crate::core::{map_event, process, Action, Mode, State};
use crate::layouts::{LayoutBuilder, LayoutType};
use crate::persistence::StatePersistence;
use crate::runtime::{EffectExecutor, TerminalRuntime};

// --- Application ------------------------------------------------------------
pub struct App {
    pub state: State,
    runtime: TerminalRuntime,
    executor: EffectExecutor,
    registry: ComponentRegistry,
    persistence: StatePersistence,
}

impl App {
    pub fn new(context: crate::core::Context, config: serde_json::Value) -> Result<Self> {
        // Initialize persistence with platform-specific directories
        let persistence = StatePersistence::new().wrap_err("Failed to initialize state persistence")?;

        // The config passed in already contains merged defaults + saved state
        // (handled by nix.rs get_context_and_config)

        // Determine initial mode
        let mode = if !context.has_nix {
            Mode::NixInstall
        } else if !context.has_config {
            Mode::Configure
        } else {
            Mode::Manage
        };

        let state = State::new(mode.clone(), context.clone(), config);

        // Create registry as pure orchestrator
        let registry = ComponentRegistry::new();

        let mut app = Self {
            state,
            runtime: TerminalRuntime::new().wrap_err("Failed to initialize terminal runtime")?,
            executor: EffectExecutor::new(),
            registry,
            persistence,
        };

        // Set initial layout based on mode
        let mode_clone = mode.clone();
        app.setup_layout(mode)
            .wrap_err_with(|| format!("Failed to setup layout for mode: {:?}", mode_clone))?;

        Ok(app)
    }

    pub async fn run(&mut self) -> Result<()> {
        // Start the async effect worker
        self.executor.start_worker();

        loop {
            // Update layout cache before layout calculations
            self.state.update_layout_cache();

            // Get layout updates if state changed (uses cache)
            let terminal_area = self.runtime.area().wrap_err("Failed to get terminal area")?;
            let layout_updates = self.registry.calculate_layout(terminal_area, &self.state);

            // Apply layout updates to state before rendering
            if let Some(updates) = layout_updates {
                self.state.apply_layout_updates(updates);
            }

            // Render with updated state (will use cached layout from calculate_layout above)
            self.runtime
                .draw(|f| {
                    let _ = self.registry.render(f, f.area(), &self.state);
                })
                .wrap_err("Failed to render frame")?;

            // Check exit condition
            if self.state.should_quit() {
                // Save state before exiting
                let _ = self.persistence.save(&self.state.config);
                break;
            }

            // Poll for next action with priority: effects > components > events
            if let Some(action) = self.poll_next_action().await? {
                self.handle_action(action).await?;
            }
        }
        Ok(())
    }

    async fn poll_next_action(&mut self) -> Result<Option<Action>> {
        // Priority order: effects > components > events
        if let Some(action) = self.executor.poll_pending().await? {
            return Ok(Some(action));
        }

        if let Some(action) = self.registry.poll_action() {
            return Ok(Some(action));
        }

        if let Some(event) = self.runtime.poll_event(Duration::from_millis(50))? {
            // Try component event handling first
            if let Ok(Some(action)) = self.registry.handle_event(event.clone(), &self.state) {
                return Ok(Some(action));
            }
            return Ok(map_event(event, &self.state));
        }

        Ok(None)
    }

    async fn handle_action(&mut self, action: Action) -> Result<()> {
        // Update components first
        let follow_ups = self.registry.update(action.clone(), &self.state)?;

        // Process core action
        let (transition, effect) = process(action, &self.state);

        // Apply state transition and handle focus changes
        if let Some(t) = transition {
            if let Some(focus_change) = self.state.transition(t) {
                // Notify components of focus change
                self.registry
                    .handle_focus_change(focus_change.old_focus.as_ref(), focus_change.new_focus.as_ref())?;
            }
        }

        // Handle side effects
        if let Some(e) = effect {
            if let Some(follow_up) = self.executor.execute(e).await? {
                Box::pin(self.handle_action(follow_up)).await?;
            }
        }

        // Process follow-up actions from components
        for action in follow_ups {
            Box::pin(self.handle_action(action)).await?;
        }

        Ok(())
    }

    fn setup_layout(&mut self, mode: Mode) -> Result<()> {
        // Set up the layout structure
        let layout = match mode {
            Mode::NixInstall => LayoutType::Builder(
                LayoutBuilder::vertical()
                    .add(ComponentId::Main, ratatui::layout::Constraint::Percentage(100))
                    .margin(2),
            ),
            Mode::Configure | Mode::Manage => LayoutType::Builder(
                LayoutBuilder::vertical()
                    .add(ComponentId::Header, ratatui::layout::Constraint::Length(3))
                    .add(ComponentId::Main, ratatui::layout::Constraint::Min(10))
                    .add(ComponentId::Footer, ratatui::layout::Constraint::Length(3))
                    .margin(1),
            ),
        };

        self.registry.set_layout(layout);

        // Create and register actual components based on mode
        match mode {
            Mode::NixInstall => {
                // Just the main component for install mode
                let main_component = ComponentType::Main(MainComponent {});
                self.registry
                    .register(ComponentId::Main, main_component, &mut self.state)?;
            }
            Mode::Configure | Mode::Manage => {
                // Register all three components for configure/manage modes
                let header_component = ComponentType::Header(HeaderComponent {});
                let main_component = ComponentType::Main(MainComponent {});
                let footer_component = ComponentType::Footer(FooterComponent {});

                self.registry
                    .register(ComponentId::Header, header_component, &mut self.state)?;
                self.registry
                    .register(ComponentId::Main, main_component, &mut self.state)?;
                self.registry
                    .register(ComponentId::Footer, footer_component, &mut self.state)?;
            }
        }

        Ok(())
    }
}
