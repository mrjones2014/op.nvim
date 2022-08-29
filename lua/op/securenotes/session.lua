local M = {}

---@class EditSession
---@field uuid string
---@field vault_uuid string

---Map buf_id={ note_uuid, vault_uuid }
local sessions = {}

function M.new(buf_id, note)
  sessions[tostring(buf_id)] = {
    uuid = note.id,
    vault_uuid = note.vault.id,
  }
end

---@param buf_id number
---@return EditSession
function M.get_for_buf_id(buf_id)
  return sessions[tostring(buf_id)]
end

function M.close_session_for_buf_id(buf_id)
  sessions[tostring(buf_id)] = nil
end

return M
