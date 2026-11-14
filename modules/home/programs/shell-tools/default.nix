{
  config,
  lib,
  pkgs,
  ...
}: let
  duckdbExtensionRows = (import ../../../../overlays/manifest.nix).extensions.duckdb-extensions.rows;
  duckdbExtensions = pkgs.linkFarm "duckdb-extensions" (lib.mapAttrsToList (name: row: {
      name = "${name}.duckdb_extension";
      path = pkgs.runCommand "${name}.duckdb_extension" {src = pkgs.fetchurl {inherit (row) url hash;};} ''gzip -dc "$src" > "$out"'';
    })
    duckdbExtensionRows);
  duckdbStatements = statement: lib.concatMapStrings (name: "${statement name};\n") (lib.attrNames duckdbExtensionRows);
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
    file.".duckdbrc".text = ''
      .startup_text none
      SET temp_directory = '${config.xdg.cacheHome}/duckdb';
      ${lib.concatMapStrings (name: "LOAD ${name};\n") (lib.attrNames (lib.filterAttrs (_: row: row.load or false) duckdbExtensionRows))}'';
    activation.installDuckdbExtensions = lib.hm.dag.entryAfter ["writeBoundary"] ''
      run ${lib.getExe pkgs.duckdb-current} -no-init -c ${lib.escapeShellArg (duckdbStatements (name: "FORCE INSTALL '${duckdbExtensions}/${name}.duckdb_extension'"))}
    '';
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
