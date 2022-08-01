local M = {}

local op = require('op.cli')
local utils = require('op.utils')
local ts = require('op.treesitter')

function M.op_create()
  local strings = ts.get_all_strings()
  utils.select_fields(strings, function(fields, item_title, vault)
    if not fields or #fields == 0 then
      return
    end

    local field_cli_args = vim.tbl_map(function(field)
      return string.format('%s=%s', field.name, field.value)
    end, fields)

    local args = vim.list_extend({
      '--dry-run',
      '--category',
      'login',
      '--title',
      item_title,
      '--vault',
      vault,
    }, field_cli_args)
    local stdout, stderr, exit_code = op.item.create(args)
    print(vim.inspect(stdout), vim.inspect(stderr), exit_code)
  end)
end

function M.op_signin()
  local stdout, stderr = op.account.list({ '--format', 'json' })
  if #stderr > 0 then
    vim.notify(stderr[1])
    return
  end

  if #stdout == 0 then
    return
  end

  local accounts = vim.json.decode(table.concat(stdout, ''))
  if #accounts == 0 then
    return
  end

  vim.ui.select(accounts, {
    prompt = 'Select 1Password account',
    format_item = function(account)
      return string.format('%s (%s, UUID: %s)', account.email, account.url, account.user_uuid)
    end,
  }, function(selection)
    if not selection then
      return
    end
    local _, stderr_2 = op.signin({ '--account', selection.user_uuid })
    if #stderr_2 > 0 then
      vim.notify(stderr_2[1])
    else
      vim.notify(string.format('Signed in with %s (%s)', selection.email, selection.url))
    end
  end)
end

function M.op_whoami()
  local stdout, stderr = op.whoami({ '--format', 'json' })
  if #stderr > 0 then
    vim.notify(stderr[1])
  elseif #stdout > 0 then
    local account = vim.json.decode(table.concat(stdout, ''))
    vim.notify(string.format('Signed in with %s (%s)', account.email, account.url))
  end
end

M.op_insert_reference = utils.with_inputs(
  { { 'Select 1Password item', find = true }, 'Enter item field name' },
  function(item_name, field_name)
    local stdout, stderr =
      op.item.get({ item_name, '--fields', string.format('label=%s', field_name), '--format', 'json' })
    if #stdout > 0 then
      local ref = utils.get_op_reference(stdout)
      utils.insert_at_cursor(ref)
    elseif #stderr > 0 then
      if stderr[1]:find('More than one item matches') then
        table.remove(stderr, 1)
        local vaults = utils.parse_vaults_from_more_than_one_match(stderr)
        vim.ui.select(vaults, {
          prompt = 'Multiple matching items, select one',
          format_item = function(item)
            return item.name .. ': ' .. item.id
          end,
        }, function(item)
          if not item then
            return
          end

          local stdout_2, stderr_2 =
            op.item.get({ item.id, '--fields', string.format('label=%s', field_name), '--format', 'json' })
          if #stdout_2 > 0 then
            local ref = utils.get_op_reference(stdout)
            utils.insert_at_cursor(ref)
          elseif #stderr_2 > 0 then
            vim.notify(stderr_2[1])
          end
        end)
      else
        vim.notify(stderr[1])
      end
    end
  end
)

return M
