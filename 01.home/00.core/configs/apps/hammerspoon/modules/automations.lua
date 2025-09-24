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
local log = hs.logger.new("automations", "info")

-- Configuration
local DOWNLOADS_DIR = os.getenv("HOME") .. "/Downloads"

-- Settings keys for persistent state
local SETTINGS = {
    unzip = "automations.unzip.enabled",
    webp2png = "automations.webp2png.enabled",
    pdf = "automations.pdf.enabled",
}

-- Watchers storage
local watchers = {}

-- Track processed files to prevent duplicates (file path -> timestamp)
local processedFiles = {}
local PROCESSED_CACHE_TIME = 3600 -- 1 hour cache

-- Initialize default settings
local function initSettings()
    for _, key in pairs(SETTINGS) do
        if hs.settings.get(key) == nil then
            hs.settings.set(key, true)
        end
    end
end

-- Clean old entries from processed files cache
local function cleanProcessedCache()
    local now = hs.timer.secondsSinceEpoch()
    for path, timestamp in pairs(processedFiles) do
        if now - timestamp > PROCESSED_CACHE_TIME then
            processedFiles[path] = nil
        end
    end
end

-- Check if file was already processed recently
local function wasAlreadyProcessed(filePath)
    cleanProcessedCache()
    return processedFiles[filePath] ~= nil
end

-- Mark file as processed
local function markAsProcessed(filePath)
    processedFiles[filePath] = hs.timer.secondsSinceEpoch()
end

-- Automation actions
local actions = {}

function actions.unzip(zipPath)
    local basename = files.basename(zipPath)

    -- Use ouch - it automatically creates a folder for multi-file archives
    local cmd = string.format(
        'cd "%s" && ouch decompress -y -r "%s" 2>&1',
        files.dirname(zipPath):gsub('"', '\\"'),
        basename:gsub('"', '\\"')
    )

    local output, success = process.execute(cmd, true)

    if success then
        canvas.show("UNZIPPED: " .. basename:gsub("%.zip$", ""))
        log.i("Successfully unzipped: " .. zipPath)
    else
        canvas.show("UNZIP FAILED: " .. basename)
        log.e("Failed to unzip: " .. zipPath .. " - Output: " .. (output or "no output"))
    end
end

function actions.webp2png(webpPath)
    -- More robust extension replacement (case-insensitive)
    local pngPath = webpPath:gsub("%.webp$", ".png", 1)
    if pngPath == webpPath then
        pngPath = webpPath:gsub("%.WEBP$", ".png", 1)
    end
    local basename = files.basename(pngPath)

    local cmd = string.format('magick "%s" "%s" 2>&1', webpPath:gsub('"', '\\"'), pngPath:gsub('"', '\\"'))

    local output, success = process.execute(cmd, true)

    if success then
        -- Remove original WebP after successful conversion
        local rmCmd = string.format('/bin/rm -f "%s"', webpPath:gsub('"', '\\"'))
        process.execute(rmCmd, true)
        canvas.show("CONVERTED: " .. basename)
        log.i("Successfully converted: " .. webpPath .. " -> " .. pngPath)
    else
        canvas.show("CONVERT FAILED: " .. basename)
        log.e("Failed to convert: " .. webpPath .. " - Output: " .. (output or "no output"))
    end
end

