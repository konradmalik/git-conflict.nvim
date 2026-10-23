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

---@param bufnr integer?
---@return integer
local function resolve(bufnr)
    if not bufnr or bufnr == 0 then return vim.api.nvim_get_current_buf() end
    return bufnr
end

local M = {}

---Clears all conflict highlights and diagnostics
---@param bufnr integer?
function M.clear(bufnr)
    bufnr = resolve(bufnr)
    -- a buffer is decorated if and only if it has cached positions
    if not buf_conflicts[bufnr] then return end
    buf_conflicts[bufnr] = nil
    if vim.api.nvim_buf_is_valid(bufnr) then decorations.clear(bufnr) end
end

---Refreshes conflict highlight and diagnostics
---@param bufnr integer?
function M.refresh(bufnr)
    bufnr = resolve(bufnr)
    M.clear(bufnr)
    if not vim.api.nvim_buf_is_valid(bufnr) or not parser.buf_can_have_conflicts(bufnr) then
        return
    end

    local positions = parser.detect_conflicts(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false))
    if #positions == 0 then return end

    buf_conflicts[bufnr] = positions
    decorations.apply(bufnr, positions, config.labels, config.enable_diagnostics)

    vim.api.nvim_exec_autocmds("User", {
        pattern = "GitConflict",
        modeline = false,
        data = { buf = bufnr, positions = positions },
    })
end

---Gets conflicts positions for a given buffer
---@param bufnr integer?
---@return ConflictPosition[]?
function M.positions(bufnr) return buf_conflicts[resolve(bufnr)] end

---Sets highlights and their colors based on config, keeps already defined ones
function M.set_highlights() decorations.set_highlights(config.highlights, true) end

---Call needed only if changing the config
function M.setup(user_config)
    config = vim.tbl_deep_extend("force", config, user_config or {})
    decorations.set_highlights(config.highlights, false)
end

return M
