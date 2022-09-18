package main

import "fmt"

func AsyncCallback(requestId string, json *string, err error) {
	PluginInstance.Nvim.ExecLua("print('got here')", nil)
	if err != nil {
		PluginInstance.Nvim.ExecLua(fmt.Sprintf("print([[%s]])", err.Error()), nil)
		luaCode := fmt.Sprintf("require('op.api.async').callback([[%s]], nil, [[%s]])", requestId, err)
		PluginInstance.Nvim.ExecLua(luaCode, nil)
	} else {
		PluginInstance.Nvim.ExecLua("print('got here too')", nil)
		// it's failing on something to do with *json
		PluginInstance.Nvim.ExecLua(fmt.Sprintf("print([[%s]])", *json), nil)
		luaCode := fmt.Sprintf("require('op.api.async').callback([[%s]], [[%s]], nil)", requestId, *json)
		PluginInstance.Nvim.ExecLua(luaCode, nil)
	}
}
