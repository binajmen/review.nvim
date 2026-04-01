if vim.g.loaded_review then
  return
end
vim.g.loaded_review = true

vim.api.nvim_create_user_command('Review', function(opts)
  require('review').command(opts)
end, {
  nargs = '+',
  complete = function(arg_lead, cmd_line)
    return require('review').complete(arg_lead, cmd_line)
  end,
  desc = 'Review comments management',
})

vim.keymap.set('v', '<Plug>(ReviewAdd)', function()
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'x', false)
  require('review').add_comment()
end, { desc = 'Review: add comment on selection', silent = true })

vim.keymap.set('n', '<Plug>(ReviewAdd)', function()
  require('review').add_file_comment()
end, { desc = 'Review: add file comment' })

vim.keymap.set('n', '<Plug>(ReviewList)', function()
  require('review').list_comments()
end, { desc = 'Review: list comments' })

vim.keymap.set('n', '<Plug>(ReviewYank)', function()
  require('review').yank_comments()
end, { desc = 'Review: yank comments' })

vim.keymap.set('n', '<Plug>(ReviewClear)', function()
  require('review').clear_comments()
end, { desc = 'Review: clear comments' })
