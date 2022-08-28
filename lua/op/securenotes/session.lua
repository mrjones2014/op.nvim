local M = {}

---Map buf_id={ note_uuid, vault_uuid }
local sessions = {}

function M.new(buf_id, note)
  sessions[tostring(buf_id)] = {
    uuid = note.id,
    vault_uuid = note.vault.id,
  }
end

function M.get_for_buf_id(buf_id)
  return sessions[tostring(buf_id)]
end

return M
