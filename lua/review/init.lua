local M = {}

---@class ReviewComment
---@field file string
---@field line_start? integer
---@field line_end? integer
---@field snippet? string
---@field comment string

---@type ReviewComment[]
M.comments = {}

--- Get the relative file path (relative to cwd), or absolute if outside.
---@param bufnr? integer
---@return string
local function rel_path(bufnr)
  local full = vim.api.nvim_buf_get_name(bufnr or 0)
  local cwd = vim.fn.getcwd()
  if full:sub(1, #cwd) == cwd then
    return full:sub(#cwd + 2) -- strip cwd + trailing slash
  end
  return full
end

--- Configure the plugin. Can be called before or after `plugin/review.lua` runs.
---@param opts? ReviewConfig
function M.setup(opts)
  require('review.config').setup(opts)
end

--- Add a comment for the current visual selection.
function M.add_comment()
  local line_start = vim.fn.line("'<")
  local line_end = vim.fn.line("'>")
  local bufnr = vim.api.nvim_get_current_buf()
  local file = rel_path(bufnr)
  local snippet_lines = vim.api.nvim_buf_get_lines(bufnr, line_start - 1, line_end, false)
  local snippet = table.concat(snippet_lines, '\n')

  require('review.ui').open_comment_float(function(comment_text)
    table.insert(M.comments, {
      file = file,
      line_start = line_start,
      line_end = line_end,
      snippet = snippet,
      comment = comment_text,
    })
    require('review.signs').refresh(M.comments)
    vim.notify(string.format('Review: comment #%d added (%s:%d-%d)', #M.comments, file, line_start, line_end), vim.log.levels.INFO)
  end)
end

--- Add a file-level comment (no snippet).
function M.add_file_comment()
  local file = rel_path()

  require('review.ui').open_comment_float(function(comment_text)
    table.insert(M.comments, {
      file = file,
      comment = comment_text,
    })
    require('review.signs').refresh(M.comments)
    vim.notify(string.format('Review: comment #%d added (%s)', #M.comments, file), vim.log.levels.INFO)
  end)
end

--- Show all comments in a floating window with edit/delete keymaps.
---@param jump_to_idx? integer
function M.list_comments(jump_to_idx)
  if #M.comments == 0 then
    vim.notify('Review: no comments yet.', vim.log.levels.INFO)
    return
  end

  require('review.ui').list_comments(M.comments, {
    on_delete = function(idx)
      table.remove(M.comments, idx)
      require('review.signs').refresh(M.comments)
    end,
    on_edit = function(idx, new_text)
      M.comments[idx].comment = new_text
      require('review.signs').refresh(M.comments)
    end,
    on_reopen = function(idx)
      M.list_comments(idx)
    end,
  }, jump_to_idx)
end

--- Format all comments into a markdown string.
---@return string
function M.format_comments()
  return require('review.format').format_comments(M.comments)
end

--- Yank all comments to the system clipboard.
function M.yank_comments()
  if #M.comments == 0 then
    vim.notify('Review: no comments to yank.', vim.log.levels.WARN)
    return
  end

  local text = M.format_comments()
  vim.fn.setreg('+', text)
  vim.notify(string.format('Review: %d comment(s) yanked to clipboard.', #M.comments), vim.log.levels.INFO)
end

--- Clear all comments.
function M.clear_comments()
  local count = #M.comments
  M.comments = {}
  require('review.signs').refresh(M.comments)
  vim.notify(string.format('Review: cleared %d comment(s).', count), vim.log.levels.INFO)
end

--- Delete a specific comment by index.
---@param index integer
function M.delete_comment(index)
  if index < 1 or index > #M.comments then
    vim.notify('Review: invalid comment index.', vim.log.levels.ERROR)
    return
  end
  table.remove(M.comments, index)
  require('review.signs').refresh(M.comments)
  vim.notify(string.format('Review: deleted comment #%d.', index), vim.log.levels.INFO)
end

--- Subcommands for :Review
---@type table<string, fun(args: string?)>
local subcommands = {
  add = function()
    M.add_file_comment()
  end,
  list = function()
    M.list_comments()
  end,
  yank = function()
    M.yank_comments()
  end,
  clear = function()
    M.clear_comments()
  end,
  delete = function(args)
    local idx = tonumber(args)
    if not idx then
      vim.notify('Review: delete requires a comment number.', vim.log.levels.ERROR)
      return
    end
    M.delete_comment(idx)
  end,
}

local subcommand_names = vim.tbl_keys(subcommands)
table.sort(subcommand_names)

--- Handle the :Review user command.
---@param opts table
function M.command(opts)
  local parts = vim.split(vim.fn.trim(opts.args), '%s+')
  local sub = parts[1]
  local rest = parts[2]
  if sub and subcommands[sub] then
    subcommands[sub](rest)
  else
    vim.notify(
      'Review: unknown subcommand "' .. (sub or '') .. '". Available: ' .. table.concat(subcommand_names, ', '),
      vim.log.levels.ERROR
    )
  end
end

--- Complete :Review subcommands.
---@param arg_lead string
---@param cmd_line string
---@return string[]
function M.complete(arg_lead, cmd_line)
  local parts = vim.split(vim.fn.trim(cmd_line), '%s+')
  if #parts <= 2 then
    return vim.tbl_filter(function(s)
      return s:find(arg_lead, 1, true) == 1
    end, subcommand_names)
  end
  return {}
end

return M
