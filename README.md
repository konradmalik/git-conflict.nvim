# git-conflict.nvim

My refactored, simplified and in some cases extended version of [git-conflict](https://github.com/akinsho/git-conflict.nvim).

Main aim:

-   must be simple, very lightweight and maintainable by me.
-   be more of a library that a typical plugin.

## TL;DR

Default config:

```lua
require('git-conflict').setup({
    highlights = {
        current = "diffAdded",
        incoming = "diffChanged",
        ancestor = "diffRemoved",
    },
    labels = {
        current = "(Current Change)",
        incoming = "(Incoming Change)",
        ancestor = "(Base Change)",
    },
    enable_diagnostics = true,
})

```

This plugin defined a `GitConflict` `User` event that is triggered on every `M.refresh(bufnr)` that detected any conflicts.

It's useful to define other buffer-specific commands, autocommands or keymaps based on that event.

Exemplary usage in your neovim configuration:

```lua
local cmd = require("git-conflict.commands")
local gc = require("git-conflict")
local opts_with_desc = function(desc) return { desc = "[GitConflict] " .. desc } end
local function buf_opts_with_desc(bufnr, desc)
    local opts = opts_with_desc(desc)
    opts.buffer = bufnr
    return opts
end

gc.setup({
    highlights = {
        current = "diffAdded",
        incoming = "diffChanged",
        ancestor = "diffDeleted",
    },
})

local group = vim.api.nvim_create_augroup("GitConflict", { clear = true })

vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost" }, {
    group = group,
    callback = function(args)
        local buf = args.buf
        gc.refresh(buf)
    end,
})

vim.keymap.set("n", "]x", cmd.buf_next_conflict, opts_with_desc("Next Conflict"))
vim.keymap.set("n", "[x", cmd.buf_prev_conflict, opts_with_desc("Previous Conflict"))
vim.keymap.set(
    "n",
    "<leader>xq",
    cmd.send_conflicts_to_qf,
    opts_with_desc("Send repo conflicts to QF")
)

vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "GitConflict",
    callback = function(args)
        local buf = args.buf

        vim.keymap.set(
            "n",
            "<leader>co",
            function() cmd.buf_conflict_choose_current(buf) end,
            buf_opts_with_desc("Choose ours (current/HEAD/LOCAL)")
        )

        vim.keymap.set(
            "n",
            "<leader>ct",
            function() cmd.buf_conflict_choose_incoming(buf) end,
            buf_opts_with_desc("Choose theirs (incoming/REMOTE)")
        )

        vim.keymap.set(
            "n",
            "<leader>cb",
            function() cmd.buf_conflict_choose_both(buf) end,
            buf_opts_with_desc("Choose both")
        )

        vim.keymap.set(
            "n",
            "<leader>cn",
            function() cmd.buf_conflict_choose_none(buf) end,
            buf_opts_with_desc("Choose none")
        )
    end,
})
```

## Notable features:

-   plugin works more lazily
    -   executes via autocmd only when buffer is likely to have conflicts
-   publishes `GitConflict` `User` for easy integration
-   does not scan the whole repo for all conflicted files
-   creates diagnostics for conflicts
-   commands (see `commands.lua`)
    -   jump to prev/next conflict
    -   choose ours/theirs/both versions
    -   on demand to send conflicts in all files to a QF list

Sorry, not much more documentation this time. See code for details.
Notably the module returned in `init.lua` should be self-explanatory.
Useful functions can be imported and used via `require("git-conflict.commands")`.
