local M = {}

local op = require('op.cli')

local function collect_inputs(prompts, callback, outputs)
  outputs = outputs or {}
  if not prompts or #prompts == 0 then
    callback(unpack(outputs))
    return
  end
  vim.ui.input({ prompt = prompts[1] }, function(input)
    table.insert(outputs, input)
    table.remove(prompts, 1)
    collect_inputs(prompts, callback, outputs)
  end)
end

local function with_inputs(prompts, callback)
  return function(...)
    if ... and #... >= #prompts then
      callback(...)
      return
    end

    collect_inputs(prompts, callback, { ... })
  end
end

local function parse_vaults_from_more_than_one_match(output)
  local vaults = {}
  for _, line in pairs(output) do
    line = vim.trim(line)
    local _, vault_start_idx = line:find('" in vault ')
    local _, separator_idx = line:find(':')
    table.insert(
      vaults,
      { name = string.sub(line, vault_start_idx + 1, separator_idx - 1), id = string.sub(line, separator_idx + 2) }
    )
  end

  return vaults
end

M.op_insert = with_inputs({ '1Password item name', 'Item field name' }, function(item_name, field_name)
  op.item.get({ item_name, '--fields', 'label=' .. field_name }, function(stdout)
    vim.notify(stdout[1])
  end, function(stderr)
    if stderr[1]:find('More than one item matches') then
      table.remove(stderr, 1)
      local vaults = parse_vaults_from_more_than_one_match(stderr)
      vim.ui.select(vaults, {
        prompt = 'Multiple matching items, select one',
        format_item = function(item)
          return item.name .. ': ' .. item.id
        end,
      }, function(item)
        if not item then
          return
        end

        op.item.get({ item.id, '--fields', 'label=' .. field_name }, function(stdout)
          vim.notify(stdout[1])
        end, function(stderr_2)
          vim.notify(stderr_2[1])
        end)
      end)
    else
      vim.notify(stderr[1])
    end
  end)
end)

M.op_insert()

return M
