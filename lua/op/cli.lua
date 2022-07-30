local JOB_TIMEOUT = 5000

local global_args = {
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
  return function(args, on_stdout, on_stderr)
    args = args or {}
    local full_cmd_args = vim.list_extend(vim.list_extend(vim.list_extend({}, full_cmd), args), global_args)
    table.insert(full_cmd_args, 1, 'op')
    local stdout = {}
    local stderr = {}
    local job_id = vim.fn.jobstart(full_cmd_args, {
      stdout_buffered = true,
      stderr_buffered = true,
      on_stdout = function(_, data)
        stdout = non_empty_values(data)
      end,
      on_stderr = function(_, data)
        stderr = non_empty_values(data)
      end,
    })
    local status = vim.fn.jobwait({ job_id }, 5000)[1]
    -- see :h jobwait
    if status == -1 then
      vim.notify_once(
        'Command with args ' .. vim.inspect(full_cmd_args) .. ' timed out after ' .. (JOB_TIMEOUT / 1000) .. ' seconds'
      )
    end
    if #stdout > 0 and on_stdout then
      on_stdout(stdout)
    end
    if #stderr > 0 and on_stderr then
      on_stderr(stderr)
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
