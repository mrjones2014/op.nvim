if vim.g.op_nvim_loaded == true then
  return
end

vim.g.op_nvim_loaded = true

vim.api.nvim_create_user_command('OpInsert', function()
  require('op.api').op_insert_reference()
end, { desc = 'Insert a 1Password item reference at the current cursor position' })

vim.api.nvim_create_user_command('OpCreate', function()
  require('op.api').op_create()
end, { desc = 'Create a new 1Password item from strings in the current buffer' })

vim.api.nvim_create_user_command('OpOpen', function()
  require('op.api').op_open()
end, { desc = 'Open an item in the 1Password 8 desktop app' })

vim.api.nvim_create_user_command('OpSwitchAccount', function()
  require('op.api').op_switch_account()
end, { desc = 'Open an item in the 1Password 8 desktop app' })
