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

vim.api.nvim_create_user_command('OpSignin', function()
  require('op.api').op_signin()
end, { desc = 'Choose a 1Password account to sign in with' })

vim.api.nvim_create_user_command('OpSignout', function()
  require('op.api').op_signout()
end, { desc = 'Sign out of 1Password CLI' })

vim.api.nvim_create_user_command('OpWhoami', function()
  require('op.api').op_whoami()
end, { desc = 'Check what 1Password account you are currently signed in with' })
