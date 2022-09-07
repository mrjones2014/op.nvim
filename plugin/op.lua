local state = require('op.state')
if state.commands_initialized == true then
  return
end

state.commands_initialized = true

vim.api.nvim_create_user_command('OpInsert', function()
  require('op').op_insert()
end, { desc = 'Insert a 1Password item reference at the current cursor position' })

vim.api.nvim_create_user_command('OpCreate', function()
  require('op').op_create()
end, { desc = 'Create a new 1Password item from strings in the current buffer' })

vim.api.nvim_create_user_command('OpView', function()
  require('op').op_view_item()
end, { desc = 'Open an item in the 1Password 8 desktop app' })

vim.api.nvim_create_user_command('OpEdit', function()
  require('op').op_edit_item()
end, { desc = 'Open an item to the edit view in the 1Password 8 desktop app' })

vim.api.nvim_create_user_command('OpOpen', function()
  require('op').op_open_and_fill()
end, { desc = 'Open and fill an item in your default browser' })

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
  require('op').op_note(args and args.fargs and (args.fargs[1] == 'new' or args.fargs[1] == 'create'))
end, { desc = 'Find and open a 1Password Secure Note', nargs = '?' })

vim.api.nvim_create_user_command('OpSidebar', function(input)
  local should_refresh = false
  if input and input.fargs and input.fargs[1] == 'refresh' then
    should_refresh = true
  end
  require('op').op_sidebar(should_refresh)
end, { desc = 'Toggle the 1Password sidebar', nargs = '?' })
