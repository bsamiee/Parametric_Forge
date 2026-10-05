# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/apps/nvim/default.nix
# ----------------------------------------------------------------------------
# Store-owned Neovim rail and Lua fact generator. Home Manager deploys the pinned plugin set (zero network at first start) and one
# server/tool/chord/syntax inventory projects into generated estate/*.lua modules and .luarc.json. Lua owns runtime behavior; Nix owns
# packages, paths, and facts.
{
  config,
  lib,
  pkgs,
  ...
}: let
  toLua = lib.generators.toLua {};
  manifest = import ../../../../../overlays/manifest.nix;
  flakeRoot = config.estate.lsp.flakeRoot;
  stateHome = config.xdg.stateHome;

  # --- [TREESITTER_COMPAT_UNIT_NEOVIM_PIN_NVIM_TREESITTER_MAIN_PARSERS]
  grammars = [
    "bash"
    "c_sharp"
    "css"
    "csv"
    "diff"
    "dockerfile"
    "git_config"
    "git_rebase"
    "gitattributes"
    "gitcommit"
    "html"
    "java"
    "javascript"
    "jsdoc"
    "json"
    "json5"
    "kdl"
    "lua"
    "markdown"
    "markdown_inline"
    "mermaid"
    "nix"
    "python"
    "query"
    "regex"
    "sql"
    "toml"
    "tsx"
    "typescript"
    "vim"
    "vimdoc"
    "xml"
    "yaml"
  ];
  treesitter = pkgs.vimPlugins.nvim-treesitter.withPlugins (p: map (n: p.${n}) grammars);

  # The plugin set derives from overlays/manifest.nix extensions.nvim-plugins: each row's `attr` resolves in pkgs.vimPlugins, so a new plugin is
  # one manifest row plus its setup owner in lua/plugins/. nvim-treesitter alone is replaced by the grammar-carrying build above.
  plugins =
    lib.mapAttrs (_: row: pkgs.vimPlugins.${row.attr}) manifest.extensions.nvim-plugins.rows
    // {nvim-treesitter = treesitter;};

  # One Lua fact inventory serves lua_ls settings (any workspace root, the repo sources included) and the generated .luarc.json in the config dir.
  luaLibrary =
    ["${pkgs.neovim-unwrapped}/share/nvim/runtime/lua"]
    ++ lib.mapAttrsToList (_: p: "${p}/lua") plugins;

  # --- [LSP_INVENTORY]
  # `cmd`/`filetypes`/`root_markers`/`settings` feed vim.lsp.config rows. Commands are bare names resolving through the Forge per-user
  # profile — never per-project shells (tool-resolution policy).
  servers = {
    nixd = {
      cmd = ["nixd"];
      filetypes = ["nix"];
      root_markers = ["flake.nix" ".git"];
      settings.nixd = config.estate.lsp.nixd;
    };
    lua_ls = {
      cmd = ["lua-language-server"];
      filetypes = ["lua"];
      root_markers = [".luarc.json" "stylua.toml" ".git"];
      # The generated .luarc.json reaches only the deployed config dir; the settings row carries the same facts to every root, so repo sources
      # resolve at apps/nvim (stylua.toml) with vim/plugin awareness.
      settings.Lua = {
        runtime.version = "LuaJIT";
        workspace = {
          checkThirdParty = false;
          library = luaLibrary;
        };
        diagnostics.globals = ["vim" "Snacks"];
      };
    };
    bashls = {
      cmd = ["bash-language-server" "start"];
      filetypes = ["sh" "bash"];
      root_markers = [".git"];
      # Editor side disables the LSP shellcheck lane: nvim-lint owns shellcheck (namespace separation, one diagnostic per fault).
      settings.bashIde = {
        shellcheckPath = "";
        shfmt.path = "shfmt";
      };
    };
    # Python (ty), TypeScript (tsc), and Biome carry no row: each project's mise.toml and uv.lock own those toolchains, so the machine roster
    # names only profile-installed servers.
    postgres_lsp = {
      cmd = ["postgrestools" "lsp-proxy"];
      filetypes = ["sql"];
      root_markers = ["postgrestools.jsonc" ".git"];
      settings = {};
    };
    yamlls = {
      cmd = ["yaml-language-server" "--stdio"];
      filetypes = ["yaml"];
      root_markers = [".git"];
      settings.yaml = {
        schemaStore.enable = true;
        validate = true;
      };
    };
    # Roslyn loads no project until a client sends `solution/open`; `--autoLoadProjects` makes the server discover and load them from the
    # workspace folders itself, so vim.lsp without roslyn.nvim gets project-scoped diagnostics, not misc-files mode.
    # `--logLevel` and `--extensionLogDirectory` are mandatory server arguments; the server creates the directory.
    # TOML: taplo's LSP mode; the SchemaStore catalog is on by default, and the PATH wrapper seats the house taplo.toml only where no project config exists.
    taplo = {
      cmd = ["taplo" "lsp" "stdio"];
      filetypes = ["toml"];
      root_markers = [".taplo.toml" "taplo.toml" ".git"];
      settings = {};
    };
    # jdtls imports a folder without a build file as an invisible project; its source roots, referenced jars, and project JDK arrive as
    # `java.project.sourcePaths`, `java.project.referencedLibraries`, and `java.configuration.runtimes` settings, so the machine row carries no
    # project facts: a project's Eclipse .classpath owns them.
    jdtls = {
      cmd = ["jdtls"];
      filetypes = ["java"];
      root_markers = ["pom.xml" "build.gradle" "build.gradle.kts" ".git"];
      settings = {};
    };
    roslyn_ls = {
      cmd = [
        "Microsoft.CodeAnalysis.LanguageServer"
        "--stdio"
        "--autoLoadProjects"
        "--logLevel"
        "Information"
        "--extensionLogDirectory"
        "${stateHome}/roslyn-ls"
      ];
      filetypes = ["cs"];
      root_markers = ["global.json" ".git"];
      settings = {};
    };
  };

  # --- [TOOL_ROWS_FORMATTERS_LINTERS_SEARCH_PROVIDER_ESTATE_ACTIONS]
  # Bare names resolve through the per-user profile; the health surface proves resolution (`probes` names the real tools behind sh-wrapped rows).
  # Estate rows are the register-rail projection inside the editor: `mode` selects the dispatch arm (scratch = capture into a float,
  # pane = zellij floating pane for TUI/long-running commands).
  estateRows = [
    {
      id = "flake-inputs";
      label = "Flake inputs (nix flake metadata)";
      argv = ["nix" "flake" "metadata" "--json" flakeRoot];
      mode = "scratch";
      ft = "json";
    }
    {
      id = "flake-checker";
      label = "Flake input health (flake-checker)";
      argv = ["flake-checker" "--fail-mode"];
      cwd = flakeRoot;
      mode = "scratch";
    }
    {
      id = "deadnix";
      label = "Dead Nix code (deadnix)";
      argv = ["deadnix" "--output-format" "json" "."];
      cwd = flakeRoot;
      mode = "scratch";
      ft = "json";
    }
    {
      id = "statix";
      label = "Nix antipatterns (statix)";
      argv = ["statix" "check" "."];
      cwd = flakeRoot;
      mode = "scratch";
    }
    {
      # sort -V: lexicographic ls misorders generations across digit widths.
      id = "generation-diff";
      label = "Generation diff (nvd)";
      argv = ["sh" "-c" "nvd diff $(ls -d /nix/var/nix/profiles/system-*-link | sort -V | tail -n 2)"];
      probes = ["nvd"];
      mode = "scratch";
    }
    {
      # Derivation-level diff of the last two generations. Substituted builds leave drv gaps anywhere in the closure: toplevel absence rails
      # before launch, an inner-drv abort rails into the same typed verdict line.
      id = "nix-diff";
      label = "Generation diff, derivation level (nix-diff)";
      argv = ["sh" "-c" ''set -- $(ls -d /nix/var/nix/profiles/system-*-link | sort -V | tail -n 2); left=$(nix-store --query --deriver "$1"); right=$(nix-store --query --deriver "$2"); for d in "$left" "$right"; do [ -e "$d" ] || { echo "deriver not in store: $d (substituted build; use the nvd row)"; exit 1; }; done; nix-diff "$left" "$right" 2>&1 || printf '\nnix-diff aborted: derivation closure incomplete locally (substituted builds); use the nvd row\n' ''];
      probes = ["nix-diff" "nix-store"];
      mode = "scratch";
    }
    {
      id = "nix-tree";
      label = "Closure browser (nix-tree)";
      argv = ["nix-tree"];
      cwd = flakeRoot;
      mode = "pane";
    }
    {
      id = "redeploy-check";
      label = "redeploy --check-only";
      argv = ["redeploy" "--check-only"];
      cwd = flakeRoot;
      mode = "pane";
    }
    {
      id = "nh-dry";
      label = "Switch dry run (nh darwin --dry)";
      argv = ["nh" "darwin" "switch" "--dry" flakeRoot];
      mode = "pane";
    }
    {
      id = "provision-doctor";
      label = "provision doctor";
      argv = ["provision" "doctor" "--json"];
      mode = "scratch";
      ft = "json";
    }
  ];

  toolFacts = {
    flake_root = flakeRoot;
    plugins =
      lib.mapAttrsToList (name: p: {
        inherit name;
        path = "${p}";
      })
      plugins;
    inherit grammars;
    format =
      {
        nix = ["alejandra"];
        sh = ["shfmt"];
        bash = ["shfmt"];
        lua = ["stylua"];
        toml = ["taplo"];
        sql = ["sqruff"];
      }
      // lib.genAttrs
      ["css" "html" "javascript" "javascriptreact" "json" "jsonc" "markdown" "typescript" "typescriptreact"]
      (_: ["prettier"]);
    # Lane shape is the contract: `ft` rows index by filetype, `workflow` attaches path-gated, `global` rides every buffer (plugins/lint.lua).
    lint = {
      ft = {
        nix = ["deadnix" "statix"];
        sh = ["shellcheck"];
        bash = ["shellcheck"];
        dockerfile = ["hadolint"];
      };
      workflow = ["zizmor"];
      global = ["typos"];
    };
    estate = estateRows;
  };

  # --- [SYNTAX_PROJECTION]
  # The owner scope table carries its own treesitter captures (design-language master scope map); hue, style, and capture binding all live in
  # theme.nix — a rebind there lands here with zero edits.
  syntaxFacts = {
    scopes =
      map (row: {
        inherit (row) name captures;
        color = row.color.hex;
        style = row.style or "";
      })
      config.estate.theme.syntaxScopes;
    roles =
      config.estate.theme.projections.rolesHex
      # Git-state vocabulary rows: colorscheme highlights read .color, gitsigns sign text reads .glyph (the editor gutter is a terminal render
      # surface); the ascii twin stays with persisted consumers.
      // {git = lib.mapAttrs (_: g: {inherit (g) color glyph;}) config.estate.theme.projections.gitHex;};
  };

  luarc =
    {"$schema" = "https://raw.githubusercontent.com/LuaLS/vscode-lua/master/setting/schema.json";}
    // servers.lua_ls.settings.Lua;

  genLuaModule = value: "-- Generated from the Forge Nix owner (apps/nvim/default.nix).\nreturn ${toLua value}\n";
