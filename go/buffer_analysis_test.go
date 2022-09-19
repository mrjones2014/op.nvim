package main

import (
	"testing"
)

func (a AsyncManager) MockExecutor(exe Executor) {
	a.execLua = exe
}

func FormatSecretType_WithItemTitle(t *testing.T) {
	Async.MockExecutor(func(lua string) {})
	// TODO
}

func FormatSecretType_WithoutItmeTitle(t *testing.T) {
	Async.MockExecutor(func(lua string) {})
	// TODO
}

func AnalyzeBufferTest(t *testing.T) {
	Async.MockExecutor(func(lua string) {})
	// TODO
}
