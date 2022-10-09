local M = {}

local lazyrequire = require('op.lazyrequire').require_on_index
-- aliasing require like this keeps type intelligence
-- and LSP go-to-definition etc. working
local require = lazyrequire
local op = require('op.api')
local utils = require('op.utils')
local ts = require('op.treesitter')
local msg = require('op.msg')
local cfg = require('op.config')
local securenotes = require('op.securenotes')
local categories = require('op.categories')
local sidebar = require('op.sidebar')
local state = require('op.state')
local diagnostics = require('op.diagnostics')

function M.setup(user_config)
  cfg.setup(user_config)
end

local function format_account(account)
  if account.name then
    return account.name
  end

  return string.format('%s (%s)', account.email, account.url)
end

local function get_account(uuid)
  local stdout, stderr = op.account.get({ '--format', 'json', '--account', uuid })
  if #stderr > 0 then
    msg.error(stderr[1])
  elseif #stdout > 0 then
    local account = vim.json.decode(table.concat(stdout, ''))
    return account
  end
end

function M.op_designate_field(value)
  local _, designation = pcall(vim.fn.OpDesignateField, value)
  return designation
end

function M.op_signout()
  op.signout({ async = true }, function(_, stderr)
    if #stderr > 0 then
      msg.error(stderr[1])
    else
      state.signed_in = false
      msg.success('1Password CLI signed out.')
    end
  end)
end

function M.op_signin(account_identifier, on_done)
  if not cfg.get_config_immutable().biometric_unlock then
    return M.op_whoami()
  end

  local function signin(account)
    op.signin({ async = true, '--account', account }, function(_, signin_stderr, error_code)
      if #signin_stderr > 0 then
        msg.error(signin_stderr[1])
      elseif error_code == 0 then
        local account_details = get_account(account)
        if account_details then
          msg.success(string.format('Signed into %s', format_account(account_details)))
          state.signed_in = true
          if type(on_done) == 'function' then
            on_done()
          end
        end
      end
    end)
  end

  if account_identifier and type(account_identifier) == 'string' and #account_identifier > 0 then
    signin(account_identifier)
    return
  end

  local stdout, stderr = op.account.list({ '--format', 'json' })
  if #stderr > 0 then
    msg.error(stderr[1])
  elseif #stdout > 0 then
    local accounts = vim.json.decode(table.concat(stdout, ''))
    if #accounts == 0 then
      msg.error('[ERROR] No accounts found for 1Password CLI')
      return
    end

    if #accounts == 1 then
      signin(accounts[1].account_uuid)
      return
    end

    vim.ui.select(accounts, {
      prompt = 'Select 1Password account',
      format_item = format_account,
    }, function(selected)
      if not selected then
        return
      end

      signin(selected.account_uuid)
    end)
  end
end

function M.op_whoami()
  op.whoami({ async = true, '--format', 'json' }, function(stdout, stderr)
    if #stderr > 0 then
      -- if using token based auth, give a custom error message
      if not cfg.get_config_immutable().biometric_unlock then
        msg.error(
          '[ERROR] When using token based sessions, you must run `eval $(op signin)` *before* launching Neovim'
            .. ' in order for op.nvim to be able to use the session.'
        )
        return
      end

      msg.error(stderr[1])
    elseif #stdout > 0 then
      local account_info = vim.json.decode(table.concat(stdout, ''))
      local account_details = get_account(account_info.account_uuid)
      if account_details then
        msg.success(string.format('Current 1Password account: %s', format_account(account_details)))
      end
    end
  end)
end

function M.op_view_item()
  utils.find_and_open_desktop_app_url('view')
end

function M.op_edit_item()
  utils.find_and_open_desktop_app_url('edit')
end

function M.op_open_and_fill()
  local stdout, stderr = op.item.list({ '--format', 'json' })
  if #stderr > 0 then
    msg.error(stderr[1])
  elseif #stdout > 0 then
    local items = vim.json.decode(table.concat(stdout, ''))
    vim.ui.select(items, {
      prompt = 'Select 1Password item',
      format_item = function(item)
        return utils.format_item_for_select(item)
      end,
    }, function(item)
      if not item then
        return
      end

      if not item.urls or #item.urls < 1 then
        msg.error('No URLs associated with item.')
        return
      end
      utils.open_and_fill(item.urls[1].href, item.id)
    end)
  end
end

function M.op_create()
  local strings = ts.get_all_strings()
  utils.select_fields(strings, function(fields, item_title, vault)
    if not fields or #fields == 0 then
      return
    end

    local field_cli_args = vim.tbl_map(function(field)
      if field.designation then
        return string.format('%s[%s]=%s', field.name, field.designation.field_type, field.value)
      end

      return string.format('%s=%s', field.name, field.value)
    end, fields)

    local url_fields = vim.tbl_filter(function(field)
      if not field.designation then
        return false
      end

      return field.designation.field_type == 'url'
    end, fields)

    local args = {
      '--format',
      'json',
      '--category',
      categories.LOGIN.text,
      '--title',
      item_title,
      '--vault',
      vault.id,
    }

    if #url_fields > 0 then
      table.insert(args, '--url')
      table.insert(args, url_fields[1].value)
    end

    vim.list_extend(args, field_cli_args)
    args.async = true
    op.item.create(args, function(stdout, stderr)
      if #stderr > 0 then
        msg.error(stderr[1])
      elseif #stdout > 0 then
        local item = vim.json.decode(table.concat(stdout, ''))
        msg.success(string.format("Created 1Password login item '%s' in vault '%s'", item.title, item.vault.name))
      end
    end)
  end)
end

M.op_insert = utils.with_inputs(
  { { 'Select 1Password item', find = true }, 'Enter item field name' },
  function(item_name, field_name)
    local stdout, stderr =
      op.item.get({ item_name, '--fields', string.format('label=%s', field_name), '--format', 'json' })
    if #stdout > 0 then
      local ref = utils.get_op_reference(stdout)
      utils.insert_at_cursor(ref)
    elseif #stderr > 0 then
      msg.error(stderr[1])
    end
  end
)

function M.op_note(create_note)
  if create_note then
    securenotes.new_secure_note()
  else
    securenotes.open_secure_note()
  end
end

function M.op_sidebar(should_refresh)
  if should_refresh then
    sidebar.load_sidebar_items()
    sidebar.open()
    return
  end

  sidebar.toggle()
end

function M.op_analyze_buffer()
  diagnostics.analyze_buffer(0, true)
end

return M
