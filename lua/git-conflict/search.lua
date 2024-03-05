local conflicts = {}
local gather_stdout = function(_, data, _)
    for _, entry in ipairs(data) do
        if entry and entry ~= "" then table.insert(conflicts, entry) end
    end
end

local stdout_to_qflist = function()
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

local start_conflicts_job = function()
    conflicts = {}
    local conflict_marker = require("git-conflict.conflicts").conflict_start
    return vim.fn.jobstart({
        "git",
        "--no-pager",
        "grep",
        "--no-color",
        "--full-name",
        "--line-number",
        conflict_marker,
    }, {
        on_stdout = gather_stdout,
        on_exit = stdout_to_qflist,
    })
end

return {
    setqflist = start_conflicts_job,
}
