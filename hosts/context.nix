# Title         : context.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : hosts/context.nix
# ----------------------------------------------------------------------------
# Host-context factory: one vocabulary for every host on every OS. A new
# machine is a new row here; host files project rows into darwinSystem or
# nixosSystem, and the home graph gates imports on `host.os`/`host.features`.
let
  # Universal 1Password-held key ("Forge SSH Key"): auth + signing everywhere.
  authorizedKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ13xqqm/BVTzJNN/V0Cukvk4xAentt3qqE525URRqwS Forge SSH Key"
  ];
in {
  macbook = {
    name = "macbook";
    os = "darwin";
    system = "aarch64-darwin";
    stateVersion = {
      system = 7;
      home = "26.05";
    };
    user = {
      name = "bardiasamiee";
      home = "/Users/bardiasamiee";
    };
    features = {
      desktop = true;
      server = false;
    };
    ssh = {inherit authorizedKeys;};
  };

  # Hostinger VPS (live-verified: x86_64, BIOS boot, single /dev/sda). Primary
  # user mirrors the Darwin identity; serviceUsers carry workload identities
  # (Maghz compose plane) so existing tunnel/deploy rows survive the cutover.
  maghz = {
    name = "maghz";
    os = "nixos";
    system = "x86_64-linux";
    stateVersion = {
      system = "26.11";
      home = "26.11";
    };
    user = {
      name = "bardiasamiee";
      home = "/home/bardiasamiee";
    };
    serviceUsers = [
      {
        name = "maghz-agent";
        groups = ["docker"];
      }
    ];
    features = {
      desktop = false;
      server = true;
    };
    ssh = {inherit authorizedKeys;};
    disk.device = "/dev/sda";
  };
}
