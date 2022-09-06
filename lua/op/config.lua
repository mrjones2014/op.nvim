local M = {}

local config = {
  op_cli_path = 'op',
  biometric_unlock = true,
  signin_on_start = false,
  use_icons = true,
  url_open_command = function()
    if vim.fn.has('mac') == 1 then
      return 'open'
    elseif vim.fn.has('unix') == 1 then
      return 'xdg-open'
    end
    return nil
  end,
  sidebar = {
    'favorites',
    'secure_notes',
    width = 30,
    side = 'right',
    mappings = {
      ['<CR>'] = 'default_open',
      ['go'] = 'open_in_desktop_app',
      ['ge'] = 'edit_in_desktop_app',
    },
  },
  statusline_fmt = function(account_name)
    if not account_name or #account_name == 0 then
      return ' 1Password: No active session'
    end

    return string.format(' 1Password: %s', account_name)
  end,
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
  config = vim.tbl_deep_extend('force', config, user_config)

  if require('op.state').remote_plugin_loaded then
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
