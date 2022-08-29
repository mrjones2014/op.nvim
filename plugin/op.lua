if vim.g.op_nvim_loaded == true then
  return
end

--luacheck:ignore
vim.g.op_nvim_loaded = true

vim.api.nvim_create_user_command('OpInsert', function()
  require('op').op_insert_reference()
end, { desc = 'Insert a 1Password item reference at the current cursor position' })

vim.api.nvim_create_user_command('OpCreate', function()
  require('op').op_create()
end, { desc = 'Create a new 1Password item from strings in the current buffer' })

vim.api.nvim_create_user_command('OpOpen', function()
  require('op').op_open()
end, { desc = 'Open an item in the 1Password 8 desktop app' })

vim.api.nvim_create_user_command('OpSignin', function(input)
  local account_identifier = input and input.fargs and input.fargs[1] or nil
  require('op').op_signin(account_identifier)
end, { desc = 'Choose a 1Password account to sign in with', nargs = '?' })

vim.api.nvim_create_user_command('OpSignout', function()
  require('op').op_signout()
end, { desc = 'Sign out of 1Password CLI' })

vim.api.nvim_create_user_command('OpWhoami', function()
  require('op').op_whoami()
end, { desc = 'Check what 1Password account you are currently signed in with' })

vim.api.nvim_create_user_command('OpNote', function(args)
  if args and args.fargs and (args.fargs[1] == 'new' or args.fargs[1] == 'create') then
    require('op.securenotes').new_secure_note()
  else
    require('op.securenotes').open_secure_note()
  end
end, { desc = 'Find and open a 1Password Secure Note', nargs = '?' })

vim.api.nvim_create_user_command('OpNoteSync', function()
  require('op.securenotes').load_note_changes()
end, { desc = 'Sync Secure Note changes from 1Password into the buffer' })
