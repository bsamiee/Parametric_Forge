# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/nixos/default.nix
# ----------------------------------------------------------------------------
# NixOS system surface: boot, network, SSH, users, container runtime, and the
# Atuin sync server. Owns nothing Darwin owns — Homebrew, launchd, and macOS
# defaults never generalize here.
{
  host,
  pkgs,
  modulesPath,
  ...
}: {
  # qemu-guest profile carries the virtio initrd modules the KVM hypervisor
  # needs to expose the boot disk; without them initrd never finds root.
  imports = [(modulesPath + "/profiles/qemu-guest.nix") ./disko.nix];

  # --- Boot -------------------------------------------------------------------
  # BIOS GRUB; disko projects the install device from the EF02 partition row.
  boot.loader.grub.enable = true;
  boot.tmp.cleanOnBoot = true;
  zramSwap.enable = true;

  # --- Locale / time ------------------------------------------------------------
  time.timeZone = "America/Chicago";
  i18n.defaultLocale = "en_US.UTF-8";

  # --- Network ------------------------------------------------------------------
  # Static addressing projected from the host-context network row — the
  # provider serves no DHCP. SSH only on day one; every service stays loopback
  # behind the ssh.nix vpsTunnels registry (webhook, postgres, ollama, n8n, atuin).
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

  # --- Services --------------------------------------------------------------
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

    # Atuin sync server: loopback-only, reached exclusively through the client
    # tunnel row. Port 8788 — 8888 belongs to forge-jupyter on every host.
    atuin = {
      enable = true;
      host = "127.0.0.1";
      port = 8788;
      openRegistration = true;
    };

    journald.extraConfig = "SystemMaxUse=500M";
  };

  # --- Identity -------------------------------------------------------------
  # Declarative users only; key-based access, passwordless wheel (agent-first
  # frictionless posture, parity with the Darwin Touch-ID rail).
  security.sudo.wheelNeedsPassword = false;
  users.mutableUsers = false;
  users.users =
    {
      root.openssh.authorizedKeys.keys = host.ssh.authorizedKeys;
      ${host.user.name} = {
        isNormalUser = true;
        inherit (host.user) home;
        extraGroups = ["wheel" "docker"];
        openssh.authorizedKeys.keys = host.ssh.authorizedKeys;
        # Lingering keeps HM systemd user services (Jupyter, tunnels) alive
        # without an interactive session — the launchd RunAtLoad analogue.
        linger = true;
      };
    }
    // builtins.listToAttrs (map (row: {
        inherit (row) name;
        value = {
          isNormalUser = true;
          extraGroups = row.groups;
          openssh.authorizedKeys.keys = host.ssh.authorizedKeys;
        };
      })
      (host.serviceUsers or []));

  # --- Container runtime ---------------------------------------------------
  # System Docker daemon (Maghz compose plane); the nixpkgs docker CLI bundles
  # the compose plugin, so `docker compose` works without extra rows.
  virtualisation.docker = {
    enable = true;
    autoPrune.enable = true;
  };

  # Store hygiene: timer-driven GC (the Darwin forge-nix-maintenance analogue).
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  # --- Root-visible tooling -----------------------------------------------
  # Flake operations and remote activation need git at the system layer; the
  # full CLI estate is Home Manager-owned per user.
  environment.systemPackages = [pkgs.git];
}
