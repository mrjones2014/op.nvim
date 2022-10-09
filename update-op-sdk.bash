#!/usr/bin/env bash

rm -rf op-sdk-*
luarocks download op-sdk
ROCK_PATH="$(find . -name "op-sdk-*" -maxdepth 1)"
luarocks unpack "$ROCK_PATH"

ROCK_ROOT="$(find . -name "op-sdk-*" -maxdepth 1 -type d)"
cp "$ROCK_ROOT/op-lua-sdk/src/op-sdk.lua" "./lua/op-sdk.lua"
cp -r "$ROCK_ROOT/op-lua-sdk/src/op-sdk/" "./lua/op-sdk/"
