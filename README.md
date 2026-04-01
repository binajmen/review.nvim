# review.nvim

Annotate code with review comments and export them as formatted markdown.

During code reviews, select lines, type a comment, and when you're done, yank
everything to the clipboard as a clean markdown document ready to paste into a
PR, issue, or chat.

## Features

- **Visual selection comments** — select lines, add a comment with the code snippet attached
- **File-level comments** — comment on a file without a specific selection
- **Floating list viewer** — browse, edit, and delete comments interactively
- **Sign column indicators** — marks commented lines in the gutter, coexists with gitsigns
- **Inline virtual lines** — optionally display comment text directly below the code
- **Markdown export** — yank all comments to clipboard as formatted markdown
- **Self-lazy-loading** — zero startup cost, no plugin manager configuration needed

## Requirements

- Neovim >= 0.9

## Installation

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  'your-username/review.nvim',
  opts = {},
  keys = {
    { '<leader>ra', '<Plug>(ReviewAdd)', mode = 'v', desc = 'Review: add comment on selection' },
    { '<leader>ra', '<Plug>(ReviewAdd)', mode = 'n', desc = 'Review: add file comment' },
    { '<leader>rl', '<Plug>(ReviewList)', desc = 'Review: list comments' },
    { '<leader>ry', '<Plug>(ReviewYank)', desc = 'Review: yank comments' },
    { '<leader>rc', '<Plug>(ReviewClear)', desc = 'Review: clear comments' },
  },
}
```

### [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  'your-username/review.nvim',
  config = function()
    require('review').setup()
  end,
}
```

### Manual

Clone the repo anywhere and add it to your runtimepath:

```lua
vim.opt.rtp:prepend('~/projects/review.nvim')
require('review').setup()
```

## Usage

### Commands

| Command                | Description                              |
| ---------------------- | ---------------------------------------- |
| `:Review add`          | Add a file-level comment                 |
| `:Review list`         | List all comments in a floating window   |
| `:Review yank`         | Yank all comments to clipboard           |
| `:Review clear`        | Clear all comments                       |
| `:Review delete {idx}` | Delete a specific comment by index       |

### `<Plug>` Mappings

| Mapping              | Mode   | Description                        |
| -------------------- | ------ | ---------------------------------- |
| `<Plug>(ReviewAdd)`  | Visual | Add comment on selected lines      |
| `<Plug>(ReviewAdd)`  | Normal | Add file-level comment             |
| `<Plug>(ReviewList)` | Normal | List all comments                  |
| `<Plug>(ReviewYank)` | Normal | Yank comments to clipboard         |
| `<Plug>(ReviewClear)`| Normal | Clear all comments                 |

## Configuration

All options are optional. These are the defaults:

```lua
require('review').setup({
  float_width = 0.6,       -- Comment input float width (0-1)
  float_height = 8,        -- Comment input float height (lines)
  list_width = 0.8,        -- List viewer float width (0-1)
  list_height_max = 0.8,   -- List viewer max height (0-1)
  keys = {
    close = 'q',           -- Close/cancel key in floats
    edit = 'e',            -- Edit key in list viewer
    delete = 'd',          -- Delete key in list viewer
  },
  signs = {
    enabled = true,        -- Show signs in the sign column
    text = 'R',            -- Sign text (1-2 characters)
    hl = 'DiagnosticInfo', -- Highlight group for the sign
    priority = 5,          -- Sign priority (gitsigns uses 6)
  },
  virtual_lines = {
    enabled = false,       -- Show comment text as virtual lines
    prefix = '💬 ',        -- Prefix before each comment line
    hl = 'DiagnosticInfo', -- Highlight group for virtual lines
  },
})
```

## License

MIT
