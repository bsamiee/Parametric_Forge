-- Title         : linux.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : configs/nixos/neovim/linux.lua
-- ---------------------------------------------------------------------------
-- Linux-specific Neovim configuration

-- Linux-specific clipboard integration
if vim.env.XDG_SESSION_TYPE == "wayland" then
  -- Wayland clipboard integration
  vim.g.clipboard = {
    name = "wl-clipboard",
    copy = {
      ["+"] = "wl-copy",
      ["*"] = "wl-copy --primary",
    },
    paste = {
      ["+"] = "wl-paste --no-newline",
      ["*"] = "wl-paste --no-newline --primary",
    },
    cache_enabled = 0,
  }
else
  -- X11 clipboard integration
  vim.g.clipboard = {
    name = "xclip",
    copy = {
      ["+"] = "xclip -selection clipboard",
      ["*"] = "xclip -selection primary",
    },
    paste = {
      ["+"] = "xclip -selection clipboard -o",
      ["*"] = "xclip -selection primary -o",
    },
    cache_enabled = 0,
  }
end

-- Use system clipboard
vim.opt.clipboard = "unnamedplus"

-- Linux-specific file operations using XDG directories
local xdg_state_home = vim.env.XDG_STATE_HOME or vim.fn.expand("~/.local/state")
local xdg_cache_home = vim.env.XDG_CACHE_HOME or vim.fn.expand("~/.cache")
local xdg_config_home = vim.env.XDG_CONFIG_HOME or vim.fn.expand("~/.config")

vim.opt.backupdir = xdg_state_home .. "/nvim/backup"
vim.opt.directory = xdg_state_home .. "/nvim/swap"
vim.opt.undodir = xdg_state_home .. "/nvim/undo"
vim.opt.viewdir = xdg_state_home .. "/nvim/view"

-- Create directories if they don't exist
local function ensure_dir(path)
  if vim.fn.isdirectory(path) == 0 then
    vim.fn.mkdir(path, "p")
  end
end

ensure_dir(xdg_state_home .. "/nvim/backup")
ensure_dir(xdg_state_home .. "/nvim/swap")
ensure_dir(xdg_state_home .. "/nvim/undo")
ensure_dir(xdg_state_home .. "/nvim/view")

-- Linux-specific external tool integration
if vim.fn.executable("xdg-open") == 1 then
  vim.keymap.set("n", "gx", function()
    local url = vim.fn.expand("<cWORD>")
    vim.fn.system("xdg-open " .. vim.fn.shellescape(url))
  end, { desc = "Open URL/file with system default" })
end

-- Linux notification integration
if vim.fn.executable("notify-send") == 1 then
  vim.api.nvim_create_user_command("Notify", function(opts)
    vim.fn.system("notify-send 'Neovim' " .. vim.fn.shellescape(opts.args))
  end, { nargs = 1, desc = "Send Linux notification" })
  
  -- Notify on long-running operations
  vim.api.nvim_create_autocmd("User", {
    pattern = "LspProgressUpdate",
    callback = function()
      -- Only notify for long operations
      vim.defer_fn(function()
        local clients = vim.lsp.get_active_clients()
        for _, client in ipairs(clients) do
          if client.progress and client.progress.percentage and client.progress.percentage == 100 then
            vim.fn.system("notify-send 'Neovim LSP' 'Operation completed for " .. client.name .. "'")
          end
        end
      end, 5000)
    end,
  })
end

-- Linux-specific terminal integration
if vim.env.TERM == "wezterm" then
  -- WezTerm-specific optimizations
  vim.opt.termguicolors = true
  vim.opt.ttimeoutlen = 10
  
  -- WezTerm integration functions
  vim.keymap.set("n", "<leader>tt", function()
    vim.fn.system("wezterm cli spawn --cwd " .. vim.fn.shellescape(vim.fn.getcwd()))
  end, { desc = "Open new WezTerm tab" })
  
elseif vim.env.TERM_PROGRAM == "gnome-terminal" then
  -- GNOME Terminal optimizations
  vim.opt.termguicolors = true
  
elseif vim.env.TERM == "xterm-256color" then
  -- Generic xterm optimizations
  vim.opt.termguicolors = true
  vim.opt.t_Co = 256
end

-- Linux-specific key mappings
vim.keymap.set("n", "<leader>lf", function()
  vim.fn.system("nautilus " .. vim.fn.shellescape(vim.fn.expand("%:p:h")))
end, { desc = "Open current directory in file manager" })

vim.keymap.set("n", "<leader>lt", function()
  vim.fn.system("wezterm start --cwd " .. vim.fn.shellescape(vim.fn.getcwd()))
end, { desc = "Open terminal in current directory" })

-- systemd integration
if vim.fn.executable("systemctl") == 1 then
  vim.api.nvim_create_user_command("SystemdStatus", function(opts)
    local service = opts.args
    if service == "" then
      vim.cmd("terminal systemctl --user status")
    else
      vim.cmd("terminal systemctl --user status " .. service)
    end
  end, { nargs = "?", desc = "Show systemd service status" })
  
  vim.api.nvim_create_user_command("SystemdLogs", function(opts)
    local service = opts.args
    if service == "" then
      vim.cmd("terminal journalctl --user -f")
    else
      vim.cmd("terminal journalctl --user -f -u " .. service)
    end
  end, { nargs = "?", desc = "Follow systemd service logs" })
end

