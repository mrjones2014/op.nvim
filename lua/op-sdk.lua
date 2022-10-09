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

local function filter(predicate, list)
  local result = {}
  for _, value in pairs(list) do
    if predicate(value) then
      table.insert(result, value)
    end
  end

  return result
end

local function insert_all(list, ...)
  local items = { ... }
  for _, item in ipairs(items) do
    table.insert(list, item)
  end
end

local function join_lists(list, list2)
  local result = {}
  insert_all(result, unpack(list))
  insert_all(result, unpack(list2))
  return result
end

---Build the CLI bindings as a table with the specified backend
---@param cli_path string the path to the CLI, defaults to `op`
---@param command_map table
---@param backend Backend
---@param prev_args string[]|nil
---@return Cli the CLI bindings as a table
local function build_api(cli_path, command_map, backend, prev_args)
  cli_path = cli_path or 'op'
  local api = {}
  for key, cmd_obj in pairs(command_map) do
    if type(cmd_obj) == 'string' then
      local args = { key, cmd_obj }
      if prev_args and #prev_args > 0 then
        args = join_lists(prev_args, args)
      end

      -- don't include list indices as args
      args = filter(function(val)
        return type(val) == 'string'
      end, args)

      api[cmd_obj] = function(cmd_args, ...)
        local all_args = join_lists({ cli_path }, join_lists(args, cmd_args or {}))
        return backend(all_args, ...)
      end
    elseif type(cmd_obj) == 'table' then
      prev_args = prev_args or {}
      api[key] = build_api(cli_path, cmd_obj, backend, join_lists(prev_args, { key }))
    end
  end

  return api
end

local M = {}

---Initialize the SDK with the specified backend, or default backend if `backend` is `nil`
---@param backend|nil Backend backend to use, defaults to a default backend using io.popen, creates functions that return `stdout:string[], stderr:string[], exit_code:integer`
---@param cli_path string|nil the path to the 1Password CLI if not on `$PATH`
---@return Cli the CLI bindings as a table
function M.init(backend, cli_path)
  backend = backend or require('op-sdk.backend.default')
  cli_path = cli_path or 'op'
  return build_api(cli_path, OP_COMMANDS, backend, nil)
end

return M
