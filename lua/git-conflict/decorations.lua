--- @class ConflictHighlights
--- @field current string
--- @field incoming string
--- @field ancestor string?

--- @class ConflictLabels
--- @field current string
--- @field incoming string
--- @field ancestor string

local NAME = "git-conflict"
local NAMESPACE = vim.api.nvim_create_namespace(NAME)
local PRIORITY = vim.hl.priorities.diagnostics - 1

local CURRENT_HL = "GitConflictCurrent"
local INCOMING_HL = "GitConflictIncoming"
local ANCESTOR_HL = "GitConflictAncestor"
local CURRENT_LABEL_HL = "GitConflictCurrentLabel"
local INCOMING_LABEL_HL = "GitConflictIncomingLabel"
local ANCESTOR_LABEL_HL = "GitConflictAncestorLabel"

---@param bufnr integer
---@param hl string
---@param range_start integer
---@param range_end integer
local function hl_range(bufnr, hl, range_start, range_end)
    if not range_start or not range_end then return end
    vim.api.nvim_buf_set_extmark(bufnr, NAMESPACE, range_start, 0, {
        hl_group = hl,
        hl_eol = true,
        hl_mode = "combine",
        end_row = range_end,
        priority = PRIORITY,
    })
end

---@param bufnr integer
---@param hl_group string
---@param label string
---@param lnum integer
local function draw_section_label(bufnr, hl_group, label, lnum)
    vim.api.nvim_buf_set_extmark(bufnr, NAMESPACE, lnum, 0, {
        hl_group = hl_group,
        virt_text = { { label, hl_group } },
        virt_text_pos = "eol",
        priority = PRIORITY,
    })
end

---@param bufnr integer
---@param positions ConflictPosition[]
---@param labels ConflictLabels
local function highlight_conflicts(bufnr, positions, labels)
    for _, position in ipairs(positions) do
        local current_start = position.current.range_start
        local current_end = position.current.range_end
        local incoming_start = position.incoming.range_start
        local incoming_end = position.incoming.range_end

        draw_section_label(bufnr, CURRENT_LABEL_HL, labels.current, current_start)
        hl_range(bufnr, CURRENT_LABEL_HL, current_start, current_start + 1)
        hl_range(bufnr, CURRENT_HL, current_start + 1, current_end + 1)
        draw_section_label(bufnr, INCOMING_LABEL_HL, labels.incoming, incoming_end)
        hl_range(bufnr, INCOMING_HL, incoming_start, incoming_end)
        hl_range(bufnr, INCOMING_LABEL_HL, incoming_end, incoming_end + 1)

        if position.ancestor then
            local ancestor_start = position.ancestor.range_start
            local ancestor_end = position.ancestor.range_end
            draw_section_label(bufnr, ANCESTOR_LABEL_HL, labels.ancestor, ancestor_start)
            hl_range(bufnr, ANCESTOR_LABEL_HL, ancestor_start, ancestor_start + 1)
            hl_range(bufnr, ANCESTOR_HL, ancestor_start + 1, ancestor_end + 1)
        end
    end
end

---@param bufnr integer
---@param positions ConflictPosition[]
local function set_diagnostics(bufnr, positions)
    local diagnostics = {}
    for _, position in ipairs(positions) do
        diagnostics[#diagnostics + 1] = {
            lnum = position.current.range_start,
            end_lnum = position.incoming.range_end,
            col = 0,
            severity = vim.diagnostic.severity.ERROR,
            message = "Git conflict",
            source = NAME,
        }
    end
    vim.diagnostic.set(NAMESPACE, bufnr, diagnostics)
end

local M = {}

---@param highlights ConflictHighlights
function M.set_highlights(highlights)
    local groups = {
        {
            src = highlights.current,
            fallback = "#405d7e",
            hl = CURRENT_HL,
            label = CURRENT_LABEL_HL,
        },
        {
            src = highlights.incoming,
            fallback = "#314753",
            hl = INCOMING_HL,
            label = INCOMING_LABEL_HL,
        },
        {
            src = highlights.ancestor,
            fallback = "#68217a",
            hl = ANCESTOR_HL,
            label = ANCESTOR_LABEL_HL,
        },
    }
    for _, g in ipairs(groups) do
        local bg = vim.api.nvim_get_hl(0, { name = g.src }).bg or g.fallback
        vim.api.nvim_set_hl(0, g.hl, { bg = bg, default = true })
        vim.api.nvim_set_hl(0, g.label, { bg = bg, bold = true, default = true })
    end
end

---@param bufnr integer
---@param positions ConflictPosition[]
---@param labels ConflictLabels
---@param enable_diagnostics boolean
function M.apply(bufnr, positions, labels, enable_diagnostics)
    highlight_conflicts(bufnr, positions, labels)
    if enable_diagnostics then set_diagnostics(bufnr, positions) end
end

---@param bufnr integer
---@param enable_diagnostics boolean
function M.clear(bufnr, enable_diagnostics)
    vim.api.nvim_buf_clear_namespace(bufnr, NAMESPACE, 0, -1)
    if enable_diagnostics then vim.diagnostic.reset(NAMESPACE, bufnr) end
end

return M
