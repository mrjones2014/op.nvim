local M = {
  op_cli_path = 'op',
  account_uuid = nil,
  global_args = {
    '--cache',
    '--no-color',
  },
}

function M.setup(user_config)
  user_config = user_config or {}
  M.op_cli_path = user_config.op_cli_path or M.op_cli_path
  M.account_uuid = user_config.account_uuid or M.account_uuid
  M.global_args = user_config.global_args or M.global_args
end

function M.get_global_args()
  local args = vim.deepcopy(M.global_args or {})
  if M.account_uuid then
    table.insert(args, '--account')
    table.insert(M.account_uuid)
  end
end

return M
