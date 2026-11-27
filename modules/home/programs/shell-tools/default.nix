{
  config,
  launchdAgent,
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
    ./mise.nix
    ./procs.nix
    ./redeploy.nix
    ./serpl.nix
    ./ssh.nix
    ./starship.nix
    ./tlrc.nix
    ./tmux.nix
    ./trippy.nix
    ./xh.nix
    ./zoxide.nix
  ];

  home = {
    packages = [
      pkgs._7zz-rar
      pkgs.ast-grep
      pkgs.awscli2-current
      pkgs.coderabbit
      pkgs.curl-impersonate-current
      pkgs.defuddle
      pkgs.doctl-current
      pkgs.dua-current
      pkgs.duckdb-current
      pkgs.fq
      pkgs.gawk
      pkgs.hostinger
      pkgs.hyperfine
      pkgs.ipsw-current
      pkgs.jq
      pkgs.macmon-current
      pkgs.mq
      pkgs.single-file
      pkgs.oha
      pkgs.openssl_4_1
      pkgs.ouch
      pkgs.parallel
      pkgs.powershell-current
      pkgs.rclone
      pkgs.ripgrep
      pkgs.rsync-current
      pkgs.sd
      pkgs.ssm-session-manager-plugin-current
      pkgs.swift-section
      pkgs.tscli-current
      pkgs.uv
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

  # --- [AWS_AGENT_TOOLKIT]
  launchd.agents.aws-agent-skills = launchdAgent {
    name = "aws-agent-skills";
    argv = [(lib.getExe pkgs.awscli2-current) "agent-toolkit" "update-skill" "--all" "--no-sign-request"];
    StartCalendarInterval = [
      {
        Hour = 13;
        Minute = 20;
      }
    ];
  };

  xdg.configFile = {
    # --- [RIPGREP]
    "ripgrep/config".text = ''
      --hidden
      --glob=!.git
    '';

    # --- [GNU_PARALLEL]
    "parallel/will-cite".text = "";
  };
}
