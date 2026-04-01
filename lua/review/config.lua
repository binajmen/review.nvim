---@class ReviewConfig
---@field float_width number Float width ratio for comment input (0-1, default 0.6)
---@field float_height integer Float height in lines for comment input (default 8)
---@field list_width number Float width ratio for list viewer (0-1, default 0.8)
---@field list_height_max number Max float height ratio for list viewer (0-1, default 0.8)
---@field keys ReviewKeys
---@field signs ReviewSigns
---@field virtual_lines ReviewVirtualLines
---
---@class ReviewKeys
---@field close string Key to close/cancel floats (default "q")
---@field edit string Key to edit a comment in the list viewer (default "e")
---@field delete string Key to delete a comment in the list viewer (default "d")
---
---@class ReviewSigns
---@field enabled boolean Show signs in the sign column (default true)
---@field text string Sign text, 1-2 characters (default "R")
---@field hl string Highlight group for the sign (default "DiagnosticInfo")
---@field priority integer Sign priority; lower than gitsigns (6) by default (default 5)
---
---@class ReviewVirtualLines
---@field enabled boolean Show comment text as virtual lines below code (default false)
---@field prefix string Prefix before comment text (default "💬 ")
---@field hl string Highlight group for virtual line text (default "DiagnosticInfo")

local M = {}

---@type ReviewConfig
local defaults = {
  float_width = 0.6,
  float_height = 8,
  list_width = 0.8,
  list_height_max = 0.8,
  keys = {
    close = 'q',
    edit = 'e',
    delete = 'd',
  },
  signs = {
    enabled = true,
    text = 'R',
    hl = 'DiagnosticInfo',
    priority = 5,
  },
  virtual_lines = {
    enabled = false,
    prefix = '💬 ',
    hl = 'DiagnosticInfo',
  },
}

---@type ReviewConfig
M.values = vim.deepcopy(defaults)

---@param opts? ReviewConfig
function M.setup(opts)
  M.values = vim.tbl_deep_extend('force', defaults, opts or {})

  vim.validate('float_width', M.values.float_width, 'number')
  vim.validate('float_height', M.values.float_height, 'number')
  vim.validate('list_width', M.values.list_width, 'number')
  vim.validate('list_height_max', M.values.list_height_max, 'number')
  vim.validate('keys', M.values.keys, 'table')
  vim.validate('keys.close', M.values.keys.close, 'string')
  vim.validate('keys.edit', M.values.keys.edit, 'string')
  vim.validate('keys.delete', M.values.keys.delete, 'string')
  vim.validate('signs', M.values.signs, 'table')
  vim.validate('signs.enabled', M.values.signs.enabled, 'boolean')
  vim.validate('signs.text', M.values.signs.text, 'string')
  vim.validate('signs.hl', M.values.signs.hl, 'string')
  vim.validate('signs.priority', M.values.signs.priority, 'number')
  vim.validate('virtual_lines', M.values.virtual_lines, 'table')
  vim.validate('virtual_lines.enabled', M.values.virtual_lines.enabled, 'boolean')
  vim.validate('virtual_lines.prefix', M.values.virtual_lines.prefix, 'string')
  vim.validate('virtual_lines.hl', M.values.virtual_lines.hl, 'string')
end

return M
