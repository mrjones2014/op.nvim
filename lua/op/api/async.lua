local msg = require('op.msg')

local M = {}

M.requests = {}

function M.create_request(on_done)
  local success, request_id = pcall(require('op.utils').rand_id)
  if not success then
    msg.error('Failed to generate request id.')
    return
  end

  M.requests[request_id] = on_done
  return request_id
end

function M.callback(request_id, json, err)
  if err ~= nil and err ~= vim.NIL then
    msg.error(tostring(err))
  end

  if type(json) == 'string' then
    local callbackfn = M.requests[request_id]
    if type(callbackfn) == 'function' then
      local fn = vim.deepcopy(callbackfn)
      M.requests[request_id] = nil
      fn(json)
    end
  end
end

return M
