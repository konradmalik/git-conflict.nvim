local group = vim.api.nvim_create_augroup("GitConflict", { clear = true })
vim.api.nvim_create_autocmd({ "VimEnter", "ColorScheme" }, {
    group = group,
    callback = function() require("git-conflict").set_highlights() end,
})
-- loaded lazily, VimEnter already happened
if vim.v.vim_did_enter == 1 then require("git-conflict").set_highlights() end

vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost" }, {
    group = group,
    callback = function(args) require("git-conflict").refresh(args.buf) end,
})

vim.api.nvim_create_autocmd("BufWipeout", {
    group = group,
    callback = function(args) require("git-conflict").clear(args.buf) end,
})
