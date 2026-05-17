local markers = require("git-conflict.markers")

--- @class ConflictPosition
--- @field incoming Range
--- @field middle Range
--- @field current Range
--- @field ancestor Range?

--- @class Range
--- @field range_start integer
--- @field range_end integer
--- @field content_start integer
--- @field content_end integer

---@param section Range
---@param lnum integer line number BEFORE the marker that ends this section
local function finish_range(section, lnum)
    section.range_end = lnum - 1
    section.content_end = lnum - 1
end

---Iterate through the buffer line by line checking there is a matching conflict marker
---when we find a starting mark we collect the position details and add it to a list of positions
---@param lines string[]
---@return ConflictPosition[]
local function detect_conflicts(lines)
    local positions = {}
    local position, has_start, has_middle, has_ancestor = nil, false, false, false
    for index, line in ipairs(lines) do
        local lnum = index - 1
        if line:match(markers.conflict_start) then
            has_start, has_middle, has_ancestor = true, false, false
            position = {
                current = { range_start = lnum, content_start = lnum + 1 },
                middle = nil,
                incoming = nil,
                ancestor = nil,
            }
        end
        if has_start and line:match(markers.conflict_ancestor) then
            assert(position, "position was nil")
            has_ancestor = true
            position.ancestor = { range_start = lnum, content_start = lnum + 1 }
            finish_range(position.current, lnum)
        end
        if has_start and line:match(markers.conflict_middle) then
            assert(position, "position was nil")
            has_middle = true
            finish_range(has_ancestor and position.ancestor or position.current, lnum)
            position.middle = { range_start = lnum, range_end = lnum + 1 }
            position.incoming = { range_start = lnum + 1, content_start = lnum + 1 }
        end
        if has_start and has_middle and line:match(markers.conflict_end) then
            assert(position, "position was nil")
            position.incoming.range_end = lnum
            position.incoming.content_end = lnum - 1
            positions[#positions + 1] = position
            position, has_start, has_middle, has_ancestor = nil, false, false, false
        end
    end
    return positions
end

---@param bufnr integer
---@return boolean
local function buf_can_have_conflicts(bufnr)
    return vim.api.nvim_buf_call(
        bufnr,
        function() return vim.fn.search(markers.conflict_start, "cnw", nil, 500) end
    ) > 0
end

return {
    detect_conflicts = detect_conflicts,
    buf_can_have_conflicts = buf_can_have_conflicts,
}
