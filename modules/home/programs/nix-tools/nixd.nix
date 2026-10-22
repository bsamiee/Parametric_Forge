# Title         : nixd.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/nix-tools/nixd.nix
# ----------------------------------------------------------------------------
# nixd option-completion owner (nix-community/nixd, the LSP — distinct from the determinate-nixd daemon). Option-completion expressions
# generate once from the host context; the Neovim server rows consume them.
{
  host,
  lib,
  ...
}: let
  # git+file:// forces the git-tree fetcher (never walks .git), so nixd's upstream fetchers skip the core.fsmonitor
  # unix socket at .git/fsmonitor--daemon.ipc that a plain-path copy would choke on.
  flake = ''(builtins.getFlake "git+file://${host.flakeRoot}")'';
  hostOptions = "${flake}.darwinConfigurations.${host.name}.options";
in {
  options.forge.lsp.nixd = lib.mkOption {
    type = lib.types.raw;
    readOnly = true;
    default = {
      nixpkgs.expr = "${flake}.legacyPackages.${host.system}";
      formatting.command = ["alejandra"];
      options = {
        nix-darwin.expr = hostOptions;
        home-manager.expr = "${hostOptions}.home-manager.users.type.getSubOptions [ ]";
      };
    };
    description = "Generated nixd option-completion expressions from the host context; LSP clients consume rows, never hand-maintained strings.";
  };
}
