# Title         : notebooklm.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /modules/home/programs/shell-tools/notebooklm.nix
# ----------------------------------------------------------------------------
# Durable `notebooklm-mcp` launcher (PleasePrompto NotebookLM MCP server) on PATH.
# Portable across local and remote hosts via npx, exposing the bare-binary
# command name the Maghz MCP fleet (`command: "notebooklm-mcp"`) expects.
{pkgs, ...}: let
  notebooklmMcp = pkgs.writeShellApplication {
    name = "notebooklm-mcp";
    runtimeInputs = [pkgs.nodejs];
    text = ''
      # Durable runtime defaults; any MCP client `env` block still overrides via :- fallback.
      export NOTEBOOKLM_AI_MARKER="''${NOTEBOOKLM_AI_MARKER:-false}"
      export SESSION_TIMEOUT="''${SESSION_TIMEOUT:-3600}"
      exec npx -y notebooklm-mcp@latest "$@"
    '';
  };
in {
  home.packages = [notebooklmMcp];
}
