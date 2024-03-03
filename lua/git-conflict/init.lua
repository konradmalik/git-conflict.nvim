local color = require("git-conflict.colors")
local conflicts = require("git-conflict.conflicts")

--- @class ConflictHighlights
--- @field current string
--- @field incoming string
--- @field ancestor string?

--- @class ConflictPosition
--- @field incoming Range
--- @field middle Range
--- @field current Range

--- @class Range
--- @field range_start integer
--- @field range_end integer
--- @field content_start integer
--- @field content_end integer

local CURRENT_HL = "GitConflictCurrent"
local INCOMING_HL = "GitConflictIncoming"
local ANCESTOR_HL = "GitConflictAncestor"
local CURRENT_LABEL_HL = "GitConflictCurrentLabel"
local INCOMING_LABEL_HL = "GitConflictIncomingLabel"
local ANCESTOR_LABEL_HL = "GitConflictAncestorLabel"
local PRIORITY = vim.highlight.priorities.diagnostics - 1
local NAME = "git-conflict"
local NAMESPACE = vim.api.nvim_create_namespace(NAME)

local conflict_start = conflicts.conflict_start
local conflict_middle = conflicts.conflict_middle
local conflict_end = conflicts.conflict_end
local conflict_ancestor = conflicts.conflict_ancestor

local DEFAULT_CURRENT_BG_COLOR = 4218238 -- #405d7e
local DEFAULT_INCOMING_BG_COLOR = 3229523 -- #314753
local DEFAULT_ANCESTOR_BG_COLOR = 6824314 -- #68217A

local config = {
    highlights = {
        current = "DiffText",
        incoming = "DiffAdd",
        ancestor = "DiffChange",
    },
    labels = {
        current = "(Current Change)",
        incoming = "(Incoming Change)",
        ancestor = "(Base Change)",
    },
    enable_diagnostics = true,
}

---Set an extmark for each section of the git conflict
---@param bufnr integer
---@param hl string
---@param range_start integer
---@param range_end integer
---@return integer? extmark_id
local function hl_range(bufnr, hl, range_start, range_end)
    if not range_start or not range_end then return end
    return vim.api.nvim_buf_set_extmark(bufnr, NAMESPACE, range_start, 0, {
        hl_group = hl,
        hl_eol = true,
        hl_mode = "combine",
        end_row = range_end,
        priority = PRIORITY,
    })
end

---Add highlights and additional data to each section heading of the conflict marker
---@param bufnr integer
---@param hl_group string
---@param label string
---@param lnum integer
---@return integer extmark id
local function draw_section_label(bufnr, hl_group, label, lnum)
    return vim.api.nvim_buf_set_extmark(bufnr, NAMESPACE, lnum, 0, {
        hl_group = hl_group,
        virt_text = { { label, hl_group } },
        virt_text_pos = "eol",
        priority = PRIORITY,
    })
end

---Highlight each part of a git conflict i.e. the incoming changes vs the current/HEAD changes
---@param bufnr integer
---@param positions table
local function highlight_conflicts(bufnr, positions)
    for _, position in ipairs(positions) do
        local current_start = position.current.range_start
        local current_end = position.current.range_end
        local incoming_start = position.incoming.range_start
        local incoming_end = position.incoming.range_end

        draw_section_label(bufnr, CURRENT_LABEL_HL, config.labels.current, current_start)
        hl_range(bufnr, CURRENT_LABEL_HL, current_start, current_start + 1)
        hl_range(bufnr, CURRENT_HL, current_start + 1, current_end + 1)
        draw_section_label(bufnr, INCOMING_LABEL_HL, config.labels.incoming, incoming_end)
        hl_range(bufnr, INCOMING_HL, incoming_start, incoming_end)
        hl_range(bufnr, INCOMING_LABEL_HL, incoming_end, incoming_end + 1)

        if not vim.tbl_isempty(position.ancestor) then
            local ancestor_start = position.ancestor.range_start
            local ancestor_end = position.ancestor.range_end
            draw_section_label(bufnr, ANCESTOR_LABEL_HL, config.labels.ancestor, ancestor_start)
            hl_range(bufnr, ANCESTOR_LABEL_HL, ancestor_start, ancestor_start + 1)
            hl_range(bufnr, ANCESTOR_HL, ancestor_start + 1, ancestor_end + 1)
        end
    end
end

