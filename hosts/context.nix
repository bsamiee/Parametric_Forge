# Title         : context.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : hosts/context.nix
# ----------------------------------------------------------------------------
# Host-context factory: one vocabulary for every host on every OS. A new machine is a new row here; the host factory projects rows into
# darwinSystem or nixosSystem, and the home graph gates imports on `host.os`.
let
  # Universal 1Password-held key ("Forge SSH Key"): auth + signing everywhere.
  authorizedKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ13xqqm/BVTzJNN/V0Cukvk4xAentt3qqE525URRqwS Forge SSH Key"
  ];
in {
  macbook = {
    name = "macbook";
    label = "Bardia's MacBook Pro";
    os = "darwin";
    system = "aarch64-darwin";
    timeZone = "America/Chicago";
    stateVersion = {
      system = 7;
      home = "26.05";
    };
    user = {
      name = "bardiasamiee";
      home = "/Users/bardiasamiee";
    };
    ssh = {inherit authorizedKeys;};
  };

  # Hostinger VPS: x86_64, BIOS boot, single /dev/sda. Primary user mirrors the Darwin identity; serviceUsers
  # carry the Maghz compose-plane workload identities that own the tunnel and deploy rows.
  maghz = {
    name = "maghz";
    os = "nixos";
    system = "x86_64-linux";
    timeZone = "America/Chicago";
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
    ssh = {inherit authorizedKeys;};
    disk.device = "/dev/sda";
    # Hostinger serves no DHCP: static addressing (proto static route, /24 + /48 scopes).
    network = {
      interface = "eth0";
      ipv4 = {
        address = "31.97.131.41";
        prefixLength = 24;
        gateway = "31.97.131.254";
      };
      ipv6 = {
        address = "2a02:4780:2d:23df::1";
        prefixLength = 48;
        gateway = "2a02:4780:2d::1";
      };
      nameservers = ["153.92.2.6" "1.1.1.1"];
    };
  };
}
