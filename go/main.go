package main

import (
	"github.com/neovim/go-client/nvim/plugin"
)

type CliOutput struct {
	Output     string `json:"output"`
	ReturnCode int    `json:"return_code"`
}

func main() {
	plugin.Main(func(p *plugin.Plugin) error {
		for _, handlerDef := range Handlers {
			p.HandleFunction(handlerDef.Options, handlerDef.Handler)
		}
		return nil
	})
}
