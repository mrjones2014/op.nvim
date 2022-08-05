# op.nvim

1Password for Neovim! Create items using strings from the current buffer as fields,
and insert item reference URIs (e.g. `op://vault-name/item-name/field-name`)
directly from Neovim. Works with biometric unlock!

![op.nvim demo gif](https://github.com/mrjones2014/demo-gifs/raw/master/op-nvim-plugin.gif)
<sup>
The UI is handled by `vim.ui.input()` and `vim.ui.select()`;
I recommend pairing this with [Telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)
and [dressing.nvim](https://github.com/stevearc/dressing.nvim) for nice `vim.ui.*` handlers.
</sup>

<hr>

Jump to: [Install](#install), [Configuration](#configuration), [Commands](#commands), [Features](#features)

<hr>

## Install

`packer.nvim`

```lua
use({ 'mrjones2014/op.nvim', run = 'make install' })
```

`vim-plug`

```VimL
Plug 'mrjones2014/op.nvim', { 'do': 'make install' }
```

No other setup is required, however there are a few settings you can change if needed.
See [Configuration](#configuration).

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
    -- aren't viewing the output directly anyway
    '--no-color',
  },
  -- Update the statusline component on startup.
  -- Note that if you have biometric authentication
  -- enabled, this will prompt you for authentication
  -- and start a session on setup.
  update_statusline_on_start = false,
})
```

## Commands

| Command      | Description                                                     |
| ------------ | --------------------------------------------------------------- |
| `:OpInsert`  | Insert an item reference at current cursor position             |
| `:OpCreate`  | Create a new item using strings in the current buffer as fields |
| `:OpOpen`    | Open an item in the 1Password 8 desktop app                     |
| `:OpSignin`  | Choose a 1Password account to sign in with                      |
| `:OpSignout` | Sign out of 1Password CLI                                       |
| `:OpWhoami`  | Check which 1Password account you are currently signed in with  |

## Features

- Biometric unlock! Unlock 1Password with fingerprint or Apple watch from within Neovim
- Create items from strings in the current buffer
  - If the Treesitter query fails or there's no Treesitter parser for the current filetype, fallback to manual value input (if a Treesitter parser exists, please open an issue or PR so we can get the right query added!)
- Infer default field and item names based on field value patterns
- Open an item in the 1Password 8 desktop app
- Insert an item reference URI (e.g. `op://vault-name/item-name/field-name`)
- Switch between multiple 1Password accounts
- Statusline component (See [Statusline](#statusline))

### Statusline

`op.nvim` provides a statusline component as a function that returns a string.
The statusline component shows either "1Password: No active session" when you do not
have an active 1Password CLI session, or "1Password: Account Name" after you've started
a session. See screenshots below.

![statusline when not signed in](https://github.com/mrjones2014/demo-gifs/raw/master/op-statusline-not-signed-in.png)

![statusline when signed in](https://github.com/mrjones2014/demo-gifs/raw/master/op-nvim-statusline-signed-in.png)
