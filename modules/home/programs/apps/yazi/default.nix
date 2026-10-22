# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/apps/yazi/default.nix
# ----------------------------------------------------------------------------
# Yazi file workbench owner: store-owned plugin rows and typed previewer/opener/fetcher/preloader rows generating yazi.toml. File-action routing
# is rows here, never inline TOML literals; upstream-default rows are deleted, so every settings row below diverges from the upstream preset.
{
  config,
  lib,
  pkgs,
  ...
}: let
  manifest = import ../../../../../overlays/manifest.nix;

  # Power-leader prefix from the chord owner's Power layer modifiers, in yazi's key-notation letters.
  powerLeader = lib.concatMapStringsSep "-" (m:
    {
      left_command = "D";
      left_option = "A";
      left_control = "C";
      left_shift = "S";
    }.${
      m.kc
    })
  config.forge.chords.layers.power.mods;

  # The wrapper seats every previewer runtime on yazi's own PATH: the RAR-capable 7zip as the one archive runtime, the FFmpeg build the media
  # tools install, and DuckDB for the data lane, which stays off the machine PATH.
  yaziPkg = pkgs.yazi.override {
    _7zz = pkgs._7zz-rar;
    ffmpeg-headless = pkgs.ffmpeg-full;
    extraPackages = [pkgs.duckdb];
  };

  # --- [PREVIEWER_ROWS]
  # Directory tree, archives, markdown, the DuckDB data lane, then a hexyl lane for the true-binary residue (mime-ext classifies unknown
  # extensions via file(1); what remains octet-stream is genuinely opaque). All globs are disjoint; source and JSON files keep yazi's built-in
  # code and json previewers, and DuckDB owns tabular/columnar formats. Every external-command row is local:// scoped (regular + search results):
  # a bare url glob also matches archive:// URLs, shadowing the native archive previewer with commands that cannot read those URLs.
  duckdbGlobs = ["*.{csv,tsv}" "*.parquet" "*.xlsx" "*.duckdb"];
  previewerRows =
    [
      {
        url = "local://*/";
        run = ''piper -- eza -TL=3 --color=always --icons=always --group-directories-first --no-quotes "$1"'';
      }
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

  # Preload opt-outs: volumes, caches, and generated trees never spend preview bandwidth eagerly; hover still previews on demand.
  preloaderRows = map (url: {
    inherit url;
    run = "noop";
  }) ["/Volumes/**" "**/Library/Caches/**" "**/node_modules/**" "**/.git/**"];

  # Fetcher rows: mime-ext extension-database MIME (speed over file(1) on huge trees) + first-party git status.
  fetcherRows =
    [
      {
        url = "local://*";
        run = "mime-ext.local";
        prio = "high";
        group = "mime";
      }
    ]
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
        run = "nvim-edit.sh %s";
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
  # never match and silently drop the rule.
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
      mime = "*";
      use = ["open" "edit" "reveal"];
    }
  ];
in {
  imports = [./theme.nix];

  programs.yazi = {
    enable = true;
    package = yaziPkg;
    initLua = builtins.readFile ./init.lua;
    keymap = fromTOML (builtins.replaceStrings ["<POWER-"] ["<${powerLeader}-"] (builtins.readFile ./keymap.toml));

    # Store-owned plugins, no runtime fetching: the set derives from overlays/manifest.nix extensions.yazi-plugins — a row with `attr` resolves in
    # nixpkgs `yaziPlugins`, a row with owner/repo/rev/hash is a pinned upstream tree nixpkgs omits.
    plugins =
      lib.mapAttrs (
        _: row:
          if row ? attr
          then pkgs.yaziPlugins.${row.attr}
          else pkgs.fetchFromGitHub {inherit (row) owner repo rev hash;}
      )
      manifest.extensions.yazi-plugins.rows;

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
}
