# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/apps/yazi/default.nix
# ----------------------------------------------------------------------------
# Yazi file workbench owner: store-owned plugin rows, typed previewer/opener/fetcher/preloader rows generating yazi.toml, SFTP VFS mounts projected
# from the estate SSH rows, and the diagnostic previewer kernel. File-action routing is rows here, never inline TOML literals; upstream-default rows
# are deleted, so every settings row below diverges from the 26.5.6 preset.

{
  config,
  lib,
  pkgs,
  ...
}: let
  tomlFormat = pkgs.formats.toml {};

  yaziPkg = pkgs.yazi.override {
    _7zz = pkgs._7zz-rar; # RAR-capable 7zip: one archive runtime for the whole owner
  };

  # The ambient SSH_AUTH_SOCK is the identity-less Apple agent; VFS rows pin the estate identity socket (config.forge.ssh.identityAgent) explicitly.

  # Diagnostic previewer kernel: ONE dispatch surface over the config-language lanes; every arm is read-only evidence (checks + syntax render), never
  # a build, never network. Hover latency stays bounded by head caps.
  diagPreview = pkgs.writeShellApplication {
    name = "yazi-diag-preview.sh";
    runtimeInputs = [pkgs.alejandra pkgs.deadnix pkgs.statix pkgs.taplo pkgs.jq pkgs.yq-go pkgs.bat pkgs.coreutils];
    text = ''
      # Usage: yazi-diag-preview.sh <lane> <file>; lanes: nix toml json yaml kdl
      lane="''${1:?lane required}"
      file="''${2:?file required}"
      size="$(wc -c <"$file")" # full-parse diagnostics stay off huge files
      diag() { # bounded diagnostic block, one lane arm each
        case "$lane" in
          nix)
            if alejandra --check --quiet "$file" >/dev/null 2>&1; then
              printf '[FMT] alejandra clean\n'
            else
              printf '[FMT] alejandra would reformat\n'
            fi
            deadnix --no-underscore "$file" 2>/dev/null | head -10 || true
            statix check --format errfmt "$file" 2>/dev/null | head -10 || true
            ;;
          toml)
            if taplo lint "$file" >/dev/null 2>&1; then
              printf '[PARSE] toml ok\n'
            else
              taplo lint "$file" 2>&1 | head -10 || true
            fi
            ;;
          json)
            if err="$(jq empty "$file" 2>&1)"; then
              printf '[PARSE] json ok\n'
            else
              printf '%s\n' "$err" | head -6
            fi
            ;;
          yaml)
            if err="$(yq --exit-status 'true' "$file" 2>&1 >/dev/null)"; then
              printf '[PARSE] yaml ok\n'
            else
              printf '%s\n' "$err" | head -6
            fi
            ;;
          kdl) ;; # no admitted KDL linter; syntax render only
          *) printf 'yazi-diag-preview.sh: unknown lane %s\n' "$lane" >&2; exit 64 ;;
        esac
      }
      if [ "$size" -le 2097152 ]; then
        diag
      else
        printf '[SKIP] diagnostics: %s bytes exceeds 2MiB parse cap\n' "$size"
      fi
      printf '%s\n' '────────────────────────────────────────'
      bat --color=always --style=plain --paging=never "$file" 2>/dev/null | head -200 || true
    '';
  };

  # --- [PREVIEWER_ROWS]
  # Directory tree, config-language diagnostics (one lane per row), archives, markdown, the DuckDB data lane, then a hexyl lane for the true-binary
  # residue (mime-ext classifies unknown extensions via file(1); what remains octet-stream is genuinely opaque). All globs are disjoint; JSON stays on
  # the jq diagnostic lane and DuckDB owns tabular/columnar formats. Every external-command row is local:// scoped (regular + search results): a bare
  # url glob also matches sftp:// and archive:// URLs, shadowing the native vfs/archive previewers with commands that cannot read those URLs.
  diagLanes = {
    nix = "*.nix";
    kdl = "*.kdl";
    toml = "*.toml";
    json = "*.json";
    yaml = "*.{yaml,yml}";
  };
  duckdbGlobs = ["*.{csv,tsv}" "*.parquet" "*.xlsx" "*.duckdb"];
  previewerRows =
    [
      {
        url = "local://*/";
        run = ''piper -- eza -TL=3 --color=always --icons=always --group-directories-first --no-quotes "$1"'';
      }
    ]
    ++ lib.mapAttrsToList (lane: glob: {
      url = "local://${glob}";
      run = ''piper -- yazi-diag-preview.sh ${lane} "$1"'';
    })
    diagLanes
    ++ [
      {
        url = "local://*.tar*";
        run = ''piper --format=url -- tar tf "$1"'';
      }
      {
        url = "local://*.md";
        run = ''piper -- rich --line-numbers --force-terminal "$1"'';
      }
    ]
    ++ map (glob: {
      url = "local://${glob}";
      run = "duckdb";
    })
    duckdbGlobs
    ++ [
      {
        url = "local://*";
        mime = "application/octet-stream";
        run = ''piper -- hexyl --border=none --length=4KiB "$1"'';
      }
    ];

  # Preload opt-outs: remote mounts (device, SFTP VFS, and the rclone VPS mount root), caches, and generated trees never burn preview
  # bandwidth eagerly; hover still previews on demand.
  preloaderRows = map (url: {
    inherit url;
    run = "noop";
  }) ["/Volumes/**" "${config.forge.ssh.mountRoot}/**" "sftp://**" "**/Library/Caches/**" "**/node_modules/**" "**/.git/**"];

  # Fetcher rows: mime-ext extension-database MIME (speed over file(1) on huge or remote trees) + first-party git status; the version assert pins the
  # 26.5.6 surface these rows and files spell — fetcher `group` grammar, per-lane task worker pools, and the [services] vfs.toml schema.
  fetcherRows = assert lib.assertMsg (lib.versionAtLeast yaziPkg.version "26.5.6")
  "yazi ${yaziPkg.version}: config assumes the 26.5.6 fetcher/tasks/vfs grammar";
    map (side: {
      url = "${side}://*";
      run = "mime-ext.${side}";
      prio = "high";
      group = "mime";
    }) ["local" "remote"]
    ++ map (url: {
      inherit url;
      run = "git";
      group = "git";
    }) ["local://*" "local://*/"];

  # --- [OPENER_POLICY_ROWS]
  # Typed opener table + routing rules; the archive owner is the augment-command event family (augmented-extract) over the shared _7zz-rar runtime
  # — native `extract` and ad-hoc archive commands never route beside it. Preset openers not named here (play, download)
  # survive the per-key merge and stay callable from rules.
  openers = {
    edit = [
      {
        run = "forge-edit.sh %s";
        block = false;
        for = "unix";
      }
    ];
    open = [
      {
        run = "open %s";
        desc = "System open";
        for = "macos";
      }
    ];
    reveal = [
      {
        run = "open -R %s";
        desc = "Reveal in Finder";
        for = "macos";
      }
    ];
    extract = [
      {
        run = "ya pub augmented-extract --list %s";
        desc = "Extract here";
        for = "unix";
      }
    ];
    inspect = [
      {
        run = ''mediainfo %s; printf -- "-- press ENTER to close"; read -r _'';
        block = true;
        desc = "Media info";
        for = "unix";
      }
    ];
  };
  # MIME spellings match the mime-ext emission (unprefixed IANA: application/tar, rar, 7z-compressed, xz, bzip2, gzip) — legacy x-* spellings
  # never match and silently drop the rule. The vfs row keeps download routing for absent/stale remote files ahead of the catch-all.
  openRules = [
    {
      url = "*/";
      use = ["edit" "open" "reveal"];
    }
    {
      mime = "text/*";
      use = ["edit" "reveal"];
    }
    {
      mime = "image/*";
      use = ["open" "inspect" "reveal"];
    }
    {
      mime = "{audio,video}/*";
      use = ["open" "inspect" "reveal"];
    }
    {
      mime = "application/{zip,rar,7z*,tar,gzip,xz,zstd,bzip*,lzma,compress,archive,cpio,arj,xar,ms-cab*}";
      use = ["extract" "reveal"];
    }
    {
      url = "*.{dwg,dxf,3dm,skp,ifc,rvt,rfa,step,stp,iges,igs,stl,obj,fbx,glb,gltf}";
      use = ["open" "reveal"];
    }
    {
      mime = "application/{json,ndjson}";
      use = ["edit" "reveal"];
    }
    {
      mime = "vfs/{absent,stale}";
      use = ["download"];
    }
    {
      mime = "*";
      use = ["open" "edit" "reveal"];
    }
  ];
