local search = require("git-conflict.search")

describe("search", function()
    it("splits git grep output on the first line number", function()
        -- act
        local actual_items = search.to_qf_items({ "dir/file.lua:3:<<<<<<< a:12:b" }, "/repo")

        -- assert
        assert.are.same({
            {
                filename = "/repo/dir/file.lua",
                lnum = 3,
                text = "Conflict marker",
                type = "E",
            },
        }, actual_items)
    end)
end)
