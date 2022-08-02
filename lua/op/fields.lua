local M = {}

M.FIELD_TYPE_PATTERNS = {
  email = {
    id = 'email',
    field = 'username',
    type = 'email',
    pattern = '^[%w.]+@%w+%.%w+$',
  },
  url = {
    id = 'url',
    field = 'url',
    type = 'url',
    pattern = 'http[s]*://[^ >,;]+',
  },
}

function M.detect_field_type(str)
  for _, data in pairs(M.FIELD_TYPE_PATTERNS) do
    if string.match(str, data.pattern) then
      return data.id
    end
  end
end

return M
