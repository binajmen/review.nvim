local M = {}

local ns = vim.api.nvim_create_namespace('review')

--- Find the buffer number for a given relative file path.
---@param file string
---@return integer?
local function find_buf(file)
  local cwd = vim.fn.getcwd()
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) then
      local name = vim.api.nvim_buf_get_name(bufnr)
      local rel = name
      if name:sub(1, #cwd) == cwd then
        rel = name:sub(#cwd + 2)
      end
      if rel == file then
        return bufnr
      end
    end
  end
end

--- Clear all review extmarks from all loaded buffers.
local function clear_all()
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) then
      vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
    end
  end
end

--- Refresh signs and virtual lines for all comments.
---@param comments ReviewComment[]
function M.refresh(comments)
  local cfg = require('review.config').values

  M._comments = comments

  clear_all()

  if not cfg.signs.enabled and not cfg.virtual_lines.enabled then
    return
  end

  for _, comment in ipairs(comments) do
    if comment.line_start and comment.line_end then
      local bufnr = find_buf(comment.file)
      if bufnr then
        if cfg.signs.enabled then
          for line = comment.line_start, comment.line_end do
            vim.api.nvim_buf_set_extmark(bufnr, ns, line - 1, 0, {
              sign_text = cfg.signs.text,
              sign_hl_group = cfg.signs.hl,
              priority = cfg.signs.priority,
            })
          end
        end

        if cfg.virtual_lines.enabled then
          local virt_lines = {}
          for vline in comment.comment:gmatch('[^\n]+') do
            table.insert(virt_lines, { { cfg.virtual_lines.prefix .. vline, cfg.virtual_lines.hl } })
          end
          vim.api.nvim_buf_set_extmark(bufnr, ns, comment.line_end - 1, 0, {
            virt_lines = virt_lines,
            virt_lines_above = false,
          })
        end
      end
    end
  end
end

--- Last known comments reference for BufEnter refresh.
---@type ReviewComment[]?
M._comments = nil

--- Setup BufEnter autocmd for lazy sign placement.
function M.setup_autocmd()
  vim.api.nvim_create_autocmd('BufEnter', {
    group = vim.api.nvim_create_augroup('ReviewSigns', { clear = true }),
    callback = function()
      if M._comments and #M._comments > 0 then
        M.refresh(M._comments)
      end
    end,
  })
end

M.setup_autocmd()

return M
