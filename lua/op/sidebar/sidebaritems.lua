local M = {}

local function should_use_icons()
  return require('op.config').get_config_immutable().use_icons
end

local indent = 2
local padding = 1

M.icons = {
  FAVORITES = '',
  SECURE_NOTES = '',
}

M.hl_namespace = nil

M.highlight_groups = {
  HEADER = 'OpSidebarHeader',
  ITEM = 'OpSidebarItem',
  FAVORITE_ICON = 'OpSidebarFavoriteIcon',
  DEFAULT_ICONS = 'OpSidebarIconDefault',
}

M.item_type = {
  HEADER = 'header',
  ITEM = 'item',
  SEPARATOR = 'separator',
}

local function apply_highlight(item, buf_nr, line_nr)
  -- line numbers are zero-indexed
  line_nr = line_nr - 1

  if item.type == M.item_type.SEPARATOR then
    -- no highlight, line is blank
    return
  end

  local line = vim.api.nvim_buf_get_lines(buf_nr, line_nr, line_nr + 1, false)[1]
  if not line or #line == 0 then
    return
  end

  local line_len = #line
  local icon_len = #M.icons.FAVORITES -- icons should all be the same width

  if item.type == M.item_type.HEADER then
    if should_use_icons() then
      vim.api.nvim_buf_add_highlight(
        buf_nr,
        M.hl_namespace,
        item.is_favorite_header and M.highlight_groups.FAVORITE_ICON or M.highlight_groups.DEFAULT_ICONS,
        line_nr,
        padding,
        padding + icon_len
      )
      vim.api.nvim_buf_add_highlight(
        buf_nr,
        M.hl_namespace,
        M.highlight_groups.HEADER,
        line_nr,
        padding + icon_len + 1,
        line_len
      )
    else
      vim.api.nvim_buf_add_highlight(buf_nr, M.hl_namespace, M.highlight_groups.HEADER, line_nr, padding, line_len)
    end
  else
    if should_use_icons() then
      vim.api.nvim_buf_add_highlight(
        buf_nr,
        M.hl_namespace,
        M.highlight_groups.DEFAULT_ICONS,
        line_nr,
        padding + indent,
        padding + indent + icon_len
      )
      vim.api.nvim_buf_add_highlight(
        buf_nr,
        M.hl_namespace,
        M.highlight_groups.ITEM,
        line_nr,
        padding + indent + icon_len + 1,
        line_len
      )
    else
      vim.api.nvim_buf_add_highlight(
        buf_nr,
        M.hl_namespace,
        M.highlight_groups.ITEM,
        line_nr,
        padding + indent,
        line_len
      )
    end
  end
end

local function setup_highlight(name, attrs)
  local cmd = string.format('hi default %s', name)
  if attrs.fg then
    cmd = string.format('%s guifg=%s', cmd, attrs.fg)
  end
  if attrs.ctermfg then
    cmd = string.format('%s ctermfg=%s', cmd, tostring(attrs.ctermfg):lower())
  end
  if attrs.bg then
    cmd = string.format('%s guibg=%s', cmd, attrs.bg)
  end
  if attrs.ctermbg then
    cmd = string.format('%s ctermbg=%s', cmd, tostring(attrs.ctermbg):lower())
  end

  local styles = {}
  if attrs.bold then
    table.insert(styles, 'bold')
  end
  if attrs.italic then
    table.insert(styles, 'italic')
  end

  if #styles > 0 then
    cmd = string.format('%s gui=%s', cmd, table.concat(styles, ','))
  end

  vim.cmd(cmd)
end

local default_hl_setup = false
function M.setup_default_highlights()
  local normal_fg = '#ffffff'
  local default_normal_hl = vim.api.nvim_get_hl_by_name('Normal', true)
  if default_normal_hl and default_normal_hl.foreground then
    normal_fg = string.format('#%06x', default_normal_hl.foreground)
  end

  setup_highlight(M.highlight_groups.HEADER, {
    fg = normal_fg,
    ctermfg = vim.opt.background == 'dark' and 'LightGray' or 'Black',
    bold = true,
  })

  setup_highlight(M.highlight_groups.ITEM, {
    fg = normal_fg,
    ctermfg = vim.opt.background == 'dark' and 'LightGray' or 'Black',
    italic = true,
  })

  setup_highlight(M.highlight_groups.FAVORITE_ICON, {
    fg = '#FFAB00',
    ctermfg = 'Yellow',
  })

  setup_highlight(M.highlight_groups.DEFAULT_ICONS, {
    fg = '#0572EC',
    ctermfg = 'Blue',
  })
end

function M.apply_highlights(item_list, buf_nr)
  if M.hl_namespace == nil then
    M.hl_namespace = vim.api.nvim_create_namespace('OpNvim')
  end

  if not default_hl_setup then
    M.setup_default_highlights()
  end

  for idx, item in ipairs(item_list) do
    apply_highlight(item, buf_nr, idx)
  end
end

function M.favorites_header()
  return M.header({ title = 'Favorites', icon = M.icons.FAVORITES, favorites = true })
end

function M.secure_notes_header()
  return M.header({ title = 'Secure Notes', icon = M.icons.SECURE_NOTES })
end

function M.header(fields)
  local header = setmetatable({}, M)
  header.title = fields.title
  header.icon = fields.icon
  header.type = M.item_type.HEADER
  header.is_favorite_header = fields.favorites == true
  return header
end

function M.item(item)
  local sidebar_item = setmetatable({}, M)
  sidebar_item.title = item.title
  sidebar_item.icon = require('op.icons').category_icon(item.category)
  sidebar_item.data = { uuid = item.id, vault_uuid = item.vault.id, category = item.category, url = item.url }
  sidebar_item.type = M.item_type.ITEM
  return sidebar_item
end

function M.separator()
  local item = setmetatable({}, M)
  item.type = M.item_type.SEPARATOR
  return item
end

function M.render(item)
  if item.type == M.item_type.SEPARATOR then
    return ''
  end

  if item.type == M.item_type.ITEM then
    if should_use_icons() then
      return string.format('%s%s %s', (' '):rep(padding + indent), item.icon, item.title)
    end

    return string.format('%s• %s', (' '):rep(padding + indent), item.title)
  end

  -- item.type == header
  if should_use_icons() then
    return string.format('%s%s %s', (' '):rep(padding), item.icon, item.title)
  end

  return string.format('%s', (' '):rep(padding), item.title)
end

return M
