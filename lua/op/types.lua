--- types This module just provides type annotations for the Lua language server
--- to provide better help in completions and signature help. Provides no functionality.

-- luacheck: push ignore 211

-- Diagnostic request and response types

---@class OpLineDiagnostic
---@field line number
---@field col_start number
---@field col_end number
---@field secret_type string
---@field buf number|nil
---@field file string|nil
local OpLineDiagnostic

---@class OpLineDiagnosticRequest
---@field linenr number
---@field text string
local OpLineDiagnosticRequest

-- CLI API types

---`args` is a list-like table of CLI arguments, with one optional configuration field: `async: boolean`.
---`async` defaults to false, you can set `{ async = true, ... }` to run the CLI asynchronously.
---@alias OpApiFunc fun(args:table|nil, on_done:fun(stdout:table, stderr:table, exit_code:number)|nil)

---@class OpAccountApi
---@field add OpApiFunc
---@field get OpApiFunc
---@field list OpApiFunc
---@field forget OpApiFunc
local AccountApi

---@class ConnectGroupApi
---@field grant OpApiFunc
---@field revoke OpApiFunc
local ConnectGroupApi

---@class ConnectServerApi
---@field create OpApiFunc
---@field get OpApiFunc
---@field edit OpApiFunc
---@field delete OpApiFunc
---@field list OpApiFunc
local ConnectServerApi

---@class ConnectTokenApi
---@field create OpApiFunc
---@field edit OpApiFunc
---@field delete OpApiFunc
---@field list OpApiFunc
local ConnectTokenApi

---@class ConnectVaultApi
---@field grant OpApiFunc
---@field revoke OpApiFunc
local ConnectVaultApi

---@class OpConnectApi
---@field group ConnectGroupApi
---@field server ConnectServerApi
---@field token ConnectTokenApi
---@field vault ConnectVaultApi
local ConnectApi

---@class OpDocumentApi
---@field create OpApiFunc
---@field get OpApiFunc
---@field edit OpApiFunc
---@field delete OpApiFunc
---@field list OpApiFunc
local DocumentApi

---@class OpEventsApi
---@field create OpApiFunc
local EventsApi

---@class GroupUserApi
---@field grant OpApiFunc
---@field revoke OpApiFunc
---@field list OpApiFunc
local GroupUserApi

---@class OpGroupApi
---@field user GroupUserApi
---@field create OpApiFunc
---@field get OpApiFunc
---@field edit OpApiFunc
---@field delete OpApiFunc
---@field list OpApiFunc
local GroupApi

---@class OpItemApi
---@field create OpApiFunc
---@field get OpApiFunc
---@field edit OpApiFunc
---@field delete OpApiFunc
---@field list OpApiFunc
---@field share OpApiFunc
local ItemApi

---@class OpUserApi
---@field create OpApiFunc
---@field get OpApiFunc
---@field edit OpApiFunc
---@field delete OpApiFunc
---@field list OpApiFunc
---@field provision OpApiFunc
---@field confirm OpApiFunc
---@field suspend OpApiFunc
---@field reactivate OpApiFunc
local UserApi

---@class OpVaultApi
---@field create OpApiFunc
---@field get OpApiFunc
---@field edit OpApiFunc
---@field delete OpApiFunc
---@field list OpApiFunc
local VaultApi

---@class OpApi
---@field inject OpApiFunc
---@field read OpApiFunc
---@field run OpApiFunc
---@field signin OpApiFunc
---@field signout OpApiFunc
---@field update OpApiFunc
---@field whoami OpApiFunc
---@field account OpAccountApi
---@field connect OpConnectApi
---@field document OpDocumentApi
---@field eventsApi OpEventsApi
---@field group OpGroupApi
---@field item OpItemApi
---@field user OpUserApi
---@field vault OpVaultApi
local OpApi -- luacheck: ignore 221

-- luacheck: pop

return OpApi
