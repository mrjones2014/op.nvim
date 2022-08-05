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

  if op_account_name then
    return string.format(' 1Password: %s', op_account_name)
  else
    return ' 1Password: No active session'
  end
end

return M
