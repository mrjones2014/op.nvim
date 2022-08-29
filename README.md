<div align="center">

# op.nvim

<!-- panvimdoc-ignore-start -->

![Neovim version](https://img.shields.io/badge/Neovim-0.6-brightgreen?logo=neovim) ![1Password CLI V2](https://img.shields.io/badge/1Password%20CLI-V2-blue?logo=1password) [![GitHub license](https://img.shields.io/github/license/mrjones2014/op.nvim)](https://github.com/mrjones2014/op.nvim/blob/master/LICENSE)

[Prerequisites](#prerequisites) • [Install](#install) • [Configuration](#configuration) • [Commands](#commands) • [Features](#features) • [API](#api)

<!-- panvimdoc-ignore-end -->

</div>

1Password for Neovim! Create items using strings from the current buffer as fields,
and insert item reference URIs (e.g. `op://vault-name/item-name/field-name`)
directly from Neovim. Works with biometric unlock!

<!-- panvimdoc-ignore-start -->

![op.nvim demo gif](https://github.com/mrjones2014/demo-gifs/raw/master/op-nvim-plugin-v2.gif) \
<sup>
The UI is handled by `vim.ui.input()` and `vim.ui.select()`;
I recommend pairing this with [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)
and [dressing.nvim](https://github.com/stevearc/dressing.nvim) for nice `vim.ui.*` handlers.
</sup>

<!-- panvimdoc-ignore-end -->

## Prerequisites

**Required:**

- [1Password CLI v2](https://developer.1password.com/docs/cli/) installed

**Optional, but recommended:**

- [1Password 8 desktop app](https://1password.com/downloads/) (required to use biometric unlock for CLI)
- [Biometric unlock for CLI](https://developer.1password.com/docs/cli/get-started#turn-on-biometric-unlock) enabled (see [Using Token-Based Sessions](#using-token-based-sessions) if you do not use biometric unlock for CLI)
- A Neovim plugin to handle `vim.ui.select()` and `vim.ui.input()` &mdash; I recommend [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) paired with [dressing.nvim](https://github.com/stevearc/dressing.nvim)

### Windows Support

This plugin does not currently support Windows. I don't use Windows so I can't test on Windows.
However, I would happily accept Pull Requests adding Windows support, with a commitment to
ongoing maintenance from the PR author.

## Install

`packer.nvim`

```lua
use({ 'mrjones2014/op.nvim', run = 'make install' })
```

`vim-plug`

```VimL
Plug 'mrjones2014/op.nvim', { 'do': 'make install' }
```

No other setup is required if using biometric unlock for the 1Password CLI,
however there are a few settings you can change if needed. See [Configuration](#configuration).

## Configuration

Configuration can be set by calling `require('op').setup(config_table)`.

**The `require('op').setup()` function is idempotent** (i.e. can be called multiple times without side effects).

```lua
require('op').setup({
  -- you can change this to a full path if `op`
  -- is not on your $PATH
  op_cli_path = 'op',
  -- Whether to sign in on start.
  signin_on_start = false,
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
  -- Use biometric unlock by default,
  -- set this to false and also see
  -- "Using Token-Based Sessions" section
  -- of README.md if you don't use biometric
  -- unlock for CLI.
  biometric_unlock = true,
  -- settings for Secure Notes editor
  secure_notes = {
    -- prefix for buffer names when
    -- editing 1Password Secure Notes
    buf_name_prefix = '1P:',
  }
})
```

### Using Token-Based Sessions

If you do not use biometric unlock for the 1Password CLI, you can use token-based sessions.
**You must run `eval $(op signin)` _before_ launching Neovim** in order for `op.nvim` to be
able to access the session. You also **must** configure `op.nvim` with `biometric_unlock = false`.

## Commands

\* = Asynchronous \
† = Partially asynchronous

- `:OpSignin` \* - Choose a 1Password account to sign in with. Accepts account shorthand, signin address, account UUID, or user UUID as an optional argument.
- `:OpSignout` \* - End your current 1Password CLI session.
- `:OpWhoami` \* - Check which 1Password account your current CLI session is using.
- `:OpCreate` † - Create a new item using strings in the current buffer as fields.
- `:OpOpen` † - Open an item in the 1Password 8 desktop app.
- `:OpInsert` - Insert an item reference at current cursor position.
- `:OpNote` - Find and open a 1Password Secure Note item

## Features

- Biometric unlock! Unlock 1Password with fingerprint or Apple watch from within Neovim
- Create items from strings in the current buffer
  - If the Treesitter query fails or there's no Treesitter parser for the current filetype, fallback to manual value input (if a Treesitter parser exists, please open an issue or PR so we can get the right query added!)
- Infer default field and item names based on field value patterns
- Open an item in the 1Password 8 desktop app
- Insert an item reference URI (e.g. `op://vault-name/item-name/field-name`)
- Switch between multiple 1Password accounts (only works with biometric unlock enabled)
- Secure Notes Editor (See [Secure Notes Editor](#secure-notes-editor))
- Statusline component that updates asynchronously (See [Statusline](#statusline))
- Most commands are partially or fully asynchronous

### Secure Notes Editor

Edit your 1Password Secure Notes items directly in Neovim! Run `:OpNote` to find a Secure Note item (via `vim.ui.select()`)
and open it in a new buffer. The buffer will have `filetype=markdown` so you get Markdown filetype highlighting. Note
that it will also append `.md` in the buffer name &mdash; this is just so that [nvim-web-devicons](https://github.com/kyazdani42/nvim-web-devicons)
will assign the Markdown icon to the buffer, e.g. if you're using [bufferline.nvim](https://github.com/akinsho/bufferline.nvim)
or similar. It will not change the title of your Secure Note in 1Password.

#### Security

The Secure Notes editor **will never write your notes to disk**. It uses a special `buftype` option, `buftype=acwrite`,
which allows `op.nvim` to intercept the `:w` command by setting up an `autocmd BufWriteCmd`, which then allows `op.nvim`
to completely handle "writing" the Secure Note by updating it via the 1Password CLI.

Note that in order to write the contents back to the correct item, `op.nvim` associates buffer IDs with `{ uuid, vault_uuid }` pairs.
**`op.nvim` does not store the note title or anything other than the UUID and vault UUID in the edit session**.

### Statusline

`op.nvim` provides a statusline component as a function that returns a string.
The statusline component updates asynchronously using [goroutines](https://go.dev/tour/concurrency/1),
and will either show "1Password: No active session" when you do not have an active 1Password CLI
session, or "1Password: Account Name" after you've started a session.

<!-- panvimdoc-ignore-start -->

See screenshots below.

![statusline when not signed in](https://github.com/mrjones2014/demo-gifs/raw/master/op-statusline-not-signed-in.png)

![statusline when signed in](https://github.com/mrjones2014/demo-gifs/raw/master/op-nvim-statusline-signed-in.png)

<!-- panvimdoc-ignore-end -->

## API

Part of `op.nvim`'s design includes complete bindings to the CLI that you can use for scripting with Lua. This API
is available in the `op.api` module. This module returns a table that matches the hierarchy of the 1Password CLI commands.
The only exception is that `op events-api` is reformatted as `op.eventsApi`, for obvious reasons. Each command is accessed
as a function that takes the command flags and arguments as a list. The functions all return three values, which are
the `STDOUT` as a list of lines, `STDERR` as a list of lines, and the exit code as a number.
Some examples are below:

```lua
local op = require('op.api')
local stdout, stderr, exit_code = op.signin()
local stdout, stderr, exit_code = op.account.get({ '--format', 'json' })
local stdout, stderr, exit_code = op.item.list({ '--format', 'json' })
local stdout, stderr, exit_code = op.eventsApi.create({ 'SigninEvents', '--features', 'signinattempts', '--expires-in', '1h' })
local stdout, stderr, exit_code = op.connect.server.create({ 'Production', '--vaults', 'Production' })

-- all API functions can be called asynchronously by setting `args.async = true`
-- and passing a callback as a second parameter
op.account.get({ async = true, '--format', 'json' }, function(stdout, stderr, exit_code)
  -- do stuff with stdout, stderr, exit_code
end)
```

If you implement a cool feature using the API, please consider contributing it to this plugin in a PR!

See [lua/op/types.lua](./lua/op/types.lua) for type annotations describing the `require('op.api')` table. This file
should also provide type information and completions when using `lua-language-server`.
