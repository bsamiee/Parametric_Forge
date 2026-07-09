# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/apps/yazi/default.nix
# ----------------------------------------------------------------------------
# Yazi file workbench owner: store-owned plugin rows, typed previewer/opener/
# fetcher/preloader rows generating yazi.toml, and the diagnostic previewer
# kernel. File-action routing is rows here, never inline TOML literals.
{
  lib,
  pkgs,
  ...
}: let
  yaziPkg = pkgs.yazi.override {
    _7zz = pkgs._7zz-rar; # RAR-capable 7zip: one archive runtime for the whole owner
  };

  # Diagnostic previewer kernel: ONE dispatch surface over the config-language
  # lanes; every arm is read-only evidence (checks + syntax render), never a
  # build, never network. Hover latency stays bounded by head caps.
  diagPreview = pkgs.writeShellApplication {
    name = "yazi-diag-preview.sh";
    runtimeInputs = [pkgs.alejandra pkgs.deadnix pkgs.statix pkgs.taplo pkgs.jq pkgs.yq-go pkgs.bat pkgs.coreutils];
    text = ''
      # Usage: yazi-diag-preview.sh <lane> <file>; lanes: nix toml json yaml kdl
      lane="''${1:?lane required}"
      file="''${2:?file required}"
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
      diag
      printf '%s\n' '────────────────────────────────────────'
      bat --color=always --style=plain --paging=never "$file" 2>/dev/null | head -200 || true
    '';
  };

  # --- Previewer rows ---------------------------------------------------------
  # Order is precedence: directory tree, config-language diagnostics, archives,
  # markdown, then the DuckDB data lane. JSON stays on the jq diagnostic lane;
  # DuckDB owns tabular/columnar formats (ledger 30 keeps Yazi file-domain).
  previewerRows = [
    {
      url = "*/";
      run = ''piper -- eza -TL=3 --color=always --icons=always --group-directories-first --no-quotes "$1"'';
    }
    {
      url = "*.nix";
      run = ''piper -- yazi-diag-preview.sh nix "$1"'';
    }
    {
      url = "*.kdl";
      run = ''piper -- yazi-diag-preview.sh kdl "$1"'';
    }
    {
      url = "*.toml";
      run = ''piper -- yazi-diag-preview.sh toml "$1"'';
    }
    {
      url = "*.json";
      run = ''piper -- yazi-diag-preview.sh json "$1"'';
    }
    {
      url = "*.{yaml,yml}";
      run = ''piper -- yazi-diag-preview.sh yaml "$1"'';
    }
    {
      url = "*.tar*";
      run = ''piper --format=url -- tar tf "$1"'';
    }
    {
      url = "*.md";
      run = ''piper -- rich --line-numbers --force-terminal "$1"'';
    }
    {
      url = "*.{csv,tsv}";
      run = "duckdb";
    }
    {
      url = "*.parquet";
      run = "duckdb";
    }
    {
      url = "*.xlsx";
      run = "duckdb";
    }
    {
      url = "*.duckdb";
      run = "duckdb";
    }
  ];

  # Preload opt-outs: remote mounts, caches, and generated trees never burn
  # preview bandwidth eagerly; hover still previews on demand.
  preloaderRows = [
    {
      url = "/Volumes/**";
      run = "noop";
    }
    {
      url = "**/Library/Caches/**";
      run = "noop";
    }
    {
      url = "**/node_modules/**";
      run = "noop";
    }
    {
      url = "**/.git/**";
      run = "noop";
    }
  ];

  # Fetcher rows: mime-ext extension-database MIME (speed over file(1) on huge
  # or remote trees) + first-party git status. `id = "mime"/"git"` rows are the
  # <=26.1.22 compatibility spelling; this owner pins 26.x semantics.
  fetcherRows = assert lib.assertMsg (lib.versionAtLeast yaziPkg.version "26.2")
  "yazi ${yaziPkg.version}: mime-ext fetcher rows assume the >26.1.22 grammar"; [
    {
      url = "local://*";
      run = "mime-ext.local";
      prio = "high";
      group = "mime";
    }
    {
      url = "remote://*";
      run = "mime-ext.remote";
      prio = "high";
      group = "mime";
    }
    {
      url = "*";
      run = "git";
      group = "git";
    }
    {
      url = "*/";
      run = "git";
      group = "git";
    }
  ];

  # --- Opener policy rows -------------------------------------------------------
  # Typed opener table + routing rules; the archive owner is the augment-command
  # event family (augmented-extract) over the shared _7zz-rar runtime — native
  # `extract` and ad-hoc archive commands never route beside it.
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
  openRules = [
    {
      name = "*/";
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
      mime = "application/{zip,gzip,x-tar,x-bzip2,x-7z-compressed,x-rar,x-xz,zstd}";
      use = ["extract" "reveal"];
    }
    {
      name = "*.{dwg,dxf,3dm,skp,ifc,rvt,rfa,step,stp,iges,igs,stl,obj,fbx,glb,gltf}";
      use = ["open" "reveal"];
    }
    {
      mime = "application/{json,toml,yaml,x-ndjson}";
      use = ["edit" "reveal"];
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

    # Store-owned plugin rows (substrate: no runtime fetching). nixpkgs
    # yaziPlugins rows are current against upstream; augment-command pins the
    # upstream HEAD directly (not packaged in nixpkgs).
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

    # Popup-first configuration with deterministic editor handoff; every table
    # below is a typed row set, rendered to yazi.toml at build.
    settings = {
      plugin = {
        prepend_previewers = previewerRows;
        prepend_preloaders = preloaderRows;
        prepend_fetchers = fetcherRows;
      };

      mgr = {
        ratio = [1 4 3];
        sort_by = "natural"; # 1.md < 2.md < 10.md
        sort_sensitive = false;
        sort_reverse = false;
        sort_dir_first = true;
        sort_translit = true;
        linemode = "mtime";
        show_hidden = false;
        show_symlink = true; # popup usage benefits from direct path truth
        mouse_events = ["click" "scroll" "drag"];
        title_format = "Yazi: {cwd}";
      };

      preview = {
        max_width = 1200;
        max_height = 900;
      };

      opener = openers;
      open.prepend_rules = openRules;

      tasks = {
        micro_workers = 10;
        macro_workers = 10;
        bizarre_retry = 3;
        image_alloc = 536870912; # 512MB; WezTerm handles large images
        image_bound = [4096 4096];
        suppress_preload = false;
      };

      pick = {
        open_title = " [OPEN WITH] ";
        open_origin = "hovered";
        open_offset = [0 1 50 7];
      };

      which = {
        sort_by = "none";
        sort_sensitive = false;
        sort_reverse = false;
        sort_translit = false;
      };

      input = {
        cursor_blink = true;
        cd_title = " [GO TO DIR] ";
        cd_origin = "bottom-center";
        cd_offset = [0 (-3) 50 3];
        create_title = [" [CREATE FILE] " " [CREATE DIR] "];
        create_origin = "bottom-center";
        create_offset = [0 (-3) 50 3];
        rename_title = " [RENAME] ";
        rename_origin = "bottom-center";
        rename_offset = [0 (-3) 50 3];
        filter_title = " [FILTER] ";
        filter_origin = "bottom-center";
        filter_offset = [0 (-3) 50 3];
        find_title = [" [FIND NEXT] " " [FIND PREVIOUS] "];
        find_origin = "bottom-center";
        find_offset = [0 (-3) 50 3];
        search_title = " [SEARCH - {n}] ";
        search_origin = "bottom-center";
        search_offset = [0 (-3) 50 3];
        shell_title = [" [SHELL] " " [SHELL BLOCK] "];
        shell_origin = "bottom-center";
        shell_offset = [0 (-3) 60 3];
      };

      confirm = {
        trash_title = " [TRASH {n} FILE{s}] ";
        trash_origin = "center";
        trash_offset = [0 0 50 10];
        delete_title = " [DELETE {n} FILE{s}] ";
        delete_origin = "center";
        delete_offset = [0 0 50 10];
        overwrite_title = " [OVERWRITE FILE] ";
        overwrite_content = "Will overwrite the following file:";
        overwrite_origin = "center";
        overwrite_offset = [0 0 50 10];
        quit_title = " [QUIT] ";
        quit_content = "The following tasks are still running, are you sure you want to quit?";
        quit_origin = "center";
        quit_offset = [0 0 50 10];
      };
    };
  };

  xdg.configFile."yazi/keymap.toml".source = ./keymap.toml;
}
