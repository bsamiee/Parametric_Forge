-- Title         : darwin.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : configs/darwin/neovim/darwin.lua
-- ---------------------------------------------------------------------------
-- macOS-specific Neovim configuration

-- macOS-specific clipboard integration
vim.opt.clipboard = "unnamedplus"

-- macOS-specific font settings for GUI Neovim
if vim.g.neovide then
  vim.o.guifont = "SF Mono:h14"
  vim.g.neovide_input_macos_alt_is_meta = true
  vim.g.neovide_cursor_animation_length = 0.05
  vim.g.neovide_cursor_trail_size = 0.3
end

-- macOS-specific terminal integration
if vim.env.TERM_PROGRAM == "WezTerm" then
  vim.opt.termguicolors = true
  -- WezTerm-specific optimizations
  vim.opt.ttimeoutlen = 10
elseif vim.env.TERM_PROGRAM == "iTerm.app" then
  vim.opt.termguicolors = true
  -- iTerm2-specific optimizations
  vim.opt.ttimeoutlen = 10
elseif vim.env.TERM_PROGRAM == "Apple_Terminal" then
  -- Terminal.app has limited color support
  vim.opt.termguicolors = false
  vim.env.TERM = "xterm-256color"
end

-- macOS-specific key mappings
if vim.fn.has("mac") == 1 then
  -- Use Cmd key for common operations (if in GUI)
  if vim.g.neovide or vim.g.vscode then
    vim.keymap.set("n", "<D-s>", ":w<CR>", { desc = "Save file" })
    vim.keymap.set("n", "<D-q>", ":q<CR>", { desc = "Quit" })
    vim.keymap.set("n", "<D-w>", ":bd<CR>", { desc = "Close buffer" })
    vim.keymap.set("n", "<D-n>", ":enew<CR>", { desc = "New file" })
    vim.keymap.set("n", "<D-o>", ":e<CR>", { desc = "Open file" })
  end
  
  -- Alt/Option key mappings for terminal
  vim.keymap.set("n", "∆", ":m .+1<CR>==", { desc = "Move line down" })  -- Alt+j
  vim.keymap.set("n", "˚", ":m .-2<CR>==", { desc = "Move line up" })    -- Alt+k
  vim.keymap.set("v", "∆", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
  vim.keymap.set("v", "˚", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })
end

-- macOS-specific file operations
vim.opt.backupdir = vim.fn.expand("~/.local/state/nvim/backup")
vim.opt.directory = vim.fn.expand("~/.local/state/nvim/swap")
vim.opt.undodir = vim.fn.expand("~/.local/state/nvim/undo")

-- Create directories if they don't exist
local function ensure_dir(path)
  if vim.fn.isdirectory(path) == 0 then
    vim.fn.mkdir(path, "p")
  end
end

ensure_dir(vim.fn.expand("~/.local/state/nvim/backup"))
ensure_dir(vim.fn.expand("~/.local/state/nvim/swap"))
ensure_dir(vim.fn.expand("~/.local/state/nvim/undo"))

-- macOS-specific external tool integration
if vim.fn.executable("open") == 1 then
  -- Use macOS 'open' command for opening files/URLs
  vim.keymap.set("n", "gx", function()
    local url = vim.fn.expand("<cWORD>")
    vim.fn.system("open " .. vim.fn.shellescape(url))
  end, { desc = "Open URL/file with system default" })
end

-- macOS notification integration (if terminal-notifier is available)
if vim.fn.executable("terminal-notifier") == 1 then
  vim.api.nvim_create_user_command("Notify", function(opts)
    vim.fn.system("terminal-notifier -message " .. vim.fn.shellescape(opts.args) .. " -title 'Neovim'")
  end, { nargs = 1, desc = "Send macOS notification" })
end

-- macOS-specific LSP configuration
local lspconfig_ok, lspconfig = pcall(require, "lspconfig")
if lspconfig_ok then
  -- Use macOS-specific paths for language servers if needed
  local homebrew_prefix = vim.fn.system("brew --prefix"):gsub("\n", "")
  
  -- Example: Swift LSP (macOS-specific)
  if vim.fn.executable("sourcekit-lsp") == 1 then
    lspconfig.sourcekit.setup({
      cmd = { "sourcekit-lsp" },
      filetypes = { "swift", "objective-c", "objective-cpp" },
    })
  end
end

-- macOS-specific treesitter configuration
local treesitter_ok, treesitter_configs = pcall(require, "nvim-treesitter.configs")
if treesitter_ok then
  -- Use macOS-specific compiler if needed
  require("nvim-treesitter.install").compilers = { "clang", "gcc" }
end

-- macOS-specific telescope configuration
local telescope_ok, telescope = pcall(require, "telescope")
if telescope_ok then
  -- Use macOS-specific file browser
  vim.keymap.set("n", "<leader>fo", function()
    vim.fn.system("open " .. vim.fn.expand("%:p:h"))
  end, { desc = "Open current directory in Finder" })
end

-- macOS-specific autocmds
vim.api.nvim_create_augroup("DarwinSpecific", { clear = true })

-- Auto-save when losing focus (macOS app switching)
vim.api.nvim_create_autocmd("FocusLost", {
  group = "DarwinSpecific",
  pattern = "*",
  command = "silent! wa",
  desc = "Auto-save when losing focus",
})

-- Handle macOS dark mode changes
vim.api.nvim_create_autocmd("Signal", {
  group = "DarwinSpecific",
  pattern = "SIGUSR1",
  callback = function()
    -- Toggle between light and dark themes based on system appearance
    local appearance = vim.fn.system("defaults read -g AppleInterfaceStyle 2>/dev/null"):gsub("\n", "")
    if appearance == "Dark" then
      vim.opt.background = "dark"
    else
      vim.opt.background = "light"
    end
  end,
  desc = "Handle macOS appearance changes",
})

-- macOS-specific performance optimizations
if vim.fn.has("mac") == 1 then
  -- Optimize for macOS file system
  vim.opt.fsync = false  -- Disable fsync for better performance on APFS
  
  -- Use macOS-specific shell if available
  if vim.fn.executable("/opt/homebrew/bin/zsh") == 1 then
    vim.opt.shell = "/opt/homebrew/bin/zsh"
  elseif vim.fn.executable("/usr/local/bin/zsh") == 1 then
    vim.opt.shell = "/usr/local/bin/zsh"
  end
end

-- macOS-specific debugging
vim.api.nvim_create_user_command("DarwinInfo", function()
  local info = {
    "macOS Neovim Configuration Info:",
    "TERM_PROGRAM: " .. (vim.env.TERM_PROGRAM or "unknown"),
    "Clipboard: " .. vim.inspect(vim.opt.clipboard:get()),
    "Shell: " .. vim.opt.shell:get(),
    "GUI: " .. (vim.g.neovide and "Neovide" or "Terminal"),
    "Homebrew prefix: " .. vim.fn.system("brew --prefix 2>/dev/null"):gsub("\n", ""),
  }
  vim.notify(table.concat(info, "\n"), vim.log.levels.INFO, { title = "Darwin Config" })
end, { desc = "Show macOS-specific Neovim configuration info" })