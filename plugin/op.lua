local state = require('op.state')
if state.commands_initialized == true then
  return
end

state.commands_initialized = true

vim.tbl_map(function(cmd)
  vim.api.nvim_create_user_command(cmd[1], cmd[2], cmd[3])
end, require('op.commands'))
