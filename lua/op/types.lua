--- types This module just provides type annotations for the Lua language server
--- to provide better help in completions and signature help. Provides no functionality.

-- Diagnostic request and response types

---@class OpLineDiagnostic
---@field line number
---@field col_start number
---@field col_end number
---@field secret_type string
local OpLineDiagnostic

---@class OpLineDiagnosticRequest
---@field linenr number
---@field text string
local OpLineDiagnosticRequest

-- CLI API types

---`args` is a list-like table of CLI arguments, with one optional configuration field: `async: boolean`.
---`async` defaults to false, you can set `{ async = true, ... }` to run the CLI asynchronously.
---@alias ApiFunc fun(args:table|nil, on_done:fun(stdout:table, stderr:table, exit_code:number)|nil)

---@class AccountApi
---@field add ApiFunc
---@field get ApiFunc
---@field list ApiFunc
---@field forget ApiFunc
local AccountApi

---@class ConnectGroupApi
---@field grant ApiFunc
---@field revoke ApiFunc
local ConnectGroupApi

---@class ConnectServerApi
---@field create ApiFunc
---@field get ApiFunc
---@field edit ApiFunc
---@field delete ApiFunc
---@field list ApiFunc
local ConnectServerApi

---@class ConnectTokenApi
---@field create ApiFunc
---@field edit ApiFunc
---@field delete ApiFunc
---@field list ApiFunc
local ConnectTokenApi

---@class ConnectVaultApi
---@field grant ApiFunc
---@field revoke ApiFunc
local ConnectVaultApi

---@class ConnectApi
---@field group ConnectGroupApi
---@field server ConnectServerApi
---@field token ConnectTokenApi
---@field vault ConnectVaultApi
local ConnectApi

---@class DocumentApi
---@field create ApiFunc
---@field get ApiFunc
---@field edit ApiFunc
---@field delete ApiFunc
---@field list ApiFunc
local DocumentApi

---@class EventsApi
---@field create ApiFunc
local EventsApi

---@class GroupUserApi
---@field grant ApiFunc
---@field revoke ApiFunc
---@field list ApiFunc
local GroupUserApi

---@class GroupApi
---@field user GroupUserApi
---@field create ApiFunc
---@field get ApiFunc
---@field edit ApiFunc
---@field delete ApiFunc
---@field list ApiFunc
local GroupApi

---@class ItemApi
---@field create ApiFunc
---@field get ApiFunc
---@field edit ApiFunc
---@field delete ApiFunc
---@field list ApiFunc
---@field share ApiFunc
local ItemApi

---@class UserApi
---@field create ApiFunc
---@field get ApiFunc
---@field edit ApiFunc
---@field delete ApiFunc
---@field list ApiFunc
---@field provision ApiFunc
---@field confirm ApiFunc
---@field suspend ApiFunc
---@field reactivate ApiFunc
local UserApi

---@class VaultApi
---@field create ApiFunc
---@field get ApiFunc
---@field edit ApiFunc
---@field delete ApiFunc
---@field list ApiFunc
local VaultApi

---@class Api
---@field inject ApiFunc
---@field read ApiFunc
---@field run ApiFunc
---@field signin ApiFunc
---@field signout ApiFunc
---@field update ApiFunc
---@field whoami ApiFunc
---@field account AccountApi
---@field connect ConnectApi
---@field document DocumentApi
---@field eventsApi EventsApi
---@field group GroupApi
---@field item ItemApi
---@field user UserApi
---@field vault VaultApi
local Api

return Api
