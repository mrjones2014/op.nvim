local M = {}

local lazyrequire = require('op.lazyrequire').require_on_index
-- aliasing require like this keeps type intelligence
-- and LSP go-to-definition etc. working
local require = lazyrequire

---@type Api
local op = require('op.api')
local config = require('op.config')
local msg = require('op.msg')
local icons = require('op.icons')

local function with_item_overviews(callback)
  local stdout, stderr = op.item.list({ '--format', 'json' })
  if #stdout > 0 then
    callback(vim.json.decode(table.concat(stdout, '')))
  elseif #stderr > 0 then
    msg.error(stderr[1])
  end
end

local function collect_inputs(prompts, callback, outputs)
  outputs = outputs or {}
  if not prompts or #prompts == 0 then
    callback(unpack(outputs))
    return
  end
  local prompt = prompts[1]
  if type(prompt) == 'table' and prompt.find == true then
    with_item_overviews(function(items)
      vim.ui.select(items, {
        prompt = prompt[1],
        format_item = function(item)
          return M.format_item_for_select(item)
        end,
      }, function(selected)
        if not selected then
          return
        end
        table.insert(outputs, selected.id)
        table.remove(prompts, 1)
        vim.schedule(function()
          collect_inputs(prompts, callback, outputs)
        end)
      end)
    end)
  else
    local prompt_str
    if type(prompt) == 'table' then
      prompt_str = prompt[1]
    else
      prompt_str = prompt
    end
    vim.ui.input({ prompt = prompt_str }, function(input)
      table.insert(outputs, input)
      table.remove(prompts, 1)
      vim.schedule(function()
        collect_inputs(prompts, callback, outputs)
      end)
    end)
  end
end

function M.format_item_for_select(item)
  if config.get_config_immutable().use_icons then
    return string.format("%s '%s' in vault '%s'", icons.category_icon(item.category), item.title, item.vault.name)
  end

  return string.format("'%s' in vault '%s'", item.title, item.vault.name)
end

---Get one input per prompt, then call the callback
---with each input as passed as a separate parameter
---to the callback (via `unpack(inputs_tbl)`).
---To use vim.ui.select() on all 1Password items,
---pass the prompt as a table with `find=true`,
---e.g. with_inputs({ 'Select 1Password item' find = true }, 'Field name')
function M.with_inputs(prompts, callback)
  return function(...)
    local prompts_copy = vim.deepcopy(prompts)
    if ... and #... >= #prompts_copy then
      callback(...)
      return
    end

    collect_inputs(prompts_copy, callback, { ... })
  end
end

local function get_field_designation(value)
  local json, _ = vim.fn.OpDesignateField(value)
  if json and json ~= vim.NIL then
    local result = vim.json.decode(json)
    if result == vim.NIL then
      return nil
    end

    return result
  end

  return nil
end

local function select_fields_inner(items, fields, callback, used_items, done)
  fields = fields or {}
  used_items = used_items or {}

  if done then
    return callback(fields)
  end

  local function on_field_value_selected(selected)
    if not selected then
      return select_fields_inner(items, fields, callback, used_items, true)
    end

    table.insert(used_items, selected)

    -- local field_type = opfields.detect_field_type(selected)
    local designation = get_field_designation(selected)
    local input_params = { prompt = 'Field Label' }
    if designation then
      input_params.default = designation.field_title
    end

    vim.schedule(function()
      vim.ui.input(input_params, function(input)
        if not input or #input == 0 then
          msg.error('Field name is required.')
          -- insert invalid field
          table.insert(fields, {})
          return select_fields_inner(items, fields, callback, used_items, true)
        end

        local field = {
          name = input,
          value = selected,
          designation = designation,
        }
        table.insert(fields, field)
        select_fields_inner(items, fields, callback, used_items, false)
      end)
    end)
  end

  -- failed to get strings with treesitter, use vim.ui.input() instead of vim.ui.select()
  if not items then
    vim.ui.input(
      { prompt = 'Enter field value, or close this dialog to finish selecting fields' },
      on_field_value_selected
    )
    return
  end

  items = vim.tbl_filter(function(item)
    return item and #item > 0 and not vim.tbl_contains(used_items, item)
  end, items)

  vim.ui.select(
    items,
    { prompt = 'Select field value, or close this dialog to finish selecting fields' },
    on_field_value_selected
  )
