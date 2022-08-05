local M = {}

local cfg = require('op.config')

function M.setup(user_config)
  cfg.setup(user_config)
  if cfg.get_config_immutable().update_statusline_on_start == true then
    if vim.g.op_nvim_remote_loaded then
      require('op.statusline').update()
    else
      vim.api.nvim_create_autocmd('User', {
        group = vim.api.nvim_create_augroup('OpNvimInit', { clear = true }),
        pattern = 'OpNvimRemoteLoaded',
        callback = require('op.statusline').update,
      })
    end
  end
end

return M
