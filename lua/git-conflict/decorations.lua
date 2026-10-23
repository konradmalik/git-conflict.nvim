--- @class ConflictHighlights
--- @field current string
--- @field incoming string
--- @field ancestor string

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
---@param range_end integer exclusive
---@param label string? virtual text at the end of the first line
local function hl_range(bufnr, hl, range_start, range_end, label)
    vim.api.nvim_buf_set_extmark(bufnr, NAMESPACE, range_start, 0, {
        hl_group = hl,
        hl_eol = true,
        hl_mode = "combine",
        end_row = range_end,
        virt_text = label and { { label, hl } },
        virt_text_pos = label and "eol",
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

        hl_range(bufnr, CURRENT_LABEL_HL, current_start, current_start + 1, labels.current)
        hl_range(bufnr, CURRENT_HL, current_start + 1, current_end + 1)
        hl_range(bufnr, INCOMING_HL, incoming_start, incoming_end)
        hl_range(bufnr, INCOMING_LABEL_HL, incoming_end, incoming_end + 1, labels.incoming)

        if position.ancestor then
            local ancestor_start = position.ancestor.range_start
            local ancestor_end = position.ancestor.range_end
            hl_range(bufnr, ANCESTOR_LABEL_HL, ancestor_start, ancestor_start + 1, labels.ancestor)
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
---@param default boolean keep highlight groups that are already defined
function M.set_highlights(highlights, default)
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
        vim.api.nvim_set_hl(0, g.hl, { bg = bg, default = default })
        vim.api.nvim_set_hl(0, g.label, { bg = bg, bold = true, default = default })
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
function M.clear(bufnr)
    vim.api.nvim_buf_clear_namespace(bufnr, NAMESPACE, 0, -1)
    vim.diagnostic.reset(NAMESPACE, bufnr)
end

return M
