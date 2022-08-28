local M = {}

local lazyrequire = require('op.lazyrequire').require_on_index
-- aliasing require like this keeps type intelligence
-- and LSP go-to-definition etc. working
local require = lazyrequire

---@type Api
local op = require('op.api')
local msg = require('op.msg')
local session = require('op.securenotes.session')
local config = require('op.config')

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

local function buf_set_options(buf, opts)
  for key, opt in pairs(opts) do
    if key == 'title' or key == 'name' then
      local prefix = vim.tbl_get(config.get_config_immutable(), 'secure_notes', 'buf_name_prefix')
      local name = vim.trim(opt)
      if prefix and #prefix > 0 then
        name = string.format('%s %s', vim.trim(prefix), name)
      end
      vim.api.nvim_buf_set_name(buf, name)
    else
      vim.api.nvim_buf_set_option(buf, key, opt)
    end
  end
end

---Return note contents as an array of lines
local function note_contents(note)
  local contents = vim.tbl_filter(function(field)
    return field.id == 'notesPlain' and field.purpose == 'NOTES'
  end, note.fields)[1]
  if not contents then
    contents = ''
  else
    contents = contents.value
  end

  local normalized, _ = string.gsub(contents, '\r\n', '\n')
  return vim.split(normalized, '\n')
end

function M.save_secure_note(buf_id)
  -- TODO
  msg.error("require('op.securenotes).save_secure_note not implemented yet!")
end

function M.load_secure_note(uuid, vault_uuid)
  local win_id = vim.api.nvim_get_current_win()
  with_note(uuid, vault_uuid, function(note)
    vim.schedule(function()
      local buf = vim.api.nvim_create_buf(true, false)
      if buf == 0 then
        msg.error('Failed to create buffer for secure notes.')
        return
      end

      session.new(buf, note)

      buf_set_options(buf, {
        filetype = 'markdown',
        buftype = 'nofile',
        title = note.title,
      })
      vim.api.nvim_win_set_buf(win_id, buf)
      local contents = note_contents(note)
      vim.api.nvim_buf_set_lines(buf, 0, #contents, false, contents)
    end)
  end)
end

function M.open_secure_note()
  local stdout, stderr = op.item.list({ '--categories="Secure Note"', '--format', 'json' })
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
