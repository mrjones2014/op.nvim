--- types This module just provides type annotations for the Lua language server
--- to provide better help in completions and signature help. Provides no functionality.

---@class AccountApi
---@field add fun(args:table|nil)
---@field get fun(args:table|nil)
---@field list fun(args:table|nil)
---@field forget fun(args:table|nil)
local AccountApi

---@class ConnectGroupApi
---@field grant fun(args:table|nil)
---@field revoke fun(args:table|nil)
local ConnectGroupApi

---@class ConnectServerApi
---@field create fun(args:table|nil)
---@field get fun(args:table|nil)
---@field edit fun(args:table|nil)
---@field delete fun(args:table|nil)
---@field list fun(args:table|nil)
local ConnectServerApi

---@class ConnectTokenApi
---@field create fun(args:table|nil)
---@field edit fun(args:table|nil)
---@field delete fun(args:table|nil)
---@field list fun(args:table|nil)
local ConnectTokenApi

---@class ConnectVaultApi
---@field grant fun(args:table|nil)
---@field revoke fun(args:table|nil)
local ConnectVaultApi

---@class ConnectApi
---@field group ConnectGroupApi
---@field server ConnectServerApi
---@field token ConnectTokenApi
---@field vault ConnectVaultApi
local ConnectApi

---@class DocumentApi
---@field create fun(args:table|nil)
---@field get fun(args:table|nil)
---@field edit fun(args:table|nil)
---@field delete fun(args:table|nil)
---@field list fun(args:table|nil)
local DocumentApi

---@class EventsApi
---@field create fun(args:table|nil)
local EventsApi

---@class GroupUserApi
---@field grant fun(args:table|nil)
---@field revoke fun(args:table|nil)
---@field list fun(args:table|nil)
local GroupUserApi

---@class GroupApi
---@field user GroupUserApi
---@field create fun(args:table|nil)
---@field get fun(args:table|nil)
---@field edit fun(args:table|nil)
---@field delete fun(args:table|nil)
---@field list fun(args:table|nil)
local GroupApi

---@class ItemApi
---@field create fun(args:table|nil)
---@field get fun(args:table|nil)
---@field edit fun(args:table|nil)
---@field delete fun(args:table|nil)
---@field list fun(args:table|nil)
---@field share fun(args:table|nil)
local ItemApi

---@class UserApi
---@field create fun(args:table|nil)
---@field get fun(args:table|nil)
---@field edit fun(args:table|nil)
---@field delete fun(args:table|nil)
---@field list fun(args:table|nil)
---@field provision fun(args:table|nil)
---@field confirm fun(args:table|nil)
---@field suspend fun(args:table|nil)
---@field reactivate fun(args:table|nil)
local UserApi

---@class VaultApi
---@field create fun(args:table|nil)
---@field get fun(args:table|nil)
---@field edit fun(args:table|nil)
---@field delete fun(args:table|nil)
---@field list fun(args:table|nil)
local VaultApi

---@class Api
---@field inject fun(args:table|nil)
---@field read fun(args:table|nil)
---@field run fun(args:table|nil)
---@field signin fun(args:table|nil)
---@field signout fun(args:table|nil)
---@field update fun(args:table|nil)
---@field whoami fun(args:table|nil)
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
