local gc = require("git-conflict")

---@return integer
local function create_buf_with_conflict()
    local bufnr = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_buf_set_lines(bufnr, 0, 0, false, {
        "<<<<<<<",
        "current",
        "|||||||",
        "ancestor",
        "=======",
        "incoming",
        ">>>>>>>",
    })
    return bufnr
end

describe("in buffer with conflicts", function()
    it("populates positions after refresh", function()
        -- arrange
        local bufnr = create_buf_with_conflict()

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
end)
