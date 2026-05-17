---@param conflicts string[]
---@param root string repo root used to resolve repo-relative filenames
local stdout_to_qflist = function(conflicts, root)
    ---@type vim.quickfix.entry[]
    local qf_entries = {}
    for _, conflict in ipairs(conflicts) do
        local filename, line = conflict:match("(.+):(%d+):")
        table.insert(qf_entries, {
            filename = vim.fs.joinpath(root, filename),
            lnum = tonumber(line),
            text = "Conflict marker",
            type = "E",
        })
    end
    vim.fn.setqflist({}, "r", { title = "Git Conflicts", items = qf_entries })
    vim.cmd("copen")
end

---@param bufnr integer
local start_conflicts_job = function(bufnr)
    local conflict_marker = require("git-conflict.markers").conflict_start
    local git_root = vim.fs.root(bufnr, ".git")
    if not git_root then
        vim.notify("git-conflict: buffer not inside a git repository", vim.log.levels.WARN)
        return
    end
    local obj = vim.system({
        "git",
        "--no-pager",
        "grep",
        "--no-color",
        "--full-name",
        "--line-number",
        conflict_marker,
    }, {
        text = true,
        cwd = git_root,
    }):wait()
    if not obj.stdout then return end
    local outlines = vim.fn.split(obj.stdout, "\n")
    stdout_to_qflist(outlines, git_root)
end

return {
    setqflist = start_conflicts_job,
}