-- Container integration
if vim.fn.executable("podman") == 1 then
  vim.api.nvim_create_user_command("PodmanPs", function()
    vim.cmd("terminal podman ps -a")
  end, { desc = "Show container status" })
  
  vim.api.nvim_create_user_command("PodmanImages", function()
    vim.cmd("terminal podman images")
  end, { desc = "Show container images" })
  
  vim.keymap.set("n", "<leader>cp", ":PodmanPs<CR>", { desc = "Show containers" })
  vim.keymap.set("n", "<leader>ci", ":PodmanImages<CR>", { desc = "Show images" })
end

-- Git integration with Linux-specific features
if vim.fn.executable("git") == 1 then
  -- Use Linux-specific diff tool
  vim.opt.diffopt:append("algorithm:patience")
  
  -- Git commit message template
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "gitcommit",
    callback = function()
      vim.opt_local.spell = true
      vim.opt_local.textwidth = 72
      vim.opt_local.colorcolumn = "50,72"
    end,
  })
end

-- Linux-specific LSP configuration
local lspconfig_ok, lspconfig = pcall(require, "lspconfig")
if lspconfig_ok then
  -- Use Linux-specific paths for language servers
  local nix_store_path = "/nix/store"
  
  -- Nix LSP configuration
  if vim.fn.executable("nil") == 1 then
    lspconfig.nil_ls.setup({
      settings = {
        ['nil'] = {
          formatting = {
            command = { "nixpkgs-fmt" },
          },
        },
      },
    })
  end
  
  -- Bash LSP configuration
  if vim.fn.executable("bash-language-server") == 1 then
    lspconfig.bashls.setup({
      filetypes = { "sh", "bash" },
    })
  end
  
  -- Python LSP configuration
  if vim.fn.executable("pyright") == 1 then
    lspconfig.pyright.setup({
      settings = {
        python = {
          analysis = {
            typeCheckingMode = "basic",
            useLibraryCodeForTypes = true,
          },
        },
      },
    })
  end
end

-- Linux-specific treesitter configuration
local treesitter_ok, treesitter_configs = pcall(require, "nvim-treesitter.configs")
if treesitter_ok then
  -- Use system compiler
  require("nvim-treesitter.install").compilers = { "gcc", "clang" }
  
  -- Linux-specific parser installation
  treesitter_configs.setup({
    ensure_installed = {
      "bash", "c", "cpp", "python", "rust", "go", "javascript", "typescript",
      "lua", "nix", "yaml", "toml", "json", "dockerfile", "make", "cmake"
    },
    highlight = {
      enable = true,
      additional_vim_regex_highlighting = false,
    },
    indent = {
      enable = true,
    },
  })
end

-- Linux-specific autocmds
vim.api.nvim_create_augroup("LinuxSpecific", { clear = true })

-- Auto-reload files changed outside of Neovim
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI" }, {
  group = "LinuxSpecific",
  pattern = "*",
  command = "if mode() != 'c' | checktime | endif",
  desc = "Auto-reload files changed outside Neovim",
})

-- Handle Linux desktop notifications for long operations
vim.api.nvim_create_autocmd("VimLeave", {
  group = "LinuxSpecific",
  callback = function()
    if vim.fn.executable("notify-send") == 1 then
      vim.fn.system("notify-send 'Neovim' 'Session ended'")
    end
  end,
  desc = "Notify when Neovim session ends",
})

-- Linux-specific performance optimizations
if vim.fn.has("linux") == 1 then
  -- Optimize for Linux file system
  vim.opt.fsync = false  -- Disable fsync for better performance on ext4/btrfs
  
  -- Use Linux-specific shell
  if vim.fn.executable("/run/current-system/sw/bin/zsh") == 1 then
    vim.opt.shell = "/run/current-system/sw/bin/zsh"
  elseif vim.fn.executable("/bin/bash") == 1 then
    vim.opt.shell = "/bin/bash"
  end
  
  -- Linux-specific swap behavior
  vim.opt.swapfile = true
  vim.opt.updatetime = 300
  vim.opt.updatecount = 100
end

-- Linux-specific debugging
vim.api.nvim_create_user_command("LinuxInfo", function()
  local info = {
    "Linux Neovim Configuration Info:",
    "XDG_SESSION_TYPE: " .. (vim.env.XDG_SESSION_TYPE or "unknown"),
    "XDG_CURRENT_DESKTOP: " .. (vim.env.XDG_CURRENT_DESKTOP or "unknown"),
    "TERM: " .. (vim.env.TERM or "unknown"),
    "Clipboard: " .. vim.inspect(vim.opt.clipboard:get()),
    "Shell: " .. vim.opt.shell:get(),
    "Backup dir: " .. vim.opt.backupdir:get()[1],
    "Undo dir: " .. vim.opt.undodir:get()[1],
    "systemctl available: " .. (vim.fn.executable("systemctl") == 1 and "yes" or "no"),
    "podman available: " .. (vim.fn.executable("podman") == 1 and "yes" or "no"),
    "xdg-open available: " .. (vim.fn.executable("xdg-open") == 1 and "yes" or "no"),
    "notify-send available: " .. (vim.fn.executable("notify-send") == 1 and "yes" or "no"),
  }
  vim.notify(table.concat(info, "\n"), vim.log.levels.INFO, { title = "Linux Config" })
end, { desc = "Show Linux-specific Neovim configuration info" })

-- Font configuration for GUI Neovim on Linux
if vim.g.neovide then
  vim.o.guifont = "JetBrains Mono:h12"
  vim.g.neovide_scale_factor = 1.0
  vim.g.neovide_transparency = 0.95
  vim.g.neovide_cursor_animation_length = 0.05
  vim.g.neovide_cursor_trail_size = 0.3
end