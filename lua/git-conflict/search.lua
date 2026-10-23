local conflict_marker = require("git-conflict.markers").conflict_start

---@param conflicts string[] git grep output lines
---@param root string repo root used to resolve repo-relative filenames
---@return vim.quickfix.entry[]
local to_qf_items = function(conflicts, root)
    ---@type vim.quickfix.entry[]
    local qf_entries = {}
    for _, conflict in ipairs(conflicts) do
        local filename, line = conflict:match("^(.-):(%d+):")
        table.insert(qf_entries, {
            filename = vim.fs.joinpath(root, filename),
            lnum = tonumber(line),
            text = "Conflict marker",
            type = "E",
        })
    end
    return qf_entries
end

---@param bufnr integer
local setqflist = function(bufnr)
    local git_root = vim.fs.root(bufnr, ".git")
    if not git_root then
        vim.notify("git-conflict: buffer not inside a git repository", vim.log.levels.WARN)
        return
    end
    vim.system(
        {
            "git",
            "--no-pager",
            "grep",
            "--no-color",
            "-I", -- skip binary files, they print no line numbers
            "--full-name",
            "--line-number",
            conflict_marker,
        },
        {
            text = true,
            cwd = git_root,
        },
        vim.schedule_wrap(function(obj)
            -- git grep exits with 1 when nothing matched
            if obj.code > 1 then
                vim.notify("git-conflict: " .. obj.stderr, vim.log.levels.ERROR)
                return
            end
            local items = to_qf_items(vim.split(obj.stdout, "\n", { trimempty = true }), git_root)
            vim.fn.setqflist({}, "r", { title = "Git Conflicts", items = items })
            vim.cmd("copen")
        end)
    )
end

return {
    setqflist = setqflist,
    to_qf_items = to_qf_items,
}