in {
  imports = [./theme.nix];

  home.packages = [diagPreview];

  programs.yazi = {
    enable = true;
    enableZshIntegration = true;
    package = yaziPkg;
    initLua = ./init.lua;

    # Store-owned plugin rows, no runtime fetching: nixpkgs `yaziPlugins` is the packaged substrate, and augment-command
    # pins upstream HEAD directly since nixpkgs omits it.
    plugins = {
      inherit (pkgs.yaziPlugins) full-border toggle-pane jump-to-char mount piper git smart-filter mime-ext duckdb zoom;

      # Semantic command layer: open/quit/tab/paste/archive/scroll behaviors
      augment-command = pkgs.fetchFromGitHub {
        owner = "hankertrix";
        repo = "augment-command.yazi";
        rev = "dd2d6cf07f81cef543e37883352e30b91634ec86";
        hash = "sha256-sB2t3Gg+WdPG6OE8pD6VovD+x9nN21Jn8XydZZdTqCg=";
      };
    };

    # Popup-first configuration with deterministic editor handoff; every table below is a typed row set, rendered to yazi.toml at build.
    settings = {
      plugin = {
        prepend_previewers = previewerRows;
        prepend_preloaders = preloaderRows;
        prepend_fetchers = fetcherRows;
      };

      mgr = {
        sort_by = "natural"; # 1.md < 2.md < 10.md
        sort_translit = true;
        linemode = "mtime";
      };

      preview.max_width = 1200;

      opener = openers;
      open.prepend_rules = openRules;

      # Preview-heavy surface (previewer + fetcher rows above) lifts the fetch/preload lanes past the preset pools;
      # image_bound caps decode size for popup-pane hover latency.
      tasks = {
        fetch_workers = 8;
        preload_workers = 5;
        image_bound = [4096 4096];
      };

      pick.open_title = " [OPEN WITH] ";

      # Popup geometry as rows: every input popup shares bottom-center at [0 (-3) 50 3] unless its row overrides;
      # confirms share center at [0 0 50 10] and optionally carry a body line.
      input =
        {cursor_blink = true;}
        // lib.concatMapAttrs (name: row: {
          "${name}_title" = row.title;
          "${name}_origin" = "bottom-center";
          "${name}_offset" = row.offset or [0 (-3) 50 3];
        }) {
          cd.title = " [GO TO DIR] ";
          create.title = [" [CREATE FILE] " " [CREATE DIR] "];
          rename.title = " [RENAME] ";
          filter.title = " [FILTER] ";
          find.title = [" [FIND NEXT] " " [FIND PREVIOUS] "];
          search.title = " [SEARCH - {n}] ";
          shell = {
            title = [" [SHELL] " " [SHELL BLOCK] "];
            offset = [0 (-3) 60 3];
          };
        };

      confirm = lib.concatMapAttrs (name: row:
        {
          "${name}_title" = row.title;
          "${name}_offset" = [0 0 50 10];
        }
        // lib.optionalAttrs (row ? body) {"${name}_body" = row.body;}) {
        trash.title = " [TRASH {n} FILE{s}] ";
        delete.title = " [DELETE {n} FILE{s}] ";
        overwrite.title = " [OVERWRITE FILE] ";
        quit = {
          title = " [QUIT] ";
          body = "The following tasks are still running, are you sure you want to quit?";
        };
      };
    };
  };

  xdg.configFile."yazi/keymap.toml".source = ./keymap.toml;

  # SFTP VFS mounts projected from the estate SSH rows: one service per host, authenticated through the 1Password agent socket; enter with
  # `cd sftp://<host>/`. Preloading over the tunnel is opted out above.
  xdg.configFile."yazi/vfs.toml".source = tomlFormat.generate "yazi-vfs" {
    services =
      lib.mapAttrs (_: row: {
        type = "sftp";
        host = row.hostName;
        inherit (row) user;
        port = 22;
        identity_agent = config.forge.ssh.identityAgent;
      })
      config.forge.ssh.hosts;
  };
}
