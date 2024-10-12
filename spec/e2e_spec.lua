local gc = require("git-conflict")

local working_directory

---@return string
local function prepare_git_repo()
    local tmpdir = assert(vim.uv.fs_mkdtemp(vim.uv.os_tmpdir() .. "/git-conflict-nvim-XXXXXX"))
    assert(vim.uv.fs_copyfile("./test/create_conflict.sh", tmpdir .. "/create_conflict.sh"))
    assert(os.execute("cd " .. tmpdir .. " && ./create_conflict.sh &> /dev/null"))
    return tmpdir
end

describe("in conflicted file", function()
    setup(function() working_directory = prepare_git_repo() end)
    teardown(function()
        if working_directory then assert(os.execute("rm -rf " .. working_directory)) end
    end)

    -- TODO this test does not need e2e
    -- we should test here something else, like list files with conflicts (QF list)
    it("populates positions after refresh", function()
        -- arrange
        local bufnr = vim.api.nvim_create_buf(true, false)
        vim.api.nvim_buf_set_name(bufnr, working_directory .. "/conflict-test/conflicted.lua")
        vim.api.nvim_buf_call(bufnr, vim.cmd.edit)

        -- act
        gc.refresh(bufnr)

        -- assert
        local actual_positons = gc.positions(bufnr)
        assert.are.same({
            {
                ["ancestor"] = {
                    ["content_end"] = 5,
                    ["content_start"] = 5,
                    ["range_end"] = 5,
                    ["range_start"] = 4,
                },
                ["current"] = {
                    ["content_end"] = 3,
                    ["content_start"] = 1,
                    ["range_end"] = 3,
                    ["range_start"] = 0,
                },
                ["incoming"] = {
                    ["content_end"] = 7,
                    ["content_start"] = 7,
                    ["range_end"] = 8,
                    ["range_start"] = 7,
                },
                ["middle"] = {
                    ["range_end"] = 7,
                    ["range_start"] = 6,
                },
            },
        }, actual_positons)
    end)
end)
