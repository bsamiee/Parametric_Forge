# Title         : webhook.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/webhook.nix
# ----------------------------------------------------------------------------
# Webhook server (adnanh/webhook) - lightweight HTTP endpoint for triggering scripts

{ config, lib, ... }:

let
  webhookDir = "${config.xdg.configHome}/webhook";

  # Example hooks configuration - user should customize
  exampleHooks = [
    {
      id = "health";
      execute-command = "echo";
      pass-arguments-to-command = [
        { source = "string"; name = "ok"; }
      ];
      include-command-output-in-response = true;
    }
  ];
in
{
  # --- XDG Config Directory ---------------------------------------------------
  xdg.configFile."webhook/.gitkeep".text = "";

  # --- Example Hooks Template -------------------------------------------------
  xdg.configFile."webhook/hooks.example.json".text = builtins.toJSON exampleHooks;

  # --- Activation: Ensure directory structure ---------------------------------
  home.activation.ensureWebhookDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "${webhookDir}/scripts"
    chmod 700 "${webhookDir}"
  '';

  # --- Environment Variables --------------------------------------------------
  home.sessionVariables = {
    WEBHOOK_HOOKS_DIR = webhookDir;
    WEBHOOK_PORT = "9000";
  };
}
