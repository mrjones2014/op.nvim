local M = {}

function M.is_plugin_binary_installed()
  local installed = vim.fn.filereadable(vim.g.op_nvim_bin_path) == 1
  if installed then
    vim.health.ok('op.nvim remote plugin binary is installed.')
  else
    vim.health.err(
      'op.nvim remote plugin binary is not installed',
      'Run the post-install hook `make install` from the plugin directory'
    )
  end
  return installed
end

function M.is_plugin_binary_executable()
  local executable = vim.fn.filereadable(vim.g.op_nvim_bin_path) == 1
  if executable then
    vim.health.ok('op.nvim remote plugin binary is executable.')
  else
    vim.health.err(
      'op.nvim remote plugin binary is not executable!',
      'Run the post-install hook `make install` from the plugin directory'
    )
  end
  return executable
end

function M.remote_plugin_running()
  if not vim.g.op_nvim_remote_loaded or vim.fn.OpSetup == nil then
    vim.health.err(
      'Remote plugin not running!',
      'Run the post-install hook `make install` from the plugin directory or reinstall plugin.'
    )
    return false
  else
    vim.health.ok('Remote plugin is running.')
    return true
  end
end

function M.is_able_to_auth()
  if require('op.config').get_config_immutable().biometric_unlock then
    vim.health.ok('Biometric unlock is enabled.')
    local api = require('op.api')
    local account_output = api.account.list({ '--format', 'json' })
    local accounts = vim.json.decode(table.concat(account_output, ''))
    if #accounts == 0 then
      vim.health.err('No accounts added to 1Password CLI!', 'Run `op signin` in a new shell.')
      return false
    end

    local _, stderr, exit_code = require('op.api').signin({ '--account', accounts[1].account_uuid })
    if exit_code == 0 then
      vim.health.ok('Able to sign in with biometric unlock')
      return true
    else
      vim.health.err('Unable to sign in with biometric unlock!', {
        table.concat(stderr, '\n'),
        "Make sure 'Connect with 1Password CLI' is enabled in 1Password desktop app developer settings.",
        'https://developer.1password.com/docs/cli/app-integration',
      })
      return false
    end
  end

  local _, _, exit_code = require('op.api').whoami()
  if exit_code ~= 0 then
    vim.health.err(
      'Biometric unlock is disabled, and op CLI cannot be authenticated from the environment!',
      'Run `eval $(op signin)` in your shell *before* launching Neovim.'
    )
    return false
  else
    return true
  end
end

M.check = function()
  vim.health.start('op.nvim')
  M.is_plugin_binary_installed()
  M.is_plugin_binary_executable()
  M.is_able_to_auth()
end

return M