end

function M.with_vault(callback, async)
  local function handler(stdout, stderr)
    if #stdout > 0 then
      local vaults = vim.json.decode(table.concat(stdout, ''))
      vim.ui.select(vaults, {
        prompt = 'Select Vault',
        format_item = function(vault)
          return vault.name
        end,
      }, function(selected)
        if not selected then
          msg.error('Vault is required.')
          return
        end
        callback(selected)
      end)
    elseif #stderr > 0 then
      msg.error(stderr[1])
    end
  end

  if async == true then
    op.vault.list({ async = true, '--format', 'json' }, handler)
  else
    local stdout, stderr = op.vault.list({ '--format', 'json' })
    handler(stdout, stderr)
  end
end

function M.select_fields(items, callback)
  select_fields_inner(items, {}, function(fields)
    if not fields or #fields == 0 then
      msg.error('Item creation cancelled.')
      return
    end

    if
      #vim.tbl_filter(function(field)
        return not field or not field.name or #field.name == 0 or not field.value or #field.value == 0
      end, fields) > 0
    then
      msg.error('One or more fields is missing a name or value, cannot create item.')
      return
    end

    local field_with_item_title_designation = vim.tbl_filter(function(field)
      return field.designation ~= nil and field.designation.item_title and #field.designation.item_title > 0
    end, fields)[1]
    local suggested_title = nil
    if field_with_item_title_designation then
      -- designation.item_title may be empty or nil if
      -- designation.field_type is email, URL, etc.
      -- anything not related to a specific site/service
      suggested_title = field_with_item_title_designation.designation.item_title
    end

    vim.schedule(function()
      vim.ui.input({
        prompt = 'Item Title',
        default = suggested_title,
      }, function(item_title)
        if not item_title or #item_title == 0 then
          msg.error('Item title is required')
          return
        end

        M.with_vault(function(vault)
          if type(callback) == 'function' then
            callback(fields, item_title, vault)
          end
        end)
      end)
    end)
  end)
end

---Not full UUID validation but does
---some quick checks for things that make
---it definitely *not* a UUID such as
---containing spaces or lowercase characters
local function quick_uuid_check(uuid)
  if
    not uuid
    or uuid:match('%s') -- spaces
    or uuid:match('%x') -- hexadecimal digits (\3, \4, etc.)
    or uuid:match('%l') -- lowercase letters
    or uuid:match('%c') -- control chars (\n, \r, \t, etc)
    or uuid:match('%p') -- punctuation characters
    or uuid:match('=') -- equals sign for field assignment statements
    or uuid:match('-') -- hyphens for --flags
  then
    return false
  end

  return true
end

function M.with_account_uuid(callback, opts)
  local global_args = config.get_global_args() or {}
  for idx, arg in pairs(global_args) do
    if arg == '--account' then
      -- next arg should be the account UUID
      local account_uuid = global_args[idx + 1]
      if type(account_uuid) == 'string' and quick_uuid_check(account_uuid) then
        callback(account_uuid)
        return
      else
        -- if arg right after --account is not a UUID string,
        -- get account via `op account get` and return
        break
      end
    end
  end

  local function account_get_handler(stdout, stderr)
    if #stderr > 0 then
      msg.error(stderr[1])
    elseif #stdout > 0 then
      local account = vim.json.decode(table.concat(stdout, ''))
      callback(account.id)
    end
  end

  if opts and opts.async == true then
    op.account.get({ async = true, '--format', 'json' }, account_get_handler)
  else
    local stdout, stderr = op.account.get({ '--format', 'json' })
    account_get_handler(stdout, stderr)
  end
end

