local M = {}

local config = {
  op_cli_path = 'op',
  global_args = {
    '--cache',
    '--no-color',
  },
}

function M.setup(user_config)
  user_config = user_config or {}
  config.op_cli_path = user_config.op_cli_path or config.op_cli_path
  config.global_args = user_config.global_args or config.global_args

  -- only update in remote plugin if not default
  if M.op_cli_path ~= 'op' then
    vim.fn.OpSetup(M.op_cli_path)
  end
end

function M.get_global_args()
  return vim.deepcopy(config.global_args or {})
end

return M
