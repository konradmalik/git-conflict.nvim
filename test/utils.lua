---in case of more than one, returns the first found
---@param bufnr integer
---@return integer?
local function winnr_for_bufnr(bufnr)
    for _, win in ipairs(vim.api.nvim_list_wins()) do
        if vim.api.nvim_win_get_buf(win) == bufnr then return win end
    end
end

return {
    ---@return integer
    create_buf_with_conflict = function()
        local bufnr = vim.api.nvim_create_buf(true, false)
        vim.api.nvim_buf_set_lines(bufnr, 0, 0, false, {
            "the conflict",
            "is below",
            "",
            "<<<<<<<",
            "current",
            "|||||||",
            "ancestor",
            "=======",
            "incoming",
            ">>>>>>>",
        })
        return bufnr
    end,

    winnr_for_bufnr = winnr_for_bufnr,

    ---@param bufnr integer
    ---@return integer
    create_win_with_bufnr = function(bufnr)
        return vim.api.nvim_open_win(bufnr, true, { split = "right" })
    end,

    ---@param winnr integer
    move_cursor_to_conflict = function(winnr) vim.api.nvim_win_set_cursor(winnr, { 5, 2 }) end,

    ---@param list integer[]
    ---@return integer?
    get_max_value = function(list)
        local max_value = list[1]
        for i = 2, #list do
            if list[i] > max_value then max_value = list[i] end
        end
        return max_value
    end,

    ---@param bufnr integer
    ---@return string[]
    get_buf_lines = function(bufnr) return vim.api.nvim_buf_get_lines(bufnr, 0, -1, true) end,

    close_buffers_except_initial = function()
        for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
            if bufnr ~= 1 then vim.api.nvim_buf_delete(bufnr, { force = true }) end
        end
    end,
}
