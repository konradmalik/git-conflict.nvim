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
                    ["range_end"] = 7,
                    ["range_start"] = 7,
                },
            },
        }, actual_positons)
    end)

    it("populates diagnostics after refresh", function()
        -- act
        gc.refresh(bufnr)

        -- assert
        local nsid = vim.api.nvim_get_namespaces()["git-conflict"]
        local actual_diagnostics = vim.diagnostic.get(bufnr)
        for _, d in ipairs(actual_diagnostics) do
            d._extmark_id = nil
        end
        assert.are.same({
            {
                ["bufnr"] = bufnr,
                ["col"] = 0,
                ["end_col"] = 0,
                ["end_lnum"] = 9,
                ["lnum"] = 3,
                ["message"] = "Git conflict",
                ["namespace"] = nsid,
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

    it("does clear positions", function()
        -- act
        gc.refresh(bufnr)
        gc.clear(bufnr)

        -- assert
        assert.is_nil(gc.positions(bufnr))
    end)

    it("returns positions for the current buffer when given 0", function()
        -- arrange
        vim.api.nvim_set_current_buf(bufnr)

        -- act
        gc.refresh(bufnr)

        -- assert
        assert.are.same(gc.positions(bufnr), gc.positions(0))
        assert.is_not_nil(gc.positions(0))
    end)

    it("publishes GitConflict event after decorating the buffer", function()
        -- arrange
        local nsid = vim.api.nvim_get_namespaces()["git-conflict"]
        local extmarks_at_event
        local autocmd = vim.api.nvim_create_autocmd("User", {
            pattern = "GitConflict",
            callback = function()
                extmarks_at_event = #vim.api.nvim_buf_get_extmarks(bufnr, nsid, 0, -1, {})
            end,
        })
        finally(function() vim.api.nvim_del_autocmd(autocmd) end)

        -- act
        gc.refresh(bufnr)

        -- assert
        assert.are.same(6, extmarks_at_event)
    end)

    it("forgets positions when the buffer is wiped out", function()
        -- arrange
        dofile("plugin/git-conflict.lua")
        finally(function() vim.api.nvim_del_augroup_by_name("GitConflict") end)
        gc.refresh(bufnr)

        -- act
        vim.api.nvim_buf_delete(bufnr, { force = true })

        -- assert
        assert.is_nil(gc.positions(bufnr))
    end)

    it("applies extmarks within namespace", function()
        -- arrange
        local nsid = vim.api.nvim_get_namespaces()["git-conflict"]

        -- act
        gc.refresh(bufnr)

        -- assert
        assert_extmarks(bufnr, nsid, 1, "GitConflictCurrentLabel", 3)
        assert_extmarks(bufnr, nsid, 1, "GitConflictCurrent", 4)
        assert_extmarks(bufnr, nsid, 1, "GitConflictAncestorLabel", 5)
        assert_extmarks(bufnr, nsid, 1, "GitConflictAncestor", 6)
        assert_extmarks(bufnr, nsid, 0, "", 7)
        assert_extmarks(bufnr, nsid, 1, "GitConflictIncoming", 8)
        assert_extmarks(bufnr, nsid, 1, "GitConflictIncomingLabel", 9)
    end)
end)

describe("setup", function()
    after_each(function() gc.setup({ highlights = { current = "DiffText" } }) end)

    it("overrides already defined highlights", function()
        -- arrange
        gc.set_highlights()

        -- act
        gc.setup({ highlights = { current = "Search" } })

        -- assert
        local expected_bg = vim.api.nvim_get_hl(0, { name = "Search" }).bg
        assert.are.same(expected_bg, vim.api.nvim_get_hl(0, { name = "GitConflictCurrent" }).bg)
    end)
end)
