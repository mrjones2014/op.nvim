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

M.op_insert = with_inputs({ '1Password item name', 'Item field name' }, function(item_name, field_name)
  op.item.get({ item_name, '--fields', 'label=' .. field_name }, function(stdout)
    vim.notify(stdout[1])
  end)
end)

M.op_insert()

return M
