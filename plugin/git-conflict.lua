local group = vim.api.nvim_create_augroup("GitConflict", { clear = true })
vim.api.nvim_create_autocmd({ "VimEnter", "ColorScheme" }, {
    group = group,
    callback = function() require("git-conflict").set_highlights() end,
})

vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost" }, {
    group = group,
    callback = function(args)
        local buf = args.buf
        require("git-conflict").refresh(buf)
    end,
})
