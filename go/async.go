package main

import (
	"fmt"
	"strings"
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

func (a AsyncManager) Print(msg string) {
	luaCode := fmt.Sprintf("print('%s')", strings.ReplaceAll(msg, "'", "\\'"))
	a.execLua(luaCode)
}

func (a AsyncManager) UpdateStatusline(accountName *string) {
	if accountName == nil {
		a.execLua("require('op.statusline').update(nil)")
	} else {
		a.execLua(fmt.Sprintf("require('op.statusline').update(\"%s\")", accountName))
	}
}

var Async = AsyncManager{
	execLua: func(lua string) {
		PluginInstance.Nvim.ExecLua(lua, nil)
	},
}
