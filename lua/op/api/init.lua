local config = require('op.config')

local OP_COMMANDS = {
  'inject',
  'read',
  'run',
  'signin',
  'signout',
  'update',
  'whoami',
  account = {
    'add',
    'get',
    'list',
    'forget',
  },
  connect = {
    group = {
      'grant',
      'revoke',
    },
    server = {
      'create',
      'get',
      'edit',
      'delete',
      'list',
    },
    token = {
      'create',
      'edit',
      'delete',
      'list',
    },
    vault = {
      'grant',
      'revoke',
    },
  },
  document = {
    'create',
    'get',
    'edit',
    'delete',
    'list',
  },
  eventsApi = {
    'create',
  },
  group = {
    user = {
      'grant',
      'revoke',
      'list',
    },
    'create',
    'get',
    'edit',
    'delete',
    'list',
  },
  item = {
    'create',
    'get',
    'edit',
    'delete',
    'list',
    'share',
  },
  user = {
    'provision',
    'confirm',
    'get',
    'edit',
    'suspend',
    'reactivate',
    'delete',
    'list',
  },
  vault = {
    'create',
    'edit',
    'get',
    'delete',
    'list',
  },
}

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

local function build_cmd(full_cmd)
  return function(args, on_done)
    args = args or {}
    local full_cmd_args = vim.list_extend(
      vim.deepcopy(full_cmd),
      vim.list_extend(vim.deepcopy(config.get_config_immutable().global_args or {}), args)
    )

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
end

local function build_api(command_map, parent_key)
  local api = {}
  for key, cmd_obj in pairs(command_map) do
    if type(cmd_obj) == 'string' then
      local args = { key, cmd_obj }
      if parent_key then
        table.insert(args, 1, parent_key)
      end

      -- don't include list indices as args
      args = vim.tbl_filter(function(val)
        return type(val) == 'string'
      end, args)

      api[cmd_obj] = build_cmd(args)
    else
      if type(cmd_obj) == 'table' then
        api[key] = build_api(cmd_obj, key)
      end
    end
  end

  return api
end

---@type Api
local API = build_api(OP_COMMANDS)
return API
