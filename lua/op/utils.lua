local M = {}

local op = require('op.cli')

local function with_item_overviews(callback)
  op.item.list({ '--format', 'json' }, function(stdout)
    callback(vim.json.decode(table.concat(stdout, '')))
  end, function(stderr)
    vim.notify(stderr[1])
  end)
end

local function collect_inputs(prompts, callback, outputs)
  outputs = outputs or {}
  if not prompts or #prompts == 0 then
    callback(unpack(outputs))
    return
  end
  local prompt = prompts[1]
  if type(prompt) == 'table' and prompt.find == true then
    with_item_overviews(function(items)
      vim.ui.select(items, {
        prompt = 'Select 1Password item',
        format_item = function(item)
          return string.format("'%s' in vault '%s' (UUID %s)", item.title, item.vault.name, item.id)
        end,
      }, function(selected)
        table.insert(outputs, selected.id)
        table.remove(prompts, 1)
        collect_inputs(prompts, callback, outputs)
      end)
    end)
  else
    vim.ui.input({ prompt = prompts[1] }, function(input)
      table.insert(outputs, input)
      table.remove(prompts, 1)
      collect_inputs(prompts, callback, outputs)
    end)
  end
end

---Get one input per prompt, then call the callback
---with each input as passed as a separate parameter
---to the callback (via `unpack(inputs_tbl)`).
---To use vim.ui.select() on all 1Password items,
---pass the prompt as a table with `find=true`,
---e.g. with_inputs({ 'Select 1Password item' find = true }, 'Field name')
function M.with_inputs(prompts, callback)
  return function(...)
    local prompts_copy = vim.deepcopy(prompts)
    if ... and #... >= #prompts_copy then
      callback(...)
      return
    end

    collect_inputs(prompts_copy, callback, { ... })
  end
end

---Takes in the stderr output that happens when
---more than one item matches the query,
---returns a table with fields `name` and `id`,
---where `id` is the item UUID
function M.parse_vaults_from_more_than_one_match(output)
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

---Given stdout as a table of lines,
---parse the JSON and return the `op://` reference
---@param stdout table
---@return string
function M.get_op_reference(stdout)
  local item = vim.json.decode(table.concat(stdout, ''))
  return item.reference
end

---Insert given text at cursor position.
function M.insert_at_cursor(text)
  local pos = vim.api.nvim_win_get_cursor(0)[2]
  local line = vim.api.nvim_get_current_line()
  local new_line = line:sub(0, pos + 1) .. text .. line:sub(pos + 2)
  vim.api.nvim_set_current_line(new_line)
end

return M
