local M = {}

function M.category_icon(category)
  local categories = require('op.categories')
  local category_data = categories[category or 'CUSTOM'] or category.CUSTOM
  return category_data.icon
end

return M
