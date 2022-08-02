local JOB_TIMEOUT = 5000

local global_args = {
  '--cache',
  '--no-color',
}

local OP_COMMANDS = {
  account = {
    'add',
    'get',
    'list',
    'forget',
  },
  item = {
    'create',
    'get',
    'edit',
    'delete',
    'list',
    'share',
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
  return function(args)
    args = args or {}
    local full_cmd_args = vim.list_extend(vim.deepcopy(full_cmd), vim.list_extend(vim.deepcopy(global_args), args))
    table.insert(full_cmd_args, 1, 'op')

    local output = non_empty_values(vim.fn.systemlist(full_cmd_args))
    local exit_code = vim.deepcopy(vim.v.shell_error or 0)
    if exit_code ~= 0 then
      -- non-zero exit code, return output in stderr position
      return {}, output, exit_code
    else
      -- zero exit code, return output in stdout position
      return output, {}, exit_code
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

return build_api(OP_COMMANDS)
