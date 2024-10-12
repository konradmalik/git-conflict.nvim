local gc = require("git-conflict")
local utils = require("test.utils")

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
                    ["content_end"] = 3,
                    ["content_start"] = 3,
                    ["range_end"] = 3,
                    ["range_start"] = 2,
                },
                ["current"] = {
                    ["content_end"] = 1,
                    ["content_start"] = 1,
                    ["range_end"] = 1,
                    ["range_start"] = 0,
                },
                ["incoming"] = {
                    ["content_end"] = 5,
                    ["content_start"] = 5,
                    ["range_end"] = 6,
                    ["range_start"] = 5,
                },
                ["middle"] = {
                    ["range_end"] = 5,
                    ["range_start"] = 4,
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
                ["bufnr"] = 3,
                ["col"] = 0,
                ["end_col"] = 0,
                ["end_lnum"] = 6,
                ["lnum"] = 0,
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
end)
