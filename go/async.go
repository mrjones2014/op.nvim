package main

import (
	"fmt"
)

func asyncCallback(requestId string, json *string, err error) {
	if err != nil {
		luaCode := fmt.Sprintf("require('op.api.async').callback(%q, nil, %q)", requestId, err.Error())
		PluginInstance.Nvim.ExecLua(luaCode, nil)
	} else {
		luaCode := fmt.Sprintf("require('op.api.async').callback(%q, %q, nil)", requestId, *json)
		PluginInstance.Nvim.ExecLua(luaCode, nil)
	}
}

func run[T any](requestId string, params T, handler func(params T) (*string, error)) {
	json, err := handler(params)
	asyncCallback(requestId, json, err)
}

func DoAsync[T any](requestId string, params T, handler func(params T) (*string, error)) {
	go run(requestId, params, handler)
}
