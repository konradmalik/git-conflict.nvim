local commands = require("git-conflict.commands")
local utils = require("test.utils")

local working_directory

---@return string
local function prepare_git_repo()
    local mktemp_obj = vim.system(
        { "mktemp", "-d", "-t", "git-conflict-nvim-XXXXXX" },
        { text = true }
    )
        :wait()

    if mktemp_obj.code ~= 0 then error("cannot create tmpdir") end

    local tmpdir = vim.fn.split(mktemp_obj.stdout, "\n")[1]

    local code = vim.system({ "cp", "./test/create_conflict.sh", tmpdir .. "/create_conflict.sh" })
        :wait().code
    if code ~= 0 then error("cannot copy create_conflict script") end
    code = vim.system({ "./create_conflict.sh" }, { cwd = tmpdir }):wait().code
    if code ~= 0 then error("cannot execute create_conflict script") end
    return tmpdir
end

describe("in repo with conflicts", function()
    setup(function() working_directory = prepare_git_repo() end)
    teardown(function()
        if working_directory then assert(os.execute("rm -rf " .. working_directory)) end
    end)
    after_each(function() utils.close_buffers_except_initial() end)

    it("populates quickfix list", function()
        -- arrange
        vim.cmd.edit(working_directory .. "/conflict-test/new.lua")

        -- act
        commands.send_conflicts_to_qf()
        local actual_qflist = vim.fn.getqflist()

        -- assert
        local buffers = vim.api.nvim_list_bufs()
        local buf1 = buffers[#buffers - 2]
        local buf2 = buffers[#buffers - 1]
        assert.are.same({
            {
                ["bufnr"] = buf1,
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
                ["bufnr"] = buf2,
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
