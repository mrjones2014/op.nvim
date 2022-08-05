local M = {}

local cfg = require('op.config')

function M.setup(user_config)
  cfg.setup(user_config)
  if cfg.get_config_immutable().update_statusline_on_start == true then
    require('op.statusline').update()
  end
end

return M
