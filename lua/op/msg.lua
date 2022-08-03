local M = {}

function M.success(msg)
  vim.notify(msg, vim.log.levels.INFO)
end

function M.error(msg)
  vim.notify(msg, vim.log.levels.ERROR)
end

return M
