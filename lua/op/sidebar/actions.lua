local M = {}

local lazyrequire = require('op.lazyrequire').require_on_index
-- aliasing require like this keeps type intelligence
-- and LSP go-to-definition etc. working
local require = lazyrequire
local securenotes = require('op.securenotes')
local utils = require('op.utils')
local msg = require('op.msg')
local op = require('op.api')

---If the item is a login and has a URL, open and fill.
---If the item is a Secure Note, open in Secure Notes editor.
---Otherwise, open in 1Password 8 desktop app.
---@param sidebar_item table
function M.default_open(sidebar_item)
  if sidebar_item.data.category == 'SECURE_NOTE' then
    securenotes.load_secure_note(sidebar_item.data.uuid, sidebar_item.data.vault_uuid)
    return
  end

  if sidebar_item.data.url and #sidebar_item.data.url > 0 then
    utils.open_and_fill(sidebar_item.data.url, sidebar_item.data.uuid)
    return
  end

  M.open_in_desktop_app(sidebar_item)
end

---Open the item in the 1Password 8 desktop app.
---@param sidebar_item table
function M.open_in_desktop_app(sidebar_item)
  local stdout, stderr = op.account.get({ '--format', 'json' })
  if #stderr > 0 then
    msg.error(stderr[1])
  elseif #stdout > 0 then
    local account = vim.json.decode(table.concat(stdout, ''))
    local url = string.format(
      'onepassword://view-item?a=%s&v=%s&i=%s',
      account.id,
      sidebar_item.data.vault_uuid,
      sidebar_item.data.uuid
    )
    utils.open_url(url)
  end
end

---Edit the item in the 1Password 8 desktop app.
---@param sidebar_item table
function M.edit_in_desktop_app(sidebar_item)
  local stdout, stderr = op.account.get({ '--format', 'json' })
  if #stderr > 0 then
    msg.error(stderr[1])
  elseif #stdout > 0 then
    local account = vim.json.decode(table.concat(stdout, ''))
    local url = string.format(
      'onepassword://edit-item?a=%s&v=%s&i=%s',
      account.id,
      sidebar_item.data.vault_uuid,
      sidebar_item.data.uuid
    )
    utils.open_url(url)
  end
end

return M