---Iterate through the buffer line by line checking there is a matching conflict marker
---when we find a starting mark we collect the position details and add it to a list of positions
---@param lines string[]
---@return boolean
---@return ConflictPosition[]
local function detect_conflicts(lines)
    local positions = {}
    local position, has_start, has_middle, has_ancestor = {}, false, false, false
    for index, line in ipairs(lines) do
        local lnum = index - 1
        if line:match(conflict_start) then
            has_start = true
            position = {
                current = { range_start = lnum, content_start = lnum + 1 },
                middle = {},
                incoming = {},
                ancestor = {},
            }
        end
        if has_start and line:match(conflict_ancestor) then
            has_ancestor = true
            position.ancestor.range_start = lnum
            position.ancestor.content_start = lnum + 1
            position.current.range_end = lnum - 1
            position.current.content_end = lnum - 1
        end
        if has_start and line:match(conflict_middle) then
            has_middle = true
            if has_ancestor then
                position.ancestor.content_end = lnum - 1
                position.ancestor.range_end = lnum - 1
            else
                position.current.range_end = lnum - 1
                position.current.content_end = lnum - 1
            end
            position.middle.range_start = lnum
            position.middle.range_end = lnum + 1
            position.incoming.range_start = lnum + 1
            position.incoming.content_start = lnum + 1
        end
        if has_start and has_middle and line:match(conflict_end) then
            position.incoming.range_end = lnum
            position.incoming.content_end = lnum - 1
            positions[#positions + 1] = position

            position, has_start, has_middle, has_ancestor = {}, false, false, false
        end
    end
    return #positions > 0, positions
end

---Derive the color of the section label highlights based on each sections highlights
---@param highlights ConflictHighlights
local function set_highlights(highlights)
    local function inner_set(hls, default_bg, hl, label_hl)
        local current_color = vim.api.nvim_get_hl(0, { name = hls })
        local current_bg = current_color.bg or default_bg
        local current_label_bg = color.shade_color(current_bg, 30) or current_bg
        vim.api.nvim_set_hl(0, hl, { bg = current_bg, default = true })
        vim.api.nvim_set_hl(0, label_hl, { bg = current_label_bg, default = true })
    end

    inner_set(highlights.current, DEFAULT_CURRENT_BG_COLOR, CURRENT_HL, CURRENT_LABEL_HL)
    inner_set(highlights.incoming, DEFAULT_INCOMING_BG_COLOR, INCOMING_HL, INCOMING_LABEL_HL)
    inner_set(highlights.ancestor, DEFAULT_ANCESTOR_BG_COLOR, ANCESTOR_HL, ANCESTOR_LABEL_HL)
end

---@param bufnr integer?
---@return boolean
local function buf_can_have_conflicts(bufnr)
    bufnr = bufnr or 0
    local result = -1
    vim.api.nvim_buf_call(
        bufnr,
        function() result = vim.fn.search(conflict_start, "cnw", nil, 500) end
    )
    return result > 0
end

local function clear_highlights(bufnr) vim.api.nvim_buf_clear_namespace(bufnr, NAMESPACE, 0, -1) end

local function clear_diagnostic(bufnr) vim.diagnostic.reset(NAMESPACE, bufnr) end

---Set diagnostics for all conflicts
---@param bufnr integer
---@param positions table
local function set_diagnostics(bufnr, positions)
    local diagnostics = {}
    for _, position in ipairs(positions) do
        table.insert(diagnostics, {
            lnum = position.current.range_start,
            end_lnum = position.incoming.range_end,
            col = 0,
            severity = vim.diagnostic.severity.E,
            message = "Git conflict",
            source = NAME,
        })
    end
    vim.diagnostic.set(NAMESPACE, bufnr, diagnostics)
end

---Find all conflicts and process them
---@param bufnr integer?
---@param range_start integer?
---@param range_end integer?
---@return ConflictPosition[]
local function run(bufnr, range_start, range_end)
    bufnr = bufnr or 0
    local lines = vim.api.nvim_buf_get_lines(bufnr or 0, range_start or 0, range_end or -1, false)
    local has_conflict, positions = detect_conflicts(lines)

    if has_conflict then
        vim.api.nvim_exec_autocmds("User", {
            pattern = "GitConflict",
            modeline = false,
            data = { buf = bufnr, positions = positions },
        })

        highlight_conflicts(bufnr, positions)

        if config.enable_diagnostics then set_diagnostics(bufnr, positions) end
    end
    return positions
end

local M = {}

---Clears all conflict highlights and diagnostics
---@param bufnr integer?
M.clear = function(bufnr)
    bufnr = bufnr or 0
    if not vim.api.nvim_buf_is_valid(bufnr) then return end
    clear_highlights(bufnr)
    if config.enable_diagnostics then clear_diagnostic(bufnr) end
end

---@type table<integer, ConflictPosition[]>
local buf_conflicts = {}

---Refreshes conflict highlight and diagnostics
---@param bufnr integer?
function M.refresh(bufnr)
    if not bufnr or bufnr == 0 then bufnr = vim.api.nvim_get_current_buf() end

    if buf_conflicts[bufnr] then
        M.clear(bufnr)
        buf_conflicts[bufnr] = nil
    end

    if buf_can_have_conflicts(bufnr) then
        local positions = run(bufnr)
        buf_conflicts[bufnr] = positions
    end
end

---Gets conflicts positions for a given buffer
---@param bufnr integer
---@return ConflictPosition[]
function M.positions(bufnr) return buf_conflicts[bufnr] end

---Call once to setup the plugin
function M.setup(user_config)
    config = vim.tbl_deep_extend("force", config, user_config or {})

    set_highlights(config.highlights)

    vim.api.nvim_create_autocmd("ColorScheme", {
        group = vim.api.nvim_create_augroup("GitConflictHighlights", { clear = true }),
        callback = function() set_highlights(config.highlights) end,
    })
end

return M
