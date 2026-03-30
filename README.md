# git-conflict.nvim

My refactored, simplified and in some cases extended version of [git-conflict](https://github.com/akinsho/git-conflict.nvim).

Main aim:

- simple, very lightweight and maintainable by me
- full control when and how it's executed

## TL;DR

Default config (no need to call setup if you're not changing the default config):

```lua
require('git-conflict').setup({
    highlights = {
        -- note that highlights need to have a bg
        -- otherwise default color will be used
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
})

```

This plugin defines a `GitConflict` `User` event that is triggered on every `M.refresh(bufnr)` that detected any conflicts.

It's useful to define other buffer-specific commands, autocommands or keymaps based on that event.

Exemplary usage in my Neovim configuration:

```lua
local opts_with_desc = function(desc) return { desc = "[GitConflict] " .. desc } end
local function buf_opts_with_desc(bufnr, desc)
    local opts = opts_with_desc(desc)
    opts.buffer = bufnr
    return opts
end

vim.keymap.set(
    "n",
    "]x",
    require("git-conflict.commands").buf_next_conflict,
    opts_with_desc("Next Conflict")
)
vim.keymap.set(
    "n",
    "[x",
    require("git-conflict.commands").buf_prev_conflict,
    opts_with_desc("Previous Conflict")
)
vim.keymap.set(
    "n",
    "<leader>xq",
    require("git-conflict.commands").send_conflicts_to_qf,
    opts_with_desc("Send repo conflicts to QF")
)

vim.api.nvim_create_autocmd("User", {
    group = vim.api.nvim_create_augroup("OnGitConflict", { clear = true }),
    pattern = "GitConflict",
    callback = function(args)
        local cmd = require("git-conflict.commands")
        local buf = args.buf

        vim.api.nvim_buf_create_user_command(
            buf,
            "ConflictChooseOurs",
            function() cmd.buf_conflict_choose_current(buf) end,
            opts_with_desc("Choose ours (current/HEAD/LOCAL)")
        )
        vim.keymap.set(
            "n",
            "<leader>co",
            function() cmd.buf_conflict_choose_current(buf) end,
            buf_opts_with_desc(buf, "Choose ours (current/HEAD/LOCAL)")
        )

        vim.api.nvim_buf_create_user_command(
            buf,
            "ConflictChooseTheirs",
            function() cmd.buf_conflict_choose_incoming(buf) end,
            opts_with_desc("Choose theirs (incoming/REMOTE)")
        )
        vim.keymap.set(
            "n",
            "<leader>ct",
            function() cmd.buf_conflict_choose_incoming(buf) end,
            buf_opts_with_desc(buf, "Choose theirs (incoming/REMOTE)")
        )

        vim.api.nvim_buf_create_user_command(
            buf,
            "ConflictChooseBoth",
            function() cmd.buf_conflict_choose_both(buf) end,
            opts_with_desc("Choose both")
        )
        vim.keymap.set(
            "n",
            "<leader>cb",
            function() cmd.buf_conflict_choose_both(buf) end,
            buf_opts_with_desc(buf, "Choose both")
        )

        vim.api.nvim_buf_create_user_command(
            buf,
            "ConflictChooseNone",
            function() cmd.buf_conflict_choose_none(buf) end,
            opts_with_desc("Choose none")
        )
        vim.keymap.set(
            "n",
            "<leader>cn",
            function() cmd.buf_conflict_choose_none(buf) end,
            buf_opts_with_desc(buf, "Choose none")
        )
    end,
})
```

## Notable features:

- publishes `GitConflict` `User` autocommand for easy integration
- creates diagnostics for conflicts
- commands (see `commands.lua`)
    - jump to prev/next conflict
    - choose ours/theirs/both versions
    - send conflicts in current repo to a QF list

See the code for more details.

Notably the module returned in `init.lua` should be self-explanatory.
Useful functions can be imported and used via `require("git-conflict.commands")`.
