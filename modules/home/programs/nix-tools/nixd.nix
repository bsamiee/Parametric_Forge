# Title         : nixd.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/nix-tools/nixd.nix
# ----------------------------------------------------------------------------
# nixd estate-portal owner (nix-community/nixd, the LSP — distinct from the
# determinate-nixd daemon). Option-completion expressions are generated once
# from the host context; every LSP client (Neovim rows, Claude marketplace)
# consumes these rows instead of hand-maintained strings.
{
  host,
  lib,
  ...
}: let
  flakeRoot = "${host.user.home}/Documents/99.Github/Parametric_Forge";
  # git+file:// forces the git-tree fetcher (never walks .git), so nixd's
  # upstream nix-2.34 fetchers skip the core.fsmonitor unix socket at
  # .git/fsmonitor--daemon.ipc a plain-path copy would choke on.
  flake = ''(builtins.getFlake "git+file://${flakeRoot}")'';
  configClass =
    {
      darwin = "darwinConfigurations";
      nixos = "nixosConfigurations";
    }.${
      host.os
    };
  hostOptions = "${flake}.${configClass}.${host.name}.options";
  optionSetName =
    {
      darwin = "nix-darwin";
      nixos = "nixos";
    }.${
      host.os
    };
in {
  options.forge.lsp = lib.mkOption {
    type = lib.types.raw;
    readOnly = true;
    default = {
      inherit flakeRoot;
      nixd = {
        nixpkgs.expr = "import ${flake}.inputs.nixpkgs { }";
        formatting.command = ["alejandra"];
        options = {
          ${optionSetName}.expr = hostOptions;
          home-manager.expr = "${hostOptions}.home-manager.users.type.getSubOptions [ ]";
          # flake-parts debug output is enabled in flake.nix for this row.
          flake-parts.expr = "${flake}.debug.options";
        };
      };
    };
    description = "Generated nixd option-completion expressions from the host context; LSP clients consume rows, never hand-maintained strings.";
  };
}
