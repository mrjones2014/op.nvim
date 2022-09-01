local M = {}

local config = {
  op_cli_path = 'op',
  biometric_unlock = true,
  signin_on_start = false,
  use_icons = true,
  global_args = {
    '--cache',
    '--no-color',
  },
  secure_notes = {
    buf_name_prefix = '1P:',
  },
}

local function handle_setup()
  if config.signin_on_start == true then
    require('op').op_signin()
  end

  -- only update in remote plugin if not default
  if config.op_cli_path ~= 'op' then
    vim.fn.OpSetup(config.op_cli_path)
  end
end

function M.setup(user_config)
  user_config = user_config or {}
  config = vim.tbl_extend('force', config, user_config)

  if vim.g.op_nvim_remote_loaded then
    handle_setup()
  else
    vim.api.nvim_create_autocmd('User', {
      group = vim.api.nvim_create_augroup('OpNvimInit', { clear = true }),
      pattern = 'OpNvimRemoteLoaded',
      callback = handle_setup,
    })
  end
end

function M.get_global_args()
  return vim.deepcopy(config.global_args or {})
end

function M.get_config_immutable()
  return vim.deepcopy(config)
end

return M
