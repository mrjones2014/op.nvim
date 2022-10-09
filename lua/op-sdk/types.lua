--- types This module just provides type annotations for the Lua language server
--- to provide better help in completions and signature help. Provides no Backendality.

-- CLI API types

---SDK backend. Takes full command as a list-like table of arguments, and handles execution.
---@alias Backend fun(args:string[], ...): any

---@class AccountCli
---@field add Backend
---@field get Backend
---@field list Backend
---@field forget Backend
local AccountCli

---@class ConnectGroupCli
---@field grant Backend
---@field revoke Backend
local ConnectGroupCli

---@class ConnectServerCli
---@field create Backend
---@field get Backend
---@field edit Backend
---@field delete Backend
---@field list Backend
local ConnectServerCli

---@class ConnectTokenCli
---@field create Backend
---@field edit Backend
---@field delete Backend
---@field list Backend
local ConnectTokenCli

---@class ConnectVaultCli
---@field grant Backend
---@field revoke Backend
local ConnectVaultCli

---@class ConnectCli
---@field group ConnectGroupCli
---@field server ConnectServerCli
---@field token ConnectTokenCli
---@field vault ConnectVaultCli
local ConnectCli

---@class DocumentCli
---@field create Backend
---@field get Backend
---@field edit Backend
---@field delete Backend
---@field list Backend
local DocumentCli

---@class EventsCli
---@field create Backend
local EventsCli

---@class GroupUserCli
---@field grant Backend
---@field revoke Backend
---@field list Backend
local GroupUserCli

---@class GroupCli
---@field user GroupUserCli
---@field create Backend
---@field get Backend
---@field edit Backend
---@field delete Backend
---@field list Backend
local GroupCli

---@class ItemCli
---@field create Backend
---@field get Backend
---@field edit Backend
---@field delete Backend
---@field list Backend
---@field share Backend
local ItemCli

---@class UserCli
---@field create Backend
---@field get Backend
---@field edit Backend
---@field delete Backend
---@field list Backend
---@field provision Backend
---@field confirm Backend
---@field suspend Backend
---@field reactivate Backend
local UserCli

---@class VaultCli
---@field create Backend
---@field get Backend
---@field edit Backend
---@field delete Backend
---@field list Backend
local VaultCli

---@class EventsApi
---@field create Backend
local EventsApi

---@class Cli
---@field inject Backend
---@field read Backend
---@field run Backend
---@field signin Backend
---@field signout Backend
---@field update Backend
---@field whoami Backend
---@field account AccountCli
---@field connect ConnectCli
---@field document DocumentCli
---@field eventsCli EventsApi
---@field group GroupCli
---@field item ItemCli
---@field user UserCli
---@field vault VaultCli
local Cli

return Cli
