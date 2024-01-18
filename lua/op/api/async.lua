local msg = require('op.msg')

local M = {}

local requests = {}

M.requests = requests

function M.create_request(on_done)
  local success, request_id = pcall(require('op.utils').uuid_short)
  if not success then
    msg.error('Failed to generate request id.')
    return
  end

  requests[request_id] = on_done
  return request_id
end

function M.invalidate_request(request_id)
  requests[request_id] = nil
end

function M.callback(request_id, json, err)
  if err ~= nil and err ~= vim.NIL then
    msg.error(tostring(err))
  end

  if type(json) == 'string' then
    local callbackfn = requests[request_id]
    if type(callbackfn) == 'function' then
      local fn = callbackfn
      requests[request_id] = nil
      fn(json)
    end
  else
    vim.notify(string.format('[op.nvim async callback]: expected json string, got %s', type(json)))
  end
end

return M
