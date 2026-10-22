# Title         : context.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : hosts/context.nix
# ----------------------------------------------------------------------------
# Host-context registry: one row per machine. The host factory projects each row into darwinSystem, and the home graph reads the same row.
{
  macbook = let
    home = "/Users/bardiasamiee";
  in {
    name = "macbook";
    label = "Bardia's MacBook Pro";
    system = "aarch64-darwin";
    timeZone = "America/Chicago";
    stateVersion = {
      system = 7;
      home = "26.05";
    };
    user = {
      name = "bardiasamiee";
      inherit home;
    };
    # Forge checkout the deploy rail builds from and the editor's nixd evaluates.
    flakeRoot = "${home}/Developer/Parametric_Forge";
    # 1Password-held key: SSH auth and commit signing.
    ssh.authorizedKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ13xqqm/BVTzJNN/V0Cukvk4xAentt3qqE525URRqwS Bardia SSH Key"
    ];
  };
}
