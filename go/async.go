package main

import (
	"fmt"
)

func AsyncSuccess(requestId string, json string) {
	luaCode := fmt.Sprintf("require('op.api.async').callback(%q, %q, nil)", requestId, json)
	PluginInstance.Nvim.ExecLua(luaCode, nil)
}

func AsyncErr(requestId string, err error) {
	luaCode := fmt.Sprintf("require('op.api.async').callback(%q, nil, %q)", requestId, err.Error())
	PluginInstance.Nvim.ExecLua(luaCode, nil)
}
