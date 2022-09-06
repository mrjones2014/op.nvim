local M = {}

local lazyrequire = require('op.lazyrequire').require_on_index
-- aliasing require like this keeps type intelligence
-- and LSP go-to-definition etc. working
local require = lazyrequire
local config = require('op.config')
local msg = require('op.msg')
local bufs = require('op.buffers')
local op = require('op.api')
local sidebaritem = require('op.sidebar.sidebaritems')
local actions = require('op.sidebar.actions')
local state = require('op.state')
local categories = require('op.categories')
local main = require('op')

local initialized = false

local sidebar_items = {}

local op_view = {
  buf = nil,
  win = nil,
  parent_win = nil,
}

local function update_view(view)
  view = view or {}
  op_view = {
    buf = view.buf,
    win = view.win,
    parent_win = view.parent_win,
  }
end

local function is_open()
  return op_view.buf and op_view.buf ~= 0
end

-- HACK: some window options need to be reset
local function reset_win_options(in_between)
  local parent_win_opts = {
    number = vim.api.nvim_win_get_option(op_view.parent_win, 'number'),
    relativenumber = vim.api.nvim_win_get_option(op_view.parent_win, 'relativenumber'),
    signcolumn = vim.api.nvim_win_get_option(op_view.parent_win, 'signcolumn'),
    winfixwidth = vim.api.nvim_win_get_option(op_view.parent_win, 'winfixwidth'),
    winfixheight = vim.api.nvim_win_get_option(op_view.parent_win, 'winfixheight'),
  }
  if type(in_between) == 'function' then
    in_between()
  end
  for opt, value in pairs(parent_win_opts) do
    vim.api.nvim_win_set_option(op_view.parent_win, opt, value)
  end
end

local function update_items(items)
  sidebar_items = items
  M.render()
end

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
      url = vim.tbl_get(item, 'urls', 1, 'href'),
      vault = {
        id = item.vault.id,
      },
    }
  end, items)
end

local function build_sidebar_items(items)
  local lines = {}
  if #items.favorites > 0 then
    table.insert(lines, sidebaritem.favorites_header())

    vim.tbl_map(function(favorite)
      table.insert(lines, sidebaritem.item(favorite))
    end, items.favorites)
  end

  if #items.favorites > 0 and #items.secure_notes > 0 then
    table.insert(lines, sidebaritem.separator())
  end

  if #items.secure_notes > 0 then
    table.insert(lines, sidebaritem.secure_notes_header())
    vim.tbl_map(function(note)
      table.insert(lines, sidebaritem.item(note))
    end, items.secure_notes)
  end

  return lines
end

function M.load_sidebar_items()
  local load_favorites = should_load_favorites()
  local load_notes = should_load_notes()

  if not load_favorites and not load_notes then
    return
  end

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

      update_items(build_sidebar_items(items))
    end
  end

  local function load_data()
    if load_favorites then
      op.item.list({ async = true, '--format', 'json', '--favorite' }, function(stdout, stderr)
        set_items(stdout, stderr, 'favorites')
      end)
    end

    if load_notes then
      op.item.list(
        { async = true, '--format', 'json', string.format('--categories="%s"', categories.SECURE_NOTE.text) },
        function(stdout, stderr)
          set_items(stdout, stderr, 'secure_notes')
        end
      )
    end
  end

  if not state.signed_in then
    main.op_signin(nil, load_data)
  else
    load_data()
  end
end

function M.open()
  local parent_win = vim.fn.win_getid(vim.fn.winnr('#'))

  if not initialized then
    M.load_sidebar_items()
    initialized = true
  end

  if is_open() then
    return
  end

  local buf_id = bufs.create({
    filetype = '1PasswordSidebar',
    buftype = 'nofile',
    readonly = true,
    title = '1Password',
    lines = vim.tbl_map(function(line)
      return sidebaritem.render(line)
    end, sidebar_items),
    unlisted = true,
  })

  if buf_id == 0 then
    msg.error('Failed to create sidebar buffer.')
    update_view()
    return
  end

  local cfg = config.get_config_immutable()

  for lhs, rhs in pairs(cfg.sidebar.mappings) do
    local action = actions[rhs]
    -- if not an action name, then treat as a vim :cmd
    if not action and type(rhs) == 'string' then
      action = rhs
    end

    -- wrap with our handler
    if type(action) == 'function' then
      local copied_fn = vim.deepcopy(action)
      action = function()
        local line = vim.api.nvim_win_get_cursor(0)[1]
        local sidebar_item = sidebar_items[line]
        if not sidebar_item then
          msg.error(
            'Failed to get 1Password sidebar item. This probably indicated a bug in op.nvim, '
              .. 'please open an issue if the problem persists.'
          )
          return
        end

        if sidebar_item.type ~= 'item' then
          return
        end

        copied_fn(sidebar_item)
      end
    end

    vim.keymap.set('n', lhs, action, { buffer = buf_id })
  end

  local sidebar_side = cfg.sidebar.side
  local split_cmd = sidebar_side == 'right' and 'belowright' or 'aboveleft'
  vim.cmd(string.format('%s %svsplit', split_cmd, tostring(cfg.sidebar.width or 40)))
  local win_id = vim.api.nvim_get_current_win()
  update_view({ buf = buf_id, win = win_id, parent_win = parent_win })
  vim.api.nvim_win_set_buf(win_id, buf_id)
  vim.api.nvim_win_set_option(win_id, 'number', false)
  vim.api.nvim_win_set_option(win_id, 'signcolumn', 'no')
  vim.api.nvim_win_set_option(win_id, 'winfixwidth', true)
  vim.api.nvim_win_set_option(win_id, 'winfixheight', true)

  bufs.autocmds({
    {
      'WinEnter',
      callback = function()
        -- if it's not our window but it is the sidebar buffer,
        -- go to next buffer and reset window options
        if vim.api.nvim_get_current_win() ~= op_view.win and vim.api.nvim_get_current_buf() == op_view.buf then
          reset_win_options(function()
            vim.cmd('bnext')
          end)
          return
        end
      end,
    },
    {
      { 'BufEnter', 'BufWinEnter' },
      callback = function()
        -- if not open or not in sidebar window
        local curwin = vim.api.nvim_get_current_win()
        if not is_open() or curwin ~= op_view.win then
          return
        end

        local curbuf = vim.api.nvim_win_get_buf(curwin)
        -- if another buffer took over our window
        if curbuf ~= op_view.buf then
          -- restore our window and move new buf to parent window
          vim.api.nvim_win_set_buf(op_view.win, op_view.buf)
          reset_win_options(function()
            vim.api.nvim_win_set_buf(op_view.parent_win, curbuf)
          end)
          vim.defer_fn(function()
            vim.api.nvim_set_current_win(op_view.parent_win)
          end, 1)
        end
      end,
    },
  })

  M.render()
end

function M.close()
  if is_open() then
    vim.api.nvim_buf_delete(op_view.buf, { force = true })
    update_view()
  end
end

function M.toggle()
  if is_open() then
    M.close()
    return
  end

  M.open()
end

function M.render()
  if not is_open() then
    return
  end

  local buf_lines = vim.tbl_map(function(line)
    return sidebaritem.render(line)
  end, sidebar_items)
  bufs.update_lines(op_view.buf, buf_lines)
  sidebaritem.apply_highlights(sidebar_items, op_view.buf)
end

return M
