local M = {}

local op_account_name = nil
local initialized = false

function M.update(account_name)
  op_account_name = account_name
end

function M.component()
  if not initialized then
    vim.fn.OpEnableStatusline()
    initialized = true
  end

  local fmt = require('op.config').get_config_immutable().statusline_fmt
  if type(fmt) ~= 'function' then
    fmt = function(account_name)
      if not account_name or #account_name == 0 then
        return ' 1Password: No active session'
      end

      return string.format(' 1Password: %s', account_name)
    end
  end

  return fmt(op_account_name)
end

return M
