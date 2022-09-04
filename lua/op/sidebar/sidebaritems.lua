local M = {}

function M.header(fields)
  local header = setmetatable({}, M)
  header.title = fields.title
  header.icon = fields.icon
  header.type = 'header'
  return header
end

function M.item(item)
  local sidebar_item = setmetatable({}, M)
  sidebar_item.title = item.title
  sidebar_item.icon = require('op.icons').category_icon(item.category)
  sidebar_item.data = { uuid = item.id, vault_uuid = item.vault.id }
  sidebar_item.type = 'item'
  return sidebar_item
end

function M.separator()
  local item = setmetatable({}, M)
  item.type = 'separator'
  return item
end

function M.render(item)
  if item.type == 'separator' then
    return ''
  end

  local use_icons = require('op.config').get_config_immutable().use_icons

  if item.type == 'item' then
    if use_icons then
      return string.format('   %s %s', item.icon, item.title)
    end

    return string.format('   • %s', item.title)
  end

  -- item.type == header
  if use_icons then
    return string.format(' %s %s', item.icon, item.title)
  end

  return string.format(' %s', item.title)
end

return M
