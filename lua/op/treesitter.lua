local M = {}

local utils = require('op.utils')

local function build_query()
  if vim.bo.filetype == 'go' then
    return vim.treesitter.query.parse_query(vim.bo.filetype, [[(interpreted_string_literal) @strings]])
  end

  return vim.treesitter.query.parse_query(vim.bo.filetype, [[(string) @strings]])
end

local function extract_string_value(str)
  -- lua raw strings
  if utils.str_has_prefix(str, '[[') and utils.str_has_suffix(str, ']]') then
    return str:sub(3, -3)
  end

  -- rust raw strings
  if utils.str_has_prefix(str:lower(), 'r"') and utils.str_has_suffix(str, '"') then
    return str:sub(3, -2)
  end

  -- C# raw strings
  if utils.str_has_prefix(str, '@"') and utils.str_has_suffix(str, '"') then
    return str:sub(3, -2)
  end

  -- python raw strings
  if vim.bo.filetype == 'python' and utils.str_has_prefix(str, '"""') and utils.str_has_prefix('"""') then
    return str:sub(4, -4)
  end

  -- JS template strings
  if utils.str_has_prefix(str, '`') and utils.str_has_suffix(str, '`') then
    return str:sub(2, -2)
  end

  -- normal single quoted strings
  if utils.str_has_prefix(str, "'") and utils.str_has_suffix(str, "'") then
    return str:sub(2, -2)
  end

  -- normal double quoted strings
  if utils.str_has_prefix(str, '"') and utils.str_has_suffix(str, '"') then
    return str:sub(2, -2)
  end
end

---Get all strings in the current buffer
function M.get_all_strings()
  local query = build_query()
  local parser = vim.treesitter.get_parser(0)
  local ast = parser:parse()[1]
  local root = ast:root()
  local strings = {}
  for _, node in query:iter_captures(root, 0) do
    table.insert(strings, extract_string_value(vim.treesitter.query.get_node_text(node, 0)))
  end

  return utils.dedup_list(strings)
end

return M
