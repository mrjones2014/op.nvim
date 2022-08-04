package main

import (
	"github.com/neovim/go-client/nvim/plugin"
)

type CliOutput struct {
	Outupt     string `json:"output"`
	ReturnCode int    `json:"return_code"`
}

func main() {
	plugin.Main(func(p *plugin.Plugin) error {
		p.HandleFunction(&plugin.FunctionOptions{Name: "Opcmd"}, OpCmd)
		p.HandleFunction(&plugin.FunctionOptions{Name: "OpSetup"}, Setup)
		p.HandleFunction(&plugin.FunctionOptions{Name: "OpDesignateField"}, DesignateField)
		return nil
	})
}
