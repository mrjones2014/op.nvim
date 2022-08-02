local M = {}

local op = require('op.cli')
local utils = require('op.utils')
local ts = require('op.treesitter')
local opfields = require('op.fields')

function M.op_open()
  local stdout, stderr = op.item.list({ '--format', 'json' })
  if #stderr > 0 then
    vim.notify(stderr[1])
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

      local account_stdout, account_stderr = op.account.get({ '--format', 'json' })
      if #account_stderr > 0 then
        vim.notify(account_stderr[1])
      elseif #account_stdout > 0 then
        local account = vim.json.decode(table.concat(account_stdout, ''))
        local url = string.format('onepassword://view-item?a=%s&v=%s&i=%s', account.id, item.vault.id, item.id)
        utils.open_url(url)
      end
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
      if field.type then
        return string.format('%s[%s]=%s', field.name, field.type, field.value)
      end

      return string.format('%s=%s', field.name, field.value)
    end, fields)

    local url_fields = vim.tbl_filter(function(field)
      return field.type == opfields.FIELD_TYPE_PATTERNS.url.id
    end, fields)

    local args = {
      '--format',
      'json',
      '--category',
      'login',
      '--title',
      item_title,
      '--vault',
      vault,
    }

    if #url_fields > 0 then
      table.insert(args, '--url')
      table.insert(args, url_fields[1].value)
    end

    vim.list_extend(args, field_cli_args)
    local stdout, stderr = op.item.create(args)
    if #stderr > 0 then
      vim.notify(stderr[1])
    elseif #stdout > 0 then
      local item = vim.json.decode(table.concat(stdout, ''))
      vim.notify(
        string.format("Created 1Password login item '%s' in vault '%s' (UUID %s)", item.title, item.vault.name, item.id)
      )
    end
  end)
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
