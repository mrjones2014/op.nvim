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

local function deepcopy(obj, seen)
  -- Handle non-tables and previously-seen tables.
  if type(obj) ~= 'table' then
    return obj
  end
  if seen and seen[obj] then
    return seen[obj]
  end

  -- New table; mark it as seen and copy recursively.
  local s = seen or {}
  local res = {}
  s[obj] = res
  for k, v in pairs(obj) do
    res[deepcopy(k, s)] = deepcopy(v, s)
  end
  return setmetatable(res, getmetatable(obj))
end

local function merge_args(base_args, args)
  args = args or {}
  local cmd_args = deepcopy(args)
  for key, value in ipairs(base_args) do
    table.insert(cmd_args, key, value)
  end
  return cmd_args
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

      table.insert(args, 1, cli_path)
      api[cmd_obj] = function(cmd_args, ...)
        local all_args = merge_args(args, cmd_args)
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

---@class CliBuilderOptions
---@field backend Backend|nil backend to use, defaults to a default backend using io.popen, creates functions that return `stdout:string[], stderr:string[], exit_code:integer`
---@field cli_path string|nil path to the CLI binary if not in `$PATH`, defaults to `op`

---Initialize the SDK with the specified backend, or default backend if `backend` is `nil`
---@param options CliBuilderOptions
---@return Cli the CLI bindings as a table
function M.new(options)
  options = options or {}
  local backend = options.backend or require('op-sdk.backend.default')
  local cli_path = options.cli_path or 'op'
  return build_api(cli_path, OP_COMMANDS, backend, nil)
end

return M
