local M = {}

M.account_name = nil

function M.update(account)
  -- if explicitly given false, and we already
  -- have an account name, it was an action that did
  -- not switch accounts (i.e. getting an item, etc.)
  -- so we don't need to waste time/resources updating
  if account == false and M.account_name then
    return
  end

  if account and account.name then
    M.account_name = account.name
    return
  end

  vim.schedule_wrap(function()
    local stdout, stderr = require('op.cli').accout.get({ '--format', 'json' })
    if #stderr > 0 or #stdout == 0 then
      return
    end

    account = vim.json.decode(table.concat(stdout))
    M.account_name = account.name
  end)
end

function M.component()
  if M.account_name then
    return string.format(' 1Password: %s', M.account_name)
  else
    return ' 1Password: No active session'
  end
end

return M
