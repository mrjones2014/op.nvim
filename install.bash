#!/usr/bin/env bash

OSTYPE=$(uname)
if [[ "$OSTYPE" == *"Linux"* ]]; then
  cp ./bin/op-nvim-linux ./bin/op-nvim
elif [[ "$OSTYPE" == "Darwin"* ]]; then
  cp ./bin/op-nvim-mac-universal ./bin/op-nvim
else
  echo "Platform $OSTYPE not supported."
  exit 1
fi
