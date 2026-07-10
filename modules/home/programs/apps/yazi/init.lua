-- Title         : init.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : modules/home/programs/apps/yazi/init.lua
-- ----------------------------------------------------------------------------
-- Plugin setup rows: every option below diverges from its plugin's default;
-- restated defaults are deleted, and unknown keys warn at startup.

-- Core Plugins ---------------------------------------------------------------
require("zoxide"):setup({
    update_db = true,
})

-- Cross-instance yank state rides DDS, not an external clipboard hack
require("session"):setup({
    sync_yanked = true,
})

require("full-border"):setup()

require("git"):setup()

-- External Plugins -----------------------------------------------------------

-- Extension-database MIME: close the gz/zst/ndjson gaps, then classify the
-- unknown-extension residue through file(1) so text files off the database
-- still reach the code previewer.
require("mime-ext.local"):setup({
    with_exts = {
        gz = "application/gzip",
        tgz = "application/gzip",
        zst = "application/zstd",
        ndjson = "application/ndjson",
    },
    fallback_file1 = true,
})

-- DuckDB data-preview lane: csv/tsv/parquet/xlsx/duckdb previewer rows
require("duckdb"):setup()

require("augment-command"):setup({
    prompt = true, -- Choose between hovered/selected items when both exist
    smart_tab_create = true, -- Create tabs in hovered directory
    smart_tab_switch = true, -- Create intermediate tabs when switching ahead
    smooth_scrolling = true, -- Animate file-list scrolling
})
