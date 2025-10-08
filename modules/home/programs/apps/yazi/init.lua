-- Title         : init.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : modules/home/programs/apps/yazi/init.lua
-- ----------------------------------------------------------------------------
-- Initialize Yazi plugins

-- Custom Plugins -------------------------------------------------------------
require("sidebar-status"):setup()
require("auto-layout").setup()

-- External Plugins -----------------------------------------------------------
require("full-border"):setup {
	type = ui.Border.ROUNDED,                   -- Available values: ui.Border.PLAIN, ui.Border.ROUNDED
}

require("easyjump"):setup({
    icon_fg = "#F1FA8C",
    first_key_fg = "#50FA7B",
})

require("augment-command"):setup({
    prompt = true,                              -- Create prompt to choose between hovered/selected items when both exist
    default_item_group_for_prompt = "hovered",  -- Default item group when prompt submitted without value (hovered/selected/none)
    smart_enter = true,                         -- Use one command to open files or enter directories
    smart_paste = false,                        -- Paste items into directory without entering it
    smart_tab_create = true,                    -- Create tabs in hovered directory instead of current directory
    smart_tab_switch = true,                    -- Create intermediate tabs when switching to non-existent tab
    confirm_on_quit = true,                     -- Prompt for confirmation before quitting with multiple tabs open
    open_file_after_creation = false,           -- Open file immediately after creating it
    enter_directory_after_creation = false,     -- Enter directory immediately after creating it
    use_default_create_behaviour = false,       -- Use Yazi's default create command behavior
    enter_archives = true,                      -- Automatically extract and enter archive files
    extract_retries = 3,                        -- Number of password retry attempts for encrypted archives
    recursively_extract_archives = true,        -- Extract archives inside archives recursively
    preserve_file_permissions = false,          -- Preserve file permissions when extracting (security risk - requires tar)
    encrypt_archives = false,                   -- Encrypt archives when creating them
    encrypt_archive_headers = false,            -- Encrypt archive headers (7z only)
    reveal_created_archive = true,              -- Automatically hover over created archive
    remove_archived_files = false,              -- Remove original files after adding to archive
    must_have_hovered_item = true,              -- Stop execution when no hovered item exists
    skip_single_subdirectory_on_enter = true,   -- Skip directories with only one subdirectory when entering
    skip_single_subdirectory_on_leave = true,   -- Skip directories with only one subdirectory when leaving
    smooth_scrolling = true,                    -- Enable smooth scrolling through file list
    scroll_delay = 0.02,                        -- Delay between scroll commands (smaller = faster scrolling)
    create_item_delay = 0.25,                   -- Delay before revealing created items (filesystem dependent)
    wraparound_file_navigation = true,          -- Wrap from bottom to top or top to bottom when navigating
})
