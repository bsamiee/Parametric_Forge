# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/nixos/default.nix
# ----------------------------------------------------------------------------
# NixOS system surface: boot, network, SSH, users, container runtime, and the Atuin sync server. Owns nothing Darwin owns —
# Homebrew, launchd, and macOS defaults never generalize here.

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
  # Static addressing projected from the host-context network row — the provider serves no DHCP. SSH only on day one; every
  # service stays loopback behind the ssh.nix vpsTunnels registry.
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

    # Atuin sync server: loopback-only, reached exclusively through the client tunnel row. Port 8788 — 8888 belongs to forge-jupyter on every host.
    atuin = {
      enable = true;
      host = "127.0.0.1";
      port = 8788;
      openRegistration = true;
    };

    # ntfy push server: the estate-private notification tier, loopback-only behind the maghz tunnel row (SSH is the auth boundary while no public
    # ingress exists). The Mac publish arm selects its target through the NTFY_URL Doppler row; pointing that row here requires the Maghz compose
    # Caddy site plus deny-all token auth landing together.
    ntfy-sh = {
      enable = true;
      # base-url is loopback-truthful on BOTH tunnel ends (the forward maps port-to-port); it flips to the public URL with the ingress landing.
      settings = {
        base-url = "http://127.0.0.1:2586";
        listen-http = "127.0.0.1:2586";
      };
    };

    journald.extraConfig = "SystemMaxUse=500M";
  };

  # --- [IDENTITY]
  # Declarative users only; key-based access, passwordless wheel (agent-first frictionless posture, parity with the Darwin Touch-ID rail).
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
        # Lingering keeps HM systemd user services (Jupyter, tunnels) alive without an interactive session — the launchd RunAtLoad analogue.
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

  # --- [CONTAINER_RUNTIME]
  # System Docker daemon (Maghz compose plane); the nixpkgs docker CLI bundles the compose plugin, so `docker compose` works without extra rows.
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

  # --- [ROOT_VISIBLE_TOOLING]
  # Flake operations and remote activation need git at the system layer; the full CLI estate is Home Manager-owned per user. doppler serves the
  # maghz-agent service user (no HM graph): the /srv/maghz-scoped read-only token is the VPS runtime secret consumer.
  environment.systemPackages = [pkgs.git pkgs.doppler];
}
