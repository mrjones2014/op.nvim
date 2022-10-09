local lazyrequire = require('op.lazyrequire').require_on_index
-- aliasing require like this keeps type intelligence
-- and LSP go-to-definition etc. working
local require = lazyrequire
local config = require('op.config')

local function non_empty_values(output)
  if not output then
    return {}
  end

  if #output == 0 then
    return {}
  end

  return vim.tbl_filter(function(value)
    return value and #value > 0
  end, output)
end

local function handle_cmd(args, on_done)
  args = args or {}

  -- binary path is handled by our backend
  table.remove(args, 1)

  local full_cmd_args = vim.list_extend(vim.deepcopy(config.get_config_immutable().global_args or {}), args)

  local function callback(data, on_done_cb)
    local parsed_data = vim.json.decode(data)

    local output_list = non_empty_values(vim.split(parsed_data.output, '\n'))
    -- output in stdout position
    local values = { output_list, {}, parsed_data.return_code }
    if parsed_data.return_code ~= 0 then
      -- if nonzero exit, output in stderr position
      values = { {}, output_list, parsed_data.return_code }
    end

    if type(on_done_cb) == 'function' then
      on_done_cb(unpack(values))
    end

    return unpack(values)
  end

  if args.async == true then
    local request_id = require('op.api.async').create_request(function(data)
      callback(data, on_done)
    end)
    vim.fn.OpCmdAsync(request_id, unpack(full_cmd_args))
  else
    local data = vim.fn.OpCmd(unpack(full_cmd_args))
    return callback(data)
  end
end

local API = require('op-sdk').init(handle_cmd)

---@type Api
return API
