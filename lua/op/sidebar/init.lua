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
local sidebaritem = require('op.sidebar.sidebaritems')
local utils = require('op.utils')
local securenotes = require('op.securenotes')

local initialized = false

local sidebar_items = {}

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
      url = vim.tbl_get(item, 'urls', 1),
      vault = {
        id = item.vault.id,
      },
    }
  end, items)
end

local function build_sidebar_items(items)
  local lines = {}
  if #items.favorites > 0 then
    table.insert(lines, sidebaritem.header({ title = 'Favorites', icon = '' }))

    vim.tbl_map(function(favorite)
      table.insert(lines, sidebaritem.item(favorite))
    end, items.favorites)
  end

  if #items.favorites > 0 and #items.secure_notes > 0 then
    table.insert(lines, sidebaritem.separator())
  end

  if #items.secure_notes > 0 then
    table.insert(lines, sidebaritem.header({ title = 'Secure Notes', icon = icons.category_icon('SECURE_NOTE') }))
    vim.tbl_map(function(note)
      table.insert(lines, sidebaritem.item(note))
    end, items.secure_notes)
  end

  return lines
end

local function on_enter()
  local line = vim.api.nvim_win_get_cursor(0)[1]
  local sidebar_item = sidebar_items[line]
  if not sidebar_item then
    msg.error('Failed to open 1Password sidebar item.')
    return
  end

  if sidebar_item.type ~= 'item' then
    return
  end

  if sidebar_item.data.category == 'SECURE_NOTE' then
    securenotes.load_secure_note(sidebar_item.data.uuid, sidebar_item.data.vault_uuid)
    return
  end

  if sidebar_item.data.url and #sidebar_item.data.url > 0 then
    utils.open_and_fill(sidebar_item.data.url, sidebar_item.data.uuid)
    return
  end

  local stdout, stderr = op.account.get({ '--format', 'json' })
  if #stderr > 0 then
    msg.error(stderr[1])
  elseif #stdout > 0 then
    local account = vim.json.decode(table.concat(stdout, ''))
    local url = string.format(
      'onepassword://view-item?a=%s&v=%s&i=%s',
      account.id,
      sidebar_item.data.vault_uuid,
      sidebar_item.data.uuid
    )
    utils.open_url(url)
  end
end

function M.load_sidebar_items()
  local items = {
    favorites = {},
    secure_notes = {},
  }

  local function set_items(stdout, stderr, type)
    if #stderr > 0 then
      msg.error(stderr[1])
    elseif #stdout > 0 then
      local favorites = vim.json.decode(table.concat(stdout, ''))
      items[type] = strip_sensitive_data(favorites)
    end
  end

  if should_load_favorites() then
    local stdout, stderr = op.item.list({ '--format', 'json', '--favorite' })
    set_items(stdout, stderr, 'favorites')
  end

  if should_load_notes() then
    local stdout, stderr = op.item.list({ '--format', 'json', '--categories="Secure Note"' })
    set_items(stdout, stderr, 'secure_notes')
  end

  sidebar_items = build_sidebar_items(items)
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
    lines = vim.tbl_map(function(line)
      return sidebaritem.render(line)
    end, sidebar_items),
    unlisted = true,
  })

  vim.keymap.set('n', '<CR>', on_enter, { buffer = op_buf_id })

  if op_buf_id == 0 then
    msg.error('Failed to create sidebar buffer.')
    op_buf_id = nil
    return
  end

  local cfg = config.get_config_immutable()
  vim.cmd(tostring(cfg.sidebar.width or 40) .. 'vsplit')
  -- luacheck thinks it's readonly for some reason
  -- luacheck:ignore
  vim.wo.number = false
  local win_id = vim.api.nvim_get_current_win()
  vim.wo.signcolumn = 'no'
  vim.api.nvim_win_set_buf(win_id, op_buf_id)

  bufs.autocmds({
    {
      -- prevent other buffers from being loaded in the sidebar window
      'BufWinEnter',
      callback = function()
        local bufnr = vim.api.nvim_get_current_buf()
        if bufnr ~= op_buf_id and vim.fn.bufnr('#') == op_buf_id then
          local op_win_id = vim.api.nvim_get_current_win()
          vim.cmd('noautocmd wincmd p')
          local alt_win_id = vim.api.nvim_get_current_win()
          if alt_win_id == op_win_id then
            vim.cmd('noautocmd wincmd h')
          end
          alt_win_id = vim.api.nvim_get_current_win()
          if alt_win_id == op_win_id then
            vim.cmd('noautocmd wincmd l')
          end
          alt_win_id = vim.api.nvim_get_current_win()
          if alt_win_id == op_win_id then
            vim.cmd('noautocmd wincmd j')
          end
          alt_win_id = vim.api.nvim_get_current_win()
          if alt_win_id == op_win_id then
            vim.cmd('noautocmd wincmd k')
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

  local buf_lines = vim.tbl_map(function(line)
    return sidebaritem.render(line)
  end, sidebar_items)
  bufs.update_lines(op_buf_id, buf_lines)
end

return M
