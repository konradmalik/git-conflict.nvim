local commands = require("git-conflict.commands")

local working_directory

---@return string
local function prepare_git_repo()
    local tmpdir = assert(vim.uv.fs_mkdtemp(vim.uv.os_tmpdir() .. "/git-conflict-nvim-XXXXXX"))
    assert(vim.uv.fs_copyfile("./test/create_conflict.sh", tmpdir .. "/create_conflict.sh"))
    assert(os.execute("cd " .. tmpdir .. " && ./create_conflict.sh &> /dev/null"))
    return tmpdir
end

describe("in repo with conflicts", function()
    setup(function() working_directory = prepare_git_repo() end)
    teardown(function()
        if working_directory then assert(os.execute("rm -rf " .. working_directory)) end
    end)

    it("populates quickfix list", function()
        -- arrange
        vim.cmd.edit(working_directory .. "/conflict-test/conflicted.lua")

        -- act
        commands.send_conflicts_to_qf()
        local actual_qflist = vim.fn.getqflist()

        -- assert
        assert.are.same({
            {
                ["bufnr"] = 2,
                ["col"] = 0,
                ["end_col"] = 0,
                ["end_lnum"] = 0,
                ["lnum"] = 1,
                ["module"] = "",
                ["nr"] = 0,
                ["pattern"] = "",
                ["text"] = "Conflict marker",
                ["type"] = "E",
                ["valid"] = 1,
                ["vcol"] = 0,
            },
            {
                ["bufnr"] = 3,
                ["col"] = 0,
                ["end_col"] = 0,
                ["end_lnum"] = 0,
                ["lnum"] = 1,
                ["module"] = "",
                ["nr"] = 0,
                ["pattern"] = "",
                ["text"] = "Conflict marker",
                ["type"] = "E",
                ["valid"] = 1,
                ["vcol"] = 0,
            },
        }, actual_qflist)
    end)
end)
