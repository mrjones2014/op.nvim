package main

import (
	"github.com/neovim/go-client/nvim/plugin"
)

// A Neovim Remote Plugin handler, with options
type HandlerDefinition struct {
	Options *plugin.FunctionOptions
	Handler interface{}
}

var Handlers = []HandlerDefinition{
	{
		Options: &plugin.FunctionOptions{Name: "OpCmd"},
		Handler: OpCmd,
	},
	{
		Options: &plugin.FunctionOptions{Name: "OpCmdAsync"},
		Handler: OpCmdAsync,
	},
	{
		Options: &plugin.FunctionOptions{Name: "OpSetup"},
		Handler: OpSetup,
	},
	{
		Options: &plugin.FunctionOptions{Name: "OpDesignateField"},
		Handler: OpDesignateField,
	},
	{
		Options: &plugin.FunctionOptions{Name: "OpEnableStatusline"},
		Handler: OpEnableStatusline,
	},
}
