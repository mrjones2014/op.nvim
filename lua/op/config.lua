local M = {
  op_cli_path = 'op',
  global_args = {
    '--cache',
    '--no-color',
  },
}

function M.setup(user_config)
  user_config = user_config or {}
  M.op_cli_path = user_config.op_cli_path or M.op_cli_path
  M.global_args = user_config.global_args or M.global_args
end

return M
