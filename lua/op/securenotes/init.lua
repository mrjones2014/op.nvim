local M = {}

local lazyrequire = require('op.lazyrequire').require_on_index
-- aliasing require like this keeps type intelligence
-- and LSP go-to-definition etc. working
local require = lazyrequire

---@type OpApi
local op = require('op.api')
local msg = require('op.msg')
local session = require('op.securenotes.session')
local config = require('op.config')
local utils = require('op.utils')
local bufs = require('op.buffers')
local categories = require('op.categories')

local function with_note(uuid, vault_uuid, callback)
  op.item.get({ async = true, uuid, '--vault', vault_uuid, '--format', 'json' }, function(stdout, stderr)
    if #stderr > 0 then
      msg.error(stderr[1])
    elseif #stdout > 0 then
      local note = vim.json.decode(table.concat(stdout, ''))
      callback(note)
    end
  end)
end

local function format_title(title)
  local prefix = vim.tbl_get(config.get_config_immutable(), 'secure_notes', 'buf_name_prefix')
  if prefix then
    return string.format('%s %s.md', vim.trim(prefix), vim.trim(title))
  end

  return string.format('%s.md', vim.trim(title))
end

---Return note contents as an array of lines
---@return table
local function note_contents(note)
  local contents = vim.tbl_filter(function(field)
    return field.id == 'notesPlain' and field.purpose == 'NOTES'
  end, note.fields)[1]
  if not contents then
    contents = ''
  else
    contents = contents.value
  end

  contents = contents or ''

  local normalized, _ = string.gsub(contents, '\r\n', '\n')
  return vim.split(normalized, '\n')
end

local function setup_secure_note_buf(win_id, note)
  local title = format_title(note.title)
  local existing_buf = vim.tbl_filter(function(buf)
    local buf_name = vim.api.nvim_buf_get_name(buf):sub(#title * -1)
    return buf_name == title
  end, vim.api.nvim_list_bufs())[1]
  if existing_buf and session.get_for_buf_id(existing_buf) then
    vim.api.nvim_win_set_buf(0, existing_buf)
    return
  end

  local buf = bufs.create({
    filetype = 'markdown',
    buftype = 'acwrite',
    modified = false,
    title = title,
    lines = note_contents(note),
  })

  if buf == 0 then
    msg.error('Failed to create buffer for Secure Notes.')
    return nil
  end

  session.create(buf, note)

  bufs.autocmds({
    {
      -- set modified on TextChanged, :w sets nomodified
      { 'TextChanged', 'TextChangedI' },
      buffer = buf,
      callback = function()
        -- wait till after text is set the first time
        if vim.b.op_nvim_secure_note_initialized then
          vim.api.nvim_buf_set_option(buf, 'modified', true)
          return
        end

        vim.api.nvim_buf_set_option(buf, 'modified', false)
        vim.b.op_nvim_secure_note_initialized = true -- luacheck:ignore 122
      end,
    },
    {
      -- Handle autocmd BufWriteCmd so that :w can be used to update the Secure Note in 1Password
      'BufWriteCmd',
      buffer = buf,
      callback = M.save_secure_note,
    },
    {
      -- Handle autocmd BufReadCmd so that :e can be used to load changes from 1Password into the buffer
      'BufReadCmd',
      buffer = buf,
      callback = M.load_note_changes,
    },
    {
      -- kill session on buffer delete
      { 'BufDelete', 'BufWipeout' },
      buffer = buf,
      callback = function()
        session.close_session_for_buf_id(buf)
      end,
    },
  })

  -- finally, open the buffer
  vim.api.nvim_win_set_buf(win_id, buf)
end

function M.load_note_changes()
  local buf_id = vim.api.nvim_get_current_buf()
  local modified = vim.api.nvim_buf_get_option(buf_id, 'modified')

  local function sync()
    local editing_session = session.get_for_buf_id(buf_id)
    if not editing_session then
      msg.error(string.format('No active editing session for buffer %s', buf_id))
      return
    end

    local stdout, stderr =
      op.item.get({ editing_session.uuid, '--vault', editing_session.vault_uuid, '--format', 'json' })
    if #stderr > 0 then
      msg.error(stderr[1])
    elseif #stdout > 0 then
      local note = vim.json.decode(table.concat(stdout, ''))
      local contents = note_contents(note)
      vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, contents)
      vim.defer_fn(function()
        vim.api.nvim_buf_set_option(buf_id, 'modified', false)
        -- reset filetype to restore highlighting
        vim.bo.filetype = 'markdown' -- luacheck: ignore 122
      end, 1)
    end
  end

  if modified then
    local choices = [[&Overwrite with current buffer text
&Discard current buffer changes
&Cancel]]
    local choice = vim.fn.confirm('Unsaved changes in your Secure Note:', choices, '&Cancel', 'Error')
    -- 0 = <ESC>, 3 = [C]ancel
    if choice == 0 or choice == 3 then
      return
    end

    if choice == 1 then
      M.save_secure_note()
      return
    end

    -- choice == 2, Discard current buffer changes
    sync()
  else
    sync()
  end
