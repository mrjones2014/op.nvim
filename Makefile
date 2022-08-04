default: all

.PHONY: build-macos
build-macos:
	GOOS=darwin GOARCH=amd64 go build -o op-nvim-mac-amd64
	GOOS=darwin GOARCH=arm64 go build -o op-nvim-mac-arm64
	lipo -create -output op-nvim-mac-universal op-nvim-mac-amd64 op-nvim-mac-arm64

.PHONY: build-linux
build-linux:
	GOOS=linux GOARCH=amd64 go build -o op-nvim-linux

.PHONY: all
all: build-macos build-linux

.PHONY: clean
clean:
	rm op-nvim-mac-universal op-nvim-mac-arm64 op-nvim-mac-arm64 op-nvim-linux

.PHONY: install
install:
	mkdir -p bin
	if [[ "$$OSTYPE" == "linux-gnu"* ]]; then cp ./op-nvim-linux ./bin/op-nivm; elif [[ "$$OSTYPE" == "darwin"* ]]; then cp ./op-nvim-mac-universal ./bin/op-nvim; fi
