local M = {}

local lazyrequire = require('op.lazyrequire').require_on_index
-- aliasing require like this keeps type intelligence
-- and LSP go-to-definition etc. working
local require = lazyrequire
local config = require('op.config')
local msg = require('op.msg')
local icons = require('op.icons')
local bufs = require('op.buffers')
local op = require('op.api')

local initialized = false

local sidebar_items = {
  favorites = {},
  secure_notes = {},
}

local op_buf_id = nil

local function should_load_favorites()
  local cfg = config.get_config_immutable()
  return vim.tbl_contains(cfg.sidebar, 'favorites')
end

local function should_load_notes()
  local cfg = config.get_config_immutable()
  return vim.tbl_contains(cfg.sidebar, 'secure_notes')
end

local function strip_sensitive_data(items)
  return vim.tbl_map(function(item)
    return {
      id = item.id,
      title = item.title,
      category = item.category,
    }
  end, items)
end

local function favorites_header(use_icons)
  if use_icons then
    return ' Favorites'
  else
    return 'Favorites'
  end
end

local function secure_notes_header(use_icons)
  if use_icons then
    return string.format('%s Secure Notes', icons.category_icon('SECURE_NOTE'))
  else
    return 'Secure Notes'
  end
end

local function format_item(item, use_icons)
  if use_icons then
    return string.format('  %s %s', icons.category_icon(item.category), item.title)
  end

  return string.format('  • %s', item.title)
end

local function get_lines()
  local cfg = config.get_config_immutable()
  local use_icons = cfg.use_icons

  local lines = {}
  if #sidebar_items.favorites > 0 then
    table.insert(lines, favorites_header(use_icons))

    vim.tbl_map(function(favorite)
      table.insert(lines, format_item(favorite, use_icons))
    end, sidebar_items.favorites)
  end

  if #sidebar_items.favorites > 0 and #sidebar_items.secure_notes > 0 then
    table.insert(lines, '')
  end

  if #sidebar_items.secure_notes > 0 then
    table.insert(lines, secure_notes_header(use_icons))
    vim.tbl_map(function(note)
      table.insert(lines, format_item(note, use_icons))
    end, sidebar_items.secure_notes)
  end

  return lines
end

function M.load_sidebar_items()
  local function set_items(stdout, stderr, type)
    if #stderr > 0 then
      msg.error(stderr[1])
    elseif #stdout > 0 then
      local favorites = vim.json.decode(table.concat(stdout, ''))
      sidebar_items[type] = strip_sensitive_data(favorites)
      M.render()
    end
  end

  if should_load_favorites() then
    op.item.list({ async = true, '--format', 'json', '--favorite' }, function(stdout, stderr)
      set_items(stdout, stderr, 'favorites')
    end)
  end

  if should_load_notes() then
    op.item.list({ async = true, '--format', 'json', '--categories="Secure Note"' }, function(stdout, stderr)
      set_items(stdout, stderr, 'secure_notes')
    end)
  end
end

function M.toggle()
  if op_buf_id and op_buf_id ~= 0 then
    vim.api.nvim_buf_delete(op_buf_id, { force = true })
    op_buf_id = nil
  end

  if not initialized then
    M.load_sidebar_items()
    initialized = true
  end

  op_buf_id = bufs.create({
    filetype = '1PasswordSidebar',
    buftype = 'nofile',
    readonly = true,
    title = '1Password',
    lines = get_lines(),
    unlisted = true,
  })

  if op_buf_id == 0 then
    msg.error('Failed to create sidebar buffer.')
    op_buf_id = nil
    return
  end

  vim.cmd('vsplit')
  -- luacheck thinks it's readonly for some reason
  -- luacheck:ignore
  vim.wo.number = false
  local win_id = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win_id, op_buf_id)

  bufs.autocmds({
    {
      'BufWinEnter',
      callback = function()
        local bufnr = vim.api.nvim_get_current_buf()
        if bufnr ~= op_buf_id and vim.fn.bufnr('#') == op_buf_id then
          vim.notify('switching bufs')
          local op_win_id = vim.api.nvim_get_current_win()
          vim.cmd('noautocmd wincmd p')
          local alt_win_id = vim.api.nvim_get_current_win()
          if alt_win_id == op_win_id then
            vim.cmd('noautocmd wincmd h')
          end
          alt_win_id = vim.api.nvim_get_current_win()
          if alt_win_id == op_win_id then
            vim.cmd('noautocmd wincmd j')
          end
          alt_win_id = vim.api.nvim_get_current_win()
          if alt_win_id == op_win_id then
            vim.cmd('noautocmd wincmd l')
          end
          alt_win_id = vim.api.nvim_get_current_win()
          if alt_win_id == op_win_id then
            vim.cmd('noautocmd vsplit')
          end
          alt_win_id = vim.api.nvim_get_current_win()
          vim.api.nvim_win_set_buf(0, bufnr)
          vim.api.nvim_win_set_buf(op_win_id, op_buf_id)
          vim.defer_fn(function()
            vim.api.nvim_set_current_win(alt_win_id)
          end, 5)
        end
      end,
    },
  })

  M.render()
end

function M.render()
  if not op_buf_id or op_buf_id == 0 then
    return
  end

  local buf_lines = get_lines()
  bufs.update_lines(op_buf_id, buf_lines)
end

return M
