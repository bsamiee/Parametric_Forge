# Title         : dev-tools.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/languages/dev-tools.nix
# ----------------------------------------------------------------------------
# Language-agnostic tooling: linters, formatters, and helpers shared across multiple ecosystems.
{
  config,
  pkgs,
  ...
}: {
  home = {
    # Codex CLI ships inside ChatGPT.app and updates with it; the bundle's launcher follows this link back to its CodexCLI.app.
    file.".local/bin/codex".source = config.lib.file.mkOutOfStoreSymlink "/Applications/ChatGPT.app/Contents/Resources/codex-cli/bin/codex";

    packages = with pkgs; [
      # --- [SHELL_TOOLING]
      bash # Bash runtime for generated scripts and explicit bash sessions
      shellcheck # POSIX shell static analysis
      shfmt # Shell formatter

      # --- [GENERAL_DATA_TOOLS]
      qsv # High-performance CSV and tabular data toolkit

      # --- [CLOUD_IAC]
      google-cloud-sdk # Google Cloud CLI for OAuth/API bootstrap and project administration
      gws # Google Workspace CLI for scripted and batch Workspace administration
    ];
  };
}
