# git-conflict.nvim

My refactored, simplified and in some cases extended version of [git-conflict](https://github.com/akinsho/git-conflict.nvim).

Main aim - must be simple, very lightweight and maintainable by me.

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
    enable_autocommand = true,
    enable_diagnostics = true,
    enable_keymaps = true,
})

```

## Notable features:

-   plugin works more lazily
    -   executes via autocmd only when buffer is likely to have conflicts
-   does not scan the whole repo for all conflicted files
-   custom diagnostics for conflicts
-   keymaps (see `keymaps.lua`)
    -   jump to prev/next conflict
    -   choose ours/theirs/both versions
    -   on demand to send confilts in all files to a QF list

Sorry, not much more documentation this time. See code for details.
