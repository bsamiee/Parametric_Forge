// Title         : runtime/executor.rs
// Author        : Bardia Samiee
// Project       : Parametric Forge Interface
// License       : MIT
// Path          : interface/src/runtime/executor.rs
// ----------------------------------------------------------------------------

use crate::core::{Action, Effect, NixCommand};
use crate::nix;
use color_eyre::eyre::{Result, WrapErr};
use tokio::sync::mpsc::{unbounded_channel, UnboundedReceiver, UnboundedSender};
use tokio::task::JoinHandle;

// --- Effect Executor --------------------------------------------------------
pub struct EffectExecutor {
    effect_tx: UnboundedSender<PendingEffect>,
    effect_rx: Option<UnboundedReceiver<PendingEffect>>,
    action_tx: UnboundedSender<Action>,
    action_rx: UnboundedReceiver<Action>,
    worker_handle: Option<JoinHandle<()>>,
}

struct PendingEffect {
    effect: Effect,
    retries: u8,
}

impl EffectExecutor {
    pub fn new() -> Self {
        let (effect_tx, effect_rx) = unbounded_channel();
        let (action_tx, action_rx) = unbounded_channel();

        Self {
            effect_tx,
            effect_rx: Some(effect_rx),
            action_tx,
            action_rx,
            worker_handle: None,
        }
    }

    pub fn start_worker(&mut self) {
        if let Some(mut effect_rx) = self.effect_rx.take() {
            let action_tx = self.action_tx.clone();

            let handle = tokio::spawn(async move {
                while let Some(mut pending) = effect_rx.recv().await {
                    // Process effect asynchronously
                    let result = Self::process_effect(&pending.effect).await;

                    match result {
                        Ok(Some(action)) => {
                            let _ = action_tx.send(action);
                        }
                        Err(e) => {
                            // Retry logic
                            if pending.retries < 3 {
                                pending.retries += 1;
                                let _ = action_tx.send(Action::SetError(format!("Retrying: {}", e)));
                                // Re-queue for retry (would need another channel for this)
                            } else {
                                let _ = action_tx.send(Action::SetError(format!("Failed: {}", e)));
                            }
                        }
                        _ => {}
                    }
                }
            });

            self.worker_handle = Some(handle);
        }
    }

    async fn process_effect(effect: &Effect) -> Result<Option<Action>> {
        match effect {
            Effect::Exit => {
                std::process::exit(0);
            }
            Effect::Nix(cmd) => Self::process_nix_command(cmd).await,
        }
    }

    async fn process_nix_command(cmd: &NixCommand) -> Result<Option<Action>> {
        match cmd {
            NixCommand::Build(config) => {
                nix::build_config(&config)
                    .await
                    .wrap_err("Failed to build Nix configuration")?;
                Ok(Some(Action::ClearError))
            }
            NixCommand::Apply => {
                nix::apply_config()
                    .await
                    .wrap_err("Failed to apply Nix configuration")?;
                Ok(Some(Action::ClearError))
            }
            NixCommand::Check => {
                nix::check_config()
                    .await
                    .wrap_err("Failed to check Nix configuration")?;
                Ok(Some(Action::ClearError))
            }
            NixCommand::Format => {
                nix::format_config()
                    .await
                    .wrap_err("Failed to format Nix configuration")?;
                Ok(Some(Action::ClearError))
            }
            NixCommand::Install => {
                // Still synchronous - requires user interaction
                nix::run_installer().wrap_err("Failed to run Nix installer")?;
                Ok(Some(Action::Exit))
            }
            NixCommand::Query(_query) => {
                // Queries will be async when implemented
                Ok(None)
            }
        }
    }

    pub async fn execute(&mut self, effect: Effect) -> Result<Option<Action>> {
        match effect {
            Effect::Exit => {
                std::process::exit(0);
            }
            Effect::Nix(cmd) => self.execute_nix(cmd).await,
        }
    }

    async fn execute_nix(&mut self, cmd: NixCommand) -> Result<Option<Action>> {
        match cmd {
            NixCommand::Install => {
                // Synchronous - requires user interaction
                nix::run_installer().wrap_err("Failed to run Nix installer")?;
                Ok(Some(Action::Exit))
            }
            NixCommand::Build(config) => {
                // Queue for async execution
                self.queue_effect(Effect::Nix(NixCommand::Build(config)));
                Ok(Some(Action::SetStatus("Building configuration...".to_string())))
            }
            NixCommand::Apply => {
                // Queue for async execution
                self.queue_effect(Effect::Nix(NixCommand::Apply));
                Ok(Some(Action::SetStatus("Applying configuration...".to_string())))
            }
            NixCommand::Check => {
                // Queue for async execution
                self.queue_effect(Effect::Nix(NixCommand::Check));
                Ok(Some(Action::SetStatus("Checking configuration...".to_string())))
            }
            NixCommand::Format => {
                // Queue for async execution
                self.queue_effect(Effect::Nix(NixCommand::Format));
                Ok(Some(Action::SetStatus("Formatting configuration...".to_string())))
            }
            NixCommand::Query(_query) => {
                // Queries are synchronous for now
                Ok(None)
            }
        }
    }

    fn queue_effect(&mut self, effect: Effect) {
        let _ = self.effect_tx.send(PendingEffect { effect, retries: 0 });
    }

    pub async fn poll_pending(&mut self) -> Result<Option<Action>> {
        // Try to receive an action from the worker
        match self.action_rx.try_recv() {
            Ok(action) => Ok(Some(action)),
            Err(_) => Ok(None),
        }
    }

    pub fn has_pending(&self) -> bool {
        // Check if there are messages waiting
        !self.action_rx.is_empty()
    }

    pub fn clear_pending(&mut self) {
        // Drain the receiver
        while self.action_rx.try_recv().is_ok() {}
    }
}

impl Drop for EffectExecutor {
    fn drop(&mut self) {
        if let Some(handle) = self.worker_handle.take() {
            handle.abort();
        }
    }
}