end

function M.save_secure_note()
  local buf_id = vim.api.nvim_get_current_buf()
  local editing_session = session.get_for_buf_id(buf_id)
  if not editing_session then
    msg.error(string.format('No active editing session for buffer %s', buf_id))
  end

  local buf_lines = vim.api.nvim_buf_get_lines(buf_id, 0, -1, false)
  local buf_str = table.concat(buf_lines, '\n')
  op.item.edit({
    async = true,
    '--format',
    'json',
    '--vault',
    editing_session.vault_uuid,
    editing_session.uuid,
    string.format('notesPlain=%s', buf_str),
  }, function(stdout, stderr)
    if #stderr > 0 then
      msg.error(stderr[1])
    elseif #stdout > 0 then
      msg.success('1Password Secure Note updated.')
      vim.api.nvim_buf_set_option(buf_id, 'modified', false)
    end
  end)
end

function M.new_secure_note()
  local win_id = vim.api.nvim_get_current_win()
  utils.with_vault(function(vault)
    vim.schedule(function()
      vim.ui.input({ prompt = 'Secure Note Title' }, function(title)
        if not title or #title == 0 then
          msg.error('Secure Note title is required.')
          return
        end

        op.item.create({
          async = true,
          '--format',
          'json',
          '--category',
          categories.SECURE_NOTE.text,
          '--vault',
          vault.id,
          '--title',
          title,
        }, function(stdout, stderr)
          if #stderr > 0 then
            msg.error(stderr[1])
          elseif #stdout > 0 then
            local note = vim.json.decode(table.concat(stdout, ''))
            msg.success(string.format("Created Secure Note '%s'", title))
            vim.schedule(function()
              setup_secure_note_buf(win_id, note)
            end)
          end
        end)
      end)
    end)
  end)
end

function M.load_secure_note(uuid, vault_uuid)
  local win_id = vim.api.nvim_get_current_win()
  with_note(uuid, vault_uuid, function(note)
    vim.schedule(function()
      setup_secure_note_buf(win_id, note)
    end)
  end)
end

function M.open_secure_note()
  local stdout, stderr =
    op.item.list({ string.format('--categories="%s"', categories.SECURE_NOTE.text), '--format', 'json' })
  if #stderr > 0 then
    msg.error(stderr[1])
  elseif #stdout > 0 then
    local secure_notes = vim.json.decode(table.concat(stdout, ''))
    vim.ui.select(secure_notes, {
      prompt = '1Password Secure Notes',
      format_item = function(secure_note)
        return secure_note.title
      end,
    }, function(selected)
      if not selected then
        return
      end

      M.load_secure_note(selected.id, selected.vault.id)
    end)
  end
end

return M
