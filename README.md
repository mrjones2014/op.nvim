# op.nvim

1Password for Neovim! Create items using strings from the current buffer as fields,
and insert item reference URIs (e.g. `op://vault-name/item-name/field-name`)
directly from Neovim.

![op.nvim demo gif](https://github.com/mrjones2014/demo-gifs/raw/master/op-nvim-plugin.gif)

## Usage

`packer.nvim`

```lua
use({ 'mrjones2014/op.nvim', run = 'make install' })
```

`vim-plug`

```VimL
Plug 'mrjones2014/op.nvim', { 'do': 'make install' }
```

No other setup is required, however there are a few settings you can change if needed.
See [Configuration](#configuration)

## Configuration

Configuration can be set by calling `require('op').setup(config_table)`.

**The `require('op').setup()` function is idempotent** (i.e. can be called multiple times without side effects).

```lua
require('op').setup({
  -- you can change this to a full path if `op`
  -- is not on your $PATH
  op_cli_path = 'op',
  -- global_args accepts any arguments
  -- listed under "Global Flags" in
  -- `op --help` output.
  global_args = {
    -- use the item cache
    '--cache',
    -- print output with no color, since we
    -- are just binding it to Lua functions
    '--no-color',
  }
})
```

## Commands

| Command     | Description                                                     |
| ----------- | --------------------------------------------------------------- |
| `:OpInsert` | Insert an item reference at current cursor position             |
| `:OpCreate` | Create a new item using strings in the current buffer as fields |
| `:OpOpen`   | Open an item in the 1Password 8 desktop app                     |
| `:OpSignin` | Choose a 1Password account to sign in with                      |
| `:OpWhoami` | Check which 1Password account you are currently signed in with  |
