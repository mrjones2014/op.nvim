package main

import (
	"fmt"
)

type Executor = func(string)

type AsyncManager struct {
	execLua Executor
}

func (a AsyncManager) Success(requestId string, json string) {
	luaCode := fmt.Sprintf("require('op.api.async').callback(%q, %q, nil)", requestId, json)
	a.execLua(luaCode)
}

func (a AsyncManager) Err(requestId string, err error) {
	luaCode := fmt.Sprintf("require('op.api.async').callback(%q, nil, %q)", requestId, err.Error())
	a.execLua(luaCode)
}

var Async = AsyncManager{
	execLua: func(lua string) {
		PluginInstance.Nvim.ExecLua(lua, nil)
	},
}
