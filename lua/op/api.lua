local M = {}

local op = require('op.cli')
local utils = require('op.utils')
local ts = require('op.treesitter')

function M.op_new()
  local strings = ts.get_all_strings()
  utils.select_fields(strings, function(fields, item_title, vault)
    if not fields or #fields == 0 then
      return
    end

    local field_cli_args = vim.tbl_map(function(field)
      return string.format('"%s=%s"', field.name, field.value)
    end, fields)

    local args = vim.list_extend({
      '--dry-run',
      '--category=login',
      string.format('--title="%s"', item_title),
      string.format('--vault="%s"', vault),
    }, field_cli_args)
    op.item.create(args, function(stdout)
      print(vim.inspect(stdout))
    end, function(stderr)
      print(vim.inspect(stderr))
    end)
  end)
end

M.op_insert_reference = utils.with_inputs(
  { { 'Select 1Password item', find = true }, 'Enter item field name' },
  function(item_name, field_name)
    op.item.get({ item_name, '--fields', string.format('label="%s"', field_name), '--format', 'json' }, function(stdout)
      local ref = utils.get_op_reference(stdout)
      utils.insert_at_cursor(ref)
    end, function(stderr)
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

          op.item.get(
            { item.id, '--fields', string.format('label="%s"', field_name), '--format', 'json' },
            function(stdout)
              local ref = utils.get_op_reference(stdout)
              utils.insert_at_cursor(ref)
            end,
            function(stderr_2)
              vim.notify(stderr_2[1])
            end
          )
        end)
      else
        vim.notify(stderr[1])
      end
    end)
  end
)

return M
