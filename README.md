# op.nvim

1Password for Neovim! Create items using strings from the current buffer as fields,
and insert item reference URIs (e.g. `op://vault-name/item-name/field-name`)
directly from Neovim.

![op.nvim demo gif](https://user-images.githubusercontent.com/8648891/182436845-cc0ce2d8-27ea-4fc9-b7d0-73be0a9473a9.gif)

## Usage

`packer.nvim`

```lua
use({ 'mrjones2014/op.nvim' })
```

`vim-plug`

```VimL
Plug 'mrjones2014/op.nvim'
```

No other setup is required, however there are a few settings you can change if needed.
Settings can be changed via the Lua API, default settings are shown below:

```lua
require('op').setup({
  -- you can change this to a full path if `op`
  -- is not on your $PATH
  op_cli_path = 'op',
  -- set an account UUID to use a specific account
  -- can be changed by calling `require('op').setup()`
  -- again passing a new value for `account_uuid`
  account_uuid = nil,
  -- global_args accepts any arguments
  -- listed under "Global Flags" in
  -- `op --help` output. For `--account`,
  -- it is recommended to use the
  -- `config.account_uuid` config option
  -- instead, as it can be more easily changed
  -- if needed.
  global_args = {
    -- use the item cache
    '--cache',
    -- print output with no color, since we
    -- are just binding it to Lua functions
    '--no-color',
  }
})
```

**The `require('op').setup()` function is idempotent** (i.e. can be called multiple times without side effects), so you can
use it to change accounts by updating the value of the `account_uuid` configuration.

## Commands

| Command     | Description                                                     |
| ----------- | --------------------------------------------------------------- |
| `:OpInsert` | Insert an item reference at current cursor position             |
| `:OpCreate` | Create a new item using strings in the current buffer as fields |
| `:OpOpen`   | Open an item in the 1Password 8 desktop app                     |
