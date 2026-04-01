local M = {}

--- Build formatted lines and a mapping from line numbers to comment indices.
---@param comments ReviewComment[]
---@return string[] lines
---@return table<integer, integer> line_to_comment
function M.build_list_lines(comments)
  local all_lines = {}
  local line_to_comment = {}

  for i, c in ipairs(comments) do
    local block
    if c.snippet then
      local ext = c.file:match '%.(%w+)$' or ''
      local line_label
      if c.line_start == c.line_end then
        line_label = string.format('line %d', c.line_start)
      else
        line_label = string.format('lines %d-%d', c.line_start, c.line_end)
      end
      block = string.format('## %d. %s (%s)\n```%s\n%s\n```\n**Comment:** %s', i, c.file, line_label, ext, c.snippet, c.comment)
    else
      block = string.format('## %d. %s\n**Comment:** %s', i, c.file, c.comment)
    end
    local block_lines = vim.split(block, '\n')

    if i > 1 then
      -- blank line before --- so markdown renders it as a rule, not a setext heading
      table.insert(all_lines, '')
      table.insert(all_lines, '---')
      table.insert(all_lines, '')
      line_to_comment[#all_lines - 2] = i
      line_to_comment[#all_lines - 1] = i
      line_to_comment[#all_lines] = i
    end

    local start = #all_lines + 1
    for _, l in ipairs(block_lines) do
      table.insert(all_lines, l)
    end
    for ln = start, #all_lines do
      line_to_comment[ln] = i
    end
  end

  return all_lines, line_to_comment
end

--- Format comments into a markdown string.
---@param comments ReviewComment[]
---@return string
function M.format_comments(comments)
  if #comments == 0 then
    return ''
  end
  local lines = M.build_list_lines(comments)
  return table.concat(lines, '\n')
end

return M
