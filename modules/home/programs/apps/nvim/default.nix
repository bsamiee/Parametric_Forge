# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/apps/nvim/default.nix
# ----------------------------------------------------------------------------
# Store-owned Neovim rail and Lua fact generator. Home Manager deploys the pinned plugin set (zero network at first start) and one
# server/tool/chord/syntax inventory projects into generated forge/*.lua modules, the Claude LSP marketplace parity rows, and .luarc.json —
# editor and Claude LSP never drift. Lua owns runtime behavior; Nix owns packages, paths, and facts.
{
  config,
  lib,
  pkgs,
  ...
}: let
  toLua = lib.generators.toLua {};
  home = config.home.homeDirectory;
  flakeRoot = config.forge.lsp.flakeRoot;
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

  # Plugin admissions ride overlays/manifest.nix extensions.nvim-plugins rows; a new plugin is one name here plus its setup owner in lua/plugins/.
  plugins =
    lib.genAttrs [
      "dracula-vim"
      "snacks-nvim"
      "nvim-treesitter-textobjects"
      "conform-nvim"
      "nvim-lint"
      "gitsigns-nvim"
      "lualine-nvim"
      "grug-far-nvim"
      "render-markdown-nvim"
      "overseer-nvim"
      "trouble-nvim"
    ] (name: pkgs.vimPlugins.${name})
    // {nvim-treesitter = treesitter;};

  # One Lua fact inventory serves lua_ls settings (any workspace root, the repo sources included) and the generated .luarc.json in the config dir.
  luaLibrary =
    ["${pkgs.neovim-unwrapped}/share/nvim/runtime/lua"]
    ++ lib.mapAttrsToList (_: p: "${p}/lua") plugins;

  # --- [LSP_INVENTORY_ONE_ROW_FAMILY_TWO_CONSUMERS]
  # `cmd`/`filetypes`/`root_markers`/`settings` feed vim.lsp.config rows; `claude` is the marketplace identity (plugin dir, extension map,
  # optional settings override, optional lifecycle rows startupTimeout/shutdownTimeout/maxRestarts in milliseconds and counts) the health
  # surface proves against .claude/lsp-marketplace — command/args derive from `cmd` at projection, so the tracked .lsp.json is a copy of the
  # generated row and any hand edit there is drift. A plugin's tracked file change bumps its plugin.json version: Claude Code pins the
  # installed cache to that version and refreshes it only on a bump (the activation row below runs the refresh).
  # Commands are bare names resolving through the Forge per-user profile — never per-project shells (tool-resolution policy).
  servers = {
    nixd = rec {
      cmd = ["nixd"];
      filetypes = ["nix"];
      root_markers = ["flake.nix" ".git"];
      settings.nixd = config.forge.lsp.nixd;
      claude = {
        plugin = "nixd-lsp";
        extensions.".nix" = "nix";
        inherit settings;
      };
    };
    lua_ls = {
      cmd = ["lua-language-server"];
      filetypes = ["lua"];
      root_markers = [".luarc.json" "stylua.toml" ".git"];
      # The generated .luarc.json reaches only the deployed config dir; the settings row carries the same facts to every root, so repo sources
      # resolve at apps/nvim (stylua.toml) with vim/plugin awareness. The Claude lane below carries only the drift-free globals, since a
      # store-path workspace.library would drift the tracked .lsp.json on every plugin bump.
      settings.Lua = {
        runtime.version = "LuaJIT";
        workspace = {
          checkThirdParty = false;
          library = luaLibrary;
        };
        diagnostics.globals = ["vim" "Snacks"];
      };
      claude = {
        plugin = "lua-lsp";
        extensions.".lua" = "lua";
        settings.Lua.diagnostics.globals = ["vim" "Snacks"];
      };
    };
    bashls = {
      cmd = ["bash-language-server" "start"];
      filetypes = ["sh" "bash"];
      root_markers = [".git"];
      # Editor side disables the LSP shellcheck lane: nvim-lint owns shellcheck (namespace separation, one diagnostic per fault); Claude keeps it.
      settings.bashIde = {
        shellcheckPath = "";
        shfmt.path = "shfmt";
      };
      claude = {
        plugin = "bash-lsp";
        extensions = {
          ".sh" = "shellscript";
          ".bash" = "shellscript";
        };
        settings.bashIde = {
          shellcheckPath = "shellcheck";
          shfmt.path = "shfmt";
        };
      };
    };
    ty = {
      cmd = ["ty" "server"];
      filetypes = ["python"];
      root_markers = ["pyproject.toml" ".git"];
      settings = {};
      claude = {
        plugin = "ty-lsp";
        extensions = {
          ".py" = "python";
          ".pyi" = "python";
        };
      };
    };
    # TypeScript 7 (`typescript@7` upstream identity); nixpkgs typescript-go still ships the dev snapshot binary as `tsgo` — a package-drift row.
    tsgo = {
      cmd = ["tsgo" "--lsp" "-stdio"];
      filetypes = ["typescript" "typescriptreact" "javascript" "javascriptreact"];
      root_markers = ["tsconfig.json" "package.json" ".git"];
      settings = {};
      claude = {
        plugin = "tsgo-lsp";
        extensions = {
          ".ts" = "typescript";
          ".tsx" = "typescriptreact";
          ".mts" = "typescript";
          ".cts" = "typescript";
          ".js" = "javascript";
          ".jsx" = "javascriptreact";
          ".mjs" = "javascript";
          ".cjs" = "javascript";
        };
      };
    };
    postgres_lsp = {
      cmd = ["postgrestools" "lsp-proxy"];
      filetypes = ["sql"];
      root_markers = ["postgrestools.jsonc" ".git"];
      settings = {};
      claude = {
        plugin = "postgres-lsp";
        extensions.".sql" = "sql";
      };
    };
    yamlls = rec {
      cmd = ["yaml-language-server" "--stdio"];
      filetypes = ["yaml"];
      root_markers = [".git"];
      settings.yaml = {
        schemaStore.enable = true;
        validate = true;
      };
      claude = {
        plugin = "yaml-lsp";
        extensions = {
          ".yaml" = "yaml";
          ".yml" = "yaml";
        };
        inherit settings;
      };
    };
    # Roslyn loads no project until a client sends `solution/open`; `--autoLoadProjects` makes the server discover and load them from the
    # workspace folders itself, so generic clients (Claude Code, vim.lsp without roslyn.nvim) get project-scoped diagnostics, not misc-files mode.
    # `--logLevel` and `--extensionLogDirectory` are mandatory server arguments; the server creates the directory.
    # TOML: taplo's LSP mode; the SchemaStore catalog is on by default, and the PATH wrapper seats the house taplo.toml only where no project config exists.
    taplo = {
      cmd = ["taplo" "lsp" "stdio"];
      filetypes = ["toml"];
      root_markers = [".taplo.toml" "taplo.toml" ".git"];
      settings = {};
      claude = {
        plugin = "taplo-lsp";
        extensions.".toml" = "toml";
      };
    };
    # Biome's LSP proxy: the editor attaches it beside tsgo for lint diagnostics on every Biome language; the Claude lane claims only the
    # extensions no other row owns (JSON, JSONC, CSS) because Claude Code starts one server per extension, first registered wins.
    biome = {
      cmd = ["biome" "lsp-proxy"];
      filetypes = ["json" "jsonc" "css" "javascript" "javascriptreact" "typescript" "typescriptreact"];
      root_markers = ["biome.json" "biome.jsonc" ".git"];
      settings = {};
      claude = {
        plugin = "biome-lsp";
        extensions = {
          ".json" = "json";
          ".jsonc" = "jsonc";
          ".css" = "css";
        };
      };
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
      claude = {
        plugin = "roslyn-lsp";
        extensions = {
          ".cs" = "csharp";
          ".csx" = "csharp";
        };
        # Solution load on a large workspace outpaces the default startup window (upstream's own plugin seats 120s); a crash loop stops after
        # three restarts.
        startupTimeout = 120000;
        maxRestarts = 3;
      };
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
      label = "forge-redeploy --check-only";
      argv = ["forge-redeploy" "--check-only"];
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
      label = "forge-provision doctor";
      argv = ["forge-provision" "doctor" "--json"];
      mode = "scratch";
      ft = "json";
    }
    {
      id = "mcp-doctor";
      label = "forge-mcp doctor";
      argv = ["forge-mcp" "doctor"];
      mode = "scratch";
    }
    {
      id = "receipts-redeploy";
      label = "Redeploy receipts (tail)";
      argv = ["tail" "-n" "40" "${home}/Library/Logs/forge-redeploy.receipts.log"];
      mode = "scratch";
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
    provider.python3 = "${home}/.local/bin/pynvim-python";
    format =
      {
        nix = ["alejandra"];
        sh = ["shfmt"];
        bash = ["shfmt"];
        lua = ["stylua"];
        python = ["ruff_format"];
        toml = ["taplo"];
        yaml = ["yamlfmt"];
        sql = ["sqruff"];
        cs = ["csharpier"];
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
        python = ["ruff"];
        yaml = ["yamllint"];
        dockerfile = ["hadolint"];
      };
      workflow = ["actionlint" "zizmor"];
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
      config.forge.theme.syntaxScopes;
    roles =
      config.forge.theme.projections.rolesHex
      # Git-state vocabulary rows: colorscheme highlights read .color, gitsigns sign text reads .glyph (the editor gutter is a terminal render
      # surface); the ascii twin stays with persisted consumers.
      // {git = lib.mapAttrs (_: g: {inherit (g) color glyph;}) config.forge.theme.projections.gitHex;};
  };

  luarc =
    {"$schema" = "https://raw.githubusercontent.com/LuaLS/vscode-lua/master/setting/schema.json";}
    // servers.lua_ls.settings.Lua;

  genLuaModule = value: "-- Generated from the Forge Nix owner (apps/nvim/default.nix).\nreturn ${toLua value}\n";
in {
  # defaultEditor projects EDITOR and VISUAL as nvim into home.sessionVariables.
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    initLua = builtins.readFile ./init.lua;
    plugins = lib.attrValues plugins;
  };

  # Python provider through the uv tool lane: pynvim's own interpreter shim, isolated from ambient virtualenvs — never ambient discovery.
  home.activation.pynvimProvider = lib.hm.dag.entryAfter ["writeBoundary"] ''
    [ -x "$HOME/.local/bin/pynvim-python" ] \
      || run ${pkgs.uv}/bin/uv tool install pynvim >/dev/null 2>&1 \
      || echo "pynvim provider install deferred; :checkhealth forge proves the lane" >&2
  '';

  # Recursive tree link merges tracked sources with generated fact modules in one home-files derivation; new tracked Lua files deploy with zero rows.
  xdg.configFile = {
    "nvim/lua" = {
      source = ./lua;
      recursive = true;
    };
    "nvim/.luarc.json".text = builtins.toJSON luarc;
    "nvim/lua/forge/palette.lua".text = config.forge.theme.projections.luaPalette;
    "nvim/lua/forge/syntax.lua".text = genLuaModule syntaxFacts;
    "nvim/lua/forge/lsp.lua".text = genLuaModule {
      servers =
        lib.mapAttrs (_: row: {
          inherit (row) cmd filetypes root_markers settings;
        })
        servers;
    };
    "nvim/lua/forge/tools.lua".text = genLuaModule toolFacts;
    "nvim/lua/forge/chords.lua".text = genLuaModule config.forge.chords.nvim.rows;
    # Claude marketplace parity projection: identity rows the health surface compares against <flake_root>/.claude/lsp-marketplace/<plugin>/
    # .lsp.json. command/args are one fact — the server `cmd` row — projected here.
    "forge/lsp/claude-marketplace.json".text = builtins.toJSON (
      lib.mapAttrs' (_: row:
        lib.nameValuePair row.claude.plugin ({
            command = builtins.head row.cmd;
            extensionToLanguage = row.claude.extensions;
          }
          // lib.optionalAttrs (builtins.tail row.cmd != []) {args = builtins.tail row.cmd;}
          // lib.optionalAttrs (row.claude ? settings) {inherit (row.claude) settings;}
          // lib.filterAttrs (name: _: builtins.elem name ["startupTimeout" "shutdownTimeout" "maxRestarts"]) row.claude))
      servers
    );
  };

  # Claude Code consumes the marketplace only once registered; installing a plugin is an operator decision per scope
  # (`claude plugin install <plugin>@forge-lsp --scope user|project`), never an activation side effect. Directory marketplaces copy each
  # installed plugin into ~/.claude/plugins/cache and refresh that copy only on `plugin update`, so this row converges what IS installed:
  # register the marketplace when absent, update an installed plugin whose cached .lsp.json differs from the tracked file. The claude binary
  # is a native install outside Nix; its absence defers the row, and `:checkhealth forge` proves the state.
  home.activation.claudeLspPlugins = lib.hm.dag.entryAfter ["writeBoundary"] (let
    plugins = lib.concatStringsSep " " (lib.mapAttrsToList (_: row: row.claude.plugin) servers);
  in ''
    claude_bin="$HOME/.local/bin/claude"
    market="${flakeRoot}/.claude/lsp-marketplace"
    if [ -x "$claude_bin" ] && [ -d "$market" ]; then
      known="$HOME/.claude/plugins/known_marketplaces.json"
      installed="$HOME/.claude/plugins/installed_plugins.json"
      if ! ${pkgs.jq}/bin/jq -e '."forge-lsp"' "$known" >/dev/null 2>&1; then
        run "$claude_bin" plugin marketplace add "$market" >/dev/null 2>&1 || echo "forge-lsp marketplace registration deferred" >&2
      fi
      for plugin in ${plugins}; do
        cached="$(${pkgs.jq}/bin/jq -r --arg id "$plugin@forge-lsp" '.plugins[$id][0].installPath // empty' "$installed" 2>/dev/null)"
        if [ -n "$cached" ] && ! cmp -s "$cached/.lsp.json" "$market/$plugin/.lsp.json"; then
          run "$claude_bin" plugin update "$plugin@forge-lsp" >/dev/null 2>&1 || echo "$plugin@forge-lsp update deferred" >&2
        fi
      done
    else
      echo "claude binary or lsp-marketplace absent; Claude LSP plugin reconcile deferred" >&2
    fi
  '');
}
