local FIELD_TYPE_PATTERNS = {
  {
    id = 'email',
    field = 'email',
    type = 'email',
    pattern = '^[%w.]+@%w+%.%w+$',
  },
  {
    id = 'url',
    field = 'url',
    type = 'url',
    pattern = 'http[s]*://[^ >,;]+',
  },
}

local M = {}

function M.detect_field_type(str)
  for _, data in pairs(FIELD_TYPE_PATTERNS) do
    if string.match(str, data.pattern) then
      return data.id
    end
  end
end

return M
