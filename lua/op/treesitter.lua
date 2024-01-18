local M = {}

local lazyrequire = require('op.lazyrequire').require_on_index
-- aliasing require like this keeps type intelligence
-- and LSP go-to-definition etc. working
local require = lazyrequire

local utils = require('op.utils')

local treesitter_string_nodes = {
  go = 'interpreted_string_literal',
  rust = 'string_literal',
  swift = 'line_str_text',
  dockerfile = { 'double_quoted_string', 'unquoted_string' },
  dart = 'string_literal',
  kotlin = 'line_string_literal',
  java = 'string_literal',
  zig = 'STRINGLITERALSINGLE',
  default = 'string',
}

local function build_queries()
  local node_name = treesitter_string_nodes[vim.bo.filetype] or treesitter_string_nodes.default

  if type(node_name) == 'string' then
    return { vim.treesitter.query.parse(vim.bo.filetype, string.format('(%s) @strings', node_name)) }
  end

  return vim.tbl_map(function(query)
    return vim.treesitter.query.parse(vim.bo.filetype, string.format('(%s) @strings', query))
  end, node_name)
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

  -- sometimes treesitter gives us the internal string value
  return str
end

---Get all strings in the current buffer
function M.get_all_strings()
  local good_query, queries = pcall(build_queries)
  if not good_query then
    return nil
  end

  local parser = vim.treesitter.get_parser(0)
  local ast = parser:parse()[1]
  local root = ast:root()
  local strings = {}
  for _, query in pairs(queries) do
    for _, node in query:iter_captures(root, 0) do ---@diagnostic disable-line: missing-parameter
      table.insert(strings, extract_string_value(vim.treesitter.get_node_text(node, 0)))
    end
  end

  return utils.dedup_list(strings)
end

return M
