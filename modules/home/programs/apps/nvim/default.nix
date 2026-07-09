# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/apps/nvim/default.nix
# ----------------------------------------------------------------------------
# Store-owned Neovim rail and Lua fact generator. Home Manager deploys the
# pinned plugin set (zero network at first start) and one server/tool/chord/
# syntax inventory projects into generated forge/*.lua modules, the Claude LSP
# marketplace parity rows, and .luarc.json — editor and Claude LSP never
# drift. Lua owns runtime behavior; Nix owns packages, paths, and facts.
{
  config,
  lib,
  pkgs,
  ...
}: let
  toLua = lib.generators.toLua {};
  home = config.home.homeDirectory;
  flakeRoot = config.forge.lsp.flakeRoot;

  # --- Treesitter compat unit: neovim pin + nvim-treesitter main + parsers ----
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

  # Plugin admissions ride overlays/manifest.nix extensions.nvim-plugins rows.
  plugins = {
    dracula-vim = pkgs.vimPlugins.dracula-vim;
    snacks-nvim = pkgs.vimPlugins.snacks-nvim;
    nvim-treesitter = treesitter;
    conform-nvim = pkgs.vimPlugins.conform-nvim;
    nvim-lint = pkgs.vimPlugins.nvim-lint;
    grug-far-nvim = pkgs.vimPlugins.grug-far-nvim;
    render-markdown-nvim = pkgs.vimPlugins.render-markdown-nvim;
    overseer-nvim = pkgs.vimPlugins.overseer-nvim;
    trouble-nvim = pkgs.vimPlugins.trouble-nvim;
  };

  # One Lua fact inventory serves lua_ls settings (any workspace root, the
  # repo sources included) and the generated .luarc.json in the config dir.
  luaLibrary =
    ["${pkgs.neovim-unwrapped}/share/nvim/runtime/lua"]
    ++ lib.mapAttrsToList (_: p: "${p}/lua") plugins;

  # --- LSP inventory: one row family, two consumers ---------------------------
  # `cmd`/`filetypes`/`root_markers`/`settings` feed vim.lsp.config rows;
  # `claude` is the marketplace identity (plugin dir, command, args, extension
  # map) the health surface proves against .claude/lsp-marketplace. Commands
  # are bare names resolving through the Forge per-user profile — never
  # per-project shells (tool-resolution policy).
  servers = {
    nixd = rec {
      cmd = ["nixd"];
      filetypes = ["nix"];
      root_markers = ["flake.nix" ".git"];
      settings.nixd = config.forge.lsp.nixd;
      claude = {
        plugin = "nixd-lsp";
        command = "nixd";
        extensions.".nix" = "nix";
        inherit settings;
      };
    };
    lua_ls = {
      cmd = ["lua-language-server"];
      filetypes = ["lua"];
      root_markers = [".luarc.json" "stylua.toml" ".git"];
      # The generated .luarc.json only reaches the deployed config dir; the
      # settings row carries the same facts to every root — the repo sources
      # resolve at apps/nvim (stylua.toml) and keep vim/plugin awareness.
      # Claude side stays settings-free: store paths in a tracked .lsp.json
      # would drift on every plugin bump.
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
        command = "lua-language-server";
        extensions.".lua" = "lua";
      };
    };
    bashls = {
      cmd = ["bash-language-server" "start"];
      filetypes = ["sh" "bash"];
      root_markers = [".git"];
      # Editor side disables the LSP shellcheck lane: nvim-lint owns shellcheck
      # (namespace separation, one diagnostic per fault); Claude keeps it.
      settings.bashIde = {
        shellcheckPath = "";
        shfmt.path = "shfmt";
      };
      claude = {
        plugin = "bash-lsp";
        command = "bash-language-server";
        args = ["start"];
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
        command = "ty";
        args = ["server"];
        extensions = {
          ".py" = "python";
          ".pyi" = "python";
        };
      };
    };
    # TypeScript 7 (`typescript@7` upstream identity); nixpkgs typescript-go
    # still ships the dev snapshot binary as `tsgo` — a package-drift row.
    tsgo = {
      cmd = ["tsgo" "--lsp" "-stdio"];
      filetypes = ["typescript" "typescriptreact" "javascript" "javascriptreact"];
      root_markers = ["tsconfig.json" "package.json" ".git"];
      settings = {};
      claude = {
        plugin = "tsgo-lsp";
        command = "tsgo";
        args = ["--lsp" "-stdio"];
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
        command = "postgrestools";
        args = ["lsp-proxy"];
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
        command = "yaml-language-server";
        args = ["--stdio"];
        extensions = {
          ".yaml" = "yaml";
          ".yml" = "yaml";
        };
        inherit settings;
      };
    };
    roslyn_ls = {
      cmd = ["roslyn-language-server" "--stdio"];
      filetypes = ["cs"];
      root_markers = ["global.json" ".git"];
      settings = {};
      claude = {
        plugin = "roslyn-lsp";
        command = "roslyn-language-server";
        args = ["--stdio"];
        extensions = {
          ".cs" = "csharp";
          ".csx" = "csharp";
        };
      };
    };
  };

  # --- Tool rows: formatters, linters, search, provider, estate actions -------
  # Bare names resolve through the per-user profile; the health surface proves
  # resolution (`probes` names the real tools behind sh-wrapped rows). Estate
  # rows are the CA-1 projection inside the editor: `mode` selects the
  # dispatch arm (scratch = capture into a float, pane = zellij floating pane
  # for TUI/long-running commands).
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
      # Derivation-level diff of the last two generations. Substituted builds
      # leave drv gaps anywhere in the closure: toplevel absence rails before
      # launch, an inner-drv abort rails into the same typed verdict line.
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
    {
      id = "receipts-drift";
      label = "Nix drift receipts (tail)";
      argv = ["tail" "-n" "40" "${home}/Library/Logs/forge-nix-drift.receipts.log"];
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
    format = {
      nix = ["alejandra"];
      sh = ["shfmt"];
      bash = ["shfmt"];
      lua = ["stylua"];
      python = ["ruff_format"];
      toml = ["taplo"];
      yaml = ["yamlfmt"];
      json = ["prettier"];
      jsonc = ["prettier"];
      markdown = ["prettier"];
      css = ["prettier"];
      html = ["prettier"];
      javascript = ["prettier"];
      javascriptreact = ["prettier"];
      typescript = ["prettier"];
      typescriptreact = ["prettier"];
      sql = ["pg_format"];
    };
    lint = {
      nix = ["deadnix" "statix"];
      sh = ["shellcheck"];
      bash = ["shellcheck"];
      python = ["ruff"];
      yaml = ["yamllint"];
      dockerfile = ["hadolint"];
      # GitHub Actions lanes attach path-gated in plugins/lint.lua.
      workflow = ["actionlint" "zizmor"];
      global = ["typos"];
    };
    estate = estateRows;
  };

  # --- Syntax projection: theme owner scopes -> treesitter captures -----------
  # config.forge.theme.syntaxScopes is the pivot (design-language master scope
  # map); this correspondence is editor-projection knowledge only — hue and
  # style stay owner-decided, a rebind there lands here with zero edits.
  captureMap = {
    Comment = ["comment"];
    String = ["string" "character"];
    Escape = ["string.escape" "character.special"];
    Number = ["number" "number.float"];
    Constant = ["constant" "constant.builtin" "boolean"];
    Keyword = ["keyword"];
    Operator = ["operator" "keyword.operator"];
    Function = ["function" "function.method" "function.macro" "function.builtin"];
    Type = ["type" "type.builtin" "constructor"];
    Variable = ["variable" "variable.member" "property"];
    Parameter = ["variable.parameter"];
    Attribute = ["attribute"];
    Tag = ["tag"];
    Heading = ["markup.heading"];
    Bold = ["markup.strong"];
    Italic = ["markup.italic"];
    Link = ["markup.link" "markup.link.url" "string.special.url"];
    Inserted = ["diff.plus"];
    Deleted = ["diff.minus"];
    # Diagnostics own invalid code in the editor; no treesitter capture.
    Invalid = [];
  };
  syntaxFacts = {
    scopes =
      map (row: {
        inherit (row) name;
        color = row.color.hex;
        style = row.style or "";
        # Total lookup: a theme scope without a captureMap row faults at eval.
        captures = captureMap.${row.name};
      })
      config.forge.theme.syntaxScopes;
    roles = lib.mapAttrs (_: lib.mapAttrs (_: c: c.hex)) config.forge.theme.roles;
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

  # Python provider through the uv tool lane: pynvim's own interpreter shim,
  # isolated from ambient virtualenvs — never ambient discovery.
  home.activation.pynvimProvider = lib.hm.dag.entryAfter ["writeBoundary"] ''
    [ -x "$HOME/.local/bin/pynvim-python" ] || run ${pkgs.uv}/bin/uv tool install pynvim >/dev/null 2>&1 || true
  '';

  # Recursive tree link merges tracked sources with the generated fact modules
  # in one home-files derivation; new tracked Lua files deploy with zero rows.
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
    # Claude marketplace parity projection: identity rows the health surface
    # compares against <flake_root>/.claude/lsp-marketplace/<plugin>/.lsp.json.
    "forge/lsp/claude-marketplace.json".text = builtins.toJSON (
      lib.mapAttrs' (_: row:
        lib.nameValuePair row.claude.plugin ({
            command = row.claude.command;
            extensionToLanguage = row.claude.extensions;
          }
          // lib.optionalAttrs (row.claude ? args) {inherit (row.claude) args;}
          // lib.optionalAttrs (row.claude ? settings) {inherit (row.claude) settings;}))
      servers
    );
  };
}
