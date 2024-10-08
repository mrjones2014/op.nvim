vim.cmd([[
  set rtp+=.
  set rtp+=lua-vendor/nvim-treesitter
  set rtp+=lua-vendor/ts-vimdoc.nvim
  runtime plugin/nvim-treesitter.lua
]])

require('nvim-treesitter.configs').setup({ ---@diagnostic disable-line: missing-fields
  ensure_installed = {
    'markdown',
    'markdown_inline',
  },
})
