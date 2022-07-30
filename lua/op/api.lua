local M = {}

local op = require('op.cli')
local utils = require('op.utils')

M.op_insert_reference = utils.with_inputs(
  { { 'Select 1Password item', find = true }, 'Enter item field name' },
  function(item_name, field_name)
    op.item.get({ item_name, '--fields', 'label=' .. field_name, '--format', 'json' }, function(stdout)
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

          op.item.get({ item.id, '--fields', 'label=' .. field_name, '--format', 'json' }, function(stdout)
            local ref = utils.get_op_reference(stdout)
            utils.insert_at_cursor(ref)
          end, function(stderr_2)
            vim.notify(stderr_2[1])
          end)
        end)
      else
        vim.notify(stderr[1])
      end
    end)
  end
)

return M
