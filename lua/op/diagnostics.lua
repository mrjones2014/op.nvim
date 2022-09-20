local lazyrequire = require('op.lazyrequire').require_on_index
-- aliasing require like this keeps type intelligence
-- and LSP go-to-definition etc. working
local require = lazyrequire
local async = require('op.api.async')
local config = require('op.config')

local M = {}

-- map buf_id to request_id
local request_bufs = {}

local function set_buf_diagnostics(diagnostics)
  local buf_diagnostics = {}

  -- map diagnostics to the correct buffers
  for _, diagnostic in ipairs(diagnostics) do
    buf_diagnostics[diagnostic.bufnr] = buf_diagnostics[diagnostic.bufnr] or {}
    table.insert(buf_diagnostics[diagnostic.bufnr], diagnostic)
  end

  -- set diagnostics on buffers
  for bufnr, diagnostics_for_buf in pairs(buf_diagnostics) do
    pcall(vim.diagnostic.set, M.diagnostics_namespace, bufnr, diagnostics_for_buf)
  end
end

local function convert_diagnostics(line_diagnostics, buf)
  local cfg = config.get_config_immutable().secret_detection_diagnostics
  local file_bufs = {}
  local original_buf = vim.api.nvim_get_current_buf()
  if not buf then
    -- open unlisted buffers for all files
    vim.tbl_map(function(line_diagnostic)
      if file_bufs[line_diagnostic.file] then
        return
      end

      file_bufs[line_diagnostic.file] = vim.api.nvim_create_buf(true, false)
      vim.api.nvim_buf_set_name(file_bufs[line_diagnostic.file], line_diagnostic.file)
      vim.api.nvim_set_current_buf(file_bufs[line_diagnostic.file])
      vim.cmd('e')
    end, line_diagnostics)
    vim.api.nvim_set_current_buf(original_buf)
  end
  return vim.tbl_map(function(result)
    -- specify type for LSP help
    ---@type OpLineDiagnostic
    result = result or {}
    return {
      bufnr = buf or file_bufs[result.file],
      lnum = result.line,
      col = result.col_start,
      end_col = result.col_end,
      message = string.format('Hard-coded %s detected', result.secret_type or 'secret'),
      severity = cfg.severity,
      source = 'op.nvim',
    }
  end, line_diagnostics)
end

M.diagnostics_namespace = vim.api.nvim_create_namespace('OpBufferAnalysis')

function M.analyze_buffer(buf, manual)
  buf = buf or 0 -- default to current buffer
  local cfg = config.get_config_immutable().secret_detection_diagnostics
  if
    (cfg.disabled and not manual)
    or vim.tbl_contains(cfg.disabled_filetypes, vim.api.nvim_buf_get_option(buf, 'filetype'))
  then
    return
  end

  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  if #lines > cfg.max_file_lines then
    vim.diagnostic.reset(M.diagnostics_namespace, buf)
    return
  end
  local line_requests = {}
  for linenr, line in ipairs(lines) do
    if #(vim.trim(line)) > 0 then
      table.insert(line_requests, {
        bufnr = buf,
        linenr = linenr - 1, -- lists in Lua are 1-based index
        text = line,
      })
    end
  end

  -- invalidate any still-running requests
  if request_bufs[buf] then
    async.invalidate_request(request_bufs[buf])
    request_bufs[buf] = nil
  end

  local request_id = async.create_request(function(json)
    -- mark request completed
    request_bufs[buf] = nil

    if #(json or '') == 0 then
      -- removes all diagnostics in current buffer for our namespace
      vim.diagnostic.reset(M.diagnostics_namespace, buf)
      return
    end

    ---@type OpLineDiagnostic[]
    local results = vim.json.decode(json)
    if #results == 0 then
      -- removes all diagnostics in current buffer for our namespace
      vim.diagnostic.reset(M.diagnostics_namespace, buf)
      return
    end

    set_buf_diagnostics(convert_diagnostics(results, buf))
  end)
  request_bufs[buf] = request_id

  if #line_requests > 0 then
    local requests_json = vim.json.encode(line_requests)
    vim.fn.OpAnalyzeBuffer(request_id, requests_json)
  else
    vim.diagnostic.reset(M.diagnostics_namespace, buf)
  end
end

function M.analyze_workspace()
  local cfg = config.get_config_immutable().secret_detection_diagnostics.workspace_diagnostics
  local ignore_patterns = cfg.ignore_patterns
  local request_id = async.create_request(function(json)
    if not json or #json == 0 then
      return
    end

    local workspace_diagnostics = vim.json.decode(json)
    set_buf_diagnostics(convert_diagnostics(workspace_diagnostics))
    vim.defer_fn(function()
      cfg.on_done()
    end, 1)
  end)
  vim.fn.OpAnalyzeWorkspace(request_id, unpack(ignore_patterns))
end

function M.reset()
  vim.diagnostic.reset(M.diagnostics_namespace)
end

return M
