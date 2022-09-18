package main

import (
	"fmt"
	"strings"
)

// replace ' with \' and \ with \\
func sanitize(s string) string {
	return strings.ReplaceAll(
		strings.ReplaceAll(s, "'", "\\'"),
		"\\",
		"\\\\",
	)
}

func AsyncCallback(requestId string, json *string, err error) {
	if err != nil {
		luaCode := fmt.Sprintf("require('op.api.async').callback('%s', nil, '%s')", sanitize(requestId), sanitize(err.Error()))
		PluginInstance.Nvim.ExecLua(luaCode, nil)
	} else {
		luaCode := fmt.Sprintf("require('op.api.async').callback('%s', '%s', nil)", sanitize(requestId), sanitize(*json))
		PluginInstance.Nvim.ExecLua(luaCode, nil)
	}
}
