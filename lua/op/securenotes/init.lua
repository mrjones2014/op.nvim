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
        name = string.format('%s %s.md', vim.trim(prefix), name)
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

function M.load_secure_note(uuid, vault_uuid)
  local win_id = vim.api.nvim_get_current_win()
  with_note(uuid, vault_uuid, function(note)
    vim.schedule(function()
      local buf = vim.api.nvim_create_buf(true, true)
      if buf == 0 then
        msg.error('Failed to create buffer for Secure Notes.')
        return
      end

      session.new(buf, note)

      local contents = note_contents(note)
      vim.api.nvim_buf_set_lines(buf, 0, #contents, false, contents)
      buf_set_options(buf, {
        filetype = 'markdown',
        buftype = 'acwrite',
        title = note.title,
        modified = false,
      })

      local contents_str = table.concat(contents, '\n')

      -- set modified on TextChanged, :OpCommit sets nomodified
      vim.api.nvim_create_autocmd({ 'TextChanged', 'TextChangedI' }, {
        buffer = buf,
        callback = function()
          local has_changes = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), '\n') ~= contents_str
          vim.api.nvim_buf_set_option(buf, 'modified', has_changes)
        end,
      })

      -- Handle autocmd BufWriteCmd so that :w can be used to update the Secure Note in 1Password
      vim.api.nvim_create_autocmd('BufWriteCmd', {
        buffer = buf,
        callback = M.save_secure_note,
      })

      -- kill session on buffer delete
      vim.api.nvim_create_autocmd('BufDelete', {
        buffer = buf,
        callback = function()
          session.close_session_for_buf_id(buf)
        end,
      })

      -- finally, open the buffer
      vim.api.nvim_win_set_buf(win_id, buf)
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
