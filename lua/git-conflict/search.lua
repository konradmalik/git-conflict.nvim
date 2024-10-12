---@param conflicts string[]
local stdout_to_qflist = function(conflicts)
    local qf_entries = {}
    for _, conflict in ipairs(conflicts) do
        local filename, line = conflict:match("(.+):(%d+):")
        table.insert(qf_entries, {
            filename = filename,
            lnum = line,
            text = "Conflict marker",
            type = "E",
        })
    end
    vim.fn.setqflist({}, "r", { title = "Git Conflicts", items = qf_entries })
    vim.cmd("copen")
end

---@param bufnr integer
local start_conflicts_job = function(bufnr)
    local conflict_marker = require("git-conflict.shared").conflict_start
    local git_root = vim.fs.root(bufnr, ".git")
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
    stdout_to_qflist(outlines)
end

return {
    setqflist = start_conflicts_job,
}
