vim.api.nvim_create_user_command('OpInsert', function()
  require('op.api').op_insert_reference()
end, { desc = 'Insert a 1Password item reference at the current cursor position' })
