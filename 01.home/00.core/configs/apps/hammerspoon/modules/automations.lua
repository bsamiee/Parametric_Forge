-- Title         : automations.lua
-- Author        : Bardia Samiee
-- Project       : Parametric Forge
-- License       : MIT
-- Path          : /01.home/00.core/configs/apps/hammerspoon/modules/automations.lua
-- ----------------------------------------------------------------------------
-- File automation system: unzip, webp→png, PDF optimization
-- Simplified architecture using native hs.pathwatcher and hs.settings

local canvas = require("notifications.canvas")
local files = require("utils.files")
local process = require("utils.process")

local M = {}
local log = hs.logger.new("automations", hs.logger.info)

-- Configuration
local DOWNLOADS_DIR = os.getenv("HOME") .. "/Downloads"

-- Settings keys for persistent state
local SETTINGS = {
    unzip = "automations.unzip.enabled",
    webp2png = "automations.webp2png.enabled",
    pdf = "automations.pdf.enabled"
}

-- Watchers storage
local watchers = {}

-- Initialize default settings
local function initSettings()
    for _, key in pairs(SETTINGS) do
        if hs.settings.get(key) == nil then
            hs.settings.set(key, true)
        end
    end
end

-- Automation actions
local actions = {}

function actions.unzip(zipPath)
    local dir = files.dirname(zipPath)
    local basename = files.basename(zipPath)
    local cmd = string.format(
        "/usr/bin/ditto -x -k %q %q && /bin/rm -f %q",
        zipPath, dir, zipPath
    )

    local success = process.execute(cmd, true)
    if success then
        canvas.show("UNZIPPED: " .. basename)
        log.i("Unzipped: " .. zipPath)
    else
        canvas.show("UNZIP FAILED: " .. basename)
        log.w("Failed to unzip: " .. zipPath)
    end
end

function actions.webp2png(webpPath)
    local pngPath = webpPath:gsub("[Ww][Ee][Bb][Pp]$", "png")
    local basename = files.basename(pngPath)
    local cmd = string.format("magick %q %q && rm -f %q", webpPath, pngPath, webpPath)

    local success = process.execute(cmd, true)
    if success then
        canvas.show("CONVERTED: " .. basename)
        log.i("Converted WebP: " .. webpPath)
    else
        canvas.show("CONVERT FAILED: " .. basename)
        log.w("Failed to convert WebP: " .. webpPath)
    end
end

function actions.optimizePdf(pdfPath)
    local basename = files.basename(pdfPath)

    -- Check if PDF has substantial text (skip vector PDFs)
    local textCheck = process.execute(
        string.format("pdftotext %q - 2>/dev/null | wc -c", pdfPath),
        true
    )
    local textLength = tonumber(textCheck and textCheck:match("%d+")) or 0

    if textLength > 50 then
        log.i("Skipping vector PDF: " .. pdfPath)
        return
    end

    -- OCR and optimize
    local cmd = string.format("ocrmypdf --optimize 3 --skip-text %q %q", pdfPath, pdfPath)
    local success = process.execute(cmd, true)

    if success then
        canvas.show("PDF OPTIMIZED: " .. basename)
        log.i("Optimized PDF: " .. pdfPath)
    else
        canvas.show("PDF OPTIMIZATION FAILED: " .. basename)
        log.w("Failed to optimize PDF: " .. pdfPath)
    end
end

-- File watcher callback
local function onFileChange(changedFiles, flagTables)
    for i, filePath in ipairs(changedFiles) do
        if files.exists(filePath) and
           not files.shouldIgnoreFile(filePath) and
           files.isRecentlyCreated(filePath, 300) then

            -- Wait for file to stabilize
            hs.timer.doAfter(0.5, function()
                if not files.exists(filePath) then return end

                local ext = files.extension(filePath)

                if ext == "zip" and hs.settings.get(SETTINGS.unzip) then
                    actions.unzip(filePath)
                elseif ext == "webp" and hs.settings.get(SETTINGS.webp2png) then
                    actions.webp2png(filePath)
                elseif ext == "pdf" and hs.settings.get(SETTINGS.pdf) then
                    actions.optimizePdf(filePath)
                end
            end)
        end
    end
end

-- Watcher management
local function startWatcher()
    if watchers.downloads then return end

    watchers.downloads = hs.pathwatcher.new(DOWNLOADS_DIR, onFileChange)
    watchers.downloads:start()
    log.i("File automation watcher started")
end

local function stopWatcher()
    if watchers.downloads then
        watchers.downloads:stop()
        watchers.downloads = nil
        log.i("File automation watcher stopped")
    end
end

-- Public API
function M.enable(automationType)
    local setting = SETTINGS[automationType]
    if not setting then return false end

    hs.settings.set(setting, true)
    canvas.show("AUTOMATION ON: " .. string.upper(automationType))

    -- Ensure watcher is running if any automation is enabled
    local anyEnabled = false
    for _, key in pairs(SETTINGS) do
        if hs.settings.get(key) then
            anyEnabled = true
            break
        end
    end

    if anyEnabled then
        startWatcher()
    end

    return true
end

function M.disable(automationType)
    local setting = SETTINGS[automationType]
    if not setting then return false end

    hs.settings.set(setting, false)
    canvas.show("AUTOMATION OFF: " .. string.upper(automationType))

    -- Stop watcher if no automations are enabled
    local anyEnabled = false
    for _, key in pairs(SETTINGS) do
        if hs.settings.get(key) then
            anyEnabled = true
            break
        end
    end

    if not anyEnabled then
        stopWatcher()
    end

    return true
end

function M.toggle(automationType)
    local setting = SETTINGS[automationType]
    if not setting then return false end

    if hs.settings.get(setting) then
        return M.disable(automationType)
    else
        return M.enable(automationType)
    end
end

function M.isEnabled(automationType)
    local setting = SETTINGS[automationType]
    return setting and hs.settings.get(setting) == true
end

function M.getStatus()
    return {
        unzip = M.isEnabled("unzip"),
        webp2png = M.isEnabled("webp2png"),
        pdf = M.isEnabled("pdf")
    }
end

function M.init()
    initSettings()

    -- Start watcher if any automation is enabled
    for _, key in pairs(SETTINGS) do
        if hs.settings.get(key) then
            startWatcher()
            break
        end
    end

    log.i("File automations initialized")
    return true
end

function M.stop()
    stopWatcher()
    log.i("File automations stopped")
end

return M
