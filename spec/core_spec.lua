local gc = require("git-conflict")
local utils = require("test.utils")

---@param bufnr integer
---@param nsid integer
---@param count integer
---@param hlgroup string
---@param linenr integer 0-based
local function assert_extmarks(bufnr, nsid, count, hlgroup, linenr)
    local exts = vim.api.nvim_buf_get_extmarks(
        bufnr,
        nsid,
        { linenr, 0 },
        { linenr, 0 },
        { details = true }
    )
    assert.are.same(count, #exts)
    for i = 1, count do
        assert.are.same(hlgroup, exts[i][4].hl_group)
    end
end

describe("in buffer with conflicts", function()
    local bufnr
    before_each(function() bufnr = utils.create_buf_with_conflict() end)
    after_each(function() utils.close_buffers_except_initial() end)

    it("populates positions after refresh", function()
        -- act
        gc.refresh(bufnr)

        -- assert
        local actual_positons = gc.positions(bufnr)
        assert.are.same({
            {
                ["ancestor"] = {
                    ["content_end"] = 6,
                    ["content_start"] = 6,
                    ["range_end"] = 6,
                    ["range_start"] = 5,
                },
                ["current"] = {
                    ["content_end"] = 4,
                    ["content_start"] = 4,
                    ["range_end"] = 4,
                    ["range_start"] = 3,
                },
                ["incoming"] = {
                    ["content_end"] = 8,
                    ["content_start"] = 8,
                    ["range_end"] = 9,
                    ["range_start"] = 8,
                },
                ["middle"] = {
                    ["range_end"] = 8,
                    ["range_start"] = 7,
                },
            },
        }, actual_positons)
    end)

    it("populates diagnostics after refresh", function()
        -- act
        gc.refresh(bufnr)

        -- assert
        local actual_diagnostics = vim.diagnostic.get(bufnr)
        assert.are.same({
            {
                ["bufnr"] = bufnr,
                ["col"] = 0,
                ["end_col"] = 0,
                ["end_lnum"] = 9,
                ["lnum"] = 3,
                ["message"] = "Git conflict",
                ["namespace"] = 2,
                ["severity"] = 1,
                ["source"] = "git-conflict",
            },
        }, actual_diagnostics)
    end)

    it("does clear diagnostics", function()
        -- act
        gc.refresh(bufnr)
        gc.clear(bufnr)

        -- assert
        local actual_diagnostics = vim.diagnostic.get(bufnr)
        assert.are.same({}, actual_diagnostics)
    end)

    it("applies extmarks within namespace", function()
        -- arrange
        local nsid = vim.api.nvim_get_namespaces()["git-conflict"]

        -- act
        gc.refresh(bufnr)

        -- assert
        assert_extmarks(bufnr, nsid, 2, "GitConflictCurrentLabel", 3)
        assert_extmarks(bufnr, nsid, 1, "GitConflictCurrent", 4)
        assert_extmarks(bufnr, nsid, 2, "GitConflictAncestorLabel", 5)
        assert_extmarks(bufnr, nsid, 1, "GitConflictAncestor", 6)
        assert_extmarks(bufnr, nsid, 0, "", 7)
        assert_extmarks(bufnr, nsid, 1, "GitConflictIncoming", 8)
        assert_extmarks(bufnr, nsid, 2, "GitConflictIncomingLabel", 9)
    end)
end)
