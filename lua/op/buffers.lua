local M = {}

function M.create(opts)
  local buf = vim.api.nvim_create_buf(not opts.unlisted, false)
  if buf == 0 then
    return buf
  end

  if not opts then
    return buf
  end

  -- set lines first
  if opts.lines then
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, opts.lines)
  end

  for key, opt in pairs(opts) do
    if key == 'title' or key == 'name' then
      local name = vim.trim(opt)
      vim.api.nvim_buf_set_name(buf, name)
    elseif key == 'readonly' or key == 'modifiable' then
      vim.api.nvim_buf_set_option(buf, 'readonly', true)
      vim.api.nvim_buf_set_option(buf, 'modifiable', false)
    elseif key ~= 'lines' and key ~= 'unlisted' then
      vim.api.nvim_buf_set_option(buf, key, opt)
    end
  end

  vim.api.nvim_buf_set_option(buf, 'swapfile', false)

  return buf
end

function M.autocmds(autocmds)
  for _, au in ipairs(autocmds) do
    -- separate out numeric keys from string keys
    local options = {}
    for key, value in pairs(au) do
      if type(key) == 'string' then
        options[key] = value
      end
    end
    vim.api.nvim_create_autocmd(au[1], options)
  end
end

function M.update_lines(buf, lines)
  local readonly = vim.api.nvim_buf_get_option(buf, 'readonly')
  local modifiable = vim.api.nvim_buf_get_option(buf, 'modifiable')
  vim.api.nvim_buf_set_option(buf, 'readonly', false)
  vim.api.nvim_buf_set_option(buf, 'modifiable', true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, 'readonly', readonly)
  vim.api.nvim_buf_set_option(buf, 'modifiable', modifiable)
end

return M
