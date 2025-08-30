-- Title         : context.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : /01.home/00.core/configs/apps/sketchybar/modules/core/context.lua
-- ----------------------------------------------------------------------------
-- Context intelligence system - understands workspace and project context

local M = {
	project_types = {},
	current_project = nil,
	context_cache = {},
	intelligent_behaviors = {},
}

-- Project type detection patterns
M.project_types = {
	nix = { patterns = { "flake.nix", "default.nix", "*.nix" }, color = 0xff8be9fd },
	rust = { patterns = { "Cargo.toml", "src/", "*.rs" }, color = 0xffffb86c },
	python = { patterns = { "pyproject.toml", "requirements.txt", "*.py" }, color = 0xfff1fa8c },
	node = { patterns = { "package.json", "node_modules/", "*.js", "*.ts" }, color = 0xff50fa7b },
	git = { patterns = { ".git/", ".gitignore" }, color = 0xffff5555 },
	docs = { patterns = { "*.md", "README*", "docs/" }, color = 0xffbd93f9 },
}

-- Detect project type in current directory
function M.detect_project_type(directory)
	local cached = performance.cache_get("project_type:" .. directory)
	if cached then
		return cached
	end

	local detected_types = {}

	for proj_type, config in pairs(M.project_types) do
		sbar.exec("cd '" .. directory .. "' && ls -la", function(ls_output)
			if ls_output then
				for _, pattern in ipairs(config.patterns) do
					if ls_output:match(pattern:gsub("%*", ".*"):gsub("%.", "%%.")) then
						table.insert(detected_types, {
							type = proj_type,
							color = config.color,
							confidence = pattern:match("%*") and 0.7 or 0.9,
						})
					end
				end
			end
		end)
	end

	-- Cache result and return primary type
	performance.cache_set("project_type:" .. directory, detected_types, 10)
	return detected_types[1] or { type = "general", color = 0xff6272a4, confidence = 0.5 }
end

-- Context-aware workspace behavior coordination
function M.apply_context_behaviors(context)
	-- Git repository context
	if context.type == "nix" or context.type == "git" then
		-- Enable enhanced git status monitoring
		M.register_git_monitoring(context.directory)
	end

	-- Development context
	if context.type == "rust" or context.type == "python" or context.type == "node" then
		-- Enable build status monitoring
		M.register_build_monitoring(context.directory)
	end

	-- Trigger context-specific SketchyBar updates
	events.trigger("ecosystem_context_switched", {
		workspace = context.workspace,
		project_type = context.type,
		directory = context.directory,
	})
end

-- Git monitoring with cross-tool coordination
function M.register_git_monitoring(directory)
	-- Debounced git status updates that coordinate across ecosystem
	local git_update = performance.debounce(function()
		sbar.exec("cd '" .. directory .. "' && git status --porcelain -b 2>/dev/null", function(status)
			if status then
				local git_data = {
					directory = directory,
					branch = status:match("## ([^%s%.%.]*)") or "main",
					has_changes = #status:gsub("##[^\n]*\n?", "") > 0,
					ahead = status:match("%[ahead (%d+)") and tonumber(status:match("%[ahead (%d+)")) or 0,
					behind = status:match("%[behind (%d+)") and tonumber(status:match("%[behind (%d+)")) or 0,
				}

				events.trigger("ecosystem_git_updated", git_data)
			end
		end)
	end, 2.0, "git_monitor:" .. directory)

	-- Register for filesystem changes
	events.register("ecosystem_file_operation", git_update, 85)
end

-- Build monitoring for development contexts
function M.register_build_monitoring(directory)
	-- Check for build status and coordinate with development workflow
	local build_check = performance.debounce(function()
		sbar.exec(
			"cd '"
				.. directory
				.. "' && (test -f Cargo.toml && cargo check --quiet) || (test -f pyproject.toml && ruff check .) || true",
			function(build_output)
				local build_status = {
					directory = directory,
					has_errors = build_output and build_output:match("error") ~= nil,
					last_check = os.time(),
				}

				events.trigger("ecosystem_build_status", build_status)
			end
		)
	end, 5.0, "build_monitor:" .. directory)

	events.register("ecosystem_file_operation", build_check, 80)
end

-- Intelligent hotkey behavior coordination with skhdrc
function M.register_intelligent_hotkeys()
	-- Context-aware bookmark jumps that coordinate with yazi bookmarks
	interactions.register_hotkey_action("workspace_bookmark", function(data)
		local context = M.current_context
		if context and context.type == "nix" then
			-- Nix projects get special bookmark behaviors
			events.trigger("ecosystem_nix_bookmark", context)
		end
	end)
end

-- Initialize context intelligence
function M.init()
	M.register_intelligent_hotkeys()

	-- Listen for ecosystem workspace changes
	events.register("ecosystem_workspace_changed", function(data)
		M.current_context = data.context
		M.apply_context_behaviors(data.context)
	end, 100)
end

return M
