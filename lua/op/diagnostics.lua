local lazyrequire = require('op.lazyrequire').require_on_index
-- aliasing require like this keeps type intelligence
-- and LSP go-to-definition etc. working
local require = lazyrequire
local async = require('op.api.async')
local config = require('op.config')

local M = {}

-- map buf_id to request_id
local request_bufs = {}

M.diagnostics_namespace = vim.api.nvim_create_namespace('OpBufferAnalysis')

function M.analyze_buffer(buf, manual)
  buf = buf or 0 -- default to current buffer
  local cfg = config.get_config_immutable().secret_detection_diagnostics
  if (cfg.disabled and not manual) or vim.tbl_contains(cfg.disabled_filetypes, vim.api.nvim_buf_get_option(buf, 'filetype')) then
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
        linenr = linenr,
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

    local diagnostics = vim.tbl_map(function(result)
      -- specify type for LSP help
      ---@type OpLineDiagnostic
      result = result or {}
      return {
        bufnr = buf,
        lnum = result.line - 1,
        col = result.col_start,
        end_col = result.col_end,
        message = string.format('Hard-coded %s detected', result.secret_type or 'secret'),
        severity = cfg.severity,
        source = 'op.nvim',
      }
    end, results)
    vim.diagnostic.set(M.diagnostics_namespace, buf, diagnostics)
  end)
  request_bufs[buf] = request_id

  if #line_requests > 0 then
    local requests_json = vim.json.encode(line_requests)
    vim.fn.OpAnalyzeBuffer(request_id, requests_json)
  else
    vim.diagnostic.reset(M.diagnostics_namespace, buf)
  end
end

function M.reset()
  vim.diagnostic.reset(M.diagnostics_namespace)
end

return M
