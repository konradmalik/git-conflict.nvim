local cmds = require("git-conflict.commands")
local gc = require("git-conflict")
local utils = require("test.utils")

---@param bufnr integer
local function assert_cleared_highlights(bufnr)
    local nsid = vim.api.nvim_get_namespaces()["git-conflict"]
    local exts = vim.api.nvim_buf_get_extmarks(bufnr, nsid, { 4, 0 }, { 4, 0 }, {})
    assert.are.same(0, #exts)
end

---@param bufnr integer
local function assert_cleared_diagnostics(bufnr) assert.are.same({}, vim.diagnostic.get(bufnr)) end

describe("in buffer with conflicts", function()
    local winnr
    local bufnr
    before_each(function()
        bufnr = utils.create_buf_with_conflict()
        winnr = utils.create_win_with_bufnr(bufnr)
        gc.refresh(bufnr)
    end)
    after_each(function()
        vim.api.nvim_win_close(winnr, true)
        utils.close_buffers_except_initial()
    end)

    it("chooses current version", function()
        -- arrange
        utils.move_cursor_to_conflict(winnr)

        -- act
        cmds.buf_conflict_choose_current(bufnr)

        -- assert
        local actual_content = utils.get_buf_lines(bufnr)
        assert.are.same({
            "the conflict",
            "is below",
            "",
            "current",
            "",
        }, actual_content)
        assert_cleared_diagnostics(bufnr)
        assert_cleared_highlights(bufnr)
    end)

    it("chooses incoming option", function()
        -- arrange
        utils.move_cursor_to_conflict(winnr)

        -- act
        cmds.buf_conflict_choose_incoming(bufnr)

        -- assert
        local actual_content = utils.get_buf_lines(bufnr)
        assert.are.same({
            "the conflict",
            "is below",
            "",
            "incoming",
            "",
        }, actual_content)
        assert_cleared_diagnostics(bufnr)
        assert_cleared_highlights(bufnr)
    end)

    it("chooses both options", function()
        -- arrange
        utils.move_cursor_to_conflict(winnr)

        -- act
        cmds.buf_conflict_choose_both(bufnr)

        -- assert
        local actual_content = utils.get_buf_lines(bufnr)
        assert.are.same({
            "the conflict",
            "is below",
            "",
            "current",
            "incoming",
            "",
        }, actual_content)
        assert_cleared_diagnostics(bufnr)
        assert_cleared_highlights(bufnr)
    end)

    it("chooses no options", function()
        -- arrange
        utils.move_cursor_to_conflict(winnr)

        -- act
        cmds.buf_conflict_choose_none(bufnr)

        -- assert
        local actual_content = utils.get_buf_lines(bufnr)
        assert.are.same({
            "the conflict",
            "is below",
            "",
            "",
        }, actual_content)
        assert_cleared_diagnostics(bufnr)
        assert_cleared_highlights(bufnr)
    end)

    it("chooses current version after unsaved edits above the conflict", function()
        -- arrange
        vim.api.nvim_buf_set_lines(bufnr, 0, 0, true, { "added line" })
        vim.api.nvim_win_set_cursor(winnr, { 6, 2 })

        -- act
        cmds.buf_conflict_choose_current(bufnr)

        -- assert
        local actual_content = utils.get_buf_lines(bufnr)
        assert.are.same({
            "added line",
            "the conflict",
            "is below",
            "",
            "current",
            "",
        }, actual_content)
        assert_cleared_diagnostics(bufnr)
    end)

    it("does not publish GitConflict event when resolving the last conflict", function()
        -- arrange
        utils.move_cursor_to_conflict(winnr)
        local events = 0
        local autocmd = vim.api.nvim_create_autocmd("User", {
            pattern = "GitConflict",
            callback = function() events = events + 1 end,
        })
        finally(function() vim.api.nvim_del_autocmd(autocmd) end)

        -- act
        cmds.buf_conflict_choose_current(bufnr)

        -- assert
        assert.are.same(0, events)
    end)

    it("moves to prev conflict", function()
        -- arrange
        utils.move_cursor_to_conflict(winnr)

        -- act
        cmds.buf_prev_conflict()

        -- assert
        local actual_position = vim.api.nvim_win_get_cursor(winnr)
        assert.are.same({ 4, 0 }, actual_position)
    end)

    it("moves to next conflict", function()
        -- act
        cmds.buf_next_conflict()

        -- assert
        local actual_position = vim.api.nvim_win_get_cursor(winnr)
        assert.are.same({ 4, 0 }, actual_position)
    end)
end)
