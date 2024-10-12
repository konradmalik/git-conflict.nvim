---@return integer
return {
    ---@return integer
    create_buf_with_conflict = function()
        local bufnr = vim.api.nvim_create_buf(true, false)
        vim.api.nvim_buf_set_lines(bufnr, 0, 0, false, {
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

    ---@param list integer[]
    ---@return integer?
    get_max_value = function(list)
        local max_value = list[1]
        for i = 2, #list do
            if list[i] > max_value then max_value = list[i] end
        end
        return max_value
    end,

    close_buffers_except_initial = function()
        for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
            if bufnr ~= 1 then vim.api.nvim_buf_delete(bufnr, { force = true }) end
        end
    end,
}