---Takes in the stderr output that happens when
---more than one item matches the query,
---returns a table with fields `name` and `id`,
---where `id` is the item UUID
function M.parse_vaults_from_more_than_one_match(output)
  local vaults = {}
  for _, line in pairs(output) do
    line = vim.trim(line)
    local _, vault_start_idx = line:find('" in vault ')
    local _, separator_idx = line:find(':')
    table.insert(
      vaults,
      { name = string.sub(line, vault_start_idx + 1, separator_idx - 1), id = string.sub(line, separator_idx + 2) }
    )
  end

  return vaults
end

---Given stdout as a table of lines,
---parse the JSON and return the `op://` reference
---@param stdout table
---@return string
function M.get_op_reference(stdout)
  local item = vim.json.decode(table.concat(stdout, ''))
  return item.reference
end

---Insert given text at cursor position.
function M.insert_at_cursor(text)
  local pos = vim.api.nvim_win_get_cursor(0)[2]
  local line = vim.api.nvim_get_current_line()
  local new_line = line:sub(0, pos + 1) .. text .. line:sub(pos + 2)
  vim.api.nvim_set_current_line(new_line)
end

function M.str_has_suffix(str, suffix)
  return suffix == '' or str:sub(-#suffix) == suffix
end

function M.str_has_prefix(str, prefix)
  return str:sub(1, #prefix) == prefix
end

---Remove duplicates from list.
---Does not modify in place. Input is immutable.
function M.dedup_list(list)
  local seen = {}
  local result = {}
  for _, val in pairs(list) do
    if not vim.tbl_contains(seen, val) then
      table.insert(result, val)
    end

    table.insert(seen, val)
  end

  return result
end

---Open a 1Password 8 desktop app URL
---@param action "view" | "edit"
function M.find_and_open_desktop_app_url(action)
  if action ~= 'view' and action ~= 'edit' then
    msg.error(string.format("Unsupported URL action '%s'", action))
    return
  end

  local stdout, stderr = op.item.list({ '--format', 'json' })
  if #stderr > 0 then
    msg.error(stderr[1])
  elseif #stdout > 0 then
    local items = vim.json.decode(table.concat(stdout, ''))
    vim.ui.select(items, {
      prompt = 'Select 1Password item',
      format_item = function(item)
        return M.format_item_for_select(item)
      end,
    }, function(item)
      if not item then
        return
      end

      M.with_account_uuid(function(account_uuid)
        if not account_uuid then
          msg.error('Failed to retrieve account UUID')
          return
        end

        local url = string.format('onepassword://%s-item?a=%s&v=%s&i=%s', action, account_uuid, item.vault.id, item.id)
        M.open_url(url)
      end, { async = true })
    end)
  end
end

---Open URL in default handler
function M.open_url(url)
  local cmd = config.get_config_immutable().url_open_command
  if type(cmd) == 'function' then
    cmd = cmd()
  end

  if not cmd then
    msg.error('op.nvim: config.url_open_command must return a string value')
    return
  end

  vim.fn.jobstart({ cmd, url }, { detach = true })
end

local random_seeded = false
local uuid_gen_template = 'xxxxxxxxxxxxxxxxxxxxxxxxxx'

---Generate a short (26 character) random UUID
---@return string the UUID
function M.uuid_short()
  if not random_seeded then
    math.randomseed(tonumber((tostring(os.time())):reverse()) + 0)
    random_seeded = true
  end

  local str, _ = string.gsub(uuid_gen_template, 'x', function()
    local v = math.random(0, 0xf)
    return string.format('%x', v)
  end)

  return str
end

---Given an item URL and an item UUID, open and fill it
---@param url string
---@param uuid string
function M.open_and_fill(url, uuid)
  local key_value = string.format('%s=%s', M.uuid_short(), uuid)
  local url_with_params
  if string.find(url, '?') then
    url_with_params = string.format('%s&%s', url, key_value)
  else
    url_with_params = string.format('%s?%s', url, key_value)
  end

  M.open_url(url_with_params)
end

return M
