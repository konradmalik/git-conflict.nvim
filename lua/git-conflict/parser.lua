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
---@param offset integer? 0-based line number of the first line, defaults to 0
---@return ConflictPosition[]
local function detect_conflicts(lines, offset)
    offset = offset or 0
    local positions = {}
    local position
    for index, line in ipairs(lines) do
        local lnum = offset + index - 1
        if line:match(markers.conflict_start) then
            position = { current = { range_start = lnum, content_start = lnum + 1 } }
        elseif position and not position.middle then
            if line:match(markers.conflict_ancestor) then
                finish_range(position.current, lnum)
                position.ancestor = { range_start = lnum, content_start = lnum + 1 }
            elseif line:match(markers.conflict_middle) then
                finish_range(position.ancestor or position.current, lnum)
                position.middle = { range_start = lnum, range_end = lnum }
                position.incoming = { range_start = lnum + 1, content_start = lnum + 1 }
            end
        elseif position and line:match(markers.conflict_end) then
            position.incoming.range_end = lnum
            position.incoming.content_end = lnum - 1
            positions[#positions + 1] = position
            position = nil
        end
    end
    return positions
end

---@param bufnr integer loaded buffer
---@return ConflictPosition[]
local function buf_detect_conflicts(bufnr)
    -- finding the start marker in C is much cheaper than parsing every line in lua,
    -- so most buffers (without conflicts) never get their lines copied
    local starts = vim.fn.matchbufline(bufnr, markers.conflict_start, 1, "$")
    if #starts == 0 then return {} end
    -- matchbufline lines are 1-based
    local offset = starts[1].lnum - 1
    return detect_conflicts(vim.api.nvim_buf_get_lines(bufnr, offset, -1, false), offset)
end

return {
    detect_conflicts = detect_conflicts,
    buf_detect_conflicts = buf_detect_conflicts,
}