in {
  # defaultEditor projects EDITOR and VISUAL as nvim into home.sessionVariables. withPython3 makes the wrapper build a store-owned
  # python3.withPackages [pynvim] host and seat it as vim.g.python3_host_prog ahead of every user Lua file.
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    withPython3 = true;
    initLua = builtins.readFile ./init.lua;
    plugins = lib.attrValues plugins;
    # Editor-only search engines for the snacks pickers and grug-far: ripgrep, fd, and ast-grep left the machine PATH for each project's mise.toml,
    # so the wrapper seats them on nvim's own PATH and the user profile stays project-owned.
    extraPackages = [pkgs.ripgrep pkgs.fd pkgs.ast-grep];
  };

  # Recursive tree link merges tracked sources with generated fact modules in one home-files derivation; new tracked Lua files deploy with zero rows.
  xdg.configFile = {
    "nvim/lua" = {
      source = ./lua;
      recursive = true;
    };
    "nvim/.luarc.json".text = builtins.toJSON luarc;
    "nvim/lua/estate/palette.lua".text = config.estate.theme.projections.luaPalette;
    "nvim/lua/estate/syntax.lua".text = genLuaModule syntaxFacts;
    "nvim/lua/estate/lsp.lua".text = genLuaModule {
      servers =
        lib.mapAttrs (_: row: {
          inherit (row) cmd filetypes root_markers settings;
        })
        servers;
    };
    "nvim/lua/estate/tools.lua".text = genLuaModule toolFacts;
    "nvim/lua/estate/chords.lua".text = genLuaModule config.estate.chords.nvim.rows;
  };
}
