-- this module used with permission from
-- https://github.com/tjdevries/lazy.nvim/blob/238c1b9a661947b864a7d103f9d6b1f376c3b72f/lua/lazy.lua

local lazy = {}

--- Require on index.
---
--- Will only require the module after the first index of a module.
--- Only works for modules that export a table.
lazy.require_on_index = function(require_path)
  return setmetatable({}, {
    __index = function(_, key)
      return require(require_path)[key]
    end,

    __newindex = function(_, key, value)
      require(require_path)[key] = value
    end,
  })
end

return lazy
