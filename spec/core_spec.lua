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
end)
