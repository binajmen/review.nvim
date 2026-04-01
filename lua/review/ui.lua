local config = require('review.config')
local format = require('review.format')

local M = {}

--- Open a small floating window for typing a comment.
--- Calls `on_done(text)` with the trimmed content when the user saves (:w or :wq).
---@param on_done fun(text: string)
---@param initial_text? string
function M.open_comment_float(on_done, initial_text)
  local cfg = config.values

  -- Clean up any leftover buffer from a previous comment
  local existing = vim.fn.bufnr('review://comment')
  if existing ~= -1 then
    vim.api.nvim_buf_delete(existing, { force = true })
  end

  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].buftype = 'acwrite'
  vim.bo[buf].filetype = 'markdown'
  vim.api.nvim_buf_set_name(buf, 'review://comment')

  local width = math.floor(vim.o.columns * cfg.float_width)
  local height = cfg.float_height
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = width,
    height = height,
    row = row,
    col = col,
    style = 'minimal',
    border = 'rounded',
    title = ' Review Comment (save to confirm, :q to cancel) ',
    title_pos = 'center',
  })

  if initial_text then
    local init_lines = vim.split(initial_text, '\n')
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, init_lines)
  end

  vim.cmd('startinsert')

  -- Handle BufWriteCmd (since buftype=acwrite, :w triggers this instead of disk write)
  vim.api.nvim_create_autocmd('BufWriteCmd', {
    buffer = buf,
    once = true,
    callback = function()
      local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      local text = vim.fn.trim(table.concat(lines, '\n'))
      vim.api.nvim_win_close(win, true)
      vim.api.nvim_buf_delete(buf, { force = true })
      if text ~= '' then
        on_done(text)
      else
        vim.notify('Review: empty comment, skipped.', vim.log.levels.WARN)
      end
    end,
  })

  -- Allow close key to cancel
  vim.keymap.set('n', cfg.keys.close, function()
    vim.api.nvim_win_close(win, true)
    vim.api.nvim_buf_delete(buf, { force = true })
    vim.notify('Review: comment cancelled.', vim.log.levels.INFO)
  end, { buffer = buf, nowait = true })
end

--- Show all comments in a floating window with edit/delete keymaps.
---@param comments ReviewComment[]
---@param callbacks { on_delete: fun(idx: integer), on_edit: fun(idx: integer, new_text: string), on_reopen: fun(idx: integer) }
---@param jump_to_idx? integer
function M.list_comments(comments, callbacks, jump_to_idx)
  local cfg = config.values

  local lines, line_to_comment = format.build_list_lines(comments)

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].filetype = 'markdown'
  vim.bo[buf].modifiable = false

  local width = math.floor(vim.o.columns * cfg.list_width)
  local height = math.min(#lines + 2, math.floor(vim.o.lines * cfg.list_height_max))
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = width,
    height = height,
    row = row,
    col = col,
    style = 'minimal',
    border = 'rounded',
    title = string.format(
      ' Review Comments (%s=edit, %s=delete, %s=close) ',
      cfg.keys.edit, cfg.keys.delete, cfg.keys.close
    ),
    title_pos = 'center',
  })

  local function close()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
    if vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_delete(buf, { force = true })
    end
  end

  local function refresh()
    if #comments == 0 then
      close()
      vim.notify('Review: no comments left.', vim.log.levels.INFO)
      return
    end
    lines, line_to_comment = format.build_list_lines(comments)
    vim.bo[buf].modifiable = true
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].modifiable = false
    local new_height = math.min(#lines + 2, math.floor(vim.o.lines * cfg.list_height_max))
    vim.api.nvim_win_set_height(win, new_height)
  end

  -- Jump to the requested comment's heading line
  if jump_to_idx then
    local heading = string.format('## %d.', jump_to_idx)
    for ln, line_text in ipairs(lines) do
      if line_text:find(heading, 1, true) then
        vim.api.nvim_win_set_cursor(win, { ln, 0 })
        break
      end
    end
  end

  vim.keymap.set('n', cfg.keys.close, close, { buffer = buf, nowait = true })

  vim.keymap.set('n', cfg.keys.delete, function()
    local cursor_line = vim.api.nvim_win_get_cursor(win)[1]
    local idx = line_to_comment[cursor_line]
    if not idx then
      return
    end
    callbacks.on_delete(idx)
    vim.notify(string.format('Review: deleted comment #%d.', idx), vim.log.levels.INFO)
    refresh()
  end, { buffer = buf, nowait = true })

  vim.keymap.set('n', cfg.keys.edit, function()
    local cursor_line = vim.api.nvim_win_get_cursor(win)[1]
    local idx = line_to_comment[cursor_line]
    if not idx then
      return
    end
    close()
    M.open_comment_float(function(new_text)
      callbacks.on_edit(idx, new_text)
      vim.notify(string.format('Review: updated comment #%d.', idx), vim.log.levels.INFO)
      vim.schedule(function()
        callbacks.on_reopen(idx)
      end)
    end, comments[idx].comment)
  end, { buffer = buf, nowait = true })
end

return M
