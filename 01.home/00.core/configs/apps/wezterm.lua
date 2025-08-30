-- Title         : wezterm.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : 01.home/00.core/configs/apps/wezterm.lua
-- ----------------------------------------------------------------------------
-- WezTerm terminal configuration with workspace management
local wezterm = require("wezterm")
local act = wezterm.action
local mux = wezterm.mux
local config = wezterm.config_builder()
-- Plugins ──────────────────────────────────────────────────────────────────
local workspace_switcher = wezterm.plugin.require("https://github.com/MLFlexer/smart_workspace_switcher.wezterm")
-- Path Configuration (XDG-compliant) ───────────────────────────────────────
-- Use environment variables from Nix configuration
local XDG = {
	CONFIG_HOME = os.getenv("XDG_CONFIG_HOME") or os.getenv("HOME") .. "/.config",
	DATA_HOME = os.getenv("XDG_DATA_HOME") or os.getenv("HOME") .. "/.local/share",
	STATE_HOME = os.getenv("XDG_STATE_HOME") or os.getenv("HOME") .. "/.local/state",
	CACHE_HOME = os.getenv("XDG_CACHE_HOME") or os.getenv("HOME") .. "/.cache",
	RUNTIME_DIR = os.getenv("XDG_RUNTIME_DIR") or os.getenv("HOME") .. "/Library/Caches/TemporaryItems",
}
-- WezTerm-specific paths from environment
local WEZTERM_PATHS = {
	CONFIG_DIR = os.getenv("WEZTERM_CONFIG_DIR") or XDG.CONFIG_HOME .. "/wezterm",
	RUNTIME_DIR = os.getenv("WEZTERM_RUNTIME_DIR") or XDG.STATE_HOME .. "/wezterm",
	LOG_DIR = os.getenv("WEZTERM_LOG_DIR") or XDG.STATE_HOME .. "/wezterm",
}
-- Domain Configuration ─────────────────────────────────────────────────────
local DOMAINS = {
	persistent = {
		name = "persistent",
		socket_path = WEZTERM_PATHS.RUNTIME_DIR .. "/sock",
	},
	ssh = {}, -- Populated from config file if exists
}
-- Appearance Constants ─────────────────────────────────────────────────────
local APPEARANCE = {
	color_scheme = "Dracula (base16)",
	background_opacity = 0.85,
	blur_radius = 20,
	inactive_pane = { saturation = 0.75, brightness = 0.8 },
}
-- Daemon Configuration (Persistent Sessions) ───────────────────────────────
-- Note: XDG directories are created by xdg.nix activation script
config.daemon_options = {
	stdout = WEZTERM_PATHS.LOG_DIR .. "/daemon.stdout",
	stderr = WEZTERM_PATHS.LOG_DIR .. "/daemon.stderr",
	pid_file = WEZTERM_PATHS.RUNTIME_DIR .. "/daemon.pid",
}
-- Unix domains for persistent multiplexer
config.unix_domains = {
	{
		name = DOMAINS.persistent.name,
		socket_path = DOMAINS.persistent.socket_path,
		no_serve_automatically = false,
	},
}
-- Make persistent domain the default
config.default_domain = "persistent"
-- Appearance ───────────────────────────────────────────────────────────────
config.color_scheme = APPEARANCE.color_scheme
config.window_background_opacity = APPEARANCE.background_opacity
config.macos_window_background_blur = APPEARANCE.blur_radius
config.inactive_pane_hsb = APPEARANCE.inactive_pane
local palette = wezterm.color.get_builtin_schemes()[APPEARANCE.color_scheme]
local colors = {
	bg = palette.background, -- #282a36
	fg = palette.foreground, -- #f8f8f2
	red = "#ff5555",
	green = "#50fa7b",
	yellow = "#f1fa8c",
	blue = "#6272a4",
	cyan = "#8be9fd",
	purple = "#bd93f9",
	orange = "#ffb86c",
	pink = "#ff79c6",
}
-- Icons ────────────────────────────────────────────────────────────────────
local icons = {
	process = {
		-- Shells (nil = don't show icon for shells)
		["zsh"] = nil,
		["bash"] = nil,
		["fish"] = nil,
		-- Development Tools
		["cargo"] = wezterm.nerdfonts.dev_rust,
		["git"] = wezterm.nerdfonts.dev_git,
		["go"] = wezterm.nerdfonts.seti_go,
		["lua"] = wezterm.nerdfonts.seti_lua,
		["node"] = wezterm.nerdfonts.md_hexagon,
		["python"] = wezterm.nerdfonts.dev_python,
		["python3"] = wezterm.nerdfonts.dev_python,
		["ruby"] = wezterm.nerdfonts.dev_ruby_rough,
		-- Text Editors
		["nvim"] = wezterm.nerdfonts.custom_vim,
		["vim"] = wezterm.nerdfonts.dev_vim,
		["code"] = wezterm.nerdfonts.md_microsoft_visual_studio_code,
		["emacs"] = wezterm.nerdfonts.custom_emacs,
		-- Container and Cloud Tools
		["docker"] = wezterm.nerdfonts.linux_docker,
		["docker-compose"] = wezterm.nerdfonts.linux_docker,
		["kubectl"] = wezterm.nerdfonts.md_kubernetes,
		-- Utilities
		["xh"] = wezterm.nerdfonts.md_waves,
		["gh"] = wezterm.nerdfonts.dev_github_badge,
		["make"] = wezterm.nerdfonts.seti_makefile,
		["sudo"] = wezterm.nerdfonts.fa_hashtag,
		["lazygit"] = wezterm.nerdfonts.dev_github_alt,
		["htop"] = wezterm.nerdfonts.md_chart_line,
		["btop"] = wezterm.nerdfonts.md_chart_areaspline,
		-- Additional utilities
		["ssh"] = wezterm.nerdfonts.md_ssh,
		["tmux"] = wezterm.nerdfonts.cod_terminal_tmux,
		["less"] = wezterm.nerdfonts.md_file_document,
		["man"] = wezterm.nerdfonts.md_book_open_variant,
	},
	directory = {
		home = wezterm.nerdfonts.md_home,
		config = wezterm.nerdfonts.md_cog,
		git = wezterm.nerdfonts.dev_git,
		download = wezterm.nerdfonts.md_download,
		documents = wezterm.nerdfonts.md_file_document_box,
		images = wezterm.nerdfonts.md_image,
		video = wezterm.nerdfonts.md_video,
		music = wezterm.nerdfonts.md_music,
		desktop = wezterm.nerdfonts.md_desktop_mac,
		code = wezterm.nerdfonts.md_code_braces,
	},
	ui = {
		zoom = wezterm.nerdfonts.md_magnify,
		workspace = wezterm.nerdfonts.md_television_guide,
	},
}
-- Font Configuration ───────────────────────────────────────────────────────
-- Note: All fonts are installed via 00.system/fonts.nix with automatic icon patching
-- The font-patcher.nix ensures all fonts have Nerd Font icons available
-- Available Geist Mono weights: Thin, ExtraLight, Light, Regular, Medium, SemiBold, Bold, ExtraBold, Black
local FONT = {
	family = wezterm.font_with_fallback({
		{ family = "GeistMono Nerd Font", weight = "Regular" }, -- Primary: Correct name from font-patcher
		{ family = "Geist Mono Nerd Font", weight = "Regular" }, -- Alternative name
		{ family = "Iosevka Nerd Font", weight = "Regular" }, -- Fallback mono
		"Symbols Nerd Font", -- Icon fallback: nerd-fonts.symbols-only
	}),
	size = 12,
	line_height = 0.85,
}
-- Fonts & Cursor ───────────────────────────────────────────────────────────
config.font = FONT.family
config.font_size = FONT.size
config.line_height = FONT.line_height
config.force_reverse_video_cursor = true
config.default_cursor_style = "BlinkingBar"
config.cursor_thickness = 2
config.cursor_blink_rate = 250
-- Frame ────────────────────────────────────────────────────────────────────
config.window_decorations = "RESIZE"
config.window_padding = { left = 15, right = 15, top = 5, bottom = 5 }
config.initial_cols = 120
config.initial_rows = 34
-- Tab‑bar ──────────────────────────────────────────────────────────────────
local invisible = "rgba(0,0,0,0)"
local window_bg = "rgba(40, 42, 54, 0.75)"
config.use_fancy_tab_bar = false
config.show_tabs_in_tab_bar = true
config.tab_max_width = 120
config.window_frame = {
	active_titlebar_bg = invisible,
	inactive_titlebar_bg = invisible,
}
config.colors = {
	tab_bar = {
		background = window_bg,
		inactive_tab_edge = invisible,
		active_tab = { bg_color = colors.cyan, fg_color = "#282a36" }, --- Explicit fg for editors contrast
		inactive_tab = { bg_color = window_bg, fg_color = colors.fg },
		inactive_tab_hover = { bg_color = colors.blue, fg_color = colors.fg },
		new_tab = { bg_color = window_bg, fg_color = colors.pink },
		new_tab_hover = { bg_color = colors.pink, fg_color = colors.fg },
	},
}
--- Host-specific colors
local host_bg = {
	prod = colors.red,
	staging = colors.yellow,
	dev = colors.green,
}
-- SSH Domains Configuration ────────────────────────────────────────────────
-- SSH domain setup and color coding
local function setup_ssh_domains()
	-- WezTerm SSH domains enable persistent multiplexed sessions to remote servers
	-- These use your SSH config (~/.ssh/config) for authentication
	-- Add entries here when you need WezTerm workspace management on a server
	-- Define your SSH domains directly here
	-- WezTerm will use your SSH config (from 01.home/ssh.nix) for connection details
	local ssh_domains = {
		-- Example configurations (uncomment and modify as needed):
		-- {
		--     name = "dev-server",
		--     remote_address = "dev-server",  -- Must match SSH config host
		--     multiplexing = "WezTerm",       -- Use WezTerm's multiplexer
		-- },
		-- {
		--     name = "prod",
		--     remote_address = "prod.example.com",
		--     multiplexing = "None",  -- Direct SSH without multiplexing
		-- },
	}
	-- Apply color coding based on domain names
	for _, domain in ipairs(ssh_domains) do
		if domain.name then
			-- Color tabs based on environment keywords
			if domain.name:match("prod") or domain.name:match("production") then
				host_bg[domain.name] = colors.red
			elseif domain.name:match("staging") or domain.name:match("stage") then
				host_bg[domain.name] = colors.yellow
			elseif domain.name:match("dev") or domain.name:match("development") then
				host_bg[domain.name] = colors.green
			else
				host_bg[domain.name] = colors.blue -- Default for other SSH domains
			end
		end
	end
	return ssh_domains
end
config.ssh_domains = setup_ssh_domains()
-- Helper Functions ─────────────────────────────────────────────────────────
-- Mode definitions for cleaner lookup
local MODE_DEFINITIONS = {
	search_mode = { name = "SEARCH", color = colors.yellow },
	copy_mode = { name = "COPY", color = colors.cyan },
	resize_mode = { name = "RESIZE", color = colors.orange },
	window_mode = { name = "WINDOW", color = colors.pink },
}
local function check_visual_mode(window, pane, key_table)
	if key_table == "copy_mode" then
		return false
	end
	local selection = window:get_selection_text_for_pane(pane)
	return selection and selection ~= ""
end
local function check_alt_screen_mode(pane)
	if not pane:is_alt_screen_active() then
		return false
	end
	local process = pane:get_foreground_process_name()
	if not process then
		return true
	end
	process = process:match("([^/\\]+)$") or process
	return process ~= "nvim" and process ~= "vim" and process ~= "emacs"
end
local function get_current_mode(window, pane)
	local key_table = window:active_key_table()
	-- Check for predefined key table modes
	if key_table and MODE_DEFINITIONS[key_table] then
		local mode = MODE_DEFINITIONS[key_table]
		return mode.name, mode.color
	end
	-- Check for visual mode (selection without copy mode)
	if check_visual_mode(window, pane, key_table) then
		return "VISUAL", colors.purple
	end
	-- Check for alt screen mode (full-screen apps, not editors)
	if check_alt_screen_mode(pane) then
		return "ALT", colors.blue
	end
	-- Check for unknown key tables
	if key_table then
		return key_table:upper():gsub("_", " "), colors.pink
	end
	return "NORMAL", colors.green
end
--- Get process info for tab
local function get_process_info(tab)
	local pane = tab.active_pane
	if not pane then
		return nil, nil
	end
	local process = pane.foreground_process_name
	if not process or process == "" then
		-- Try to get it from the pane object if it's a live pane
		local ok, proc_name = pcall(function()
			return pane:get_foreground_process_name()
		end)
		if ok then
			process = proc_name
		end
	end
	if not process or process == "" then
		return nil, nil
	end
	-- Extract just the process name
	process = process:match("([^/\\]+)$") or process
	-- Get icon from our consolidated icon table
	local icon = icons.process[process]
	-- Don't show icons for shells (they return nil)
	if icon == nil and (process == "zsh" or process == "bash" or process == "fish") then
		return nil, nil
	end
	return process, icon
end
--- Path processing utilities
local PATH_ALIASES = {
	["~/Development"] = icons.directory.code,
	["~/Documents"] = icons.directory.documents,
	["~/Downloads"] = icons.directory.download,
	["~/Desktop"] = icons.directory.desktop,
	["~/.config"] = icons.directory.config,
	["~/Code"] = icons.directory.code,
}
local function extract_path_from_uri(uri)
	if not uri then
		return nil
	end
	local path
	if type(uri) == "userdata" then
		path = uri.file_path
	elseif type(uri) == "string" then
		if uri:match("^file://") then
			path = uri:gsub("^file://[^/]*", "")
		else
			path = uri
		end
	else
		return nil
	end
	if path then
		path = path:gsub("%%(%x%x)", function(hex)
			return string.char(tonumber(hex, 16))
		end)
	end
	return path
end
local function normalize_path(path)
	if not path then
		return nil
	end
	local home = os.getenv("HOME")
	if home then
		path = path:gsub("^" .. home, "~")
	end
	return path
end
local function get_path_with_alias(path)
	for alias_path, icon in pairs(PATH_ALIASES) do
		if path == alias_path then
			return icon, alias_path:match("([^/]+)$")
		elseif path:find("^" .. alias_path .. "/") then
			local rest = path:sub(#alias_path + 2)
			local last = rest:match("([^/]+)$") or rest
			return icon, last
		end
	end
	return nil, nil
end
local function check_git_repo(user_vars, path)
	if not user_vars or user_vars.IS_GIT_REPO ~= "true" then
		return false
	end
	-- Don't show git icon if in special directory
	for alias_path, _ in pairs(PATH_ALIASES) do
		if path:find("^" .. alias_path) then
			return false
		end
	end
	return true
end
local function format_path_for_status(path, icon, display_name)
	-- For status bar, check if we're in root of aliased directory
	for alias_path, alias_icon in pairs(PATH_ALIASES) do
		if path == alias_path and icon == alias_icon then
			return icon -- Just icon for root directory
		end
	end
	return icon .. "/" .. display_name -- Icon/subdirectory for nested paths
end
local function format_path_for_tab(path)
	local last = path:match("([^/]+)$") or path
	local depth = select(2, path:gsub("/", ""))
	return depth > 2 and ("…/" .. last) or last
end
local function process_path_for_display(uri_or_path, user_vars, is_tab_context)
	local path = extract_path_from_uri(uri_or_path)
	if not path then
		return ""
	end
	path = normalize_path(path)
	if not path then
		return ""
	end
	-- Handle home directory
	if path == "~" or path == "~/" then
		return is_tab_context and "" or "~"
	end
	-- Check for special directory aliases
	local icon, display_name = get_path_with_alias(path)
	if icon then
		if is_tab_context then
			return icon .. " " .. display_name
		else
			return format_path_for_status(path, icon, display_name)
		end
	end
	-- Check for git repos
	if check_git_repo(user_vars or {}, path) then
		local repo_name = path:match("([^/]+)/?$") or path
		return icons.directory.git .. " " .. repo_name
	end
	-- Default display logic
	if is_tab_context then
		return format_path_for_tab(path)
	else
		return path:match("([^/]+)$") or path
	end
end
--- Smart directory formatting with icons (for tabs)
local function format_cwd(tab)
	local pane = tab.active_pane
	if not pane then
		return ""
	end
	local user_vars = pane.user_vars or {}
	return process_path_for_display(pane.current_working_dir, user_vars, true)
end
--- Format current working directory for status bar
local function format_status_cwd(pane)
	if not pane then
		return ""
	end
	-- Safely get user vars
	local user_vars = {}
	local ok = pcall(function()
		user_vars = pane:get_user_vars() or {}
	end)
	if not ok then
		return ""
	end
	local path = pane.current_working_dir
	if not path or path == "" then
		-- Fallback to user vars if available
		path = user_vars.WEZTERM_CWD
		if not path then
			return ""
		end
	end
	return process_path_for_display(path, user_vars, false)
end
-- Status Bar Handlers ──────────────────────────────────────────────────────
--- Update left status (mode indicator)
wezterm.on("update-status", function(window, pane)
	local mode_name, mode_color = get_current_mode(window, pane)
	window:set_left_status(wezterm.format({
		{ Background = { Color = window_bg } },
		{ Foreground = { Color = mode_color } },
		{ Text = "  [" .. mode_name .. "]  " },
	}))
end)
--- Update right status (cwd, workspace, hostname)
wezterm.on("update-right-status", function(window, pane)
	-- Safety check for valid pane
	if not pane or not pcall(function()
		return pane:pane_id()
	end) then
		return
	end
	local cells = {}
	-- Current working directory (first)
	local ok, cwd = pcall(function()
		return format_status_cwd(pane)
	end)
	if ok and cwd and cwd ~= "" then
		table.insert(cells, cwd)
	end
	-- Workspace (second)
	local workspace = mux.get_active_workspace()
	table.insert(cells, icons.ui.workspace .. " " .. workspace)
	-- Hostname (last)
	local hostname = wezterm.hostname()
	local dot = hostname:find("[.]")
	if dot then
		hostname = hostname:sub(1, dot - 1)
	end
	table.insert(cells, hostname)
	-- Build status string
	local status_text = table.concat(cells, " | ")
	window:set_right_status(wezterm.format({
		{ Background = { Color = window_bg } },
		{ Foreground = { Color = colors.cyan } },
		{ Text = "  " .. status_text .. "  " },
	}))
end)
-- Tab Formatting ───────────────────────────────────────────────────────────
-- Helper functions for tab formatting
local function build_tab_title_parts(tab)
	local index = tab.tab_index + 1
	local title_parts = { tostring(index) }
	local has_content = false
	if tab.tab_title and #tab.tab_title > 0 then
		table.insert(title_parts, tab.tab_title)
		has_content = true
	else
		local process, process_icon = get_process_info(tab)
		if process and process_icon then
			table.insert(title_parts, process_icon .. " " .. process)
			has_content = true
		else
			local cwd_display = format_cwd(tab)
			if cwd_display and cwd_display ~= "" then
				table.insert(title_parts, cwd_display)
				has_content = true
			end
		end
	end
	return title_parts, has_content
end
local function check_tab_zoomed(tab)
	for _, p in ipairs(tab.panes) do
		if p.is_zoomed then
			return true
		end
	end
	return false
end
local function get_tab_colors(tab, pane, hover)
	if tab.is_active then
		return colors.cyan, colors.bg
	elseif pane.domain_name and host_bg[pane.domain_name] then
		return host_bg[pane.domain_name], colors.fg
	elseif hover then
		return colors.blue, colors.fg
	else
		return window_bg, colors.fg
	end
end
wezterm.on("format-tab-title", function(tab, _, _, _, hover, _)
	if not tab or not tab.active_pane then
		return "[" .. tostring(tab and tab.tab_index + 1 or "?") .. "]"
	end
	local title_parts, has_content = build_tab_title_parts(tab)
	local title = has_content and table.concat(title_parts, " • ") or title_parts[1]
	if check_tab_zoomed(tab) then
		title = title .. " " .. icons.ui.zoom
	end
	local bg, fg = get_tab_colors(tab, tab.active_pane, hover)
	return wezterm.format({
		{ Background = { Color = bg } },
		{ Foreground = { Color = fg } },
		{ Text = " " .. title .. " " },
	})
end)
-- Startup and session management ───────────────────────────────────────────
-- GUI startup handling
wezterm.on("gui-startup", function(cmd)
	local args = {}
	if cmd then
		args = cmd.args
	end
	local _, _, window = mux.spawn_window(args)
	if window then
		window:gui_window():maximize()
	end
end)
-- Workspace switching events
-- The plugin emits these events when workspaces change
-- You can use them for custom actions like saving state
wezterm.on("smart_workspace_switcher.workspace_switcher.chosen", function(_, workspace)
	-- This is called after switching to a workspace
	wezterm.log_info("Switched to workspace: " .. tostring(workspace))
end)
-- Command Palette ──────────────────────────────────────────────────────────
config.command_palette_bg_color = colors.bg
config.command_palette_fg_color = colors.cyan
config.command_palette_rows = 10
config.command_palette_font_size = FONT.size
-- Behaviour ────────────────────────────────────────────────────────────────
config.default_prog = { "/bin/zsh", "-l" }
config.automatically_reload_config = true
config.native_macos_fullscreen_mode = true
config.enable_kitty_keyboard = true
config.switch_to_last_active_tab_when_closing_tab = true
config.hide_mouse_cursor_when_typing = true
config.adjust_window_size_when_changing_font_size = false
-- Hyperlink Rules ─────────────────────────────────────────────────────────
local function setup_hyperlink_rules()
	local rules = wezterm.default_hyperlink_rules()
	local additional_rules = {
		-- File paths (leverages path extraction function)
		-- Matches absolute paths and makes them clickable
		{
			regex = [[(?:^|[\s"])(/[^\s"]+)]],
			format = "file://$1",
			highlight = 1,
		},
		-- Nix package references (useful for your Nix-based project)
		-- Makes nixpkgs#package clickable to search nixos packages
		{
			regex = [[\bnixpkgs#([a-zA-Z0-9\-_]+)\b]],
			format = "https://search.nixos.org/packages?query=$1",
		},
		-- Home-relative paths (~/...)
		{
			regex = [[~(/[^\s]+)]],
			format = "file://" .. os.getenv("HOME") .. "$1",
			highlight = 1,
		},
		-- Docker images (matches docker.io/library/nginx:latest or nginx:1.21)
		{
			regex = [[\b([a-z0-9]+(?:[._-][a-z0-9]+)*]]
				.. [[(?:/[a-z0-9]+(?:[._-][a-z0-9]+)*)*]]
				.. [[:[a-z0-9]+(?:[._-][a-z0-9]+)*)\b]],
			format = "https://hub.docker.com/r/$1",
			highlight = 1,
		},
		-- Kubernetes resources (matches pod/nginx-abc123 or deployment/frontend)
		{
			regex = [[\b(pod|deployment|service|configmap|secret|ingress)/([a-z0-9-]+)\b]],
			format = "k8s://$1/$2", -- Custom protocol, could be handled by an opener
			highlight = 1,
		},
		-- IPv4 addresses (make them clickable for SSH)
		{
			regex = [[\b(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\b]],
			format = "ssh://$1",
			highlight = 1,
		},
		-- Localhost ports (matches localhost:3000 or 127.0.0.1:8080)
		{
			regex = [[\b(?:localhost|127\.0\.0\.1):(\d{1,5})\b]],
			format = "http://localhost:$1",
			highlight = 1,
		},
		-- NixOS options (matches nixos.services.nginx.enable)
		{
			regex = [[\b(nixos\.[a-zA-Z0-9._-]+)\b]],
			format = "https://search.nixos.org/options?query=$1",
			highlight = 1,
		},
	}
	for _, rule in ipairs(additional_rules) do
		table.insert(rules, rule)
	end
	return rules
end
config.hyperlink_rules = setup_hyperlink_rules()
-- Quick Select Configuration ──────────────────────────────────────────────
local function setup_quick_select()
	return {
		patterns = {
			-- Development patterns (leverages existing icon definitions)
			"src/[^ ]+", -- Source paths
			"[0-9a-f]{7,40}", -- Git hashes (matches git icon usage)
			"([A-Z]+-\\d+)", -- JIRA/Issue IDs
			"TODO:? .+", -- TODOs
			"\\b\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\b", -- IP addresses
			"\\S+\\.nix", -- Nix files (relevant to project)
			"~/[^\\s]+", -- Home-relative paths
			"/[^\\s]+", -- Absolute paths
		},
		alphabet = "asdfghjklqwertyuiop", -- Home row priority
	}
end
local quick_select = setup_quick_select()
config.quick_select_patterns = quick_select.patterns
config.quick_select_alphabet = quick_select.alphabet
config.window_close_confirmation = "NeverPrompt"
config.freetype_load_target = "Normal"
config.freetype_render_target = "Normal"
config.audible_bell = "Disabled"
config.visual_bell = {
	fade_in_function = "EaseIn",
	fade_in_duration_ms = 150,
	fade_out_function = "EaseOut",
	fade_out_duration_ms = 150,
	target = "BackgroundColor",
}
-- Set default workspace
config.default_workspace = "default"
config.skip_close_confirmation_for_processes_named = {
	"bash",
	"sh",
	"zsh",
	"fish",
	"tmux",
	"nu",
	"cmd.exe",
	"pwsh.exe",
	"powershell.exe",
}
-- Performance ──────────────────────────────────────────────────────────────
config.front_end = "OpenGL" -- Changed from WebGpu - OpenGL supports transparency properly on macOS
config.max_fps = 120
config.animation_fps = 120
config.scrollback_lines = 5000
-- Key Configuration ────────────────────────────────────────────────────────
config.send_composed_key_when_left_alt_is_pressed = false
config.use_dead_keys = false
-- Leader key using Option+Space - doesn't conflict with terminal shortcuts
-- CTRL+A is commonly used for beginning of line in terminals
config.leader = { key = "Space", mods = "OPT", timeout_milliseconds = 1000 }
-- Mode Key Tables ──────────────────────────────────────────────────────────
config.key_tables = {
	resize_mode = {
		{ key = "h", action = act.AdjustPaneSize({ "Left", 5 }) },
		{ key = "l", action = act.AdjustPaneSize({ "Right", 5 }) },
		{ key = "k", action = act.AdjustPaneSize({ "Up", 5 }) },
		{ key = "j", action = act.AdjustPaneSize({ "Down", 5 }) },
		{ key = "Escape", action = "PopKeyTable" },
	},
	window_mode = {
		{ key = "n", action = act.SpawnWindow },
		{ key = "w", action = act.CloseCurrentPane({ confirm = false }) },
		{ key = "Escape", action = "PopKeyTable" },
	},
	copy_mode = {
		-- Vim-like navigation
		{ key = "h", action = act.CopyMode("MoveLeft") },
		{ key = "j", action = act.CopyMode("MoveDown") },
		{ key = "k", action = act.CopyMode("MoveUp") },
		{ key = "l", action = act.CopyMode("MoveRight") },
		-- Word navigation
		{ key = "w", action = act.CopyMode("MoveForwardWord") },
		{ key = "b", action = act.CopyMode("MoveBackwardWord") },
		{ key = "e", action = act.CopyMode("MoveForwardWordEnd") },
		-- Line navigation
		{ key = "0", action = act.CopyMode("MoveToStartOfLine") },
		{ key = "$", action = act.CopyMode("MoveToEndOfLineContent") },
		{ key = "^", action = act.CopyMode("MoveToStartOfLineContent") },
		-- Page navigation
		{ key = "g", action = act.CopyMode("MoveToScrollbackTop") },
		{ key = "G", action = act.CopyMode("MoveToScrollbackBottom") },
		{ key = "H", action = act.CopyMode("MoveToViewportTop") },
		{ key = "L", action = act.CopyMode("MoveToViewportBottom") },
		{ key = "M", action = act.CopyMode("MoveToViewportMiddle") },
		-- Selection modes
		{ key = "v", action = act.CopyMode({ SetSelectionMode = "Cell" }) },
		{ key = "V", action = act.CopyMode({ SetSelectionMode = "Line" }) },
		{ key = "v", mods = "CTRL", action = act.CopyMode({ SetSelectionMode = "Block" }) },
		-- Copy and exit
		{
			key = "y",
			action = act.Multiple({
				{ CopyTo = "ClipboardAndPrimarySelection" },
				{ CopyMode = "Close" },
			}),
		},
		-- Just exit
		{ key = "q", action = act.CopyMode("Close") },
		{ key = "Escape", action = act.CopyMode("Close") },
		-- Search within copy mode
		{ key = "/", action = act.Search({ CaseInSensitiveString = "" }) },
		{ key = "n", action = act.CopyMode("NextMatch") },
		{ key = "N", action = act.CopyMode("PriorMatch") },
	},
}
-- Key Bindings ─────────────────────────────────────────────────────────────
-- Design Philosophy:
-- - Leader key: Option+Space (avoids CTRL+A which is beginning-of-line)
-- - Tab navigation: CMD+number (standard macOS pattern)
-- - Pane navigation: Ctrl+arrows OR Cmd+Option+HJKL (avoids vim conflicts)
-- - Pane resizing: Ctrl+Shift+arrows OR Cmd+Shift+HJKL
-- - Avoid CTRL+[HJKL] as they conflict with vim and terminal apps
-- - Preserve Option+arrows for word jumping in terminal
config.keys = {
	-- macOS standard shortcuts
	{ key = "t", mods = "CMD", action = act.SpawnTab("CurrentPaneDomain") },
	{ key = "w", mods = "CMD", action = act.CloseCurrentTab({ confirm = false }) },
	-- Clipboard copy/paste
	{ key = "c", mods = "CMD", action = act.CopyTo("Clipboard") },
	{ key = "v", mods = "CMD", action = act.PasteFrom("Clipboard") },
	-- Command palette and search
	{ key = "k", mods = "CMD", action = act.ActivateCommandPalette },
	{ key = "f", mods = "CMD|SHIFT", action = act.Search({ CaseInSensitiveString = "" }) },
	{ key = "k", mods = "CMD|SHIFT", action = act.ClearScrollback("ScrollbackOnly") },
	-- Pane splitting (Cmd+D horizontal, Cmd+Shift+D vertical) like iTerm2
	{ key = "d", mods = "CMD", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
	{ key = "d", mods = "CMD|SHIFT", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
	-- NOTE: Removed CTRL+arrows and CTRL+SHIFT+arrows to preserve terminal functionality
	-- Use CMD+OPT+hjkl for pane navigation and CMD+SHIFT+hjkl for resizing instead
	-- Pane management
	{ key = "w", mods = "CMD|OPT", action = act.CloseCurrentPane({ confirm = false }) },
	{ key = "z", mods = "CMD|OPT", action = act.TogglePaneZoomState },
	-- Alternative vim-style navigation (using Cmd+Option to avoid conflicts)
	-- CTRL+H/J/K/L conflicts with terminal apps, especially vim
	{ key = "h", mods = "CMD|OPT", action = act.ActivatePaneDirection("Left") },
	{ key = "j", mods = "CMD|OPT", action = act.ActivatePaneDirection("Down") },
	{ key = "k", mods = "CMD|OPT", action = act.ActivatePaneDirection("Up") },
	{ key = "l", mods = "CMD|OPT", action = act.ActivatePaneDirection("Right") },
	-- Vim-style pane resizing (Cmd+Shift for safety)
	{ key = "h", mods = "CMD|SHIFT", action = act.AdjustPaneSize({ "Left", 3 }) },
	{ key = "j", mods = "CMD|SHIFT", action = act.AdjustPaneSize({ "Down", 3 }) },
	{ key = "k", mods = "CMD|SHIFT", action = act.AdjustPaneSize({ "Up", 3 }) },
	{ key = "l", mods = "CMD|SHIFT", action = act.AdjustPaneSize({ "Right", 3 }) },
	-- Tab navigation (Cycling)
	{ key = "[", mods = "CMD|SHIFT", action = act.ActivateTabRelative(-1) },
	{ key = "]", mods = "CMD|SHIFT", action = act.ActivateTabRelative(1) },
	-- Tab navigation (CMD + number - standard macOS pattern)
	{ key = "1", mods = "CMD", action = act.ActivateTab(0) },
	{ key = "2", mods = "CMD", action = act.ActivateTab(1) },
	{ key = "3", mods = "CMD", action = act.ActivateTab(2) },
	{ key = "4", mods = "CMD", action = act.ActivateTab(3) },
	{ key = "5", mods = "CMD", action = act.ActivateTab(4) },
	{ key = "6", mods = "CMD", action = act.ActivateTab(5) },
	{ key = "7", mods = "CMD", action = act.ActivateTab(6) },
	{ key = "8", mods = "CMD", action = act.ActivateTab(7) },
	{ key = "9", mods = "CMD", action = act.ActivateTab(-1) },
	-- Leader key bindings ────────────────────────────────────────────────────
	-- Mode management
	{
		key = "r",
		mods = "LEADER",
		action = act.ActivateKeyTable({ name = "resize_mode", one_shot = false }),
	},
	{
		key = "w",
		mods = "LEADER",
		action = act.ActivateKeyTable({ name = "window_mode", one_shot = false }),
	},
	{ key = "[", mods = "LEADER", action = act.ActivateCopyMode },
	-- Quick Select mode for pattern-based selection
	{ key = "u", mods = "LEADER", action = act.QuickSelect },
	{
		key = "U",
		mods = "LEADER",
		action = act.QuickSelectArgs({
			patterns = { "https?://\\S+" }, -- URLs only
		}),
	},
	-- Workspace management
	{ key = "p", mods = "LEADER", action = workspace_switcher.switch_workspace() },
	{ key = "l", mods = "LEADER", action = workspace_switcher.switch_to_prev_workspace() },
	{
		key = "L",
		mods = "LEADER",
		action = wezterm.action.ShowLauncherArgs({ flags = "FUZZY|WORKSPACES|DOMAINS" }),
	},
	{
		key = "W",
		mods = "LEADER",
		action = act.PromptInputLine({
			description = "Enter name for new workspace",
			action = wezterm.action_callback(function(window, pane, line)
				if line then
					window:perform_action(act.SwitchToWorkspace({ name = line }), pane)
				end
			end),
		}),
	},
	-- Rename current workspace
	{
		key = "R",
		mods = "LEADER",
		action = act.PromptInputLine({
			description = "Enter new workspace name",
			action = wezterm.action_callback(function(_, _, line)
				if line then
					wezterm.mux.rename_workspace(wezterm.mux.get_active_workspace(), line)
				end
			end),
		}),
	},
	-- Quick workspace save/restore could be implemented here if needed
}
-- Mouse Configuration ──────────────────────────────────────────────────────
config.bypass_mouse_reporting_modifiers = "SHIFT"
config.mouse_bindings = {
	{
		event = { Up = { streak = 1, button = "Left" } },
		mods = "CMD",
		action = act.OpenLinkAtMouseCursor,
	},
	{
		event = { Down = { streak = 1, button = { WheelUp = 1 } } },
		mods = "CMD",
		action = act.IncreaseFontSize,
	},
	{
		event = { Down = { streak = 1, button = { WheelDown = 1 } } },
		mods = "CMD",
		action = act.DecreaseFontSize,
	},
	{
		event = { Down = { streak = 1, button = { WheelUp = 1 } } },
		mods = "NONE",
		action = act.ScrollByLine(-3),
	},
	{
		event = { Down = { streak = 1, button = "Middle" } },
		mods = "NONE",
		action = act.PasteFrom("PrimarySelection"),
	},
	{
		event = { Up = { streak = 1, button = "Right" } },
		mods = "NONE",
		action = act.CopyTo("ClipboardAndPrimarySelection"),
	},
	{
		event = { Down = { streak = 3, button = "Left" } },
		mods = "NONE",
		action = act.SelectTextAtMouseCursor("Line"),
	},
	{
		event = { Down = { streak = 2, button = "Left" } },
		mods = "NONE",
		action = act.SelectTextAtMouseCursor("Word"),
	},
}
return config
