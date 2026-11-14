{
  config,
  lib,
  pkgs,
  ...
}: let
  duckdbExtensionRows = (import ../../../../overlays/manifest.nix).extensions.duckdb-extensions.rows;
  duckdbLoads = lib.attrNames (lib.filterAttrs (_: row: row.load or false) duckdbExtensionRows);
in {
  imports = [
    ./1password.nix
    ./act.nix
    ./atuin.nix
    ./bat.nix
    ./bottom.nix
    ./carapace.nix
    ./eza.nix
    ./fastfetch.nix
    ./fd.nix
    ./fzf.nix
    ./loc.nix
    ./mise.nix
    ./procs.nix
    ./redeploy.nix
    ./serpl.nix
    ./ssh.nix
    ./starship.nix
    ./tailscale.nix
    ./tlrc.nix
    ./trippy.nix
    ./xh.nix
    ./zoxide.nix
  ];

  home = {
    packages = [
      pkgs._7zz-rar
      pkgs.ast-grep
      pkgs.coderabbit
      pkgs.curl-impersonate-current
      pkgs.defuddle
      pkgs.difftastic
      pkgs.dua-current
      pkgs.duckdb-current
      pkgs.dysk
      pkgs.flock
      pkgs.fq
      pkgs.gawk
      pkgs.hexyl
      pkgs.hostinger
      pkgs.hurl-current
      pkgs.hyperfine
      pkgs.jq
      pkgs.lychee
      pkgs.macmon
      pkgs.monolith
      pkgs.mq
      pkgs.oha-current
      pkgs.netcoredbg
      pkgs.ouch
      pkgs.parallel
      pkgs.powershell-current
      pkgs.rclone
      pkgs.ripgrep
      pkgs.rsync-current
      pkgs.sd
      pkgs.sshs
      pkgs.tmux
      pkgs.tree
      pkgs.tscli-current
      pkgs.uv
      pkgs.watchexec-current
      pkgs.witr
      pkgs.yq-go-current
    ];

    # --- [DUCKDB]
    file =
      {
        ".duckdbrc".text = ''
          .startup_text none
          SET temp_directory = '${config.xdg.cacheHome}/duckdb';
          SET max_temp_directory_size = '64GiB';
          SET memory_limit = '16GiB';
          SET errors_as_json = true;
          ${lib.concatMapStrings (name: "INSTALL AND LOAD ${name};\n") duckdbLoads}${lib.optionalString (lib.elem "spatial" duckdbLoads) "SET geometry_always_xy = true;\n"}'';
      }
      // lib.mapAttrs' (name: row:
        lib.nameValuePair ".duckdb/extensions/v${pkgs.duckdb-current.version}/osx_arm64/${name}.duckdb_extension" {
          source = pkgs.runCommand "${name}.duckdb_extension" {src = pkgs.fetchurl {inherit (row) url hash;};} ''gzip -dc "$src" > "$out"'';
          force = true;
        })
      duckdbExtensionRows;
  };

  xdg.configFile = {
    # --- [RIPGREP]
    "ripgrep/config".text = ''
      --hidden
      --glob=!.git
    '';

    # --- [HURL]
    "hurl/config".text = "--connect-timeout 10\n";

    # --- [GNU_PARALLEL]
    "parallel/will-cite".text = "";
  };
}
