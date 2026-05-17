local gc = require("git-conflict")
local conflict_marker = require("git-conflict.markers").conflict_start

---@param bufnr integer
---@param section Range
---@return string[]
local function get_section_lines(bufnr, section)
    return vim.api.nvim_buf_get_lines(bufnr, section.content_start, section.content_end + 1, true)
end

---@param bufnr integer
---@param position ConflictPosition
---@param replacement string[]
local function replace_conflict(bufnr, position, replacement)
    vim.api.nvim_buf_set_lines(
        bufnr,
        position.current.range_start,
        position.incoming.range_end + 1,
        true,
        replacement
    )
end

---@param bufnr integer
---@param positions ConflictPosition[]
---@param action fun(bufnr: integer, position: ConflictPosition)
local function process_current_conflict(bufnr, positions, action)
    local line1, _ = unpack(vim.api.nvim_win_get_cursor(0))
    -- lines from API are 0-indexed
    local line = line1 - 1
    for _, position in ipairs(positions) do
        if position.current.range_start <= line and position.incoming.range_end >= line then
            action(bufnr, position)
            -- important to refresh after changing the conflict
            gc.refresh(bufnr)
            return
        end
    end
    vim.notify("no conflict at that line", vim.log.levels.WARN)
end

---@param bufnr integer?
---@param action fun(bufnr: integer, position: ConflictPosition)
local function with_current_conflict(bufnr, action)
    if not bufnr or bufnr == 0 then bufnr = vim.api.nvim_get_current_buf() end
    local positions = gc.positions(bufnr) or {}
    process_current_conflict(bufnr, positions, action)
end

local M = {}

---find next conflict in the current buffer
M.buf_next_conflict = function() vim.fn.search(conflict_marker, "w") end

---find previous conflict in the current buffer
M.buf_prev_conflict = function() vim.fn.search(conflict_marker, "bw") end

---send all conflicts in the repo to QF list
M.send_conflicts_to_qf = function() require("git-conflict.search").setqflist(0) end

---Choose ours (current/HEAD/LOCAL)
---@param bufnr integer?
M.buf_conflict_choose_current = function(bufnr)
    with_current_conflict(
        bufnr,
        function(buf, pos) replace_conflict(buf, pos, get_section_lines(buf, pos.current)) end
    )
end

---Choose theirs (incoming/REMOTE)
---@param bufnr integer?
M.buf_conflict_choose_incoming = function(bufnr)
    with_current_conflict(
        bufnr,
        function(buf, pos) replace_conflict(buf, pos, get_section_lines(buf, pos.incoming)) end
    )
end

---Choose both
---@param bufnr integer?
M.buf_conflict_choose_both = function(bufnr)
    with_current_conflict(bufnr, function(buf, pos)
        local lines = get_section_lines(buf, pos.current)
        vim.list_extend(lines, get_section_lines(buf, pos.incoming))
        replace_conflict(buf, pos, lines)
    end)
end

---Choose none
---@param bufnr integer?
M.buf_conflict_choose_none = function(bufnr)
    with_current_conflict(bufnr, function(buf, pos) replace_conflict(buf, pos, {}) end)
end

return M
