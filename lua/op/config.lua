local M = {}

local config = {
  op_cli_path = 'op',
  global_args = {
    '--cache',
    '--no-color',
  },
  update_statusline_on_start = false,
}

function M.setup(user_config)
  user_config = user_config or {}
  config = vim.tbl_extend('force', config, user_config)

  -- only update in remote plugin if not default
  if M.op_cli_path ~= 'op' then
    vim.fn.OpSetup(M.op_cli_path)
  end
end

function M.get_global_args()
  return vim.deepcopy(config.global_args or {})
end

function M.get_config_immutable()
  return vim.deepcopy(config)
end

return M