function actions.optimizePdf(pdfPath)
    local basename = files.basename(pdfPath)

    -- Check if PDF needs OCR (scanned PDFs have little/no text)
    local textCheckCmd = string.format('pdftotext "%s" - 2>/dev/null | wc -c', pdfPath:gsub('"', '\\"'))
    local textCheck = process.execute(textCheckCmd, true)
    local textLength = tonumber(textCheck and textCheck:match("%d+")) or 0

    -- Determine processing strategy based on text content
    local needsOCR = textLength < 100 -- Scanned PDFs have minimal text
    local outputPath = pdfPath:gsub("%.pdf$", "_optimized.pdf")

    local cmd
    if needsOCR then
        -- Scanned PDF: perform OCR + optimization
        log.i("Detected scanned PDF (text: " .. textLength .. " chars): " .. basename)
        cmd = string.format(
            'ocrmypdf --optimize 3 --rotate-pages --deskew "%s" "%s" 2>&1',
            pdfPath:gsub('"', '\\"'),
            outputPath:gsub('"', '\\"')
        )
    else
        -- Digital PDF: just optimize images (no OCR needed)
        log.i("Detected digital PDF (text: " .. textLength .. " chars): " .. basename)
        cmd = string.format(
            'ocrmypdf --optimize 3 --skip-text --jpeg-quality 85 "%s" "%s" 2>&1',
            pdfPath:gsub('"', '\\"'),
            outputPath:gsub('"', '\\"')
        )
    end

    local output, success = process.execute(cmd, true)

    if success then
        -- Check if optimization actually reduced size
        local originalSize = files.size(pdfPath)
        local optimizedSize = files.size(outputPath)

        if optimizedSize > 0 and optimizedSize < originalSize * 0.95 then
            -- Significant size reduction, replace original
            local mvCmd = string.format('/bin/mv -f "%s" "%s"', outputPath:gsub('"', '\\"'), pdfPath:gsub('"', '\\"'))
            process.execute(mvCmd, true)

            local reduction = math.floor((1 - optimizedSize/originalSize) * 100)
            canvas.show(string.format("PDF OPTIMIZED: %s (-%d%%)", basename, reduction))
            log.i(string.format("Optimized %s: %d%% size reduction", basename, reduction))
        else
            -- No significant improvement, remove temp file
            local rmCmd = string.format('/bin/rm -f "%s"', outputPath:gsub('"', '\\"'))
            process.execute(rmCmd, true)

            canvas.show("PDF ALREADY OPTIMAL: " .. basename)
            log.i("PDF already optimized, no changes made: " .. basename)
        end
    else
        -- Clean up failed output
        local rmCmd = string.format('/bin/rm -f "%s"', outputPath:gsub('"', '\\"'))
        process.execute(rmCmd, true)

        -- Don't show error for expected cases
        if output and output:match("already has an OCR text layer") then
            canvas.show("PDF HAS TEXT: " .. basename)
            log.i("PDF already has OCR layer: " .. basename)
        else
            canvas.show("PDF OPTIMIZATION FAILED: " .. basename)
            log.e("Failed to optimize PDF: " .. pdfPath .. " - Output: " .. (output or "no output"))
        end
    end
end

-- Check if file was just completed (renamed from temp to final)
local function wasJustCompleted(filePath, flagTable)
    -- flagTable is a table where keys are flag names and values are booleans
    -- Check for events that indicate a new/completed file
    if not flagTable then
        return false
    end

    -- Only trigger on creation or rename (not modification to avoid loops)
    -- Also check if file was created recently to avoid processing old files
    return (flagTable.itemCreated or flagTable.itemRenamed) and files.isRecentlyCreated(filePath, 60)
end

-- File watcher callback
local function onFileChange(changedFiles, flagTables)
    for i, filePath in ipairs(changedFiles) do
        local flagTable = flagTables[i]

        if
            files.exists(filePath)
            and not files.shouldIgnoreFile(filePath)
            and not wasAlreadyProcessed(filePath)
            and wasJustCompleted(filePath, flagTable)
        then
            local ext = files.extension(filePath)

            -- Add a small delay to ensure file is fully written
            if ext == "zip" and hs.settings.get(SETTINGS.unzip) then
                log.i("Detected ZIP file: " .. filePath)
                markAsProcessed(filePath)
                hs.timer.doAfter(0.5, function()
                    if files.exists(filePath) then
                        log.i("Processing ZIP file: " .. filePath)
                        actions.unzip(filePath)
                    end
                end)
            elseif ext == "webp" and hs.settings.get(SETTINGS.webp2png) then
                log.i("Detected WebP file: " .. filePath)
                markAsProcessed(filePath)
                hs.timer.doAfter(0.5, function()
                    if files.exists(filePath) then
                        log.i("Processing WebP file: " .. filePath)
                        actions.webp2png(filePath)
                    end
                end)
            elseif ext == "pdf" and hs.settings.get(SETTINGS.pdf) then
                log.i("Detected PDF file: " .. filePath)
                markAsProcessed(filePath)
                hs.timer.doAfter(1.0, function() -- Longer delay for PDFs
                    if files.exists(filePath) then
                        log.i("Processing PDF file: " .. filePath)
                        actions.optimizePdf(filePath)
                    end
                end)
            end
        end
    end
end

-- Watcher management
local function startWatcher()
    if watchers.downloads then
        return
    end

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
    if not setting then
        return false
    end

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
    if not setting then
        return false
    end

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
    if not setting then
        return false
    end

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
        pdf = M.isEnabled("pdf"),
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
