# Title         : advanced-editors.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/programs/advanced-editors.nix
# ----------------------------------------------------------------------------
# Advanced text editors: neovim (modern Vim) with comprehensive configuration
# for development workflows. Provides LSP integration, plugin management,
# syntax highlighting, and extensive customization for professional code editing.

{
  config,
  lib,
  pkgs,
  ...
}:

{
  programs = {
    # --- Neovim Advanced Text Editor ----------------------------------
    # Modern, extensible text editor with Lua configuration and LSP support
    # Provides comprehensive development environment with plugins and customization
    # Note: Home-manager has neovim module - this shows comprehensive configuration
    
    neovim = {
      enable = true;
      
      # --- Core Configuration --------------------------------------
      # Basic Neovim settings and behavior
      defaultEditor = true;        # Set as system default editor
      viAlias = true;             # Create 'vi' alias
      vimAlias = true;            # Create 'vim' alias
      vimdiffAlias = true;        # Create 'vimdiff' alias
      
      # --- Plugin Management -----------------------------------
      # Plugin configuration using home-manager's plugin system
      plugins = with pkgs.vimPlugins; [
        # --- Core Plugins --------------------------------
        # Essential functionality plugins
        {
          plugin = lazy-nvim;
          type = "lua";
          config = ''
            -- Lazy.nvim plugin manager configuration
            require("lazy").setup({
              -- Plugin specifications will be loaded from separate files
              spec = {
                { import = "plugins" },
              },
              defaults = {
                lazy = false,
                version = false,
              },
              install = { colorscheme = { "tokyonight", "habamax" } },
              checker = { enabled = true },
              performance = {
                rtp = {
                  disabled_plugins = {
                    "gzip",
                    "matchit",
                    "matchparen",
                    "netrwPlugin",
                    "tarPlugin",
                    "tohtml",
                    "tutor",
                    "zipPlugin",
                  },
                },
              },
            })
          '';
        }
        
        # --- LSP and Completion --------------------------
        # Language Server Protocol and autocompletion
        {
          plugin = nvim-lspconfig;
          type = "lua";
          config = ''
            -- LSP configuration
            local lspconfig = require('lspconfig')
            local capabilities = require('cmp_nvim_lsp').default_capabilities()
            
            -- Configure language servers
            local servers = {
              'rust_analyzer',
              'pyright',
              'tsserver',
              'nil_ls',  -- Nix language server
              'lua_ls',
              'bashls',
              'jsonls',
              'yamlls',
              'marksman',  -- Markdown language server
            }
            
            for _, lsp in ipairs(servers) do
              lspconfig[lsp].setup({
                capabilities = capabilities,
                on_attach = function(client, bufnr)
                  -- LSP keybindings
                  local opts = { buffer = bufnr, silent = true }
                  vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
                  vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
                  vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
                  vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, opts)
                  vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
                  vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, opts)
                  vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
                  vim.keymap.set('n', '<leader>f', vim.lsp.buf.format, opts)
                end,
              })
            end
          '';
        }
        
        nvim-cmp              # Completion engine
        cmp-nvim-lsp          # LSP completion source
        cmp-buffer            # Buffer completion source
        cmp-path              # Path completion source
        cmp-cmdline           # Command line completion
        luasnip               # Snippet engine
        cmp_luasnip           # Snippet completion source
        
        # --- File Navigation and Management --------------
        # File tree and navigation plugins
        {
          plugin = nvim-tree-lua;
          type = "lua";
          config = ''
            -- File tree configuration
            require("nvim-tree").setup({
              sort_by = "case_sensitive",
              view = {
                width = 30,
                mappings = {
                  list = {
                    { key = "u", action = "dir_up" },
                  },
                },
              },
              renderer = {
                group_empty = true,
              },
              filters = {
                dotfiles = false,
                custom = { ".git", "node_modules", "target" },
              },
            })
            
            -- Keybinding to toggle file tree
            vim.keymap.set('n', '<leader>e', ':NvimTreeToggle<CR>', { silent = true })
          '';
        }
        
        {
          plugin = telescope-nvim;
          type = "lua";
          config = ''
            -- Telescope fuzzy finder configuration
            require('telescope').setup({
              defaults = {
                mappings = {
                  i = {
                    ["<C-n>"] = require('telescope.actions').cycle_history_next,
                    ["<C-p>"] = require('telescope.actions').cycle_history_prev,
                    ["<C-j>"] = require('telescope.actions').move_selection_next,
                    ["<C-k>"] = require('telescope.actions').move_selection_previous,
                  },
                },
              },
            })
            
            -- Telescope keybindings
            local builtin = require('telescope.builtin')
            vim.keymap.set('n', '<leader>ff', builtin.find_files, {})
            vim.keymap.set('n', '<leader>fg', builtin.live_grep, {})
            vim.keymap.set('n', '<leader>fb', builtin.buffers, {})
            vim.keymap.set('n', '<leader>fh', builtin.help_tags, {})
          '';
        }
        
        telescope-fzf-native-nvim  # Native FZF sorter for telescope
        plenary-nvim              # Lua utility library (required by telescope)
        
        # --- Git Integration -----------------------------
        # Git workflow and visualization plugins
        {
          plugin = gitsigns-nvim;
          type = "lua";
          config = ''
            -- Git signs configuration
            require('gitsigns').setup({
              signs = {
                add          = { text = '│' },
                change       = { text = '│' },
                delete       = { text = '_' },
                topdelete    = { text = '‾' },
                changedelete = { text = '~' },
                untracked    = { text = '┆' },
              },
              signcolumn = true,
              numhl      = false,
              linehl     = false,
              word_diff  = false,
              watch_gitdir = {
                follow_files = true
              },
              attach_to_untracked = true,
              current_line_blame = false,
              current_line_blame_opts = {
                virt_text = true,
                virt_text_pos = 'eol',
                delay = 1000,
                ignore_whitespace = false,
              },
              sign_priority = 6,
              update_debounce = 100,
              status_formatter = nil,
              max_file_length = 40000,
              preview_config = {
                border = 'single',
                style = 'minimal',
                relative = 'cursor',
                row = 0,
                col = 1
              },
            })
          '';
        }
        
        fugitive              # Git integration
        vim-gitgutter         # Git diff indicators
        
        # --- Syntax and Language Support ----------------
        # Enhanced syntax highlighting and language features
        {
          plugin = nvim-treesitter.withAllGrammars;
          type = "lua";
          config = ''
            -- Treesitter configuration
            require('nvim-treesitter.configs').setup({
              highlight = {
                enable = true,
                additional_vim_regex_highlighting = false,
              },
              indent = {
                enable = true,
              },
              incremental_selection = {
                enable = true,
                keymaps = {
                  init_selection = "gnn",
                  node_incremental = "grn",
                  scope_incremental = "grc",
                  node_decremental = "grm",
                },
              },
              textobjects = {
                select = {
                  enable = true,
                  lookahead = true,
                  keymaps = {
                    ["af"] = "@function.outer",
                    ["if"] = "@function.inner",
                    ["ac"] = "@class.outer",
                    ["ic"] = "@class.inner",
                  },
                },
              },
            })
          '';
        }
        
        # --- UI and Appearance ---------------------------
        # Theme and interface enhancement plugins
        {
          plugin = tokyonight-nvim;
          type = "lua";
          config = ''
            -- Tokyo Night theme configuration
            require("tokyonight").setup({
              style = "night",
              light_style = "day",
              transparent = false,
              terminal_colors = true,
              styles = {
                comments = { italic = true },
                keywords = { italic = true },
                functions = {},
                variables = {},
                sidebars = "dark",
                floats = "dark",
              },
              sidebars = { "qf", "help" },
              day_brightness = 0.3,
              hide_inactive_statusline = false,
              dim_inactive = false,
              lualine_bold = false,
            })
            
            -- Set colorscheme
            vim.cmd[[colorscheme tokyonight]]
          '';
        }
        
        {
          plugin = lualine-nvim;
          type = "lua";
          config = ''
            -- Status line configuration
            require('lualine').setup({
              options = {
                icons_enabled = true,
                theme = 'tokyonight',
                component_separators = { left = '', right = ''},
                section_separators = { left = '', right = ''},
                disabled_filetypes = {
                  statusline = {},
                  winbar = {},
                },
                ignore_focus = {},
                always_divide_middle = true,
                globalstatus = false,
                refresh = {
                  statusline = 1000,
                  tabline = 1000,
                  winbar = 1000,
                }
              },
              sections = {
                lualine_a = {'mode'},
                lualine_b = {'branch', 'diff', 'diagnostics'},
                lualine_c = {'filename'},
                lualine_x = {'encoding', 'fileformat', 'filetype'},
                lualine_y = {'progress'},
                lualine_z = {'location'}
              },
              inactive_sections = {
                lualine_a = {},
                lualine_b = {},
                lualine_c = {'filename'},
                lualine_x = {'location'},
                lualine_y = {},
                lualine_z = {}
              },
              tabline = {},
              winbar = {},
              inactive_winbar = {},
              extensions = {}
            })
          '';
        }
        
        nvim-web-devicons     # File type icons
        
        # --- Development Tools ---------------------------
        # Code formatting, linting, and development utilities
        {
          plugin = conform-nvim;
          type = "lua";
          config = ''
            -- Code formatting configuration
            require("conform").setup({
              formatters_by_ft = {
                lua = { "stylua" },
                python = { "isort", "black" },
                rust = { "rustfmt" },
                javascript = { { "prettierd", "prettier" } },
                typescript = { { "prettierd", "prettier" } },
                json = { { "prettierd", "prettier" } },
                yaml = { { "prettierd", "prettier" } },
                markdown = { { "prettierd", "prettier" } },
                nix = { "nixfmt" },
                sh = { "shfmt" },
              },
              format_on_save = {
                timeout_ms = 500,
                lsp_fallback = true,
              },
            })
            
            -- Format keybinding
            vim.keymap.set({ "n", "v" }, "<leader>mp", function()
              require("conform").format({
                lsp_fallback = true,
                async = false,
                timeout_ms = 500,
              })
            end, { desc = "Format file or range (in visual mode)" })
          '';
        }
        
        comment-nvim          # Smart commenting
        nvim-autopairs        # Auto-close brackets and quotes
        indent-blankline-nvim # Indentation guides
        
        # --- Terminal and System Integration ------------
        # Terminal and external tool integration
        {
          plugin = toggleterm-nvim;
          type = "lua";
          config = ''
            -- Terminal integration configuration
            require("toggleterm").setup({
              size = 20,
              open_mapping = [[<c-\>]],
              hide_numbers = true,
              shade_filetypes = {},
              shade_terminals = true,
              shading_factor = 2,
              start_in_insert = true,
              insert_mappings = true,
              persist_size = true,
              direction = "float",
              close_on_exit = true,
              shell = vim.o.shell,
              float_opts = {
                border = "curved",
                winblend = 0,
                highlights = {
                  border = "Normal",
                  background = "Normal",
                },
              },
            })
          '';
        }
      ];
      
      # --- Extra Configuration --------------------------------
      # Additional Lua configuration
      extraLuaConfig = ''
        -- General Neovim settings
        vim.opt.number = true
        vim.opt.relativenumber = true
        vim.opt.tabstop = 2
        vim.opt.shiftwidth = 2
        vim.opt.expandtab = true
        vim.opt.smartindent = true
        vim.opt.wrap = false
        vim.opt.swapfile = false
        vim.opt.backup = false
        vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
        vim.opt.undofile = true
        vim.opt.hlsearch = false
        vim.opt.incsearch = true
        vim.opt.termguicolors = true
        vim.opt.scrolloff = 8
        vim.opt.signcolumn = "yes"
        vim.opt.isfname:append("@-@")
        vim.opt.updatetime = 50
        vim.opt.colorcolumn = "80"
        
        -- Leader key
        vim.g.mapleader = " "
        
        -- Key mappings
        vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
        vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")
        vim.keymap.set("n", "J", "mzJ`z")
        vim.keymap.set("n", "<C-d>", "<C-d>zz")
        vim.keymap.set("n", "<C-u>", "<C-u>zz")
        vim.keymap.set("n", "n", "nzzzv")
        vim.keymap.set("n", "N", "Nzzzv")
        
        -- System clipboard integration
        vim.keymap.set({"n", "v"}, "<leader>y", [["+y]])
        vim.keymap.set("n", "<leader>Y", [["+Y]])
        vim.keymap.set({"n", "v"}, "<leader>d", [["_d]])
        
        -- Replace word under cursor
        vim.keymap.set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])
        
        -- Make file executable
        vim.keymap.set("n", "<leader>x", "<cmd>!chmod +x %<CR>", { silent = true })
        
        -- Quick save and quit
        vim.keymap.set("n", "<leader>w", "<cmd>w<CR>")
        vim.keymap.set("n", "<leader>q", "<cmd>q<CR>")
        
        -- Buffer navigation
        vim.keymap.set("n", "<leader>bn", "<cmd>bnext<CR>")
        vim.keymap.set("n", "<leader>bp", "<cmd>bprevious<CR>")
        vim.keymap.set("n", "<leader>bd", "<cmd>bdelete<CR>")
        
        -- Window navigation
        vim.keymap.set("n", "<C-h>", "<C-w>h")
        vim.keymap.set("n", "<C-j>", "<C-w>j")
        vim.keymap.set("n", "<C-k>", "<C-w>k")
        vim.keymap.set("n", "<C-l>", "<C-w>l")
        
        -- Resize windows
        vim.keymap.set("n", "<C-Up>", ":resize -2<CR>")
        vim.keymap.set("n", "<C-Down>", ":resize +2<CR>")
        vim.keymap.set("n", "<C-Left>", ":vertical resize -2<CR>")
        vim.keymap.set("n", "<C-Right>", ":vertical resize +2<CR>")
        
        -- Auto commands
        vim.api.nvim_create_autocmd("BufWritePre", {
          pattern = "*",
          callback = function()
            -- Remove trailing whitespace on save
            vim.cmd([[%s/\s\+$//e]])
          end,
        })
        
        vim.api.nvim_create_autocmd("FileType", {
          pattern = { "nix", "lua", "rust", "python", "javascript", "typescript" },
          callback = function()
            vim.opt_local.tabstop = 2
            vim.opt_local.shiftwidth = 2
            vim.opt_local.expandtab = true
          end,
        })
      '';
      
      # --- Extra Packages ----------------------------------
      # Additional packages needed for plugins and functionality
      extraPackages = with pkgs; [
        # Language servers
        rust-analyzer
        pyright
        nodePackages.typescript-language-server
        nil                    # Nix language server
        lua-language-server
        bash-language-server
        nodePackages.vscode-langservers-extracted  # JSON, HTML, CSS, ESLint
        yaml-language-server
        marksman              # Markdown language server
        
        # Formatters
        stylua               # Lua formatter
        black                # Python formatter
        isort                # Python import sorter
        rustfmt              # Rust formatter
        nodePackages.prettier # JavaScript/TypeScript/JSON/YAML formatter
        nixfmt               # Nix formatter
        shfmt                # Shell script formatter
        
        # Tools
        ripgrep              # Required by telescope
        fd                   # Required by telescope
        tree-sitter          # Syntax highlighting
        git                  # Git integration
        fzf                  # Fuzzy finder
      ];
    };
  };

  # --- Integration Notes -----------------------------------------------
  # 1. Neovim configuration uses home-manager's built-in module
  # 2. Plugin management handled through home-manager's plugin system
  # 3. LSP servers and formatters installed as extra packages
  # 4. Configuration uses Lua for modern Neovim setup
  # 5. Integration with system clipboard and external tools
  # 6. Comprehensive key bindings for efficient workflow
  
  # --- TODO: Future Improvements --------------------------------------
  # 1. Add support for debugging with nvim-dap
  # 2. Integrate with project-specific configurations
  # 3. Add support for AI-powered code completion
  # 4. Create language-specific configuration profiles
  # 5. Integrate with external tools (tmux, terminals, etc.)
  # 6. Add support for collaborative editing
  # 7. Create custom snippets and templates
  # 8. Add support for note-taking and documentation workflows
  
  # --- Usage Examples ------------------------------------------------
  # Common Neovim operations with this configuration:
  
  # File operations:
  # <leader>e                      # Toggle file tree
  # <leader>ff                     # Find files with telescope
  # <leader>fg                     # Live grep with telescope
  # <leader>fb                     # Browse buffers
  # <leader>w                      # Save file
  # <leader>q                      # Quit
  
  # LSP operations:
  # gd                             # Go to definition
  # K                              # Show hover information
  # <leader>rn                     # Rename symbol
  # <leader>ca                     # Code actions
  # <leader>f                      # Format file
  # gr                             # Find references
  
  # Git operations:
  # ]c / [c                        # Navigate git hunks
  # <leader>hs                     # Stage hunk
  # <leader>hr                     # Reset hunk
  # <leader>hp                     # Preview hunk
  
  # Terminal:
  # <C-\>                          # Toggle floating terminal
  
  # Navigation:
  # <C-h/j/k/l>                    # Navigate windows
  # <leader>bn/bp                  # Navigate buffers
  # J/K (visual mode)              # Move lines up/down
}