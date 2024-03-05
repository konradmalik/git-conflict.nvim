local gc = require("git-conflict")
local conflict_marker = require("git-conflict.conflicts").conflict_start

---@param bufnr integer
---@param position ConflictPosition
---@param replacement string[]
local replace_conflict = function(bufnr, position, replacement)
    vim.api.nvim_buf_set_lines(
        bufnr,
        position.current.range_start,
        position.incoming.range_end + 1,
        true,
        replacement
    )
end

---@param bufnr integer
---@param position ConflictPosition
local choose_current = function(bufnr, position)
    local choosen = vim.api.nvim_buf_get_lines(
        bufnr,
        position.current.content_start,
        position.current.content_end + 1,
        true
    )
    replace_conflict(bufnr, position, choosen)
end

---@param bufnr integer
---@param position ConflictPosition
local choose_incoming = function(bufnr, position)
    local choosen = vim.api.nvim_buf_get_lines(
        bufnr,
        position.incoming.content_start,
        position.incoming.content_end + 1,
        true
    )
    replace_conflict(bufnr, position, choosen)
end

---@param bufnr integer
---@param position ConflictPosition
local choose_both = function(bufnr, position)
    local current = vim.api.nvim_buf_get_lines(
        bufnr,
        position.current.content_start,
        position.current.content_end + 1,
        true
    )
    local incoming = vim.api.nvim_buf_get_lines(
        bufnr,
        position.incoming.content_start,
        position.incoming.content_end + 1,
        true
    )
    local choosen = {}
    vim.list_extend(choosen, current)
    vim.list_extend(choosen, incoming)
    replace_conflict(bufnr, position, choosen)
end

---@param bufnr integer
---@param position ConflictPosition
local choose_none = function(bufnr, position) replace_conflict(bufnr, position, {}) end

---@param bufnr integer
---@param positions ConflictPosition[]
---@param action function
local process_current_conflict = function(bufnr, positions, action)
    local line1, _ = unpack(vim.api.nvim_win_get_cursor(0))
    -- we expect lines to be 0-indexed
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

local M = {}

---find next conflict in the current buffer
M.buf_next_conflict = function() vim.fn.search(conflict_marker, "w") end

---find prev conflict in the current buffer
M.buf_prev_conflict = function() vim.fn.search(conflict_marker, "bw") end

---send all conflicts in the repo to QF list
M.send_conflicts_to_qf = function()
    local search = require("git-conflict.search")
    search.setqflist()
end

---Choose ours (current/HEAD/LOCAL)
---@param bufnr integer?
M.buf_conflict_choose_current = function(bufnr)
    if not bufnr or bufnr == 0 then bufnr = vim.api.nvim_get_current_buf() end
    local positions = gc.positions(bufnr) or {}
    process_current_conflict(bufnr, positions, choose_current)
end

---Choose theirs (incoming/REMOTE)
---@param bufnr integer?
M.buf_conflict_choose_incoming = function(bufnr)
    if not bufnr or bufnr == 0 then bufnr = vim.api.nvim_get_current_buf() end
    local positions = gc.positions(bufnr) or {}
    process_current_conflict(bufnr, positions, choose_incoming)
end

---Choose both
---@param bufnr integer?
M.buf_conflict_choose_both = function(bufnr)
    if not bufnr or bufnr == 0 then bufnr = vim.api.nvim_get_current_buf() end
    local positions = gc.positions(bufnr) or {}
    process_current_conflict(bufnr, positions, choose_both)
end

---Choose none
---@param bufnr integer?
M.buf_conflict_choose_none = function(bufnr)
    if not bufnr or bufnr == 0 then bufnr = vim.api.nvim_get_current_buf() end
    local positions = gc.positions(bufnr) or {}
    process_current_conflict(bufnr, positions, choose_none)
end

return M
