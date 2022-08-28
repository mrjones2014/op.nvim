# Contributing

## Architecture

This plugin is built using a [remote plugin](https://neovim.io/doc/user/remote_plugin.html) written in Go
(using [Neovim's official Go client](https://github.com/neovim/go-client)).

The main purpose of the remote plugin is to keep your 1Password CLI session alive. Neovim launches
external jobs in a separate
[UNIX session](https://stackoverflow.com/questions/6548823/use-and-meaning-of-session-and-process-group-in-unix/6553076#6553076),
which means running the 1Password CLI through Neovim's built-in jobs control API would result
in having to re-authenticate for every single command. Having a remote plugin allows the Go backend
to be a long-running process, keeping your 1Password CLI session alive.

Additionally, since Lua does not have a proper [regular expression](https://en.wikipedia.org/wiki/Regular_expression)
engine, the Go backend handles detecting field and item type designations.

## Development Environment

This plugin does not support Windows since I do not use Windows and therefore cannot test
on Windows, however I would happily accept Pull Requests adding Linux support as long as the
PR comes with a commitment to ongoing maintenance for Windows support.

This project has two development dependencies:

- [Make](https://www.gnu.org/software/make/) (preinstalled on MacOS and Linux)
- [Go](https://go.dev/)

Additionally, this plugin requires Neovim version 0.6.0 or greater (specifically, it depends on the `vim.ui.*` APIs).

Once you have those installed, the first thing you should do is run `make setup-hooks` which will
set up some git hooks for automatically rebuilding the Go backend on commit when there are changes
to Go source files.

To build and install the Go backend, you can simply run `make`. This will cross-compile the Go backend
to all platforms, and install the correct binary for your host platform into the plugin's runtime path.

If you ever update the function handlers found in `handlers.go`, or the function signature of any of the
handler functions, you will need to run `make update-remote-plugin-manifest` to update the remote plugin
manifest found in `plugin/op.vim`.
