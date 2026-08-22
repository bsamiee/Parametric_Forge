# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/nixos/default.nix
# ----------------------------------------------------------------------------
# Minimal NixOS VPS surface: boot, static network, SSH, users, and store hygiene. Workloads extend this baseline only when they have a real owner.
{
  host,
  pkgs,
  modulesPath,
  ...
}: {
  # qemu-guest profile carries the virtio initrd modules the KVM hypervisor needs to expose the boot disk; without them initrd never finds root.
  imports = [(modulesPath + "/profiles/qemu-guest.nix") ./disko.nix];

  # --- [BOOT]
  # BIOS GRUB; disko projects the install device from the EF02 partition row.
  boot.loader.grub.enable = true;
  boot.tmp.cleanOnBoot = true;
  zramSwap.enable = true;

  # --- [LOCALE]
  # Time zone projects from the host-context row through the host factory.
  i18n.defaultLocale = "en_US.UTF-8";

  # --- [NETWORK]
  # Static addressing projected from the host-context network row — the provider serves no DHCP. SSH is the only admitted ingress.
  networking = {
    usePredictableInterfaceNames = false;
    useDHCP = false;
    interfaces.${host.network.interface} = {
      ipv4.addresses = [{inherit (host.network.ipv4) address prefixLength;}];
      ipv6.addresses = [{inherit (host.network.ipv6) address prefixLength;}];
    };
    defaultGateway = {
      address = host.network.ipv4.gateway;
      inherit (host.network) interface;
    };
    defaultGateway6 = {
      address = host.network.ipv6.gateway;
      inherit (host.network) interface;
    };
    inherit (host.network) nameservers;

    firewall = {
      enable = true;
      allowedTCPPorts = [22];
    };
  };

  # --- [SERVICES]
  services = {
    openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        # Key-only root: nixos-rebuild --target-host activation rail.
        PermitRootLogin = "prohibit-password";
      };
    };

    journald.extraConfig = "SystemMaxUse=500M";
  };

  # --- [IDENTITY]
  # Declarative users only; key-based access, passwordless wheel (agent-first frictionless posture, parity with the Darwin Touch-ID rail).
  security.sudo.wheelNeedsPassword = false;
  users.mutableUsers = false;
  users.users = {
    root.openssh.authorizedKeys.keys = host.ssh.authorizedKeys;
    ${host.user.name} = {
      isNormalUser = true;
      inherit (host.user) home;
      extraGroups = ["wheel"];
      openssh.authorizedKeys.keys = host.ssh.authorizedKeys;
    };
  };

  # Store hygiene: timer-driven GC (the Darwin forge-nix-maintenance analogue).
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  # --- [ROOT_VISIBLE_TOOLING]
  # Flake operations and remote activation need git at the system layer; the user CLI estate remains Home Manager-owned.
  environment.systemPackages = [pkgs.git];
}
