package main

import (
	"github.com/neovim/go-client/nvim/plugin"
)

var PluginInstance *plugin.Plugin

func main() {
	plugin.Main(func(p *plugin.Plugin) error {
		PluginInstance = p
		for _, handlerDef := range Handlers {
			p.HandleFunction(handlerDef.Options, handlerDef.Handler)
		}
		return nil
	})
}
