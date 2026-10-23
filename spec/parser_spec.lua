local parser = require("git-conflict.parser")

describe("parser", function()
    it("treats a second middle marker as incoming content", function()
        -- act
        local actual_positions = parser.detect_conflicts({
            "<<<<<<< HEAD",
            "current",
            "=======",
            "incoming",
            "=======",
            ">>>>>>> branch",
        })

        -- assert
        assert.are.same({
            {
                current = { range_start = 0, range_end = 1, content_start = 1, content_end = 1 },
                middle = { range_start = 2, range_end = 2 },
                incoming = { range_start = 3, range_end = 5, content_start = 3, content_end = 4 },
            },
        }, actual_positions)
    end)

    it("does not treat longer '=' lines as the middle marker", function()
        -- act
        local actual_positions = parser.detect_conflicts({
            "<<<<<<< HEAD",
            "title",
            "========",
            "=======",
            "incoming",
            ">>>>>>> branch",
        })

        -- assert
        assert.are.same({
            {
                current = { range_start = 0, range_end = 2, content_start = 1, content_end = 2 },
                middle = { range_start = 3, range_end = 3 },
                incoming = { range_start = 4, range_end = 5, content_start = 4, content_end = 4 },
            },
        }, actual_positions)
    end)

    it("treats an ancestor marker after the middle marker as incoming content", function()
        -- act
        local actual_positions = parser.detect_conflicts({
            "<<<<<<< HEAD",
            "current",
            "=======",
            "|||||||",
            ">>>>>>> branch",
        })

        -- assert
        assert.are.same({
            {
                current = { range_start = 0, range_end = 1, content_start = 1, content_end = 1 },
                middle = { range_start = 2, range_end = 2 },
                incoming = { range_start = 3, range_end = 4, content_start = 3, content_end = 3 },
            },
        }, actual_positions)
    end)
end)
