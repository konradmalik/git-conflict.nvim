local decorations = require("git-conflict.decorations")
local parser = require("git-conflict.parser")

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

---@type table<integer, ConflictPosition[]>
local buf_conflicts = {}

local M = {}

---Clears all conflict highlights and diagnostics
---@param bufnr integer?
function M.clear(bufnr)
    if not bufnr or bufnr == 0 then bufnr = vim.api.nvim_get_current_buf() end
    if not vim.api.nvim_buf_is_valid(bufnr) then return end
    decorations.clear(bufnr, config.enable_diagnostics)
end

---Refreshes conflict highlight and diagnostics
---@param bufnr integer?
function M.refresh(bufnr)
    if not bufnr or bufnr == 0 then bufnr = vim.api.nvim_get_current_buf() end
    if not vim.api.nvim_buf_is_valid(bufnr) then
        buf_conflicts[bufnr] = nil
        return
    end

    if buf_conflicts[bufnr] then
        decorations.clear(bufnr, config.enable_diagnostics)
        buf_conflicts[bufnr] = nil
    end

    if not parser.buf_can_have_conflicts(bufnr) then return end

    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local positions = parser.detect_conflicts(lines)
    if #positions == 0 then return end

    buf_conflicts[bufnr] = positions

    vim.api.nvim_exec_autocmds("User", {
        pattern = "GitConflict",
        modeline = false,
        data = { buf = bufnr, positions = positions },
    })

    decorations.apply(bufnr, positions, config.labels, config.enable_diagnostics)
end

---Gets conflicts positions for a given buffer
---@param bufnr integer
---@return ConflictPosition[]?
function M.positions(bufnr) return buf_conflicts[bufnr] end

---Sets highlights and their colors based on config
function M.set_highlights() decorations.set_highlights(config.highlights) end

---Call needed only if changing the config
function M.setup(user_config)
    config = vim.tbl_deep_extend("force", config, user_config or {})
    M.set_highlights()
end

return M
