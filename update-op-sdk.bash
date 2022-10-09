#!/usr/bin/env bash

rm -rf op-sdk-*
rm -rf ./lua/op-sdk.lua ./lua/op-sdk/
luarocks download op-sdk
ROCK_PATH="$(find . -name "op-sdk-*.src.rock" -maxdepth 1)"
luarocks unpack "$ROCK_PATH"

ROCK_ROOT="$(find . -name "op-sdk-*" -maxdepth 1 -type d)"
cp "$ROCK_ROOT/op-sdk-lua/src/op-sdk.lua" "./lua/op-sdk.lua"
mkdir "./lua/op-sdk/"
cp -r "$ROCK_ROOT/op-sdk-lua/src/op-sdk/" "./lua/op-sdk/"
